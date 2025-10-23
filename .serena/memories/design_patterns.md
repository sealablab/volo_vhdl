# Design Patterns and Guidelines

## ⚠️ CRITICAL: MCC 3-Bit Control Scheme (READ THIS FIRST!)

**ALL MCC modules require THREE control bits in Control0[31:29]:**

```
Control0[31] = MCC_READY (active-high) - Set by MCC after deployment
Control0[30] = Enable (active-high) - User-controlled enable/disable
Control0[29] = ClkEn (active-high) - ⚠️ MANDATORY for clocked logic
```

**Correct Pattern:** `0xE0000000` (bits 31+30+29 all set)  
**WRONG Pattern:** `0xC0000000` (missing bit 29) → **MODULE FREEZES!**

**Why This Matters**: Missing Clock Enable (bit 29) is the #1 cause of frozen modules. Without bit 29, sequential logic is frozen even when "enabled" via bit 30.

**Quick Start - Use Helper Function**:
```python
# In CocotB tests (conftest.py provides helpers)
from conftest import mcc_cr0

# Automatic 3-bit scheme:
cr0 = mcc_cr0(divider=240)  # Returns 0xEEF00000 ✓
cr0 = mcc_cr0()              # Returns 0xE0000000 ✓

# Manual (ensure all 3 bits!):
cr0 = 0xEEF00000  # ✓ Bits 31+30+29 all set
cr0 = 0xC0F00000  # ✗ Missing bit 29 → FREEZE!
```

**Reference**: See detailed MCC_READY pattern below, `mcc_debugging_techniques.md` memory, and `conftest.py` validation functions.

---

## Key Design Patterns

### 1. Direct Instantiation Pattern (MANDATORY for Top Layer)
All top-level integration files must use direct entity instantiation:

```vhdl
-- Top-level file: modules/*/top/*.vhd
architecture rtl of module_top is
begin
    -- ✅ REQUIRED: Direct instantiation
    U_CORE: entity WORK.module_core
        port map (
            clk => clk,
            n_reset => n_reset,
            enable => enable,
            data_in => data_in,
            data_out => data_out
        );
end architecture;
```

**Benefits**:
- Clear compilation order requirements
- Port mismatches caught at analysis time
- Uniform pattern across top-level files
- Easier dependency tracking

### 2. MCC 3-Bit Control Scheme (MANDATORY for all MCC modules)

**Added**: 2025-01-23 (Clock Enable discovery)  
**Updated**: Expanded from original 1-bit MCC_READY convention

**Problem**: During FPGA bitstream loading, all MCC control registers initialize to 0x00000000. Modules must:
1. Remain disabled during network delay (10-200ms)
2. Enable clock gating for sequential logic
3. Provide user-level enable/disable control

**Solution**: Use THREE mandatory control bits in Control0[31:29]

**Control Bit Definitions**:
```
Control0[31] = MCC_READY (active-high)
  - Set by MCC after bitstream deployment
  - 0 = Bitstream loading, config not ready
  - 1 = Config loaded, module ready to operate

Control0[30] = Enable (active-high)
  - User-controlled module enable/disable
  - 0 = Module idle (safe parked state)
  - 1 = Module enabled for operation

Control0[29] = ClkEn (active-high) ⚠️ CRITICAL!
  - Clock enable for sequential logic
  - 0 = Sequential logic FROZEN (no state updates)
  - 1 = Sequential logic active (clocked)
```

**Configuration Patterns**:
```
# With clock divider (bits 23:16)
Div=240 (0xF0): 0xEEF00000
                1110_1110_1111_0000...
                ^^^^ ^^^^
                │││└─ Divider bits (240 = 0xF0)
                ││└── ClkEn (bit 29) ✓
                │└─── Enable (bit 30) ✓
                └──── MCC_READY (bit 31) ✓

# Base pattern (no divider):
0xE0000000 = 1110_0000_0000_0000...
             │││
             ││└── ClkEn (bit 29) ✓
             │└─── Enable (bit 30) ✓
             └──── MCC_READY (bit 31) ✓

# WRONG patterns (DO NOT USE):
0xC0000000 = 1100_0000... (missing bit 29) → FREEZE!
0x60000000 = 0110_0000... (missing bit 31) → DISABLED!
```

**VHDL Implementation** (Top.vhd):
```vhdl
-- Register Map (Comment Header - MANDATORY)
-- MCC 3-Bit Control Scheme:
--   Control0[31] = MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
--   Control0[30] = User Enable (1=enable, 0=disable)
--   Control0[29] = Clock Enable (1=clocked, 0=frozen) ⚠️ MANDATORY
--   Control0[28:0] = Module-specific configuration

architecture ModuleName of CustomWrapper is
    -- MCC control signals (extract all 3 bits!)
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal clk_enable     : std_logic;
    signal global_enable  : std_logic;
    
    -- Internal signals
    signal status_internal  : unsigned(6 downto 0);
begin
    -- ========================================================================
    -- MCC 3-BIT CONTROL EXTRACTION (CRITICAL!)
    -- ========================================================================
    mcc_ready      <= Control0(31);  -- MCC sets after deployment
    user_enable    <= Control0(30);  -- User-level enable
    clk_enable     <= Control0(29);  -- ⚠️ MUST extract for clocked modules!
    
    -- Combine all 3 for safe operation
    global_enable  <= mcc_ready and user_enable and clk_enable;
    
    -- ========================================================================
    -- MODULE INSTANCE
    -- ========================================================================
    MODULE_INST: entity WORK.ModuleName
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Enable => global_enable,   -- Safe: all 3 bits required
            ClkEn  => clk_enable,      -- Or '1' if always clocked
            ...
        );
end architecture;
```

**CocotB Testing Pattern** (with validation):
```python
from conftest import (
    setup_clock, reset_active_high, init_mcc_inputs,
    mcc_set_regs, wait_for_mcc_ready, mcc_cr0  # Helper!
)

@cocotb.test()
async def test_initialization(dut):
    # Hardware startup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)
    
    # Option 1: Use helper (recommended, includes validation)
    await mcc_set_regs(dut, {
        0: mcc_cr0(divider=240),  # Returns 0xEEF00000 with all 3 bits
        1: 0x043C7D00,            # Module params
        2: 0x64000000
    }, set_mcc_ready=True)
    
    # Option 2: Manual (conftest validates and warns if bit 29 missing)
    await mcc_set_regs(dut, {
        0: 0xEEF00000,  # ✓ All 3 bits present (validated automatically)
        1: 0x043C7D00,
        2: 0x64000000
    }, set_mcc_ready=True)
    
    # Wait for module to settle
    await wait_for_mcc_ready(dut)
    
    # Test normal operation
    # ...
```

**Validation** (`conftest.py` provides automatic checking):
```python
# conftest.py provides:
MCC_READY_BIT = 31
ENABLE_BIT = 30
CLK_EN_BIT = 29  # ⚠️ CRITICAL!
MCC_CR0_BASE = 0xE0000000  # All 3 bits set

def validate_control0(cr0_value, context=""):
    """Warns if Clock Enable (bit 29) is missing"""
    # Automatically called by mcc_set_regs()
    # Emits warning if enable=1 but clk_en=0

def mcc_cr0(divider=0, extra_bits=0):
    """Construct Control0 with all 3 bits"""
    # Returns 0xE0000000 | divider<<16 | extra_bits
```

**Why Clock Enable is Critical**:
Without Clock Enable (bit 29), the module's sequential logic is **completely frozen**:
- Counters don't increment
- State machines don't transition  
- Outputs remain static
- Both simulation AND hardware appear "dead"

**Historical Context**: This was the root cause of the 2025-01-23 PulseStar debugging session. Changing from 0xC0000000 (2 bits) to 0xE0000000 (3 bits) immediately fixed all "frozen module" issues.

**Benefits**:
- ✓ **Safe default**: All-zero state keeps module disabled (bit 31=0)
- ✓ **Network-aware**: MCC sets CR0[31]=1 only after config loaded
- ✓ **Clock gating**: Bit 29 enables sequential logic (MANDATORY!)
- ✓ **User control**: Bit 30 provides runtime enable/disable
- ✓ **Testable**: CocotB validates configuration automatically
- ✓ **Debuggable**: Tools like `debug_mcc_config.py` test bit patterns

**Reference Implementations**:
- **`modules/EMFI-Seq/top/Top.vhd`** - MCC_READY pattern (2-bit, needs update to 3-bit)
- **`modules/PulseStar/top/Top.vhd`** - Full 3-bit scheme example
- **`tests/conftest.py`** - Validation and helper functions
- **`scripts/debug_mcc_config.py`** - Systematic bit pattern testing tool

**Reference Documentation**:
- **`mcc_debugging_techniques.md`** (Serena memory) - Full debugging guide
- **`CLAUDE.md`** - MCC_READY section with complete examples
- **`tests/test_mcc_primitives.py`** - Validation test suite

**Discovered**: 2025-01-23, PulseStar hardware debugging session

[... rest of the design_patterns.md content continues unchanged ...]

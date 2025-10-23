# Design Patterns and Guidelines

## ⚠️ CRITICAL: MCC 3-Bit Control Scheme (READ THIS FIRST!)

**ALL MCC modules require THREE control bits in Control0[31:29]:**

```
Control0[31] = MCC_READY (active-high) - Set by MCC after deployment
Control0[30] = Enable (active-high) - User-controlled enable/disable
Control0[29] = ClkEn (active-high) - ⚠️ MANDATORY for clocked modules!
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

### 2. Enable Control Semantics (CRITICAL - Added 2025-10-23)

**Problem**: What should `enable='0'` do? Reset to idle, or hold current state?

**Answer**: **HOLD STATE** (not reset!)

This allows for FSM freeze/resume functionality, which is essential for:
- Debugging (pause module mid-operation)
- Power management (freeze without losing state)
- Synchronization (pause until other modules ready)

**Correct Pattern**:
```vhdl
process(clk, n_reset)
begin
    if n_reset = '0' then
        -- Reset: Force safe state
        current_state <= STATE_IDLE;
        tx_busy <= '0';
        
    elsif rising_edge(clk) then
        if clk_en = '1' and enable = '1' then
            -- Normal operation
            case current_state is
                when STATE_IDLE =>
                    if send_pulse = '1' then
                        current_state <= STATE_ACTIVE;
                        tx_busy <= '1';
                    end if;
                when STATE_ACTIVE =>
                    -- ... FSM logic ...
            end case;
        end if;
        -- enable='0': Hold all state (outputs parked, FSM frozen)
        -- clk_en='0': Hold all state (no updates)
    end if;
end process;
```

**WRONG Pattern** (DO NOT USE):
```vhdl
elsif rising_edge(clk) then
    if clk_en = '1' and enable = '1' then
        -- Normal operation
    elsif enable = '0' then
        -- ❌ WRONG: Resetting to idle on disable
        current_state <= STATE_IDLE;
        tx_busy <= '0';
    end if;
```

**Control Signal Priority** (highest to lowest):
1. **Reset** (`n_reset='0'`) - Forces safe state, clears all registers
2. **Clock Enable** (`clk_en='0'`) - Freezes sequential logic (no state updates)
3. **Functional Enable** (`enable='0'`) - Parks outputs, holds FSM state

**Test Pattern for Freeze/Resume**:
```python
# Start transmission
dut.send_pulse.value = 1
await RisingEdge(dut.clk)
dut.send_pulse.value = 0

# Wait until busy
await ClockCycles(dut.clk, 100)
assert dut.tx_busy.value == 1

# Disable (should freeze FSM, not reset)
dut.enable.value = 0
await ClockCycles(dut.clk, 100)
assert dut.tx_busy.value == 1  # ✓ State held (frozen)

# Re-enable (should resume)
dut.enable.value = 1
await wait_for_tx_done(dut)  # ✓ Transmission completes
```

**Discovered**: 2025-10-23, SimpleSerial V1 TX development. Test 9 (enable control) was failing because FSM reset to idle instead of holding state.

### 3. Delta-Cycle Race Avoidance (CRITICAL - Added 2025-10-23)

**Problem**: When incrementing an index signal, dependent combinational signals may read the OLD index value in the same delta cycle.

**Symptom**: Wrong data order or stale values (e.g., sending `0x00112233` but getting `0x00011223`).

**Root Cause**:
```vhdl
-- Combinational assignments
current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);
high_nibble <= current_byte(7 downto 4);  -- BUG: May use old current_byte!

-- Sequential logic
when STATE_SEND_HEX_LOW =>
    if uart_done = '1' then
        byte_idx <= byte_idx + 1;  -- Index updates
        uart_data <= nibble_to_hex_ascii(high_nibble);  -- Reads OLD nibble!
    end if;
```

**Solution 1: Direct Read (PREFERRED)**:
```vhdl
-- Bypass intermediate signal - read directly from source
current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);

-- ✅ Direct read eliminates race
high_nibble <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8 + 4);
low_nibble  <= payload_latch(to_integer(byte_idx) * 8 + 3 downto to_integer(byte_idx) * 8);
```

**Solution 2: Settling State** (if direct read not possible):
```vhdl
constant STATE_LOAD_BYTE : std_logic_vector(3 downto 0) := "0010";

when STATE_SEND_HEX_LOW =>
    if uart_done = '1' then
        byte_idx <= byte_idx + 1;
        current_state <= STATE_LOAD_BYTE;  -- Wait for settling
    end if;

when STATE_LOAD_BYTE =>
    -- Now current_byte reflects NEW byte_idx value
    uart_data <= nibble_to_hex_ascii(high_nibble);  -- Correct!
    current_state <= STATE_SEND_HEX_HIGH;
```

**Pattern Recognition**:
- Index signals feeding array/vector slicing
- Multi-level combinational dependencies (A → B → C)
- Immediate use of updated values in same cycle

**Reference**: `docs/VHDL_DELTA_CYCLE_PATTERNS.md` for detailed examples and debugging tips.

**Discovered**: 2025-10-23, SimpleSerial V1 TX development. Payload bytes were being read in wrong order.

### 4. UART/Protocol Busy Flag Checking (Added 2025-10-23)

**Problem**: When wrapping a lower-level module (like `uart_tx_core`), the wrapper FSM may return to IDLE before the underlying module completes.

**Symptom**: Back-to-back transmissions corrupt or fail with framing errors.

**Solution**: Check the underlying module's busy flag before accepting new work:

```vhdl
-- Top-level signals
signal uart_busy : std_logic;  -- From uart_tx_core
signal tx_busy   : std_logic;  -- Wrapper's busy flag

-- FSM
when STATE_IDLE =>
    tx_busy <= '0';
    
    -- ✅ Only accept new work if UART core is idle!
    if send_pulse = '1' and uart_busy = '0' then
        tx_busy <= '1';
        uart_send <= '1';
        current_state <= STATE_ACTIVE;
    end if;
```

**Why This is Needed**:
- Wrapper FSM may complete its state machine before UART finishes its last bit
- UART TX core may need extra cycles after stop bit to fully settle
- Back-to-back transmissions can overlap without this check

**Test Pattern**:
```python
for cmd in commands:
    # Send command
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0
    
    # Capture response
    frame = await capture_uart_string(dut)
    assert frame == expected
    
    # No extra delay needed - busy flag prevents overlap!
```

**Discovered**: 2025-10-23, SimpleSerial V1 TX development. Back-to-back commands test was failing with UART framing errors.

### 5. MCC 3-Bit Control Scheme (MANDATORY for all MCC modules)

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
    async def test_logic():
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
        
        # Wait for module to settle
        await wait_for_mcc_ready(dut)
        
        # Test normal operation
        dut._log.info("✓ Test PASSED")
    
    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_initialization")
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

### 6. FSM State Encoding (Verilog Portability)

Use `std_logic_vector` encoding instead of enumeration types:

```vhdl
-- ✅ CORRECT: Vector encoding (Verilog portable)
constant STATE_IDLE   : std_logic_vector(3 downto 0) := "0000";
constant STATE_ACTIVE : std_logic_vector(3 downto 0) := "0001";
constant STATE_DONE   : std_logic_vector(3 downto 0) := "0010";

signal current_state : std_logic_vector(3 downto 0);

-- ❌ WRONG: Enumeration (not Verilog portable)
type state_type is (IDLE, ACTIVE, DONE);
signal current_state : state_type;
```

**Benefits**:
- Verilog portability (enums don't translate)
- Explicit encoding visible in code
- Easier state machine debugging
- Consistent with Tier 1 coding standards

### 7. Standard Status Register Format

**Bit Allocation**:
- Bit 7: FAULT (sticky, cleared only on reset)
- Bit 6: ALARM (sticky, cleared only on reset)
- Bits 5-0: Module-specific status

```vhdl
signal stat_reg : unsigned(7 downto 0);

-- Set FAULT on error condition
if error_detected = '1' then
    stat_reg(7) <= '1';  -- Sticky fault
end if;

-- Clear on reset only
if n_reset = '0' then
    stat_reg <= (others => '0');
end if;
```

### 8. Platform Interface Package Pattern

For modules requiring complex register interfaces:

```vhdl
-- common/platform_interface_pkg.vhd
package platform_interface_pkg is
    -- Register field bit positions
    constant CTRL0_ENABLE_BIT : natural := 0;
    constant CTRL0_MODE_LOW   : natural := 1;
    constant CTRL0_MODE_HIGH  : natural := 3;
    
    -- Field extraction functions
    function extract_ctrl_enable(ctrl_data : std_logic_vector) return std_logic;
    function extract_ctrl_mode(ctrl_data : std_logic_vector) return unsigned;
    
    -- Validation functions
    function is_mode_valid(mode : unsigned) return std_logic;
end package;
```

## Common Patterns in Practice

### Pattern: Synchronous Reset with Enable Hierarchy

```vhdl
process(clk, n_reset)
begin
    if n_reset = '0' then
        -- Reset: Safe defaults
        current_state <= STATE_IDLE;
        counter <= (others => '0');
        output <= (others => '0');
        
    elsif rising_edge(clk) then
        if clk_en = '1' then        -- Priority 2: Clock enable
            if enable = '1' then     -- Priority 3: Functional enable
                -- Normal operation
                case current_state is
                    when STATE_IDLE =>
                        if start_pulse = '1' then
                            current_state <= STATE_ACTIVE;
                        end if;
                    when STATE_ACTIVE =>
                        counter <= counter + 1;
                        -- ... FSM logic ...
                end case;
            end if;
            -- enable='0': Hold state (FSM frozen)
        end if;
        -- clk_en='0': Hold all state
    end if;
end process;
```

### Pattern: Multi-Core Integration

```vhdl
architecture rtl of module_top is
    -- Internal signals
    signal core1_output : std_logic_vector(15 downto 0);
    signal core2_input  : std_logic_vector(15 downto 0);
begin
    -- Core 1: Data generator
    U_CORE1: entity WORK.data_generator
        port map (
            clk => clk,
            enable => enable,
            data_out => core1_output
        );
    
    -- Core 2: Data processor
    U_CORE2: entity WORK.data_processor
        port map (
            clk => clk,
            enable => enable,
            data_in => core1_output,  -- Connect cores
            data_out => output
        );
end architecture;
```

## Testing Patterns for Design Verification

### Pattern: Test Enable Control Freeze/Resume

```python
@cocotb.test()
async def test_enable_freeze_resume(dut):
    async def test_logic():
        await setup_clock(dut)
        await reset_active_low(dut)
        
        # Start operation
        dut.enable.value = 1
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
        # Wait until busy
        await ClockCycles(dut.clk, 50)
        assert dut.busy.value == 1
        
        # Freeze (enable='0')
        dut.enable.value = 0
        await ClockCycles(dut.clk, 100)
        assert dut.busy.value == 1  # ✓ State held
        
        # Resume (enable='1')
        dut.enable.value = 1
        await wait_for_completion(dut)  # ✓ Completes
        
        dut._log.info("✓ Freeze/resume test PASSED")
    
    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_enable_freeze_resume")
```

### Pattern: Test Delta-Cycle Sensitivity

```python
@cocotb.test()
async def test_indexed_access(dut):
    async def test_logic():
        # Set up payload
        dut.payload_data.value = 0x33221100  # Bytes: 00, 11, 22, 33
        
        # Test each index
        for idx in range(4):
            dut.byte_idx.value = idx
            await ClockCycles(dut.clk, 1)  # Allow signals to settle
            
            # Verify correct byte extracted
            expected_byte = (0x33221100 >> (idx * 8)) & 0xFF
            actual_byte = int(dut.current_byte.value)
            assert actual_byte == expected_byte, \
                f"Idx {idx}: expected 0x{expected_byte:02X}, got 0x{actual_byte:02X}"
        
        dut._log.info("✓ Indexed access test PASSED")
    
    await run_with_timeout(test_logic(), timeout_sec=5, test_name="test_indexed_access")
```

## Reference Documentation

**On-Disk Files** (NEW - Added 2025-10-23):
- `docs/VHDL_DELTA_CYCLE_PATTERNS.md` - Delta-cycle race conditions deep dive
- `docs/COCOTB_UART_TEST_PATTERNS.md` - UART protocol testing patterns

**Serena Memories**:
- `coding_standards` - VHDL tiered rule system
- `cocotb_testing_guide` - CocotB framework and patterns
- `mcc_debugging_techniques` - MCC troubleshooting
- `ghdl_patterns_and_solutions` - Build and simulation patterns

**Example Code**:
- `modules/volo_common/core/volo_simpleserial_v1_tx.vhd` - Delta-cycle avoidance, enable control
- `modules/PulseStar/top/Top.vhd` - MCC 3-bit scheme
- `tests/test_simpleserial_v1_tx.py` - Protocol testing, timeout patterns

## Summary

**Key Takeaways (Added 2025-10-23)**:

1. **Enable control**: `enable='0'` should HOLD STATE, not reset to idle
2. **Delta-cycle races**: Read directly from source, or add settling state
3. **Busy flag checking**: Always check underlying module's busy before accepting new work
4. **UART timing**: Half bit for first sample, full bit after, settling delay after stop
5. **Timeout patterns**: Always use `run_with_timeout()`, calculate from specs, never `while` loops

These patterns are documented in detail in the reference files and have been proven through comprehensive testing.

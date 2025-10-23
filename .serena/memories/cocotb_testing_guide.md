# CocotB Testing Guide for Volo VHDL

## Overview
CocotB (Coroutine-based Cosimulation TestBench) is the **standard testing framework** for the Volo VHDL project. It replaces legacy GHDL testbenches with Python-based async/await testing.

⚠️ **DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead

## Quick Start

### Running Tests
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module
make TEST_MODULE=mcc_primitives        # Run MCC primitives test
make test-all                          # Run all tests
make clean                             # Clean artifacts
make waves                             # View waveforms
```

### Environment Variables
```bash
WAVES=1                    # Enable waveform dump (default)
WAVES=0                    # Disable waveforms for faster tests
COCOTB_LOG_LEVEL=DEBUG     # Set log level (DEBUG/INFO/WARNING/ERROR)
```

## Test Structure

### Basic Template
```python
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low

@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("Test 1: Reset Behavior")
   
    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut)
   
    assert dut.output.value == 0, "Output should be 0 after reset"
    dut._log.info("✓ Reset test PASSED")
```

### Shared Utilities (conftest.py)
All tests can use these helpers from `tests/conftest.py`:

**Clock Management**:
- `setup_clock(dut, period_ns=10, clk_signal="clk")` - Start clock
- Default: 10ns period (100MHz)

**Reset Sequences**:
- `reset_active_low(dut, cycles=2, rst_signal="rst_n")` - Active-low reset
- `reset_active_high(dut, cycles=2, rst_signal="rst")` - Active-high reset (MCC style)
- `reset_dut(dut, active_low=True)` - Auto-detect reset type

**Signal Monitoring**:
- `count_pulses(signal, clk, num_cycles)` - Count signal pulses
- `wait_for_value(signal, expected, clk, timeout=1000)` - Wait for value with timeout
- `capture_signal_sequence(signal, clk, num_cycles)` - Capture value sequence

**Initialization**:
- `init_dut(dut, clock_period_ns=10, active_low_reset=True)` - Complete init (clock + reset)

**Assertions**:
- `assert_signal_value(signal, expected, message)` - Assert with helpful error
- `assert_pulse_count(signal, clk, cycles, expected, tolerance=0)` - Assert pulse count

## MCC Module Testing

### MCC_READY Convention (MANDATORY for all MCC modules)

**Control0[31] = MCC_READY flag (ACTIVE-HIGH)**

This convention solves the "all-zero reset state" problem during bitstream loading:

**The Problem**:
When an FPGA bitstream is loaded onto Moku hardware:
1. Bitstream loads → all control registers = 0x00000000
2. Network delay (10-200ms typical) before configuration arrives
3. Registers updated over network with actual configuration
4. Module starts operating

During step 2, the module sees **all zeros** on control inputs. Without MCC_READY, this can cause unpredictable behavior.

**The Solution - CR0[31] as MCC_READY**:
```
Control0[31] = 0 → Module DISABLED (safe during all-zero state)
Control0[31] = 1 → Module ENABLED and ready for operation
```

**VHDL Implementation Pattern** (in Top.vhd):
```vhdl
architecture ModuleName of CustomWrapper is
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal global_enable  : std_logic;
begin
    -- Extract MCC_READY flag (CR0[31])
    mcc_ready     <= Control0(31);
    user_enable   <= Control0(30);  -- Example: user-level enable
    
    -- Gate module with MCC_READY (safe during all-zero state)
    global_enable <= mcc_ready and user_enable;
    
    MODULE_INST: entity WORK.ModuleName
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Enable => global_enable,  -- Safe: disabled when CR0[31]=0
            ...
        );
end architecture;
```

**Benefits**:
- ✓ Safe default: All-zero state keeps module disabled
- ✓ Clear semantic: Bit 31 = "configuration valid and ready"
- ✓ Active-high logic: No confusing inversions
- ✓ Network-aware: External system sets CR0[31]=1 after config loaded
- ✓ Testable: CocotB tests simulate realistic initialization

**Example**: See `modules/EMFI-Seq/top/Top.vhd` for reference implementation

### MCC Primitives (NEW - Added 2025-10-22)

The following primitives in `conftest.py` handle MCC initialization with realistic network latency:

**MCC Initialization**:
- `init_mcc_inputs(dut)` - Zero all InputA-D channels
- `mcc_set_regs(dut, control_regs, set_mcc_ready=True, ...)` - Set control registers with network delay
- `wait_for_mcc_ready(dut, settle_cycles=10)` - Wait for module to stabilize
- `wait_for_first_clk_en(dut, clk_en_signal="clk_en", ...)` - Wait for first clock enable pulse
- `mcc_disable(dut, ...)` - Clear MCC_READY to safely disable module

### MCC Test Initialization Pattern (UPDATED)

**Old pattern** (DEPRECATED - manual register writes):
```python
async def init_control_registers(dut):
    dut.Control0.value = 0x00000000
    dut.Control1.value = 0
    # ... manual initialization
```

**New pattern** (RECOMMENDED - uses MCC primitives):
```python
from conftest import (
    setup_clock,
    reset_active_high,
    init_mcc_inputs,
    mcc_set_regs,
    wait_for_mcc_ready
)

@cocotb.test()
async def test_mcc_initialization(dut):
    # Step 1: Hardware startup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)
    
    # Step 2: Simulate network delay + configuration load
    await mcc_set_regs(dut, {
        0: 0x40000001,  # User bits (CR0[31] set automatically)
        1: 0x0000007F,  # Module config
        5: 0x0000199A   # Voltage level
    }, set_mcc_ready=True)  # Automatically sets CR0[31]=1
    
    # Step 3: Wait for module to settle
    await wait_for_mcc_ready(dut)
    
    # Now safe to test module behavior
```

**Network Latency Simulation**:
```python
# Random delay (10-200ms) - simulates real-world variability
await mcc_set_regs(dut, {...}, set_mcc_ready=True)

# Fixed delay (reproducible tests)
await mcc_set_regs(dut, {...}, set_mcc_ready=True, 
                  total_delay_ms=50.0, per_reg_delay_ms=0)

# No delay (fast tests)
await mcc_set_regs(dut, {...}, set_mcc_ready=True,
                  simulate_network_delay=False)
```

**Runtime Register Updates**:
```python
# Update registers while module is running
await mcc_set_regs(dut, {
    5: 0x00001000  # Change voltage
}, set_mcc_ready=False)  # Module already running, don't touch CR0[31]
```

**Complete Workflow Example**:
```python
@cocotb.test()
async def test_complete_initialization(dut):
    """Demonstrate complete MCC initialization workflow"""
    
    # === Phase 1: Hardware startup ===
    await setup_clock(dut, clk_signal="Clk", period_ns=10)
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)
    
    # === Phase 2: All-zero state (simulates bitstream load) ===
    # GHDL defaults all signals to 0, so this is implicit
    # In real hardware, registers are 0 after bitstream load
    for i in range(16):
        getattr(dut, f"Control{i}").value = 0
    await ClockCycles(dut.Clk, 10)
    
    # === Phase 3: Network delay + configuration ===
    await mcc_set_regs(dut, {
        0: 0x40000001,  # DivSel, enables, etc.
        1: 0x0000000A,  # Delays
        5: 0x0000199A,  # Voltage levels
    }, set_mcc_ready=True, total_delay_ms=25.0)
    
    # === Phase 4: Wait for module to settle ===
    await wait_for_mcc_ready(dut, settle_cycles=20)
    
    # === Phase 5: Verify operational ===
    await ClockCycles(dut.Clk, 100)
    # ... test module behavior
```

### CustomWrapper Entity Stub

For testing MCC modules (those using CustomWrapper), you need the CustomWrapper entity stub:

**File**: `mcc_templates/CustomWrapper_test_stub.vhd`

**Interface** (from MCC spec):
```vhdl
entity CustomWrapper is
    port (
        -- System
        Clk, Reset : in std_logic;
       
        -- Inputs (4 x 16-bit signed ADC)
        InputA, InputB, InputC, InputD : in signed(15 downto 0);
       
        -- Outputs (4 x 16-bit signed DAC)
        OutputA, OutputB, OutputC, OutputD : out signed(15 downto 0);
       
        -- Control Registers (16 x 32-bit std_logic_vector)
        Control0..Control15 : in std_logic_vector(31 downto 0)
    );
end entity CustomWrapper;
```

**Key Points**:
- Control registers are `std_logic_vector(31 downto 0)` NOT `signed`
- Control0[31] = MCC_READY flag (MANDATORY convention)
- MCC provides 16 control registers (Control0-Control15)
- MCC provides 4 input channels (InputA-D) and 4 output channels (OutputA-D)
- Stub must be included in VHDL_SOURCES before module's Top.vhd
- TOPLEVEL must be lowercase: `customwrapper` (GHDL lowercases entity names)

### Example Makefile Entry
```makefile
ifeq ($(TEST_MODULE),mcc_primitives)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd \
                   $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_fsm.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_stair.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/EMFI_Seq.vhd \
                   $(PROJECT_ROOT)/mcc_templates/CustomWrapper_test_stub.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/Top.vhd
    TOPLEVEL = customwrapper          # Lowercase!
    COCOTB_TEST_MODULES = test_mcc_primitives
endif
```

## Test Organization

### File Naming
- Test files: `test_<module_name>.py`
- Example: `test_clk_divider_core.py`, `test_emfi_seq_top.py`, `test_mcc_primitives.py`

### Test Numbering
Use numbered test functions with clear descriptions:
```python
@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)
    # ... test code
   
@cocotb.test()
async def test_clock_enable(dut):
    """Test 2: Clock Enable Control"""
    # ... test code
```

### Test Categories
Typical test sequence:
1. **Reset behavior** - Verify reset clears state
2. **MCC initialization** - Verify MCC_READY convention (for MCC modules)
3. **Basic functionality** - Core feature works
4. **Edge cases** - Boundary conditions, special values
5. **Control signals** - Enable, ClkEn, Reset interactions
6. **Randomized inputs** - Runtime-generated test data
7. **Integration** - Multi-module interactions
8. **Summary** - Final validation message

## Best Practices

### 1. Use Runtime Randomization
```python
import random

@cocotb.test()
async def test_randomized_delays(dut):
    random.seed()  # Use current time
    delay = random.randint(2, 15)
    dut._log.info(f"Random delay: {delay}")
    dut.delay_config.value = delay
    # ... verify behavior
```

### 2. Clear Logging
```python
dut._log.info("=" * 70)
dut._log.info("Test 3: Random Configuration")
dut._log.info("=" * 70)
dut._log.info(f"Config: delay={delay}, threshold={threshold}")
dut._log.info("✓ Test PASSED")
```

### 3. Helpful Assertions
```python
assert actual == expected, \
    f"Mismatch: expected {expected:#x}, got {actual:#x}"
```

### 4. Test Independence
Each test should:
- Initialize its own clock
- Apply its own reset
- Set all required signals
- Not depend on other tests' state

### 5. Avoid Magic Numbers
```python
# Bad
dut.config.value = 0x199A

# Good
VOLTAGE_1V1 = 0x199A  # From Moku_Voltage_pkg
dut.config.value = VOLTAGE_1V1
```

### 6. Use MCC Primitives for MCC Modules
```python
# Bad - manual register writes
dut.Control0.value = 0x80000000
await ClockCycles(dut.Clk, 100)

# Good - MCC primitives with network latency
await mcc_set_regs(dut, {0: 0x40000000}, set_mcc_ready=True)
await wait_for_mcc_ready(dut)
```

## Working Examples

### Simple Core Test
**File**: `tests/test_clk_divider_core.py` (7 tests passing)
- Reset behavior
- Division ratios (power-of-2 and arbitrary)
- Enable control
- Edge cases (div=1, div=256)

### Package Test
**File**: `tests/test_moku_voltage_pkg.py` (3 tests passing)
- Package function testing
- Voltage conversion validation

### MCC Integration Test
**File**: `tests/test_emfi_seq_top.py` (7 tests)
- CustomWrapper stub usage
- MCC control register mapping
- Multi-core integration
- Runtime randomization

### MCC Primitives Test (NEW)
**File**: `tests/test_mcc_primitives.py` (6 tests passing)
- MCC_READY all-zero state safety
- Network latency simulation
- Enable/disable sequences
- Runtime register updates
- Complete initialization workflow

## Migration from GHDL Testbenches

**Old pattern** (DEPRECATED):
```vhdl
-- tb/core/tb_module.vhd
entity tb_module is end entity;
architecture sim of tb_module is
    -- testbench code
end architecture;
```

**New pattern** (STANDARD):
```python
# tests/test_module.py
import cocotb
from conftest import init_dut

@cocotb.test()
async def test_feature(dut):
    await init_dut(dut)
    # test code
```

**Benefits**:
- Python's expressiveness vs VHDL verbosity
- Async/await for clean timing control
- Shared utilities (conftest.py)
- Runtime randomization
- Better logging and debugging
- Cross-platform compatibility
- MCC network latency simulation

## Common Pitfalls

### 1. Clock Signal Naming
```python
# MCC modules use capital Clk
await setup_clock(dut, clk_signal="Clk")

# Core modules use lowercase clk
await setup_clock(dut, clk_signal="clk")
```

### 2. Reset Polarity
```python
# Active-low (rst_n)
await reset_active_low(dut, rst_signal="rst_n")

# Active-high (Reset - MCC style)
await reset_active_high(dut, rst_signal="Reset")
```

### 3. Signal Value Access
```python
# Deprecated
val = int(dut.signal.value.signed_integer)

# Correct
val = int(dut.signal.value.to_signed())
```

### 4. GHDL Case Sensitivity
```makefile
# WRONG - GHDL lowercases entity names
TOPLEVEL = CustomWrapper

# CORRECT
TOPLEVEL = customwrapper
```

### 5. Control Register Types
```python
# Control registers are std_logic_vector, accept int
dut.Control0.value = 0x80000000  # Correct

# Don't try to assign signed
dut.Control0.value = signed(...) # Wrong
```

### 6. Forgetting MCC_READY Convention
```python
# Bad - CR0[31] not handled
dut.Control0.value = 0x40000000  # Missing MCC_READY bit

# Good - use mcc_set_regs which handles CR0[31]
await mcc_set_regs(dut, {0: 0x40000000}, set_mcc_ready=True)
```

### 7. Not Simulating Network Delay
```python
# Bad - unrealistic instant configuration
dut.Control0.value = 0x80000000
dut.Control1.value = 0x0000007F

# Good - realistic network latency
await mcc_set_regs(dut, {
    0: 0x40000000,
    1: 0x0000007F
}, set_mcc_ready=True)  # Includes 10-200ms delay by default
```

## Debugging

### Enable Waveforms
```bash
make TEST_MODULE=my_module WAVES=1
make waves  # View in GTKWave
```

### Increase Log Level
```bash
COCOTB_LOG_LEVEL=DEBUG make TEST_MODULE=my_module
```

### Add Debug Logging
```python
@cocotb.test()
async def test_debug(dut):
    dut._log.info(f"Signal value: {dut.signal.value}")
    dut._log.info(f"State: {dut.state.value}")
```

### Print All Signals
```python
from conftest import log_signal_table

log_signal_table(dut, ["clk_en", "enable", "div_sel", "stat_reg"])
```

## Adding New Tests

1. **Create test file**: `tests/test_<module>.py`
2. **Add Makefile entry**: Update `tests/Makefile`
3. **Include dependencies**: List all VHDL sources in compilation order
4. **Set TOPLEVEL**: Use lowercase entity name
5. **Write tests**: Use async/await pattern
6. **Use MCC primitives**: For MCC modules, use mcc_set_regs(), etc.
7. **Run**: `make TEST_MODULE=<module>`
8. **Update help**: Add to `make list-tests` output

## Reference Files

- **Template**: `tests/test_clk_divider_core.py` - Core module example
- **MCC Template**: `tests/test_mcc_primitives.py` - MCC initialization example
- **Utilities**: `tests/conftest.py` - Shared helper functions
- **Makefile**: `tests/Makefile` - Build system integration
- **README**: `tests/README.md` - User-facing documentation
- **MCC Stub**: `mcc_templates/CustomWrapper_test_stub.vhd` - CustomWrapper entity

## Summary

✅ **DO**:
- Use CocotB for all new tests
- Import helpers from conftest.py
- Use MCC primitives for MCC modules (mcc_set_regs, wait_for_mcc_ready, etc.)
- Follow MCC_READY convention (CR0[31] active-high)
- Simulate network latency for realistic tests
- Add clear logging and assertions
- Use runtime randomization
- Test each module independently
- Initialize all signals/registers

❌ **DON'T**:
- Create new GHDL testbenches
- Hard-code test values (use constants)
- Skip MCC_READY implementation in Top.vhd
- Manually write Control0 without mcc_set_regs
- Skip network latency simulation
- Assume instant register updates
- Rely on test execution order
- Forget to add Makefile entry

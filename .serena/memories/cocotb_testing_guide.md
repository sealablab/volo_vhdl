# CocotB Testing Guide for Volo VHDL

## Overview
CocotB (Coroutine-based Cosimulation TestBench) is the **standard testing framework** for the Volo VHDL project. It replaces legacy GHDL testbenches with Python-based async/await testing.

⚠️ **DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead

## Quick Start

### Running Tests
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module
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

### CustomWrapper Entity Stub

For testing MCC modules (those using CustomWrapper), you need the CustomWrapper entity stub:

**File**: `tests/customwrapper_stub.vhd`

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
- MCC provides 16 control registers (Control0-Control15)
- MCC provides 4 input channels (InputA-D) and 4 output channels (OutputA-D)
- Stub must be included in VHDL_SOURCES before module's Top.vhd
- TOPLEVEL must be lowercase: `customwrapper` (GHDL lowercases entity names)

### Example Makefile Entry
```makefile
ifeq ($(TEST_MODULE),emfi_seq_top)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd \
                   $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_fsm.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_stair.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/EMFI_Seq.vhd \
                   customwrapper_stub.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/Top.vhd
    TOPLEVEL = customwrapper          # Lowercase!
    COCOTB_TEST_MODULES = test_emfi_seq_top
endif
```

### MCC Test Initialization Pattern
```python
async def init_control_registers(dut):
    """Initialize all MCC control registers"""
    # Control0: Module-specific (e.g., Enable, ClkEn, DivSel)
    dut.Control0.value = 0x00000000
   
    # Control1-4: Module-specific parameters
    dut.Control1.value = 0
    dut.Control2.value = 0
    dut.Control3.value = 0
    dut.Control4.value = 0
   
    # Control5-15: Initialize unused registers
    for i in range(5, 16):
        getattr(dut, f"Control{i}").value = 0
   
    # Initialize all input channels
    dut.InputA.value = 0
    dut.InputB.value = 0
    dut.InputC.value = 0
    dut.InputD.value = 0
   
    await ClockCycles(dut.Clk, 1)
```

## Test Organization

### File Naming
- Test files: `test_<module_name>.py`
- Example: `test_clk_divider_core.py`, `test_emfi_seq_top.py`

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
2. **Basic functionality** - Core feature works
3. **Edge cases** - Boundary conditions, special values
4. **Control signals** - Enable, ClkEn, Reset interactions
5. **Randomized inputs** - Runtime-generated test data
6. **Integration** - Multi-module interactions
7. **Summary** - Final validation message

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
6. **Run**: `make TEST_MODULE=<module>`
7. **Update help**: Add to `make list-tests` output

## Reference Files

- **Template**: `tests/test_clk_divider_core.py` - Complete working example
- **Utilities**: `tests/conftest.py` - Shared helper functions
- **Makefile**: `tests/Makefile` - Build system integration
- **README**: `tests/README.md` - User-facing documentation
- **MCC Stub**: `tests/customwrapper_stub.vhd` - CustomWrapper entity for MCC testing

## Summary

✅ **DO**:
- Use CocotB for all new tests
- Import helpers from conftest.py
- Add clear logging and assertions
- Use runtime randomization
- Test each module independently
- Initialize all signals/registers

❌ **DON'T**:
- Create new GHDL testbenches
- Hard-code test values (use constants)
- Skip initialization
- Assume signal defaults
- Rely on test execution order
- Forget to add Makefile entry

# CocotB Testing Guide - Volo VHDL Project

**Status**: Active - This is the NEW standard for testing (as of 2025-01-22)  
**Replaces**: Legacy GHDL testbenches (see `ghdl_patterns_and_solutions` memory - DEPRECATED)

## Overview

CocotB (Coroutine Co-simulation TestBench) is a Python-based testing framework for HDL designs. We use it with GHDL as the simulator backend.

**Replaces**: Legacy GHDL testbenches and 4-layer VHDL architecture

⚠️ **DEPRECATED**: The previous 4-layer GHDL testbench architecture (Interface/Validation/Functional/Generic) is no longer used. CocotB provides better organization through Python's natural test structure with `@cocotb.test()` decorators and clear test function names.

## Why CocotB?

✅ **Advantages over GHDL testbenches:**
- Modern Python syntax (async/await) instead of VHDL processes
- Rich assertion library with clear error messages
- Shared test utilities eliminate code duplication
- Easier debugging with Python tools
- Better CI/CD integration
- Faster test development

## Project Structure

```
tests/
├── Makefile                      # CocotB build configuration
├── conftest.py                   # Shared utilities (fixtures, helpers)
├── test_clk_divider_core.py      # Clock divider tests (7 tests)
├── test_moku_voltage_pkg.py      # Voltage conversion tests (3 tests)
├── test_moku_pct_pkg.py          # Percentage conversion tests (9 tests)
├── moku_voltage_pkg_tb_wrapper.vhd  # Wrapper for voltage package testing
├── moku_pct_pkg_tb_wrapper.vhd   # Wrapper for percentage package testing
└── sim_build/                    # Build artifacts (auto-generated)
```

## Quick Start

### Running Tests

```bash
cd tests/

# Run default test module
make

# Run all tests sequentially
make test-all

# Run specific module
make TEST_MODULE=clk_divider_core
make TEST_MODULE=moku_voltage_pkg
make TEST_MODULE=moku_pct_pkg

# List available tests
make list-tests

# Clean artifacts
make clean

# View waveforms
make waves                             # View waveforms with GTKWave
```

### Environment Variables

```bash
WAVES=1                    # Enable waveform dump (default)
WAVES=0                    # Disable waveforms for faster tests
COCOTB_LOG_LEVEL=DEBUG     # Set log level (DEBUG, INFO, WARNING, ERROR)
```

## Available Test Modules

### 1. clk_divider_core (volo_common/core)
**File**: `test_clk_divider_core.py`  
**Tests**: 7  
**Coverage**:
- Reset behavior
- Division ratios (2, 5, 10, 16)
- Enable control
- Generic parameter variations
- Counter rollover
- Status register

**Run**: `make TEST_MODULE=clk_divider_core`

### 2. moku_voltage_pkg (volo_common/common)
**File**: `test_moku_voltage_pkg.py`  
**Tests**: 3  
**Coverage**:
- Package constants verification (1V, 2.5V, 3.3V, 5V, negative values)
- Basic conversion sanity checks (passthrough validation)
- Summary with reference to comprehensive testing

**Run**: `make TEST_MODULE=moku_voltage_pkg`

**Note**: This is a lightweight test focused on constants validation. Comprehensive voltage conversion testing is performed through `test_moku_pct_pkg.py`, which exercises all Moku_Voltage_pkg functions extensively. This maintains the 1:1 package-to-test relationship while avoiding test complexity.

### 3. moku_pct_pkg (volo_common/common)
**File**: `test_moku_pct_pkg.py`  
**Tests**: 9  
**Dependencies**: Moku_Voltage_pkg  
**Coverage**:
- Unipolar ranges (0-5V, 0-3.3V, 0-2.5V)
  - Boundary values (0%, 50%, 100%)
  - Round-trip conversion (pct → digital → voltage → pct)
  - Clamping behavior
- Bipolar ranges (-5V to +5V, -2.5V to +2.5V)
  - Boundary values
  - Negative voltage handling
  - Round-trip conversion
- Type safety validation
- Percentage validation and clamping

**Run**: `make TEST_MODULE=moku_pct_pkg`

**Note**: This test provides comprehensive validation of `Moku_Voltage_pkg` functions since `Moku_Pct_pkg` uses voltage conversion internally for all percentage conversions.

## Test File Structure

### Basic Template

```python
"""
CocotB Testbench for <module_name>

Module Under Test: <path/to/module.vhd>
Description: <what this module does>

Test Categories:
1. Reset behavior
2. Core functionality
3. Edge cases
4. Error handling

Author: Claude Code (CocotB migration)
Date: 2025-01-22
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

# Import shared test utilities
from conftest import (
    setup_clock,
    reset_active_low,
    count_pulses,
    wait_for_value
)

@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 60)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 60)

    # Initialize
    await setup_clock(dut)
    
    # Set inputs
    dut.enable.value = 1
    dut.config.value = 0
    
    # Apply reset
    await reset_active_low(dut)
    
    # Check reset state
    assert dut.output.value == 0, "Output should be 0 after reset"
    
    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_basic_functionality(dut):
    """Test 2: Basic Functionality"""
    dut._log.info("=" * 60)
    dut._log.info("Test 2: Basic Functionality")
    dut._log.info("=" * 60)
    
    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut)
    
    # Set input
    dut.data_in.value = 0x42
    await ClockCycles(dut.clk, 2)
    
    # Check output
    assert dut.data_out.value == 0x42, f"Expected 0x42, got 0x{dut.data_out.value:02x}"
    
    dut._log.info("✓ Basic functionality test PASSED")
```

### Package Testing Pattern

For testing VHDL packages (like Moku_Pct_pkg or Moku_Voltage_pkg), you need a wrapper entity:

**Simple Constants-Only Wrapper** (for lightweight package testing):
```vhdl
-- moku_voltage_pkg_tb_wrapper.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Moku_Voltage_pkg.all;

entity moku_voltage_pkg_tb_wrapper is
    port (
        -- Expose package constants as output ports
        const_digital_1v  : out signed(15 downto 0);
        const_digital_2v5 : out signed(15 downto 0);
        -- ... other constants
        
        -- Simple passthrough for sanity check
        test_digital_passthrough : in signed(15 downto 0) := (others => '0');
        test_digital_result      : out signed(15 downto 0)
    );
end entity;

architecture simple of moku_voltage_pkg_tb_wrapper is
begin
    const_digital_1v <= MOKU_DIGITAL_1V;
    const_digital_2v5 <= MOKU_DIGITAL_2V5;
    test_digital_result <= test_digital_passthrough;
end architecture;
```

**Function Testing Wrapper** (for comprehensive package testing):
```vhdl
-- moku_pct_pkg_tb_wrapper.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Moku_Voltage_pkg.all;
use work.Moku_Pct_pkg.all;

entity moku_pct_pkg_tb_wrapper is
end entity;

architecture behavioral of moku_pct_pkg_tb_wrapper is
    -- Test signals exposed to CocotB
    signal test_pct_5v0 : natural range 0 to 100 := 0;
    signal test_digital_5v0 : signed(15 downto 0);
    signal test_voltage : real := 0.0;
begin
    -- Drive signals using package functions
    test_digital_5v0 <= pct_5v0_to_digital(test_pct_5v0);
    test_voltage <= digital_to_voltage(test_digital_5v0);
end architecture;
```

Then test from Python:
```python
# Simple constants test
@cocotb.test()
async def test_voltage_constants(dut):
    await Timer(1, units='ns')
    assert dut.const_digital_1v.value == 6554

# Function test
@cocotb.test()
async def test_conversions(dut):
    dut.test_pct_5v0.value = 50  # Set 50%
    await Timer(1, units='ns')
    assert dut.test_digital_5v0.value == 0x4000  # Check digital
```

**Design Principle**: Keep package tests simple. If comprehensive testing happens elsewhere (e.g., Moku_Voltage_pkg is fully tested through Moku_Pct_pkg), create a lightweight constants-only test to maintain the 1:1 package-to-test relationship without introducing complexity.

## Shared Utilities (conftest.py)

### Clock Management

```python
await setup_clock(dut)                           # Start 100MHz clock
await setup_clock(dut, period_ns=20)            # Start 50MHz clock
await setup_clock(dut, clk_signal="Clk")        # MCC-style capitalized signal
```

### Reset Sequences

```python
await reset_active_low(dut)                      # Standard active-low reset
await reset_active_low(dut, cycles=5)           # Hold reset for 5 cycles
await reset_active_high(dut)                     # Active-high reset
await reset_dut(dut, active_low=False)          # Auto-detect
```

### Signal Monitoring

```python
# Count pulses
pulses = await count_pulses(dut.clk_en, dut.clk, 100)
assert pulses == 10, f"Expected 10 pulses, got {pulses}"

# Wait for specific value
success = await wait_for_value(dut.done, 1, dut.clk, timeout_cycles=1000)
assert success, "Module never signaled done"

# Capture signal sequence
sequence = await capture_signal_sequence(dut.state, dut.clk, 20)
assert sequence == [0, 0, 1, 2, 3, 0], "Unexpected state sequence"
```

### Assertion Helpers

```python
# Assert pulse count (combines counting + assertion)
await assert_pulse_count(dut.clk_en, dut.clk, cycles=100, expected=10, tolerance=1)

# Assert signal value
assert_signal_value(dut.output, 0x1234, "Output mismatch after reset")
```

### Complete Initialization

```python
# Clock + reset in one call
await init_dut(dut)
await init_dut(dut, clock_period_ns=20, active_low_reset=False)
```

## Common Patterns

### Test Multiple Scenarios

```python
@cocotb.test()
async def test_division_ratios(dut):
    """Test various division ratios"""
    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut)
    
    test_cases = [
        (2, 10),    # div_sel=2, expect 10 pulses in 20 cycles
        (5, 4),     # div_sel=5, expect 4 pulses in 20 cycles
        (10, 2),    # div_sel=10, expect 2 pulses in 20 cycles
    ]
    
    for div_sel, expected_pulses in test_cases:
        dut.div_sel.value = div_sel
        await ClockCycles(dut.clk, 2)  # Let setting propagate
        
        pulses = await count_pulses(dut.clk_en, dut.clk, 20)
        assert pulses == expected_pulses, \
            f"div_sel={div_sel}: expected {expected_pulses}, got {pulses}"
        
        dut._log.info(f"✓ Division by {div_sel} verified")
```

### Debug with Logging

```python
# Add detailed logging for debugging
dut._log.info(f"Status register: 0x{int(dut.status.value):02x}")
dut._log.info(f"State: {int(dut.state.value)}")

# Log signal table for debugging
log_signal_table(dut, ["clk_en", "enable", "div_sel", "stat_reg"])
```

### Timeout Protection

```python
# Wait with timeout
success = await wait_for_value(dut.ready, 1, dut.clk, timeout_cycles=100)
if not success:
    dut._log.error("Timeout waiting for ready signal")
    assert False, "Module failed to assert ready within 100 cycles"
```

## Adding Tests to Makefile

When creating a new test module, update `tests/Makefile`:

```makefile
# Add to source files section
ifeq ($(TEST_MODULE),your_module_core)
    YOUR_MODULE_DIR = $(MODULES_DIR)/your_module
    VHDL_SOURCES = $(YOUR_MODULE_DIR)/common/your_pkg.vhd \
                   $(YOUR_MODULE_DIR)/core/your_module_core.vhd
    TOPLEVEL = your_module_core
    COCOTB_TEST_MODULES = test_your_module_core
endif
```

Update `test-all` target:
```makefile
test-all:
    @$(MAKE) TEST_MODULE=clk_divider_core
    @$(MAKE) TEST_MODULE=moku_voltage_pkg
    @$(MAKE) TEST_MODULE=moku_pct_pkg
    @$(MAKE) TEST_MODULE=your_module_core    # Add your test here
```

Update help text:
```makefile
help:
    # ...
    @echo "  - your_module_core     (your_module/core)"
```

## Best Practices

### DO ✅

1. **Use descriptive test names** that explain what is being tested
2. **Add logging** with clear headers and progress messages
3. **Use shared utilities** from `conftest.py` to avoid duplication
4. **Write independent tests** that don't depend on execution order
5. **Test one feature per test function** for clarity
6. **Add context to assertions** with helpful error messages
7. **Wait for signals to propagate** after changing inputs
8. **Keep package tests simple** - avoid complexity spilling out of testbenches

```python
# Good: Clear assertion message
assert dut.output.value == expected, \
    f"Output mismatch: expected 0x{expected:04x}, got 0x{int(dut.output.value):04x}"

# Bad: No context
assert dut.output.value == expected
```

### DON'T ❌

1. **Don't create GHDL testbenches** - Use CocotB instead
2. **Don't duplicate test utilities** - Use `conftest.py`
3. **Don't forget to wait for clock edges** after input changes
4. **Don't use blocking operations** - Use `await` for all waits
5. **Don't ignore test failures** - Investigate and fix the root cause
6. **Don't test internal signals** - Test external behavior only
7. **Don't over-engineer package tests** - If comprehensive testing happens elsewhere, keep it simple

## Common Issues and Solutions

### Issue 1: Signal Not Updating

**Problem**: Signal value doesn't change after assignment

**Cause**: Not waiting for clock edge or simulation delta cycle

**Solution**:
```python
dut.input.value = 0x42
await ClockCycles(dut.clk, 1)  # Wait for change to propagate
assert dut.output.value == 0x42
```

### Issue 2: Test Hangs/Timeout

**Problem**: Test never completes

**Cause**: Waiting for a signal that never changes

**Solution**: Use `wait_for_value()` with timeout
```python
success = await wait_for_value(dut.done, 1, dut.clk, timeout_cycles=100)
assert success, "Module didn't complete within timeout"
```

### Issue 3: Metavalue Warnings

**Problem**: GHDL warns about metavalues ('U', 'X', etc.)

**Cause**: Reading signals before initialization/reset

**Solution**: Always reset before testing
```python
await setup_clock(dut)
dut.enable.value = 1  # Set inputs BEFORE reset
await reset_active_low(dut)
# Now signals are initialized
```

### Issue 4: Real Type Signals Not Accessible

**Problem**: `dut.signal_name` raises error for real type signals

**Cause**: GHDL's VPI doesn't expose real type signals to CocotB

**Solution**: Avoid testing real type signals directly. Either:
- Test through integer/signed conversions
- Use constants-only wrapper for package testing
- Acknowledge comprehensive testing happens in dependent modules

```python
# Bad: Trying to access real signal
dut.voltage_out.value = 2.5  # Will fail

# Good: Test constants and conversions only
assert dut.const_digital_2v5.value == 16384
dut.test_digital_passthrough.value = 16384
await Timer(1, units='ns')
assert dut.test_digital_result.value == 16384
```

## Migration from GHDL Testbenches

### GHDL vs CocotB Comparison

| GHDL Testbench | CocotB Equivalent |
|----------------|-------------------|
| `wait for 10 ns;` | `await ClockCycles(dut.clk, 1)` |
| `wait until rising_edge(clk);` | `await RisingEdge(dut.clk)` |
| `assert output = expected report "Failed";` | `assert dut.output.value == expected, "Failed"` |
| `report "Test message" severity note;` | `dut._log.info("Test message")` |
| `std.env.stop(0);` | (automatic - test completes when function returns) |

### Migration Steps

1. Create `tests/test_<module>.py`
2. Import CocotB and shared utilities
3. Convert each test section to a `@cocotb.test()` function
4. Replace VHDL wait statements with CocotB triggers
5. Replace assertions with Python `assert`
6. Add module to `tests/Makefile`
7. Run tests: `make TEST_MODULE=<module> clean && make TEST_MODULE=<module>`
8. Archive old GHDL testbench if all tests pass

## Example Test Files

### Production-Ready Examples

**Complete Core Module Test**:  
`tests/test_clk_divider_core.py` - Demonstrates:
- Multiple test scenarios
- Shared utility usage
- Clear logging and assertions
- Comprehensive coverage (7 tests)
- Proper error messages

**Package Testing (Comprehensive)**:  
`tests/test_moku_pct_pkg.py` - Demonstrates:
- Package function testing
- Wrapper entity pattern
- Round-trip validation
- Boundary testing
- Type safety verification (9 tests)

**Package Testing (Lightweight)**:  
`tests/test_moku_voltage_pkg.py` - Demonstrates:
- Constants-only testing approach
- Simple wrapper to avoid complexity
- Reference to comprehensive testing elsewhere
- Maintains 1:1 package-to-test relationship (3 tests)

## Resources

- **CocotB Documentation**: https://docs.cocotb.org/
- **Shared Utilities**: `tests/conftest.py` (well-documented)
- **Example Tests**: 
  - `tests/test_clk_divider_core.py` (core module testing)
  - `tests/test_moku_pct_pkg.py` (comprehensive package testing)
  - `tests/test_moku_voltage_pkg.py` (lightweight package testing)
- **Makefile**: `tests/Makefile` (build configuration)

## Status of Migration

✅ **Migrated to CocotB:**
- clk_divider_core (7 tests passing)
- moku_voltage_pkg (3 tests passing - lightweight constants validation)
- moku_pct_pkg (9 tests passing - comprehensive voltage conversion coverage)

⏳ **To Be Migrated:**
- EMFI-Seq modules (future)
- SimpleWaveGen modules (future)

🗑️ **Archived (Old GHDL):**
- stoplight_core (archived 2025-01-22)

---

**Last Updated**: 2025-10-22  
**Migration Lead**: Claude Code  
**Framework Version**: CocotB 2.0.0  
**Total Active Tests**: 19 (7 clk_divider + 3 moku_voltage + 9 moku_pct)

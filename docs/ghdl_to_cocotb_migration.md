# GHDL to CocotB Migration Guide

**Status**: Active Migration
**Date**: 2025-01-22
**Branch**: `feature/coco_tb_transition`

---

## Executive Summary

The Volo VHDL project is transitioning from native GHDL VHDL testbenches to Python-based CocotB testbenches. This document captures:
- The rationale for this transition
- Lessons learned from GHDL testbench development
- Migration strategy and checklist
- What to preserve and what to purge

---

## Table of Contents

1. [Why Transition to CocotB?](#why-transition-to-cocotb)
2. [GHDL Testbench Pain Points](#ghdl-testbench-pain-points)
3. [Lessons Learned from GHDL](#lessons-learned-from-ghdl)
4. [CocotB Advantages](#cocotb-advantages)
5. [Migration Strategy](#migration-strategy)
6. [What to Preserve](#what-to-preserve)
7. [Testbench Purge Checklist](#testbench-purge-checklist)
8. [CocotB Best Practices](#cocotb-best-practices)

---

## Why Transition to CocotB?

### Current State (GHDL Testbenches)

The project accumulated native VHDL testbenches with increasing complexity and fragility:
- Complex workarounds for VHDL-2008 language restrictions
- Difficult debugging with limited introspection
- Verbose test code requiring VHDL expertise
- Limited reusability across modules
- Slow iteration cycle (edit VHDL → recompile → re-elaborate → run)

### Desired State (CocotB Testbenches)

CocotB provides:
- Python-based test development (faster iteration)
- Rich ecosystem of testing libraries (pytest, coverage, etc.)
- Better debugging with Python tools (print, debugger, logging)
- Easier data manipulation and comparison
- Test reusability through Python modules
- No recompilation needed for test changes
- Industry-standard verification methodology

---

## GHDL Testbench Pain Points

### 1. Shared Variables Require Protected Types (VHDL-2008)

**The Problem:**
```vhdl
-- VHDL-93 allowed this, VHDL-2008 forbids it
shared variable test_count : natural := 0;  -- ❌ Compilation error

-- Workaround 1: Move to local variables inside process
process
    variable test_count : natural := 0;  -- ✅ Works but limits scope
begin
    -- All helper procedures must also be inside process
end process;

-- Workaround 2: Use signals (adds timing complexity)
signal test_count : natural := 0;  -- ✅ Works but requires wait for 0 ns

-- Workaround 3: Define protected types (overly complex)
type test_counter_type is protected
    procedure increment;
    impure function get_count return natural;
end protected;
```

**Why This Was Painful:**
- Simple test counters required complex workarounds
- Moving code between process/architecture required refactoring
- Protected types are overkill for simple testbenches

**CocotB Solution:**
```python
# Python: Simple, natural variable scoping
test_count = 0
pass_count = 0

def check_test(name, condition):
    global test_count, pass_count
    test_count += 1
    if condition:
        pass_count += 1
```

---

### 2. Variable Shadowing Warnings

**The Problem:**
```vhdl
function offset_voltage(voltage : real; offset : real) return real is
    variable offset_voltage : real;  -- ⚠️ Shadows function name
begin
    offset_voltage := voltage + offset;
    return clamp_voltage_safe(offset_voltage);
end function;

-- Solution: Use different names
function offset_voltage(voltage : real; offset : real) return real is
    variable result_voltage : real;  -- ✅ Clear but verbose
begin
    result_voltage := voltage + offset;
    return clamp_voltage_safe(result_voltage);
end function;
```

**Why This Was Painful:**
- Natural naming conventions trigger warnings
- Forces verbose variable names
- Mental overhead tracking which names are "taken"

**CocotB Solution:**
```python
# Python: No shadowing issues, clear scoping
def offset_voltage(voltage, offset):
    result = voltage + offset
    return clamp_voltage_safe(result)
```

---

### 3. String/Bit Width Mismatches

**The Problem:**
```vhdl
status_reg(6 downto 3) <= "000";   -- ❌ 3 bits assigned to 4-bit slice
status_reg(6 downto 3) <= "0000";  -- ✅ Must match exactly
```

**Why This Was Painful:**
- Easy to miscount bits
- Compiler error messages not always clear
- Verbose syntax for bit manipulation

**CocotB Solution:**
```python
# Python: More flexible, explicit
status_reg = 0x0000
status_reg |= (wave_select & 0x7)  # Mask handles width automatically
```

---

### 4. Real Number Comparison Issues

**The Problem:**
```vhdl
-- Direct comparison fails due to floating-point precision
assert voltage_out = 1.2 report "Test failed" severity error;  -- ❌ Fragile

-- Need custom tolerance functions
constant TOLERANCE : real := 0.01;
function real_equal(a, b : real; tol : real := TOLERANCE) return boolean is
begin
    return abs(a - b) < tol;
end function;

-- Then use in tests
assert real_equal(voltage_out, 1.2) report "Test passed" severity note;  -- ✅ Verbose
```

**Why This Was Painful:**
- Required custom helper functions for every testbench
- Verbose syntax for simple comparisons
- Different approaches across testbenches

**CocotB Solution:**
```python
# Python: Built-in support, clear syntax
import pytest
assert voltage_out == pytest.approx(1.2, abs=0.01)

# Or using numpy
import numpy as np
assert np.isclose(voltage_out, 1.2, atol=0.01)
```

---

### 5. Complex Timing and Clock Management

**The Problem:**
```vhdl
-- Manual clock generation
clk_process : process
begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
end process;

-- Manual clock enable patterns
clk_en_process : process
begin
    clk_en <= '0';
    wait for CLK_PERIOD * 3;
    clk_en <= '1';
    wait for CLK_PERIOD;
end process;

-- Manual waiting in tests
wait until clk_en = '1';  -- Can hang if signal never goes high
wait for CLK_PERIOD * 5;
wait until rising_edge(clk);
```

**Why This Was Painful:**
- Boilerplate clock generation in every testbench
- Easy to create timing bugs (race conditions)
- Hard to debug when waits don't return
- Timeout logic adds complexity

**CocotB Solution:**
```python
# CocotB: Built-in clock utilities
from cocotb.clock import Clock
await cocotb.start(Clock(dut.clk, 10, units="ns"))

# Elegant edge waiting
await RisingEdge(dut.clk)
await FallingEdge(dut.clk_en)

# Timeout built-in
await with_timeout(RisingEdge(dut.done), 100, 'ns')
```

---

### 6. Limited Debugging Capabilities

**The Problem:**
```vhdl
-- Debugging limited to report statements
report "Debug: wave_out = " & to_hstring(wave_out) severity note;
report "Debug: fault = " & std_logic'image(fault_out) severity note;

-- No interactive debugging
-- No easy way to inspect internal signals during development
-- Limited control flow introspection
```

**Why This Was Painful:**
- Print-based debugging only
- No breakpoints or interactive inspection
- Recompile required for debug changes
- Hard to trace complex test failures

**CocotB Solution:**
```python
# Python: Rich debugging ecosystem
print(f"Debug: wave_out = {dut.wave_out.value:#x}")
dut._log.info(f"Testing wave_select={wave_select}")

# Interactive debugging
import pdb; pdb.set_trace()

# Logging framework
import logging
logger = logging.getLogger(__name__)
logger.debug(f"State transition: {old_state} -> {new_state}")
```

---

### 7. Test Reusability and Organization

**The Problem:**
```vhdl
-- Every testbench duplicates common patterns
-- No easy way to share test utilities
-- Helper procedures must be duplicated or moved to packages

-- Example: Test reporting duplicated across testbenches
procedure check_test(test_name : string; condition : boolean) is
begin
    test_count := test_count + 1;
    if condition then
        report "PASS: " & test_name severity note;
    else
        report "FAIL: " & test_name severity error;
    end if;
end procedure;
```

**Why This Was Painful:**
- Code duplication across testbenches
- Inconsistent test reporting styles
- Difficult to refactor common patterns
- No standard test framework

**CocotB Solution:**
```python
# Python: Reusable test utilities
from volo_testlib import check_test, TestCounter, ClockManager

# Standard pytest integration
import pytest

@pytest.mark.parametrize("div_sel,expected", [
    (0, 1),   # Divide by 1
    (1, 2),   # Divide by 2
    (255, 256)  # Divide by 256
])
async def test_clock_divider(dut, div_sel, expected):
    """Parameterized test - runs 3x automatically"""
    pass
```

---

## Lessons Learned from GHDL

### What GHDL Taught Us (Preserve These Insights)

#### 1. **Proper Initialization is Critical**
```vhdl
-- GHDL enforced this lesson well
signal data : std_logic_vector(15 downto 0) := (others => '0');  -- ✅ Explicit init
```

**Lesson for CocotB:** Always initialize DUT inputs before first clock edge:
```python
# Apply before starting clock
dut.rst.value = 1
dut.enable.value = 0
dut.div_sel.value = 0
await cocotb.start(Clock(dut.clk, 10, units="ns"))
```

#### 2. **Reset Testing is Essential**
```vhdl
-- GHDL testbenches always tested reset behavior first
rst <= '1';
wait for CLK_PERIOD * 2;
rst <= '0';
wait for CLK_PERIOD;
check_test("Reset state", output = expected_reset_value);
```

**Lesson for CocotB:** Reset tests should be first in every testbench:
```python
async def test_reset_behavior(dut):
    """Always test reset first"""
    dut.rst.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    assert dut.output.value == 0x0000, "Reset should clear output"
```

#### 3. **Separation of Concerns**
```vhdl
-- GHDL taught us to separate processes
clk_process : process       -- Clock generation
test_process : process      -- Test stimulus
validation_process : process -- Parameter validation
```

**Lesson for CocotB:** Separate test concerns into different coroutines:
```python
@cocotb.test()
async def test_basic_operation(dut):
    """Main test"""
    pass

@cocotb.test()
async def test_error_conditions(dut):
    """Error handling"""
    pass

async def monitor_status(dut):
    """Separate monitoring coroutine"""
    while True:
        await RisingEdge(dut.clk)
        if dut.fault.value:
            dut._log.warning("Fault detected!")
```

#### 4. **Timing Awareness**
```vhdl
-- GHDL made timing explicit and visible
wait for CLK_PERIOD;        -- One clock cycle
wait until rising_edge(clk);  -- Synchronous to clock
```

**Lesson for CocotB:** Maintain explicit timing control:
```python
# Don't just wait arbitrary time
await Timer(100, units='ns')  # ❌ Fragile, clock-independent

# Synchronize to clock edges
await RisingEdge(dut.clk)  # ✅ Robust
await ClockCycles(dut.clk, 5)  # ✅ Clear intent
```

#### 5. **Direct Instantiation Pattern**
```vhdl
-- GHDL enforced direct instantiation in this project
DUT: entity WORK.my_module
    port map (
        clk => clk,
        rst => rst
    );
```

**Lesson for CocotB:** This taught us clean module hierarchy. In CocotB, DUT access is equally clean:
```python
# CocotB provides clean DUT access automatically
dut.clk      # Direct port access
dut.rst      # No complex binding needed
```

#### 6. **Comprehensive Test Reporting**
```vhdl
-- GHDL testbenches developed good reporting patterns
report "========================================" severity note;
report "Test Summary:" severity note;
report "  Total tests: " & integer'image(test_count) severity note;
report "  Passed:      " & integer'image(pass_count) severity note;
report "========================================" severity note;

if fail_count = 0 then
    report "ALL TESTS PASSED" severity note;
else
    report "TEST FAILED" severity error;
end if;
```

**Lesson for CocotB:** Maintain comprehensive reporting using pytest:
```python
# pytest provides this automatically
# Custom reporting in conftest.py
def pytest_terminal_summary(terminalreporter, exitstatus, config):
    terminalreporter.write_sep("=", "Volo VHDL Test Summary")
    terminalreporter.write_line(f"Total: {terminalreporter.stats}")
```

---

## CocotB Advantages

### 1. **Python Ecosystem**
- Access to NumPy, SciPy, matplotlib for data analysis
- pytest framework for test organization
- Rich assertion libraries
- Easy file I/O for test vectors

### 2. **Faster Iteration**
```bash
# GHDL workflow (slow)
edit testbench.vhd → ghdl -a → ghdl -e → ghdl -r

# CocotB workflow (fast)
edit test.py → make  # No recompilation of test code!
```

### 3. **Better Data Structures**
```python
# Easy test vector management
test_vectors = [
    {"div_sel": 0, "expected_period": 1},
    {"div_sel": 1, "expected_period": 2},
    {"div_sel": 10, "expected_period": 11},
]

for tv in test_vectors:
    dut.div_sel.value = tv["div_sel"]
    # Test...
```

### 4. **Waveform Analysis**
```python
# Can generate plots directly from tests
import matplotlib.pyplot as plt
await capture_waveform(dut.output, cycles=100)
plt.plot(waveform_data)
plt.savefig("output_waveform.png")
```

### 5. **Coverage Analysis**
```python
# Integration with coverage tools
# pytest-cov provides automatic coverage reporting
# Can track which design states were exercised
```

---

## Migration Strategy

### Phase 1: Infrastructure Setup (Current)
- [ ] Create CocotB test directory structure
- [ ] Set up Makefile integration with GHDL
- [ ] Create base test utilities (volo_testlib)
- [ ] Document CocotB patterns for this project
- [ ] Create example tests for reference modules

### Phase 2: Parallel Testing
- [ ] Write CocotB tests for new modules
- [ ] Keep existing GHDL tests running (verify equivalence)
- [ ] Compare coverage between GHDL and CocotB tests
- [ ] Identify gaps

### Phase 3: Purge Legacy Tests
- [ ] Verify CocotB tests cover all GHDL test cases
- [ ] Archive GHDL testbenches (don't delete immediately)
- [ ] Remove from build system
- [ ] Update documentation to reference CocotB tests

### Phase 4: Continuous Improvement
- [ ] Expand test coverage using CocotB capabilities
- [ ] Add regression test suite
- [ ] Integrate with CI/CD
- [ ] Add formal verification where applicable

---

## What to Preserve

### Keep These GHDL Files (For Now)
```
ai-workflow/ng/README-ghdl-testbench-tips-ng.md  # Reference documentation
ai-workflow/ng/README-synth-vhdl-tips-ng.md      # RTL patterns (not testbench)
docs/ghdl_to_cocotb_migration.md                 # This document
```

### Archive These GHDL Testbenches
Move to `archive/ghdl_testbenches/` before deletion:
```
modules/*/tb/**/*_tb.vhd
modules/volo_common/tb/core/clk_divider_core_tb.vhd
modules/SimpleWaveGen/tb/core/simplewavegen_core_tb.vhd
modules/SimpleWaveGen/tb/top/simplewavegen_top_tb.vhd
modules/EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd
modules/stoplight/tb/core/stoplight_core_tb.vhd
modules/stoplight/tb/top/stoplight_top_tb.vhd
```

### Delete These Patterns (After Archive)
```bash
# Compiled artifacts
**/*.o
**/work-obj*.cf
**/*_tb (executables)

# Testbench source (after archiving)
**/tb/**/*_tb.vhd
```

---

## Testbench Purge Checklist

Before purging a GHDL testbench:

- [ ] **Document what it tested** - List test cases in migration notes
- [ ] **CocotB replacement exists** - Equivalent or better coverage
- [ ] **Run final comparison** - Both tests pass on same RTL
- [ ] **Archive source** - Move to `archive/ghdl_testbenches/YYYY-MM-DD/`
- [ ] **Update Makefile** - Remove from build targets
- [ ] **Update documentation** - Reference CocotB test instead
- [ ] **Commit changes** - Clear commit message explaining purge

### Example Purge Commit Message
```
Purge GHDL testbench: clk_divider_core_tb.vhd

Replaced with CocotB test: tests/test_clk_divider_core.py

The CocotB test provides equivalent coverage plus:
- Parameterized testing for all division ratios
- Automatic edge case generation
- Better timing verification

Original GHDL testbench archived to:
archive/ghdl_testbenches/2025-01-22/clk_divider_core_tb.vhd
```

---

## CocotB Best Practices (For This Project)

### 1. Test Structure
```python
"""
Module: test_clk_divider_core.py
Tests: volo_common/core/clk_divider_core.vhd

Test Categories:
1. Reset behavior
2. Division ratios (0-255)
3. Enable control
4. Edge cases (0, 1, MAX_DIV, overflow)
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import pytest

@cocotb.test()
async def test_reset(dut):
    """Test reset behavior"""
    clock = Clock(dut.clk, 10, units="ns")
    await cocotb.start(clock)

    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)

    # Check reset state
    assert dut.clk_en.value == 0, "clk_en should be low after reset"
    assert dut.stat_reg.value == 0, "counter should be zero after reset"

    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
```

### 2. Use Fixtures for Common Setup
```python
# conftest.py
import pytest
import cocotb

@pytest.fixture
async def setup_clock(dut):
    """Standard clock setup for all tests"""
    clock = Clock(dut.clk, 10, units="ns")
    await cocotb.start(clock)
    return clock

@pytest.fixture
async def reset_dut(dut, setup_clock):
    """Apply standard reset sequence"""
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
```

### 3. Parameterized Testing
```python
@pytest.mark.parametrize("div_sel,expected_ratio", [
    (0, 1),     # Divide by 1
    (1, 2),     # Divide by 2
    (10, 11),   # Divide by 11
    (255, 256), # Maximum division
])
@cocotb.test()
async def test_division_ratios(dut, div_sel, expected_ratio, setup_clock, reset_dut):
    """Test various division ratios"""
    dut.div_sel.value = div_sel
    dut.enable.value = 1

    # Count clock enables over known period
    clk_en_count = 0
    for _ in range(expected_ratio * 10):
        await RisingEdge(dut.clk)
        if dut.clk_en.value == 1:
            clk_en_count += 1

    expected_count = 10
    assert clk_en_count == expected_count, \
        f"div_sel={div_sel}: expected {expected_count} enables, got {clk_en_count}"
```

### 4. Logging and Debug Output
```python
@cocotb.test()
async def test_with_logging(dut):
    """Example with good logging"""
    dut._log.info("Starting test")
    dut._log.debug(f"Initial state: clk_en={dut.clk_en.value}")

    # Test code...

    if dut.stat_reg.value != expected:
        dut._log.error(f"Expected {expected:#x}, got {dut.stat_reg.value:#x}")
        assert False

    dut._log.info("Test passed")
```

### 5. Timeout Protection
```python
from cocotb.triggers import with_timeout, TimeoutError

@cocotb.test()
async def test_with_timeout(dut):
    """Prevent infinite waits"""
    try:
        await with_timeout(
            RisingEdge(dut.done),
            100, 'ns'
        )
    except TimeoutError:
        dut._log.error("Timeout waiting for done signal")
        assert False, "Test timed out"
```

---

## Migration Checklist for Each Module

### Pre-Migration Inventory
- [ ] List all existing GHDL testbenches for module
- [ ] Document test coverage (what scenarios are tested)
- [ ] Identify test utilities used
- [ ] Note any special timing requirements

### CocotB Test Development
- [ ] Create `tests/test_<module>.py`
- [ ] Write equivalent tests in CocotB
- [ ] Add additional tests (leverage CocotB advantages)
- [ ] Verify coverage matches or exceeds GHDL

### Validation
- [ ] Run both GHDL and CocotB tests on same RTL
- [ ] Compare results (both should pass)
- [ ] Check for timing differences
- [ ] Review waveforms if available

### Cleanup
- [ ] Archive GHDL testbench
- [ ] Remove from Makefile
- [ ] Update module README
- [ ] Update project documentation

---

## Frequently Asked Questions

### Q: Should we delete all GHDL testbenches immediately?
**A:** No. Archive first, verify CocotB coverage, then delete after confidence is established.

### Q: What about the GHDL tips documentation?
**A:** Keep `README-ghdl-testbench-tips-ng.md` as reference. Many patterns still apply to RTL development, just not testbenches.

### Q: Can we use both GHDL and CocotB tests?
**A:** During migration, yes. Long-term, standardize on CocotB for consistency.

### Q: What about CI/CD integration?
**A:** CocotB integrates better with modern CI/CD (pytest, coverage reports, JUnit XML output).

### Q: Will this slow down development?
**A:** Initially (learning curve), but long-term it will speed up development significantly.

---

## Next Steps

1. **Set up CocotB infrastructure** (this branch: `feature/coco_tb_transition`)
2. **Create reference test** for one simple module (e.g., `clk_divider_core`)
3. **Document patterns** that work well for this project
4. **Train team** on CocotB best practices
5. **Begin systematic migration** of existing testbenches
6. **Archive and purge** GHDL testbenches as CocotB equivalents are verified

---

## References

- **CocotB Documentation**: https://docs.cocotb.org/
- **GHDL Patterns (Preserved)**: `ghdl_patterns_and_solutions` memory
- **Project Standards**: `CLAUDE.md`, `.cursor/rules.mdc`
- **Original GHDL Tips**: `ai-workflow/ng/README-ghdl-testbench-tips-ng.md`

---

**Document History:**
- 2025-01-22: Initial creation (feature/coco_tb_transition branch)

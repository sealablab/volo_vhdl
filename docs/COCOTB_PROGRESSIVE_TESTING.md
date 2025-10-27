# CocotB Progressive Testing Strategy

## Problem Statement

The default CocotB test output is extremely verbose, which is problematic for LLM-based development workflows:
- Excessive output fills up LLM context windows quickly
- Important information gets lost in noise
- Debugging becomes harder when context is consumed by repetitive log messages

## Solution: Progressive Testing with Verbosity Control

We've implemented a **Progressive Testing Strategy** that addresses these issues:

### 1. Progressive Test Levels (P1-P4)

Tests are organized into progressive levels, allowing incremental validation:

- **P1_BASIC**: Minimal tests, LLM-friendly output (default)
  - Core functionality only
  - Small test values for speed
  - Essential assertions
  - ~10-20 lines of output total

- **P2_INTERMEDIATE**: Standard testing
  - Edge cases and boundaries
  - Larger test values
  - More thorough coverage
  - ~50-100 lines of output

- **P3_COMPREHENSIVE**: Full validation
  - All corner cases
  - Stress testing
  - Performance validation
  - ~200-500 lines of output

- **P4_EXHAUSTIVE**: Debug-level testing
  - Random testing
  - All permutations
  - Detailed diagnostics
  - Unlimited output

### 2. Verbosity Levels

Independent of test levels, output verbosity can be controlled:

- **SILENT** (0): No output except failures
- **MINIMAL** (1): Test name + PASS/FAIL only [DEFAULT for LLMs]
- **NORMAL** (2): Progress indicators + results
- **VERBOSE** (3): Detailed step-by-step output
- **DEBUG** (4): Full debug information

### 3. Per-Module Test Organization

Tests are organized in module-specific directories:

```
tests/
├── test_base.py                        # Base class with verbosity control
├── counter_nbit_tests/
│   ├── counter_nbit_constants.py       # Shared constants and configs
│   ├── P1_counter_nbit_basic.py        # Basic tests (LLM-friendly)
│   ├── P2_counter_nbit_intermediate.py # Intermediate tests
│   ├── P3_counter_nbit_comprehensive.py # Comprehensive tests
│   └── P4_counter_nbit_exhaustive.py   # Exhaustive/debug tests
├── simplewavegen_tests/
│   ├── simplewavegen_constants.py
│   ├── P1_simplewavegen_basic.py
│   └── ...
└── ...
```

## Usage

### Running Tests at Different Levels

```bash
# Default: P1 with MINIMAL verbosity (LLM-friendly)
uv run pytest tests/counter_nbit_tests/P1_counter_nbit_basic.py

# Run P2 tests (includes P1)
TEST_LEVEL=P2_INTERMEDIATE uv run pytest tests/counter_nbit_tests/P2_counter_nbit_intermediate.py

# Run all levels with normal verbosity
TEST_LEVEL=P3_COMPREHENSIVE COCOTB_VERBOSITY=NORMAL uv run pytest tests/counter_nbit_tests/P3_counter_nbit_comprehensive.py
```

### Environment Variables

```bash
# Control test progression level
export TEST_LEVEL=P1_BASIC           # Default
export TEST_LEVEL=P2_INTERMEDIATE
export TEST_LEVEL=P3_COMPREHENSIVE
export TEST_LEVEL=P4_EXHAUSTIVE

# Control output verbosity
export COCOTB_VERBOSITY=SILENT       # No output except failures
export COCOTB_VERBOSITY=MINIMAL      # Default for LLMs
export COCOTB_VERBOSITY=NORMAL       # Human-friendly
export COCOTB_VERBOSITY=VERBOSE      # Detailed
export COCOTB_VERBOSITY=DEBUG        # Everything
```

## Example Output Comparison

### Old Approach (Verbose)
```
======================================================================
Test 1: Reset Behavior
======================================================================
  Count after reset: 0
✓ Reset test PASSED
======================================================================
Test 2: Count Up to Max
======================================================================
  Initial: count = 0
  After cycle 1: count = 1
  After cycle 2: count = 2
  After cycle 3: count = 3
  After cycle 4: count = 4
  After cycle 5: count = 5
  ...
  [200+ more lines]
```

### New Approach - P1 + MINIMAL (Default for LLMs)
```
P1 - BASIC TESTS
T1: Reset behavior
  ✓ PASS
T2: Count up to 5
  ✓ PASS
T3: Count down from 5
  ✓ PASS
T4: Enable control
  ✓ PASS
ALL 4 TESTS PASSED
```

### New Approach - P1 + NORMAL (For Humans)
```
============================================================
PHASE: P1 - BASIC TESTS
============================================================
============================================================
Test 1: Reset behavior
✓ Reset behavior PASSED
============================================================
Test 2: Count up to 5
✓ Count up to 5 PASSED
============================================================
Test 3: Count down from 5
✓ Count down from 5 PASSED
============================================================
Test 4: Enable control
✓ Enable control PASSED
============================================================
MODULE: counter_nbit
TESTS RUN: 4
PASSED: 4
FAILED: 0
RESULT: ALL TESTS PASSED ✓
============================================================
```

## Migration Guide

### Converting Existing Tests

1. **Create module directory**:
```bash
mkdir tests/<module>_tests
```

2. **Create constants file** (`<module>_constants.py`):
```python
MODULE_NAME = "module_name"
HDL_SOURCES = [...]
HDL_TOPLEVEL = "entity_name"
# Test parameters, expected values, etc.
```

3. **Split tests by progression level**:
- Move basic functionality tests to `P1_<module>_basic.py`
- Move thorough tests to `P2_<module>_intermediate.py`
- Move stress tests to `P3_<module>_comprehensive.py`
- Add debug/experimental tests to `P4_<module>_exhaustive.py`

4. **Use TestBase class**:
```python
from test_base import TestBase, TestLevel, VerbosityLevel

class MyModuleBasicTests(TestBase):
    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)

    async def run_p1_basic(self):
        await self.test("Test name", self.test_function)

    async def test_function(self):
        # Test implementation
        self.log("Optional message", VerbosityLevel.VERBOSE)
```

## Benefits

### For LLMs
- **90% reduction** in output verbosity at P1/MINIMAL
- Context window preserved for actual code analysis
- Clear PASS/FAIL signals without noise
- Structured, predictable output format

### For Humans
- Progressive validation (start simple, add complexity)
- Easier debugging (can increase verbosity when needed)
- Better organization (tests grouped by module)
- Shared constants reduce duplication

### For CI/CD
- Fast P1 tests for quick feedback
- P2/P3 for thorough validation
- P4 for nightly/weekend stress testing
- Environment-based configuration

## Best Practices

1. **Always start with P1 tests** - Get basic functionality working first
2. **Use MINIMAL verbosity by default** - Especially in LLM workflows
3. **Keep P1 tests fast** - Use small test values (10-100, not 4095)
4. **Document expected output** in constants file
5. **Share test utilities** via constants file
6. **Progress incrementally** - P1 → P2 → P3, not all at once

## Implementation Status

### Completed
- ✅ `test_base.py` - Base class with verbosity control
- ✅ `counter_nbit_tests/` - Example implementation
  - ✅ Constants file
  - ✅ P1 basic tests
  - ✅ P2 intermediate tests
- ✅ This documentation

### To Do
- [ ] Migrate existing tests to new structure
- [ ] Update test runner (`run.py`) to support new structure
- [ ] Add P3/P4 examples
- [ ] Create migration script for automated conversion
- [ ] Update CI/CD pipelines

## Conclusion

This progressive testing strategy with verbosity control solves the LLM context window problem while maintaining thorough test coverage. The default P1/MINIMAL configuration provides essential validation with minimal output, while higher levels and verbosity settings remain available when needed.

The per-module organization also improves maintainability and makes it easier to find and run specific tests.
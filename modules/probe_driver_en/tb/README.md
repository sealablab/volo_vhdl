# Probe Driver Testbenches

This directory contains testbenches for the `probe_driver` module components.

## Directory Structure

```
tb/
├── README.md          # This file
├── datadef/           # Testbenches for datadef layer
│   └── PercentLut_pkg_tb.vhd
├── common/            # Testbenches for common layer (future)
└── core/              # Testbenches for core layer (future)
```

## Running Tests with GHDL

### Prerequisites
- GHDL installed with VHDL-2008 support
- Run commands from the repository root directory

### Compilation and Execution

#### PercentLut_pkg Testbench

```bash
# Compile the package
ghdl -a --std=08 modules/probe_driver/datadef/PercentLut_pkg.vhd

# Compile the testbench
ghdl -a --std=08 modules/probe_driver/tb/datadef/PercentLut_pkg_tb.vhd

# Elaborate
ghdl -e --std=08 PercentLut_pkg_tb

# Run simulation
ghdl -r --std=08 PercentLut_pkg_tb
```

Or run all steps at once:
```bash
ghdl -a --std=08 modules/probe_driver/datadef/PercentLut_pkg.vhd && \
ghdl -a --std=08 modules/probe_driver/tb/datadef/PercentLut_pkg_tb.vhd && \
ghdl -e --std=08 PercentLut_pkg_tb && \
ghdl -r --std=08 PercentLut_pkg_tb
```

### Expected Output

A successful test run should show:
- Individual test results for all 20 test cases
- `ALL TESTS PASSED` message
- `SIMULATION DONE` message

Example:
```
=== PercentLut_pkg Testbench Started ===
Test 1: CRC calculation returns 16-bit result - PASSED
Test 2: CRC calculation is deterministic - PASSED
...
Test 20: Pattern LUT lookup - odd index returns 0x5555 - PASSED
=== Test Summary ===
Total tests run: 20
ALL TESTS PASSED
SIMULATION DONE
```

## Test Coverage

### PercentLut_pkg_tb.vhd

This testbench provides comprehensive coverage of all functions in `PercentLut_pkg`:

#### CRC Functions (Tests 1-5)
- Basic CRC calculation functionality
- Deterministic behavior verification
- CRC validation with correct and incorrect CRCs
- Validation failure for invalid LUT (index 0 ≠ 0x0000)

#### Safe Lookup Functions (Tests 6-11)
- Valid index lookups (both `std_logic_vector` and `natural` versions)
- Boundary condition testing (indices 0 and 100)
- Out-of-bounds clamping verification

#### Index Validation Functions (Tests 12-17)
- Valid index validation (both `std_logic_vector` and `natural` versions)
- Boundary condition testing
- Invalid index detection

#### Helper Functions (Test 18)
- CRC creation helper function verification

#### Pattern-Based Testing (Tests 19-20)
- Non-linear LUT data patterns
- Verification of correct data retrieval

## Test Data

The testbench uses two primary test patterns:

1. **Linear LUT**: `lut[i] = i` for validation of basic functionality
2. **Pattern LUT**: Alternating 0xAAAA/0x5555 pattern for pattern-specific tests

## Compliance

- ✅ VHDL-2008 compatible
- ✅ GHDL compatible 
- ✅ Deterministic test patterns
- ✅ Proper test result reporting
- ✅ Follows project testbench standards (prints required completion messages)
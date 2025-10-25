# CocotB Test Suite

This directory contains **CocotB simulation tests ONLY** for the Volo VHDL project.

## Directory Purpose

**`tests/` = CocotB simulation tests**

For other types of testing:
- **`scripts/hardware/`** - Hardware deployment & validation on real Moku
- **`scripts/diagnostics/`** - Physical connection diagnostics & debugging
- **`scripts/mokubench/`** - Full bench integration tests

**Migration Status**: Active transition from GHDL VHDL testbenches to CocotB
**Branch**: `feature/coco_tb_transition`
**Started**: 2025-01-22

---

## Quick Start

### Prerequisites

```bash
# Install CocotB
pip install cocotb cocotb-test

# Verify GHDL is installed
ghdl --version

# Optional: Install GTKWave for waveform viewing
# macOS: brew install gtkwave
# Ubuntu: sudo apt install gtkwave
```

### Running Tests

```bash
# Run all tests for default module
cd tests
make

# Run specific module tests
make MODULE=clk_divider_core

# Enable detailed logging
COCOTB_LOG_LEVEL=DEBUG make

# View waveforms (after test run)
make waves
```

---

## Available Tests

### clk_divider_core ⭐ (Pilot Test)
**File**: `test_clk_divider_core.py`
**Module**: `volo_common/core/clk_divider_core.vhd`
**Status**: ✅ Complete
**Migrated from**: `volo_common/tb/core/clk_divider_core_tb.vhd`

**Test Coverage**:
1. Reset behavior
2. Divide by 1 (bypass mode)
3. Divide by 2
4. Divide by 10
5. Enable control (freeze functionality)
6. Maximum division (div_sel=255 → ÷256)
7. Counter status register

**Run**: `make MODULE=clk_divider_core`

---

## Test Organization

### Directory Structure
```
tests/
├── Makefile                      # CocotB build system
├── README.md                     # This file
├── test_clk_divider_core.py     # Pilot test
├── conftest.py                   # Shared fixtures (TODO)
└── volo_testlib/                 # Shared utilities (TODO)
    ├── __init__.py
    ├── clock_utils.py
    ├── reset_utils.py
    └── assertions.py
```

### Test Naming Convention
- `test_<module_name>.py` - Test file for each RTL module
- Test functions: `async def test_<feature>(dut)`
- Descriptive names explaining what is tested

---

## Writing Tests

### Basic Test Template

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_reset_behavior(dut):
    """Test reset functionality"""
    # Start clock
    clock = cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)

    # Check reset state
    assert dut.output.value == 0, "Output should be 0 after reset"

    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
```

### Best Practices

1. **Always start with reset test** - First test should verify reset behavior
2. **Use descriptive test names** - Clear indication of what's being tested
3. **Add docstrings** - Explain test purpose and approach
4. **Use logging** - `dut._log.info()`, `dut._log.debug()`
5. **Check edge cases** - Zero, max values, wraparound
6. **Verify timing** - Use ClockCycles for deterministic behavior

### Patterns from GHDL (Preserve These)

✅ **Proper initialization** - Always initialize DUT inputs before clock starts
✅ **Reset testing** - Test reset first, every time
✅ **Timing awareness** - Synchronize to clock edges
✅ **Comprehensive reporting** - Log test progress and results
✅ **Separation of concerns** - One test per feature

---

## Migrating from GHDL

See documentation:
- `../docs/ghdl_to_cocotb_migration.md` - Complete migration guide
- `../docs/testbench_inventory.md` - List of testbenches to migrate

### Migration Checklist

For each GHDL testbench:

- [ ] Create equivalent CocotB test
- [ ] Verify coverage matches or exceeds GHDL test
- [ ] Run both tests on same RTL (verify equivalence)
- [ ] Document any differences or improvements
- [ ] Archive GHDL testbench
- [ ] Update module documentation

---

## Environment Variables

```bash
# Simulator selection
SIM=ghdl                    # Default: GHDL
SIM=verilator               # Alternative (if installed)

# VHDL standard
VHDL_STANDARD=08            # Default: VHDL-2008

# Logging
COCOTB_LOG_LEVEL=DEBUG      # Detailed logging
COCOTB_LOG_LEVEL=INFO       # Standard logging (default)
COCOTB_LOG_LEVEL=WARNING    # Minimal logging

# Waveforms
WAVES=1                     # Enable waveform dump (default)
WAVES=0                     # Disable waveform dump

# Test selection
TESTCASE=test_specific      # Run specific test function
```

---

## Troubleshooting

### "cocotb not found"
```bash
pip install cocotb cocotb-test
```

### "GHDL not found"
```bash
# Ensure GHDL is in PATH
which ghdl

# Install if needed (macOS)
brew install ghdl

# Install if needed (Ubuntu)
sudo apt install ghdl
```

### "Module not found" errors
```bash
# Ensure you're in the tests/ directory
cd tests

# Check Makefile VHDL_SOURCES paths
make help
```

### Tests hang or timeout
- Check for `await` on signals that never change
- Verify clock is running (`cocotb.start_soon(Clock(...).start())`)
- Check enable/reset signal states

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: CocotB Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y ghdl
          pip install cocotb cocotb-test pytest
      - name: Run tests
        run: |
          cd tests
          make MODULE=clk_divider_core
```

---

## Contributing

When adding new tests:

1. Follow the naming convention: `test_<module>.py`
2. Add module to `Makefile` (update VHDL_SOURCES)
3. Document test coverage in this README
4. Include docstrings in test functions
5. Use `dut._log` for test progress reporting

---

## Resources

- **CocotB Documentation**: https://docs.cocotb.org/
- **GHDL Documentation**: https://ghdl.github.io/ghdl/
- **Project Migration Guide**: `../docs/ghdl_to_cocotb_migration.md`
- **Testbench Inventory**: `../docs/testbench_inventory.md`

---

**Last Updated**: 2025-01-22
**Status**: Pilot test complete, expanding coverage

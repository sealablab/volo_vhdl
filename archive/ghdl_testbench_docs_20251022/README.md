# Archived GHDL Testbench Documentation

**Archived Date**: 2025-01-22  
**Reason**: Project transitioned to CocotB testing framework  
**Status**: Reference only - DO NOT USE for new development

## Contents

This directory contains legacy GHDL testbench documentation that has been superseded by CocotB:

- `README-ghdl-testbench-tips.md` - Original GHDL patterns
- `README-ghdl-testbench-tips-ng.md` - Next-gen GHDL patterns
- `README-layered-testbench-ng.md` - 4-layer testbench architecture
- `LAYERED-TESTBENCH-*.md` - Layered testbench checklists

## Replacement

**New Testing Framework**: CocotB  
**Documentation**: See `tests/README.md` and Serena memory `cocotb_testing_guide`  
**Example**: `tests/test_clk_divider_core.py`

## Migration Status

✅ All new tests should use CocotB  
⚠️ Do NOT create new GHDL testbenches  
📚 This documentation preserved for historical reference only

---

For current testing practices, see:
- `tests/README.md` - CocotB testing guide
- `tests/conftest.py` - Shared test utilities
- Serena memory: `cocotb_testing_guide`

# GHDL Testbench Archive Update - 2025-10-22

## Additional Testbenches Archived

The following GHDL testbenches were found in active `modules/` directories during Moku_Pct_pkg development and moved to this archive location.

### Files Archived (2025-10-22)

1. **probe_driver/tb/top/probe_driver_interface_tb.vhd**
   - Original location: `modules/probe_driver/tb/top/`
   - Status: Legacy GHDL testbench, to be replaced with CocotB tests

2. **SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd**
   - Original location: `modules/SimpleWaveGen/tb/core/`
   - Status: Legacy GHDL testbench, to be replaced with CocotB tests

3. **SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd**
   - Original location: `modules/SimpleWaveGen/tb/top/`
   - Status: Legacy GHDL testbench, to be replaced with CocotB tests

## Reason for Archival

Per project standard (CLAUDE.md):
- **⚠️ DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead
- Existing GHDL tests are being phased out and migrated to CocotB
- CocotB is the new testing standard (Python-based, async/await)

## Migration Status

- ✅ **clk_divider_core**: Migrated to CocotB (`tests/test_clk_divider_core.py`) - 7/7 passing
- ✅ **Moku_Pct_pkg**: New CocotB tests (`tests/test_moku_pct_pkg.py`) - 9/9 passing
- 🔜 **probe_driver**: To be migrated to CocotB
- 🔜 **SimpleWaveGen**: To be migrated to CocotB

## Original Archive Date

This archive directory was originally created 2025-01-22 for the CocotB migration initiative. These additional files were found and added on 2025-10-22 during the Moku_Pct_pkg development cleanup.

## Testing Policy Going Forward

**New Standard**: All new tests use CocotB framework in `tests/` directory
- Location: `tests/test_<module>.py`
- Framework: Python with async/await
- Shared utilities: `tests/conftest.py`
- Documentation: `tests/README.md`

**Legacy GHDL tests**: Archived here, maintained for reference only

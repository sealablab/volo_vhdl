# Scrapped IntensityLUT/PercentLUT Implementations - 2025-10-22

## Reason for Removal
These files were part of an earlier implementation of percentage/intensity mapping that is being completely redesigned with better type safety and integration with the Moku_Voltage_pkg.

## Files Removed

### Active Module Files (from modules/probe_driver/datadef/)
1. **PercentLut_pkg.vhd** (28,131 bytes)
   - Record-based PercentLut package with CRC validation
   - 101-element LUT (indices 0-100) mapping to 16-bit voltage values
   - Included CRC-16 validation functions
   - Used Moku_Voltage_pkg for voltage conversion support

2. **PercentLut_Analysis.md** (7,086 bytes)
   - Analysis document comparing flat vs record-based approaches
   - Detailed Verilog conversion strategies
   - Recommendations for when to use each approach

### Archived Testbench Files (already in archive/)
The following files in `archive/ghdl_testbenches/2025-01-22/` reference PercentLut but are already archived:
- `probe_driver/tb/datadef/PercentLut_pkg_tb.vhd`
- Various integration tests in probe_driver and probe_driver_en testbenches

## What This Package Did
- Provided 0-100 percentage indexing to voltage values
- CRC-16 validation for data integrity
- Safe lookup functions with bounds checking
- Integration with Moku voltage conversion utilities

## Replacement Strategy
The new implementation will:
1. Integrate more closely with Moku_Voltage_pkg
2. Provide compile-time type safety for different voltage ranges
3. Prevent mixing incompatible intensity types (e.g., 3v3 vs 5v0)
4. Support common pre-defined voltage ranges
5. Use cleaner naming and better design patterns

## Status
- **Date Scrapped**: 2025-10-22
- **Reason**: Complete redesign from scratch with better architecture
- **No backward compatibility required**: Clean slate for new design

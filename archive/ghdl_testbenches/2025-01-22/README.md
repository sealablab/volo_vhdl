# GHDL Testbench Archive - 2025-01-22

## Purpose

This archive contains GHDL testbenches removed during the CocotB migration project. These files are preserved for historical reference and potential future recovery if needed.

## Archival Reason

These testbenches were removed because:
1. **Inactive modules** - The parent modules are not in the active build system (Makefile.deps)
2. **Package-only tests** - Tests that only validate package definitions, not actual RTL behavior
3. **Superseded by CocotB** - Functionality now covered by CocotB tests

## Archive Contents

### Inactive Modules (10 testbenches)

#### probe_driver_en (5 testbenches)
- Module not in Makefile.deps build order
- Likely superseded by probe_driver module
- Files archived:
  - `tb/datadef/Global_Probe_Table_pkg_en_tb.vhd`
  - `tb/datadef/Global_Probe_Table_pkg_tb.vhd`
  - `tb/datadef/Probe_Config_pkg_en_tb.vhd`
  - `tb/datadef/Probe_Config_pkg_tb.vhd`
  - `tb/top/probe_driver_en_integration_tb.vhd`
  - `tb/top/probe_driver_interface_tb.vhd`

#### probe_hero8 (4 testbenches)
- Module not in Makefile.deps build order
- Contains redundant "detailed" test variants
- Files archived:
  - `tb/core/probe_hero8_core_tb.vhd`
  - `tb/core/probe_hero8_core_detailed_tb.vhd`
  - `tb/top/probe_hero8_top_tb.vhd`
  - `tb/top/probe_hero8_top_detailed_tb.vhd`

#### EMFI-Seq (1 testbench)
- Module not in Makefile.deps build order
- Tests analog voltage conversion (stair DAC)
- File archived:
  - `tb/core/tb_EMFI_Seq_stair.vhd`

### Package Tests from Active Modules (7 testbenches)

These test only package definitions (constants, types, functions) rather than actual RTL behavior. Package validation is better done through core/top-level tests.

#### probe_driver (5 package tests)
- Module is active but these tests only validate packages
- Files archived:
  - `tb/datadef/Global_Probe_Table_pkg_en_tb.vhd`
  - `tb/datadef/Global_Probe_Table_pkg_tb.vhd`
  - `tb/datadef/PercentLut_pkg_tb.vhd`
  - `tb/datadef/Probe_Config_pkg_en_tb.vhd`
  - `tb/datadef/Probe_Config_pkg_tb.vhd`

#### SimpleWaveGen (2 package tests)
- Module is active and deployed to MCC device
- Files archived:
  - `tb/common/platform_interface_pkg_tb.vhd`
  - `tb/common/waveform_common_pkg_tb.vhd`

### Already Migrated (1 testbench)

#### volo_common (1 testbench)
- Successfully migrated to CocotB: `tests/test_clk_divider_core.py`
- File archived:
  - `tb/core/clk_divider_core_tb.vhd`

## Archive Policy

**Retention:** Keep for 6 months (until 2025-07-22)
**After retention period:** Evaluate for permanent deletion
**Recovery:** If needed, files can be restored from this archive

## Active Build System

As of 2025-01-22, the active modules in Makefile.deps are:
- `volo_common` - Shared library (Moku_Voltage_pkg, clk_divider_core)
- `probe_driver` - Active module
- `SimpleWaveGen` - Active module (deployed to MCC)
- `stoplight` - Active module

## Migration Status

**Total GHDL testbenches before cleanup:** 24
**Archived/Deleted:** 18 (75%)
**Remaining for CocotB migration:** 5 (21%)
**Already migrated:** 1 (4%)

### Remaining testbenches to migrate:
- `stoplight/tb/core/stoplight_core_tb.vhd` → CocotB
- `stoplight/tb/top/stoplight_top_tb.vhd` → CocotB
- `SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd` → CocotB
- `SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd` → CocotB
- `probe_driver/tb/top/probe_driver_interface_tb.vhd` → CocotB

## Related Documentation

- CocotB migration guide: `docs/ghdl_to_cocotb_migration.md`
- Testbench inventory: `docs/testbench_inventory.md`
- Transition plan: `docs/cocotb_transition_plan.md`

## Notes

This cleanup was performed as part of the systematic CocotB migration to:
1. Reduce maintenance burden of GHDL testbenches
2. Focus migration effort on actively-used modules
3. Eliminate redundant package-only tests
4. Preserve historical test code for reference

---

**Archive Date:** 2025-01-22
**Archive Reason:** CocotB migration cleanup
**Review Date:** 2025-07-22

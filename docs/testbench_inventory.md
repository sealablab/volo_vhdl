# GHDL Testbench Inventory

**Status**: Pre-Migration Inventory
**Date**: 2025-01-22
**Branch**: `feature/coco_tb_transition`
**Total GHDL Testbenches**: 24

---

## Testbench Summary by Module

### EMFI-Seq (1 testbench)
- `EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd` - Tests stair-step DAC (analog monitor)

### probe_driver_en (5 testbenches)
**Datadef Layer:**
- `probe_driver_en/tb/datadef/Global_Probe_Table_pkg_en_tb.vhd`
- `probe_driver_en/tb/datadef/Global_Probe_Table_pkg_tb.vhd`
- `probe_driver_en/tb/datadef/Probe_Config_pkg_en_tb.vhd`
- `probe_driver_en/tb/datadef/Probe_Config_pkg_tb.vhd`

**Top Layer:**
- `probe_driver_en/tb/top/probe_driver_en_integration_tb.vhd`
- `probe_driver_en/tb/top/probe_driver_interface_tb.vhd`

### probe_driver (6 testbenches)
**Datadef Layer:**
- `probe_driver/tb/datadef/Global_Probe_Table_pkg_en_tb.vhd`
- `probe_driver/tb/datadef/Global_Probe_Table_pkg_tb.vhd`
- `probe_driver/tb/datadef/PercentLut_pkg_tb.vhd`
- `probe_driver/tb/datadef/Probe_Config_pkg_en_tb.vhd`
- `probe_driver/tb/datadef/Probe_Config_pkg_tb.vhd`

**Top Layer:**
- `probe_driver/tb/top/probe_driver_interface_tb.vhd`

### probe_hero8 (4 testbenches)
**Core Layer:**
- `probe_hero8/tb/core/probe_hero8_core_detailed_tb.vhd`
- `probe_hero8/tb/core/probe_hero8_core_tb.vhd`

**Top Layer:**
- `probe_hero8/tb/top/probe_hero8_top_detailed_tb.vhd`
- `probe_hero8/tb/top/probe_hero8_top_tb.vhd`

### SimpleWaveGen (4 testbenches)
**Common Layer:**
- `SimpleWaveGen/tb/common/platform_interface_pkg_tb.vhd`
- `SimpleWaveGen/tb/common/waveform_common_pkg_tb.vhd`

**Core Layer:**
- `SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd`

**Top Layer:**
- `SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`

### stoplight (2 testbenches)
**Core Layer:**
- `stoplight/tb/core/stoplight_core_tb.vhd`

**Top Layer:**
- `stoplight/tb/top/stoplight_top_tb.vhd`

### volo_common (1 testbench)
**Core Layer:**
- `volo_common/tb/core/clk_divider_core_tb.vhd`

---

## Migration Priority

### Phase 1: High Priority (Core Infrastructure)
These modules are actively used and need CocotB tests first:

1. **volo_common/clk_divider_core** - Shared module, recently integrated into EMFI-Seq
2. **EMFI-Seq** - Active development, just integrated clk_divider
3. **SimpleWaveGen** - Reference module, successfully deployed to MCC

### Phase 2: Medium Priority
4. **stoplight** - Good teaching example, simple FSM
5. **probe_hero8** - Smaller probe variant

### Phase 3: Lower Priority (Complex Legacy)
6. **probe_driver** - Large, complex, may need refactoring
7. **probe_driver_en** - Variant of probe_driver

---

## Testbench Characteristics

### By Test Layer
- **Common/Datadef (Package tests)**: 10 testbenches
- **Core (Algorithm tests)**: 5 testbenches
- **Top (Integration tests)**: 9 testbenches

### Complexity Assessment

**Simple (Good starting points for CocotB migration):**
- `volo_common/tb/core/clk_divider_core_tb.vhd` ⭐ **START HERE**
- `stoplight/tb/core/stoplight_core_tb.vhd`
- `EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd`

**Medium:**
- `SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd`
- `SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`
- `stoplight/tb/top/stoplight_top_tb.vhd`

**Complex (Package/LUT tests):**
- All `probe_driver*/tb/datadef/*_tb.vhd` files
- `SimpleWaveGen/tb/common/platform_interface_pkg_tb.vhd`
- `SimpleWaveGen/tb/common/waveform_common_pkg_tb.vhd`

**Very Complex (Integration tests):**
- `probe_driver_en/tb/top/probe_driver_en_integration_tb.vhd`
- `probe_hero8/tb/top/probe_hero8_top_detailed_tb.vhd`

---

## Recommended Migration Order

### Step 1: Pilot Test (Week 1)
**Target**: `volo_common/tb/core/clk_divider_core_tb.vhd`

**Why**:
- Simple module (single entity)
- Clear functionality (clock division)
- Recently developed (fresh in memory)
- Used by EMFI-Seq (high value)
- Good learning example

**Success Criteria**:
- CocotB test provides equivalent coverage
- Team comfortable with CocotB workflow
- Patterns documented for reuse

### Step 2: Expand to EMFI-Seq (Week 2)
**Target**: `EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd`

**Why**:
- Current focus module
- Tests datadef layer (voltage conversions)
- Will validate CocotB for real number testing

### Step 3: Reference Module (Week 3)
**Target**: SimpleWaveGen testbenches (4 total)

**Why**:
- Successfully deployed to MCC
- Demonstrates full test hierarchy (common→core→top)
- Good template for future modules

### Step 4: Systematic Cleanup (Ongoing)
- Migrate remaining modules as capacity allows
- Archive GHDL testbenches after CocotB verification
- Update documentation

---

## Archive Strategy

### Archive Location
```
archive/ghdl_testbenches/
├── 2025-01-22_initial_archive/
│   ├── README.md                    # Explains what's archived and why
│   ├── volo_common/
│   │   └── clk_divider_core_tb.vhd
│   ├── EMFI-Seq/
│   │   └── tb_EMFI_Seq_stair.vhd
│   └── ...
└── migration_notes.md               # Per-module migration notes
```

### What to Archive
- Original VHDL testbench source
- Any test vectors or golden outputs
- Notes on test coverage
- Known issues or limitations

### What NOT to Archive
- Compiled artifacts (*.o, work-obj*.cf)
- Executables (*_tb binaries)
- Temporary files

---

## Purge Checklist Template

For each testbench to be purged:

```markdown
## Module: <module_name>
## Testbench: <testbench_file.vhd>
## Migration Date: YYYY-MM-DD

### Original Test Coverage
- [ ] Test case 1: Description
- [ ] Test case 2: Description
- [ ] ...

### CocotB Replacement
- **File**: tests/test_<module>.py
- **Coverage**: [Equal | Better | Worse]
- **Additional tests**: List any new tests added

### Verification
- [ ] GHDL test passes on current RTL
- [ ] CocotB test passes on same RTL
- [ ] Results compared (waveforms, logs)
- [ ] Coverage verified

### Archive
- [ ] Source copied to archive/ghdl_testbenches/YYYY-MM-DD/
- [ ] README.md created in archive directory
- [ ] Migration notes documented

### Cleanup
- [ ] Removed from module/Makefile
- [ ] Removed from modules/Makefile
- [ ] Removed source file
- [ ] Updated module README
- [ ] Commit with clear message
```

---

## Risk Assessment

### Low Risk (Safe to Purge Early)
- Simple functional tests with clear pass/fail
- Tests with deterministic behavior
- Tests that don't require complex timing

### Medium Risk (Verify Carefully)
- Tests with real number comparisons
- Tests with complex timing sequences
- Integration tests with multiple components

### High Risk (Keep Until Confident)
- Tests that found bugs in the past
- Tests with undocumented edge cases
- Tests that are currently failing (indicates unknown issues)

---

## Success Metrics

### Migration Progress
- **Testbenches migrated**: 0 / 24
- **Modules with CocotB tests**: 0 / 8
- **GHDL testbenches archived**: 0 / 24
- **GHDL testbenches purged**: 0 / 24

### Quality Metrics
- **Test coverage maintained**: Target 100%
- **New tests added**: Track additional scenarios
- **Bugs found during migration**: Document
- **Time to run tests**: Should improve with CocotB

---

## Notes

### Modules Without Testbenches
The following modules have no GHDL testbenches (may need CocotB tests):
- 4S-OH-Seq
- BPD
- MokuVoltagePkg
- TPD modules
- probe_hero9
- probe_hero11

These should be evaluated for whether they need test coverage.

---

## Next Actions

1. ✅ Complete migration guide (`ghdl_to_cocotb_migration.md`)
2. ✅ Create testbench inventory (this document)
3. ⬜ Set up CocotB infrastructure (Makefile, directory structure)
4. ⬜ Write pilot test for `clk_divider_core`
5. ⬜ Document CocotB patterns that work well
6. ⬜ Begin systematic migration

---

**Document Maintained By**: Development team
**Last Updated**: 2025-01-22

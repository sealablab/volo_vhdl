# CocotB Transition Plan

**Branch**: `feature/coco_tb_transition`
**Started**: 2025-01-22
**Status**: Infrastructure Complete, Ready for Testing

---

## Executive Summary

Successfully completed infrastructure setup for CocotB transition. Ready to test pilot implementation and begin systematic migration of 24 GHDL testbenches.

---

## Completed (Phase 1: Infrastructure Setup)

### ✅ Documentation Created
- [x] `docs/ghdl_to_cocotb_migration.md` - Complete migration guide
  - Documented 7 GHDL pain points
  - Preserved lessons learned
  - Defined 4-phase migration strategy
  - CocotB best practices for this project
- [x] `docs/testbench_inventory.md` - Inventory of 24 GHDL testbenches
  - Organized by module and priority
  - Migration order defined
  - Archive strategy documented

### ✅ CocotB Infrastructure
- [x] Created `tests/` directory structure
- [x] `tests/Makefile` - GHDL integration, module selection
- [x] `tests/README.md` - Comprehensive testing guide
- [x] `tests/test_clk_divider_core.py` - Pilot test (7 test cases)

### ✅ Git Commits
- [x] Commit cadefc9: Migration documentation
- [x] Commit 26f5c44: CocotB infrastructure and pilot test

---

## Current Status: Ready for Phase 2

### Immediate Next Steps (Session 1)

#### 1. Test the Infrastructure ⚠️ CRITICAL FIRST STEP
```bash
cd tests
make MODULE=clk_divider_core
```

**Expected outcome**: All 7 tests pass
**If tests fail**: Debug and fix infrastructure issues before proceeding

**Success criteria**:
- All tests pass
- Waveforms generate (dump.ghw created)
- No CocotB import errors
- GHDL compilation successful

#### 2. Verify Prerequisites (If Test Fails)
```bash
# Check CocotB installation
pip list | grep cocotb

# If not installed:
pip install cocotb cocotb-test

# Verify GHDL
ghdl --version

# Should show GHDL 1.x or 2.x with VHDL-2008 support
```

#### 3. Compare with GHDL Test (Validation)
```bash
# Run original GHDL test
cd modules
make compile-single-module MODULE_NAME=volo_common
cd volo_common
# Run GHDL testbench if it exists

# Compare results with CocotB test
# Both should test same functionality
```

---

## Phase 2: Expand Test Utilities

### Goal: Create Reusable Test Infrastructure

#### Task 2.1: Create conftest.py
**File**: `tests/conftest.py`
**Purpose**: Shared pytest fixtures

```python
# Fixtures to create:
- setup_clock(dut, period_ns=10)
- reset_dut(dut, active_low=True, cycles=2)
- verify_reset_state(dut, expected_outputs)
```

**Acceptance**: Other tests can import and use fixtures

#### Task 2.2: Create volo_testlib Package
**Directory**: `tests/volo_testlib/`
**Files**:
- `__init__.py`
- `clock_utils.py` - Clock management helpers
- `reset_utils.py` - Reset sequence helpers
- `assertions.py` - Custom assertions for VHDL types
- `waveform_utils.py` - Waveform capture/analysis

**Acceptance**: Pilot test can be simplified using utilities

#### Task 2.3: Document Patterns
**File**: `tests/PATTERNS.md`
**Content**:
- Common test patterns that work well
- Anti-patterns to avoid
- GHDL compatibility notes
- Timing patterns

---

## Phase 3: Migrate EMFI-Seq Tests

### Goal: Second Module Migration

#### Task 3.1: Migrate tb_EMFI_Seq_stair.vhd
**Original**: `modules/EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd`
**New**: `tests/test_emfi_seq_stair.py`

**What it tests**:
- Voltage to digital conversions (real number testing)
- Stair-step DAC output
- One-hot state to voltage mapping

**Challenges**:
- Real number comparisons (use pytest.approx)
- Package imports (Moku_Voltage_pkg)

**Success criteria**:
- All voltage conversion tests pass
- Real number tolerance handled correctly
- Coverage equals or exceeds GHDL test

#### Task 3.2: Update Makefile
Add EMFI_Seq module to `tests/Makefile`:
```makefile
ifeq ($(MODULE),emfi_seq_stair)
    VHDL_SOURCES = $(MODULES_DIR)/EMFI-Seq/datadef/Moku_Voltage_pkg.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_stair.vhd
    TOPLEVEL = onehot_analog_monitor
    MODULE_TEST = test_emfi_seq_stair
endif
```

---

## Phase 4: Migrate SimpleWaveGen Tests (High Value)

### Goal: Complete Module Migration (4 Testbenches)

#### Task 4.1: Common Layer Tests
**Original**:
- `modules/SimpleWaveGen/tb/common/platform_interface_pkg_tb.vhd`
- `modules/SimpleWaveGen/tb/common/waveform_common_pkg_tb.vhd`

**New**:
- `tests/test_platform_interface_pkg.py`
- `tests/test_waveform_common_pkg.py`

#### Task 4.2: Core Test
**Original**: `modules/SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd`
**New**: `tests/test_simplewavegen_core.py`

#### Task 4.3: Top Test
**Original**: `modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`
**New**: `tests/test_simplewavegen_top.py`

**Success criteria**:
- All 4 layers tested in CocotB
- Coverage verified against GHDL tests
- SimpleWaveGen fully validated with CocotB

---

## Phase 5: Systematic Migration (Remaining Modules)

### Migration Order:

1. **stoplight** (2 testbenches) - Simple FSM, good learning
2. **probe_hero8** (4 testbenches) - Medium complexity
3. **probe_driver** (6 testbenches) - Complex, may need refactoring
4. **probe_driver_en** (5 testbenches) - Variant of probe_driver

### For Each Module:

1. Create CocotB test
2. Verify coverage matches GHDL
3. Run both tests on same RTL
4. Archive GHDL testbench
5. Update module documentation
6. Commit with clear message

---

## Phase 6: Cleanup and Optimization

### Task 6.1: Archive GHDL Testbenches
**Directory**: `archive/ghdl_testbenches/2025-01-22/`

**Process**:
1. Verify CocotB coverage for module
2. Copy GHDL testbench to archive
3. Create README in archive explaining what/why
4. Remove from build system
5. Delete original file
6. Commit

**Safety**: Keep archive for 6 months before permanent deletion

### Task 6.2: Update Build System
- Remove GHDL testbench targets from `modules/Makefile`
- Update module-level Makefiles
- Update documentation references

### Task 6.3: CI/CD Integration
**File**: `.github/workflows/cocotb-tests.yml`

**Configuration**:
- Run on push/PR
- Test all modules
- Generate coverage report
- Upload artifacts (waveforms, logs)

---

## Phase 7: Continuous Improvement

### Task 7.1: Coverage Analysis
- Identify gaps in test coverage
- Add tests for edge cases
- Document test rationale

### Task 7.2: Performance Optimization
- Parallelize independent tests
- Optimize slow tests
- Reduce test runtime

### Task 7.3: Documentation
- Update CLAUDE.md with CocotB patterns
- Create examples for common scenarios
- Document troubleshooting guides

---

## Success Metrics

### Quantitative
- [ ] 24/24 GHDL testbenches migrated
- [ ] 0 GHDL testbenches in active use
- [ ] Test runtime < 5 minutes for full suite
- [ ] 100% of original test coverage maintained
- [ ] CI/CD integration complete

### Qualitative
- [ ] Team comfortable with CocotB workflow
- [ ] Test development faster than GHDL
- [ ] Better debugging experience reported
- [ ] New modules use CocotB from start

---

## Risk Management

### Risk 1: CocotB Infrastructure Issues
**Mitigation**: Test pilot thoroughly before expanding
**Fallback**: Keep GHDL tests until CocotB proven

### Risk 2: Real Number Testing Challenges
**Mitigation**: Use pytest.approx, document patterns
**Fallback**: Use integer arithmetic where possible

### Risk 3: Complex Package Dependencies
**Mitigation**: Test packages first (datadef layer)
**Fallback**: Keep GHDL tests for complex packages

### Risk 4: Team Adoption Resistance
**Mitigation**: Show clear benefits, provide training
**Fallback**: Gradual migration, both systems temporarily

---

## Decision Log

### Decision 1: Pilot Module Selection
**Date**: 2025-01-22
**Decision**: Start with clk_divider_core
**Rationale**: Simple, recently developed, high value
**Status**: Implemented

### Decision 2: Archive Strategy
**Date**: 2025-01-22
**Decision**: Archive before delete, keep 6 months
**Rationale**: Safety, allows rollback if needed
**Status**: Planned

### Decision 3: Migration Order
**Date**: 2025-01-22
**Decision**: Simple → Medium → Complex
**Rationale**: Build confidence and patterns incrementally
**Status**: Documented

---

## Resources

### Documentation
- CocotB Docs: https://docs.cocotb.org/
- GHDL Docs: https://ghdl.github.io/ghdl/
- pytest Docs: https://docs.pytest.org/

### Project Files
- Migration Guide: `docs/ghdl_to_cocotb_migration.md`
- Testbench Inventory: `docs/testbench_inventory.md`
- Test README: `tests/README.md`

### Preserved Knowledge
- Serena Memory: `ghdl_patterns_and_solutions`
- Project Instructions: `CLAUDE.md`
- Coding Standards: `.cursor/rules.mdc`

---

## Next Session Checklist

When resuming work:

1. [ ] Read this plan file
2. [ ] Check current branch (`feature/coco_tb_transition`)
3. [ ] Review recent commits
4. [ ] Run pilot test to verify infrastructure
5. [ ] Continue with Phase 2 or current phase

---

## Notes

### What Worked Well
- Comprehensive documentation before coding
- Clear separation of concerns
- Preserving GHDL lessons learned

### What to Improve
- Need to actually run tests (infrastructure untested)
- Create shared utilities early
- Get team feedback on patterns

### Questions for Next Session
- Did pilot test pass?
- Any GHDL compatibility issues?
- Are the fixtures/utilities needed immediately?
- Should we parallelize test development?

---

**Plan Status**: 📋 Ready for Execution
**Last Updated**: 2025-01-22
**Next Milestone**: Run pilot test and verify infrastructure

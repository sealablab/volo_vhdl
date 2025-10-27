# DS1120-PD Phase 2 Lessons Learned: Build Infrastructure Issues

## Issues Encountered and Suggested Improvements

### 1. Build System Migration Confusion

**Issue**: Attempted to use old Makefile-based build system when project had migrated to Python/CocotB infrastructure.

**What Happened**:
- Tried `make compile-single-module MODULE_NAME=DS1120-PD`
- System had moved to `python tests/run.py` approach
- Lost time trying to use deprecated build commands

**Suggested Improvements**:
- Add deprecation warnings to old Makefiles
- Create a `MIGRATION.md` file documenting the change
- Add redirects or helpful error messages in old build paths
- Update CLAUDE.md and AGENTS.md to remove old build commands

---

### 2. File Naming Convention Inconsistencies

**Issue**: Mix of hyphen and underscore naming caused compilation failures.

**What Happened**:
- Generated files used hyphens: `DS1120-PD_volo_main.vhd`
- Some references expected underscores: `DS1120_PD_volo_main.vhd`
- Duplicate files created with both naming conventions

**Suggested Improvements**:
- Enforce single naming convention project-wide
- Add pre-commit hooks to check file naming
- Document naming convention in coding standards
- Add validation to VOLO app generator

---

### 3. Test Runner Environment Issues

**Issue**: CocotB tools import failures when not using `uv run`.

**What Happened**:
- Direct `python tests/run.py` failed with import errors
- Required `uv run python tests/run.py` to work
- Not immediately obvious from error messages

**Suggested Improvements**:
```python
# Add to run.py:
if 'VIRTUAL_ENV' not in os.environ:
    print("⚠️  Not running in virtual environment!")
    print("   Use: uv run python tests/run.py")
    sys.exit(1)
```

---

### 4. Test Configuration Dependencies

**Issue**: Missing shared module dependencies not caught early.

**What Happened**:
- Initial test config missing clock divider, threshold trigger, etc.
- Only discovered when tests failed to compile
- Had to manually trace dependencies

**Suggested Improvements**:
- Add dependency validation to test_configs.py
- Create module dependency graph tool
- Add `--check-deps` flag to test runner
- Generate test configs from module manifests

---

### 5. MCC Hierarchy Access in Tests

**Issue**: Difficult to access internal signals through MCC wrapper.

**What Happened**:
- FSM state checking required complex hierarchy navigation
- Path like `dut.U_MCC_TOP.APP_INST.U_FSM` hard to determine
- Different for each module structure

**Suggested Improvements**:
- Standardize signal exposure patterns
- Add debug ports to MCC wrapper template
- Create hierarchy helper functions in conftest.py
- Document standard paths for common signals

---

### 6. Waveform Generation Options

**Issue**: GHDL wave option format incompatible with test runner.

**Error**: `ghdl:error: unknown command option '--wave=dump.ghw'`

**Suggested Fix**:
```python
# In test runner, change:
sim_args = ["--wave=dump.ghw"]  # Wrong

# To:
sim_args = ["--wave", "dump.ghw"]  # Correct
# Or use GHDL's VCD format:
sim_args = ["--vcd=dump.vcd"]
```

---

### 7. Documentation Scattered Across Multiple Locations

**Issue**: Hard to know which docs are current vs deprecated.

**What Happened**:
- Old docs in ai-workflow/ (archived)
- New docs in various places
- Serena memories as source of truth
- Mix of .md files and memory files

**Suggested Improvements**:
- Create single `CURRENT_DOCS.md` index
- Mark deprecated docs clearly
- Add "Last Updated" to all docs
- Create doc validation script

---

### 8. Python Test Discovery Issues

**Issue**: Test file organization not immediately clear.

**What Happened**:
- Started creating separate test files per test
- System expected single file with multiple @cocotb.test functions
- Had to consolidate after understanding pattern

**Suggested Improvements**:
- Document test organization pattern clearly
- Add test template generator
- Show examples in test README
- Add linting for test structure

---

## Recommended Actions for Project Improvement

### Immediate (Quick Fixes):
1. Update CLAUDE.md to remove old Makefile commands
2. Fix waveform option in test runner
3. Add virtual environment check to run.py
4. Clean up duplicate files with wrong naming

### Short-term (This Week):
1. Create MIGRATION.md for build system changes
2. Add dependency validation to test configs
3. Document naming conventions
4. Update all "how to build" documentation

### Long-term (This Month):
1. Create module dependency visualization tool
2. Standardize MCC signal exposure patterns
3. Add pre-commit hooks for naming/style
4. Create comprehensive test writing guide

---

## Positive Aspects Worth Keeping

1. **CocotB/pytest integration** - Much better than old GHDL testbenches
2. **Serena memory system** - Good for AI context management
3. **VOLO app generator** - Reduces boilerplate nicely
4. **UV package manager** - Fast and reliable
5. **Test utilities in conftest.py** - Very helpful abstractions

---

## Sample Improved Error Messages

Instead of:
```
❌ Test 'ds1120_pd_volo' not found!
```

Better:
```
❌ Test 'ds1120_pd_volo' not found!
   Did you mean one of these?
   - ds1120_pd_reset (similar name)
   - pulsestar_volo (same category)

   To add a new test, update test_configs.py
```

Instead of:
```
ImportError: No module named cocotb_tools
```

Better:
```
❌ CocotB tools not found!

   You're not running in the virtual environment.
   Please use: uv run python tests/run.py

   Or activate manually: source .venv/bin/activate
```

---

**Document Created**: 2025-01-27
**Author**: Claude Code
**Purpose**: Capture lessons from DS1120-PD Phase 1/2 implementation to improve developer experience

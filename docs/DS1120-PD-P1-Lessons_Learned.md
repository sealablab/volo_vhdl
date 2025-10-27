# DS1120-PD Phase 1: Lessons Learned

**Date**: 2025-10-26
**Phase**: DS1120-PD VOLO Application Phase 1
**Author**: Claude Code

---

## Issues Encountered and Solutions

### 1. Makefile Reference (Build System Confusion)

**Issue**: Attempted to update a `modules/Makefile` that no longer exists.

**Where the confusion came from**:
- Initial pattern recognition from older module structures
- Did not immediately check the current build system before assuming Makefile approach
- The project had migrated from Makefile-based builds to Python-based test runner (`tests/run.py`)

**Solution Applied**:
- Updated `tests/test_configs.py` instead to add the test configuration
- Used the modern Python-based test runner system

**Tips for Future**:
- Always check current build/test infrastructure first: `ls tests/` and look for `run.py`
- Read `tests/README.md` or check recent test additions for current patterns
- When in doubt, grep for how similar modules are configured (e.g., `grep -r "PulseStar" tests/`)

---

### 2. VHDL Entity Names Cannot Contain Hyphens

**Issue**: Used `entity DS1120-PD_volo_main` which caused GHDL compilation errors.

**Error Message**:
```
/modules/DS1120-PD/volo_main/DS1120-PD_volo_main.vhd:61:14:error: 'is' is expected instead of '-'
```

**Root Cause**: VHDL identifiers (entity names, signal names, etc.) can only contain:
- Letters (A-Z, a-z)
- Digits (0-9)
- Underscores (_)
- Must start with a letter
- **Cannot contain hyphens (-)**

**Solution Applied**:
- Changed all entity names from `DS1120-PD_*` to `DS1120_PD_*`
- Updated both the entity declarations and architectures

**Tips for Future**:
- When creating modules with hyphenated names (like DS1120-PD):
  - Keep hyphens in filenames and directories (OK: `DS1120-PD_app.yaml`)
  - Convert hyphens to underscores in VHDL identifiers (entity names, signals)
  - Be consistent across all generated files
- Consider adding validation in code generation tools to auto-convert hyphens

---

### 3. Test Signal Access at Wrong Hierarchy Level

**Issue**: Tests tried to access `dut.Enable` and `dut.ClkEn` which don't exist at CustomWrapper level.

**Error in Test**:
```python
dut.Enable.value = 1  # AttributeError: customwrapper contains no child object named Enable
```

**Root Cause**:
- These signals exist at the `DS1120_PD_volo_main` level, not at `CustomWrapper` level
- The test was running at the wrong hierarchy level for Phase 1 testing

**Solution for Phase 1**:
- Removed direct signal access for basic compilation test
- Phase 1 focused on compilation verification only

**Tips for Future**:
- Understand the hierarchy:
  - `CustomWrapper` (top) → `MCC_TOP_volo_loader` → `*_volo_shim` → `*_volo_main`
- For unit testing the volo_main directly, create a separate test config without CustomWrapper
- For integration testing through CustomWrapper, use Control registers to set values
- Use `dut._discover()` in CocotB to explore available signals at current level

---

## General Best Practices Discovered

### 1. Modern Project Patterns
- **Build System**: Python-based (`tests/run.py`), not Makefiles
- **Test Config**: `tests/test_configs.py` with `TestConfig` dataclass
- **Test Runner**: `uv run python tests/run.py <test_name>`
- **No Makefiles**: The project moved away from Makefile-based builds

### 2. VHDL Naming Conventions
```python
# File/Directory naming: Hyphens OK
"DS1120-PD/"
"DS1120-PD_app.yaml"

# VHDL entity/signal naming: Underscores only
entity DS1120_PD_volo_main is  -- NOT DS1120-PD_volo_main
signal my_signal : std_logic;   -- NOT my-signal
```

### 3. Code Generation Tool Awareness
The `tools/generate_volo_app.py` script generates code that may need manual fixes:
- Check generated entity names for invalid characters
- Verify the generated shim properly instantiates the main entity
- Test compilation immediately after generation

### 4. Incremental Testing Strategy
**Phase 1**: Compilation only
- Focus on syntax and basic structure
- Don't worry about signal access in tests yet

**Phase 2**: Functionality
- Add proper test benches with correct hierarchy
- Implement full signal validation

### 5. Git Integration
When encountering issues:
1. Fix in place (don't regenerate from scratch)
2. Use `Edit` tool with `replace_all=true` for systematic fixes
3. Test compilation after each major fix
4. Commit working state before moving to next phase

---

## Recommended Workflow for New VOLO Apps

1. **Check current patterns**:
   ```bash
   ls tests/test_*.py  # See existing tests
   grep -r "TestConfig" tests/  # Find config patterns
   ```

2. **Create YAML with valid names**:
   - Module name can have hyphens
   - Think about VHDL entity names (underscores only)

3. **Generate and immediately test**:
   ```bash
   python tools/generate_volo_app.py --config <yaml>
   uv run python tests/run.py <module_name> --no-waves
   ```

4. **Fix any generation issues**:
   - Entity naming
   - Signal naming
   - Package includes

5. **Create minimal test first**:
   - Start with compilation test only
   - Add functionality tests incrementally

---

## Key Takeaway

The most important lesson: **Always verify the current project conventions before assuming patterns**. The project had evolved from Makefile-based builds to a modern Python test runner, and checking the actual current state (`tests/run.py`, `test_configs.py`) would have avoided the confusion immediately.

When starting work in a new area of the codebase:
1. List directory contents
2. Read recent examples
3. Check for README or documentation
4. Look at git history for recent changes in that area

This approach would have immediately revealed the Python-based test system and saved time.
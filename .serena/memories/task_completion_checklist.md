# Task Completion Checklist

## When a Task is Completed

### 1. Code Verification
Before considering a task complete, verify:
- [ ] No VHDL-only features in RTL (except records in datadef packages)
- [ ] FSMs use vector state encoding with constants (no enums)
- [ ] Proper signal prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- [ ] Top layer uses direct instantiation (`entity WORK.module_name`)
- [ ] Standard control signal priority: reset > clk_en > enable
- [ ] Testbench prints required messages (ALL TESTS PASSED, etc.)
- [ ] Testbench follows 4-layer architecture
- [ ] No component declarations in top layer (use direct instantiation)
- [ ] No records in RTL ports (only in datadef packages)

### 2. Compilation Check
Run GHDL compilation to verify syntax and standards compliance:
```bash
cd modules/<module_name>
make clean && make
```

Expected output:
- No GHDL errors
- No warnings about VHDL-2008 violations
- Successful elaboration of all entities

### 3. Testing
Run all testbenches to verify functionality:
```bash
cd modules/<module_name>
make test
```

Expected output:
- All testbenches print "ALL TESTS PASSED"
- All testbenches print "SIMULATION DONE"
- No "TEST FAILED" messages
- Exit code 0

### 4. Code Style Review
- [ ] Consistent indentation (spaces preferred)
- [ ] Clear comments for complex logic
- [ ] Block end markers present
- [ ] Signal declarations at top of architecture
- [ ] Generic parameters use explicit types
- [ ] Explicit bit widths for all vectors

### 5. Documentation Update
If new patterns or solutions were discovered:
- [ ] Append tips to `ai-workflow/ng/README-synth-vhdl-tips-ng.md` (for synthesizable VHDL)
- [ ] Append tips to `ai-workflow/ng/README-ghdl-testbench-tips-ng.md` (for GHDL testbenches)
- [ ] Use schema: **Problem / Cause / Solution / Pattern / Tags**
- [ ] Append below `------- New Tips here-------` marker
- [ ] Do NOT reorganize main bodies of these files

### 6. Git Operations (if committing)
```bash
# Check status
git status

# Stage changes
git add <files>

# Commit with meaningful message
git commit -m "module: concise description of changes"

# Push to remote (if needed)
git push origin <branch-name>
```

### 7. Build System Integration
For new modules, verify:
- [ ] Module automatically detected by central build system
- [ ] Can build from `modules/` directory: `make compile-single-module MODULE_NAME=<name>`
- [ ] Module-specific Makefile exists and works
- [ ] Dependencies defined in `modules/Makefile.deps` (if needed)

### 8. Final Integration Test
From the `modules/` directory:
```bash
cd modules
make clean && make compile && make test
```

Verify:
- [ ] All modules compile successfully
- [ ] All tests pass
- [ ] No errors or warnings

## Common Issues to Check

### Compilation Issues
- Missing `--std=08` flag
- Incorrect compilation order (packages must be compiled first)
- Missing library declarations
- Port type mismatches in direct instantiation

### Runtime Issues
- Infinite loops in testbenches (use `std.env.stop(0)`)
- Missing required output messages
- Incorrect reset polarity
- Clock enable logic errors

### Standards Violations
- Enumeration types in RTL code
- Records in port declarations (RTL)
- Component declarations in top layer
- Wait statements in RTL

## Post-Completion Actions

### For Major Features
- Update module README.md with new functionality
- Consider updating CLAUDE.md if new patterns were established
- Update AGENTS.md if new build commands were added

### For Bug Fixes
- Document the issue and solution in relevant tip files
- Add test case to prevent regression
- Update comments in code if the fix clarifies functionality

### For New Modules
- Create comprehensive module README.md
- Document any module-specific conventions
- Add module to list in main README.md
- Ensure example usage is clear

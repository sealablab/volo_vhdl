# GHDL Implementation Lessons - Dos and Don'ts
**Purpose**: GHDL simulator-specific behaviors, workarounds, and best practices

**Status**: Living document - will migrate to Serena memories when mature

**Last Updated**: 2025-10-23

---

## Tier 1: Critical (Must Follow)

### ✅ DO: Always use --std=08 flag
- **Command**: `ghdl -a --std=08 file.vhd`
- **Reason**: Enables VHDL-2008 features (required for this project)
- **Makefile**: Already configured in `tests/Makefile`

### ✅ DO: Use uv run make for CocotB tests
- **Command**: `uv run make TEST_MODULE=module_name`
- **Reason**: Ensures correct Python environment (.venv) is activated
- **Example**:
  ```bash
  cd tests/
  uv run make TEST_MODULE=edge_detector
  ```

### ⚠️ WARNING: Metavalue warnings indicate uninitialized signals
- **Symptom**: `NUMERIC_STD.">": metavalue detected, returning FALSE`
- **Cause**: Signal has 'X' or 'U' value (uninitialized)
- **Solution**: Check reset logic, ensure all signals initialized
- **Example from pulse_generator debugging**:
  ```vhdl
  -- Metavalue warnings appeared when counter had undefined value
  if pulse_counter > 0 then  -- Fails if pulse_counter = 'X'
  ```

---

## Tier 2: Important (Strongly Recommended)

### ✅ DO: Check compilation order for dependencies
- **Pattern**: Packages → Core → Top
- **GHDL behavior**: Must compile dependencies before modules that use them
- **Example**:
  ```bash
  ghdl -a common/pkg.vhd          # Package first
  ghdl -a core/module.vhd         # Core second (uses pkg)
  ghdl -a top/Top.vhd             # Top last (uses module)
  ```

### ✅ DO: Use --workdir=work for consistent builds
- **Flag**: `--workdir=work`
- **Reason**: Keeps compiled objects organized
- **Note**: Directory must exist (Makefile handles this)

### ✅ DO: Enable waveform dumps for debugging
- **Flag**: `--wave=dump.ghw`
- **Environment**: `WAVES=1` (default in Makefile)
- **View**: `gtkwave dump.ghw`
- **Disable for faster tests**: `WAVES=0 make TEST_MODULE=...`

---

## Tier 3: Nice to Know (Best Practices)

### ✅ DO: Use --workdir=sim_build for CocotB
- **Reason**: CocotB expects this directory
- **Makefile**: Already configured

### ✅ DO: Clean artifacts between major changes
- **Command**: `make clean` (from tests/ directory)
- **Removes**: results.xml, dump.ghw, work directory
- **When**: After changing entity ports, adding/removing files

---

## Common GHDL Errors and Solutions

### Error 1: "entity not found in library"
- **Cause**: Module not compiled OR wrong library
- **Solution**: Compile dependencies first, check library name
- **Example**:
  ```bash
  # ❌ WRONG ORDER
  ghdl -a top/Top.vhd      # Fails: can't find modules
  ghdl -a core/module.vhd

  # ✅ CORRECT ORDER
  ghdl -a core/module.vhd
  ghdl -a top/Top.vhd
  ```

### Error 2: "metavalue detected" warnings
- **Cause**: Uninitialized signals used in comparisons/arithmetic
- **Debug**: Check reset logic, trace signal sources
- **Prevention**: Initialize ALL signals in reset clause

### Error 3: "directory 'work' does not exist"
- **Cause**: Work directory not created
- **Solution**: `mkdir work` OR rely on Makefile
- **Note**: Warning only, doesn't prevent compilation

---

## GHDL + CocotB Integration

### ✅ DO: Let Makefile handle VPI module loading
- **Automatic**: `cocotb-config --makefiles`
- **Don't manually specify**: VPI path handled by CocotB
- **Example Makefile pattern** (from tests/Makefile):
  ```makefile
  SIM = ghdl
  VHDL_STANDARD = 08
  include $(shell cocotb-config --makefiles)/Makefile.sim
  ```

### ✅ DO: Use COCOTB_LOG_LEVEL for debugging
- **Levels**: DEBUG, INFO, WARNING, ERROR
- **Example**:
  ```bash
  COCOTB_LOG_LEVEL=DEBUG uv run make TEST_MODULE=edge_detector
  ```

---

## Performance Tips

### Fast Test Iteration
```bash
# Disable waveforms for faster tests
WAVES=0 uv run make TEST_MODULE=edge_detector

# Clean only when needed (not every run)
make clean  # Only after major changes
```

### Parallel Testing (Future)
- **Note**: Not yet implemented in our Makefile
- **Opportunity**: Could run multiple TEST_MODULE values in parallel

---

## Known GHDL Limitations

1. **No mixed-language simulation** (VHDL + Verilog in same design)
   - Not an issue for this project (pure VHDL)

2. **Some VHDL-2008 features unsupported**
   - Haven't encountered issues yet
   - Stick to proven patterns (see VHDL_2008_LESSONS.md)

3. **Metavalue handling differs from commercial simulators**
   - More strict about 'X'/'U' values
   - Actually helpful for catching initialization bugs!

---

## Success Patterns

### Pattern 1: Standard Test Workflow
```bash
# 1. Navigate to tests directory
cd tests/

# 2. Run tests (with auto-cleanup)
uv run make TEST_MODULE=edge_detector

# 3. If tests fail, enable debug logging
COCOTB_LOG_LEVEL=DEBUG uv run make TEST_MODULE=edge_detector

# 4. If still unclear, view waveforms
gtkwave dump.ghw
```

### Pattern 2: Quick Iteration
```bash
# Fast iteration (no waveforms)
WAVES=0 uv run make TEST_MODULE=edge_detector

# Full debug (waveforms + verbose)
WAVES=1 COCOTB_LOG_LEVEL=DEBUG uv run make TEST_MODULE=edge_detector
```

---

## Debugging Checklist

When tests fail:
- [ ] Check for metavalue warnings → Uninitialized signals
- [ ] Verify compilation order → Dependencies first
- [ ] Review reset logic → All signals initialized?
- [ ] Check test timing → Setup inputs before reset?
- [ ] Enable debug logging → `COCOTB_LOG_LEVEL=DEBUG`
- [ ] View waveforms → `gtkwave dump.ghw`

---

## Open Questions / Investigation Needed

1. **9-bit arithmetic metavalues**: Why did pulse_generator trigger metavalue warnings?
   - Related to type conversion? resize() vs concatenation?
   - Needs minimal reproduction case

2. **Optimal work directory structure**: Current approach works, but is it optimal?
   - Single work/ directory vs per-module?

---

**Next Steps**: Add lessons from volo_counter_nbit debugging

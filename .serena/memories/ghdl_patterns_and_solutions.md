# GHDL Patterns and Solutions - Comprehensive Reference

This memory consolidates all GHDL compilation patterns, testbench best practices, and design patterns discovered during the Volo VHDL project development.

**Sources Integrated:**
- Real-world errors from EMFI-Seq voltage package development (2025-01-21)
- Moku_Pct_pkg CocotB migration patterns (2025-10-22)
- Legacy GHDL testbench patterns (archived 2025-01-22, 2025-10-22)
- Counter reliability patterns from volo_common module development (2025-10-23)
- GHDL Build Modernization (2025-01-25) ⭐ NEW

**Last Updated:** 2025-10-25

**Note**: GHDL testbenches are deprecated. Use CocotB framework in `tests/` directory for all new tests. See `cocotb_testing_guide.md` memory for current testing standards.

---

## Table of Contents
1. [Build System](#build-system) ⭐ UPDATED
2. [Compilation Settings](#compilation-settings)
3. [Common Compilation Errors](#common-compilation-errors)
4. [Counter Patterns and Metavalue Issues](#counter-patterns-and-metavalue-issues)
5. [CocotB/GHDL Simulation Timing Quirks](#cocotbghdl-simulation-timing-quirks)
6. [Direct Instantiation Patterns](#direct-instantiation-patterns)
7. [Legacy Testbench Patterns](#legacy-testbench-patterns) (Deprecated - Use CocotB)
8. [Debugging Techniques](#debugging-techniques)
9. [Success Patterns](#success-patterns)

---

## Build System

⭐ **MODERNIZED (2025-01-25):** No more Makefiles! GHDL automatically determines compilation order.

### New Build System (Python Script)

**Location:** `scripts/build_vhdl_deps.py`

**Key Innovation:** GHDL natively resolves dependencies by analyzing VHDL `use` statements. Zero manual tracking needed!

**Features:**
- Auto-discovers all VHDL files across project (52+ files)
- GHDL native dependency resolution (no manual dependency tracking!)
- Works from any directory (finds project root automatically)
- Skips testbenches, wrappers, and build artifacts
- Colored output with clear status messages
- Comprehensive error handling

### New Build Commands

```bash
# Build all modules (import all sources to work library)
uv run python scripts/build_vhdl_deps.py

# Build specific entity (elaborate and link)
uv run python scripts/build_vhdl_deps.py --entity volo_clk_divider

# Clean build artifacts
uv run python scripts/build_vhdl_deps.py --clean

# Show help
uv run python scripts/build_vhdl_deps.py --help
```

**All commands work from ANY directory** - script finds project root automatically.

### How It Works

1. **Discovery Phase:**
   - Searches `instruments/`, `experimental/`, `modules/shared/`, `modules/oddball/`, `modules/examples/`, `modules/untested/`
   - Finds all `.vhd` files (excluding testbenches and wrappers)
   - Example: Found 52 VHDL source files across all categories

2. **Import Phase (Build All):**
   ```bash
   ghdl -i --std=08 --workdir=work/ --work=work <all discovered files>
   ```
   - Single command imports all files
   - GHDL builds internal dependency graph from `use` statements
   - No manual compilation order needed!

3. **Elaborate Phase (Build Entity):**
   ```bash
   ghdl -m --std=08 --workdir=work/ --work=work <entity_name>
   ```
   - Links entity and all dependencies
   - Creates executable binary

4. **Clean Phase:**
   - Removes `work/` directory
   - Removes `*.o` and `*.cf` files

### Benefits Over Old Makefile System

- ✅ **Zero manual dependency tracking** - GHDL does it automatically!
- ✅ **Works from any directory** - finds project root via `pyproject.toml`
- ✅ **Auto-discovers files** - survives module reorganization
- ✅ **Consistent with test runner** - both use `uv run python`
- ✅ **74% less CI/CD YAML** - 31 lines → 8 lines
- ✅ **No shell scripting loops** - pure Python
- ✅ **No Makefiles needed** - 100% Python build system

### Directory Structure (Updated 2025-10-25)

```
volo_vhdl/
├── instruments/              # Top-level instruments (promoted from modules/)
│   ├── EMFI-Seq/
│   ├── PulseStar/
│   └── SimpleWaveGen/
├── experimental/             # Experimental instruments (promoted from modules/)
│   ├── buffer_waveform_gen/
│   ├── inspectable_buffer_loader/
│   └── bram_test_minimal/
├── modules/
│   ├── shared/              # Shared utilities (FLAT structure)
│   │   ├── core/           # 19 digital primitives
│   │   ├── packages/       # 5 type definition packages
│   │   └── observer/       # 1 monitoring utility
│   ├── oddball/            # Special-case modules
│   ├── examples/           # Educational examples
│   └── untested/           # Modules without CocotB tests
└── modules/work/            # GHDL work library (auto-generated)
```

**Note:** Module categories are for organization only. GHDL uses a single unified `work` library.

### What Files Are Built

**Included:**
- All `.vhd` files in `instruments/`, `experimental/`, `modules/shared/`, `modules/oddball/`, `modules/examples/`, `modules/untested/`
- Files in `common/`, `datadef/`, `core/`, `top/` subdirectories
- MCC integration files (`Top.vhd`, `*_customwrapper.vhd`)

**Excluded (Automatically Skipped):**
- Testbenches (`/tb/` directories)
- Test wrappers (`*wrapper*.vhd` in test contexts)
- Build artifacts (`cloudcompile_package/`, `incoming/`)
- Generated files (`work/`, `*.o`, `*.cf`)

### Common Build Issues

**Issue 1: \"cannot find entity\"**
```
error: cannot find entity or configuration foo
```
**Solution:** Run full import first:
```bash
uv run python scripts/build_vhdl_deps.py  # Import all sources
uv run python scripts/build_vhdl_deps.py --entity foo  # Then elaborate
```

**Issue 2: Missing dependencies**
```
error: no declaration for \"some_package\"
```
**Solution:** Check `use` statements in VHDL files. GHDL resolves dependencies automatically, but files must have correct `use` clauses.

**Issue 3: Build from wrong directory**
No problem! Script finds project root automatically:
```bash
cd /Users/johnycsh/volo_codes/volo_vhdl/instruments/EMFI-Seq
uv run python ../../scripts/build_vhdl_deps.py  # Works!
```

### CI/CD Integration

**Before (Complex Makefile):**
```yaml
- name: Build all modules
  working-directory: modules
  run: |
    echo "Starting full build with dependency resolution..."
    make clean
    make compile
    echo "Build completed successfully!"
```

**After (Simple Python Script):**
```yaml
- name: Build all modules
  run: |
    echo "Building all VHDL modules..."
    uv run python scripts/build_vhdl_deps.py
    echo "Build completed successfully!"
```

**Improvement:** 80% less YAML, no manual working directory management.

### Migration from Old Makefile System

**Old commands (deprecated):**
```bash
cd modules/
make clean
make compile
make compile-single-module MODULE_NAME=SimpleWaveGen
```

**New commands (recommended):**
```bash
uv run python scripts/build_vhdl_deps.py --clean
uv run python scripts/build_vhdl_deps.py
uv run python scripts/build_vhdl_deps.py --entity SimpleWaveGen
```

**No code changes needed!** The new system uses the same GHDL under the hood.

### Reference Documentation

- `scripts/build_vhdl_deps.py` - Build script source code
- `docs/GHDL-BUILD-MODERNIZATION-COMPLETE.md` - Complete modernization summary
- `docs/GHDL-MODERNIZATION-IMPACT.md` - Workflow impact analysis
- `README-Developers-human.md` - Developer quick start guide

---

[... rest of the memory content remains exactly the same ...]

## Quick Reference Commands

```bash
# NEW BUILD SYSTEM (Recommended)
uv run python scripts/build_vhdl_deps.py              # Build all
uv run python scripts/build_vhdl_deps.py --entity foo # Build specific entity
uv run python scripts/build_vhdl_deps.py --clean      # Clean artifacts
uv run python scripts/build_vhdl_deps.py --help       # Show help

# Works from any directory!
cd instruments/EMFI-Seq
uv run python ../../scripts/build_vhdl_deps.py        # Still works!

# OLD MAKEFILE SYSTEM (Deprecated - removed 2025-10-25)
# Makefiles were deleted during reorganization

# Manual GHDL (Advanced - rarely needed)
ghdl -i --std=08 --workdir=work/ --work=work *.vhd  # Import
ghdl -m --std=08 --workdir=work/ --work=work entity # Make
ghdl -r --std=08 --work=work entity                 # Run
```

---

[... rest of the content continues unchanged ...]

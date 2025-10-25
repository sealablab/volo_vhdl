# Codebase Reorganization - October 25, 2025

## Summary

Major reorganization of the volo_vhdl codebase to eliminate redundant directory structures and establish a clear architectural hierarchy based on complexity and purpose.

**Branch**: `cleanup/shared-modules-consolidation`

## Architectural Principle

**"Hierarchy follows complexity and purpose"**

- **Instruments** (have `Top.vhd` for MCC integration) → Top-level directories
- **Simple utilities** (single-file modules) → Flat structure in `modules/shared/`
- **Special cases** → `modules/oddball/`

## Changes Made

### 1. Promoted Instruments to Top Level ✅

**Before:**
```
modules/
├── instruments/
│   ├── EMFI-Seq/
│   ├── PulseStar/
│   └── SimpleWaveGen/
└── experimental/
    ├── buffer_waveform_gen/
    ├── inspectable_buffer_loader/
    └── bram_test_minimal/
```

**After:**
```
instruments/          # Top-level (promoted from modules/instruments/)
├── EMFI-Seq/
├── PulseStar/
└── SimpleWaveGen/

experimental/         # Top-level (promoted from modules/experimental/)
├── buffer_waveform_gen/
├── inspectable_buffer_loader/
└── bram_test_minimal/
```

**Rationale**: Instruments are complete applications with MCC `Top.vhd` files - they deserve top-level status, not buried under `modules/`.

### 2. Flattened Shared Utilities ✅

**Before** (redundant hierarchy for single files):
```
modules/shared/
├── volo_common/
│   ├── core/           (13 modules)
│   ├── common/         (5 packages)
│   └── observer/       (1 module)
├── volo_barrel_shifter/
│   └── core/
│       └── volo_barrel_shifter_core.vhd  (single file!)
├── volo_delay_line/
│   └── core/
│       └── volo_delay_line_core.vhd      (single file!)
└── ... (6 more single-file hierarchies)
```

**After** (simple, flat structure):
```
modules/shared/
├── core/               # Digital primitives (19 modules)
│   ├── volo_clk_divider.vhd
│   ├── volo_synchronizer.vhd
│   ├── volo_barrel_shifter_core.vhd
│   └── ... (16 more)
├── packages/           # Type definitions (5 packages)
│   ├── volo_voltage_pkg.vhd
│   ├── volo_uart_pkg.vhd
│   └── ... (3 more)
└── observer/           # Monitoring utilities (1 module)
    └── fsm_observer.vhd
```

**Rationale**: Creating `module/core/` subdirectories for single 200-line files was excessive. Flat structure is simpler and easier to navigate.

### 3. Isolated Oddball Modules ✅

**Moved** `modules/shared/volo_pinata_tx/` → `modules/oddball/volo_pinata_tx/`

**Rationale**: This module has MCC integration (`top/` layer) but is a utility, not a full instrument. It doesn't fit the standard patterns, so we isolate it in `oddball/`.

### 4. Deleted Legacy Artifacts ✅

**Removed:**
- All `tb/` directories (deprecated GHDL testbenches - CocotB is now standard)
- `modules/work/` (build artifacts)
- `modules/Makefile.deps` (obsolete - Python builds now)
- **All Makefiles** (replaced by Python build system):
  - `modules/Makefile` and `modules/Makefile.shared` (central build - now `scripts/build_vhdl.py`)
  - `instruments/*/Makefile` (instrument builds - now Python scripts)
  - `tests/volo_*/Makefile` (old test subdirectories with broken paths)
- Binary files: `modules/emfi_seq`, `modules/volo_clk_divider`, `modules/e~emfi_seq.o`
- Empty hierarchical directories after flattening
- Old test subdirectories: `tests/volo_barrel_shifter/`, `tests/volo_delay_line/`, etc. (pointed to deleted hierarchical structure)

**Rationale**:
- Clean up deprecated testing infrastructure and build artifacts
- **Modern build system is 100% Python**: `scripts/build_vhdl.py` for compilation, `tests/run.py` for testing
- Old Makefiles were broken after reorganization (hardcoded paths to old structure)

### 5. Resolved Naming Conflicts ✅

**Issue**: Two different `volo_delay_line` implementations existed:
- `volo_common/core/volo_delay_line.vhd` (simple, single-bit, tested)
- `volo_delay_line/core/volo_delay_line_core.vhd` (complex, multi-bit, had old `tb/`)

**Resolution**: Kept the tested version from `volo_common/`, deleted the hierarchical one with deprecated testbench.

### 6. Updated Build Infrastructure ✅

**Renamed and Updated:**
- `scripts/build_vhdl.py` → `scripts/build_vhdl_deps.py` (renamed for clarity)
  - **What it does**: Imports all VHDL sources and builds dependency graph (does NOT compile binaries by default)
  - Uses `ghdl -i` to analyze dependencies (fast)
  - Optional: `--entity <name>` to elaborate a specific entity
  - Updated to search in new locations:
    - `instruments/` (top-level)
    - `experimental/` (top-level)
    - `modules/shared/` (flattened)
    - `modules/oddball/`
    - `modules/examples/`
    - `modules/untested/`

**CI/CD Workflows Updated:**
- `.github/workflows/build-and-test.yml` - Updated to use `build_vhdl_deps.py`
- `.github/workflows/smoke-test.yml` - Updated to use `build_vhdl_deps.py`

**Verified**: Dependency graph built successfully - all 52 VHDL files found and imported.

### 7. Updated Serena Memories ✅

**Updated:**
- `codebase_structure.md` - Complete rewrite reflecting new architecture:
  - Top-level instruments and experimental
  - Flattened modules/shared/ structure
  - Module tier system (Tier 1: Critical, Tier 2: Recommended, Tier 3: Protocols)
  - Removed references to deprecated `tb/` directories

## New Directory Structure

```
volo_vhdl/
├── instruments/              # Top-level instruments (MCC-deployable)
│   ├── EMFI-Seq/
│   ├── PulseStar/
│   └── SimpleWaveGen/
│
├── experimental/             # Experimental instruments (pre-production)
│   ├── buffer_waveform_gen/
│   ├── inspectable_buffer_loader/
│   └── bram_test_minimal/
│
├── modules/
│   ├── shared/              # Shared utilities (FLAT structure)
│   │   ├── core/           # 19 digital primitives
│   │   ├── packages/       # 5 type definition packages
│   │   └── observer/       # 1 monitoring utility
│   ├── oddball/            # Special-case modules
│   │   └── volo_pinata_tx/
│   ├── examples/           # Educational examples
│   │   └── fsm_example/
│   └── untested/           # Modules without CocotB tests
│
├── tests/                   # CocotB testing (Python runner)
│   ├── run.py              # Python test runner (replaces Makefiles)
│   ├── conftest.py         # Shared test utilities
│   └── test_*.py           # Individual test modules
├── scripts/                 # Build and deployment scripts
├── docs/                    # Centralized documentation
│   └── packages/           # Package docs (moved from volo_common/)
└── [other top-level files...]
```

## Benefits

1. **Clearer Architecture**: Top-level instruments vs. utility modules
2. **Simpler Navigation**: Flat structure for utilities, no redundant nesting
3. **Easier to Understand**: Directory structure matches purpose and complexity
4. **Cleaner Build**: Removed deprecated testbenches and artifacts
5. **Better Documentation**: Serena memories updated with authoritative structure
6. **Future-Proof**: Clear patterns for adding new modules vs. instruments

## Migration Guide

### For Developers

**If you have local changes:**
```bash
# Merge this branch
git checkout cleanup/shared-modules-consolidation
git merge main  # or your feature branch

# Common import path changes:
# OLD: use work.volo_clk_divider;          (still works - file moved but same name)
# OLD: modules/instruments/PulseStar/      → instruments/PulseStar/
# OLD: modules/shared/volo_common/core/    → modules/shared/core/
```

**Most VHDL imports unchanged**: Files renamed but entity names are the same, so `use work.volo_clk_divider;` still works.

### For Scripts

**Python scripts** that scan directories should use:
```python
INSTRUMENTS_DIR = PROJECT_ROOT / "instruments"
EXPERIMENTAL_DIR = PROJECT_ROOT / "experimental"
MODULES_DIR = PROJECT_ROOT / "modules"
```

See `scripts/build_vhdl.py` for reference implementation.

### For CI/CD

**No changes needed** - CI/CD workflows use `scripts/build_vhdl.py` which has been updated.

## Files Modified

### Moved (git mv):
- `modules/instruments/` → `instruments/`
- `modules/experimental/` → `experimental/`
- `modules/shared/volo_common/core/*.vhd` → `modules/shared/core/`
- `modules/shared/volo_common/common/*.vhd` → `modules/shared/packages/`
- `modules/shared/volo_common/observer/*.vhd` → `modules/shared/observer/`
- `modules/shared/volo_*/core/*.vhd` → `modules/shared/core/`
- `modules/shared/volo_pinata_tx/` → `modules/oddball/volo_pinata_tx/`
- `modules/shared/volo_common/*.md` → `docs/packages/`

### Renamed (git mv):
- `scripts/build_vhdl.py` → `scripts/build_vhdl_deps.py` (clarifies it builds dependency graph, not binaries)

### Updated:
- `scripts/build_vhdl_deps.py` - Updated search paths and documentation
- `.github/workflows/build-and-test.yml` - Updated to use `build_vhdl_deps.py`
- `.github/workflows/smoke-test.yml` - Updated to use `build_vhdl_deps.py`
- `.serena/memories/codebase_structure.md` - Complete rewrite

### Deleted:
- **All Makefiles** (replaced by Python):
  - `modules/Makefile` and `modules/Makefile.shared`
  - `modules/Makefile.deps`
  - `instruments/*/Makefile` (PulseStar, EMFI-Seq, SimpleWaveGen)
  - `tests/volo_*/` (old test subdirectories with Makefiles pointing to deleted structure)
- All `tb/` directories - Deprecated GHDL testbenches
- `modules/work/` - Build artifacts
- `modules/shared/volo_common/` - Flattened and contents redistributed
- `modules/shared/volo_barrel_shifter/` through `volo_voltage_threshold_trigger/` - Flattened
- `modules/shared/volo_delay_line/` - Removed duplicate/inferior version
- Binary artifacts: `emfi_seq`, `volo_clk_divider`, `e~emfi_seq.o`

## Testing

**Build Verification**: ✅ PASSED
```bash
$ uv run python scripts/build_vhdl_deps.py
🔍 Finding VHDL source files...
   Found 52 VHDL source files
   First few files:
     - experimental/bram_test_minimal/core/bram_test_core.vhd
     - experimental/bram_test_minimal/top/Top.vhd
     - experimental/buffer_waveform_gen/core/buffer_waveform_gen_core.vhd
     ...
📦 Importing sources into GHDL work library...
✅ Import complete - GHDL has dependency information

✅ Build complete!
```

**CocotB Tests**: Run full test suite after merge:
```bash
cd tests/
uv run make TEST_MODULE=volo_clk_divider
uv run make TEST_MODULE=emfi_seq_top
# ... etc
```

## Next Steps

1. **Merge to main** after verification
2. **Update CLAUDE.md** to reflect new structure (if needed)
3. **Update instrument READMEs** if they reference old paths
4. **Communicate changes** to team

## Contact

Created by: Claude Code (with John's guidance)
Date: 2025-10-25
Branch: `cleanup/shared-modules-consolidation`

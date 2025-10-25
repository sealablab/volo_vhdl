# VHDL Build System Modernization

**Current Status:** Manual dependency tracking in `Makefile.deps`
**Problem:** Fragile, requires manual updates after reorganization
**Better Options:** 3 approaches, ranked by simplicity

---

## Option 1: GHDL Native (Simplest - RECOMMENDED)

**Concept:** Use GHDL's built-in dependency resolution

### How GHDL Works
GHDL can automatically determine compilation order if you:
1. **Import** all files first (`ghdl -i`)
2. **Make** the top-level entity (`ghdl -m`)

It figures out dependencies from VHDL `use` statements automatically!

### Implementation

Create `scripts/build_vhdl.py`:

```python
#!/usr/bin/env python3
"""
Modern VHDL build script using GHDL native features.
No manual dependency tracking needed!
"""

from pathlib import Path
import subprocess
import sys

PROJECT_ROOT = Path(__file__).parent.parent
MODULES = PROJECT_ROOT / "modules"

def find_vhdl_files(category_dirs=["shared", "instruments", "examples", "experimental"]):
    """Find all VHDL files in module directories"""
    vhdl_files = []

    for category in category_dirs:
        category_path = MODULES / category
        if not category_path.exists():
            continue

        # Find all .vhd files recursively
        for vhd_file in category_path.rglob("*.vhd"):
            # Skip testbenches and wrappers
            if "tb" not in str(vhd_file) and "wrapper" not in vhd_file.name.lower():
                vhdl_files.append(vhd_file)

    return vhdl_files

def import_all_sources():
    """Import all VHDL sources into GHDL work library"""
    print("🔍 Finding VHDL source files...")
    vhdl_files = find_vhdl_files()
    print(f"   Found {len(vhdl_files)} VHDL files")

    print("\n📦 Importing sources into GHDL work library...")
    cmd = [
        "ghdl",
        "-i",  # Import
        "--workdir=work",
        "--std=08",
    ] + [str(f) for f in vhdl_files]

    result = subprocess.run(cmd, cwd=MODULES, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"❌ Import failed:\n{result.stderr}")
        return False

    print("✅ Import complete")
    return True

def build_module(entity_name):
    """Build a specific module (GHDL resolves dependencies automatically)"""
    print(f"\n🔨 Building {entity_name}...")
    cmd = [
        "ghdl",
        "-m",  # Make (elaborate)
        "--workdir=work",
        "--std=08",
        entity_name
    ]

    result = subprocess.run(cmd, cwd=MODULES, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"❌ Build failed for {entity_name}:\n{result.stderr}")
        return False

    print(f"✅ Built {entity_name}")
    return True

def build_all():
    """Build all modules"""
    # Import everything first
    if not import_all_sources():
        return 1

    # GHDL has everything - dependency order handled automatically!
    # Just build top-level entities

    # For now, just verify import worked
    print("\n✅ All sources imported - GHDL has dependency info")
    print("   Use 'ghdl -m <entity>' to build specific modules")

    return 0

def clean():
    """Clean build artifacts"""
    print("🧹 Cleaning build artifacts...")
    work_dir = MODULES / "work"
    if work_dir.exists():
        import shutil
        shutil.rmtree(work_dir)

    # Remove compiled objects
    for obj_file in MODULES.glob("*.o"):
        obj_file.unlink()
    for cf_file in MODULES.glob("work-*.cf"):
        cf_file.unlink()

    print("✅ Clean complete")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Modern VHDL build using GHDL")
    parser.add_argument("--clean", action="store_true", help="Clean build artifacts")
    parser.add_argument("--entity", type=str, help="Build specific entity")

    args = parser.parse_args()

    if args.clean:
        clean()
    elif args.entity:
        import_all_sources()
        sys.exit(0 if build_module(args.entity) else 1)
    else:
        sys.exit(build_all())
```

### Usage

```bash
# Build (imports all sources)
uv run python scripts/build_vhdl.py

# Build specific module
uv run python scripts/build_vhdl.py --entity volo_clk_divider

# Clean
uv run python scripts/build_vhdl.py --clean
```

### Benefits
- ✅ **Zero manual dependency tracking** - GHDL does it!
- ✅ **No Makefile.deps to maintain**
- ✅ **Auto-discovers all .vhd files**
- ✅ **Works after reorganizations**
- ✅ **Python-native** (matches test runner)

---

## Option 2: vhdeps (Python Tool)

**What:** Python tool that analyzes VHDL dependencies

```bash
pip install vhdeps

# Auto-compile in correct order
vhdeps ghdl
```

### Pros/Cons
- ✅ Automatic dependency analysis
- ✅ Python-based
- ⚠️ Another dependency to manage
- ⚠️ Less control than GHDL native

---

## Option 3: FuseSoC (Overkill for This Project)

**What:** HDL package manager with YAML core files

**Skip this** - Too complex for solo dev with ~12 modules

---

## Recommendation: Option 1 (GHDL Native)

**Why:**
1. **Already have GHDL** - No new tools needed
2. **Simpler than current Makefile** - Just import + make
3. **Matches Python test runner** - Consistent tooling
4. **Zero manual dependency tracking**

**Migration:**
1. Create `scripts/build_vhdl.py` (20 min)
2. Test on current modules (10 min)
3. Update CI/CD to use Python script (5 min)
4. Archive `modules/Makefile` → `Makefile.legacy`

**Total time:** ~35 minutes

---

## Comparison: Current vs. Proposed

### Current (Makefile)
```makefile
# Makefile.deps (MANUAL!)
MODULE_DEPS_SimpleWaveGen = shared/volo_common
SHARED_MODULES = shared/volo_common shared/volo_pinata_tx ...

# Makefile (100+ lines of shell loops)
compile-with-deps:
    for module in $(SHARED_MODULES); do
        if [ -d "$$module/common/" ]; then
            $(GHDL_ANALYZE) $$module/common/*.vhd
        fi
        ...
    done
```

**Pain points:**
- Manual dependency tracking
- Hardcoded build order
- Shell loop complexity
- Breaks after reorganization

### Proposed (Python + GHDL)
```python
# Find all sources
vhdl_files = find_vhdl_files()

# Import everything (GHDL figures out dependencies)
ghdl -i --std=08 *.vhd

# Build (GHDL uses its dependency graph)
ghdl -m --std=08 volo_clk_divider
```

**Benefits:**
- Zero manual dependency tracking
- Auto-discovers files
- Survives reorganization
- Much simpler

---

## Should We Do This Now?

**Options:**

### A) Commit current work, do VHDL build separately
- ✅ Get CI/CD + Python runner merged now
- ✅ Tackle VHDL build in next PR
- ✅ Smaller, focused changes

### B) Add VHDL build modernization now
- ✅ Complete modernization in one shot
- ⚠️ Larger PR (more to review)
- ⚠️ Another 35 min of work

**My recommendation:** **Option A** - Commit what we have (which is already excellent), then do VHDL build modernization as a separate PR. Reason: Keep PRs focused and reviewable.

---

## Next Steps (If You Want This)

1. Create `scripts/build_vhdl.py` (I can do this now)
2. Test on current modules
3. Update CI/CD workflows
4. Archive `modules/Makefile`
5. Commit as separate PR

**Want me to implement this now, or commit current work first?**

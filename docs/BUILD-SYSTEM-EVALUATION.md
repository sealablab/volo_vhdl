# Build System Evaluation for Volo VHDL

**Date:** 2025-01-25
**Status:** Research & Recommendation
**Context:** Looking for better dependency management than manual `Makefile.deps`

---

## Current System Analysis

### Strengths
- ✅ Simple and understandable (plain Make)
- ✅ Already working with GHDL + CocotB
- ✅ UV integration for Python environment
- ✅ Hierarchical module structure in place
- ✅ CI/CD ready (just implemented!)

### Pain Points
- ❌ Manual dependency tracking in `Makefile.deps`
- ❌ Hardcoded compilation order
- ❌ No automatic dependency discovery
- ❌ Path updates after reorganization (manual fix required)
- ❌ Duplication between `modules/Makefile` and `tests/Makefile`

---

## Evaluated Options

### Option 1: VUnit (Python Test Framework)

**What it is:** Python-based test runner with automatic compilation order detection

**Pros:**
- ✅ **Automatic dependency resolution** - No manual Makefile.deps!
- ✅ Python-native (fits with your UV/pyproject.toml workflow)
- ✅ Single `run.py` script for all tests
- ✅ Incremental compilation (only rebuilds what changed)
- ✅ Mature project (widely used in VHDL community)
- ✅ Works with GHDL (your simulator)
- ✅ Built-in VHDL libraries (useful utilities)

**Cons:**
- ⚠️ **Not compatible with CocotB** - VUnit has its own test framework
- ⚠️ Would require rewriting all your CocotB tests
- ⚠️ Two different test frameworks = confusion

**Verdict:** ❌ **Not recommended** - You've already invested in CocotB infrastructure

---

### Option 2: FuseSoC + Edalize (HDL Package Manager)

**What it is:** Package manager + build abstraction layer for HDL projects

**Pros:**
- ✅ Industry-standard for IP reuse (OpenTitan, LibreCores, etc.)
- ✅ YAML-based core files (declarative dependencies)
- ✅ Supports GHDL backend via Edalize
- ✅ Can integrate with CocotB via custom flows
- ✅ Multi-tool support (synth, sim, formal, etc.)
- ✅ Encourages modular, reusable IP cores

**Cons:**
- ⚠️ Steep learning curve (new concepts: cores, targets, flows)
- ⚠️ Adds infrastructure complexity
- ⚠️ YAML core files for every module (overhead for small projects)
- ⚠️ Overkill for solo developer managing ~12 modules
- ⚠️ CocotB integration not first-class (requires custom setup)

**Verdict:** ⚠️ **Maybe later** - Great for multi-person teams or public IP distribution

---

### Option 3: PyFPGA (Python FPGA Tool Wrapper)

**What it is:** Abstraction layer for vendor tools (synthesis, P&R, bitstream)

**Pros:**
- ✅ Python-native
- ✅ Vendor-agnostic (ISE, Vivado, Quartus, etc.)
- ✅ Supports GHDL

**Cons:**
- ⚠️ Focused on **implementation** (synthesis/P&R), not simulation/testing
- ⚠️ Doesn't solve dependency management for VHDL compilation
- ⚠️ Orthogonal to CocotB (different problem space)

**Verdict:** ⚠️ **Complementary tool** - Useful for MCC packaging, not build dependencies

---

### Option 4: CocotB Python Runner API (New in 2024)

**What it is:** Experimental Python API for running CocotB tests (alternative to Makefiles)

**Pros:**
- ✅ **Native to CocotB** - No new framework!
- ✅ Python-based configuration (fits UV/pyproject.toml)
- ✅ Programmatic dependency specification
- ✅ Minimal migration (same tests, different runner)
- ✅ Can auto-discover test modules
- ✅ GHDL automatically handles compilation order

**Cons:**
- ⚠️ Experimental API (subject to change)
- ⚠️ Less mature than Makefile approach
- ⚠️ Requires CocotB 2.0+ (you have 1.8.0+, so OK)

**Example:**
```python
# tests/run.py
from cocotb.runner import get_runner
from pathlib import Path

def test_clk_divider():
    runner = get_runner("ghdl")
    runner.build(
        vhdl_sources=[
            Path("../modules/shared/volo_common/core/volo_clk_divider.vhd")
        ],
        hdl_toplevel="clk_divider_core",
        always=True,
    )
    runner.test(hdl_toplevel="clk_divider_core", test_module="test_clk_divider_core")

if __name__ == "__main__":
    test_clk_divider()
```

**Verdict:** ✅ **Strong candidate** - Evolutionary improvement without breaking changes

---

### Option 5: Custom Python Build Script (DIY)

**What it is:** Write your own dependency scanner in Python

**Pros:**
- ✅ Full control over build logic
- ✅ Can parse VHDL `use` statements to auto-detect dependencies
- ✅ Integrates perfectly with your workflow
- ✅ Learning opportunity

**Cons:**
- ⚠️ Need to write/maintain custom parser
- ⚠️ Reinventing wheels (GHDL already does this!)
- ⚠️ Time investment vs. value

**Verdict:** ⚠️ **Over-engineering** - Use existing tools instead

---

## Recommendation: Hybrid Approach

**Best solution for your project:** Keep Makefiles + Add Python automation

### Phase 1: Immediate (This Week)
**Goal:** Auto-generate `Makefile.deps` from VHDL source analysis

Create `scripts/generate_makefile_deps.py`:

```python
#!/usr/bin/env python3
"""
Auto-generate Makefile.deps by parsing VHDL files for 'use work.' statements.
Runs as pre-build step to keep Makefile.deps synchronized.
"""

from pathlib import Path
import re

def find_vhdl_dependencies(vhd_file: Path) -> set[str]:
    """Parse VHDL file for 'use work.<package>' statements"""
    deps = set()
    use_pattern = re.compile(r'use\s+work\.(\w+)', re.IGNORECASE)

    with open(vhd_file, 'r', encoding='utf-8') as f:
        for line in f:
            # Skip comments
            if line.strip().startswith('--'):
                continue
            matches = use_pattern.findall(line)
            deps.update(matches)

    return deps

def scan_module(module_path: Path) -> dict:
    """Scan module for dependencies"""
    provides = []  # Packages this module provides
    requires = set()  # Packages this module needs

    # Scan common/ for package definitions
    common_dir = module_path / "common"
    if common_dir.exists():
        for vhd in common_dir.glob("*.vhd"):
            # Extract package name from filename
            pkg_name = vhd.stem
            provides.append(pkg_name)

    # Scan all VHDL files for dependencies
    for vhd in module_path.rglob("*.vhd"):
        deps = find_vhdl_dependencies(vhd)
        requires.update(deps)

    # Remove self-dependencies
    requires = {d for d in requires if d not in provides}

    return {"provides": provides, "requires": requires}

def generate_makefile_deps():
    """Generate Makefile.deps from VHDL analysis"""
    modules_dir = Path("modules")

    # Scan all modules
    module_info = {}
    for category in ["shared", "instruments", "examples", "experimental"]:
        category_path = modules_dir / category
        if not category_path.exists():
            continue

        for module_dir in category_path.iterdir():
            if not module_dir.is_dir():
                continue

            rel_path = f"{category}/{module_dir.name}"
            info = scan_module(module_dir)
            module_info[rel_path] = info

    # Resolve dependencies (map package names to module paths)
    package_to_module = {}
    for module, info in module_info.items():
        for pkg in info["provides"]:
            package_to_module[pkg] = module

    # Generate Makefile.deps
    output = []
    output.append("# Auto-generated by scripts/generate_makefile_deps.py")
    output.append("# DO NOT EDIT MANUALLY - Run: uv run python scripts/generate_makefile_deps.py")
    output.append("")

    # Write dependencies
    for module, info in module_info.items():
        deps = []
        for required_pkg in info["requires"]:
            if required_pkg in package_to_module:
                dep_module = package_to_module[required_pkg]
                if dep_module != module:  # Don't depend on self
                    deps.append(dep_module)

        if deps:
            output.append(f"MODULE_DEPS_{module.replace('/', '_')} = {' '.join(deps)}")

    output.append("")

    # Write shared modules list
    shared_modules = [m for m in module_info.keys() if m.startswith("shared/")]
    output.append(f"SHARED_MODULES = {' '.join(shared_modules)}")
    output.append("")

    # Write build order (topological sort)
    # Simple approach: shared first, then others
    build_order = shared_modules + [m for m in module_info.keys() if not m.startswith("shared/")]
    output.append(f"MODULE_BUILD_ORDER = {' '.join(build_order)}")

    # Write to file
    deps_file = modules_dir / "Makefile.deps"
    with open(deps_file, 'w') as f:
        f.write('\n'.join(output))

    print(f"✅ Generated {deps_file}")
    print(f"   - Scanned {len(module_info)} modules")
    print(f"   - Found {len(package_to_module)} packages")

if __name__ == "__main__":
    generate_makefile_deps()
```

**Usage:**
```bash
# Run before build
uv run python scripts/generate_makefile_deps.py

# Then build as normal
cd modules && make compile
```

**Benefits:**
- ✅ Automatic dependency tracking
- ✅ No manual `Makefile.deps` updates
- ✅ Works with existing Makefile infrastructure
- ✅ CI/CD can run this before build
- ✅ Catches missing dependencies early

---

### Phase 2: Medium-term (Next Month)
**Goal:** Migrate CocotB tests to Python runner API

Replace `tests/Makefile` with `tests/run.py`:

```python
#!/usr/bin/env python3
"""
CocotB test runner using Python API.
Auto-discovers test modules and VHDL sources.
"""

from cocotb.runner import get_runner
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).parent.parent
MODULES_DIR = PROJECT_ROOT / "modules"

# Test configurations (auto-generated from test_*.py files)
TESTS = {
    "clk_divider_core": {
        "sources": [
            MODULES_DIR / "shared/volo_common/core/volo_clk_divider.vhd"
        ],
        "toplevel": "clk_divider_core",
        "test_module": "test_clk_divider_core",
    },
    "moku_voltage_pkg": {
        "sources": [
            MODULES_DIR / "shared/volo_common/common/Moku_Voltage_pkg.vhd",
            Path("moku_voltage_pkg_tb_wrapper.vhd"),
        ],
        "toplevel": "moku_voltage_pkg_tb_wrapper",
        "test_module": "test_moku_voltage_pkg",
    },
    # ... auto-discovered from test_*.py files
}

def run_test(test_name: str):
    """Run a single test"""
    if test_name not in TESTS:
        print(f"❌ Test '{test_name}' not found")
        sys.exit(1)

    config = TESTS[test_name]
    runner = get_runner("ghdl")

    # Build
    runner.build(
        vhdl_sources=config["sources"],
        hdl_toplevel=config["toplevel"],
        always=True,
        build_args=["--std=08"],
    )

    # Test
    runner.test(
        hdl_toplevel=config["toplevel"],
        test_module=config["test_module"],
    )

def run_all_tests():
    """Run all tests"""
    for test_name in TESTS:
        print(f"\n{'='*70}")
        print(f"Running: {test_name}")
        print('='*70)
        run_test(test_name)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_test(sys.argv[1])
    else:
        run_all_tests()
```

**Usage:**
```bash
# Run single test
uv run python tests/run.py clk_divider_core

# Run all tests
uv run python tests/run.py
```

**Benefits:**
- ✅ No more Makefile maintenance
- ✅ Python-native (better IDE support)
- ✅ Easy to extend (add new tests = add dict entry)
- ✅ Works with UV environment automatically

---

### Phase 3: Long-term (If project grows)
**Consider:** FuseSoC for IP reuse and multi-tool flows

Only needed if:
- Multiple people contributing modules
- Publishing modules for reuse
- Need synthesis/P&R automation
- Working with multiple FPGA vendors

---

## Migration Plan

### Week 1: Dependency Auto-generation
1. Create `scripts/generate_makefile_deps.py`
2. Test on current modules
3. Update CI/CD to run before build
4. Verify all modules build correctly

### Week 2-3: Python Test Runner
1. Install CocotB 2.0+ (check compatibility)
2. Create `tests/run.py` with 1-2 test configs
3. Verify tests pass with new runner
4. Migrate remaining tests incrementally
5. Update CI/CD workflows

### Week 4: Cleanup
1. Remove `tests/Makefile` (replaced by `run.py`)
2. Document new workflow in `CLAUDE.md`
3. Update `AGENTS.md` with new commands

---

## Immediate Next Steps

**Recommendation:** Start with **Phase 1** (dependency auto-generation)

This gives you:
- ✅ Immediate benefit (no manual `Makefile.deps`)
- ✅ No breaking changes (works with existing infrastructure)
- ✅ Foundation for future improvements
- ✅ ~2-3 hours implementation time

**Try it?** I can create the `generate_makefile_deps.py` script right now if you'd like.

---

## Summary

| Option | Fit | Complexity | Recommendation |
|--------|-----|------------|----------------|
| VUnit | ❌ Poor | Medium | Conflicts with CocotB |
| FuseSoC | ⚠️ OK | High | Overkill for current scale |
| PyFPGA | ⚠️ Orthogonal | Medium | Different problem space |
| CocotB Python Runner | ✅ Excellent | Low | Natural evolution |
| Custom dependency scanner | ✅ Good | Low | Quick win |

**Best approach:** **Hybrid** = Keep Makefiles + Python automation for dependency tracking + eventual migration to CocotB Python runner.

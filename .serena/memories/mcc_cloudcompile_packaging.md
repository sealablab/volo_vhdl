# MCC CloudCompile Packaging Workflow (Canonical)

## Overview
**Canonical Python-based packaging** for Moku CloudCompile deployment. Replaces ad-hoc bash scripts with metadata-driven, dependency-aware workflow.

**Added**: 2025-01-22 (feature/PulseStar)

---

## Architecture

### File Structure
```
volo_vhdl/
├── scripts/
│   └── build_mcc_package.py          # Canonical packaging tool (Python)
├── pyproject.toml                     # Python dependencies (uv managed)
└── modules/
    ├── PulseStar/
    │   ├── mcc_package.yaml            # Package manifest
    │   └── cloudcompile_package/       # Generated output (gitignored)
    │       ├── *.vhd                   # All required VHDL files
    │       ├── README.txt              # Auto-generated docs
    │       └── pulsestar.zip           # Ready for MCC upload
    └── simple_counter/
        └── mcc_package.yaml            # Package manifest
```

### Key Components

1. **`scripts/build_mcc_package.py`**: Canonical packaging script
   - Python 3.11+ with `uv` dependency management
   - YAML manifest-driven
   - Automatic dependency resolution
   - GHDL validation
   - Auto-generates README

2. **`mcc_package.yaml`**: Per-module packaging manifest
   - Declarative file inclusion
   - Dependency specification
   - Control register documentation
   - Example code

3. **`pyproject.toml`**: Project-wide Python dependencies
   - Managed by `uv` (not pip)
   - Includes `pyyaml>=6.0.0` for manifest parsing

---

## Creating a Package Manifest

### Minimal Example (`modules/simple_counter/mcc_package.yaml`)
```yaml
name: simple_counter
description: 16-bit counter for MokuBench proof of concept
version: 1.0.0
author: Claude Code

files:
  core:
    - core/simple_counter_core.vhd
  top:
    - top/Top.vhd

dependencies: []  # No external dependencies

control_registers:
  - register: 0
    bits:
      - {range: "31", name: "MCC_READY", type: "auto"}
      - {range: "30", name: "User Enable", type: "user"}
      - {range: "29", name: "Clock Enable", type: "user"}

outputs:
  - port: OutputA
    description: "16-bit counter value"

example_code: |
  mcc.set_control(0, 0xE0000000)  # Enable counter
```

### Complex Example with Dependencies (`modules/PulseStar/mcc_package.yaml`)
```yaml
name: pulsestar
description: 4-channel calibration signal generator
version: 1.0.0

files:
  datadef:
    - datadef/waveform_lut_pkg.vhd
  core:
    - core/waveform_gen_core.vhd
    - core/trigger_gen_core.vhd
    - core/uart_tx_core.vhd
  top:
    - top/Top.vhd

dependencies:
  - module: volo_common
    files:
      - core/clk_divider_core.vhd

control_registers:
  - register: 0
    bits:
      - {range: "31", name: "MCC_READY", type: "auto"}
      - {range: "28:21", name: "Frequency Divider", type: "user"}
  - register: 1
    bits:
      - {range: "31:16", name: "UART Baud Div", type: "user"}

outputs:
  - port: OutputA
    description: "I Channel (Sine wave)"
  - port: OutputB
    description: "Q Channel (Cosine, 90° offset)"

example_code: |
  mcc.set_control(0, 0xC0F00000)
  mcc.set_control(1, 0x043C7D00)
```

---

## Usage Workflow

### Prerequisites
```bash
# Install Python dependencies with uv
uv sync --no-install-project
```

### Build Package
```bash
# From project root
uv run python scripts/build_mcc_package.py modules/PulseStar

# Or from module directory
cd modules/PulseStar
uv run python ../../scripts/build_mcc_package.py .
```

### Output (5-step pipeline)
```
[1/5] Collecting files from manifest...
  ✓ datadef: waveform_lut_pkg.vhd
  ✓ core: waveform_gen_core.vhd
  ✓ dependency (volo_common): clk_divider_core.vhd
  ✓ Collected 6 files

[2/5] Validating with GHDL...
  Analyzing mcc-Top.vhd...
  Analyzing waveform_lut_pkg.vhd...
  Elaborating CustomWrapper...
  ✓ GHDL validation successful!

[3/5] Creating package directory...
  ✓ Package directory created

[4/5] Generating README.txt...
  ✓ README.txt generated

[5/5] Creating ZIP archive...
  ✓ Created: pulsestar.zip (15.9 KB)
```

### Upload to Moku Cloud Compile
```bash
cd modules/PulseStar/cloudcompile_package
# Upload pulsestar.zip to https://cloud-compile.liquidinstruments.com/
# Wait for synthesis (~5-10 min)
# Download bitstream.tar.gz
# Save to: static/bitstreams/pulsestar.tar.gz
```

---

## Features

### ✅ Automatic Dependency Resolution
- Collects files from other modules (e.g., `volo_common/clk_divider_core.vhd`)
- Transitive dependencies supported
- No manual file copying needed

### ✅ GHDL Validation
- Compiles package with GHDL before creating zip
- Validates: mcc-Top.vhd + all collected files
- Elaborates CustomWrapper entity
- Catches errors early (before MCC upload)
- Skippable with `--skip-validation`

### ✅ Auto-Generated Documentation
- README.txt generated from manifest metadata
- Includes:
  - Control register map with bit descriptions
  - Output port documentation
  - Python usage examples
  - Upload instructions

### ✅ Consistent Output
- All modules use same packaging format
- Standard directory structure
- Predictable ZIP naming (`<module_name>.zip`)
- Ready for direct MCC upload

---

## Manifest Schema

### Required Fields
```yaml
name: string                    # Module name (lowercase, no spaces)
description: string             # Short description
version: string                 # Semantic version (e.g., "1.0.0")
files:                          # Files to include
  datadef: [list of paths]     # Datadef layer (optional)
  core: [list of paths]        # Core layer (required)
  top: [list of paths]         # Top layer (required)
control_registers: [list]      # Register documentation
outputs: [list]                # Output port documentation
```

### Optional Fields
```yaml
author: string                  # Author name (default: "Unknown")
date: string                    # Date (default: "Unknown")
dependencies: [list]           # External module dependencies
example_code: |                 # Python usage example
  # Multi-line code block
```

### Control Register Schema
```yaml
control_registers:
  - register: 0                 # Register number (0-31)
    bits:
      - range: "31"             # Bit range (single or "hi:lo")
        name: "MCC_READY"       # Bit/field name
        type: "auto"            # "auto", "user", or "reserved"
        description: "..."      # Human-readable description
```

### Output Schema
```yaml
outputs:
  - port: "OutputA"             # Port name
    description: "..."          # Human-readable description
```

---

## Build Script Internals

### Compilation Order
1. **mcc-Top.vhd** (from `mcc_templates/`)
2. **Dependencies** (from other modules, category order)
3. **Module files** (in category order: datadef → core → top)
4. **Elaborate** CustomWrapper entity

### Category Order
- `datadef` → `dependency` → `core` → `top`
- Ensures packages compile before cores
- Ensures cores compile before top-level

### Validation Logic
```python
if not skip_validation and ghdl_available:
    for category in ['datadef', 'dependency', 'core', 'top']:
        for file in category_files:
            ghdl -a --std=08 --workdir=temp file.vhd
    ghdl -e --std=08 --workdir=temp CustomWrapper
```

---

## Migration from Bash Scripts

### Old Pattern (Per-Module Bash)
```bash
# modules/PulseStar/build_cloudcompile.sh
cp datadef/waveform_lut_pkg.vhd cloudcompile_package/
cp core/waveform_gen_core.vhd cloudcompile_package/
cp ../volo_common/core/clk_divider_core.vhd cloudcompile_package/
# ... manual file copying, manual README generation
```

### New Pattern (Canonical YAML)
```yaml
# modules/PulseStar/mcc_package.yaml
files:
  datadef: [datadef/waveform_lut_pkg.vhd]
  core: [core/waveform_gen_core.vhd]
dependencies:
  - module: volo_common
    files: [core/clk_divider_core.vhd]
```

**Benefits**:
- ✅ Single source of truth (YAML manifest)
- ✅ Automatic dependency resolution
- ✅ Consistent across all modules
- ✅ No bash script duplication
- ✅ Auto-generated documentation

---

## Integration with Project Workflow

### Step 1: Create Manifest
```bash
cd modules/MyNewModule
cat > mcc_package.yaml << 'EOF'
name: mynewmodule
description: My awesome module
version: 1.0.0
files:
  core: [core/mynewmodule_core.vhd]
  top: [top/Top.vhd]
control_registers: [...]
outputs: [...]
EOF
```

### Step 2: Build Package
```bash
uv run python scripts/build_mcc_package.py modules/MyNewModule
```

### Step 3: Upload to MCC
- Upload `mynewmodule.zip` to Cloud Compile
- Wait for synthesis
- Download `mynewmodule.tar.gz`

### Step 4: Deploy with MokuBench
```python
from moku.instruments import MultiInstrument, CloudCompile

m = MultiInstrument('192.168.1.100', platform_id=2)
mcc = m.set_instrument(1, CloudCompile, bitstream="mynewmodule.tar.gz")
mcc.set_control(0, 0xC0000001)  # MCC_READY + Enable
```

---

## Error Handling

### Missing Manifest
```
FileNotFoundError: No mcc_package.yaml found in modules/MyModule
Create one with: name, description, files, control_registers, outputs
```

**Solution**: Create `mcc_package.yaml` in module root.

### File Not Found
```
FileNotFoundError: File not found: modules/PulseStar/core/missing.vhd
```

**Solution**: Fix file path in manifest `files:` section.

### GHDL Validation Failed
```
✗ GHDL validation failed:
error: unit "waveform_lut_pkg" not found in library "work"
```

**Solution**: Add missing dependency to manifest `dependencies:` section.

### Dependency Module Not Found
```
FileNotFoundError: Dependency module not found: modules/volo_common
```

**Solution**: Check that dependency module exists in `modules/`.

---

## Command-Line Options

### Basic Usage
```bash
uv run python scripts/build_mcc_package.py <module_dir>
```

### Skip GHDL Validation
```bash
uv run python scripts/build_mcc_package.py modules/PulseStar --skip-validation
```

**When to use `--skip-validation`:**
- GHDL not installed
- Package previously validated
- Debugging manifest changes only
- CI/CD build without GHDL

---

## Testing

### Verify Package
```bash
# Build package
uv run python scripts/build_mcc_package.py modules/PulseStar

# Check contents
ls -lh modules/PulseStar/cloudcompile_package/
unzip -l modules/PulseStar/cloudcompile_package/pulsestar.zip
```

### Test Compilation Locally
```bash
cd modules/PulseStar/cloudcompile_package
ghdl -a --std=08 *.vhd
ghdl -e --std=08 CustomWrapper
```

---

## Reference Implementations

### PulseStar (with dependencies)
- **Manifest**: `modules/PulseStar/mcc_package.yaml`
- **Dependencies**: volo_common/clk_divider_core
- **Files**: 5 VHDL files (datadef + 3 cores + top)
- **Package size**: 15.9 KB

### simple_counter (no dependencies)
- **Manifest**: `modules/simple_counter/mcc_package.yaml`
- **Dependencies**: None
- **Files**: 2 VHDL files (core + top)
- **Package size**: 4.8 KB

---

## Future Enhancements

### Potential Additions
- ☐ Support for multiple architecture targets (different Top.vhd per platform)
- ☐ Auto-detect dependencies from VHDL `use WORK.xyz` statements
- ☐ Integration with MCC upload API (automated upload)
- ☐ Git tag-based versioning
- ☐ Package signing/checksums

### Backward Compatibility
- Existing bash scripts (`build_cloudcompile.sh`) still work
- Can coexist during migration period
- No breaking changes to existing workflows

---

## Related Memories
- **mcc_build_pattern**: Local CustomWrapper integration
- **instrument_cloud_compile**: CloudCompile Python API usage
- **tech_stack**: Python/uv dependency management

**Canonical as of**: 2025-01-22 (feature/PulseStar)

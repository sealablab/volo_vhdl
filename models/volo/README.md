# VoloApp Models

**Pydantic models for the VoloApp hardware abstraction layer**

## Overview

This directory contains the core Pydantic models for defining, validating, and generating VHDL code for VoloApp applications.

A **VoloApp** is a deployable FPGA application with:
- MCC bitstream (.tar file)
- Optional 4KB BRAM buffer (.bin file)
- Human-friendly register interface (CR20-CR30)

## Files

### `app_register.py`

Defines register types and application register models.

**Classes:**
- `RegisterType` - Enum for supported register types
- `AppRegister` - Single register definition with validation

**Register Types:**
- `COUNTER_8BIT`: 8-bit unsigned (0-255) → `std_logic_vector(7 downto 0)`
- `PERCENT`: Percentage (0-100) → `std_logic_vector(6 downto 0)`
- `BUTTON`: Boolean (0 or 1) → `std_logic`

### `volo_app.py`

Main VoloApp model with VHDL generation capabilities.

**Class:** `VoloApp`

**Key Methods:**
- `to_vhdl_signal_name(friendly_name)` - Convert "Pulse Width" → "pulse_width"
- `generate_vhdl_shim(template_path)` - Generate shim layer VHDL
- `generate_vhdl_main_template(template_path)` - Generate main template VHDL
- `to_deployment_config()` - Export deployment configuration
- `save_to_yaml(path)` - Save to YAML file
- `load_from_yaml(path)` - Load from YAML file

### `__init__.py`

Package exports and version information.

## Usage Examples

### Load and Validate App Definition

```python
from models.volo import VoloApp
from pathlib import Path

# Load from YAML
app = VoloApp.load_from_yaml(Path("modules/PulseStar/PulseStar_app.yaml"))

# Validate (automatic via Pydantic)
print(f"App: {app.name} v{app.version}")
print(f"Registers: {len(app.registers)}")
```

### Generate VHDL Shim

```python
from pathlib import Path

# Generate shim from template
shim_vhdl = app.generate_vhdl_shim(
    Path("shared/volo/templates/volo_shim_template.vhd")
)

# Save to file
output_path = Path("modules/PulseStar/volo_main/PulseStar_volo_shim.vhd")
with open(output_path, 'w') as f:
    f.write(shim_vhdl)
```

### Generate VHDL Main Template

```python
# Generate main template (only if doesn't exist)
main_template_path = Path("modules/PulseStar/volo_main/PulseStar_volo_main.vhd")

if not main_template_path.exists():
    main_vhdl = app.generate_vhdl_main_template(
        Path("shared/volo/templates/volo_main_template.vhd")
    )
    with open(main_template_path, 'w') as f:
        f.write(main_vhdl)
```

### Create New VoloApp Programmatically

```python
from models.volo import VoloApp, AppRegister, RegisterType
from pathlib import Path

app = VoloApp(
    name="MyApp",
    version="1.0.0",
    description="Example FPGA application",
    bitstream_path=Path("modules/MyApp/latest/25ff_bitstreams.tar"),
    buffer_path=Path("modules/MyApp/buffers/config.bin"),
    registers=[
        AppRegister(
            name="Enable",
            description="Enable module output",
            reg_type=RegisterType.BUTTON,
            cr_number=20,
            default_value=0
        ),
        AppRegister(
            name="Threshold",
            description="Trigger threshold (0-255)",
            reg_type=RegisterType.COUNTER_8BIT,
            cr_number=21,
            default_value=128,
            min_value=0,
            max_value=255
        )
    ],
    author="Volo Team",
    tags=["example", "template"]
)

# Save to YAML
app.save_to_yaml(Path("modules/MyApp/MyApp_app.yaml"))
```

### Signal Name Conversion

```python
from models.volo import VoloApp

# Test signal name conversion
assert VoloApp.to_vhdl_signal_name("Pulse Width") == "pulse_width"
assert VoloApp.to_vhdl_signal_name("Enable Output") == "enable_output"
assert VoloApp.to_vhdl_signal_name("PWM Duty %") == "pwm_duty"
```

### Export Deployment Config

```python
# Generate deployment configuration
deploy_config = app.to_deployment_config()

# Use with volo_loader.py
import json
with open("deploy_config.json", 'w') as f:
    json.dump(deploy_config, f, indent=2)
```

## Validation Rules

The models enforce the following validation rules:

### VoloApp
- ✓ Name: 1-50 characters
- ✓ Version: Semantic version (e.g., "1.0.0")
- ✓ Description: 1-500 characters
- ✓ Registers: 1-11 registers (CR20-CR30 limit)
- ✓ No duplicate CR numbers

### AppRegister
- ✓ CR number: Must be 20-30 (inclusive)
- ✓ COUNTER_8BIT: Values 0-255
- ✓ PERCENT: Values 0-100
- ✓ BUTTON: Values 0 or 1
- ✓ default_value: Must match type constraints
- ✓ min_value/max_value: Must match type constraints

## Architecture

### 3-Layer Design

```
┌─────────────────────────────────────────────────────┐
│ MCC_TOP_volo_loader.vhd (static, shared)           │
│ - Implements CustomWrapper interface                │
│ - Instantiates volo_bram_loader FSM                 │
│ - Extracts VOLO_READY bits (CR0[31:29])            │
└──────────────────┬──────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────┐
│ <AppName>_volo_shim.vhd (GENERATED from model)     │
│ - Maps CR20-CR30 → friendly signal names            │
│ - Combines ready signals → global_enable            │
└──────────────────┬──────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────┐
│ <AppName>_volo_main.vhd (hand-written)             │
│ - MCC-agnostic interface                            │
│ - Uses friendly signal names only                   │
└─────────────────────────────────────────────────────┘
```

### Register Map

| Range | Purpose | Details |
|-------|---------|---------|
| **CR0[31:29]** | VOLO_READY control | 3-bit ready scheme |
| **CR10-CR14** | BRAM loader | 4KB buffer streaming |
| **CR20-CR30** | App registers | Max 11 registers |

## Testing

See `tests/models/test_volo_app.py` for comprehensive tests.

Run tests:
```bash
cd tests/models
uv run pytest test_volo_app.py -v
```

## Code Generation Workflow

1. **Define app** in YAML (e.g., `PulseStar_app.yaml`)
2. **Generate VHDL** with `tools/generate_volo_app.py`
3. **Implement logic** in `<AppName>_volo_main.vhdl`
4. **Build MCC package** with `scripts/build_mcc_package.py`
5. **Deploy** with `tools/volo_loader.py`

## Design Principles

1. **Clear separation**: 3 layers with distinct responsibilities
2. **Consistency**: Same interface contract for ALL volo-apps
3. **Repeatability**: MANDATORY naming conventions
4. **Automation**: Shim is 100% generated, never hand-edited
5. **MCC-agnostic apps**: Developers work with friendly signals only

## References

- **Design**: `docs/VOLO_APP_DESIGN.md`
- **Quick Start**: `docs/VOLO_APP_FRESH_CONTEXT.md`
- **Implementation Plan**: `docs/VOLO_APP_IMPLEMENTATION_PLAN.md`
- **Example App**: `modules/PulseStar/PulseStar_app.yaml`

## Version

Current version: **1.0.0**

## License

Part of the Volo VHDL project.

# VoloApp Architecture Design

**Status**: Design Phase
**Created**: 2025-01-25
**Authors**: Volo Team

---

## Overview

**VoloApp** is a hardware abstraction layer for deploying FPGA applications to Moku platform with human-friendly register interfaces. At present it supports a **very** limited set of 'volo-app' compatible types. (These are represented below).

---


### Key Concept

A **VoloApp** consists of:
1. **MCC bitstream** (.tar) - Implements CustomWrapper interface
2. **4KB BRAM buffer** (.bin) - Loaded via network protocol
3. **Application registers** (CR20-CR30) - Human-friendly controls with limited type system

### Design Goals

- ✅ **Clear separation of concerns**: MCC ↔ Shim ↔ App (3 layers)
- ✅ **MCC-agnostic applications**: Developers never see Control Register numbers
- ✅ **Repeatable conventions**: MANDATORY naming scheme for consistency
- ✅ **Automation-friendly**: Shim layer is 100% generated from Pydantic model
- ✅ **Future GUI generation**: Design enables auto-generated control interfaces

---

## Architecture

### 3-Layer Design

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: MCC_TOP_volo_loader.vhd                       │
│ (CustomWrapper architecture - STATIC, shared)           │
│                                                         │
│ - Implements CustomWrapper interface                    │
│ - Instantiates volo_bram_loader FSM (CR10-CR14)        │
│ - Extracts VOLO_READY bits (CR0[31:29])                │
│ - Passes app registers (CR20-CR30) to shim             │
│ - Instantiates app-specific shim                        │
└──────────────────┬──────────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────────┐
│ Layer 2: <AppName>_volo_shim.vhd                       │
│ (Register Mapping - GENERATED from Pydantic)            │
│                                                         │
│ - Maps CR20-CR30 → friendly signal names                │
│ - Combines ready signals → global_enable                │
│ - Extracts bit ranges per register type                 │
│ - Instantiates <AppName>_volo_main                      │
└──────────────────┬──────────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────────┐
│ Layer 3: <AppName>_volo_main.vhd                       │
│ (Application Logic - HAND-WRITTEN)                      │
│                                                         │
│ - MCC-agnostic interface (friendly signal names)        │
│ - Implements app-specific functionality                 │
│ - ZERO knowledge of Control Registers                   │
│ - Works with signals like "pulse_width", "duty_cycle"   │
└─────────────────────────────────────────────────────────┘
```

### Register Map

#### Reserved Ranges

| Range | Purpose | Details |
|-------|---------|---------|
| **CR0[31:29]** | VOLO_READY control | 3-bit ready scheme (volo_ready, user_enable, clk_enable) |
| **CR10-CR14** | BRAM loader protocol | 4KB buffer streaming (treat as black box) |
| **CR20-CR30** | Application registers | Human-friendly interface (11 registers max) |

#### CR0[31:29]: VOLO_READY Control Scheme

```
CR0[31] = volo_ready  (set by loader after deployment)
CR0[30] = user_enable (user-controlled enable/disable)
CR0[29] = clk_enable  (clock gating for sequential logic)
```

**Safe default**: All-zero state keeps module disabled (bit 31=0)

**Global enable**: `global_enable <= volo_ready AND user_enable AND clk_enable AND loader_done`

---

## Naming Conventions

### MANDATORY File and Entity Names

| Component | File Pattern | Entity Pattern | Location |
|-----------|--------------|----------------|----------|
| **Static Top** | `MCC_TOP_volo_loader.vhd` | `architecture volo_loader of CustomWrapper` | `shared/volo/` |
| **Loader FSM** | `volo_bram_loader.vhd` | `volo_bram_loader` | `shared/volo/` |
| **Common Pkg** | `volo_common_pkg.vhd` | `volo_common_pkg` | `shared/volo/` |
| **App Shim** | `<AppName>_volo_shim.vhd` | `<AppName>_volo_shim` | `modules/<AppName>/volo_main/` |
| **App Main** | `<AppName>_volo_main.vhd` | `<AppName>_volo_main` | `modules/<AppName>/volo_main/` |

### Signal Naming

**Standard Volo Interface** (same for ALL apps):
```vhdl
-- Control signals (from loader top → shim)
volo_ready   : std_logic  -- CR0[31]
user_enable  : std_logic  -- CR0[30]
clk_enable   : std_logic  -- CR0[29]
loader_done  : std_logic  -- From loader FSM

-- Raw app registers (from loader top → shim)
app_reg_20   : std_logic_vector(31 downto 0)  -- CR20
app_reg_21   : std_logic_vector(31 downto 0)  -- CR21
-- ... up to app_reg_30

-- BRAM interface (from loader FSM → shim/main)
bram_addr    : std_logic_vector(11 downto 0)  -- 4KB = 2^12 bytes
bram_data    : std_logic_vector(31 downto 0)
bram_we      : std_logic
```

**Friendly App Signals** (defined per-app from Pydantic model):
```vhdl
-- Example from PulseStar (shim → main)
pulse_width   : std_logic_vector(7 downto 0)   -- From AppRegister.name
duty_cycle    : std_logic_vector(6 downto 0)   -- Converted to snake_case
enable_output : std_logic
```

**Conversion Rule**: `to_vhdl_signal_name()`
- Input: `"Pulse Width"` (Pydantic `name` field)
- Output: `pulse_width` (VHDL signal)
- Algorithm: lowercase, spaces→underscores, remove special chars

---

## Register Type System

### Supported Types (Limited by Design)

| Type | Pydantic Enum | VHDL Type | Bit Range | Value Range |
|------|---------------|-----------|-----------|-------------|
| **8-bit Counter** | `COUNTER_8BIT` | `std_logic_vector(7 downto 0)` | `(7 downto 0)` | 0-255 |
| **Percent** | `PERCENT` | `std_logic_vector(6 downto 0)` | `(6 downto 0)` | 0-100 |
| **Button** | `BUTTON` | `std_logic` | `(0)` | 0 or 1 |

**Future extensions** (not in initial implementation):
- Signed integers
- Fixed-point (Q format)
- Enums (dropdown choices)
- Read-only status registers

---

## Pydantic Model Structure

### AppRegister Model

```python
from pydantic import BaseModel, Field
from enum import Enum

class RegisterType(str, Enum):
    COUNTER_8BIT = "counter_8bit"
    PERCENT = "percent"
    BUTTON = "button"

class AppRegister(BaseModel):
    name: str                    # Human-readable (e.g., "Pulse Width")
    description: str             # What this register controls
    reg_type: RegisterType
    cr_number: int               # Must be 20-30
    default_value: Optional[int] = None
    min_value: Optional[int] = None
    max_value: Optional[int] = None
```

### VoloApp Model

```python
class VoloApp(BaseModel):
    name: str                    # Application name (e.g., "PulseStar")
    version: str                 # Semantic version (e.g., "1.0.0")
    description: str

    # Deployment artifacts
    bitstream_path: Path
    buffer_path: Optional[Path]

    # Application interface
    registers: List[AppRegister]  # Max 11 (CR20-CR30)

    # Metadata
    author: Optional[str]
    tags: List[str]

    # Methods
    def to_vhdl_signal_name(friendly_name: str) -> str
    def generate_vhdl_shim(template_path: Path) -> str
    def generate_vhdl_main_template(template_path: Path) -> str
    def to_deployment_config() -> dict
    def save_to_yaml(path: Path)
    @classmethod
    def load_from_yaml(path: Path) -> VoloApp
```

---

## Code Generation Workflow

### 1. Define VoloApp in YAML

**Example**: `modules/PulseStar/PulseStar_app.yaml`

```yaml
name: PulseStar
version: 1.0.0
description: High-precision pulse generation with configurable timing
author: Volo Team
tags: [pulser, timing, glitch]

bitstream_path: modules/PulseStar/latest/25ff_bitstreams.tar
buffer_path: modules/PulseStar/buffers/timing_lut.bin

registers:
  - name: Pulse Width
    description: Pulse duration in clock cycles
    reg_type: counter_8bit
    cr_number: 20
    default_value: 100

  - name: Duty Cycle
    description: PWM duty cycle percentage
    reg_type: percent
    cr_number: 21
    default_value: 50

  - name: Enable Output
    description: Toggle pulse output on/off
    reg_type: button
    cr_number: 22
    default_value: 0
```

### 2. Generate VHDL Shim

```bash
python tools/generate_volo_app.py \
  --config modules/PulseStar/PulseStar_app.yaml \
  --output modules/PulseStar/volo_main/
```

**Generates**:
- `PulseStar_volo_shim.vhd` (from Jinja2 template)
- `PulseStar_volo_main.vhd` (template, if doesn't exist)

### 3. Implement App Logic

Developer edits `PulseStar_volo_main.vhd`:
- Works with friendly signals (`pulse_width`, `duty_cycle`, `enable_output`)
- No knowledge of CR20, CR21, CR22
- MCC-agnostic implementation

### 4. Build and Deploy

```bash
# Build MCC package
uv run python scripts/build_mcc_package.py modules/PulseStar

# Upload to CloudCompile, download results, import
python scripts/import_mcc_build.py modules/PulseStar

# Deploy to device
python tools/volo_loader.py \
  --config modules/PulseStar/PulseStar_app.yaml \
  --device MokuB106 \
  --ip 192.168.13.159
```

---

## Deployment Workflow

### User Perspective

#### Step 1: Bitstream is Loaded

From the perspective of a user, a bitstream for a volo-app will appear **"stuck"** when loaded with first-party tools. This is **expected behavior** - the VHDL is waiting for the VOLO_READY signal.

#### Step 2: volo_loader Takes Over

The `volo_loader` utility:
1. Connects to Moku device
2. Sets CR0[31:29] ready bits (volo_ready, user_enable, clk_enable)
3. Streams 4KB buffer via CR10-CR14 protocol
4. Initializes app registers (CR20-CR30) with default values
5. Waits for `loader_done` signal
6. Passes control to app logic

#### Step 3: App Runs

Application proceeds with normal operation using friendly register interface.

### VHDL Perspective

```vhdl
-- In MCC_TOP_volo_loader.vhd
volo_ready  <= Control0(31);
user_enable <= Control0(30);
clk_enable  <= Control0(29);

-- In <AppName>_volo_shim.vhd
global_enable <= volo_ready and user_enable and clk_enable and loader_done;

-- Passed to <AppName>_volo_main.vhd
APP_MAIN: entity WORK.PulseStar_volo_main
    port map (
        Enable => global_enable,
        pulse_width => pulse_width,  -- Friendly signal
        -- ...
    );
```

---

## Directory Structure

### Per-Module Layout

```
modules/PulseStar/
├── PulseStar_app.yaml           # VoloApp definition
├── volo_main/                   # NEW: Volo-specific layer
│   ├── PulseStar_volo_shim.vhd  # GENERATED from YAML
│   └── PulseStar_volo_main.vhd  # Hand-written app logic
├── core/                        # Optional: Pure algorithmic logic
│   └── PulseStar_core.vhd       # (if complex enough to separate)
├── buffers/                     # BRAM data
│   └── timing_lut.bin           # 4KB buffer
├── cloudcompile_package/        # Build outputs
│   └── PulseStar.zip            # Includes MCC_TOP + shim + app
└── latest/                      # Active bitstream
    └── 25ff*_bitstreams.tar
```

### Shared Infrastructure

```
shared/volo/                     # Shared/template files
├── MCC_TOP_volo_loader.vhd      # STATIC: CustomWrapper + loader FSM
├── volo_bram_loader.vhd         # STATIC: Loader FSM
├── volo_common_pkg.vhd          # STATIC: Constants/types
└── templates/
    ├── volo_shim_template.vhd   # Jinja2 template
    └── volo_main_template.vhd   # Jinja2 template
```

---

## Key Design Decisions

### Why 3 Layers?

1. **Layer 1 (MCC_TOP)**: Single static file, shared across ALL apps
   - Eliminates duplication
   - Centralizes MCC integration complexity
   - Easier to maintain and update

2. **Layer 2 (Shim)**: Generated, never hand-edited
   - Ensures consistency
   - Eliminates human error in register mapping
   - Single source of truth (Pydantic model)

3. **Layer 3 (Main)**: Hand-written, MCC-agnostic
   - Developer focuses on app logic only
   - Testable independently
   - Portable to other platforms (with different shim)

### Why Limited Type System?

**Design Principle**: Start simple, extend later

- **3 types** (counter, percent, button) cover 80% of use cases
- Easy to validate and visualize
- Straightforward VHDL mapping
- Future-proof: Can add types without breaking existing apps

### Why BRAM Always Exposed?

**Consistency over optimization**

- Simplifies interface contract (same for ALL apps)
- Apps can ignore BRAM if unused (no harm)
- Reduces cognitive load (one interface to learn)
- Enables future enhancements (dynamic LUT updates)

### Why Separate from MokuConfig?

**Different use cases, different abstractions**

| Aspect | MokuConfig | VoloApp |
|--------|------------|---------|
| **Purpose** | Multi-instrument routing | Single-app deployment |
| **Scope** | Platform-level | Module-level |
| **Users** | System integrators | App developers |
| **Deployment** | First-party tools | volo_loader utility |

**Relationship**: VoloApp bitstreams CAN be loaded via MokuConfig, but deployment workflow is separate.

---

## Future Enhancements

### Phase 5+: Advanced Features

**GUI Generation** (High Priority):
- Auto-generate Qt/Tkinter controls from AppRegister definitions
- Real-time updates via `set_regs()` API
- Live monitoring of outputs

**Advanced Register Types**:
- Signed integers
- Fixed-point (Q format)
- Enums (dropdown choices)
- Read-only status registers

**Multi-App Loader**:
- Load multiple volo-apps to different slots
- App switching/routing logic
- Shared BRAM partitioning

**Validation Enhancements**:
- Check bitstream implements volo interface
- Validate buffer size exactly 4KB
- Detect register conflicts at build time

---

## References

- **MCC Integration**: See CLAUDE.md "MCC 3-Bit Control Scheme"
- **Existing Infrastructure**: `models/moku/platform_config.py` (MokuConfig)
- **VHDL Conventions**: See `.cursor/rules.mdc` and Serena memories
- **Testing Framework**: `tests/README.md` (CocotB)

---

## Questions and Answers

**Q: Why rename MCC_READY to VOLO_READY?**
A: Clarifies that this is a Volo convention, not an MCC requirement. MCC doesn't mandate the 3-bit ready scheme - we invented it.

**Q: Can a VoloApp work without a buffer?**
A: Yes! `buffer_path` is optional. BRAM interface is still exposed (for consistency), but app can ignore it.

**Q: What if I need more than 11 registers?**
A: Consider grouping related settings into a single register with bit fields, or use BRAM for configuration arrays.

**Q: Can I use VoloApp with non-Moku platforms?**
A: The app main logic is platform-agnostic. You'd need a different shim layer for the target platform's register interface.

---

**Document Status**: Design phase complete, ready for implementation.

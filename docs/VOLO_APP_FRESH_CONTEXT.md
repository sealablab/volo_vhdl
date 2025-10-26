# VoloApp Implementation - System Prompt for Fresh Context

**Use this document when starting with a fresh context window to implement VoloApp features.**

---

## Mission

Implement the **VoloApp abstraction** - a hardware abstraction layer for deploying FPGA applications to Moku platform with human-friendly register interfaces.

---

## Quick Context

### What is a VoloApp?

A **VoloApp** is a deployable FPGA application consisting of:
1. **MCC bitstream** (.tar) - Implements CustomWrapper interface + volo loader FSM
2. **4KB BRAM buffer** (.bin) - Loaded via network protocol (CR10-CR14)
3. **Application registers** (CR20-CR30) - Human-friendly controls with limited type system

### Architecture (3 Layers)

```
┌─────────────────────────────────────────────────────────┐
│ MCC_TOP_volo_loader.vhd (CustomWrapper architecture)   │ ← Static, shared
│ - Implements CustomWrapper interface                    │
│ - Instantiates volo_bram_loader FSM (CR10-CR14)        │
│ - Extracts VOLO_READY bits (CR0[31:29])                │
│ - Passes app registers (CR20-CR30) to shim             │
└──────────────────┬──────────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────────┐
│ <AppName>_volo_shim.vhd (Register Mapping Layer)       │ ← Generated
│ - Maps CR20-CR30 → friendly signal names                │
│ - Combines ready signals → global_enable                │
│ - Instantiates <AppName>_volo_main                      │
└──────────────────┬──────────────────────────────────────┘
                   │ instantiates
┌──────────────────▼──────────────────────────────────────┐
│ <AppName>_volo_main.vhd (Application Logic)            │ ← Hand-written
│ - MCC-agnostic interface (friendly signal names)        │
│ - Implements app-specific functionality                 │
│ - ZERO knowledge of Control Registers                   │
└─────────────────────────────────────────────────────────┘
```

---

## Register Map (Reserved Ranges)

- **CR0[31:29]**: VOLO_READY control scheme
  - Bit 31: `volo_ready` (set by loader after deployment)
  - Bit 30: `user_enable` (user-controlled enable/disable)
  - Bit 29: `clk_enable` (clock gating for sequential logic)
- **CR10-CR14**: BRAM loader protocol (4KB buffer streaming) - **treat as black box**
- **CR20-CR30**: Application registers (11 max, human-friendly interface)

---

## Naming Conventions (MANDATORY)

| Component | File Pattern | Entity Pattern | Location |
|-----------|--------------|----------------|----------|
| Static Top | `MCC_TOP_volo_loader.vhd` | `architecture volo_loader of CustomWrapper` | `shared/volo/` |
| Loader FSM | `volo_bram_loader.vhd` | `volo_bram_loader` | `shared/volo/` |
| Common Pkg | `volo_common_pkg.vhd` | `volo_common_pkg` | `shared/volo/` |
| App Shim | `<AppName>_volo_shim.vhd` | `<AppName>_volo_shim` | `modules/<AppName>/volo_main/` |
| App Main | `<AppName>_volo_main.vhd` | `<AppName>_volo_main` | `modules/<AppName>/volo_main/` |

**Signal Naming**:
- Pydantic `name` field → VHDL signal via `to_vhdl_signal_name()`
- Example: "Pulse Width" → `pulse_width`
- Pattern: lowercase, spaces→underscores, remove special chars

---

## Register Types (Limited Type System)

1. **COUNTER_8BIT**: 8-bit unsigned (0-255) → `std_logic_vector(7 downto 0)`
2. **PERCENT**: volo_percent_pkg (0-100) → `std_logic_vector(6 downto 0)`
3. **BUTTON**: Boolean push-button (0 or 1) → `std_logic`

---

## Implementation Phases

### Phase 1: Core Infrastructure ⭐ **START HERE**

**Goal**: Create foundational models and static VHDL infrastructure

#### Task 1.1: Pydantic Models
**Location**: `models/volo/`

Create:
```
models/volo/
├── __init__.py
├── app_register.py          # RegisterType enum + AppRegister model
├── volo_app.py              # VoloApp model with VHDL generation
└── README.md                # Architecture documentation
```

**Key methods in `VoloApp`**:
- `to_vhdl_signal_name(friendly_name: str) -> str`
- `get_vhdl_bit_range(reg: AppRegister) -> str`
- `generate_vhdl_shim(template_path: Path) -> str`
- `generate_vhdl_main_template(template_path: Path) -> str`
- `to_deployment_config() -> dict`
- `save_to_yaml(path)` / `load_from_yaml(path)`

**Validation rules**:
- CR numbers must be 20-30
- No duplicate CR assignments
- Max 11 registers
- Value ranges: 0-255 (8-bit), 0-100 (percent), 0-1 (button)

#### Task 1.2: Static VHDL Components
**Location**: `shared/volo/`

Create:
```
shared/volo/
├── MCC_TOP_volo_loader.vhd  # CustomWrapper architecture
├── volo_bram_loader.vhd     # Loader FSM (CR10-CR14)
├── volo_common_pkg.vhd      # Constants/types
└── templates/
    ├── volo_shim_template.vhd   # Jinja2 template
    └── volo_main_template.vhd   # Jinja2 template
```

**`volo_common_pkg.vhd` must include**:
```vhdl
package volo_common_pkg is
    -- VOLO ready control scheme (CR0[31:29])
    constant VOLO_READY_BIT  : natural := 31;
    constant USER_ENABLE_BIT : natural := 30;
    constant CLK_ENABLE_BIT  : natural := 29;

    -- BRAM loader protocol
    constant BRAM_ADDR_WIDTH : natural := 12;  -- 4KB
    constant BRAM_DATA_WIDTH : natural := 32;

    -- Application register range
    constant APP_REG_MIN : natural := 20;
    constant APP_REG_MAX : natural := 30;
end package;
```

**`volo_bram_loader.vhd` interface**:
```vhdl
entity volo_bram_loader is
    port (
        Clk       : in  std_logic;
        Reset     : in  std_logic;
        Control10 : in  std_logic_vector(31 downto 0);
        Control11 : in  std_logic_vector(31 downto 0);
        Control12 : in  std_logic_vector(31 downto 0);
        Control13 : in  std_logic_vector(31 downto 0);
        Control14 : in  std_logic_vector(31 downto 0);
        bram_addr : out std_logic_vector(11 downto 0);
        bram_data : out std_logic_vector(31 downto 0);
        bram_we   : out std_logic;
        done      : out std_logic
    );
end entity;
```

**`MCC_TOP_volo_loader.vhd` structure**:
- Architecture: `architecture volo_loader of CustomWrapper`
- Instantiates: `volo_bram_loader` FSM
- Instantiates: `<AppName>_volo_shim` (app-specific, passed as generic or hardcoded initially)
- Exposes: Standard volo interface to shim

#### Task 1.3: Jinja2 Templates

**`volo_shim_template.vhd` must generate**:
- Entity: `<AppName>_volo_shim`
- Standard volo interface (same for ALL apps):
  - Control: `Clk, Reset, volo_ready, user_enable, clk_enable, loader_done`
  - App registers: `app_reg_20..app_reg_30` (only used ones)
  - BRAM: `bram_addr, bram_data, bram_we` (ALWAYS included)
  - MCC I/O: `InputA, InputB, OutputA, OutputB`
- Architecture:
  - Friendly signal declarations (from Pydantic)
  - Register mapping (`app_reg_XX` → friendly signals)
  - Global enable computation
  - Instantiate `<AppName>_volo_main`

**`volo_main_template.vhd` must generate**:
- Entity: `<AppName>_volo_main`
- Ports:
  - Standard: `Clk, Reset, Enable, ClkEn`
  - Friendly signals (from Pydantic)
  - BRAM interface (ALWAYS included)
  - App outputs (placeholder)
- Architecture: Placeholder (developer fills in)

#### Task 1.4: Code Generation Script
**Location**: `tools/generate_volo_app.py`

**CLI**:
```bash
python tools/generate_volo_app.py \
  --config modules/PulseStar/PulseStar_app.yaml \
  --output modules/PulseStar/volo_main/
```

**Generates**:
- `<AppName>_volo_shim.vhd` (from template)
- `<AppName>_volo_main.vhd` (template, only if doesn't exist)

#### Task 1.5: Testing
**Location**: `tests/models/`

Create:
```
tests/models/
├── test_volo_app.py         # Model validation tests
└── test_vhdl_generation.py  # VHDL generation tests
```

**Coverage**:
- Duplicate CR numbers (ValidationError)
- CR out of range (<20 or >30)
- Too many registers (>11)
- Invalid value ranges
- Signal name conversion
- VHDL generation produces valid output
- Deployment config generation
- YAML save/load round-trip

---

### Phase 2: Example Implementation

**Goal**: Create first complete volo-app (PulseStar)

**Tasks**:
- Create `PulseStar_app.yaml`
- Generate shim with `generate_volo_app.py`
- Implement `PulseStar_volo_main.vhd`
- Update build to include volo infrastructure
- Test compilation and CloudCompile synthesis

---

### Phase 3: Loader Utility

**Goal**: Implement `volo_loader.py` for deployment

**Tasks**:
- Load VoloApp from YAML
- Connect to Moku device
- Set CR0[31:29] ready bits
- Stream 4KB buffer via CR10-CR14
- Initialize app registers (CR20-CR30)
- Verify app responds

---

### Phase 4: Documentation

**Goal**: Comprehensive docs for volo-app developers

**Files**:
- `docs/VOLO_APP_DESIGN.md` ✓ (already created)
- `docs/VOLO_APP_QUICKSTART.md`
- `docs/VOLO_REGISTER_MAP.md`
- Serena memory: `volo_app_architecture.md`
- Update `CLAUDE.md` and `AGENTS.md`

---

## Design Principles

1. **Clear separation**: 3 layers with distinct responsibilities
2. **Consistency**: Same interface contract for ALL volo-apps
3. **Repeatability**: MANDATORY naming conventions (never deviate!)
4. **Automation**: Shim is 100% generated, never hand-edited
5. **MCC-agnostic apps**: Developers work with friendly signals only
6. **BRAM always exposed**: For consistency (apps can ignore if unused)

---

## Key Decisions from Design Discussion

1. **Directory name**: `volo_main/` (not `volo/` or `app/`)
2. **Signal naming**: Convert Pydantic `name` to snake_case for VHDL
3. **BRAM interface**: Expose to ALL apps (for consistency)
4. **Loader FSM location**: `shared/volo/volo_bram_loader.vhd`
5. **Template location**: `shared/volo/templates/`
6. **Rename convention**: MCC_READY → VOLO_READY (clarifies Volo invention)

---

## Example VoloApp Definition

**File**: `modules/PulseStar/PulseStar_app.yaml`

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
    min_value: 1
    max_value: 255

  - name: Duty Cycle
    description: PWM duty cycle percentage
    reg_type: percent
    cr_number: 21
    default_value: 50
    min_value: 0
    max_value: 100

  - name: Enable Output
    description: Toggle pulse output on/off
    reg_type: button
    cr_number: 22
    default_value: 0
```

---

## Success Criteria (Phase 1)

Phase 1 complete when:
- [ ] `models/volo/` created with full Pydantic models
- [ ] `shared/volo/` created with static VHDL files
- [ ] Jinja2 templates render valid VHDL
- [ ] `generate_volo_app.py` successfully generates shim + main
- [ ] All pytest tests pass
- [ ] Example `PulseStar_app.yaml` validates correctly

---

## Reference Materials

- **Complete design**: See `docs/VOLO_APP_DESIGN.md`
- **Existing MCC integration**: `modules/PulseStar/top/Top.vhd` (3-bit ready scheme)
- **Register conventions**: CLAUDE.md "MCC 3-Bit Control Scheme"
- **Pydantic examples**: `models/moku/platform_config.py` (MokuConfig)
- **Coding standards**: `.cursor/rules.mdc` + Serena memories

---

## Questions to Address During Implementation

1. **BRAM loader FSM**: Do we have existing implementation, or design from scratch?
2. **Template headers**: Include "GENERATED - DO NOT EDIT" comments?
3. **Path validation**: Check that `bitstream_path` exists on disk?
4. **Helper functions**: Should `volo_common_pkg.vhd` include ready bit combinators?

---

## Next Steps

**Immediate**: Start Phase 1, Task 1.1 (Pydantic Models)

**Command**:
```bash
# Create directory
mkdir -p models/volo

# Start implementing models
# See docs/VOLO_APP_DESIGN.md for complete specs
```

---

**Ready to code!** 🚀

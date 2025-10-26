# VoloApp Implementation Plan

**Status**: Phase 1 Ready to Start
**Created**: 2025-01-25

---

## Overview

This document tracks the implementation of the **VoloApp abstraction** across multiple phases.

For complete design details, see [`VOLO_APP_DESIGN.md`](./VOLO_APP_DESIGN.md).

---

## Phase 1: Core Infrastructure ⭐ **CURRENT**

**Goal**: Create foundational models and static VHDL infrastructure

### Task 1.1: Pydantic Models ✅ Ready to Start

**Location**: `models/volo/`

**Files to create**:
- [ ] `models/volo/__init__.py`
- [ ] `models/volo/app_register.py`
- [ ] `models/volo/volo_app.py`
- [ ] `models/volo/README.md`

**app_register.py checklist**:
- [ ] `RegisterType` enum (COUNTER_8BIT, PERCENT, BUTTON)
- [ ] `AppRegister` model with fields:
  - [ ] `name: str`
  - [ ] `description: str`
  - [ ] `reg_type: RegisterType`
  - [ ] `cr_number: int` (must be 20-30)
  - [ ] `default_value: Optional[int]`
  - [ ] `min_value: Optional[int]`
  - [ ] `max_value: Optional[int]`
- [ ] Validator: `cr_number` in range 20-30
- [ ] Validator: `default_value` matches type constraints

**volo_app.py checklist**:
- [ ] `VoloApp` model with fields:
  - [ ] `name: str`
  - [ ] `version: str`
  - [ ] `description: str`
  - [ ] `bitstream_path: Path`
  - [ ] `buffer_path: Optional[Path]`
  - [ ] `registers: List[AppRegister]`
  - [ ] `author: Optional[str]`
  - [ ] `tags: List[str]`
- [ ] Validator: No duplicate CR numbers
- [ ] Validator: Max 11 registers
- [ ] Method: `to_vhdl_signal_name(friendly_name: str) -> str`
- [ ] Method: `get_vhdl_bit_range(reg: AppRegister) -> str`
- [ ] Method: `get_vhdl_type_declaration(reg: AppRegister) -> str`
- [ ] Method: `generate_vhdl_shim(template_path: Path) -> str`
- [ ] Method: `generate_vhdl_main_template(template_path: Path) -> str`
- [ ] Method: `to_deployment_config() -> dict`
- [ ] Method: `save_to_yaml(path: Path)`
- [ ] Method: `load_from_yaml(path: Path) -> VoloApp`

**Dependencies**:
```bash
# Add to pyproject.toml
pydantic = "^2.0"
jinja2 = "^3.1"
pyyaml = "^6.0"
```

---

### Task 1.2: Static VHDL Components

**Location**: `shared/volo/`

**Directory structure**:
- [ ] Create `shared/volo/` directory
- [ ] Create `shared/volo/templates/` directory

**Files to create**:
- [ ] `shared/volo/volo_common_pkg.vhd`
- [ ] `shared/volo/volo_bram_loader.vhd`
- [ ] `shared/volo/MCC_TOP_volo_loader.vhd`
- [ ] `shared/volo/templates/volo_shim_template.vhd`
- [ ] `shared/volo/templates/volo_main_template.vhd`

**volo_common_pkg.vhd checklist**:
- [ ] Package declaration
- [ ] Constants:
  - [ ] `VOLO_READY_BIT : natural := 31`
  - [ ] `USER_ENABLE_BIT : natural := 30`
  - [ ] `CLK_ENABLE_BIT : natural := 29`
  - [ ] `BRAM_ADDR_WIDTH : natural := 12`
  - [ ] `BRAM_DATA_WIDTH : natural := 32`
  - [ ] `APP_REG_MIN : natural := 20`
  - [ ] `APP_REG_MAX : natural := 30`
- [ ] Optional: Helper functions (combine ready bits, etc.)

**volo_bram_loader.vhd checklist**:
- [ ] Entity declaration:
  - [ ] Ports: `Clk, Reset`
  - [ ] Ports: `Control10..Control14` (5 control registers)
  - [ ] Ports: `bram_addr, bram_data, bram_we, done` (outputs)
- [ ] Architecture implementation:
  - [ ] FSM for CR10-CR14 protocol
  - [ ] 4KB BRAM interface (1024 words × 32-bit)
  - [ ] `done` signal when loading complete

**Question**: Do we have existing BRAM loader implementation, or design from scratch?

**MCC_TOP_volo_loader.vhd checklist**:
- [ ] Architecture: `architecture volo_loader of CustomWrapper`
- [ ] Signal declarations:
  - [ ] `volo_ready, user_enable, clk_enable` (from CR0[31:29])
  - [ ] `loader_done` (from volo_bram_loader)
  - [ ] `app_reg_20..app_reg_30` (from Control20..Control30)
  - [ ] `bram_addr, bram_data, bram_we` (from loader to app)
- [ ] Instantiate `volo_bram_loader` FSM
- [ ] Instantiate `<AppName>_volo_shim` (initially hardcoded for one app)
- [ ] Extract CR0[31:29] bits
- [ ] Pass through MCC I/O (InputA/B, OutputA/B)

**volo_shim_template.vhd checklist** (Jinja2):
- [ ] Template variables:
  - [ ] `app_name` - Application name (e.g., "PulseStar")
  - [ ] `registers` - List of register mappings
  - [ ] `cr_numbers_used` - List of CR numbers
- [ ] Entity `{{ app_name }}_volo_shim`
- [ ] Standard volo interface ports
- [ ] Architecture with:
  - [ ] Friendly signal declarations
  - [ ] Register mapping (`app_reg_XX(bits) → friendly_signal`)
  - [ ] Global enable: `volo_ready and user_enable and clk_enable and loader_done`
  - [ ] Instantiate `{{ app_name }}_volo_main`

**volo_main_template.vhd checklist** (Jinja2):
- [ ] Template variables:
  - [ ] `app_name`
  - [ ] `friendly_ports` - List of app-specific signals
- [ ] Entity `{{ app_name }}_volo_main`
- [ ] Ports:
  - [ ] Standard: `Clk, Reset, Enable, ClkEn`
  - [ ] Friendly signals (from template)
  - [ ] BRAM: `bram_addr, bram_data, bram_we`
  - [ ] Outputs: Placeholder (developer customizes)
- [ ] Architecture: Placeholder with TODO comments

---

### Task 1.3: Code Generation Script

**Location**: `tools/generate_volo_app.py`

**CLI interface**:
```bash
python tools/generate_volo_app.py \
  --config <path_to_yaml> \
  --output <output_directory>
```

**Script checklist**:
- [ ] Import VoloApp model
- [ ] CLI argument parsing (argparse):
  - [ ] `--config`: Path to VoloApp YAML
  - [ ] `--output`: Output directory for generated files
  - [ ] `--force`: Overwrite existing files (optional)
- [ ] Load VoloApp from YAML
- [ ] Validate model (automatic via Pydantic)
- [ ] Generate shim:
  - [ ] Load template from `shared/volo/templates/volo_shim_template.vhd`
  - [ ] Render with `app.generate_vhdl_shim()`
  - [ ] Write to `<output>/<AppName>_volo_shim.vhd`
- [ ] Generate main template (if not exists):
  - [ ] Load template from `shared/volo/templates/volo_main_template.vhd`
  - [ ] Render with `app.generate_vhdl_main_template()`
  - [ ] Write to `<output>/<AppName>_volo_main.vhd` (skip if exists)
- [ ] Print summary:
  - [ ] Files created
  - [ ] Register mapping table
  - [ ] Next steps for developer

---

### Task 1.4: Testing

**Location**: `tests/models/`

**Files to create**:
- [ ] `tests/models/__init__.py`
- [ ] `tests/models/test_volo_app.py`
- [ ] `tests/models/test_vhdl_generation.py`

**test_volo_app.py checklist**:
- [ ] Test: Valid VoloApp creation
- [ ] Test: Duplicate CR numbers (ValidationError)
- [ ] Test: CR number out of range (<20)
- [ ] Test: CR number out of range (>30)
- [ ] Test: Too many registers (>11)
- [ ] Test: Counter value out of range (>255)
- [ ] Test: Percent value out of range (>100)
- [ ] Test: Button value invalid (not 0 or 1)
- [ ] Test: Signal name conversion:
  - [ ] "Pulse Width" → "pulse_width"
  - [ ] "Enable Output" → "enable_output"
  - [ ] "PWM Duty %" → "pwm_duty"
- [ ] Test: YAML save/load round-trip
- [ ] Test: `to_deployment_config()` output format

**test_vhdl_generation.py checklist**:
- [ ] Test: `get_vhdl_bit_range()` for each register type
- [ ] Test: `get_vhdl_type_declaration()` for each type
- [ ] Test: Shim generation produces valid VHDL
- [ ] Test: Main generation produces valid VHDL
- [ ] Test: Generated shim includes all registers
- [ ] Test: Generated shim has correct signal names

**Run tests**:
```bash
cd tests/models
uv run pytest -v
```

---

### Task 1.5: Example VoloApp Definition

**Location**: `modules/PulseStar/`

**Files to create**:
- [ ] `modules/PulseStar/PulseStar_app.yaml`

**Content** (see example in VOLO_APP_DESIGN.md):
- [ ] Name: PulseStar
- [ ] Version: 1.0.0
- [ ] 3 registers:
  - [ ] CR20: Pulse Width (counter_8bit)
  - [ ] CR21: Duty Cycle (percent)
  - [ ] CR22: Enable Output (button)

**Test generation**:
```bash
python tools/generate_volo_app.py \
  --config modules/PulseStar/PulseStar_app.yaml \
  --output modules/PulseStar/volo_main/

# Should create:
# - modules/PulseStar/volo_main/PulseStar_volo_shim.vhd
# - modules/PulseStar/volo_main/PulseStar_volo_main.vhd
```

---

## Phase 1 Success Criteria

Phase 1 complete when:
- [x] All files in Task 1.1 created and tested
- [x] All files in Task 1.2 created and compile with GHDL
- [x] `generate_volo_app.py` successfully generates shim + main
- [x] All pytest tests pass
- [x] Example `PulseStar_app.yaml` validates and generates VHDL
- [x] Generated VHDL compiles with `ghdl -a --std=08`

---

## Phase 2: Example Implementation

**Goal**: Create first complete volo-app (PulseStar) to validate architecture

### Task 2.1: PulseStar VoloApp

**Location**: `modules/PulseStar/`

- [ ] Create `PulseStar_app.yaml` (if not done in Phase 1)
- [ ] Run `generate_volo_app.py`
- [ ] Verify `PulseStar_volo_shim.vhd` generated correctly
- [ ] Implement `PulseStar_volo_main.vhd`:
  - [ ] Read `pulse_width` signal
  - [ ] Read `duty_cycle` signal
  - [ ] Read `enable_output` signal
  - [ ] Generate pulse outputs (OutputA, OutputB)
  - [ ] Optionally use BRAM for timing LUT
- [ ] Compile with GHDL:
  ```bash
  cd modules/PulseStar
  ghdl -a --std=08 --work=work volo_main/PulseStar_volo_shim.vhd
  ghdl -a --std=08 --work=work volo_main/PulseStar_volo_main.vhd
  ```

### Task 2.2: Build Integration

- [ ] Update `scripts/build_mcc_package.py`:
  - [ ] Detect if module is a volo-app (has `<AppName>_app.yaml`)
  - [ ] Include `shared/volo/*.vhd` files
  - [ ] Include `modules/<app>/volo_main/*.vhd` files
  - [ ] Generate correct compilation order
- [ ] Test MCC package build:
  ```bash
  uv run python scripts/build_mcc_package.py modules/PulseStar
  ```
- [ ] Upload to CloudCompile
- [ ] Download bitstream
- [ ] Import to `latest/`

### Task 2.3: CocotB Testing

**Location**: `tests/`

- [ ] Create `tests/test_pulsestar_volo.py`:
  - [ ] Test reset behavior
  - [ ] Test register mapping (set friendly values)
  - [ ] Test VOLO_READY scheme (CR0[31:29])
  - [ ] Test pulse generation
  - [ ] Test BRAM interface (if used)
- [ ] Run tests:
  ```bash
  cd tests
  uv run make TEST_MODULE=pulsestar_volo
  ```

---

## Phase 3: Loader Utility

**Goal**: Implement `volo_loader.py` CLI for deployment

### Task 3.1: Loader Script

**Location**: `tools/volo_loader.py`

- [ ] CLI interface:
  ```bash
  python tools/volo_loader.py \
    --config <path_to_yaml> \
    --device <device_name> \
    --ip <device_ip>
  ```
- [ ] Implementation:
  - [ ] Load VoloApp from YAML
  - [ ] Connect to Moku device (use first-party library)
  - [ ] Load bitstream (check if already loaded)
  - [ ] Wait for device ready
  - [ ] Set CR0[31:29] (VOLO_READY + user_enable + clk_enable)
  - [ ] Stream 4KB buffer via CR10-CR14 protocol
  - [ ] Initialize app registers (CR20-CR30) with defaults
  - [ ] Poll for `loader_done` signal
  - [ ] Verify app responds (read outputs/status)
  - [ ] Logging and error handling

### Task 3.2: BRAM Loader Testing

**Location**: `tests/`

- [ ] Create `tests/test_volo_bram_loader.py`:
  - [ ] Test FSM state transitions
  - [ ] Test CR10-CR14 protocol
  - [ ] Test 4KB data streaming
  - [ ] Test `done` signal assertion
- [ ] Run tests:
  ```bash
  cd tests
  uv run make TEST_MODULE=volo_bram_loader
  ```

---

## Phase 4: Documentation

**Goal**: Comprehensive documentation for volo-app developers

### Task 4.1: User Documentation

- [x] `docs/VOLO_APP_DESIGN.md` (created in planning phase)
- [ ] `docs/VOLO_APP_QUICKSTART.md`:
  - [ ] Step-by-step tutorial
  - [ ] Create minimal volo-app from scratch
  - [ ] Generate VHDL
  - [ ] Build and deploy
- [ ] `docs/VOLO_REGISTER_MAP.md`:
  - [ ] CR0[31:29] detailed spec
  - [ ] CR10-CR14 protocol spec
  - [ ] CR20-CR30 app register conventions
  - [ ] Register type reference

### Task 4.2: Code Examples

**Location**: `examples/volo_apps/`

- [ ] Create `examples/volo_apps/minimal_example/`:
  - [ ] `minimal_app.yaml` (simplest possible volo-app)
  - [ ] `volo_main/Minimal_volo_main.vhd`
  - [ ] README with explanation
- [ ] Create `examples/volo_apps/full_featured/`:
  - [ ] `full_app.yaml` (uses all register types)
  - [ ] `volo_main/FullFeatured_volo_main.vhd`
  - [ ] Demonstrates BRAM usage
  - [ ] README with best practices

### Task 4.3: Serena Memory

- [ ] Create Serena memory: `volo_app_architecture.md`
  - [ ] Complete architecture reference
  - [ ] Naming conventions
  - [ ] Code generation workflow
  - [ ] Testing patterns
  - [ ] Common pitfalls
  - [ ] Troubleshooting guide

### Task 4.4: Update Existing Docs

- [ ] Update `CLAUDE.md`:
  - [ ] Add "VoloApp Architecture" section
  - [ ] Reference VOLO_APP_DESIGN.md
  - [ ] Add to "Core Abstractions" (alongside MokuConfig)
- [ ] Update `AGENTS.md`:
  - [ ] Add volo-app commands:
    - [ ] `generate_volo_app.py` usage
    - [ ] `volo_loader.py` usage
    - [ ] Build workflow for volo-apps
- [ ] Update `.cursor/rules.mdc`:
  - [ ] Reference volo_app_architecture.md memory

---

## Phase 5: Future Enhancements (Backlog)

**Not in initial implementation**

### GUI Generation
- [ ] Design Qt/Tkinter framework
- [ ] Auto-generate controls from AppRegister definitions
- [ ] Map register types to widgets (slider, spinbox, button)
- [ ] Live updates via `set_regs()` API
- [ ] Real-time output monitoring
- [ ] Save/load register presets

### Advanced Register Types
- [ ] Signed integers (int8, int16, int32)
- [ ] Fixed-point (Q format with configurable fraction bits)
- [ ] Enums (dropdown choices, mapped to integer values)
- [ ] Read-only status registers
- [ ] Bitmask registers (multiple boolean flags)

### Multi-App Loader
- [ ] Load multiple volo-apps to different slots
- [ ] Slot assignment in VoloApp model
- [ ] App switching/routing logic
- [ ] Shared BRAM partitioning
- [ ] Inter-app communication

### Build Validation
- [ ] Check bitstream implements volo interface (has loader FSM)
- [ ] Validate buffer is exactly 4KB
- [ ] Detect register conflicts at build time
- [ ] Synthesis report parsing (resource usage)

---

## Progress Tracking

| Phase | Status | Completion Date | Notes |
|-------|--------|-----------------|-------|
| Phase 1 | 🔵 Not Started | - | Ready to start |
| Phase 2 | ⬜ Planned | - | Depends on Phase 1 |
| Phase 3 | ⬜ Planned | - | Depends on Phase 2 |
| Phase 4 | ⬜ Planned | - | Parallel with Phase 3 |
| Phase 5 | ⬜ Backlog | - | Future work |

**Legend**: 🔵 Not Started | 🟡 In Progress | 🟢 Complete | ⬜ Planned

---

## Open Questions

1. **BRAM Loader FSM**: Do we have existing implementation to reference?
2. **MCC_TOP instantiation**: Should we use generics for app name, or hardcode initially?
3. **Template headers**: Include "GENERATED - DO NOT EDIT" warnings?
4. **Path validation**: Should VoloApp model check if files exist on disk?
5. **Helper functions**: Include ready bit combinators in volo_common_pkg?

---

## Next Immediate Steps

1. Start Phase 1, Task 1.1 (Pydantic Models)
2. Create `models/volo/` directory structure
3. Implement `AppRegister` and `RegisterType`
4. Implement `VoloApp` with VHDL generation methods
5. Write pytest tests for model validation

**Command to start**:
```bash
mkdir -p models/volo
cd models/volo
# Start coding!
```

---

**Document maintained by**: Volo Team
**Last updated**: 2025-01-25

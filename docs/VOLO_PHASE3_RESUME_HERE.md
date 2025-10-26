# VoloApp Phase 3 - Resume Context

**Date Created**: 2025-10-25
**Status**: Phase 1 & 2 ✅ Complete, Phase 3 Ready to Begin
**Branch**: `feature/implements-the-volo-plan` (merged to main)
**Commit**: `4c95cf1 feat: Implement VoloApp abstraction (Phase 1 & 2 complete)`

---

## Quick Context

**VoloApp** is a 3-layer abstraction system that enables human-friendly FPGA application deployment to Moku devices. It eliminates the need for developers to understand MCC (Moku Cloud Compile) register mappings by providing:

1. **YAML-based app definition** with friendly register names
2. **Auto-generated VHDL shim layer** for register mapping
3. **MCC-agnostic application code** using readable signal names

**Example**: Instead of writing `Control0(23 downto 16)`, developers write `pulse_width`.

---

## Architecture (3 Layers)

```
Layer 1: MCC_TOP_volo_loader.vhd (static, shared)
         ↓ CustomWrapper architecture
         ↓ Extracts CR0[31:29] VOLO_READY control bits
         ↓ Instantiates volo_bram_loader (CR10-CR14 protocol)
         ↓ Instantiates app-specific shim

Layer 2: <AppName>_volo_shim.vhd (GENERATED from YAML)
         ↓ Maps app_reg_20-30 → friendly signal names
         ↓ Computes global_enable from VOLO_READY bits
         ↓ Instantiates application main entity

Layer 3: <AppName>_volo_main.vhd (HAND-WRITTEN by developer)
         ↓ MCC-agnostic application logic
         ↓ Uses friendly signal names only
         ↓ Optionally uses 4KB BRAM buffer
```

---

## Register Map Convention

**VOLO_READY Control** (CR0[31:29]):
- `CR0[31]`: volo_ready (loader sets after deployment)
- `CR0[30]`: user_enable (user-controlled enable/disable)
- `CR0[29]`: clk_enable (clock gating for sequential logic)

**BRAM Loader Protocol** (CR10-CR14):
- 4KB buffer streaming via FSM
- Edge-detected write protocol
- `done` signal when complete

**Application Registers** (CR20-CR30):
- Max 11 registers per app
- Auto-mapped to friendly signal names
- Validated by Pydantic models

---

## Phase 1 & 2 Accomplishments ✅

### Phase 1: Core Infrastructure

**Pydantic Models** (`models/volo/`):
- `RegisterType` enum: COUNTER_8BIT, PERCENT, BUTTON
- `AppRegister`: Validates CR numbers (20-30), value ranges
- `VoloApp`: YAML serialization, VHDL generation methods

**Static VHDL** (`shared/volo/`):
- `volo_common_pkg.vhd`: Constants and helper functions
- `volo_bram_loader.vhd`: FSM for 4KB buffer streaming
- `MCC_TOP_volo_loader.vhd`: CustomWrapper architecture (Layer 1)

**Templates** (`shared/volo/templates/`):
- `volo_shim_template.vhd`: Jinja2 template for Layer 2
- `volo_main_template.vhd`: Jinja2 skeleton for Layer 3

**Code Generator** (`tools/generate_volo_app.py`):
- CLI with Rich colored output
- Always regenerates shim (with "DO NOT EDIT" warning)
- Only creates main if doesn't exist (protects developer work)
- Displays register mapping table

**Test Suite** (`tests/models/`):
- `test_volo_app.py`: Pydantic validation tests
- `test_vhdl_generation.py`: Template rendering tests
- `validate_phase1.py`: Standalone validator
- **All Phase 1 tests passing** ✅

### Phase 2: PulseStar Reference Implementation

**Application Logic** (`modules/PulseStar/volo_main/`):
- `PulseStar_volo_main.vhd`: PWM pulse generation
  - Configurable pulse width (1-255 cycles)
  - Duty cycle control (0-100%)
  - Differential outputs (OutputA, inverted OutputB)
  - Standard control signal pattern (Reset > ClkEn > Enable)
- `PulseStar_volo_shim.vhd`: GENERATED register mapping layer
  - CR20 → pulse_width (8-bit)
  - CR21 → duty_cycle (7-bit)
  - CR22 → enable_output (1-bit)

**Build Integration** (`scripts/build_mcc_package.py`):
- Auto-detects volo-apps (checks for `*_app.yaml`)
- Auto-generates manifest from VoloApp YAML
- Includes volo infrastructure files automatically
- Correct compilation order (main before shim)
- **PulseStar builds successfully** → `PulseStar.zip` (19.2 KB)

**CocotB Tests** (`tests/test_pulsestar_volo.py`):
- 7 comprehensive tests:
  1. Reset behavior
  2. VOLO_READY 3-bit control scheme
  3. Register mapping (CR20-CR22)
  4. Basic pulse generation
  5. Duty cycle control (0%, 25%, 50%, 75%, 100%)
  6. Enable/disable functionality
  7. Differential outputs
- Registered in `tests/test_configs.py` under "volo_apps"
- Uses MCC primitives and timeout wrappers

---

## Phase 3: Deployment Tooling (NOT YET STARTED)

**Goal**: Create `volo_loader.py` CLI for automated deployment to Moku hardware

**Location**: `tools/volo_loader.py`

**CLI Interface**:
```bash
python tools/volo_loader.py \
  --config modules/PulseStar/PulseStar_app.yaml \
  --device MokuB106 \
  --ip 192.168.13.159
```

**Implementation Tasks**:

1. **Load VoloApp Configuration**:
   - Parse `*_app.yaml` using VoloApp.load_from_yaml()
   - Extract bitstream path, buffer path, register defaults
   - Validate configuration

2. **Connect to Moku Device**:
   - Use first-party `moku` library
   - Discovery via IP or device name
   - Verify connection

3. **Load Bitstream**:
   - Check if bitstream already loaded (optimization)
   - Deploy bitstream to CustomWrapper slot
   - Wait for FPGA ready signal

4. **Initialize VOLO_READY Protocol**:
   - Set CR0[31:29] = 0b000 initially (all disabled)
   - Stream 4KB buffer via CR10-CR14 protocol
   - Poll loader FSM `done` signal (from BRAM loader)
   - Set CR0[31] = 1 (volo_ready)
   - Set CR0[30] = 1 (user_enable)
   - Set CR0[29] = 1 (clk_enable)

5. **Initialize Application Registers**:
   - Write CR20-CR30 with default values from YAML
   - Log register configuration

6. **Verify Deployment**:
   - Read outputs/status registers
   - Verify application responds
   - Print success message

7. **Error Handling**:
   - Network timeouts
   - Bitstream load failures
   - BRAM streaming errors
   - Clear error messages with recovery steps

**Reference Implementations**:
- Existing deployment scripts in `scripts/hardware/`
- MCC primitives in `tests/conftest.py` (mcc_set_regs, etc.)
- BRAM loader FSM in `shared/volo/volo_bram_loader.vhd`

**Testing**:
- Create `tests/test_volo_bram_loader.py`:
  - FSM state transitions
  - CR10-CR14 protocol validation
  - 4KB data streaming
  - `done` signal assertion timing

---

## File Locations Quick Reference

**Models**:
- `models/volo/volo_app.py` - Main VoloApp class
- `models/volo/app_register.py` - AppRegister and RegisterType

**VHDL Infrastructure**:
- `shared/volo/volo_common_pkg.vhd` - Constants and helpers
- `shared/volo/volo_bram_loader.vhd` - 4KB buffer loader FSM
- `shared/volo/MCC_TOP_volo_loader.vhd` - CustomWrapper architecture

**Templates**:
- `shared/volo/templates/volo_shim_template.vhd` - Layer 2 template
- `shared/volo/templates/volo_main_template.vhd` - Layer 3 skeleton

**Tools**:
- `tools/generate_volo_app.py` - VHDL code generator
- `tools/volo_loader.py` - **Phase 3 - TO BE CREATED**

**Example App**:
- `modules/PulseStar/PulseStar_app.yaml` - App definition
- `modules/PulseStar/volo_main/PulseStar_volo_main.vhd` - Application logic
- `modules/PulseStar/volo_main/PulseStar_volo_shim.vhd` - Generated shim
- `modules/PulseStar/cloudcompile_package/PulseStar.zip` - MCC package

**Tests**:
- `tests/models/validate_phase1.py` - Standalone Phase 1 validator
- `tests/test_pulsestar_volo.py` - PulseStar CocotB tests
- `tests/test_configs.py` - Test registry (pulsestar_volo entry)

**Build**:
- `scripts/build_mcc_package.py` - MCC package builder (volo-aware)

---

## How to Use (Current State)

### Create a New VoloApp

1. **Define app in YAML**:
```bash
# Example: modules/MyApp/MyApp_app.yaml
cat > modules/MyApp/MyApp_app.yaml <<EOF
name: MyApp
version: 1.0.0
description: My custom FPGA application
bitstream_path: modules/MyApp/latest/25ff_bitstreams.tar
buffer_path: modules/MyApp/buffers/data.bin

registers:
  - name: Threshold
    description: Trigger threshold
    reg_type: counter_8bit
    cr_number: 20
    default_value: 128

  - name: Enable Output
    description: Enable/disable output
    reg_type: button
    cr_number: 21
    default_value: 0
EOF
```

2. **Generate VHDL**:
```bash
python tools/generate_volo_app.py \
  --config modules/MyApp/MyApp_app.yaml \
  --output modules/MyApp/volo_main/
```

This creates:
- `MyApp_volo_shim.vhd` (GENERATED - always overwritten)
- `MyApp_volo_main.vhd` (TEMPLATE - only created if doesn't exist)

3. **Implement Application Logic**:
Edit `modules/MyApp/volo_main/MyApp_volo_main.vhd`:
- Read friendly signals: `threshold`, `enable_output`
- Implement your logic
- Drive OutputA, OutputB
- Optionally use BRAM buffer

4. **Build MCC Package**:
```bash
uv run python scripts/build_mcc_package.py modules/MyApp
```

This auto-detects volo-app and generates:
- `modules/MyApp/cloudcompile_package/MyApp.zip`
- Includes all volo infrastructure
- Ready to upload to CloudCompile

5. **Test with CocotB** (optional but recommended):
```bash
# Add test config to tests/test_configs.py
# Create tests/test_myapp_volo.py
uv run python tests/run.py myapp_volo
```

### Build and Deploy PulseStar (Example)

```bash
# Already built! Package ready:
ls modules/PulseStar/cloudcompile_package/PulseStar.zip

# Manual deployment steps (Phase 3 will automate this):
# 1. Upload PulseStar.zip to Moku Cloud Compile web interface
# 2. Wait for synthesis (~5-10 min)
# 3. Download 25ff*_bitstreams.tar
# 4. Import:
mkdir -p modules/PulseStar/incoming
mv ~/Downloads/25ff*_mokugo_* modules/PulseStar/incoming/
python scripts/import_mcc_build.py modules/PulseStar

# 5. Deploy to hardware (manual for now):
#    - Load bitstream via Moku API
#    - Stream 4KB buffer via CR10-CR14
#    - Set CR0 = 0xE0000000 (all control bits)
#    - Set CR20 = 100 (pulse_width)
#    - Set CR21 = 50 (duty_cycle)
#    - Set CR22 = 1 (enable_output)
```

---

## Design Decisions and Patterns

### Why 3 Layers?

**Layer 1 (Static)**: Shared infrastructure
- One instance for ALL volo-apps
- MCC integration (CustomWrapper)
- BRAM loading protocol
- VOLO_READY control scheme

**Layer 2 (Generated)**: Register mapping
- App-specific CR number → signal name mapping
- Auto-generated from YAML (never hand-edited)
- Type-safe signal conversions
- Global enable computation

**Layer 3 (Hand-Written)**: Application logic
- Developer writes pure VHDL here
- Zero knowledge of MCC registers
- Portable, testable, reusable
- Clean interface with friendly names

### Why CR0[31:29] for VOLO_READY?

**Problem**: During bitstream loading, all control registers initialize to 0x00000000. There's a network delay (10-200ms) before configuration arrives. Without a "ready" signal, the module sees all-zero inputs during this window.

**Solution**: Use CR0[31:29] as mandatory control bits:
- `CR0[31] = 0` → Module disabled (safe during all-zero state)
- `CR0[31] = 1` → MCC sets after config loaded (module ready)
- `CR0[30]` → User enable/disable
- `CR0[29]` → Clock enable (CRITICAL for clocked modules!)

**Benefits**:
- Safe default: All-zero state keeps module disabled
- Network-aware: External system sets CR0[31]=1 when ready
- Active-high: No confusing inversions
- Testable: CocotB simulates realistic initialization

### Why Auto-Generate Shim but Not Main?

**Shim (Always Generated)**:
- Register mapping is mechanical, error-prone if hand-written
- Changes whenever YAML is updated
- No custom logic, purely data transformation
- Contains "DO NOT EDIT MANUALLY" warning

**Main (Protect Developer Work)**:
- Contains valuable hand-written application logic
- Expensive to recreate if accidentally overwritten
- Template only created ONCE (skeleton for developer to fill in)
- Use `--force` flag to regenerate if truly needed

---

## Common Workflows

### Update Register Definitions

1. Edit `<AppName>_app.yaml`
2. Regenerate shim: `python tools/generate_volo_app.py --config <yaml> --output volo_main/`
3. Shim is updated, main is unchanged ✅
4. Rebuild: `uv run python scripts/build_mcc_package.py modules/<AppName>`

### Add New Register

1. Add to YAML `registers:` list
2. Ensure `cr_number` is unique (20-30 range)
3. Regenerate shim
4. Update main entity to use new signal (compiler will warn if missing)

### Test Changes

```bash
# Run CocotB tests
uv run python tests/run.py <appname>_volo

# Or run all volo-app tests
uv run python tests/run.py --category=volo_apps
```

---

## Known Limitations

1. **Max 11 registers per app** (CR20-CR30)
   - If you need more, consider bit-packing into existing registers
   - Or use BRAM buffer for bulk configuration

2. **3 register types only**:
   - COUNTER_8BIT (0-255)
   - PERCENT (0-100)
   - BUTTON (0-1)
   - For other types, extend `RegisterType` enum in `app_register.py`

3. **4KB BRAM buffer fixed size**
   - Determined by volo_bram_loader FSM
   - Could be extended with different loader

4. **No runtime register addition**:
   - Register map is static (defined in YAML)
   - Changes require VHDL regeneration and rebuild

---

## Troubleshooting

### Build Errors

**"No mcc_package.yaml or *_app.yaml found"**:
- Create `<AppName>_app.yaml` in module directory
- Or create manual `mcc_package.yaml` for non-volo apps

**"volo_main/ directory not found"**:
- Run `generate_volo_app.py` first to create VHDL files

**"GHDL validation failed: unit not found"**:
- Check compilation order (main before shim)
- Ensure all volo infrastructure files are included

### Test Errors

**"Test timeout"**:
- Check timing constants (DEPTH+1 for shift registers)
- Verify UART timing calculations
- Use `COCOTB_LOG_LEVEL=DEBUG` for detailed logs

**"Module not responding"**:
- Verify CR0[31:29] all set (use `mcc_cr0()` helper)
- Check enable signals (Reset > ClkEn > Enable priority)
- Ensure volo_ready AND user_enable AND clk_enable all high

---

## Phase 3 Success Criteria

✅ **volo_loader.py CLI exists and works**:
- Accepts YAML config path, device ID, IP address
- Connects to Moku device successfully
- Loads bitstream to CustomWrapper
- Streams 4KB buffer via CR10-CR14 protocol
- Initializes VOLO_READY control (CR0[31:29])
- Writes application register defaults (CR20-CR30)
- Verifies deployment (reads outputs)
- Clear error messages and recovery steps

✅ **BRAM Loader Testing**:
- CocotB tests for volo_bram_loader FSM
- Protocol validation (CR10-CR14)
- 4KB streaming verification
- FSM state transitions tested

✅ **End-to-End Workflow**:
- Create app YAML → Generate VHDL → Build → Deploy → Verify
- Works for PulseStar example
- Documented in VOLO_APP_QUICKSTART.md

✅ **Documentation**:
- User-facing tutorial (QUICKSTART)
- Deployment troubleshooting guide
- Example apps beyond PulseStar

---

## Next Session Checklist

When resuming Phase 3 work:

1. ✅ Read this file for context
2. ✅ Check git status: `git status`
3. ✅ Verify on main branch: `git branch --show-current`
4. ✅ Review Phase 3 tasks in VOLO_APP_IMPLEMENTATION_PLAN.md
5. ✅ Check Serena memories if needed:
   - `mcp__serena__read_memory cocotb_testing_guide`
   - `mcp__serena__read_memory mokuconfig_core_abstraction`
6. ✅ Start with `tools/volo_loader.py` CLI skeleton
7. ✅ Reference existing deployment scripts in `scripts/hardware/`

---

## Resources

**Design Documents**:
- `docs/VOLO_APP_DESIGN.md` - Complete architecture
- `docs/VOLO_APP_IMPLEMENTATION_PLAN.md` - Phase breakdown
- `docs/VOLO_APP_FRESH_CONTEXT.md` - Fresh context window primer

**Code Examples**:
- `modules/PulseStar/` - Complete working example
- `tests/test_pulsestar_volo.py` - Test patterns
- `tests/conftest.py` - MCC primitives and helpers

**MCC Reference**:
- `mcc_templates/CustomWrapper_test_stub.vhd` - MCC entity
- `shared/volo/MCC_TOP_volo_loader.vhd` - CustomWrapper architecture

**Serena Memories**:
- `cocotb_testing_guide` - Testing framework patterns
- `mokuconfig_core_abstraction` - Deployment model
- `mcc_build_pattern` - CloudCompile workflow

---

## Summary

**Phase 1 & 2**: ✅ COMPLETE
**Phase 3**: Ready to begin

The VoloApp abstraction is **working and tested**. PulseStar successfully builds and generates a valid MCC package. The only remaining task is automating deployment to hardware via `volo_loader.py`.

**Key Achievement**: Developers can now write MCC-agnostic VHDL using friendly signal names. The system handles all register mapping automatically.

**Ready for**: Hardware deployment automation (Phase 3)

---

*Generated: 2025-10-25*
*Last Updated: 2025-10-25*
*Commit: 4c95cf1*

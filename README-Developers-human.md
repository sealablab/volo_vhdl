# Volo VHDL Developer Guide

**Last Updated**: October 25, 2025 (Major Reorganization)

Welcome! This guide explains the refreshed organizational structure after our October 2025 cleanup. The codebase is now simpler, flatter, and easier to navigate.

## 🗂️ Directory Structure (The Big Picture)

```
volo_vhdl/
├── instruments/              # 🎯 Production instruments (deploy to Moku hardware)
│   ├── EMFI-Seq/            # EMFI sequencer
│   ├── PulseStar/           # Pulse generator
│   └── SimpleWaveGen/       # Waveform generator
│
├── experimental/             # 🧪 Experimental/prototype instruments
│   ├── bram_test_minimal/
│   ├── buffer_waveform_gen/
│   └── inspectable_buffer_loader/
│
├── modules/                  # 📦 VHDL module library
│   ├── shared/              # Shared utilities (FLAT - no nested hierarchies!)
│   │   ├── core/           # Digital primitives (19 modules)
│   │   ├── packages/       # Type definitions (5 packages)
│   │   └── observer/       # Debug/monitoring (1 module)
│   ├── oddball/            # Special cases (don't fit standard patterns)
│   │   └── volo_pinata_tx/
│   ├── examples/           # Educational examples
│   │   └── fsm_example/
│   └── untested/           # Modules without CocotB tests
│
├── tests/                    # 🧪 Python-based testing (CocotB)
│   ├── run.py              # Test runner (replaces Makefiles!)
│   ├── conftest.py         # Shared test utilities
│   ├── test_configs.py     # Test configuration
│   └── test_*.py           # Individual test modules
│
├── scripts/                  # 🔧 Build and deployment scripts
│   ├── build_vhdl_deps.py  # VHDL dependency graph builder
│   ├── build_mcc_package.py
│   └── import_mcc_build.py
│
├── docs/                     # 📚 Documentation
│   └── packages/           # Package documentation
│
├── mcc_templates/            # MCC CustomWrapper templates
├── .serena/memories/         # AI agent knowledge base
├── CLAUDE.md                 # Claude Code guidance (always read this!)
└── AGENTS.md                 # Quick build commands
```

## 🎯 Key Organizational Principles

### **1. Hierarchy Follows Purpose**

- **Top-Level Instruments** → Have `top/Top.vhd` for MCC CustomWrapper integration
- **Flat Utilities** → Simple single-file modules in `modules/shared/`
- **Special Cases** → Oddball modules that don't fit patterns

### **2. No More Nested Redundancy**

❌ **OLD (redundant hierarchy for single files):**
```
modules/shared/
└── volo_common/
    └── core/
        └── volo_clk_divider.vhd  (single file!)
```

✅ **NEW (flat and simple):**
```
modules/shared/
└── core/
    └── volo_clk_divider.vhd
```

### **3. 100% Python Build System**

**No Makefiles!** Everything is Python-based:
- Build: `scripts/build_vhdl_deps.py`
- Test: `tests/run.py`
- CI/CD: Uses the Python scripts

## 🚀 Quick Start

### Initial Setup

```bash
# Install Python dependencies (first time only)
uv sync --no-install-project

# Build VHDL dependency graph
uv run python scripts/build_vhdl_deps.py

# Verify everything works
uv run python tests/test_configs.py
```

### Running Tests

```bash
# List all available tests
uv run python tests/run.py --list

# Run a specific test
uv run python tests/run.py volo_clk_divider --no-waves

# Run by category
uv run python tests/run.py --category=uart
```

### Building

```bash
# Import all sources (builds dependency graph)
uv run python scripts/build_vhdl_deps.py

# Clean build artifacts
uv run python scripts/build_vhdl_deps.py --clean

# Elaborate specific entity
uv run python scripts/build_vhdl_deps.py --entity volo_clk_divider
```

## 📦 Module Library Organization

### Shared Modules (Flattened)

All utility modules live in **flat directories** under `modules/shared/`:

#### **core/** - Digital Primitives (19 modules)
Single-file utility modules:
- `volo_clk_divider.vhd` - Clock divider (Tier 1: Critical!)
- `volo_synchronizer.vhd` - CDC-safe synchronizer
- `volo_edge_detector.vhd` - Edge detection
- `volo_uart_tx_core.vhd` - UART transmitter
- `volo_comparator.vhd` - Digital comparator
- `volo_counter_nbit.vhd` - N-bit counter
- ... and 13 more

#### **packages/** - Type Definitions (5 packages)
- `volo_voltage_pkg.vhd` - Voltage conversion (Tier 1: Critical!)
- `volo_uart_pkg.vhd` - UART types and constants
- `volo_cobs_pkg.vhd` - COBS encoding
- `Moku_Pct_pkg.vhd` - Percentage utilities
- `mcc_loader_pkg.vhd` - MCC buffer loader

#### **observer/** - Debug/Monitoring (1 module)
- `fsm_observer.vhd` - Standardized FSM monitoring pattern

### Module Tiers (from SHARED_MODULES_AUDIT.md)

**Tier 1: Critical Infrastructure** (mandatory)
- `volo_clk_divider.vhd` - Used in ALL instruments
- `volo_voltage_pkg.vhd` - Type-safe voltage conversion

**Tier 2: General-Purpose Digital Primitives** (recommended)
- Synchronization: synchronizer, edge_detector, delay_line
- Logic: comparator, mux
- Counters: counter_nbit, pwm, debouncer

**Tier 3: Communication Protocols** (ChipWhisperer/EMFI)
- UART: uart_tx_core, uart_baud_gen
- SimpleSerial: simpleserial_v1_tx, simpleserial_v2_tx

## 🎯 Instrument Development

### When to Create an Instrument vs. Module

**Create a top-level instrument** when:
- ✅ It has MCC CustomWrapper integration (`top/Top.vhd`)
- ✅ It's deployable to Moku hardware
- ✅ It's a complete application with user-facing functionality

**Create a shared module** when:
- ✅ It's a reusable utility (clk divider, UART, etc.)
- ✅ It's a single-file component
- ✅ Multiple instruments will use it

### Instrument Directory Structure

```
instruments/my_instrument/
├── common/              # Shared utilities (optional)
├── datadef/             # Data structures, LUTs (optional)
├── core/                # Pure algorithmic logic
│   └── my_instrument_core.vhd
├── top/                 # MCC Platform integration
│   ├── MyInstrument.vhd         # Entity + architecture
│   └── Top.vhd                  # CustomWrapper architecture
├── mcc_package.yaml     # MCC CloudCompile config
├── instrument.yaml      # Instrument metadata
└── README.md
```

**Key files:**
- `MyInstrument.vhd` - Main module (instantiates cores)
- `Top.vhd` - **ONLY architecture** for CustomWrapper (MCC provides entity)

### MCC 3-Bit Control Scheme (MANDATORY!)

All MCC modules **MUST** use 3 control bits in Control0[31:29]:

```vhdl
-- Control0[31] = MCC_READY (auto-set by MCC after deployment)
-- Control0[30] = Enable (user-controlled)
-- Control0[29] = ClkEn (CRITICAL! Sequential logic frozen if 0)

mcc_ready     <= Control0(31);
user_enable   <= Control0(30);
clk_enable    <= Control0(29);  -- ⚠️ MUST extract!
global_enable <= mcc_ready and user_enable and clk_enable;
```

**Critical**: Missing bit 29 is the #1 cause of "frozen modules"!

**Test helpers** (in `tests/conftest.py`):
```python
await mcc_set_regs(dut, {
    0: mcc_cr0(divider=240),  # Returns 0xEEF00000 (all 3 bits set)
    1: 0x043C7D00,
    2: 0x64000000
}, set_mcc_ready=True)
```

## 🧪 Testing with CocotB

### Adding a New Test

1. **Create test file**: `tests/test_my_module.py`

```python
import cocotb
from cocotb.triggers import RisingEdge
from conftest import setup_clock, reset_active_low

@cocotb.test()
async def test_basic_functionality(dut):
    """Test 1: Basic functionality"""
    dut._log.info("Test 1: Basic functionality")

    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut)

    # Your test logic here
    assert dut.output.value == 0
    dut._log.info("✓ Test PASSED")
```

2. **Add to test_configs.py**:

```python
"my_module": TestConfig(
    name="my_module",
    sources=[
        SHARED_CORE / "volo_clk_divider.vhd",  # Dependencies
        INSTRUMENTS / "MyInstrument/core/my_module.vhd",
    ],
    toplevel="my_module",
    test_module="test_my_module",
    category="instruments",
),
```

3. **Run it**:

```bash
uv run python tests/run.py my_module --no-waves
```

### Test Utilities (conftest.py)

**Clock and Reset:**
- `setup_clock(dut, clk_signal="clk", period_ns=10)` - Start clock
- `reset_active_low(dut, rst_signal="n_reset", cycles=2)` - Reset
- `reset_active_high(dut, rst_signal="reset", cycles=2)` - Reset

**MCC Primitives:**
- `init_mcc_inputs(dut)` - Initialize all MCC ports to safe defaults
- `mcc_set_regs(dut, regs, set_mcc_ready=True)` - Set Control registers
- `mcc_cr0(divider=0, extra_bits=0)` - Build Control0 with 3-bit scheme
- `wait_for_mcc_ready(dut, timeout_ns=100)` - Wait for MCC_READY

**Utilities:**
- `count_pulses(dut, signal, duration_ns)` - Count pulses on signal
- `wait_cycles(dut, n, clk_signal="clk")` - Wait N clock cycles

## 🔧 Build System Details

### Dependency Graph Builder

`scripts/build_vhdl_deps.py` discovers all VHDL files and builds dependency graph:

```bash
# What it does:
# 1. Scans instruments/, experimental/, modules/ for *.vhd files
# 2. Skips testbenches (tb/), wrappers, cloudcompile packages
# 3. Uses `ghdl -i` to import sources (fast, no compilation)
# 4. GHDL analyzes dependencies automatically
```

**Locations searched:**
- `instruments/` (top-level)
- `experimental/` (top-level)
- `modules/shared/core/`, `packages/`, `observer/`
- `modules/oddball/`
- `modules/examples/`
- `modules/untested/`

**Output**: GHDL work library with dependency graph (no binaries compiled by default)

### CI/CD Integration

GitHub Actions workflows use the Python scripts:

**`.github/workflows/build-and-test.yml`:**
- Builds dependency graph
- Runs multiple CocotB tests

**`.github/workflows/smoke-test.yml`:**
- Quick smoke test (dependency graph only)

## 📁 Where Things Live

### Finding Files

**Shared utilities:**
```
modules/shared/core/volo_clk_divider.vhd
modules/shared/packages/volo_voltage_pkg.vhd
modules/shared/observer/fsm_observer.vhd
```

**Instruments:**
```
instruments/EMFI-Seq/core/EMFI_Seq_fsm.vhd
instruments/PulseStar/core/waveform_gen_core.vhd
```

**Tests:**
```
tests/test_volo_clk_divider.py
tests/test_emfi_seq_top.py
```

**Documentation:**
```
docs/packages/Moku-Voltage-LUTS.md
CLAUDE.md                    # Read this for Claude Code guidance!
AGENTS.md                    # Quick build commands
REORGANIZATION_2025-10-25.md # Details of Oct 2025 cleanup
BUILD_TEST_VERIFICATION.md   # Verification report
```

### Import Paths in VHDL

All modules compile into the same `work` library:

```vhdl
-- Use shared utilities
use work.volo_voltage_pkg.all;
use work.volo_clk_divider;

-- Direct instantiation (required for top layer!)
U1: entity work.volo_clk_divider
    port map (
        clk => clk,
        ...
    );
```

**Never use component declarations in top layer** - always direct instantiation!

## 🎓 Learning Resources

### Essential Documentation (Read First!)

1. **`CLAUDE.md`** - Claude Code guidance (authoritative)
2. **`AGENTS.md`** - Quick build commands
3. **`tests/README.md`** - CocotB testing framework
4. **`tests/conftest.py`** - Test utilities reference

### Serena Memories (AI Knowledge Base)

Access via `.serena/memories/` or through `.cursor/rules.mdc`:

**Essential memories:**
- `codebase_structure.md` - Directory organization (updated Oct 2025)
- `coding_standards.md` - VHDL rules and tiered system
- `design_patterns.md` - Common implementation patterns
- `cocotb_testing_guide.md` - Testing framework guide
- `mcc_debugging_techniques.md` - MCC troubleshooting

**Instrument-specific:**
- `instrument_*` - Individual instrument documentation
- `mcc_*` - MCC integration patterns
- `bench_config_framework.md` - Multi-instrument testbench

### Working Examples

**Simple Direct Mapping:**
- `instruments/EMFI-Seq/` - 2-file MCC integration pattern
- `modules/examples/fsm_example/` - Educational FSM example

**Platform Interface Package:**
- `instruments/SimpleWaveGen/` - Complex MCC integration with validation

**Shared Utilities:**
- `modules/shared/core/volo_clk_divider.vhd` - Simple utility module
- `modules/shared/packages/volo_voltage_pkg.vhd` - Type-safe conversions

## 🚨 Common Pitfalls (Don't Do This!)

1. ❌ **Creating nested hierarchies** for single files
   - ✅ Put single-file utilities in `modules/shared/core/` directly

2. ❌ **Using component declarations** in top layer
   - ✅ Use direct instantiation: `entity work.module_name`

3. ❌ **Forgetting Clock Enable (bit 29)** in MCC modules
   - ✅ Extract all 3 bits: MCC_READY, Enable, ClkEn

4. ❌ **Creating new GHDL testbenches** (deprecated)
   - ✅ Use CocotB Python tests in `tests/`

5. ❌ **Creating Makefiles**
   - ✅ Use Python scripts: `build_vhdl_deps.py`, `tests/run.py`

6. ❌ **Using enumeration types** in RTL
   - ✅ Use `std_logic_vector` with constants (Verilog portability)

7. ❌ **Manually setting Control0** in tests
   - ✅ Use `mcc_set_regs()` helper (validates 3-bit scheme)

## 🎯 Development Workflow

### Adding a New Shared Module

```bash
# 1. Create the VHDL file
vim modules/shared/core/my_new_module.vhd

# 2. Create CocotB test
vim tests/test_my_new_module.py

# 3. Add to test_configs.py
vim tests/test_configs.py
# Add TestConfig entry

# 4. Run test
uv run python tests/run.py my_new_module --no-waves

# 5. Build dependency graph
uv run python scripts/build_vhdl_deps.py
```

### Adding a New Instrument

```bash
# 1. Create directory structure
mkdir -p instruments/MyInstrument/{core,top,datadef}

# 2. Create core logic
vim instruments/MyInstrument/core/my_instrument_core.vhd

# 3. Create MCC integration
vim instruments/MyInstrument/top/MyInstrument.vhd  # Entity + architecture
vim instruments/MyInstrument/top/Top.vhd           # CustomWrapper architecture

# 4. Create test
vim tests/test_my_instrument.py
# Update tests/test_configs.py

# 5. Test
uv run python tests/run.py my_instrument --no-waves
```

### MCC CloudCompile Deployment

```bash
# 1. Build MCC package
uv run python scripts/build_mcc_package.py instruments/MyInstrument

# 2. Upload to CloudCompile
# Open instruments/MyInstrument/cloudcompile_package/
# Upload MyInstrument.zip to Moku Cloud Compile web interface

# 3. Download results and stage
mkdir -p instruments/MyInstrument/incoming
mv ~/Downloads/25ff*_mokugo_* instruments/MyInstrument/incoming/

# 4. Import to latest/
python scripts/import_mcc_build.py instruments/MyInstrument

# 5. Test on hardware
cd tests
uv run python test_my_instrument_mokubench.py \
  --ip 192.168.13.159 \
  --bitstream ../instruments/MyInstrument/latest/25ff*_bitstreams.tar
```

## 🔍 Troubleshooting

### Build Issues

**"No VHDL files found"**
- Check you're running from project root
- Verify file extensions are `.vhd` (not `.vhdl`)

**"Missing source files"**
- Run `uv run python tests/test_configs.py` to validate paths
- Check `test_configs.py` uses new flat paths (`SHARED_CORE`, not `VOLO_COMMON`)

### Test Issues

**"Module freezes" in MCC tests**
- Check Control0 has all 3 bits set (especially bit 29!)
- Use `mcc_cr0()` helper or `0xE0000000` base pattern
- Run `scripts/debug_mcc_config.py` for systematic testing

**Path errors in tests**
- Update `tests/test_configs.py` paths
- Use `SHARED_CORE`, `SHARED_PACKAGES`, `INSTRUMENTS`, not old nested paths

## 📚 Additional Resources

### Project-Specific

- **Migration guide**: `REORGANIZATION_2025-10-25.md`
- **Verification report**: `BUILD_TEST_VERIFICATION.md`
- **Shared modules audit**: `modules/SHARED_MODULES_AUDIT.md`

### External Documentation

- **GHDL**: https://ghdl.github.io/ghdl/
- **CocotB**: https://docs.cocotb.org/
- **UV (Python)**: https://docs.astral.sh/uv/

## 🤝 Contributing

### Before Committing

```bash
# 1. Build dependency graph
uv run python scripts/build_vhdl_deps.py

# 2. Run relevant tests
uv run python tests/run.py my_module --no-waves

# 3. Validate test configs
uv run python tests/test_configs.py
```

### Verification Checklist

- [ ] No Makefiles created (use Python scripts!)
- [ ] VHDL follows coding standards (see `coding_standards.md` memory)
- [ ] Top layer uses direct instantiation (no component declarations)
- [ ] MCC modules implement 3-bit control scheme
- [ ] CocotB test created (not GHDL testbench)
- [ ] Test config added to `test_configs.py`
- [ ] Test passes: `uv run python tests/run.py <name>`
- [ ] Dependency graph builds: `uv run python scripts/build_vhdl_deps.py`

## 💡 Tips & Best Practices

### File Organization

- **Keep it flat**: Single-file utilities go directly in `modules/shared/core/`
- **Use full hierarchy**: Only when you have multiple layers (common, datadef, core, top)
- **No redundancy**: Avoid creating `module/core/` for a single file

### Naming Conventions

- **Modules**: `volo_<name>.vhd` (e.g., `volo_clk_divider.vhd`)
- **Packages**: `volo_<name>_pkg.vhd` or `<Name>_pkg.vhd`
- **Tests**: `test_<module_name>.py`
- **Signals**: `ctrl_*` (control), `cfg_*` (config), `stat_*` (status)

### Testing

- **Test early, test often**: Add CocotB test as you develop
- **Use helpers**: `conftest.py` has clock, reset, MCC primitives
- **Validate with tools**: `mcc_set_regs()` checks 3-bit scheme automatically

---

**Questions?** Check `CLAUDE.md` or Serena memories (`.serena/memories/`)!

**Last Updated**: October 25, 2025 (Post-Reorganization)
**Branch**: `cleanup/shared-modules-consolidation` → merging to `main`

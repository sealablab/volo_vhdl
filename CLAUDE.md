# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Volo VHDL** is a VHDL-2008 project designed for **Verilog portability**, targeting FPGA development for Moku devices. The project features an AI-powered workflow, standardized module architecture, and comprehensive build/test infrastructure using GHDL.

## Core Abstractions ⭐

### MokuConfig - The Central Deployment Model

**`MokuConfig`** is THE core Python abstraction for this project:

📍 **Location**: `models/moku/platform_config.py`
🎯 **Purpose**: Single source of truth for deployment specification
🔄 **Dual Backend**: Works for BOTH CocotB simulation AND hardware deployment

**What it does:**
- Defines which instruments go in which slots (1-4 for Moku:Go)
- Specifies MCC signal routing (Input/Output/Slot connections)
- Validates configuration at creation time (type safety via Pydantic)
- Serializes to JSON/YAML for reproducibility
- Drives `tools/moku_go.py deploy` workflow

**Quick Example:**
```python
from models.moku import MokuConfig, SlotConfig, MokuConnection, MOKU_GO_PLATFORM

config = MokuConfig(
    platform=MOKU_GO_PLATFORM,
    slots={
        2: SlotConfig(
            instrument='CloudCompile',
            bitstream='modules/PulseStar/latest/*.tar'
        )
    },
    routing=[
        MokuConnection(source='Slot2OutA', destination='Output1'),
        MokuConnection(source='Slot2OutB', destination='Output2')
    ]
)

# Deploy to hardware
# $ moku_go.py deploy --device MokuB106 --config config.json

# Use in CocotB simulation (future)
# async def test_hardware(dut):
#     await deploy_mokuconfig(dut, config)
```

**Key Design Principle**:
> Write your deployment config ONCE → Use in simulation, hardware, and documentation

📚 **Deep Dive**: See Serena memory `mokuconfig_core_abstraction`

---

## Essential Documentation (Source of Truth)

Before making changes, consult these files:
- **`.cursor/rules.mdc`** - Complete coding standards and architecture rules (points to Serena memories)
- **`AGENTS.md`** - Concise agent guidelines and build commands
- **`tests/README.md`** - CocotB testing framework (NEW - preferred for all tests)
- **`tests/conftest.py`** - Shared CocotB test utilities

**Note**: Coding standards are maintained in Serena memories (accessed via `.cursor/rules.mdc`). Legacy ai-workflow/ documentation has been archived to `archive/ai-workflow-legacy-2025-10-22/`.

## Fresh Context Window Checklist

When starting with a fresh context window:

### 1. Check Serena Onboarding Status
```
mcp__serena__check_onboarding_performed
```
This will list all available memories. Don't read them all immediately - just be aware of what exists.

### 2. Verify Git State
- Current branch: `git branch --show-current`
- Working tree: `git status` (should be clean)
- Any stashed work: `git stash list`

### 3. Python Environment Setup (UV)
```bash
# First time setup - install dependencies
uv sync --no-install-project

# Verify dependencies are installed
uv pip list | grep -E "(cocotb|pydantic|moku)"
```
See `docs/UV_SETUP.md` for full documentation.

### 4. Understand Current Testing Framework
- **Standard**: CocotB (Python-based, async/await)
- **Location**: `tests/` directory
- **Reference**: `tests/test_clk_divider_core.py` (7 tests passing)
- **Python Env**: Use `uv run make TEST_MODULE=<module>` to run tests
- **⚠️ DO NOT**: Create new GHDL testbenches (deprecated)

### 5. Essential Serena Memories
Read these IMMEDIATELY for any task:
- **`mokuconfig_core_abstraction`** ⭐ - THE core deployment model (START HERE!)
- `cocotb_testing_guide` - Testing framework (NEW standard)
- `coding_standards` - VHDL rules and tiered system
- `design_patterns` - Common patterns and implementations

Read as needed:
- `codebase_structure` - Module organization
- `tech_stack` - Tools and platform info
- `mokuconfig_and_benchbench_framework` - Infrastructure models (MokuConfig vs BenchBench)

### 6. Key Documentation Files
- `CLAUDE.md` - This file (project overview)
- `AGENTS.md` - Build commands and quick start
- `docs/UV_SETUP.md` - Python environment setup with uv
- `docs/BENCH_FRAMEWORK_DESIGN.md` - Multi-instrument testbench framework
- `tests/README.md` - CocotB testing guide
- `.cursor/rules.mdc` - Points to Serena memories (source of truth)

## Build and Test Commands

### CocotB Testing (Preferred - New Standard)
```bash
# First time: Setup Python environment
uv sync --no-install-project

# Run tests (automatically uses .venv environment)
cd tests/
uv run make TEST_MODULE=clk_divider_core      # Run specific module tests
uv run make TEST_MODULE=bench_framework_poc   # Moku Platform Simulator PoC
uv run make list-tests                        # List available test modules
make clean                                    # Clean test artifacts
make waves                                    # View waveforms (if GTKWave installed)

# Environment variables
WAVES=1                    # Enable waveform dump (default)
WAVES=0                    # Disable waveforms for faster tests
COCOTB_LOG_LEVEL=DEBUG     # Set log level
```

### Central Build System (from `modules/` directory)
```bash
# Build all modules with dependency resolution
cd modules
make clean && make compile

# List all available modules
make list-modules

# Build specific module only
make compile-single-module MODULE_NAME=SimpleWaveGen
```

### GHDL Settings
- **Standard**: Always use `--std=08` for VHDL-2008
- **Usage**: Simulation backend for CocotB (not for direct testbench writing)
- **Compilation order**: Packages → Core → Top
- **Work library**: Unified work library shared across modules

### MCC CloudCompile Deployment Workflow

**Pattern**: Use `incoming/` folder per module for staging synthesis results

```bash
# 1. Build MCC package (creates cloudcompile_package/)
uv run python scripts/build_mcc_package.py modules/inspectable_buffer_loader

# 2. Upload to CloudCompile
#    • Open modules/<module>/cloudcompile_package/
#    • Upload <module>.zip to Moku Cloud Compile web interface
#    • Wait for synthesis (~5-10 min)

# 3. Download results and stage in incoming/
mkdir -p modules/inspectable_buffer_loader/incoming
mv ~/Downloads/25ff*_mokugo_* modules/inspectable_buffer_loader/incoming/

# 4. Import to latest/
python scripts/import_mcc_build.py modules/inspectable_buffer_loader

# 5. Test on hardware
cd tests
uv run python test_inspectable_buffer_loader_mokubench.py \
  --ip 192.168.13.159 \
  --bitstream ../modules/inspectable_buffer_loader/latest/25ff*_bitstreams.tar
```

**Benefits of `incoming/` folder pattern**:
- ✓ No ambiguity about which build to import (staged explicitly)
- ✓ Can accumulate multiple builds before deciding which to promote
- ✓ Clear separation: `incoming/` = staging, `latest/` = active
- ✓ Reduces human→robot friction during iteration cycles

**Directory structure per module**:
```
modules/<module>/
├── cloudcompile_package/  # Generated by build_mcc_package.py
│   ├── <module>.zip       # Upload this to CloudCompile
│   └── BUILD_MANIFEST.txt
├── incoming/              # Stage synthesis results here (YOU create)
│   ├── 25ff*.tar          # Downloaded from CloudCompile
│   └── 25ff*.log
└── latest/                # Active build (managed by import script)
    ├── 25ff*.tar
    ├── 25ff*.log
    └── BUILD_INFO.txt
```

## Module Architecture

### Directory Structure (Mandatory)
```
modules/module_name/
├── common/     # Shared utilities and packages (Tier 1: strict RTL rules)
├── datadef/    # Data structures, LUTs, records (Tier 2: relaxed rules)
├── core/       # Pure algorithmic logic (Tier 1: strict RTL rules)
├── top/        # Platform integration (Tier 1: strict RTL rules)
└── tb/         # Testbenches by layer (Tier 3: full VHDL-2008)
    ├── common/     # Package tests
    ├── datadef/    # Datadef tests
    ├── core/       # Core tests
    └── top/        # Integration tests
```

### Layer Responsibilities

**Common Layer** (`common/*.vhd`):
- Configuration constants and shared utilities
- Platform interface packages (register field management)
- Validation functions used across modules

**Datadef Layer** (`datadef/*.vhd`):
- LUT definitions and complex data structures
- Records allowed for data organization (with Verilog conversion strategy)
- Data validation utilities (CRC, checksums)
- No clock-dependent operations

**Core Layer** (`core/*.vhd`):
- Pure logic implementation, no platform-specific code
- FSMs using `std_logic_vector` state encoding (no enums)
- Standard control signals: `clk`, `reset`, `enable`, `clk_en`
- Default status register implementation

**Top Layer** (`top/*.vhd`):
- Integration with platform control system (Moku CustomWrapper)
- Two file pattern (see MCC Integration Patterns section):
  - **ModuleName.vhd**: Entity + architecture (instantiates cores with direct instantiation)
  - **Top.vhd**: CustomWrapper architecture only (maps registers to module ports)
- MCC provides CustomWrapper entity - do NOT create mcc-Top.vhd entity files
- Start with simple direct mapping pattern unless validation is needed

## Critical Coding Standards

### VHDL-2008 with Verilog Portability

**Allowed**:
- `std_logic`, `std_logic_vector`, `unsigned`, `signed`
- Generics and generate statements
- Synchronous processes with `rising_edge(clk)`
- Explicit bit widths

**Forbidden**:
- Records in port declarations (except datadef packages)
- Enumeration types in RTL (use `std_logic_vector` with constants)
- Subtype range constraints
- `wait` statements in RTL (allowed in testbenches)
- `after` delays
- Shared variables

### Direct Instantiation (MANDATORY for Top Layer)

All top-level files (`modules/**/top/*.vhd` and `modules/**/tb/top/*.vhd`) **MUST** use direct instantiation:

```vhdl
-- ✅ REQUIRED: Direct instantiation
U1: entity WORK.module_name
    port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        data_out => data_out
    );

-- ❌ FORBIDDEN in top layer: Component declaration
-- component module_name is ... end component;
-- U1: module_name port map (...);
```

### Standard Control Signals

**Priority Order** (highest to lowest):
1. **Reset** (`reset` or `n_reset`) - Forces safe state
2. **Clock Enable** (`clk_en`) - Freezes sequential logic when low
3. **Functional Enable** (`enable`) - Gates functional work

**Implementation Pattern**:
```vhdl
process(clk, n_reset)
begin
    if n_reset = '0' then
        -- Reset: All outputs to safe defaults
    elsif rising_edge(clk) then
        if clk_en = '1' then
            if enable = '1' then
                -- Normal operation
            else
                -- Idle: Hold state, outputs parked
            end if;
        end if;
        -- clk_en='0': Hold state (no updates)
    end if;
end process;
```

### Signal Naming Conventions

- **`ctrl_*`** - Control signals (enable, reset)
- **`cfg_*`** - Configuration parameters
- **`stat_*`** - Status and monitoring signals

### Status Register Standards

- **Bit 7**: FAULT (sticky, cleared only on reset)
- **Bit 6**: ALARM (sticky, cleared only on reset)
- **Update timing**: Synchronous on rising edge
- **Reset behavior**: All bits cleared on reset

## FSM Implementation

Use `std_logic_vector` encoding with constants:

```vhdl
constant IDLE_STATE   : std_logic_vector(1 downto 0) := "00";
constant ACTIVE_STATE : std_logic_vector(1 downto 0) := "01";
constant DONE_STATE   : std_logic_vector(1 downto 0) := "10";

signal current_state : std_logic_vector(1 downto 0);
```

## Testing Requirements

### CocotB Tests (Preferred - New Standard)

⚠️ **DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead

**Test Structure:**
- **Location**: `tests/test_<module_name>.py`
- **Framework**: Python-based with async/await syntax
- **Utilities**: Shared helpers in `tests/conftest.py`
  - `setup_clock()`, `reset_active_low()`, `count_pulses()`, etc.
- **Example**: See `tests/test_clk_divider_core.py` (complete reference)

**Basic Template:**
```python
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low

@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("Test 1: Reset Behavior")

    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut)

    assert dut.output.value == 0, "Output should be 0 after reset"
    dut._log.info("✓ Reset test PASSED")
```

### Legacy GHDL Tests (Deprecated)

⚠️ **Status**: Being phased out - DO NOT CREATE NEW GHDL TESTBENCHES
- Old documentation archived in `archive/ghdl_testbench_docs_*/`
- Existing GHDL tests are being migrated to CocotB

## Tiered Rule System

**Tier 1** (Strict RTL - `common/`, `core/`, `top/`):
- Strict Verilog portability
- No enumeration types, no records in ports
- std_logic_vector state encoding mandatory

**Tier 2** (Relaxed Data - `datadef/`):
- Records allowed for data organization
- LUTs and complex constants permitted
- Must document Verilog conversion strategy
- No clock-dependent operations

**Tier 3** (Full VHDL-2008 - `tb/`):
- All VHDL-2008 features allowed
- Simulation-only code, no portability constraints

## Serena-First Knowledge Architecture

The project uses **Serena MCP** (Model Context Protocol) for AI-assisted development:
- **Serena memories**: Authoritative coding standards, design patterns, testing guides
- **Symbolic code access**: Intelligent navigation via `find_symbol`, `find_referencing_symbols`
- **Single source of truth**: All standards maintained in Serena, not scattered documentation

Access Serena memories via `.cursor/rules.mdc` or the `mcp__serena__*` tools.

## Platform Interface Package Pattern

For modules requiring register interfaces:
- Use platform interface packages in `common/` directory
- Define register field bit positions as constants
- Implement field extraction and status assembly functions
- Include validation functions with fault triggering

Example:
```vhdl
use work.platform_interface_pkg.all;

-- Validate configuration
if is_wave_select_valid(wave_select) = '0' then
    fault_out <= '1';  -- Trigger fault
end if;

-- Extract control fields
global_enable <= extract_ctrl_global_enable(ctrl0_data);

-- Assemble status register
status_reg <= assemble_status0_reg(enabled, wave_select);
```

## Contributing New Patterns

When you discover new patterns or solutions:
1. **Update Serena memories**: Use `mcp__serena__write_memory` to update relevant memories
2. **Document in code**: Add comments explaining the pattern
3. **Update AGENTS.md**: Add build commands or common tasks if applicable

**Key Serena memories for patterns:**
- `coding_standards.md` - VHDL rules and conventions
- `design_patterns.md` - Common implementation patterns
- `ghdl_patterns_and_solutions.md` - Build and test patterns

## Key Design Patterns

### Shared Modules
- `clk_divider` - Clock division utility (built first as dependency)
- `volo_common` - Common utilities across all modules

### MCC Integration Patterns

**Two patterns are supported for MCC (Moku CustomWrapper) integration:**

#### Pattern 1: Simple Direct Mapping (Preferred for simple modules)
**Example**: `modules/TPD/DCSequencer/`

File structure:
```
top/
├── ModuleName.vhd  # Entity + architecture (instantiates cores)
└── Top.vhd         # CustomWrapper architecture only
```

**ModuleName.vhd** - Main module file:
- Defines entity with clean interface
- Architecture instantiates core modules
- Uses standard port names (Clk, Reset, Enable, etc.)

**Top.vhd** - CustomWrapper integration:
- Contains ONLY architecture: `architecture ModuleName of CustomWrapper`
- MCC provides CustomWrapper entity declaration
- Direct register mapping in port map (no intermediate signals)
- No synchronous process, no default values
- Minimal complexity

Example from DCSequencer:
```vhdl
-- Top.vhd
architecture DCSequencer of CustomWrapper is
begin
    DC_SEQUENCER: entity WORK.DCSequencer
        port map (
            Clk => Clk,
            Reset => Reset,
            DataIn => InputA,
            HIThreshold => signed(Control0(31 downto 16)),
            LOThreshold => signed(Control0(15 downto 0)),
            DataOutA => OutputA,
            DataOutB => OutputB
        );
end architecture;
```

**When to use:**
- Simple register mapping
- No complex validation needed
- Minimal control logic
- Direct Control/Output port usage

#### Pattern 2: Platform Interface Package (For complex modules)
**Example**: `modules/SimpleWaveGen/`

File structure:
```
common/
└── platform_interface_pkg.vhd  # Register field extraction, validation
top/
├── ModuleName_top.vhd          # Entity + architecture with register logic
└── ModuleName_customwrapper.vhd # CustomWrapper architecture
```

**When to use:**
- Complex register field extraction
- Validation functions needed
- Multiple configuration parameters
- Status register assembly logic
- Fault detection/aggregation

**Key principle**: Start with Pattern 1 (simple). Only move to Pattern 2 if you need validation functions or complex register logic.

#### MCC 3-Bit Control Scheme (MANDATORY for ALL MCC modules)

**Added**: 2025-01-23 (Clock Enable discovery)
**Updated**: Expanded from original 1-bit MCC_READY convention

**Problem**: During FPGA bitstream loading, all MCC control registers initialize to 0x00000000. Modules must:
1. Remain disabled during network delay (10-200ms)
2. Enable clock gating for sequential logic
3. Provide user-level enable/disable control

**Solution**: Use **THREE mandatory control bits in Control0[31:29]**

```
Control0[31] = MCC_READY (active-high) - Set by MCC after deployment
Control0[30] = Enable (active-high) - User-controlled enable/disable
Control0[29] = ClkEn (active-high) - ⚠️ MANDATORY for clocked modules!
```

**Critical Discovery**: Missing Clock Enable (bit 29) is the **#1 cause of frozen modules**. Without bit 29, sequential logic is frozen even when "enabled" via bit 30.

**Configuration Patterns**:
```
# Correct (all 3 bits set):
0xE0000000 = 1110_0000_0000_0000... (base pattern)
0xEEF00000 = 1110_1110_1111_0000... (with Div=240)
             │││
             ││└── ClkEn (bit 29) ✓
             │└─── Enable (bit 30) ✓
             └──── MCC_READY (bit 31) ✓

# WRONG (missing bit 29):
0xC0000000 = 1100_0000... → MODULE FREEZES!
0xC0F00000 = 1100_0000... → MODULE FREEZES!
```

**VHDL Implementation Pattern** (Top.vhd):
```vhdl
-- Register Map (add to Top.vhd header comments):
-- MCC 3-Bit Control Scheme:
--   Control0[31] = MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
--   Control0[30] = User Enable (1=enable, 0=disable)
--   Control0[29] = Clock Enable (1=clocked, 0=frozen) ⚠️ MANDATORY
--   Control0[28:0] = Module-specific configuration

architecture ModuleName of CustomWrapper is
    -- MCC control signals (extract all 3 bits!)
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal clk_enable     : std_logic;
    signal global_enable  : std_logic;
begin
    -- Extract all 3 control bits (CRITICAL!)
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    clk_enable     <= Control0(29);  -- ⚠️ MUST extract!

    -- Combine all 3 for safe operation
    global_enable  <= mcc_ready and user_enable and clk_enable;

    MODULE_INST: entity WORK.ModuleName
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Enable => global_enable,  -- Safe: all 3 bits required
            ClkEn  => clk_enable,     -- Or '1' if always clocked
            ...
        );
end architecture;
```

**CocotB Test Pattern** (with validation and helpers):
```python
from conftest import (
    setup_clock, reset_active_high, init_mcc_inputs,
    mcc_set_regs, wait_for_mcc_ready, mcc_cr0  # Helper!
)

@cocotb.test()
async def test_initialization(dut):
    # Hardware startup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Option 1: Use helper (recommended, includes validation)
    await mcc_set_regs(dut, {
        0: mcc_cr0(divider=240),  # Returns 0xEEF00000 with all 3 bits
        1: 0x043C7D00,            # Module params
        2: 0x64000000
    }, set_mcc_ready=True)

    # Option 2: Manual (conftest validates and warns if bit 29 missing)
    await mcc_set_regs(dut, {
        0: 0xEEF00000,  # ✓ All 3 bits present (validated automatically)
        1: 0x043C7D00,
        2: 0x64000000
    }, set_mcc_ready=True)

    # Wait for module to settle
    await wait_for_mcc_ready(dut)

    # Test normal operation
    # ...
```

**Validation** (`conftest.py` provides automatic checking):
```python
# conftest.py provides:
MCC_READY_BIT = 31
ENABLE_BIT = 30
CLK_EN_BIT = 29  # ⚠️ CRITICAL!
MCC_CR0_BASE = 0xE0000000  # All 3 bits set

def validate_control0(cr0_value, context=""):
    """Warns if Clock Enable (bit 29) is missing"""
    # Automatically called by mcc_set_regs()

def mcc_cr0(divider=0, extra_bits=0):
    """Construct Control0 with all 3 bits"""
    # Returns 0xE0000000 | divider<<16 | extra_bits
```

**Why Clock Enable is Critical**:
Without Clock Enable (bit 29), the module's sequential logic is **completely frozen**:
- Counters don't increment
- State machines don't transition
- Outputs remain static
- Both simulation AND hardware appear "dead"

**Benefits**:
- ✓ Safe default: All-zero state keeps module disabled (bit 31=0)
- ✓ Network-aware: MCC sets CR0[31]=1 only after config loaded
- ✓ Clock gating: Bit 29 enables sequential logic (MANDATORY!)
- ✓ User control: Bit 30 provides runtime enable/disable
- ✓ Testable: CocotB validates configuration automatically
- ✓ Debuggable: Tools like `debug_mcc_config.py` test bit patterns

**Reference Implementations**:
- **`modules/PulseStar/top/Top.vhd`** - Full 3-bit scheme (2025-01-23)
- **`tests/conftest.py`** - Validation and helper functions (lines 83-164)
- **`scripts/debug_mcc_config.py`** - Systematic bit pattern testing tool

**Reference Documentation**:
- **`mcc_debugging_techniques.md`** (Serena memory) - Full debugging guide
- **`design_patterns.md`** (Serena memory) - Pattern #2, complete details
- **`tests/test_mcc_primitives.py`** - Validation test suite

**Historical Context**: This was the root cause of the 2025-01-23 PulseStar debugging session. Changing from 0xC0000000 (2 bits) to 0xE0000000 (3 bits) immediately fixed all "frozen module" issues.

### Dependency Management
- Shared modules built first in compilation order
- Module dependencies defined in `modules/Makefile.deps`
- Unified work library for cross-module references

## Working Examples

### Pattern 1 (Simple Direct Mapping)
**DCSequencer** (`modules/TPD/DCSequencer/`) - Minimal MCC integration:
- 2 files in top/: DCSequencer.vhd + Top.vhd
- Direct Control register mapping
- No platform interface package
- Clean and simple pattern

**EMFI-Seq** (`modules/EMFI-Seq/`) - Multi-core integration with MCC_READY:
- 2 files in top/: EMFI_Seq.vhd + Top.vhd
- Instantiates multiple cores (FSM + analog monitor)
- **Demonstrates MCC_READY pattern** (updated 2025-10-22)
- Direct register mapping with safe all-zero state handling
- Good example of simple multi-core integration

### Pattern 2 (Platform Interface Package)
**SimpleWaveGen** (`modules/SimpleWaveGen/`) - Complex MCC integration:
- Successfully deployed to Moku device
- Demonstrates full workflow from GHDL testing to bitstream
- Includes all layers: common, core, top, testbenches
- Uses platform_interface_pkg for validation
- See `GHDL-to-MCC-example.md` for development journey

**Recommendation**: Study DCSequencer or EMFI-Seq first for simple integrations. Use SimpleWaveGen as reference when you need validation/fault handling.

## Common Pitfalls

1. **Don't use component declarations in top layer** - Use direct instantiation
2. **Don't use enumeration types in RTL** - Use std_logic_vector with constants
3. **Don't skip testbench layers** - Follow 4-layer architecture
4. **Don't test internal state** - Test external behavior only
5. **Don't use records in RTL ports** - Only in datadef packages
6. **Don't create separate mcc-Top.vhd entity files** - MCC provides CustomWrapper entity
7. **Don't over-engineer MCC integration** - Start with Pattern 1 (simple direct mapping) unless you need validation
8. **Don't create new GHDL testbenches** - Use CocotB instead (see `tests/README.md`)
9. **Don't use inverted MCC_READY logic** - Use active-high CR0[31] convention (safe during all-zero state)
10. **Don't manually write Control0 in tests** - Use `mcc_set_regs()` primitive to handle MCC_READY correctly

## Verification Checklist

Before committing code:
- [ ] No VHDL-only features in RTL (except records in datadef)
- [ ] FSMs use vector state encoding with constants
- [ ] Proper signal prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- [ ] Top layer uses direct instantiation (`entity WORK.module_name`)
- [ ] Standard control signal priority: reset > clk_en > enable
- [ ] **MCC modules**: Implement MCC_READY convention (CR0[31] active-high)
- [ ] **MCC tests**: Use `mcc_set_regs()` primitive (don't manually write Control0)
- [ ] Testbench prints required messages (ALL TESTS PASSED, etc.)
- [ ] Testbench follows 4-layer architecture (or uses CocotB)
- [ ] GHDL compiles with `--std=08`
- [ ] All tests pass with `make test` or `make TEST_MODULE=<module>`

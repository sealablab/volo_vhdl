# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Volo VHDL** is a VHDL-2008 project designed for **Verilog portability**, targeting FPGA development for Moku devices. The project features an AI-powered workflow, standardized module architecture, and comprehensive build/test infrastructure using GHDL.

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

### 3. Understand Current Testing Framework
- **Standard**: CocotB (Python-based, async/await)
- **Location**: `tests/` directory
- **Reference**: `tests/test_clk_divider_core.py` (7 tests passing)
- **⚠️ DO NOT**: Create new GHDL testbenches (deprecated)

### 4. Essential Serena Memories
Read these as needed for your task:
- `cocotb_testing_guide` - Testing framework (NEW standard)
- `coding_standards` - VHDL rules and tiered system
- `design_patterns` - Common patterns and implementations
- `codebase_structure` - Module organization
- `tech_stack` - Tools and platform info

### 5. Key Documentation Files
- `CLAUDE.md` - This file (project overview)
- `AGENTS.md` - Build commands and quick start
- `tests/README.md` - CocotB testing guide
- `.cursor/rules.mdc` - Points to Serena memories (source of truth)

## Build and Test Commands

### CocotB Testing (Preferred - New Standard)
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module tests
make list-tests                        # List available test modules
make clean                             # Clean test artifacts
make waves                             # View waveforms (if GTKWave installed)

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

#### MCC_READY Convention (MANDATORY for ALL MCC modules)

**Added**: 2025-10-22

**Problem**: During FPGA bitstream loading, all MCC control registers initialize to 0x00000000. Network delay (10-200ms typical) occurs before configuration arrives. Modules must remain in a safe, disabled state during this "all-zero" period.

**Solution**: Use **Control0[31] as MCC_READY flag** (active-high)

```
Control0[31] = 0 → Module DISABLED (safe during all-zero state)
Control0[31] = 1 → Module ENABLED and ready for operation
```

**VHDL Implementation Pattern** (Top.vhd):
```vhdl
-- Register Map (add to Top.vhd header comments):
-- MCC_READY Convention:
--   Control0[31] = MCC_READY flag (ACTIVE-HIGH)
--     0 = Module disabled (safe during bitstream load / all-zero state)
--     1 = Module enabled and ready for operation
--
-- Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
-- Control0[30]:    User Enable (1=enable, 0=disable)
-- Control0[29:0]:  Module-specific configuration

architecture ModuleName of CustomWrapper is
    -- MCC control signals
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal global_enable  : std_logic;
begin
    -- Extract MCC_READY flag and gate module enable
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    global_enable  <= mcc_ready and user_enable;

    MODULE_INST: entity WORK.ModuleName
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Enable => global_enable,  -- Safe: disabled when CR0[31]=0
            ...
        );
end architecture;
```

**CocotB Test Pattern** (see `tests/conftest.py` for primitives):
```python
from conftest import (
    setup_clock, reset_active_high, init_mcc_inputs,
    mcc_set_regs, wait_for_mcc_ready
)

@cocotb.test()
async def test_initialization(dut):
    # Hardware startup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Simulate network delay + config (CR0[31] set automatically)
    await mcc_set_regs(dut, {
        0: 0x40000001,  # User bits (CR0[31] handled by primitive)
        1: 0x0000007F   # Module params
    }, set_mcc_ready=True)  # Sets CR0[31]=1 after config

    # Wait for module to settle
    await wait_for_mcc_ready(dut)

    # Test normal operation
    # ...
```

**Benefits**:
- ✓ Safe default: All-zero state keeps module disabled
- ✓ Clear semantic: Bit 31 = "configuration valid and ready"
- ✓ Active-high logic: No confusing inversions
- ✓ Network-aware: MCC sets CR0[31]=1 only after config loaded
- ✓ Testable: CocotB primitives simulate realistic network latency

**Reference Implementation**: `modules/EMFI-Seq/top/Top.vhd` (updated 2025-10-22)

**Test Reference**: `tests/test_mcc_primitives.py` (6 tests passing)

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

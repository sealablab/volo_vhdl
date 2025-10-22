# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Volo VHDL** is a VHDL-2008 project designed for **Verilog portability**, targeting FPGA development for Moku devices. The project features an AI-powered workflow, standardized module architecture, and comprehensive build/test infrastructure using GHDL.

## Essential Documentation (Source of Truth)

Before making changes, consult these files:
- **`.cursor/rules.mdc`** - Complete coding standards and architecture rules
- **`AGENTS.md`** - Concise agent guidelines and build commands
- **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
- **`ai-workflow/ng/README-ghdl-testbench-tips-ng.md`** - GHDL testbench patterns
- **`ai-workflow/ng/README-layered-testbench-ng.md`** - 4-layer testbench architecture

## Build and Test Commands

### Central Build System (from `modules/` directory)
```bash
# Build all modules with dependency resolution
cd modules
make clean && make compile && make test

# List all available modules
make list-modules

# Build specific module only
make compile-single-module MODULE_NAME=SimpleWaveGen
```

### Module-Level Build (from `modules/<module_name>/` directory)
```bash
# Clean, compile, and test a single module
make clean && make && make test

# Run specific testbench
make test-<testbench_name>

# Show help for module-specific targets
make help
```

### GHDL Settings
- **Standard**: Always use `--std=08` for VHDL-2008
- **Compilation order**: Packages → Core → Top → Testbenches
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

## Testbench Requirements

### 4-Layer Testing Architecture (Mandatory)

**Layer 1: Interface Testing**
- Test WHAT the module does, not HOW
- Focus on status register bits and external behavior
- No assumptions about internal state machine

**Layer 2: Validation Testing**
- Test parameter validation and error handling
- Invalid inputs should trigger fault/alarm status bits

**Layer 3: Functional Testing**
- Test core functionality and behavior
- Verify main operational features

**Layer 4: Generic Parameter Testing**
- Test different generic configurations
- Edge cases around parameter values

### Required Output Format

All testbenches must print:
```vhdl
report "ALL TESTS PASSED" severity note;  -- On success
report "TEST FAILED" severity error;       -- On failure
report "SIMULATION DONE" severity note;    -- Always at end
```

### Termination

Use one of these patterns:
```vhdl
-- Method 1: Clean stop (preferred)
std.env.stop(0);

-- Method 2: Assertion failure
assert false report "Simulation completed" severity failure;
```

### Testbench Location

Place testbenches in `tb/` subdirectories matching the tested layer:
- `tb/common/` - Tests for common packages
- `tb/datadef/` - Tests for datadef packages
- `tb/core/` - Tests for core modules
- `tb/top/` - Integration tests for top-level modules

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

## AI Workflow Integration

The project includes an AI-assisted development workflow in `ai-workflow/`:
- **Interface refinement** - AI-guided requirements specification
- **Code generation** - Automated VHDL generation from requirements
- **Templates** - Standardized starting points for new modules

See `ai-workflow/README.md` for complete workflow documentation.

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

## Contributing New Tips

When you discover new patterns or solutions, append them to the appropriate file:
- **Synthesizable VHDL tips** → `ai-workflow/ng/README-synth-vhdl-tips-ng.md`
- **GHDL testbench tips** → `ai-workflow/ng/README-ghdl-testbench-tips-ng.md`

Use the schema: **Problem / Cause / Solution / Pattern / Tags**

Append below the `------- New Tips here-------` marker. Do NOT reorganize the main bodies of these files.

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

**EMFI-Seq** (`modules/EMFI-Seq/`) - Multi-core integration:
- 2 files in top/: EMFI_Seq.vhd + Top.vhd
- Instantiates multiple cores (FSM + analog monitor)
- Direct register mapping
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
5. **Don't modify ng/ tip files** - Only append to footer section
6. **Don't use records in RTL ports** - Only in datadef packages
7. **Don't create separate mcc-Top.vhd entity files** - MCC provides CustomWrapper entity
8. **Don't over-engineer MCC integration** - Start with Pattern 1 (simple direct mapping) unless you need validation

## Verification Checklist

Before committing code:
- [ ] No VHDL-only features in RTL (except records in datadef)
- [ ] FSMs use vector state encoding with constants
- [ ] Proper signal prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- [ ] Top layer uses direct instantiation (`entity WORK.module_name`)
- [ ] Standard control signal priority: reset > clk_en > enable
- [ ] Testbench prints required messages (ALL TESTS PASSED, etc.)
- [ ] Testbench follows 4-layer architecture
- [ ] GHDL compiles with `--std=08`
- [ ] All tests pass with `make test`

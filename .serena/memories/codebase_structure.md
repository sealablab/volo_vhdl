# Codebase Structure

## Top-Level Directory Structure
```
volo_vhdl/
├── .cursor/              # Cursor/AI agent configuration
│   └── rules.mdc        # Complete coding standards (Source of Truth)
├── .serena/             # Serena MCP configuration
├── CLAUDE.md            # Claude Code guidance (Source of Truth)
├── AGENTS.md            # Agent guidelines and build commands (Source of Truth)
├── README.md            # Project documentation
├── ai-workflow/         # AI-powered development workflow
│   ├── ng/             # Next-generation tips and patterns
│   ├── prompts/        # AI prompts for different phases
│   ├── templates/      # Input form templates
│   └── examples/       # Complete workflow examples
├── modules/             # VHDL modules (main development area)
│   ├── Makefile        # Central build system
│   ├── Makefile.deps   # Module dependency definitions
│   ├── Makefile.shared # Shared Makefile rules
│   └── [modules...]    # Individual module directories
├── mcc_templates/       # MCC (Moku Custom Core) templates
├── templates/           # Reusable VHDL templates
└── static/              # Static assets (bitstream archives, etc.)
```

## Module Directory Structure (Mandatory)
Every VHDL module follows this standardized structure:

```
modules/<module_name>/
├── common/              # Shared utilities and packages (Tier 1: strict RTL)
├── datadef/             # Data structures, LUTs, records (Tier 2: relaxed rules)
├── core/                # Pure algorithmic logic (Tier 1: strict RTL)
├── top/                 # Platform integration (Tier 1: strict RTL, optional)
├── tb/                  # Testbenches (Tier 3: full VHDL-2008)
│   ├── common/         # Tests for common packages
│   ├── datadef/        # Tests for datadef packages
│   ├── core/           # Tests for core modules
│   └── top/            # Integration tests for top-level
├── Makefile             # Module-specific build rules
└── README.md            # Module documentation
```

## Existing Modules
- **SimpleWaveGen**: Complete reference implementation (deployed to hardware)
- **volo_common**: Common utilities shared across all modules
- **clk_divider**: Clock division utility (dependency for other modules)
- **probe_driver**: Probe driver functionality
- **probe_hero8, probe_hero9, probe_hero11**: Probe hero variants
- **stoplight**: Stoplight module
- **BPD**: BPD module (in development)

## Layer Responsibilities

### Common Layer (`common/*.vhd`) - Tier 1
- Configuration constants and shared utilities
- Platform interface packages (register field management)
- Validation functions used across modules

### Datadef Layer (`datadef/*.vhd`) - Tier 2
- LUT definitions and complex data structures
- Records allowed for data organization (with Verilog conversion strategy)
- Data validation utilities (CRC, checksums)
- No clock-dependent operations

### Core Layer (`core/*.vhd`) - Tier 1
- Pure logic implementation, no platform-specific code
- FSMs using `std_logic_vector` state encoding (no enums)
- Standard control signals: `clk`, `reset`, `enable`, `clk_en`
- Default status register implementation

### Top Layer (`top/*.vhd`) - Tier 1
- Integration with platform control system (Moku CustomWrapper)
- Register exposure (control, config, status)
- **REQUIRED**: Direct instantiation pattern for all module connections
- Do NOT include CustomWrapper entity body in module files

### Testbench Layer (`tb/*.vhd`) - Tier 3
- Full VHDL-2008 features allowed
- 4-layer testing architecture: Interface → Validation → Functional → Generic
- Testbenches organized by tested layer

## Essential Documentation Files (Source of Truth)
1. **`.cursor/rules.mdc`** - Complete coding standards and architecture rules
2. **`CLAUDE.md`** - Claude Code guidance
3. **`AGENTS.md`** - Concise agent guidelines and build commands
4. **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
5. **`ai-workflow/ng/README-ghdl-testbench-tips-ng.md`** - GHDL testbench patterns
6. **`ai-workflow/ng/README-layered-testbench-ng.md`** - 4-layer testbench architecture

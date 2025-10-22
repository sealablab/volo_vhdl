# Codebase Structure

## Top-Level Directory Structure
```
volo_vhdl/
├── .cursor/              # Cursor/AI agent configuration
│   └── rules.mdc        # Points to Serena memories (Source of Truth)
├── .serena/             # Serena MCP configuration and memories
├── CLAUDE.md            # Claude Code guidance (Source of Truth)
├── AGENTS.md            # Agent guidelines and build commands (Source of Truth)
├── README.md            # Project documentation
├── modules/             # VHDL modules (main development area)
│   ├── Makefile        # Central build system
│   ├── Makefile.deps   # Module dependency definitions
│   ├── Makefile.shared # Shared Makefile rules
│   └── [modules...]    # Individual module directories
├── tests/               # CocotB testing framework (NEW standard)
│   ├── Makefile        # CocotB test build system
│   ├── conftest.py     # Shared test utilities
│   └── test_*.py       # Individual test modules
├── mcc_templates/       # MCC (Moku Custom Core) templates
├── templates/           # Reusable VHDL templates
├── static/              # Static assets (bitstream archives, etc.)
└── archive/             # Archived legacy documentation
    ├── ai-workflow-legacy-2025-10-22/  # Legacy AI workflow (archived)
    └── ghdl_testbenches/               # Legacy GHDL tests (deprecated)
```

## Module Directory Structure (Mandatory)
Every VHDL module follows this standardized structure:

```
modules/<module_name>/
├── common/              # Shared utilities and packages (Tier 1: strict RTL)
├── datadef/             # Data structures, LUTs, records (Tier 2: relaxed rules)
├── core/                # Pure algorithmic logic (Tier 1: strict RTL)
├── top/                 # Platform integration (Tier 1: strict RTL, optional)
├── tb/                  # Testbenches (Tier 3: full VHDL-2008, deprecated)
│   ├── common/         # Tests for common packages (use CocotB instead)
│   ├── datadef/        # Tests for datadef packages (use CocotB instead)
│   ├── core/           # Tests for core modules (use CocotB instead)
│   └── top/            # Integration tests for top-level (use CocotB instead)
├── Makefile             # Module-specific build rules
└── README.md            # Module documentation
```

**Note**: The `tb/` directory structure is legacy. All new tests should use CocotB framework in the `tests/` directory.

## Existing Modules

### Shared/Common Modules
- **volo_common**: Common utilities shared across all modules
  - `common/Moku_Voltage_pkg.vhd` - Voltage conversion utilities (bidirectional: voltage ↔ digital, clamping, validation)
  - `common/Moku_Pct_pkg.vhd` - Type-safe percentage-to-voltage conversion (multiple range subtypes)
  - `core/clk_divider_core.vhd` - Clock divider with generic MAX_DIV, enable control, and linear division mapping (0=÷1, 1=÷2, etc.)

### Application Modules
- **SimpleWaveGen**: Complete reference implementation (Pattern 2: Platform Interface Package, deployed to hardware)
- **EMFI-Seq**: EMFI sequencer (Pattern 1: Simple Direct Mapping, voltage conversion pattern, multi-core integration)

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

### Testbench Layer - CocotB (NEW Standard)
- **Location**: `tests/` directory (project root level)
- **Framework**: Python-based with async/await syntax
- **Test files**: `test_<module_name>.py`
- **Shared utilities**: `conftest.py`
- **Examples**: `test_clk_divider_core.py`, `test_moku_pct_pkg.py`

### Legacy Testbench Layer (`tb/*.vhd`) - Tier 3 (Deprecated)
- **Status**: Being phased out - DO NOT CREATE NEW GHDL TESTBENCHES
- Full VHDL-2008 features allowed
- Archived to `archive/ghdl_testbenches/`
- Use CocotB framework in `tests/` for all new tests

## Essential Documentation Files (Source of Truth)
1. **`.cursor/rules.mdc`** - Points to Serena memories (authoritative)
2. **`CLAUDE.md`** - Claude Code guidance
3. **`AGENTS.md`** - Concise agent guidelines and build commands
4. **`tests/README.md`** - CocotB testing framework guide
5. **`tests/conftest.py`** - Shared CocotB test utilities

**Serena Memories** (accessed via `.cursor/rules.mdc`):
- `coding_standards.md` - VHDL rules and tiered system
- `design_patterns.md` - Common patterns and implementations
- `cocotb_testing_guide.md` - Testing framework
- `ghdl_patterns_and_solutions.md` - Build and test patterns
- `tech_stack.md` - Tools and platform info

## Archived Legacy Documentation
- **`archive/ai-workflow-legacy-2025-10-22/`** - Legacy AI workflow documentation (no longer maintained)
  - Status: Archived 2025-10-22, replaced by Serena-first architecture
  - See `archive/ai-workflow-legacy-2025-10-22/README-ARCHIVAL.md` for details

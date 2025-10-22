# Volo VHDL Project

**VHDL-2008 development for Moku FPGA devices with AI-powered workflow**

This project demonstrates a modern VHDL development approach combining:
- **Serena MCP** - AI agent knowledge management system
- **CocotB** - Python-based hardware verification
- **GHDL** - Open-source VHDL simulator
- **Standardized architecture** - Consistent module organization

## 🚀 Quick Start

### For AI Agents (Claude Code, Cursor, etc.)

**Essential files to read:**
1. **`CLAUDE.md`** - Project overview and quick reference
2. **`AGENTS.md`** - Build commands and agent guidelines
3. **`.cursor/rules.mdc`** - Points to Serena memories (source of truth)

**Check Serena onboarding status:**
```bash
# Use Serena MCP tool to check available memories
mcp__serena__check_onboarding_performed
```

**Available Serena memories** (read as needed):
- `project_overview.md` - High-level project context
- `codebase_structure.md` - Directory organization
- `coding_standards.md` - VHDL rules and tiered system
- `design_patterns.md` - Common implementation patterns
- `ghdl_patterns_and_solutions.md` - Build and compilation tips
- `cocotb_testing_guide.md` - Testing framework (current standard)
- `tech_stack.md` - Tools and platform information
- `task_completion_checklist.md` - Workflow checklist

### For Humans

**Read the documentation:**
- `CLAUDE.md` - Project overview and quick start
- `AGENTS.md` - Build commands and development workflow
- `tests/README.md` - CocotB testing guide

**Build and test:**
```bash
# Run CocotB tests (preferred)
cd tests/
make TEST_MODULE=clk_divider_core

# Build all modules
cd modules/
make clean && make compile
```

## 🎯 Working Example: SimpleWaveGen

**✅ Successfully deployed to Moku hardware!**

The `modules/SimpleWaveGen/` directory contains a complete reference implementation:
- Waveform generation (sine, square, triangle)
- Platform integration with Moku CustomWrapper
- Direct instantiation pattern
- CocotB tests (in development)

Download the working bitstream: `static/SimpleWaveGen-001-b.tar` (2.0MB)

## 📁 Project Structure

```
volo_vhdl/
├── .serena/              # Serena MCP memories (SOURCE OF TRUTH)
│   └── memories/         # Knowledge base for AI agents
├── .cursor/              # Cursor AI configuration
│   └── rules.mdc         # Points to Serena memories
├── CLAUDE.md             # Claude Code guidance
├── AGENTS.md             # Agent guidelines and build commands
├── README.md             # This file
├── modules/              # VHDL modules (main development area)
│   ├── volo_common/      # Shared utilities and packages
│   ├── EMFI-Seq/         # Active module example
│   ├── SimpleWaveGen/    # Reference implementation (deployed)
│   ├── Makefile          # Central build system
│   ├── Makefile.deps     # Module dependencies
│   └── Makefile.shared   # Shared build rules
├── tests/                # CocotB testing framework (PREFERRED)
│   ├── Makefile          # Test build system
│   ├── conftest.py       # Shared test utilities
│   ├── test_*.py         # Test modules
│   └── README.md         # Testing guide
├── static/               # Deployment artifacts (bitstreams)
└── archive/              # Legacy documentation (for reference)
```

## 🏗️ Module Architecture

Every VHDL module follows this standardized structure:

```
modules/<module_name>/
├── common/      # Shared utilities (Tier 1: strict RTL)
├── datadef/     # Data structures, LUTs (Tier 2: relaxed)
├── core/        # Pure algorithmic logic (Tier 1: strict RTL)
├── top/         # Platform integration (Tier 1: strict RTL)
├── tb/          # GHDL testbenches (DEPRECATED - use CocotB)
├── Makefile     # Module build rules
└── README.md    # Module documentation
```

### Layer Responsibilities

**Common** (`common/*.vhd`):
- Configuration constants
- Platform interface packages
- Validation functions

**Datadef** (`datadef/*.vhd`):
- LUT definitions
- Complex data structures
- Records (with Verilog conversion strategy)

**Core** (`core/*.vhd`):
- Pure logic implementation
- FSMs using `std_logic_vector` (no enums)
- Standard control signals: `clk`, `reset`, `enable`, `clk_en`

**Top** (`top/*.vhd`):
- Platform integration (Moku CustomWrapper)
- **REQUIRED**: Direct instantiation (`entity WORK.module_name`)
- Register mapping

## 🧪 Testing Framework

### CocotB (Current Standard)

**Location**: `tests/` directory

**Run tests:**
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module
make list-tests                        # List available tests
make clean                             # Clean artifacts
```

**Example test:** `tests/test_clk_divider_core.py` (7 tests passing)

**Reference:** See `tests/README.md` and Serena memory `cocotb_testing_guide.md`

### GHDL Testbenches (Deprecated)

**Status**: Being phased out - DO NOT create new GHDL testbenches

**Migration**: All new tests use CocotB framework

**Archive**: Old GHDL patterns preserved in `ghdl_patterns_and_solutions.md` Serena memory

## 🛠️ Build System

### CocotB Testing
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module tests
WAVES=1 make TEST_MODULE=clk_divider_core  # Enable waveforms
```

### Central Module Build
```bash
cd modules/
make clean && make compile             # Build all modules
make list-modules                      # List available modules
make compile-single-module MODULE_NAME=SimpleWaveGen
```

### GHDL Commands
```bash
# Always use VHDL-2008 standard
ghdl -a --std=08 --work=work <file.vhd>   # Analyze
ghdl -e --std=08 --work=work <entity>     # Elaborate
ghdl -r --std=08 --work=work <entity>     # Run
```

## 📚 Knowledge Management

### Serena MCP System

The project uses **Serena MCP** (Model Context Protocol) for knowledge management:

**Why Serena?**
- **Single source of truth** - All knowledge in `.serena/memories/`
- **Agent-friendly** - Structured, searchable memories
- **Version controlled** - Knowledge evolves with code
- **Cross-session** - Knowledge persists across AI agent sessions

**Available memories:**
- `coding_standards.md` - VHDL rules, tiered system, portability
- `design_patterns.md` - FSMs, control signals, register interfaces
- `ghdl_patterns_and_solutions.md` - Compilation, debugging, testbenches
- `cocotb_testing_guide.md` - Testing framework patterns
- `codebase_structure.md` - Directory organization
- `tech_stack.md` - Tools, platform, dependencies

**How to use:**
```bash
# AI agents: Use Serena MCP tools
mcp__serena__list_memories
mcp__serena__read_memory memory_file_name="coding_standards"

# Humans: Read directly
cat .serena/memories/coding_standards.md
```

## 🎯 Coding Standards

### VHDL-2008 with Verilog Portability

**Three-tier rule system:**

**Tier 1 (Strict RTL)** - `common/`, `core/`, `top/`:
- Only `std_logic`, `std_logic_vector`, `unsigned`, `signed`
- No enumeration types (use `std_logic_vector` with constants)
- No records in port declarations
- **MANDATORY**: Direct instantiation in top layer

**Tier 2 (Relaxed Data)** - `datadef/`:
- Records allowed for data organization
- LUTs and complex constants
- Must document Verilog conversion strategy

**Tier 3 (Full VHDL-2008)** - `tb/` (deprecated):
- All VHDL-2008 features allowed
- Use CocotB instead for new tests

### Direct Instantiation (MANDATORY)

All top-level files must use direct instantiation:

```vhdl
-- ✅ REQUIRED
U1: entity WORK.module_name
    port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        data_out => data_out
    );

-- ❌ FORBIDDEN in top layer
component module_name is ... end component;
U1: module_name port map (...);
```

### Signal Naming

- `ctrl_*` - Control signals (enable, reset)
- `cfg_*` - Configuration parameters
- `stat_*` - Status and monitoring

## 🔧 Key Design Patterns

### Shared Modules

**`modules/volo_common/`**:
- `volo_common_pkg.vhd` - General utilities
- `Moku_Voltage_pkg.vhd` - Voltage conversion (16-bit ADC/DAC)
- `Moku_Pct_pkg.vhd` - Type-safe percentage-to-voltage conversion
- `clk_divider_core.vhd` - Clock divider with enable control

### FSM Implementation

Use `std_logic_vector` encoding (no enums):

```vhdl
constant IDLE_STATE   : std_logic_vector(1 downto 0) := "00";
constant ACTIVE_STATE : std_logic_vector(1 downto 0) := "01";
constant DONE_STATE   : std_logic_vector(1 downto 0) := "10";

signal current_state : std_logic_vector(1 downto 0);
```

### Control Signal Priority

1. **Reset** (`reset` or `n_reset`) - Forces safe state
2. **Clock Enable** (`clk_en`) - Freezes sequential logic
3. **Functional Enable** (`enable`) - Gates functional work

## 📖 Documentation

### For AI Agents
- **`.cursor/rules.mdc`** - Points to Serena memories
- **`CLAUDE.md`** - Claude Code quick reference
- **`AGENTS.md`** - Build commands and guidelines
- **Serena memories** - Complete knowledge base

### For Humans
- **`README.md`** - This file (project overview)
- **`CLAUDE.md`** - Quick start and key patterns
- **`tests/README.md`** - CocotB testing guide
- **`modules/README.md`** - Module system documentation

### Archived Documentation
- **`archive/ai-workflow-legacy-2025-10-22/`** - Legacy AI workflow
- **`archive/ghdl_testbench_docs_*/`** - Old GHDL testbench patterns

## 🚧 Active Development

**Current modules:**
- ✅ `modules/volo_common/` - Shared utilities (stable)
- ✅ `modules/SimpleWaveGen/` - Reference implementation (deployed)
- 🔧 `modules/EMFI-Seq/` - EMFI sequencer (in development)

**Testing migration:**
- ✅ CocotB framework established (`tests/`)
- ✅ Example tests passing (`test_clk_divider_core.py`)
- 🔧 Migrating remaining GHDL testbenches to CocotB

## 📜 Changelog

### 2025-10-22 - Serena-First Architecture
- Migrated all knowledge to Serena MCP memories
- Archived legacy `ai-workflow/` directory
- Removed obsolete modules and documentation
- Added `Moku_Pct_pkg.vhd` with CocotB tests
- Standardized on CocotB testing framework

### 2025-01-27 - SimpleWaveGen Deployment
- Successfully deployed SimpleWaveGen to Moku hardware
- Platform interface package pattern established
- Direct instantiation pattern enforced
- GHDL testbench patterns documented

### 2025-01-27 - Foundation
- Initial VHDL-2008 project structure
- Tiered rule system for Verilog portability
- Standardized module architecture
- Moku voltage conversion utilities

## 🤝 Contributing

**Before starting work:**
1. Check Serena memories for existing patterns
2. Read `CLAUDE.md` and `AGENTS.md`
3. Follow standardized module structure
4. Use CocotB for all new tests
5. Use direct instantiation in top layer
6. Update Serena memories with new learnings

## 📄 License

This project is part of Johnny's evolving VHDL development workflow for Moku FPGA devices.

---

**Key Principle**: All valuable knowledge lives in Serena memories (`.serena/memories/`). When in doubt, check there first!

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
├── instruments/         # Top-level instruments (MCC-deployable with Top.vhd)
│   ├── EMFI-Seq/       # EMFI sequencer instrument
│   ├── PulseStar/      # Pulse generator instrument
│   └── SimpleWaveGen/  # Waveform generator instrument
├── experimental/        # Experimental instruments (pre-production)
│   ├── buffer_waveform_gen/
│   ├── inspectable_buffer_loader/
│   └── bram_test_minimal/
├── modules/             # VHDL module library
│   ├── shared/         # Shared utilities (FLAT structure)
│   │   ├── core/       # Digital primitives (13 modules: clk_divider, uart, synchronizer, etc.)
│   │   ├── packages/   # Type definitions and utilities (5 packages: voltage_pkg, uart_pkg, etc.)
│   │   └── observer/   # Debug/monitoring utilities (fsm_observer)
│   ├── oddball/        # Special-case modules (don't fit standard patterns)
│   │   └── volo_pinata_tx/  # MCC-integrated utility (has top/ layer)
│   ├── examples/       # Educational examples
│   │   └── fsm_example/
│   ├── untested/       # Modules without CocotB tests (5 modules)
│   ├── Makefile        # Central build system
│   └── Makefile.shared # Shared Makefile rules
├── tests/               # CocotB testing framework (Python-based)
│   ├── Makefile        # CocotB test build system
│   ├── conftest.py     # Shared test utilities and primitives
│   └── test_*.py       # Individual test modules
├── docs/                # Centralized documentation
│   └── packages/       # Package documentation (Voltage LUTs, Pct package, etc.)
├── scripts/             # Python build and deployment scripts
│   ├── build_mcc_package.py
│   └── import_mcc_build.py
├── mcc_templates/       # MCC (Moku Custom Core) templates
├── templates/           # Reusable VHDL templates
├── static/              # Static assets (bitstream archives, etc.)
└── archive/             # Archived legacy documentation
    ├── ai-workflow-legacy-2025-10-22/  # Legacy AI workflow (archived)
    └── ghdl_testbenches/               # Legacy GHDL tests (deprecated)
```

## Architectural Principles

### **Hierarchy Based on Complexity**
- **Top-level instruments** (`instruments/`, `experimental/`) - Have `top/Top.vhd` for MCC CustomWrapper integration
- **Flat utilities** (`modules/shared/core/`, `packages/`) - Simple single-file modules, no MCC integration
- **Oddball** (`modules/oddball/`) - Special cases that don't fit standard patterns

### **Old tb/ Directories Removed**
All GHDL testbenches (deprecated) have been deleted. CocotB is now the standard testing framework.

## Instrument Directory Structure (Standard Pattern)
Instruments at top-level follow this mandatory structure:

```
instruments/<instrument_name>/
├── common/              # Shared utilities and packages (Tier 1: strict RTL)
├── datadef/             # Data structures, LUTs, records (Tier 2: relaxed rules)
├── core/                # Pure algorithmic logic (Tier 1: strict RTL)
├── top/                 # MCC Platform integration (Tier 1: strict RTL)
│   ├── <Instrument>.vhd         # Main module entity + architecture
│   └── Top.vhd                  # CustomWrapper architecture only
├── Makefile             # Module-specific build rules (optional)
├── mcc_package.yaml     # MCC CloudCompile configuration
├── instrument.yaml      # Instrument metadata
└── README.md            # Instrument documentation
```

## Shared Modules Structure (Flat Pattern)
Utilities in `modules/shared/` use a flat structure for simplicity:

```
modules/shared/
├── core/                # Digital primitives
│   ├── volo_clk_divider.vhd
│   ├── volo_synchronizer.vhd
│   ├── volo_edge_detector.vhd
│   ├── volo_delay_line.vhd
│   ├── volo_comparator.vhd
│   ├── volo_mux.vhd
│   ├── volo_counter_nbit.vhd
│   ├── volo_pwm.vhd
│   ├── volo_debouncer.vhd
│   ├── volo_uart_tx_core.vhd
│   ├── volo_uart_baud_gen.vhd
│   ├── volo_simpleserial_v1_tx.vhd
│   ├── volo_simpleserial_v2_tx.vhd
│   ├── volo_barrel_shifter_core.vhd
│   ├── volo_basic_trigger_box_core.vhd
│   ├── volo_encoder_core.vhd
│   ├── volo_parity_checker_core.vhd
│   ├── volo_sipo_core.vhd
│   └── volo_voltage_threshold_trigger_core.vhd
├── packages/            # Type definitions and utilities
│   ├── volo_voltage_pkg.vhd    # Voltage conversion (Tier 1 - Critical)
│   ├── volo_uart_pkg.vhd
│   ├── volo_cobs_pkg.vhd       # COBS encoding for SimpleSerial
│   ├── Moku_Pct_pkg.vhd        # Percentage/fraction utilities
│   └── mcc_loader_pkg.vhd
└── observer/            # Debug/monitoring utilities
    └── fsm_observer.vhd         # Standardized FSM monitoring pattern
```

**Key Point**: Files live directly in subdirectories (no nested `module/core/` hierarchy for single files).

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
- Two file pattern:
  - `<Instrument>.vhd`: Entity + architecture (instantiates cores)
  - `Top.vhd`: CustomWrapper architecture only (MCC integration)
- **REQUIRED**: Direct instantiation pattern for all module connections
- MCC provides CustomWrapper entity - do NOT create entity files

### Testing - CocotB (Standard)
- **Location**: `tests/` directory (project root level)
- **Framework**: Python-based with async/await syntax
- **Test files**: `test_<module_name>.py`
- **Shared utilities**: `conftest.py` (setup_clock, reset helpers, MCC primitives)
- **Examples**: `test_clk_divider_core.py`, `test_moku_pct_pkg.py`

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

## Module Tiers (from SHARED_MODULES_AUDIT.md)

### Tier 1: Critical Infrastructure (Mandatory)
- `volo_clk_divider.vhd` - Clock division for all instruments
- `volo_voltage_pkg.vhd` - Type-safe voltage conversion

### Tier 2: General-Purpose Digital Primitives (Recommended)
- Synchronization: synchronizer, edge_detector, delay_line
- Logic primitives: comparator, mux
- Counters/generators: counter_nbit, pwm, debouncer

### Tier 3: Communication Protocols (ChipWhisperer/EMFI)
- UART: uart_tx_core, uart_baud_gen, uart_pkg
- SimpleSerial: simpleserial_v1_tx, simpleserial_v2_tx, cobs_pkg

## Archived Legacy Documentation
- **`archive/ai-workflow-legacy-2025-10-22/`** - Legacy AI workflow documentation (no longer maintained)
  - Status: Archived 2025-10-22, replaced by Serena-first architecture
  - See `archive/ai-workflow-legacy-2025-10-22/README-ARCHIVAL.md` for details

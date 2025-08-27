# Modules Directory Structure

This directory contains all VHDL modules following the standardized project structure.

## Standard Module Structure

Each module must follow this directory structure:

```
modules/
├── module_name/
│   ├── common/     # Shared packages and utilities
│   ├── datadef/    # Data structure definitions and type packages
│   ├── core/       # Main algorithmic/logic implementation
│   ├── top/        # Top-level integration (optional)
│   └── tb/         # Testbenches organized by layer
│       ├── common/     # Tests for common layer packages
│       ├── datadef/    # Tests for datadef packages
│       ├── core/       # Tests for core layer entities
│       └── top/        # Tests for top layer integration
```

## Layer Responsibilities

### Common Layer (`common/`)
- **Purpose**: Define shared types, constants, and utilities used across the module
- **Responsibilities**:
  - Configuration parameter validation functions
  - Utility functions shared across testbenches and modules
  - Common type definitions and constants

### Datadef Layer (`datadef/`)
- **Purpose**: Define data structures and types with Verilog portability
- **Responsibilities**:
  - Data structure definitions using flat signals
  - Bit field constants and packing utilities
  - Type validation functions
  - Constants for data widths and default values
- **Constraints**:
  - Must avoid record types in favor of flat signals
  - All definitions must be Verilog-portable
  - Use explicit bit positioning for packed representations

### Core Layer (`core/`)
- **Purpose**: Pure logic implementation
- **Constraints**:
  - No register decode logic
  - No platform-specific code
  - Consume typed-by-name flat signals
  - Implement FSMs with `std_logic_vector` state encoding
  - Use constants for state labels (no enums)
  - **Create a default status register**
  - Ideally implement as a state machine

### Top Layer (`top/`)
- **Purpose**: Integrate multiple modules and handle system-level concerns
- **Responsibilities**:
  - **External interface** - Connect to platform control system (generally a Moku CustomWrapper)
  - **Register exposure** - Expose appropriate control, configuration, and status registers
  - **Important**: DO NOT include MCC CustomWrapper entity body
  - Keep top-level modules clean and focused
  - **Note**: Not all modules will require a 'top' file

### Testbench Layer (`tb/`)
- **Purpose**: Comprehensive verification of all module layers
- **Organization**: Testbenches are organized by the layer they test
- **Structure**:
  - **`tb/common/`**: Test packages and utilities from `common/` layer
  - **`tb/datadef/`**: Test datadef packages (for data definition packages)
  - **`tb/core/`**: Test entities and modules from `core/` layer
  - **`tb/top/`**: Test top-level integration from `top/` layer
- **Standards**:
  - GHDL compatible with VHDL-2008
  - Deterministic test patterns
  - Comprehensive coverage including edge cases
  - Standard output messages for automation
- **Documentation**: Each `tb/` directory must include README.md with compilation instructions

## File Naming Conventions

- **`common/`** - Contains shared packages and utilities
- **`datadef/`** - Contains data structure definitions and type packages
- **`core/`** - Contains the main algorithmic/logic implementation
- **`top/`** - Contains top-level integration (only for top-level modules)
- **`tb/`** - Contains testbenches with `<original_name>_tb.vhd` naming

## Example Module Structure

```
modules/
├── adc_controller/
│   ├── common/
│   │   ├── adc_pkg.vhd
│   │   └── adc_validation.vhd
│   ├── core/
│   │   ├── adc_core.vhd
│   │   └── adc_fsm.vhd
│   ├── top/
│   │   └── adc_top.vhd
│   └── tb/
│       ├── README.md
│       ├── common/
│       │   ├── adc_pkg_tb.vhd
│       │   └── adc_validation_tb.vhd
│       ├── core/
│       │   ├── adc_core_tb.vhd
│       │   └── adc_fsm_tb.vhd
│       └── top/
│           └── adc_top_tb.vhd
├── probe_driver/
│   ├── common/
│   │   └── probe_common_pkg.vhd
│   ├── datadef/
│   │   └── PercentLut_pkg.vhd
│   └── tb/
│       ├── README.md
│       ├── common/
│       │   └── probe_common_pkg_tb.vhd
│       └── datadef/
│           └── PercentLut_pkg_tb.vhd
└── system_integrator/
    ├── common/
    │   └── system_pkg.vhd
    ├── top/
    │   └── system_top.vhd
    └── tb/
        ├── README.md
        ├── common/
        │   └── system_pkg_tb.vhd
        └── top/
            └── system_top_tb.vhd
```

## Important Notes

- Not all modules require a `top/` layer
- All modules should have a `tb/` layer for verification
- The `common/` layer should contain reusable utilities
- The `core/` layer should be pure logic without platform dependencies
- The `tb/` layer must include comprehensive testbenches and README.md
- Follow VHDL-2008 with Verilog portability guidelines
- Use proper signal prefixes: `ctrl_*`, `cfg_*`, `stat_*`
- Testbenches must be GHDL compatible and use deterministic patterns

## Compilation and Testing

For compilation instructions and testing procedures, see:
- Individual `tb/README.md` files for module-specific instructions
- `AGENTS.md` for comprehensive GHDL compilation guidelines
- Project root `.gitignore` includes GHDL artifact exclusions

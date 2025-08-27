# Modules Directory Structure

This directory contains all VHDL modules following the standardized project structure.

## Standard Module Structure

Each module must follow this directory structure:

```
modules/
├── module_name/
│   ├── common/     # Shared packages and utilities
│   ├── core/       # Main algorithmic/logic implementation
│   └── top/        # Top-level integration (optional)
```

## Layer Responsibilities

### Common Layer (`common/`)
- **Purpose**: Define shared types, constants, and utilities used across the module
- **Responsibilities**:
  - Configuration parameter validation functions
  - Utility functions shared across testbenches and modules
  - Common type definitions and constants

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

## File Naming Conventions

- **`common/`** - Contains shared packages and utilities
- **`core/`** - Contains the main algorithmic/logic implementation
- **`top/`** - Contains top-level integration (only for top-level modules)

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
│   └── top/
│       └── adc_top.vhd
├── dac_controller/
│   ├── common/
│   │   └── dac_pkg.vhd
│   └── core/
│       └── dac_core.vhd
└── system_integrator/
    ├── common/
    │   └── system_pkg.vhd
    └── top/
        └── system_top.vhd
```

## Important Notes

- Not all modules require a `top/` layer
- The `common/` layer should contain reusable utilities
- The `core/` layer should be pure logic without platform dependencies
- Follow VHDL-2008 with Verilog portability guidelines
- Use proper signal prefixes: `ctrl_*`, `cfg_*`, `stat_*`

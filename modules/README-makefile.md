# Hierarchical Makefile System

This directory contains a hierarchical makefile system that allows building VHDL modules from any directory level while avoiding code duplication.

## Architecture

### Central Makefile (`modules/Makefile`)
- Contains all compilation logic and GHDL settings
- Automatically detects current directory level
- Supports two build modes:
  - `all_modules`: When run from `modules/` directory - builds all modules
  - `single_module`: When run from a specific module directory - builds that module only

### Module Makefiles (`modules/*/Makefile`)
- Include the central makefile logic
- Can override or add module-specific targets
- Example: `modules/probe_driver/Makefile` includes central logic and adds specific test targets

### Testbench Makefiles (`modules/*/tb/Makefile`)
- Delegate all targets to the parent module makefile
- Allow building from testbench directories

## Usage Examples

### Build from modules directory (builds all modules)
```bash
cd modules/
make clean
make compile
make test
```

### Build from specific module directory
```bash
cd modules/probe_driver/
make clean
make compile
make test
```

### Build from testbench directory (delegates to parent module)
```bash
cd modules/probe_driver/tb/
make clean
make compile
make test
```

## Available Targets

### Standard Targets (available everywhere)
- `make` or `make compile` - Compile modules and testbenches
- `make test` - Run all available testbenches
- `make clean` - Remove compilation artifacts
- `make help` - Show help information

### Module-Specific Targets (when available)
- `make compile-basic` - Compile basic components only
- `make test-<testbench_name>` - Run specific testbench
- `make quick-test` - Compile and run main testbench only
- `make list-tests` - Show available testbenches

## Key Features

1. **No Code Duplication**: All compilation logic is centralized in `modules/Makefile`
2. **Hierarchical Building**: Can build from any directory level
3. **Automatic Detection**: Automatically detects current directory and adjusts behavior
4. **Module Isolation**: Each module can have its own specific targets
5. **Delegation**: Testbench directories delegate to parent modules

## Directory Structure

```
modules/
├── Makefile                    # Central makefile with all logic
├── probe_driver/
│   ├── Makefile               # Includes central logic + module-specific targets
│   └── tb/
│       └── Makefile           # Delegates to parent module
├── clk_divider/
│   └── Makefile               # Includes central logic
└── README-makefile.md         # This documentation
```

## GHDL Compilation Artifacts

The makefile automatically cleans these artifacts:
- `work-obj*.cf` - GHDL work library files
- `*_tb` - Elaborated testbench executables
- `*.o` - Object files
- `*.exe` - Windows executables
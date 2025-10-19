# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Essential Resources (Source of Truth)
- **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
- **`ai-workflow/ng/README-ghdl-testbench-tips-ng.md`** - GHDL testbench patterns  
- **`ai-workflow/ng/README-layered-testbench-ng.md`** - 4-layer testbench architecture

## Build/Test Commands
- **Compile module**: `cd modules/<module_name> && make`
- **Run all tests**: `cd modules/<module_name> && make test`
- **Run single test**: `cd modules/<module_name> && make test-<testbench_name>`
  - Example: `make test-probe_driver_interface`
- **GHDL flags**: Always use `--std=08` for VHDL-2008 compatibility

## Core Rules
- **VHDL-2008 with Verilog portability** - Avoid VHDL-only features
- **Direct instantiation** - Required for `top/` layer files
- **Layered testbenches** - Interface → Validation → Functional → Generic
- **Signal prefixes**: `ctrl_*`, `cfg_*`, `stat_*`
- **Control priority**: `reset > clock_enable > enable` (STD-02)

## Module Structure
```
modules/module_name/
├── common/     # Shared utilities
├── datadef/    # Data structures (records allowed)
├── core/       # Pure logic (no platform code)
├── top/        # Integration (direct instantiation required)
└── tb/         # Testbenches by layer
    ├── common/     # Package tests
    ├── datadef/    # Datadef tests  
    ├── core/       # Core tests
    └── top/        # Integration tests
```

## Testbench Requirements
- **Location**: Match tested layer (`tb/core/`, `tb/top/`, etc.)
- **Naming**: `<name>_tb.vhd` with entity `<name>_tb`
- **Output**: Print `'ALL TESTS PASSED'` or `'TEST FAILED'` + `'SIMULATION DONE'`
- **Architecture**: Use 4-layer approach (see referenced file)
- **Termination**: Use `std.env.stop(0)` or `assert false report "Simulation completed" severity failure`

## New Tips Protocol
- **Append only** below `------- New Tips here-------` in referenced files
- **Use schema**: Problem/Cause/Solution/Pattern/Tags
- **Don't modify** main bodies of referenced files

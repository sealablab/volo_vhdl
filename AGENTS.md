# Volo VHDL Project - Agent Guidelines

## Essential Resources (Source of Truth)
- **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
- **`ai-workflow/ng/README-ghdl-testbench-tips-ng.md`** - GHDL testbench patterns  
- **`ai-workflow/ng/README-layered-testbench-ng.md`** - 4-layer testbench architecture

## Quick Start Checklist
1. **Read the referenced files** - They contain all the detailed guidance
2. **Follow the patterns** - Use the Pattern snippets as canonical forms
3. **Use layered testbenches** - 4-layer architecture is mandatory
4. **Control priority**: `reset > clock_enable > enable` (STD-02)
5. **Direct instantiation** - Required for top layer files

## Core Rules (Summary)
- **VHDL-2008 with Verilog portability** - Avoid VHDL-only features
- **Direct instantiation** - Required for `top/` layer files
- **Layered testbenches** - Interface → Validation → Functional → Generic
- **Signal prefixes**: `ctrl_*`, `cfg_*`, `stat_*`
- **GHDL**: Always use `--std=08`

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

## New Tips Protocol
- **Append only** below `------- New Tips here-------` in referenced files
- **Use schema**: Problem/Cause/Solution/Pattern/Tags
- **Don't modify** main bodies of referenced files

## Questions for Clarification
When working on this project, consider asking:
1. What are the target frequency and timing requirements?
2. What are the interface requirements with other modules?
3. What are the reset requirements (synchronous vs asynchronous)?
4. Are there specific area or resource constraints?

---
**For detailed guidance, see the referenced files above. This document is intentionally short to avoid duplication.**

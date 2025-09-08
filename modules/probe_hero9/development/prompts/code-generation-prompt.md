# Code Generation Prompt Template

## Context
Generate VHDL code for ProbeHero9 based on the requirements.

## Requirements Reference
- Interface: `../requirements/interface/PH9-interface-reqs-current.md`
- Functional: `../requirements/functional/PH9-functional-reqs.md`
- Constraints: `../requirements/constraints/PH9-timing-constraints.md`

## VOLO Standards
- VHDL-2008 with Verilog portability
- Direct instantiation for top layer files
- Layered testbench architecture (4-layer)
- Signal prefixes: `ctrl_*`, `cfg_*`, `stat_*`
- GHDL compatibility with `--std=08`

## Module Structure
```
modules/probe_hero9/
├── common/     # Shared utilities
├── datadef/    # Data structures (records allowed)
├── core/       # Pure logic (no platform code)
├── top/        # Integration (direct instantiation required)
└── tb/         # Testbenches by layer
```

## Code Generation Focus
- [ ] Entity definitions
- [ ] Architecture implementations
- [ ] Package definitions
- [ ] Testbench generation

## Output Location
Generate code in appropriate subdirectories:
- Core logic: `../core/`
- Top integration: `../top/`
- Data definitions: `../datadef/`
- Testbenches: `../tb/`

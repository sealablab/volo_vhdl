# Project Coding Rules (Non-Obvious Only)

## VHDL-2008 Specific Requirements
- Always use `--std=08` flag with GHDL for all operations
- Use direct instantiation in top-level modules (no component declarations)
- Follow signal priority hierarchy: `reset > clock_enable > enable`

## Module Development Guidelines
- Use signal prefixes consistently: `ctrl_*` (control), `cfg_*` (configuration), `stat_*` (status)
- Avoid unintended latches by ensuring all branches assign outputs
- Follow single-writer rule for signals (one process assigns a signal)
- Use named port maps and explicit type conversions

## Testbench Development
- Implement all 4 layers in testbenches (Interface, Validation, Functional, Generic)
- Test WHAT the module does, not HOW it does it (no implementation assumptions)
- Use `std.env.stop(0)` or `assert false report "Simulation completed" severity failure` for termination
- Print `'ALL TESTS PASSED'` or `'TEST FAILED'` + `'SIMULATION DONE'` for automation
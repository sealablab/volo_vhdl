# Project Architecture Rules (Non-Obvious Only)

## Module Architecture Requirements
- Strict layering: common → datadef → core → top
- Direct instantiation required in top/ layer files (no component declarations)
- Signal priority hierarchy: `reset > clock_enable > enable`
- Verilog portability required (avoid VHDL-only features)

## Testbench Architecture
- 4-layer testbench architecture is mandatory:
  1. Interface Testing (Status Register)
  2. Validation Testing (Error Handling)
  3. Functional Testing (Core Behavior)
  4. Generic Parameter Testing (Edge Cases)
- Test WHAT the module does, not HOW it does it

## Design Constraints
- BRAM inference requires specific coding patterns
- Pipeline registers needed for complex calculations
- Status reporting must be comprehensive in top-level modules
- Avoid unintended latches by ensuring all branches assign outputs
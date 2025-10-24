# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Essential Resources (Source of Truth)
- **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
- **`tests/README.md`** - CocotB testing framework (NEW - preferred for new tests)
- **`tests/conftest.py`** - Shared CocotB utilities and fixtures

## Build/Test Commands

### CocotB Tests (Preferred - New Standard)
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module tests
make list-tests                        # List available test modules
make clean                             # Clean test artifacts
make waves                             # View waveforms (if GTKWave installed)
```

### Legacy GHDL Tests (Deprecated - Being Phased Out)
⚠️ **DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead
- Legacy tests exist in some modules but are being migrated to CocotB
- See `archive/` for archived GHDL testbench documentation

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

## Testing Requirements

### CocotB Tests (Preferred)
- **Location**: `tests/test_<module_name>.py`
- **Framework**: Use CocotB with shared utilities from `conftest.py`
- **Utilities**: `setup_clock()`, `reset_active_low()`, `count_pulses()`, etc.
- **Structure**: One test per `@cocotb.test()` decorated async function
- **Assertions**: Use Python `assert` statements with clear messages

### Legacy GHDL Tests (Deprecated)
⚠️ **DO NOT CREATE** - These are being phased out in favor of CocotB

## Hardware Debugging Workflow (Oscilloscope-Based)

**Quick Start**: `/debug-hardware` (slash command for guided debugging)

**Full Documentation**: `docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md`
**AI Context**: Serena memory `oscilloscope_debugging_techniques`

### Workflow Steps

```
1. Design      → Add debug multiplexers (8 views per channel)
2. Simulate    → CocotB oscilloscope-only tests (baseline)
3. Synthesize  → CloudCompile (use incoming/ folder)
4. Hardware    → MokuBench tests (mirrors CocotB)
5. Debug       → Incremental fixes with git commits
6. Document    → Update Serena memories
```

### Critical Checks (Most Common Failures)

1. **Voltage Scaling**: Moku uses ±5V (NOT ±1V) → 5× error!
2. **Oscilloscope Polling**: Single sample may be cached → poll 10× with 0.1s
3. **Sticky Flags**: Use Valid flag (Fault only clears on hardware reset)
4. **State Paths**: Map transitions first (may have no software reset)

### Git Commit Pattern

**User Request**: Use same messages to user AND git (don't duplicate)

```bash
# Print diagnostic:
print("  ⚠ Issue: Oscilloscope cached data")
print("  ✓ Solution: Poll multiple times")

# Commit with SAME message:
git commit -m "Test 2 debug: Poll oscilloscope for transitions

- ⚠ Issue: Oscilloscope cached data
- ✓ Solution: Poll multiple times"
```

**Benefit**: Git history = learning trail for debugging journey

### Reference Implementation

**Module**: `inspectable_buffer_loader` (2025-10-24)
- 6/6 CocotB tests PASSED
- 4/5 hardware tests PASSED, 1 SKIPPED (documented)
- 5 incremental commits showing debugging discoveries

## New Tips Protocol
- **Append only** below `------- New Tips here-------` in referenced files
- **Use schema**: Problem/Cause/Solution/Pattern/Tags
- **Don't modify** main bodies of referenced files

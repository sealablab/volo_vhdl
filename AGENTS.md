# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Core Abstractions (Load First!)

### MokuConfig - Deployment Specification Model
**THE** central Python abstraction for this project.

📍 `models/moku/platform_config.py` → `MokuConfig`
🎯 Single source of truth: Slots + Routing + Platform + Metadata
🔄 Dual backend: CocotB simulation AND hardware deployment

**Quick Commands:**
```bash
# Deploy from config file
uv run python tools/moku_go.py deploy --device MokuB106 --config deploy.json

# Deploy from CLI (auto-generates MokuConfig internally)
uv run python tools/moku_go.py deploy --device MokuB106 --bitstream *.tar --slot 2

# Generate reusable config
python -c "
from models.moku import MokuConfig, SlotConfig, MOKU_GO_PLATFORM
config = MokuConfig(platform=MOKU_GO_PLATFORM, slots={...}, routing=[...])
print(config.model_dump_json(indent=2))
" > configs/my_deployment.json
```

📚 **Serena Memory**: `mokuconfig_core_abstraction` (load first!)

---

## Essential Resources (Source of Truth)
- **`Serena: mokuconfig_core_abstraction`** ⭐ - Core deployment model (START HERE!)
- **`models/moku/platform_config.py`** - MokuConfig implementation
- **`tests/README.md`** - CocotB testing framework (NEW - preferred for new tests)
- **`tests/conftest.py`** - Shared CocotB utilities and fixtures
- **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns

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

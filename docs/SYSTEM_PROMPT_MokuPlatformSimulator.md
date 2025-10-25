# System Prompt: Moku Platform Simulator Migration

**Use this prompt when starting a fresh context window to execute the migration.**

---

## Context

You are helping refactor `tests/bench_framework/` → `tests/moku_platform_simulator/` to use validated Pydantic models and clarify its purpose.

**Branch**: `feature/BenchConfigRewrite` (already created)
**Tagged commit**: `v0.2-validated-models` (validated models already exist)

---

## What Already Exists (Don't Recreate!)

✅ **Complete validated models in `models/`**:
- `models/moku/platforms/moku_go.py` - MokuGoPlatform (physical Moku specs)
- `models/moku/routing.py` - MokuConnection (moku library compatible)
- `models/riscure/ds1120a.py` - DS1120A probe (Input/Output/Power)
- `models/bench/benchbench.py` - BenchBench (physical lab bench)
- `models/bench/wiring.py` - WiredDevice, PhysicalWiring (validated!)
- `models/bench/pdu.py`, `models/bench/dut.py` - PDU, DUT
- `models/device_catalog.py` - Device registry
- `models/dummy/probe.py` - DummyProbe escape hatch

**All above are committed and tagged. Do NOT recreate them.**

✅ **Existing code in `tests/bench_framework/`**:
- `backend.py` - Abstract base class (KEEP, update)
- `hardware.py` - MCC hardware backend (KEEP, update)
- `simulation.py` - CocotB simulation backend (KEEP, update)
- `visualization.py` - Diagram generation (KEEP, update)
- `simulators/oscilloscope.py` - Behavioral model (KEEP, no changes)
- `config.py` - Old BenchConfig (ARCHIVE)

---

## Your Task

Follow the migration plan in `docs/MIGRATION_PLAN_MokuPlatformSimulator.md` to:

1. Create `models/moku/platform_config.py` with `MokuPlatformConfig` class
2. Rename `tests/bench_framework/` → `tests/moku_platform_simulator/`
3. Update backend classes to use new models
4. Archive old `config.py`
5. Create example tests
6. Update documentation

**Key principle**: The existing backend architecture is excellent - just update it to use the new validated models!

---

## Critical Understanding

**`bench_framework/` is actually a Moku platform simulator**:
- Purpose: "Train like you fight" - test VHDL modules as if deployed to Moku
- Same configuration works for BOTH simulation (CocotB) and hardware (real Moku)
- Enables testing multi-module interactions before hardware deployment

**Not a test config system** - it's a Moku platform deployment simulator!

---

## Key Files to Reference

1. **Migration Plan**: `docs/MIGRATION_PLAN_MokuPlatformSimulator.md` (step-by-step instructions)
2. **Analysis**: `docs/BENCH_FRAMEWORK_ANALYSIS.md` (context and decisions)
3. **Existing Models**: Browse `models/` directory to understand what's available
4. **Existing Backend**: Read `tests/bench_framework/backend.py` to understand current architecture

---

## Key Changes

### Old Pattern (being replaced):
```python
from tests.bench_framework import BenchConfig

config = BenchConfig(
    platform=MOKU_GO,  # Dict
    slots={...},
    connections=[...],  # Old Connection class
    external_hardware=[...]  # Mixed physical + runtime
)

backend = HardwareBackend(config, ip='192.168.73.1')
```

### New Pattern (what we're building):
```python
from models.moku.platform_config import MokuPlatformConfig
from models.bench.benchbench import BenchBench

# Platform deployment config
config = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,  # Validated model
    slots={...},
    routing=[...]  # MokuConnection (validated)
)

# Physical bench (has IP, wiring, etc.)
bench = BenchBench(
    bench_id='B106',
    moku=MokuGoPlatform(ip_address='192.168.73.1'),
    physical_wiring=PhysicalWiring({...})  # Validated!
)

# Hardware backend accepts BOTH
hw_backend = HardwareBackend(config, bench)

# Simulation backend only needs config
sim_backend = SimulationBackend(config, dut=dut)
```

---

## What NOT to Do

❌ Don't recreate models that already exist in `models/`
❌ Don't rewrite the backend architecture from scratch
❌ Don't change the simulator behavioral models
❌ Don't add features not in the migration plan
❌ Don't skip validation after each phase

✅ DO follow the migration plan step-by-step
✅ DO test after each phase
✅ DO commit atomically (one phase = one commit)
✅ DO ask if anything is unclear

---

## Validation Commands

After each phase, run:

```bash
# Check imports work
uv run python -c "from tests.moku_platform_simulator import MokuPlatformConfig; print('✓')"

# Check models import
uv run python -c "from models.moku.platform_config import MokuPlatformConfig; print('✓')"

# Run existing tests
cd tests/
uv run make TEST_MODULE=clk_divider_core
```

---

## Expected Git History

After completion, should see commits like:

```
feat: Create MokuPlatformConfig model
refactor: Rename bench_framework to moku_platform_simulator
refactor: Update backends to use MokuPlatformConfig
refactor: Update visualization for new models
docs: Update moku_platform_simulator documentation
test: Add example moku platform simulator test
chore: Archive old BenchConfig
```

---

## Questions to Ask If Stuck

1. "Does this already exist in `models/`?" (Check before creating!)
2. "Am I following the migration plan phases in order?"
3. "Have I tested this phase before moving on?"
4. "Is there a simpler way that achieves the same goal?"

---

## Success Criteria

When done, you should be able to:

✅ Import `MokuPlatformConfig` from `models.moku.platform_config`
✅ Create a config that works for BOTH simulation and hardware
✅ Run existing tests without errors
✅ Show wiring validation preventing Output→Output errors
✅ Generate diagrams from the new config
✅ Reference physical bench (BenchBench) for hardware deployment

---

## Starting Command

```bash
# Verify you're on the right branch
git branch --show-current  # Should show: feature/BenchConfigRewrite

# Verify tagged commit exists
git tag -l | grep validated-models  # Should show: v0.2-validated-models

# Check existing models
ls -la models/moku/
ls -la models/bench/

# Start Phase 1 of migration plan
# (Open docs/MIGRATION_PLAN_MokuPlatformSimulator.md and begin!)
```

---

## Final Note

**This is a refactor, not a rewrite!** The existing code is good - we're just:
1. Renaming to clarify purpose
2. Using validated models instead of dicts/strings
3. Separating physical bench (BenchBench) from platform config (MokuPlatformConfig)

Follow the plan, test frequently, and you'll be done in 2-3 hours. Good luck! 🚀

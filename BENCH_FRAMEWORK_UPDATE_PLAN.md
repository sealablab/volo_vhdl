# Bench Framework Documentation Update Plan

**Date**: 2025-10-25
**Branch**: `docs_and_memory_update`
**Goal**: Sync all documentation with new Pydantic-based models

---

## Executive Summary

**What Changed**:
- Old `BenchConfig` monolith → Split into `BenchBench` (physical) + `MokuPlatformConfig` (deployment)
- Directory renamed: `tests/bench_framework/` → `tests/moku_platform_simulator/`
- New validated Pydantic models in `models/` directory
- Old config archived: `archive/bench_config_old.py`

**What Needs Updating**:
- ✅ Code migration: COMPLETE (models created, directory renamed, imports updated)
- ❌ Documentation: OUT OF SYNC (31 files with old references)
- ❌ Serena memories: OUT OF SYNC (primary source of truth needs updating)

---

## Audit Results

### Files with Old References (31 total)

#### 🔴 CRITICAL - Primary Documentation (Update First)

1. **`.serena/memories/bench_config_framework.md`** ⚠️ **HIGHEST PRIORITY**
   - **Issue**: Still describes old `BenchConfig` class, old directory structure
   - **Impact**: This is the source of truth - affects all agent interactions
   - **Action**: Complete rewrite to reflect new architecture

2. **`CLAUDE.md`** (lines 71, 238)
   - **Issue**: References `bench_config_framework` memory and old patterns
   - **Impact**: Project overview for all agents
   - **Action**: Update references to new model structure

3. **`docs/BENCH_FRAMEWORK_DESIGN.md`**
   - **Issue**: Original design doc (pre-refactor)
   - **Impact**: Reference documentation
   - **Action**: Add migration note + update examples

#### 🟡 MODERATE - Test Files (Update for Consistency)

4. **`tests/test_bench_framework_poc.py`**
   - **Issue**: Still imports from old `bench_framework` (deprecated)
   - **Impact**: Test still works but uses old patterns
   - **Action**: Update to `moku_platform_simulator` imports

#### 🟢 LOW PRIORITY - Analysis/Migration Docs (Archive or Note)

5. **`docs/BENCH_FRAMEWORK_ANALYSIS.md`**
   - **Status**: Pre-migration analysis document
   - **Action**: Add header noting "COMPLETED - See models/ for implementation"

6. **`docs/MIGRATION_PLAN_MokuPlatformSimulator.md`**
   - **Status**: Migration plan document
   - **Action**: Add completion status + link to actual implementation

7. **`docs/SYSTEM_PROMPT_MokuPlatformSimulator.md`**
   - **Status**: System prompt for AI migration
   - **Action**: Archive or mark as reference

#### 📦 INSTRUMENT MEMORIES (Bulk Update - Low Priority)

8-27. **Instrument Serena memories** (20 files):
   - `instrument_oscilloscope.md`
   - `instrument_waveform_generator.md`
   - `instrument_laser_lock_box.md`
   - ... (17 more)

   **Issue**: Reference old `bench_framework` in examples
   **Impact**: Examples won't work as-is
   **Action**: Batch update with find/replace script

#### 🔧 HARDWARE-SPECIFIC DOCS

28. **`.serena/memories/riscure_ds1120a.md`**
29. **`.serena/memories/riscure_ds1121a.md`**
   - **Issue**: Reference old `BenchConfig` patterns
   - **Action**: Update to use `BenchBench` + physical wiring examples

30. **`scripts/hardware/README.md`**
31. **`scripts/diagnostics/README.md`**
   - **Issue**: Old framework references
   - **Action**: Update import examples

---

## Recommended Update Strategy

### Phase 1: Core Documentation (30 mins)

**Priority 1A: Update `bench_config_framework.md` Serena memory**

This is the PRIMARY source of truth. Needs complete rewrite.

**New structure**:
```markdown
# Moku Platform Simulator (formerly bench_framework)

## Architecture

**Physical Layer** (`models/bench/`):
- `BenchBench` - Physical lab bench (Moku IP, wiring, PDU, DUT)
- `PhysicalWiring` - Validated device-to-port connections
- `WiredDevice` - Device signal with direction validation

**Platform Layer** (`models/moku/`):
- `MokuPlatformConfig` - Deployment spec (slots, routing, settings)
- `SlotConfig` - Per-slot instrument config
- `MokuConnection` - Signal routing
- `MokuGoPlatform` - Platform specification

**Simulator** (`tests/moku_platform_simulator/`):
- `SimulationBackend` - CocotB behavioral models
- `HardwareBackend` - Real Moku deployment

## Usage Pattern

```python
# 1. Define physical bench (rarely changes)
bench = BenchBench(
    bench_id='B106',
    moku=MokuGoPlatform(ip_address='192.168.73.1'),
    physical_wiring=PhysicalWiring(connections={
        'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch')
    })
)

# 2. Define platform config (per test)
config = MokuPlatformConfig(
    platform=bench.moku,  # Or MOKU_GO_PLATFORM
    slots={
        1: SlotConfig(instrument='CloudCompile', bitstream='...'),
        2: SlotConfig(instrument='Oscilloscope', settings={...})
    },
    routing=[
        MokuConnection(source='Slot1OutA', destination='Slot2InA')
    ]
)

# 3. Run simulation
sim = SimulationBackend(config, dut)
await sim.setup()
data = await sim.run(duration_ms=10)

# 4. Deploy to hardware (same config!)
hw = HardwareBackend(config, bench)
await hw.setup()
hw_data = await hw.run(duration_ms=10)
```

## Key Changes from Old BenchConfig

| Old | New | Reason |
|-----|-----|--------|
| `BenchConfig` (monolith) | `BenchBench` + `MokuPlatformConfig` | Separation of concerns |
| String-based validation | Pydantic models + device catalog | Type safety, direction validation |
| `tests/bench_framework/` | `tests/moku_platform_simulator/` | Clarifies purpose |
| `config.py` | `models/moku/platform_config.py` | Proper model organization |
| `ProbeConnection` | `WiredDevice` in `PhysicalWiring` | Validated against device specs |
```

**Priority 1B: Update `CLAUDE.md`**

Search for:
- `bench_config_framework` → `moku_platform_simulator`
- Update "Serena memories" section to note the new architecture
- Add note about `BenchBench` vs `MokuPlatformConfig` split

### Phase 2: Test Files (15 mins)

**Update `tests/test_bench_framework_poc.py`**:

```bash
# Option A: Rename and update
git mv tests/test_bench_framework_poc.py tests/test_moku_platform_poc.py

# Option B: Just update imports in place
# Change:
from tests.bench_framework import BenchConfig, SlotConfig
# To:
from tests.moku_platform_simulator import MokuPlatformConfig, SlotConfig
```

### Phase 3: Instrument Memories - Bulk Update (20 mins)

**Script approach**:

```bash
# Create update script
cat > scripts/update_memory_imports.sh << 'EOF'
#!/bin/bash

# Update all instrument memory files
for file in .serena/memories/instrument_*.md; do
    echo "Updating $file..."

    # Replace old patterns
    sed -i.bak 's/from tests\.bench_framework/from tests.moku_platform_simulator/g' "$file"
    sed -i.bak 's/BenchConfig(/MokuPlatformConfig(/g' "$file"
    sed -i.bak 's/bench_framework/moku_platform_simulator/g' "$file"

    # Remove backup
    rm "$file.bak"
done

echo "✓ Updated instrument memories"
EOF

chmod +x scripts/update_memory_imports.sh
```

**Then manually verify**:
- Check a few updated files for correctness
- Update examples to use new model structure

### Phase 4: Hardware-Specific Docs (15 mins)

**Update Riscure probe memories**:
- Replace old `BenchConfig` examples with `BenchBench` + physical wiring
- Add examples showing validated wiring

**Update README files**:
- `scripts/hardware/README.md`
- `scripts/diagnostics/README.md`
- Simple find/replace: `bench_framework` → `moku_platform_simulator`

### Phase 5: Archive Old Analysis Docs (5 mins)

**Add completion notes**:

```bash
# Add header to analysis doc
cat > /tmp/header.txt << 'EOF'
# ⚠️ MIGRATION COMPLETE - 2025-10-24

This document was the **pre-migration analysis**. Migration is now complete.

**See**:
- `models/bench/benchbench.py` - Physical bench (BenchBench)
- `models/moku/platform_config.py` - Deployment config (MokuPlatformConfig)
- `tests/moku_platform_simulator/` - Simulator implementation
- `.serena/memories/bench_config_framework.md` - Updated usage guide

---

# Original Analysis (Archived)

EOF

# Prepend to analysis doc
cat /tmp/header.txt docs/BENCH_FRAMEWORK_ANALYSIS.md > /tmp/new.md
mv /tmp/new.md docs/BENCH_FRAMEWORK_ANALYSIS.md

# Similar for migration plan
```

---

## Verification Script

Create a verification script to ensure all updates are complete:

```bash
#!/bin/bash
# scripts/verify_bench_framework_migration.sh

echo "Checking for old bench_framework references..."
echo "=============================================="

# Check for old imports (should only be in archived files)
echo -e "\n1. Checking for old imports..."
IMPORTS=$(grep -r "from.*bench_framework" --include="*.py" tests/ 2>/dev/null | grep -v "test_bench_framework_poc.py" | grep -v ".pyc")
if [ -z "$IMPORTS" ]; then
    echo "   ✓ No old imports found (except legacy test)"
else
    echo "   ✗ Found old imports:"
    echo "$IMPORTS"
fi

# Check Serena memories for old patterns
echo -e "\n2. Checking Serena memories..."
OLD_PATTERNS=$(grep -l "class BenchConfig" .serena/memories/*.md 2>/dev/null)
if [ -z "$OLD_PATTERNS" ]; then
    echo "   ✓ No 'class BenchConfig' references"
else
    echo "   ✗ Found in:"
    echo "$OLD_PATTERNS"
fi

# Check for proper new imports
echo -e "\n3. Checking for new model imports..."
NEW_IMPORTS=$(grep -r "from models\.moku\.platform_config import" --include="*.py" tests/ 2>/dev/null | wc -l)
if [ "$NEW_IMPORTS" -gt 0 ]; then
    echo "   ✓ Found $NEW_IMPORTS files using new imports"
else
    echo "   ⚠ No files using new imports yet"
fi

# Check documentation
echo -e "\n4. Checking key documentation..."
if grep -q "MokuPlatformConfig" .serena/memories/bench_config_framework.md 2>/dev/null; then
    echo "   ✓ bench_config_framework.md updated"
else
    echo "   ✗ bench_config_framework.md NOT updated"
fi

if grep -q "moku_platform_simulator" CLAUDE.md 2>/dev/null; then
    echo "   ✓ CLAUDE.md mentions new directory"
else
    echo "   ⚠ CLAUDE.md may need update"
fi

echo -e "\n=============================================="
echo "Verification complete!"
```

---

## Estimated Time

| Phase | Task | Time |
|-------|------|------|
| 1 | Core documentation (Serena memory + CLAUDE.md) | 30 min |
| 2 | Test file updates | 15 min |
| 3 | Instrument memories bulk update | 20 min |
| 4 | Hardware-specific docs | 15 min |
| 5 | Archive old analysis docs | 5 min |
| **Total** | | **~85 minutes** |

---

## Priority Quick Reference

### DO FIRST (Critical)
1. ✅ Update `.serena/memories/bench_config_framework.md`
2. ✅ Update `CLAUDE.md` references

### DO SOON (Important)
3. Update `tests/test_bench_framework_poc.py`
4. Bulk update instrument memories

### DO EVENTUALLY (Low Impact)
5. Update hardware-specific docs
6. Archive old analysis docs
7. Add migration completion notes

---

## Rollback Plan

If issues discovered:

```bash
# Rollback Serena memory
git checkout HEAD~1 -- .serena/memories/bench_config_framework.md

# Rollback CLAUDE.md
git checkout HEAD~1 -- CLAUDE.md
```

---

## Success Criteria

- [ ] `bench_config_framework.md` describes new architecture
- [ ] `CLAUDE.md` references correct models/directories
- [ ] No active test files import from old `bench_framework`
- [ ] Instrument memories use new import patterns
- [ ] Verification script passes all checks
- [ ] All commits atomic and clear

---

## Notes

- Keep old analysis docs for historical reference
- Archive pattern: Add header noting completion + link to implementation
- Use bulk script for repetitive updates (instrument memories)
- Manually verify critical files (Serena memories, CLAUDE.md)

# Bench Framework Analysis - BenchConfig Rewrite

**Branch**: `feature/BenchConfigRewrite`
**Commit**: Tagged as `v0.2-validated-models`
**Date**: 2025-10-24

---

## Executive Summary

The existing `tests/bench_framework/` has **excellent architectural bones** but mixes physical and runtime concerns. With our new validated Pydantic models, we can refactor into a clean separation:

- **BenchBench** (physical bench setup) ✅ DONE
- **BenchConfig** (runtime test configuration) 🔧 NEEDS REFACTOR
- **Backend abstraction** (sim/hardware) ✅ KEEP WITH UPDATES
- **Visualization** ✅ KEEP (needs updates for new models)
- **Simulators** ✅ KEEP (minimal changes needed)

---

## What to Keep vs. Replace

### ✅ KEEP (Excellent Code - Update to Use New Models)

#### 1. **Backend Architecture** (`backend.py`, `hardware.py`, `simulation.py`)

**Why Keep:**
- Clean abstract base class pattern (`Backend`)
- Excellent separation of concerns (sim vs hardware)
- Async/await properly used
- Hardware backend has full MCC API integration
- Simulation backend integrates with CocotB

**Changes Needed:**
```python
# OLD:
class Backend(ABC):
    def __init__(self, config: BenchConfig):  # OLD BenchConfig
        ...

# NEW:
class Backend(ABC):
    def __init__(self, bench: BenchBench, config: RuntimeConfig):
        self.bench = bench        # Physical setup
        self.config = config      # Runtime test config
```

**Verdict**: **KEEP - Minor refactor to accept BenchBench + new BenchConfig**

---

#### 2. **Visualization** (`visualization.py`)

**Why Keep:**
- ASCII diagram generation is useful for debugging
- Mermaid diagrams are great for documentation
- `generate_summary()` provides quick validation

**Changes Needed:**
- Update to use `BenchBench.summary()` for physical layout
- Update to use new `BenchConfig` for runtime routing
- Merge probe wiring visualization from `BenchBench.physical_wiring`

**Verdict**: **KEEP - Update to use new models**

---

#### 3. **Simulators** (`simulators/oscilloscope.py`)

**Why Keep:**
- Clean behavioral model for CocotB
- Well-tested (counter PoC working)
- Good API design (`get_data()`, `verify_incrementing()`)

**Changes Needed:**
- None! This is independent of config models
- Future: Add more instrument simulators

**Verdict**: **KEEP - No changes needed**

---

### ❌ REPLACE (Superseded by New Models)

#### 1. **MOKU_GO / MOKU_PRO Dicts** (`config.py` lines 14-26)

**Replaced By**: `models/moku/platforms/moku_go.py` (MokuGoPlatform)

**Why Better:**
```python
# OLD: Dict with no validation
MOKU_GO = {
    'name': 'Moku:Go',
    'slots': 2,
    'inputs': ['Input1', 'Input2'],
}

# NEW: Validated model with physical specs
moku = MokuGoPlatform(
    ip_address='192.168.73.1',
    device_name='MokuB106',
    clock_period_ns=8.0,
    analog_inputs=[...],  # Full physical specs
    dio=DIOPort(num_pins=16, ...)
)
```

**Verdict**: **REPLACE - Delete old dicts**

---

#### 2. **Connection Class** (`config.py` lines 53-70)

**Replaced By**: `models/moku/routing.py` (MokuConnection)

**Why Better:**
- Moku library compatible (`.to_dict()` method)
- Better naming alignment with 1st-party API
- More flexible validation

**Verdict**: **REPLACE - Use MokuConnection**

---

#### 3. **ProbeConnection + ExternalHardware** (`config.py` lines 73-182)

**Replaced By**: `models/bench/wiring.py` (WiredDevice, PhysicalWiring)

**Why MUCH Better:**
```python
# OLD: String-based, no validation
ProbeConnection(probe='digital_glitch', moku='OutputA')
# → Just strings, no idea if signal exists or direction matches!

# NEW: Validated against device model!
WiredDevice(device='DS1120A', signal='digital_glitch')
# → Validates:
#    ✓ DS1120A exists in catalog
#    ✓ 'digital_glitch' is an INPUT on DS1120A
#    ✓ When wired to Moku OUT1 (output), direction matches!
```

**Verdict**: **REPLACE - Validation is the killer feature**

---

#### 4. **BenchConfig Monolith** (`config.py` lines 185-394)

**Problem**: Mixed physical + runtime concerns:
```python
BenchConfig(
    platform={...},           # PHYSICAL → belongs in BenchBench
    slots={...},              # RUNTIME ✓
    connections=[...],        # RUNTIME ✓
    external_hardware=[...],  # PHYSICAL → belongs in BenchBench
    metadata={...}            # TEST METADATA ✓
)
```

**Solution**: Split into:
1. **BenchBench** (physical) ✅ Already created
2. **RuntimeConfig** (new) 🔧 To be created

**Verdict**: **SPLIT - Keep SlotConfig and runtime parts, move physical to BenchBench**

---

## Proposed New Structure

### Directory Layout:
```
models/
├── bench/
│   ├── benchbench.py        ✅ Physical bench (DONE)
│   ├── runtime_config.py    🔧 Runtime test config (NEW)
│   ├── wiring.py            ✅ WiredDevice (DONE)
│   ├── pdu.py               ✅ PDU (DONE)
│   └── dut.py               ✅ DUT (DONE)
├── moku/
│   ├── platforms/
│   │   └── moku_go.py       ✅ MokuGoPlatform (DONE)
│   └── routing.py           ✅ MokuConnection (DONE)
└── ...

tests/bench_framework/
├── backend.py               ✅ KEEP (update imports)
├── hardware.py              ✅ KEEP (update to use BenchBench + RuntimeConfig)
├── simulation.py            ✅ KEEP (update to use BenchBench + RuntimeConfig)
├── visualization.py         ✅ KEEP (update to visualize both)
└── simulators/
    └── oscilloscope.py      ✅ KEEP (no changes)
```

---

## New RuntimeConfig Model (Proposal)

```python
# models/bench/runtime_config.py

class FrontendSettings(BaseModel):
    """Per-input frontend configuration."""
    impedance: Literal['50Ohm', '1MOhm'] = '1MOhm'
    coupling: Literal['AC', 'DC'] = 'DC'
    attenuation: str = '0dB'

class OutputSettings(BaseModel):
    """Per-output configuration."""
    gain: str = '0dB'

class ProbeRuntimeSettings(BaseModel):
    """Runtime probe settings (not physical like tip type)."""
    power_percent: int = Field(default=50, ge=5, le=100)
    frequency_hz: int | None = None
    notes: str | None = None

class RuntimeConfig(BaseModel):
    """
    Runtime test configuration (changes per test).

    Separates from BenchBench (physical setup) which changes rarely.

    Attributes:
        bench: Reference to physical bench (BenchBench instance or bench_id)
        slots: Instrument slot configurations
        mcc_routing: Internal MCC routing (slot-to-slot, slot-to-output)
        frontend_settings: Per-input frontend configuration
        output_settings: Per-output configuration
        probe_settings: Runtime probe settings (power, frequency, etc.)
        test_metadata: Test campaign info
    """

    # Reference to physical bench
    bench: BenchBench | str  # Instance or bench_id like 'B106'

    # Instrument slots (from old BenchConfig)
    slots: dict[int, SlotConfig]

    # MCC internal routing (slot-to-slot)
    mcc_routing: list[MokuConnection] = Field(default_factory=list)

    # Frontend settings (per-input)
    frontend_settings: dict[str, FrontendSettings] = Field(default_factory=dict)

    # Output settings (per-output)
    output_settings: dict[str, OutputSettings] = Field(default_factory=dict)

    # Probe runtime settings (NOT physical wiring, that's in BenchBench)
    probe_settings: dict[str, ProbeRuntimeSettings] = Field(default_factory=dict)

    # Test metadata
    test_metadata: dict[str, Any] = Field(default_factory=dict)

    def get_moku(self) -> MokuGoPlatform:
        """Get Moku platform from bench."""
        if isinstance(self.bench, BenchBench):
            return self.bench.moku
        else:
            # Load bench by ID (future: bench registry)
            raise NotImplementedError("Bench registry not implemented")

    def validate_routing(self) -> list[str]:
        """
        Validate MCC routing against Moku platform and slot definitions.

        Returns:
            List of validation errors (empty if valid)
        """
        errors = []
        moku = self.get_moku()

        # Build valid port names
        valid_ports = set()

        # Physical Moku ports
        for inp in moku.analog_inputs:
            valid_ports.add(inp.port_id)  # IN1, IN2
        for out in moku.analog_outputs:
            valid_ports.add(out.port_id)  # OUT1, OUT2

        # Slot virtual ports
        for slot_num in self.slots.keys():
            for port in ['InA', 'InB', 'InC', 'InD', 'OutA', 'OutB', 'OutC', 'OutD']:
                valid_ports.add(f'Slot{slot_num}{port}')

        # Validate connections
        for conn in self.mcc_routing:
            if conn.source not in valid_ports:
                errors.append(f"Invalid source port: {conn.source}")
            if conn.destination not in valid_ports:
                errors.append(f"Invalid destination port: {conn.destination}")

        return errors
```

---

## Migration Strategy

### Phase 1: Create RuntimeConfig ✅ (Next Step)
- Create `models/bench/runtime_config.py`
- Move `SlotConfig` from old config.py
- Add `FrontendSettings`, `ProbeRuntimeSettings`
- Add validation methods

### Phase 2: Update Backends 🔧
```python
# hardware.py
class HardwareBackend(Backend):
    def __init__(self, bench: BenchBench, config: RuntimeConfig):
        self.bench = bench      # Physical setup
        self.config = config    # Runtime config
        ...

    async def setup(self):
        # Use bench.moku.ip_address for connection
        # Use bench.physical_wiring for probe setup
        # Use config.slots for instrument deployment
        # Use config.mcc_routing for routing
```

### Phase 3: Update Visualization 🎨
- `generate_bench_diagram(bench: BenchBench)` → Physical layout
- `generate_test_diagram(config: RuntimeConfig)` → Runtime routing
- `generate_combined_diagram(bench, config)` → Full picture

### Phase 4: Deprecate Old Config 🗑️
- Move `tests/bench_framework/config.py` to `archive/`
- Update all imports
- Update documentation

---

## Key Wins from Refactor

### 🎯 Validation Prevents Hardware Mistakes

**Before**:
```python
# Silently accepts nonsense
ProbeConnection(probe='coil_current', moku='OUT1')  # Output→Output!
# → Deploy to hardware, waste 30 minutes debugging
```

**After**:
```python
# Catches error at config time!
'OUT1': WiredDevice(device='DS1120A', signal='coil_current')
# → ERROR: Cannot wire Output signal to Output port!
#    DS1120A.coil_current is an OUTPUT
#    Moku OUT1 is an OUTPUT
#    Hint: Wire to IN1 instead
```

### 🧩 Clear Separation of Concerns

| Concern | Before | After |
|---------|--------|-------|
| **Physical wiring** | Mixed in BenchConfig | BenchBench (rarely changes) |
| **Runtime config** | Mixed in BenchConfig | RuntimeConfig (per test) |
| **Device specs** | Hardcoded strings | Device catalog with models |
| **Validation** | Manual string checks | Pydantic + catalog lookup |

### 📚 Self-Documenting

```python
# Physical bench setup
bench = BenchBench.from_yaml('benches/B106.yaml')
print(bench.summary())
# →
# BenchBench: B106
#   Location: Lab 2, Station 3
#   Moku: Moku:Go (MokuB106) @ 192.168.73.1
#   Wiring: 3 connections
#     IN1  ← DS1120A.coil_current
#     OUT1 ← DS1120A.digital_glitch
#   PDU: CyberPower @ 192.168.73.10
#   DUT: STM32F4_decapped
```

### 🔌 DummyProbe Escape Hatch

```python
# Unknown probe? No problem!
custom = DummyProbe(
    model='MyCustomProbe',
    inputs=[Input(name='trigger', ...)],
    outputs=[Output(name='monitor', ...)]
)
register_device('CustomProbe', custom)

# Still get validation!
'IN1': WiredDevice(device='CustomProbe', signal='monitor')  # ✓
```

---

## Files to Keep vs Archive

### ✅ Keep (Update)
- `backend.py` - Abstract base class
- `hardware.py` - MCC hardware backend
- `simulation.py` - CocotB simulation backend
- `visualization.py` - Diagram generation
- `simulators/oscilloscope.py` - Behavioral model

### 🗑️ Archive (Replace)
- `config.py` → Move to `archive/bench_config_old.py`
  - `SlotConfig` → Move to `models/bench/runtime_config.py`
  - Everything else → Replaced by new models

### 📝 Update
- `__init__.py` - Update exports to new models

---

## Recommended Next Steps

1. ✅ **Create `models/bench/runtime_config.py`**
   - Move `SlotConfig` from old config
   - Add `FrontendSettings`, `ProbeRuntimeSettings`
   - Add validation against BenchBench

2. 🔧 **Update Backends**
   - Refactor to accept `(BenchBench, RuntimeConfig)` instead of old `BenchConfig`
   - Update `setup()` methods to use physical wiring from BenchBench
   - Update routing to use `MokuConnection` format

3. 🎨 **Update Visualization**
   - `generate_bench_diagram()` for physical layout
   - `generate_test_diagram()` for runtime config
   - Merge probe wiring from `PhysicalWiring`

4. 📖 **Documentation**
   - Update `BENCH_FRAMEWORK_DESIGN.md`
   - Add migration guide for existing tests
   - Add examples of new vs old patterns

5. 🧪 **Test Migration**
   - Convert existing test configs to new format
   - Validate no regressions
   - Add tests for validation failures

---

## Questions to Resolve

1. **Probe runtime settings location**:
   - Store power percentage in `RuntimeConfig` or `BenchBench`?
   - **Recommendation**: RuntimeConfig (varies per test)

2. **Bench registry**:
   - How to reference benches by ID (`'B106'` string)?
   - **Options**:
     - A: YAML files in `benches/` directory
     - B: Database/registry file
     - C: Just use BenchBench instances directly
   - **Recommendation**: Start with C, add registry later if needed

3. **Frontend settings defaults**:
   - Store defaults in MokuGoPlatform or RuntimeConfig?
   - **Recommendation**: Platform has physical defaults, Runtime overrides

4. **Backward compatibility**:
   - Support old BenchConfig format temporarily?
   - **Recommendation**: Clean break (no existing production configs)

---

## Summary

**The bench_framework architecture is excellent** - it just needs to use our new validated models instead of the old string-based config. The Backend abstraction, visualization tools, and simulators are all solid and worth keeping.

**Biggest win**: Validation catches wiring errors before deploying to hardware!

**Path forward**: Create RuntimeConfig, update backends to accept `(BenchBench, RuntimeConfig)`, archive old config.py.

# Moku Platform Simulator (formerly bench_framework)

**Updated**: 2025-10-25 - Complete rewrite for Pydantic model architecture
**Status**: ✅ Migrated from old `BenchConfig` monolith to validated models
**Directory**: `tests/moku_platform_simulator/` (renamed from `bench_framework`)

---

## ⚠️ CRITICAL: MCC CloudCompile Control Registers

When configuring CloudCompile slots with `control_registers`, you **MUST** use the 3-bit control scheme:

```python
SlotConfig(
    instrument='CloudCompile',
    bitstream='my_module.tar.gz',
    control_registers={
        0: 0xE0000000,  # ✓ Bits 31+30+29 (MCC_READY + Enable + ClkEn)
        # NOT 0xC0000000  # ✗ Missing bit 29 → MODULE FREEZES!
    }
)
```

**Required Bits in Control0[31:29]**:
- Bit 31: MCC_READY (set by MCC after deployment)
- Bit 30: Enable (user-level enable/disable)
- Bit 29: ClkEn (⚠️ MANDATORY - enables sequential logic)

**Use Helper Function**:
```python
from conftest import mcc_cr0

SlotConfig(
    instrument='CloudCompile',
    control_registers={
        0: mcc_cr0(divider=240),  # Returns 0xEEF00000
        1: 0x043C7D00              # Module params
    }
)
```

See `design_patterns.md` and `mcc_debugging_techniques.md` for complete details.

---

## Overview

The Moku Platform Simulator provides a unified abstraction for multi-instrument testbenches that works with both:
- **Simulation Backend**: CocotB + GHDL + instrument behavioral models
- **Hardware Backend**: Real Moku device via MCC Multi-Instrument Mode API

**Key Workflow**: Design → Test Locally → Push to Hardware

---

## Architecture (NEW - Pydantic Models)

### Physical Layer (`models/bench/`)

**Physical lab bench setup - changes rarely (weeks/months)**

#### `BenchBench` - Complete physical test bench
```python
from models.bench.benchbench import BenchBench
from models.bench.wiring import PhysicalWiring, WiredDevice
from models.moku.platforms.moku_go import MokuGoPlatform

bench = BenchBench(
    bench_id='B106',
    location='Lab 2, Station 3',
    moku=MokuGoPlatform(
        ip_address='192.168.73.1',
        device_name='MokuB106',
        clock_period_ns=8.0
    ),
    physical_wiring=PhysicalWiring(connections={
        'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch'),
        'DACOut1': WiredDevice(device='DS1120A', signal='pulse_amplitude')
    }),
    pdu=PDU(vendor='CyberPower', ip_address='192.168.73.10'),
    dut=DUT(name='STM32F4_decapped')
)

# Get summary
print(bench.summary())
# →
# BenchBench: B106
#   Location: Lab 2, Station 3
#   Moku: Moku:Go (MokuB106) @ 192.168.73.1
#   Wiring: 3 connections
#     IN1  ← DS1120A.coil_current
#     OUT1 → DS1120A.digital_glitch
```

#### `PhysicalWiring` - Validated device-to-port connections
```python
from models.bench.wiring import PhysicalWiring, WiredDevice

wiring = PhysicalWiring(connections={
    'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
    'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch')
})

# Validation happens automatically!
# ✓ Checks device exists in catalog
# ✓ Checks signal exists on device
# ✓ Validates direction matches (Input→Input, Output→Output)
```

#### `WiredDevice` - Device signal with direction validation
```python
# This will FAIL validation:
WiredDevice(device='DS1120A', signal='digital_glitch')  # OUTPUT
# → Wired to Moku IN1 (INPUT) → ValidationError!

# This PASSES:
WiredDevice(device='DS1120A', signal='coil_current')  # INPUT
# → Wired to Moku IN1 (INPUT) → ✓
```

### Platform Layer (`models/moku/`)

**Deployment configuration - changes per test**

#### `MokuPlatformConfig` - Complete deployment specification
```python
from models.moku.platform_config import MokuPlatformConfig, SlotConfig
from models.moku.routing import MokuConnection
from models.moku.platforms.moku_go import MOKU_GO_PLATFORM

config = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,  # Or bench.moku
    slots={
        1: SlotConfig(
            instrument='CloudCompile',
            bitstream='my_module.tar.gz',
            control_registers={
                0: mcc_cr0(divider=240),  # ✓ Helper sets all 3 bits
                1: 0x043C7D00
            }
        ),
        2: SlotConfig(
            instrument='Oscilloscope',
            settings={'sample_rate': 1e6, 'channels': ['count_out']}
        )
    },
    routing=[
        MokuConnection(source='Input1', destination='Slot1InA'),
        MokuConnection(source='Slot1OutA', destination='Slot2InA')
    ],
    metadata={'test_campaign': 'phase2', 'version': '1.0'}
)

# Validate routing
errors = config.validate_routing()
if errors:
    print("Routing errors:", errors)
```

#### `SlotConfig` - Per-slot instrument configuration
```python
# CloudCompile slot
slot1 = SlotConfig(
    instrument='CloudCompile',
    bitstream='path/to/bitstream.tar.gz',
    control_registers={
        0: 0xE0000000,  # MCC 3-bit scheme
        1: 0x12345678
    }
)

# Native instrument slot
slot2 = SlotConfig(
    instrument='Oscilloscope',
    settings={
        'sample_rate': 1e6,
        'channels': ['ch1', 'ch2'],
        'trigger': 'rising'
    }
)
```

#### `MokuConnection` - Signal routing
```python
from models.moku.routing import MokuConnection

# Physical input → Slot virtual input
MokuConnection(source='Input1', destination='Slot1InA')

# Slot output → Slot input (internal routing)
MokuConnection(source='Slot1OutA', destination='Slot2InA')

# Slot output → Physical output
MokuConnection(source='Slot2OutA', destination='Output1')
```

### Simulator (`tests/moku_platform_simulator/`)

**Backend abstraction for simulation and hardware**

#### `SimulationBackend` - CocotB behavioral models
```python
from tests.moku_platform_simulator import SimulationBackend

@cocotb.test()
async def test_my_module(dut):
    # Create simulation backend
    sim = SimulationBackend(config=config, dut=dut)
    await sim.setup()

    # Run simulation
    data = await sim.run(duration_ms=10)

    # Get instrument data
    osc = sim.get_instrument('Oscilloscope')
    osc_data = osc.get_data('count_out')

    # Verify
    assert osc.verify_incrementing('count_out', count=10)

    await sim.teardown()
```

#### `HardwareBackend` - Real Moku deployment
```python
from tests.moku_platform_simulator import HardwareBackend

async def deploy_to_hardware():
    # Create hardware backend (same config as simulation!)
    hw = HardwareBackend(config=config, bench=bench)
    await hw.setup()

    # Run on hardware
    hw_data = await hw.run(duration_ms=10)

    # Get instrument (same API!)
    osc = hw.get_instrument('Oscilloscope')
    hw_osc_data = osc.get_data()

    await hw.teardown()
```

---

## Complete Usage Pattern

### 1. Define Physical Bench (Once)
```python
from models.bench.benchbench import BenchBench
from models.bench.wiring import PhysicalWiring, WiredDevice
from models.moku.platforms.moku_go import MokuGoPlatform

# Define physical bench (save to YAML or code)
bench = BenchBench(
    bench_id='B106',
    location='Lab 2, Station 3',
    moku=MokuGoPlatform(
        ip_address='192.168.73.1',
        device_name='MokuB106'
    ),
    physical_wiring=PhysicalWiring(connections={
        'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch')
    })
)
```

### 2. Define Platform Config (Per Test)
```python
from models.moku.platform_config import MokuPlatformConfig, SlotConfig
from models.moku.routing import MokuConnection
from conftest import mcc_cr0

config = MokuPlatformConfig(
    platform=bench.moku,
    slots={
        1: SlotConfig(
            instrument='CloudCompile',
            bitstream='emfi_seq.tar.gz',
            control_registers={
                0: mcc_cr0(divider=240),
                1: 0x043C7D00
            }
        ),
        2: SlotConfig(
            instrument='Oscilloscope',
            settings={'sample_rate': 1e6}
        )
    },
    routing=[
        MokuConnection(source='Input1', destination='Slot1InA'),
        MokuConnection(source='Slot1OutA', destination='Slot2InA')
    ]
)
```

### 3. Test in Simulation
```python
@cocotb.test()
async def test_simulation(dut):
    sim = SimulationBackend(config, dut)
    await sim.setup()
    data = await sim.run(duration_ms=10)

    osc = sim.get_instrument('Oscilloscope')
    assert osc.verify_incrementing('count_out', count=10)
```

### 4. Deploy to Hardware (Same Config!)
```python
async def test_hardware():
    hw = HardwareBackend(config, bench)
    await hw.setup()
    hw_data = await hw.run(duration_ms=10)

    # Compare sim vs hardware
    assert compare_results(data, hw_data)
```

---

## Key Changes from Old BenchConfig

| Aspect | Old (BenchConfig) | New (Pydantic Models) |
|--------|-------------------|----------------------|
| **Architecture** | Monolithic class | Separated: BenchBench + MokuPlatformConfig |
| **Physical vs Runtime** | Mixed together | Clear separation |
| **Validation** | String-based, weak | Pydantic + device catalog |
| **Directory** | `tests/bench_framework/` | `tests/moku_platform_simulator/` |
| **Config file** | `config.py` | `models/moku/platform_config.py` |
| **Wiring** | `ProbeConnection` strings | `WiredDevice` with direction validation |
| **Type safety** | Dicts and strings | Fully typed Pydantic models |

### Migration Example

**Old pattern** (deprecated):
```python
from tests.bench_framework import BenchConfig, SlotConfig
from tests.bench_framework.config import MOKU_GO

config = BenchConfig(
    platform=MOKU_GO,  # Dict
    slots={...},
    connections=[...]
)
```

**New pattern** (current):
```python
from tests.moku_platform_simulator import MokuPlatformConfig, SlotConfig
from models.moku.platforms.moku_go import MOKU_GO_PLATFORM

config = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,  # Pydantic model
    slots={...},
    routing=[...]  # Renamed from 'connections'
)
```

---

## Benefits

1. **Validation Prevents Hardware Mistakes**
   - Direction validation catches wiring errors before deployment
   - Device catalog ensures signal names are correct
   - Type safety via Pydantic

2. **Clear Separation of Concerns**
   - Physical bench (BenchBench) changes rarely
   - Platform config (MokuPlatformConfig) changes per test
   - No mixing of concerns

3. **Agent-Designed Systems**
   - Declarative configs easier for AI to generate
   - Self-documenting via Pydantic Field descriptions
   - Validation errors provide clear guidance

4. **Fast Iteration**
   - Test locally in seconds, no hardware needed
   - Same config deploys to hardware
   - Regression testing: compare sim vs hardware

5. **Multi-Instrument Orchestration**
   - Complex setups become trivial
   - Validated routing between slots
   - Full control over signal paths

---

## Dependencies

Location: `pyproject.toml`

```toml
[project.dependencies]
cocotb = ">=1.8.0"      # Testing framework
pydantic = ">=2.0.0"    # Data validation
moku = ">=3.0.0"        # Hardware backend
```

Install with:
```bash
uv sync --no-install-project
```

---

## Directory Structure

```
models/
├── bench/
│   ├── benchbench.py        # Physical bench (BenchBench)
│   ├── wiring.py            # PhysicalWiring, WiredDevice
│   ├── pdu.py               # Power distribution
│   └── dut.py               # Device under test
├── moku/
│   ├── platform_config.py   # MokuPlatformConfig, SlotConfig
│   ├── routing.py           # MokuConnection
│   ├── platforms/
│   │   └── moku_go.py       # MokuGoPlatform
│   └── discovery.py         # Device discovery
└── device_catalog.py        # Device registry

tests/
├── moku_platform_simulator/  # Renamed from bench_framework
│   ├── __init__.py
│   ├── backend.py           # Backend ABC
│   ├── simulation.py        # SimulationBackend
│   ├── hardware.py          # HardwareBackend
│   ├── visualization.py     # Diagram generation
│   └── simulators/
│       ├── oscilloscope.py  # OscilloscopeSimulator
│       └── ...
├── bench_configs/           # Saved configurations
└── test_bench_framework_poc.py  # Example tests
```

---

## Roadmap

### Phase 1: Foundation ✅ COMPLETE
- BenchBench model (physical bench)
- MokuPlatformConfig model (deployment)
- Backend abstract class
- SimulationBackend with minimal functionality
- HardwareBackend stub
- OscilloscopeSimulator
- Simple counter PoC module
- 6 passing tests

### Phase 2: Simulation Backend Expansion 🔧 IN PROGRESS
- Remaining instrument simulators (WaveformGenerator, SpectrumAnalyzer, etc.)
- Advanced routing patterns
- Waveform comparison tools

### Phase 3: Hardware Backend 📅 PLANNED
- HardwareBackend implementation using MCC API
- Bitstream deployment
- Real-time data collection
- Sim vs hardware comparison

### Phase 4: Advanced Features 📅 FUTURE
- Configuration file loading (YAML/JSON)
- Waveform analysis utilities
- Performance profiling
- Documentation and examples

---

## Integration with Existing Workflow

The Moku Platform Simulator **complements** existing CocotB tests:

**Traditional CocotB** (still valid):
- Direct DUT testing
- Custom test logic
- Fine-grained control

**Moku Platform Simulator** (new option):
- Multi-instrument setups
- Configuration-driven
- Simulation + hardware portability
- Complex orchestration

**Use simulator when**:
- Testing multi-instrument scenarios
- Planning hardware deployment
- Need reproducible complex setups
- AI-generated test configurations

**Use traditional CocotB when**:
- Simple DUT unit tests
- Custom verification logic
- No hardware deployment planned

---

## References

- **Models**: `models/bench/benchbench.py`, `models/moku/platform_config.py`
- **Simulator**: `tests/moku_platform_simulator/`
- **Test Guide**: `tests/README.md`
- **Example Module**: `modules/simple_counter/`
- **Example Tests**: `tests/test_bench_framework_poc.py`
- **Related Memories**: `cocotb_testing_guide`, `instrument_*`, `mcc_debugging_techniques`
- **Design Documents**: `docs/BENCH_FRAMEWORK_DESIGN.md` (original), `docs/MIGRATION_PLAN_MokuPlatformSimulator.md`

---

## Historical Note

This memory was completely rewritten on 2025-10-25 to reflect the migration from the old monolithic `BenchConfig` to the new validated Pydantic model architecture. The old `tests/bench_framework/` directory has been renamed to `tests/moku_platform_simulator/` to better reflect its purpose as a Moku platform simulator.

# MokuConfig and BenchBench - Infrastructure Framework

**Priority**: 🟡 HIGH - Load after `mokuconfig_core_abstraction`
**Status**: Active - Complementary infrastructure models
**Related**: `mokuconfig_core_abstraction` (load that first!)

## Two Complementary Abstractions

### MokuConfig - Runtime Deployment Specification
**Purpose**: What to deploy right now
**Lifecycle**: Per-test, per-deployment (minutes)
**Serialization**: JSON/YAML deployment configs
**Tools**: `tools/moku_go.py`, CocotB tests (future)
**Location**: `models/moku/platform_config.py`

### BenchBench - Physical Infrastructure Configuration
**Purpose**: What's physically connected in the lab
**Lifecycle**: Lab setup (weeks/months)
**Serialization**: YAML bench configs (`benches/*.yaml`)
**Validation**: Direction matching, signal existence
**Location**: `models/bench/benchbench.py`

## Separation of Concerns

| Aspect | MokuConfig | BenchBench |
|--------|-----------|-----------|
| **Question** | "What to deploy?" | "What's physically connected?" |
| **Scope** | Deployment specification | Physical reality |
| **Changes** | Every test/deployment | Rarely (lab reorganization) |
| **User** | Test engineer, developer | Lab owner, bench maintainer |
| **Includes** | Slots, routing, bitstreams | Wiring, PDU, DUT, location |
| **Validation** | Slot limits, routing validity | Direction matching, signal existence |

## BenchBench Model Structure

```python
from models.bench import BenchBench, PhysicalWiring, WiredDevice, PDU, DUT
from models.moku.platforms.moku_go import MokuGoPlatform

bench = BenchBench(
    bench_id='B106',
    location='Lab 2, Station 3',
    owner='johny',
    
    # Moku platform (same model as MokuConfig uses!)
    moku=MokuGoPlatform(
        ip_address='192.168.13.159',
        device_name='MokuB106'
    ),
    
    # Physical wiring with direction validation
    physical_wiring=PhysicalWiring(connections={
        'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch'),
        'DACOut1': WiredDevice(device='DS1120A', signal='pulse_amplitude')
    }),
    
    # Infrastructure
    pdu=PDU(
        vendor='CyberPower',
        model='PDU41001',
        ip_address='192.168.73.10',
        port_assignments={
            1: 'Moku:Go',
            2: 'DS1120A_PSU',
            3: 'DUT_Power'
        }
    ),
    
    dut=DUT(
        name='STM32F4_decapped',
        description='STM32F407 with package removed'
    )
)
```

## Physical Wiring Validation

**Automatic direction validation prevents wiring errors:**

```python
from models.bench.wiring import PhysicalWiring, WiredDevice

# ✓ VALID: Device OUTPUT → Moku INPUT
wiring = PhysicalWiring(connections={
    'IN1': WiredDevice(device='DS1120A', signal='coil_current')
    # DS1120A.coil_current is an OUTPUT
    # Moku IN1 is an INPUT
    # Output→Input is valid!
})

# ✗ INVALID: Device OUTPUT → Moku OUTPUT
wiring = PhysicalWiring(connections={
    'OUT1': WiredDevice(device='DS1120A', signal='coil_current')
    # DS1120A.coil_current is an OUTPUT
    # Moku OUT1 is an OUTPUT
    # ValidationError: Cannot wire device OUTPUT to Moku OUTPUT!
})
```

**Validation uses Device Catalog:**
```python
from models.device_catalog import get_device

# Get device model
probe = get_device('DS1120A')

# Check signal direction
probe.get_output('coil_current')  # → Output object
probe.get_input('digital_glitch')  # → Input object
```

## Integration Pattern (Future)

**MokuConfig uses BenchBench for validation:**

```python
# Step 1: Load physical bench config
bench = load_benchbench('benches/B106.yaml')

# Step 2: Create deployment config
config = MokuConfig(
    platform=bench.moku,  # Use same platform!
    slots={...},
    routing=[...]
)

# Step 3: Validate deployment against physical wiring
for conn in config.routing:
    if conn.destination.startswith('Output'):
        # Check physical wiring exists
        port = conn.destination.replace('Output', 'OUT')
        wired_device = bench.get_wired_device(port)
        
        if not wired_device:
            warnings.warn(f"⚠ {port} not physically wired in bench!")
        else:
            print(f"✓ {port} → {wired_device.device}.{wired_device.signal}")
```

**Benefits:**
- Catch disconnected outputs before deployment
- Verify bench matches deployment expectations
- Document which external devices are connected

## Workflow Example

### Lab Setup (Once)

**Create bench config file** (`benches/B106.yaml`):
```yaml
bench_id: B106
location: Lab 2, Station 3
owner: johny

moku:
  ip_address: "192.168.13.159"
  device_name: "MokuB106"

physical_wiring:
  connections:
    IN1:
      device: DS1120A
      signal: coil_current
    OUT1:
      device: DS1120A
      signal: digital_glitch
    DACOut1:
      device: DS1120A
      signal: pulse_amplitude

pdu:
  vendor: CyberPower
  ip_address: "192.168.73.10"
  port_assignments:
    1: "Moku:Go"
    2: "DS1120A_PSU"

dut:
  name: STM32F4_decapped
  description: STM32F407 with package removed
```

**Load and validate:**
```python
from models.bench import load_benchbench

bench = load_benchbench(yaml.safe_load(Path('benches/B106.yaml').read_text()))
print(bench.summary())
# →
# BenchBench: B106
#   Location: Lab 2, Station 3
#   Moku: Moku:Go (MokuB106) @ 192.168.13.159
#   Wiring: 3 connections
#     IN1        ← DS1120A.coil_current
#     OUT1       → DS1120A.digital_glitch
#     DACOut1    → DS1120A.pulse_amplitude
#   PDU: CyberPower PDU41001 @ 192.168.73.10
#   DUT: STM32F4_decapped
#   Owner: johny
```

### Daily Testing (Per Deployment)

**Create deployment config** (uses bench IP):
```python
from models.moku import MokuConfig, SlotConfig

config = MokuConfig(
    platform=bench.moku,  # Reuse platform from bench
    slots={
        2: SlotConfig(
            instrument='CloudCompile',
            bitstream='modules/EMFI-Seq/latest/*.tar',
            control_registers={0: 0xE0000000, ...}
        )
    },
    routing=[
        MokuConnection(source='Slot2OutA', destination='Output1')
    ]
)
```

**Deploy:**
```bash
# IP comes from bench config automatically
uv run python tools/moku_go.py deploy \
    --device MokuB106 \
    --config deployment.json
```

## Current State vs Future

### Current (2025-10-25)
- ✅ BenchBench model exists (`models/bench/benchbench.py`)
- ✅ MokuConfig model exists (`models/moku/platform_config.py`)
- ✅ Physical wiring validation working
- ✅ Device catalog with DS1120A
- ❌ No automatic integration between them
- ❌ Manual IP address management

### Future Enhancements
- 🔮 `moku_go.py deploy --bench B106` (auto-populate IP from bench)
- 🔮 Automatic routing validation against physical wiring
- 🔮 Warn about unmapped physical ports
- 🔮 CocotB integration with bench configs
- 🔮 Multi-bench test campaigns

## Related Models

**BenchBench Components:**
- `PhysicalWiring` - Validated cable connections
- `WiredDevice` - Device signal with direction validation
- `PDU` - Power distribution unit
- `DUT` - Device under test

**MokuConfig Components:**
- `SlotConfig` - Per-slot instrument configuration
- `MokuConnection` - Signal routing specification
- `MokuGoPlatform` - Physical hardware specification (shared!)

**Device Catalog:**
- `DS1120A` - EMFI probe model
- `DummyProbe` - Unknown device placeholder
- `get_device()` - Catalog lookup function

## Key Files

- `models/bench/benchbench.py` - BenchBench implementation
- `models/bench/wiring.py` - PhysicalWiring, WiredDevice
- `models/moku/platform_config.py` - MokuConfig implementation
- `models/device_catalog.py` - Device registry
- `models/riscure/ds1120a.py` - DS1120A probe model
- `benches/*.yaml` - Bench configuration files (future)

## When to Use Each

**Use BenchBench when:**
- Setting up a new lab bench
- Documenting physical wiring
- Validating cable connections
- Managing lab infrastructure
- Tracking bench ownership/calibration

**Use MokuConfig when:**
- Deploying bitstreams to Moku
- Configuring multi-instrument setups
- Writing deployment scripts
- Creating test campaigns
- Running CocotB simulations (future)

**Use BOTH when:**
- Validating deployments against physical reality
- Automating IP address management
- Ensuring test configs match bench capabilities

## Moku Platform Simulator (Related)

The Moku Platform Simulator (`tests/moku_platform_simulator/`) provides simulation backends that use MokuConfig:

**SimulationBackend** - CocotB behavioral models
```python
from tests.moku_platform_simulator import SimulationBackend

@cocotb.test()
async def test_simulation(dut):
    sim = SimulationBackend(config=mokuconfig, dut=dut)
    await sim.setup()
    data = await sim.run(duration_ms=10)
```

**HardwareBackend** - Real Moku deployment
```python
from tests.moku_platform_simulator import HardwareBackend

hw = HardwareBackend(config=mokuconfig, bench=benchbench)
await hw.setup()
hw_data = await hw.run(duration_ms=10)
```

See `docs/BENCH_FRAMEWORK_DESIGN.md` for full simulator documentation.

## Related Serena Memories

- `mokuconfig_core_abstraction` - THE core model (load first!)
- `platform_models` - MokuGoPlatform details
- `riscure_ds1120a` - DS1120A probe specifications
- `cocotb_testing_guide` - CocotB integration patterns

---

**Load Priority**: 🟡 HIGH - Load after `mokuconfig_core_abstraction`
**Last Updated**: 2025-10-25

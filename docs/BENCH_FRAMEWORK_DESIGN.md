# Bench Configuration Framework - Design Document

## Vision

Create a **unified abstraction** for multi-instrument testbenches that works with both:
- **Simulation Backend**: CocotB + GHDL + instrument behavioral models
- **Hardware Backend**: Real Moku device via MCC Multi-Instrument Mode API

**Enables workflow**: Design → Test Locally → Push to Hardware

## Key Concept

Write bench configuration **once**, run it **everywhere**:

```python
# bench_config.py - Works for simulation AND hardware
config = BenchConfig(
    platform=MOKU_GO,
    slots={
        1: {'instrument': 'WaveformGenerator', 'settings': {...}},
        2: {'instrument': 'CloudCompile', 'bitstream': 'my_module.tar.gz'},
        3: {'instrument': 'Oscilloscope', 'settings': {...}}
    },
    connections=[
        {'source': 'Slot1OutA', 'destination': 'Slot2InA'},
        {'source': 'Slot2OutA', 'destination': 'Slot3InA'},
    ]
)
```

### Simulation Usage
```python
# Test locally with CocotB
bench = SimulationBackend.from_config(config, dut)
await bench.setup()
await bench.run(duration_ms=100)
assert verify_results(bench.get_data())
```

### Hardware Deployment
```python
# Same config, real hardware!
bench = HardwareBackend.from_config(config, ip='192.168.1.100')
bench.setup()
data = bench.run(duration_ms=100)
compare_to_simulation(data)
```

## Architecture

### 1. Bench Configuration Data Model

```python
@dataclass
class SlotConfig:
    instrument: str  # 'WaveformGenerator', 'Oscilloscope', 'CloudCompile', etc.
    settings: Dict[str, Any]
    control_registers: Dict[int, int] = None  # For CloudCompile slots

@dataclass
class Connection:
    source: str      # 'Input1', 'Slot1OutA', etc.
    destination: str # 'Output1', 'Slot2InA', etc.

@dataclass
class BenchConfig:
    platform: Dict[str, Any]  # MOKU_GO, MOKU_PRO, etc.
    slots: Dict[int, SlotConfig]
    connections: List[Connection]
```

### 2. Backend Abstraction

```python
class Backend(ABC):
    @abstractmethod
    async def setup(self): pass

    @abstractmethod
    async def run(self, duration_ms: float): pass

    @abstractmethod
    def get_instrument(self, slot_or_name: int | str): pass
```

### 3. Simulation Backend (CocotB)

- Instantiates **instrument behavioral models** (simulators)
- Routes signals between simulators and DUT
- Runs all instruments as concurrent CocotB tasks
- Collects data from simulated instruments

**Instrument Simulators**:
- `WaveformGeneratorSimulator` - Generates sine/square/triangle, drives DUT inputs
- `OscilloscopeSimulator` - Captures DUT outputs to array
- `SpectrumAnalyzerSimulator` - FFT of captured signal
- `DataLoggerSimulator` - Time-series recording
- `CloudCompileSimulator` - Pass-through to DUT (the VHDL under test)

### 4. Hardware Backend (MCC API)

- Uses `MultiInstrument` class from Moku Python API
- Translates `BenchConfig` to `set_instrument()` and `set_connections()` calls
- Deploys bitstreams to CloudCompile slots
- Collects data from real instruments

### 5. Signal Routing

**Simulation**: Python references between simulator objects
```python
# Route WaveformGen output to DUT input
wg_sim.output_signal = dut.InputA
```

**Hardware**: MCC connection dicts
```python
connections = [dict(source='Slot1OutA', destination='Slot2InA')]
mim.set_connections(connections=connections)
```

## Implementation Roadmap

### Phase 1: Foundation (CURRENT)
- ✅ Create `BenchConfig` data model
- ✅ Implement `Backend` abstract class
- ✅ Configuration parser and validator
- ✅ **Proof of Concept**: Simple counter module test
- 📝 Serena memory: `bench_config_framework.md`

**PoC Module**: Simple 16-bit counter
- Resets to 0
- Increments every clock cycle
- Drives all 4 outputs (OutputA/B/C/D)
- Perfect for testing: predictable, easy to simulate, tests all outputs

### Phase 2: Simulation Backend
- ✅ Implement `SimulationBackend`
- ✅ Create simulators for top 5 instruments:
  - WaveformGenerator (sine/square/triangle)
  - Oscilloscope (data capture)
  - CloudCompile (pass-through to DUT)
  - SpectrumAnalyzer (FFT)
  - DataLogger (recording)
- ✅ Test with counter module + WaveformGen → Counter → Oscilloscope
- 📝 Serena memory: `instrument_simulation_models.md`

### Phase 3: Hardware Backend
- ✅ Implement `HardwareBackend`
- ✅ Config → MCC API translation layer
- ✅ Error handling and connection validation
- ✅ Deploy same counter test to real Moku
- ✅ Compare sim vs hardware results
- 📝 Serena memory: `hardware_deployment_workflow.md`

### Phase 4: Expansion
- ✅ Remaining 11 instrument simulators
- ✅ Advanced routing patterns (fan-out, feedback loops)
- ✅ Waveform comparison tools
- 📝 Update all 16 `instrument_*.md` memories

## Key Benefits

1. **Agent-Designed Systems**: AI writes bench configs declaratively
2. **Fast Iteration**: Test locally in seconds
3. **One-Click Deployment**: `bench.deploy(ip='192.168.1.100')`
4. **Regression Testing**: Auto-compare sim vs hardware
5. **Multi-Instrument Orchestration**: Complex setups trivial
6. **Version Control**: Configs live in git with VHDL
7. **Reproducibility**: Same config = same test, always

## Serena Memory Updates

### New Memories
1. **`bench_config_framework.md`** - Philosophy, data model, examples
2. **`instrument_simulation_models.md`** - Behavioral models, accuracy notes
3. **`hardware_deployment_workflow.md`** - CocotB → Hardware pipeline

### Updates to Existing
4. **`cocotb_testing_guide.md`** - Add multi-instrument testbench section
5. **`mcc_routing_concepts.md`** - Routing in sim vs hardware
6. **Each `instrument_*.md`** - Add simulation model section

## Directory Structure

```
bench_framework/
├── __init__.py
├── config.py           # BenchConfig data model
├── backend.py          # Backend abstract class
├── simulation.py       # SimulationBackend
├── hardware.py         # HardwareBackend
├── routing.py          # Signal routing logic
└── simulators/
    ├── __init__.py
    ├── waveform_generator.py
    ├── oscilloscope.py
    ├── cloud_compile.py
    ├── spectrum_analyzer.py
    └── ... (all 16 instruments)
```

## Example: Complete Workflow

### 1. Write VHDL Module
```vhdl
-- modules/simple_counter/core/simple_counter_core.vhd
architecture rtl of simple_counter_core is
    signal counter : unsigned(15 downto 0);
begin
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            counter <= counter + 1;
        end if;
    end process;

    count_out <= std_logic_vector(counter);
end architecture;
```

### 2. Create Bench Config
```python
# bench_configs/counter_test.py
config = BenchConfig(
    platform=MOKU_GO,
    slots={
        1: {
            'instrument': 'WaveformGenerator',
            'settings': {'channel': 1, 'type': 'Sine', 'frequency': 1e6, 'amplitude': 1.0}
        },
        2: {
            'instrument': 'CloudCompile',
            'bitstream': 'simple_counter.tar.gz',
            'control_registers': {0: 0x80000001}  # MCC_READY + enable
        },
        3: {
            'instrument': 'Oscilloscope',
            'settings': {'timebase': (-5e-3, 5e-3)}
        }
    },
    connections=[
        {'source': 'Slot1OutA', 'destination': 'Slot2InA'},  # Optional: drive input
        {'source': 'Slot2OutA', 'destination': 'Slot3InA'},  # Counter → Oscilloscope
        {'source': 'Slot2OutB', 'destination': 'Slot3InB'},
    ]
)
```

### 3. Test Locally (CocotB)
```python
# tests/test_counter_bench.py
@cocotb.test()
async def test_counter_system(dut):
    bench = SimulationBackend.from_config('bench_configs/counter_test.py', dut)
    await bench.setup()
    await bench.run(duration_ms=10)

    osc = bench.get_instrument('Oscilloscope')
    data = osc.get_data()

    # Verify counter increments
    assert data['ch1'][1] == data['ch1'][0] + 1
```

### 4. Deploy to Hardware
```python
# deploy_counter.py
bench = HardwareBackend.from_config('bench_configs/counter_test.py', ip='192.168.1.100')
bench.setup()
data = bench.run(duration_ms=10)

# Should match simulation (within ADC/DAC quantization)
compare_results(simulation_data, data)
```

## Design Decisions

### Why Not Just Use MCC API Directly?
- **Portability**: Bench configs work in simulation without hardware
- **Faster iteration**: No bitstream compilation for every test
- **Agent-friendly**: Declarative configs easier for AI to generate
- **Regression testing**: Compare sim vs hardware automatically

### Why Behavioral Models Instead of Full Instrument HDL?
- **Simulation speed**: Python models 1000x faster than full VHDL
- **Accuracy trade-off**: Good enough for functional testing
- **Extensibility**: Easy to add custom instruments
- **For detailed instrument testing**: Use Moku's own validation, not ours

### CloudCompile Slot = DUT?
- Yes! CloudCompile slot is where your VHDL module lives
- In simulation: `CloudCompileSimulator` just routes to `dut` signals
- In hardware: MCC deploys bitstream and handles routing

## Next Steps

1. **Phase 1 Proof of Concept**:
   - Create simple counter module (VHDL)
   - Implement basic `BenchConfig` and `Backend` classes
   - Build minimal `SimulationBackend` with Oscilloscope simulator
   - Test: Counter → Oscilloscope bench config
   - Validate architecture before expanding

2. **If PoC succeeds**:
   - Continue with Phase 2 (full simulation backend)
   - Add remaining instrument simulators
   - Build hardware backend

3. **Documentation**:
   - Create Serena memories as each phase completes
   - Keep this design doc updated with learnings

---

**Status**: Ready to start Phase 1
**First Module**: Simple 16-bit counter (simpler than clk_divider!)
**First Bench Config**: Counter → Oscilloscope

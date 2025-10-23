# Bench Configuration Framework

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

The Bench Configuration Framework provides a unified abstraction for multi-instrument testbenches that works with both:
- **Simulation Backend**: CocotB + GHDL + instrument behavioral models
- **Hardware Backend**: Real Moku device via MCC Multi-Instrument Mode API

**Key Workflow**: Design → Test Locally → Push to Hardware

## Philosophy

Write bench configuration **once**, run it **everywhere**. The same declarative configuration works for:
- Local simulation (fast iteration, no hardware needed)
- Hardware deployment (real Moku device, same config)
- Regression testing (compare sim vs hardware automatically)

## Architecture

### Location
- Framework code: `tests/bench_framework/`
- Tests: `tests/test_bench_framework_*.py`
- Example module: `modules/simple_counter/`

### Core Components

#### 1. Configuration Data Models (`config.py`)

Uses Pydantic for type-safe, validated configurations:

```python
from bench_framework import BenchConfig, SlotConfig, Connection
from bench_framework.config import MOKU_GO, MOKU_PRO
from conftest import mcc_cr0  # Helper for Control0 values

config = BenchConfig(
    platform=MOKU_GO,
    slots={
        1: SlotConfig(
            instrument='WaveformGenerator',
            settings={'frequency': 1e6, 'amplitude': 1.0}
        ),
        2: SlotConfig(
            instrument='CloudCompile',
            bitstream='my_module.tar.gz',
            control_registers={
                0: mcc_cr0(divider=240),  # ✓ All 3 bits set automatically
                1: 0x043C7D00
            }
        ),
        3: SlotConfig(
            instrument='Oscilloscope',
            settings={'sample_rate': 1e6, 'channels': ['count_out']}
        )
    },
    connections=[
        Connection(source='Slot1OutA', destination='Slot2InA'),
        Connection(source='Slot2OutA', destination='Slot3InA'),
    ]
)
```

**Key Classes**:
- `BenchConfig`: Top-level configuration with platform, slots, connections
- `SlotConfig`: Per-slot instrument configuration
- `Connection`: Signal routing between slots/ports
- `MOKU_GO`, `MOKU_PRO`: Platform definitions

**Validation**:
- Slot numbers within platform limits
- Connection port names valid
- Required fields present
- Type safety via Pydantic
- **Control register validation** (automatic in `conftest.py`)

#### 2. Backend Abstract Class (`backend.py`)

```python
class Backend(ABC):
    @abstractmethod
    async def setup(self) -> None:
        """Configure instruments and connections"""
        pass
    
    @abstractmethod
    async def run(self, duration_ms: float) -> Dict[str, Any]:
        """Run testbench and collect data"""
        pass
    
    @abstractmethod
    def get_instrument(self, slot_or_name: Union[int, str]) -> Any:
        """Get instrument by slot number or type name"""
        pass
```

#### 3. Simulation Backend (`simulation.py`)

CocotB-based simulation using behavioral models:

```python
backend = SimulationBackend.from_config(config, dut)
await backend.setup()
data = await backend.run(duration_ms=10)

osc = backend.get_instrument('Oscilloscope')
osc_data = osc.get_data('count_out')
```

**Features**:
- Instantiates instrument simulators per slot
- Manages signal routing between simulators and DUT
- Runs concurrent CocotB tasks
- Collects data from all instruments

#### 4. Hardware Backend (`hardware.py`)

Phase 1: Stub implementation (raises NotImplementedError)
Phase 3: Will use Moku MCC Multi-Instrument API

```python
# Phase 3 (planned):
backend = HardwareBackend.from_config(config, ip='192.168.1.100')
backend.setup()
data = backend.run(duration_ms=10)
```

### Instrument Simulators (`simulators/`)

Phase 1 includes:
- **OscilloscopeSimulator**: Captures DUT outputs to time-series arrays
- **CloudCompileSimulator**: Pass-through to DUT (no model needed)

**OscilloscopeSimulator Usage**:
```python
from bench_framework.simulators import OscilloscopeSimulator

osc = OscilloscopeSimulator(dut, {
    'sample_rate': 1e6,
    'channels': ['count_out']
})

await osc.run(duration_ns=100_000)  # 100 µs

data = osc.get_data('count_out')
# Returns: {'time': [...], 'values': [...], 'sample_count': N}

# Verification helpers
is_incrementing = osc.verify_incrementing('count_out', start_sample=10, count=20)
```

Phase 2 will add: WaveformGenerator, SpectrumAnalyzer, DataLogger, etc.

## Phase 1 Proof of Concept

### Simple Counter Module

Location: `modules/simple_counter/core/simple_counter_core.vhd`

**Features**:
- 16-bit unsigned counter
- Increments every clock cycle when enabled
- Standard control signals: `clk`, `n_reset`, `clk_en`, `enable`
- Tier 1 strict RTL (Verilog portable)

**Perfect for PoC**:
- Predictable output (increments by 1)
- Easy to verify
- Minimal complexity

### Test Suite

Location: `tests/test_bench_framework_poc.py`

**6 Tests**:
1. Basic bench configuration creation and validation
2. Simulation backend setup
3. Counter → Oscilloscope data capture (full workflow)
4. Get instrument by slot number and type name
5. Configuration validation (error detection)
6. All tests passed marker

**Running Tests**:
```bash
cd tests/
make TEST_MODULE=bench_framework_poc
```

## Usage Patterns

### Pattern 1: Configuration-Driven Testing

```python
from conftest import mcc_cr0  # Helper function

@cocotb.test()
async def test_my_module(dut):
    # Setup DUT
    await setup_clock(dut)
    dut.clk_en.value = 1
    dut.enable.value = 1
    await reset_active_low(dut)
    
    # Create bench configuration
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                control_registers={
                    0: mcc_cr0(divider=240)  # ✓ All 3 bits set
                }
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'channels': ['count_out']}
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA')
        ]
    )
    
    # Run simulation
    backend = SimulationBackend.from_config(config, dut)
    await backend.setup()
    data = await backend.run(duration_ms=1.0)
    
    # Verify results
    osc = backend.get_instrument('Oscilloscope')
    assert osc.verify_incrementing('count_out', count=10)
```

### Pattern 2: Multi-Instrument Orchestration

```python
config = BenchConfig(
    platform=MOKU_PRO,
    slots={
        1: SlotConfig(instrument='WaveformGenerator', ...),
        2: SlotConfig(
            instrument='CloudCompile',
            bitstream='fir.tar.gz',
            control_registers={
                0: mcc_cr0(),  # Base pattern (0xE0000000)
                1: 0x0000007F
            }
        ),
        3: SlotConfig(instrument='Oscilloscope', ...),
        4: SlotConfig(instrument='SpectrumAnalyzer', ...)
    },
    connections=[
        Connection('Slot1OutA', 'Slot2InA'),  # WG → Filter
        Connection('Slot2OutA', 'Slot3InA'),  # Filter → Scope
        Connection('Slot2OutA', 'Slot4InA'),  # Filter → SA
    ]
)
```

## Benefits

1. **Agent-Designed Systems**: Declarative configs easier for AI to generate
2. **Fast Iteration**: Test locally in seconds, no hardware needed
3. **One-Click Deployment**: Same config deploys to hardware (Phase 3)
4. **Regression Testing**: Auto-compare sim vs hardware results
5. **Multi-Instrument Orchestration**: Complex setups become trivial
6. **Version Control**: Configs live in git with VHDL
7. **Reproducibility**: Same config = same test, always
8. **Safe Defaults**: Helper functions ensure correct Control0 patterns

## Dependencies

Location: `requirements.txt`

```
cocotb>=1.8.0      # Testing framework
pydantic>=2.0.0    # Data validation
moku>=3.0.0        # Hardware backend (Phase 3)
```

## Roadmap

### Phase 1: Foundation ✅ COMPLETE
- BenchConfig data model
- Backend abstract class
- SimulationBackend with minimal functionality
- HardwareBackend stub
- OscilloscopeSimulator
- Simple counter PoC module
- 6 passing tests

### Phase 2: Simulation Backend Expansion
- Remaining instrument simulators (WaveformGenerator, SpectrumAnalyzer, etc.)
- Advanced routing patterns
- Waveform comparison tools

### Phase 3: Hardware Backend
- HardwareBackend implementation using MCC API
- Bitstream deployment
- Real-time data collection
- Sim vs hardware comparison

### Phase 4: Advanced Features
- Configuration file loading (YAML/JSON)
- Waveform analysis utilities
- Performance profiling
- Documentation and examples

## Key Design Decisions

**Why Behavioral Models Instead of Full Instrument HDL?**
- 1000x faster simulation
- Functional accuracy sufficient for verification
- Easy to extend and customize
- Moku handles detailed instrument validation

**CloudCompile Slot = DUT**
- Yes! CloudCompile slot is where your VHDL module lives
- In simulation: Routes directly to `dut` signals
- In hardware: MCC deploys bitstream and handles routing

**Why Not Just Use MCC API Directly?**
- Portability: Configs work in simulation without hardware
- Faster iteration: No bitstream compilation for every test
- Agent-friendly: Declarative easier for AI to generate
- Regression testing: Compare sim vs hardware automatically

## References

- Design Document: `docs/BENCH_FRAMEWORK_DESIGN.md`
- Test Guide: `tests/README.md`
- Example Module: `modules/simple_counter/`
- Example Tests: `tests/test_bench_framework_poc.py`
- Related Memories: `cocotb_testing_guide`, `instrument_*`, `mcc_debugging_techniques`

## Integration with Existing Workflow

The bench framework **complements** existing CocotB tests:

**Traditional CocotB** (still valid):
- Direct DUT testing
- Custom test logic
- Fine-grained control

**Bench Framework** (new option):
- Multi-instrument setups
- Configuration-driven
- Simulation + hardware portability
- Complex orchestration

Use bench framework when:
- Testing multi-instrument scenarios
- Planning hardware deployment
- Need reproducible complex setups
- AI-generated test configurations

Use traditional CocotB when:
- Simple DUT unit tests
- Custom verification logic
- No hardware deployment planned

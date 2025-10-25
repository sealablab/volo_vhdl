# Migration Plan: bench_framework → moku_platform_simulator

**Branch**: `feature/BenchConfigRewrite`
**Goal**: Refactor bench_framework to use validated Pydantic models and clarify purpose as Moku platform simulator
**Status**: Ready to execute

---

## Context Summary

**What We Built**:
- ✅ Validated Pydantic models in `models/` (tagged as `v0.2-validated-models`)
- ✅ `BenchBench` - Physical lab bench with validated wiring
- ✅ Device catalog with direction validation
- ✅ DummyProbe escape hatch

**What We Discovered**:
- `tests/bench_framework/` is actually a **Moku platform simulator** for CocotB
- Purpose: "Train like you fight" - test VHDL as if deployed to Moku
- Enables same config for simulation AND hardware deployment
- Current name/structure doesn't reflect this purpose

---

## Migration Steps

### Phase 1: Create New Models (30 mins)

#### Step 1.1: Create `models/moku/platform_config.py`

```python
"""
Moku Platform Configuration

Deployment specification for Moku MultiInstrument mode.
Works for BOTH simulation (behavioral models) and hardware (real Moku).

This is NOT a test configuration - it's a Moku platform deployment spec.
"""

from pydantic import BaseModel, Field, field_validator
from models.moku.platforms.moku_go import MokuGoPlatform
from models.moku.routing import MokuConnection


class SlotConfig(BaseModel):
    """
    Configuration for a single instrument slot.

    Attributes:
        instrument: Instrument type name (e.g., 'CloudCompile', 'Oscilloscope')
        settings: Instrument-specific settings dictionary
        control_registers: Optional register values for CloudCompile slots
        bitstream: Optional bitstream path for CloudCompile slots
    """
    instrument: str = Field(..., description="Instrument type name")
    settings: dict[str, any] = Field(default_factory=dict, description="Instrument-specific settings")
    control_registers: dict[int, int] | None = Field(default=None, description="Control register values (CloudCompile)")
    bitstream: str | None = Field(default=None, description="Bitstream path (CloudCompile)")

    @field_validator('instrument')
    @classmethod
    def validate_instrument_name(cls, v: str) -> str:
        """Validate instrument name is non-empty."""
        if not v or not v.strip():
            raise ValueError("Instrument name cannot be empty")
        return v.strip()


class MokuPlatformConfig(BaseModel):
    """
    Moku MultiInstrument platform deployment configuration.

    Specifies which instruments to deploy to which slots and how to route
    signals between them. Works for BOTH simulation and hardware backends.

    Simulation: Creates behavioral instrument models in CocotB
    Hardware: Deploys to real Moku device via MCC API

    Attributes:
        platform: Moku platform model (Go, Lab, Pro, etc.)
        slots: Slot configurations (slot number → SlotConfig)
        routing: MCC signal routing between slots/ports
        metadata: Optional metadata (test campaign, version, etc.)

    Example:
        >>> config = MokuPlatformConfig(
        ...     platform=MOKU_GO_PLATFORM,
        ...     slots={
        ...         1: SlotConfig(instrument='CloudCompile', bitstream='emfi_seq.bit'),
        ...         2: SlotConfig(instrument='Oscilloscope', settings={'sample_rate': 1e6})
        ...     },
        ...     routing=[
        ...         MokuConnection(source='Input1', destination='Slot1InA'),
        ...         MokuConnection(source='Slot1OutA', destination='Slot2InA')
        ...     ]
        ... )
    """

    platform: MokuGoPlatform = Field(..., description="Moku platform specification")
    slots: dict[int, SlotConfig] = Field(..., description="Slot configurations")
    routing: list[MokuConnection] = Field(default_factory=list, description="MCC signal routing")
    metadata: dict[str, any] = Field(default_factory=dict, description="Optional metadata")

    @field_validator('slots')
    @classmethod
    def validate_slots(cls, v: dict[int, SlotConfig], info) -> dict[int, SlotConfig]:
        """Validate slot numbers are within platform limits."""
        if not v:
            raise ValueError("At least one slot must be configured")

        platform = info.data.get('platform')
        if platform:
            max_slots = platform.slots
            for slot_num in v.keys():
                if slot_num < 1 or slot_num > max_slots:
                    raise ValueError(f"Slot {slot_num} out of range for platform (1-{max_slots})")

        return v

    def validate_routing(self) -> list[str]:
        """
        Validate all routing connections reference valid ports.

        Returns:
            List of validation errors (empty if valid)
        """
        errors = []

        # Build list of valid port names
        valid_ports = set()

        # Add platform physical ports
        for inp in self.platform.analog_inputs:
            valid_ports.add(inp.port_id)  # IN1, IN2
        for out in self.platform.analog_outputs:
            valid_ports.add(out.port_id)  # OUT1, OUT2

        # Add slot virtual ports (SlotNInA, SlotNOutA, etc.)
        for slot_num in self.slots.keys():
            for port_type in ['InA', 'InB', 'InC', 'InD', 'OutA', 'OutB', 'OutC', 'OutD']:
                valid_ports.add(f'Slot{slot_num}{port_type}')

        # Validate each connection
        for idx, conn in enumerate(self.routing):
            if conn.source not in valid_ports:
                errors.append(f"Connection {idx}: Invalid source port '{conn.source}'")
            if conn.destination not in valid_ports:
                errors.append(f"Connection {idx}: Invalid destination port '{conn.destination}'")

        return errors

    def get_slot(self, slot_num: int) -> SlotConfig | None:
        """Get configuration for specific slot number."""
        return self.slots.get(slot_num)

    def get_instrument_slots(self, instrument_type: str) -> list[int]:
        """Get list of slot numbers containing specified instrument type."""
        return [
            slot_num
            for slot_num, config in self.slots.items()
            if config.instrument == instrument_type
        ]

    def to_dict(self) -> dict:
        """Export configuration as dictionary for serialization."""
        return self.model_dump()

    @classmethod
    def from_dict(cls, data: dict) -> 'MokuPlatformConfig':
        """Create configuration from dictionary."""
        return cls(**data)
```

**File**: `models/moku/platform_config.py`

---

#### Step 1.2: Update `models/moku/__init__.py`

Add exports:
```python
from models.moku.platform_config import MokuPlatformConfig, SlotConfig

__all__ = [
    'MokuGoPlatform',
    'MOKU_GO_PLATFORM',
    'MokuConnection',
    'MokuConnectionList',
    'MokuPlatformConfig',  # NEW
    'SlotConfig',          # NEW
]
```

---

### Phase 2: Rename Directory (5 mins)

```bash
cd tests/
git mv bench_framework moku_platform_simulator
```

**Update imports throughout codebase**:
```bash
# Find all imports
grep -r "from.*bench_framework" tests/
grep -r "import.*bench_framework" tests/

# Update each file:
# OLD: from tests.bench_framework import ...
# NEW: from tests.moku_platform_simulator import ...
```

---

### Phase 3: Update Backend Classes (45 mins)

#### Step 3.1: Update `tests/moku_platform_simulator/backend.py`

```python
"""
Backend Abstract Base Class

Defines interface for Moku platform simulation and hardware deployment.
"""

from abc import ABC, abstractmethod
from typing import Any
from models.moku.platform_config import MokuPlatformConfig


class Backend(ABC):
    """
    Abstract base class for Moku platform backends.

    Provides unified interface for both:
    - Simulation: CocotB behavioral models
    - Hardware: Real Moku device via MCC API
    """

    def __init__(self, config: MokuPlatformConfig):
        """
        Initialize backend with platform configuration.

        Args:
            config: MokuPlatformConfig instance
        """
        self.config = config
        self.instruments: dict[int, Any] = {}  # Slot number → instrument instance
        self._setup_complete = False

    @abstractmethod
    async def setup(self) -> None:
        """Configure and initialize all instruments and routing."""
        pass

    @abstractmethod
    async def run(self, duration_ms: float) -> dict[str, Any]:
        """Run configured platform for specified duration."""
        pass

    @abstractmethod
    def get_instrument(self, slot_or_name: int | str) -> Any:
        """Get instrument instance by slot number or type name."""
        pass

    def validate_setup(self) -> None:
        """Validate that setup() has been called."""
        if not self._setup_complete:
            raise RuntimeError("Backend setup() must be called before run()")

    async def teardown(self) -> None:
        """Clean up resources (optional override)."""
        pass

    def __repr__(self) -> str:
        platform_name = self.config.platform.name
        slot_count = len(self.config.slots)
        return f"{self.__class__.__name__}(platform={platform_name}, slots={slot_count})"
```

---

#### Step 3.2: Update `tests/moku_platform_simulator/simulation.py`

**Changes**:
1. Import `MokuPlatformConfig` instead of old `BenchConfig`
2. Update validation calls: `config.validate_routing()` instead of `validate_connections()`
3. Everything else stays the same!

```python
"""
Simulation Backend

CocotB-based Moku platform simulator using behavioral instrument models.
"""

from typing import Any
import cocotb
from cocotb.triggers import Timer
from .backend import Backend
from models.moku.platform_config import MokuPlatformConfig


class SimulationBackend(Backend):
    """
    Moku platform simulator using CocotB and behavioral models.

    Creates behavioral models of Moku instruments (oscilloscope, etc.)
    and simulates MCC routing between slots.
    """

    def __init__(self, config: MokuPlatformConfig, dut: Any):
        """
        Initialize simulation backend.

        Args:
            config: MokuPlatformConfig instance
            dut: CocotB DUT handle
        """
        super().__init__(config)
        self.dut = dut
        self.simulators: dict[int, Any] = {}
        self.tasks: list = []

    @classmethod
    def from_config(cls, config: MokuPlatformConfig | str | dict, dut: Any) -> 'SimulationBackend':
        """Create SimulationBackend from config."""
        if isinstance(config, str):
            raise NotImplementedError("Loading from file not implemented yet")
        elif isinstance(config, dict):
            config = MokuPlatformConfig.from_dict(config)
        elif not isinstance(config, MokuPlatformConfig):
            raise TypeError(f"config must be MokuPlatformConfig, got {type(config)}")

        return cls(config, dut)

    async def setup(self) -> None:
        """Setup simulation: create behavioral models and routing."""
        # Validate routing
        routing_errors = self.config.validate_routing()
        if routing_errors:
            raise RuntimeError(f"Routing validation failed:\n" + "\n".join(routing_errors))

        # Create simulator for each slot
        for slot_num, slot_config in self.config.slots.items():
            simulator = await self._create_simulator(slot_num, slot_config)
            self.simulators[slot_num] = simulator
            self.instruments[slot_num] = simulator

        # Setup routing (future enhancement)
        await self._setup_routing()

        self._setup_complete = True

    async def _create_simulator(self, slot_num: int, slot_config) -> Any:
        """Create behavioral model for slot."""
        instrument_type = slot_config.instrument

        if instrument_type == 'Oscilloscope':
            from .simulators.oscilloscope import OscilloscopeSimulator
            return OscilloscopeSimulator(self.dut, slot_config.settings)

        elif instrument_type == 'CloudCompile':
            # CloudCompile is pass-through to DUT
            return None

        else:
            raise ValueError(f"Unsupported instrument: {instrument_type}")

    async def _setup_routing(self) -> None:
        """Setup MCC routing (future: full routing matrix)."""
        # Placeholder for routing simulation
        pass

    async def run(self, duration_ms: float) -> dict[str, Any]:
        """Run simulation for specified duration."""
        self.validate_setup()

        duration_ns = int(duration_ms * 1_000_000)

        # Start all simulator tasks
        for slot_num, simulator in self.simulators.items():
            if simulator is not None:
                task = cocotb.start_soon(simulator.run(duration_ns))
                self.tasks.append(task)

        # Wait for duration
        await Timer(duration_ns, units='ns')

        # Collect data
        data = {}
        for slot_num, simulator in self.simulators.items():
            if simulator is not None and hasattr(simulator, 'get_data'):
                data[slot_num] = simulator.get_data()

        return data

    def get_instrument(self, slot_or_name: int | str) -> Any:
        """Get simulator by slot number or instrument type."""
        if isinstance(slot_or_name, int):
            if slot_or_name not in self.simulators:
                raise KeyError(f"No instrument in slot {slot_or_name}")
            return self.simulators[slot_or_name]

        elif isinstance(slot_or_name, str):
            for slot_num, slot_config in self.config.slots.items():
                if slot_config.instrument == slot_or_name:
                    return self.simulators[slot_num]
            raise KeyError(f"No instrument of type '{slot_or_name}' found")

        else:
            raise TypeError(f"slot_or_name must be int or str")

    async def teardown(self) -> None:
        """Clean up simulation resources."""
        for task in self.tasks:
            if not task.done():
                task.kill()
        self.tasks.clear()
```

---

#### Step 3.3: Update `tests/moku_platform_simulator/hardware.py`

**Major changes**:
1. Import `MokuPlatformConfig` and `BenchBench`
2. Constructor accepts BOTH config and bench
3. Use `bench.moku.ip_address` for connection
4. Use `config.validate_routing()` instead of old method

```python
"""
Hardware Backend

MCC API-based hardware backend for deploying to real Moku devices.
"""

from typing import Any
import time
from .backend import Backend
from models.moku.platform_config import MokuPlatformConfig
from models.bench.benchbench import BenchBench

# Moku API imports (same as before)
try:
    from moku.instruments import MultiInstrument, CloudCompile, Oscilloscope
    # ... (rest of imports)
    MOKU_AVAILABLE = True
except ImportError:
    MOKU_AVAILABLE = False
    MultiInstrument = Any
    CloudCompile = Any
    Oscilloscope = Any


class HardwareBackend(Backend):
    """
    Hardware backend using Moku MCC MultiInstrument Mode API.

    Deploys MokuPlatformConfig to real Moku hardware.
    """

    def __init__(self, config: MokuPlatformConfig, bench: BenchBench):
        """
        Initialize hardware backend.

        Args:
            config: MokuPlatformConfig instance (what to deploy)
            bench: BenchBench instance (where to deploy - has IP address)
        """
        super().__init__(config)

        if not MOKU_AVAILABLE:
            raise ImportError("Moku Python API not available. Install: uv add moku")

        self.bench = bench
        self.ip_address = bench.get_moku_ip()

        if not self.ip_address:
            raise ValueError(f"Bench {bench.bench_id} has no Moku IP address")

        # Determine platform_id from Moku model
        platform_map = {'Moku:Go': 2, 'Moku:Lab': 1, 'Moku:Pro': 3}
        self.platform_id = platform_map.get(bench.moku.name, 2)

        self.multi_instrument = None

        # Instrument class mapping (same as before)
        self.instrument_classes = {
            'Oscilloscope': Oscilloscope,
            'CloudCompile': CloudCompile,
            # ... (rest)
        }

    async def setup(self) -> None:
        """Setup hardware: connect, deploy instruments, configure routing."""
        print(f"[HardwareBackend] Connecting to {self.bench.moku} at {self.ip_address}...")

        # Connect to Moku
        try:
            self.multi_instrument = MultiInstrument(
                self.ip_address,
                platform_id=self.platform_id,
                force_connect=True
            )
            print(f"[HardwareBackend] ✓ Connected (platform_id={self.platform_id})")
        except Exception as e:
            raise ConnectionError(f"Failed to connect to {self.ip_address}: {e}")

        # Validate routing
        routing_errors = self.config.validate_routing()
        if routing_errors:
            raise ValueError(f"Routing validation failed:\n" + "\n".join(routing_errors))

        # Deploy instruments to slots
        print("[HardwareBackend] Deploying instruments...")
        for slot_num, slot_config in self.config.slots.items():
            await self._deploy_instrument(slot_num, slot_config)

        # Setup routing
        print("[HardwareBackend] Configuring MCC routing...")
        await self._setup_routing()

        # Apply control registers
        print("[HardwareBackend] Applying control registers...")
        await self._apply_control_registers()

        self._setup_complete = True
        print("[HardwareBackend] ✓ Setup complete!")

    # Rest of methods stay mostly the same, just update references:
    # - self.config instead of old BenchConfig
    # - Use routing list directly

    async def _setup_routing(self) -> None:
        """Establish MCC routing."""
        if not self.config.routing:
            return

        # Convert to MCC format
        mcc_connections = [conn.to_dict() for conn in self.config.routing]

        try:
            self.multi_instrument.set_connections(connections=mcc_connections)
            print(f"  ✓ Configured {len(mcc_connections)} connections")
        except Exception as e:
            raise RuntimeError(f"Failed to configure routing: {e}")

    # ... (rest of methods similar to before)
```

---

### Phase 4: Update Visualization (30 mins)

#### Update `tests/moku_platform_simulator/visualization.py`

Replace references to old `BenchConfig` with `MokuPlatformConfig`:

```python
"""
Diagram Generation for Moku Platform Configuration
"""

from models.moku.platform_config import MokuPlatformConfig


def generate_summary(config: MokuPlatformConfig) -> str:
    """Generate human-readable summary."""
    lines = []
    lines.append("Moku Platform Configuration Summary")
    lines.append("=" * 40)
    lines.append(f"Platform: {config.platform.name}")
    lines.append(f"Slots configured: {len(config.slots)}")
    lines.append(f"Routing connections: {len(config.routing)}")
    lines.append("")

    # List instruments
    if config.slots:
        lines.append("Instruments:")
        for slot_num, slot in sorted(config.slots.items()):
            lines.append(f"  - Slot {slot_num}: {slot.instrument}")

    # Validation
    routing_errors = config.validate_routing()
    if routing_errors:
        lines.append("\n⚠️  Validation Errors:")
        for err in routing_errors:
            lines.append(f"  - {err}")
    else:
        lines.append("\n✓ Configuration valid")

    return "\n".join(lines)

# Similar updates for generate_ascii_diagram() and generate_mermaid_diagram()
```

---

### Phase 5: Update __init__.py Exports (10 mins)

#### Update `tests/moku_platform_simulator/__init__.py`

```python
"""
Moku Platform Simulator

Lightweight Moku platform simulator for CocotB testing.

Enables "train like you fight" workflow:
- Same configuration for simulation and hardware
- Test multi-module interactions in simulation
- Deploy identical config to real Moku

Components:
- Backend: Abstract interface for sim/hardware
- SimulationBackend: CocotB behavioral models
- HardwareBackend: Real Moku deployment via MCC API
- Simulators: Behavioral models (oscilloscope, etc.)
"""

from models.moku.platform_config import MokuPlatformConfig, SlotConfig
from models.moku.platforms.moku_go import MokuGoPlatform, MOKU_GO_PLATFORM
from models.moku.routing import MokuConnection

from .backend import Backend
from .simulation import SimulationBackend
from .hardware import HardwareBackend
from .visualization import (
    generate_ascii_diagram,
    generate_mermaid_diagram,
    generate_summary,
)

__all__ = [
    # Configuration models
    'MokuPlatformConfig',
    'SlotConfig',
    'MokuConnection',
    # Platform models
    'MokuGoPlatform',
    'MOKU_GO_PLATFORM',
    # Backend classes
    'Backend',
    'SimulationBackend',
    'HardwareBackend',
    # Visualization
    'generate_ascii_diagram',
    'generate_mermaid_diagram',
    'generate_summary',
]
```

---

### Phase 6: Archive Old Config (5 mins)

```bash
mkdir -p archive/
git mv tests/moku_platform_simulator/config.py archive/bench_config_old.py
git add archive/bench_config_old.py
```

Add note in archive:
```python
# archive/bench_config_old.py
"""
OLD BenchConfig - ARCHIVED

Replaced by:
- models/moku/platform_config.py (MokuPlatformConfig)
- models/bench/benchbench.py (BenchBench for physical benches)

Date archived: 2025-10-24
Reason: Split into validated models with clear separation:
  - Physical bench reality (BenchBench)
  - Platform deployment config (MokuPlatformConfig)
"""
```

---

### Phase 7: Update Example Tests (30 mins)

Create example showing new pattern:

**File**: `tests/examples/test_moku_platform_example.py`

```python
"""
Example: Using Moku Platform Simulator

Demonstrates "train like you fight" workflow:
1. Define platform configuration
2. Test in simulation (CocotB)
3. Deploy to hardware (same config!)
"""

import cocotb
from cocotb.triggers import Timer
from tests.moku_platform_simulator import (
    MokuPlatformConfig,
    SlotConfig,
    MokuConnection,
    SimulationBackend,
    HardwareBackend,
    MOKU_GO_PLATFORM,
)
from models.bench.benchbench import BenchBench
from tests.conftest import setup_clock, reset_active_low


# Define platform configuration (works for BOTH sim and hardware!)
PLATFORM_CONFIG = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,
    slots={
        1: SlotConfig(
            instrument='CloudCompile',
            bitstream='../modules/SimpleCounter/latest/bitstream.tar'
        ),
        2: SlotConfig(
            instrument='Oscilloscope',
            settings={'sample_rate': 1e6, 'channels': ['count_out']}
        )
    },
    routing=[
        MokuConnection(source='Input1', destination='Slot1InA'),
        MokuConnection(source='Slot1OutA', destination='Slot2InA'),  # Counter → Scope
    ],
    metadata={'test': 'counter_verification'}
)


@cocotb.test()
async def test_counter_simulation(dut):
    """Test counter using simulation backend."""
    dut._log.info("Testing with SimulationBackend...")

    # Create simulation backend
    sim = SimulationBackend(config=PLATFORM_CONFIG, dut=dut)
    await sim.setup()

    # Run simulation
    data = await sim.run(duration_ms=10)

    # Get oscilloscope data
    scope = sim.get_instrument('Oscilloscope')
    scope_data = scope.get_data()

    dut._log.info(f"Captured {len(scope_data['count_out']['values'])} samples")
    assert scope.verify_incrementing('count_out', start_sample=10, count=10)

    await sim.teardown()
    dut._log.info("✓ Simulation test PASSED")


async def test_counter_hardware():
    """
    Test counter on real Moku hardware (same config!).

    Note: This is NOT a cocotb.test - run separately with pytest.
    """
    # Define physical bench
    bench = BenchBench(
        bench_id='B106',
        moku=MokuGoPlatform(ip_address='192.168.73.1', device_name='MokuB106'),
        # ... physical wiring, PDU, etc.
    )

    # Create hardware backend (same config as simulation!)
    hw = HardwareBackend(config=PLATFORM_CONFIG, bench=bench)
    await hw.setup()

    # Run on hardware
    data = await hw.run(duration_ms=10)

    # Get oscilloscope data (same API as simulation!)
    scope = hw.get_instrument('Oscilloscope')
    scope_data = scope.get_data()

    print(f"Captured {len(scope_data['ch1'])} samples from real Moku")

    await hw.teardown()
    print("✓ Hardware test PASSED")
```

---

### Phase 8: Update Documentation (20 mins)

#### Update `tests/README.md`

Add section:
```markdown
## Moku Platform Simulator

The `moku_platform_simulator/` directory provides a lightweight Moku platform
simulator for CocotB testing. This enables "train like you fight" workflow:

**Same configuration works for both simulation and hardware!**

### Example Usage

\`\`\`python
from tests.moku_platform_simulator import (
    MokuPlatformConfig, SimulationBackend, HardwareBackend
)

# Define platform config
config = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,
    slots={1: SlotConfig(instrument='CloudCompile', ...)},
    routing=[...]
)

# Simulation
sim = SimulationBackend(config, dut=dut)
await sim.setup()
sim_data = await sim.run(10)

# Hardware (same config!)
hw = HardwareBackend(config, bench=bench_b106)
await hw.setup()
hw_data = await hw.run(10)
\`\`\`

See `examples/test_moku_platform_example.py` for complete example.
```

---

## Validation Checklist

After migration, verify:

- [ ] `models/moku/platform_config.py` created with `MokuPlatformConfig`
- [ ] `tests/bench_framework/` renamed to `tests/moku_platform_simulator/`
- [ ] All imports updated throughout codebase
- [ ] Backend classes accept `MokuPlatformConfig`
- [ ] `HardwareBackend` accepts `BenchBench` for IP address
- [ ] Visualization functions updated
- [ ] Old `config.py` moved to `archive/`
- [ ] `__init__.py` exports updated
- [ ] Example test created
- [ ] Documentation updated
- [ ] All existing tests still pass
- [ ] `git status` shows clean refactor

---

## Testing Strategy

### Test Existing Tests Still Work

```bash
# Test simulation backend
cd tests/
uv run make TEST_MODULE=clk_divider_core

# Test existing bench_framework tests (if any)
uv run python test_bench_framework_poc.py
```

### Test New Example

```bash
# Run new example test
uv run pytest examples/test_moku_platform_example.py -v
```

---

## Rollback Plan

If something goes wrong:

```bash
# Rollback to tagged commit
git reset --hard v0.2-validated-models

# Or if partially complete, just checkout files:
git checkout main -- tests/bench_framework/
git checkout main -- models/moku/
```

---

## Estimated Time

- **Phase 1**: Create models - 30 mins
- **Phase 2**: Rename directory - 5 mins
- **Phase 3**: Update backends - 45 mins
- **Phase 4**: Update visualization - 30 mins
- **Phase 5**: Update exports - 10 mins
- **Phase 6**: Archive old config - 5 mins
- **Phase 7**: Example tests - 30 mins
- **Phase 8**: Documentation - 20 mins

**Total**: ~2.5-3 hours

---

## Success Criteria

✅ All old tests pass
✅ New example test works
✅ Same config works for sim and hardware
✅ Clean git history (squash before merge)
✅ Documentation updated
✅ No references to old `BenchConfig` remain

---

## Notes

- Keep commits atomic (one phase = one commit)
- Test after each phase
- Update this document if you discover issues
- Celebrate when done! 🎉

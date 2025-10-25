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
        # Cancel all running tasks
        for task in self.tasks:
            if not task.done():
                task.kill()
        self.tasks.clear()

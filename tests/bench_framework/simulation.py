"""
Simulation Backend

CocotB-based simulation backend using behavioral instrument models.
Routes signals between simulators and DUT, runs concurrent tasks.
"""

from typing import Any, Dict, Union, Optional
import cocotb
from cocotb.triggers import Timer
from .backend import Backend
from .config import BenchConfig


class SimulationBackend(Backend):
    """
    Simulation backend using CocotB and behavioral instrument models.

    Instantiates instrument simulators, manages signal routing,
    and runs all instruments as concurrent CocotB tasks.
    """

    def __init__(self, config: BenchConfig, dut: Any):
        """
        Initialize simulation backend.

        Args:
            config: BenchConfig instance
            dut: CocotB DUT (Device Under Test) handle
        """
        super().__init__(config)
        self.dut = dut
        self.simulators: Dict[int, Any] = {}
        self.tasks: list = []

    @classmethod
    def from_config(cls, config: Union[BenchConfig, str, Dict], dut: Any) -> 'SimulationBackend':
        """
        Create SimulationBackend from config file, dict, or BenchConfig.

        Args:
            config: BenchConfig instance, path to config file, or config dict
            dut: CocotB DUT handle

        Returns:
            SimulationBackend instance
        """
        if isinstance(config, str):
            # TODO: Load from file path in Phase 2
            raise NotImplementedError("Loading from file not implemented in Phase 1")
        elif isinstance(config, dict):
            config = BenchConfig.from_dict(config)
        elif not isinstance(config, BenchConfig):
            raise TypeError(f"config must be BenchConfig, str, or dict, got {type(config)}")

        return cls(config, dut)

    async def setup(self) -> None:
        """
        Setup simulation backend: create simulators and establish routing.

        Creates instrument simulator instances for each slot and
        configures signal routing between simulators and DUT.
        """
        # Validate connections before setup
        connection_errors = self.config.validate_connections()
        if connection_errors:
            raise RuntimeError(f"Connection validation failed:\n" + "\n".join(connection_errors))

        # Create simulator for each slot
        for slot_num, slot_config in self.config.slots.items():
            simulator = await self._create_simulator(slot_num, slot_config)
            self.simulators[slot_num] = simulator
            self.instruments[slot_num] = simulator

        # Establish signal routing
        await self._setup_routing()

        self._setup_complete = True

    async def _create_simulator(self, slot_num: int, slot_config) -> Any:
        """
        Create simulator instance for given slot configuration.

        Args:
            slot_num: Slot number
            slot_config: SlotConfig instance

        Returns:
            Simulator instance

        Raises:
            ValueError: If instrument type not supported
        """
        instrument_type = slot_config.instrument

        if instrument_type == 'Oscilloscope':
            from .simulators.oscilloscope import OscilloscopeSimulator
            return OscilloscopeSimulator(self.dut, slot_config.settings)

        elif instrument_type == 'CloudCompile':
            # CloudCompile is a pass-through to DUT (no simulation model needed for Phase 1)
            return None

        else:
            raise ValueError(f"Unsupported instrument type: {instrument_type} (Phase 1 supports: Oscilloscope, CloudCompile)")

    async def _setup_routing(self) -> None:
        """
        Establish signal routing between simulators and DUT.

        For Phase 1 PoC: Simple routing for counter -> oscilloscope.
        Phase 2 will implement full routing matrix.
        """
        # Phase 1: Minimal routing logic
        # This will be expanded in Phase 2 to handle all connection types
        for connection in self.config.connections:
            # For now, just validate that connections are well-formed
            # Actual signal routing will be done in instrument simulators
            pass

    async def run(self, duration_ms: float) -> Dict[str, Any]:
        """
        Run simulation for specified duration.

        Args:
            duration_ms: Duration in milliseconds

        Returns:
            Dictionary mapping slot numbers to instrument data
        """
        self.validate_setup()

        # Convert duration to simulation time units (nanoseconds)
        duration_ns = int(duration_ms * 1_000_000)

        # Start all simulator tasks
        for slot_num, simulator in self.simulators.items():
            if simulator is not None:
                task = cocotb.start_soon(simulator.run(duration_ns))
                self.tasks.append(task)

        # Wait for simulation duration
        await Timer(duration_ns, units='ns')

        # Collect data from all simulators
        data = {}
        for slot_num, simulator in self.simulators.items():
            if simulator is not None and hasattr(simulator, 'get_data'):
                data[slot_num] = simulator.get_data()

        return data

    def get_instrument(self, slot_or_name: Union[int, str]) -> Any:
        """
        Get simulator instance by slot number or instrument type.

        Args:
            slot_or_name: Slot number (int) or instrument type name (str)

        Returns:
            Simulator instance

        Raises:
            KeyError: If slot/instrument not found
        """
        if isinstance(slot_or_name, int):
            if slot_or_name not in self.simulators:
                raise KeyError(f"No instrument in slot {slot_or_name}")
            return self.simulators[slot_or_name]

        elif isinstance(slot_or_name, str):
            # Search by instrument type name
            for slot_num, slot_config in self.config.slots.items():
                if slot_config.instrument == slot_or_name:
                    return self.simulators[slot_num]
            raise KeyError(f"No instrument of type '{slot_or_name}' found")

        else:
            raise TypeError(f"slot_or_name must be int or str, got {type(slot_or_name)}")

    async def teardown(self) -> None:
        """Clean up simulation resources."""
        # Cancel all running tasks
        for task in self.tasks:
            if not task.done():
                task.kill()
        self.tasks.clear()

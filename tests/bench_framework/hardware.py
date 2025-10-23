"""
Hardware Backend (Phase 3)

MCC API-based hardware backend for deploying to real Moku devices.
Phase 1: Stub implementation for architecture validation.
Phase 3: Full implementation with MultiInstrument API.
"""

from typing import Any, Dict, Union
from .backend import Backend
from .config import BenchConfig


class HardwareBackend(Backend):
    """
    Hardware backend using Moku MCC Multi-Instrument Mode API.

    Phase 1: Stub implementation (raises NotImplementedError)
    Phase 3: Will implement:
    - MultiInstrument API integration
    - Bitstream deployment to CloudCompile slots
    - Real-time data collection from instruments
    - Connection validation and setup
    """

    def __init__(self, config: BenchConfig, ip_address: str):
        """
        Initialize hardware backend.

        Args:
            config: BenchConfig instance
            ip_address: IP address of Moku device (e.g., '192.168.1.100')
        """
        super().__init__(config)
        self.ip_address = ip_address
        self.moku_connection = None
        self.multi_instrument = None

    @classmethod
    def from_config(cls, config: Union[BenchConfig, str, Dict], ip_address: str) -> 'HardwareBackend':
        """
        Create HardwareBackend from config.

        Args:
            config: BenchConfig instance, path to config file, or config dict
            ip_address: IP address of Moku device

        Returns:
            HardwareBackend instance
        """
        if isinstance(config, str):
            raise NotImplementedError("Loading from file not implemented in Phase 1")
        elif isinstance(config, dict):
            config = BenchConfig.from_dict(config)
        elif not isinstance(config, BenchConfig):
            raise TypeError(f"config must be BenchConfig, str, or dict, got {type(config)}")

        return cls(config, ip_address)

    async def setup(self) -> None:
        """
        Setup hardware backend (Phase 3).

        Phase 3 will implement:
        1. Connect to Moku device via IP
        2. Initialize MultiInstrument mode
        3. Deploy instruments to slots (including CloudCompile bitstreams)
        4. Configure signal routing via set_connections()
        5. Apply instrument settings

        Raises:
            NotImplementedError: Phase 1 stub
        """
        raise NotImplementedError(
            "HardwareBackend.setup() will be implemented in Phase 3.\n"
            "Phase 1 focuses on simulation backend and architecture validation."
        )

    async def run(self, duration_ms: float) -> Dict[str, Any]:
        """
        Run hardware testbench (Phase 3).

        Args:
            duration_ms: Duration to run in milliseconds

        Returns:
            Dictionary containing data from all instruments

        Raises:
            NotImplementedError: Phase 1 stub
        """
        raise NotImplementedError(
            "HardwareBackend.run() will be implemented in Phase 3.\n"
            "Use SimulationBackend for Phase 1 proof of concept."
        )

    def get_instrument(self, slot_or_name: Union[int, str]) -> Any:
        """
        Get hardware instrument instance (Phase 3).

        Args:
            slot_or_name: Slot number or instrument type name

        Returns:
            Moku instrument API object

        Raises:
            NotImplementedError: Phase 1 stub
        """
        raise NotImplementedError(
            "HardwareBackend.get_instrument() will be implemented in Phase 3.\n"
            "This will return Moku instrument API objects for hardware control."
        )

    async def teardown(self) -> None:
        """
        Clean up hardware resources (Phase 3).

        Phase 3 will implement:
        - Stop all instruments
        - Release Moku device connection
        - Clean up temporary files (bitstreams)

        Raises:
            NotImplementedError: Phase 1 stub
        """
        raise NotImplementedError(
            "HardwareBackend.teardown() will be implemented in Phase 3."
        )

    def deploy_bitstream(self, slot_num: int, bitstream_path: str) -> None:
        """
        Deploy CloudCompile bitstream to slot (Phase 3).

        Args:
            slot_num: Target slot number
            bitstream_path: Path to .tar.gz bitstream file

        Raises:
            NotImplementedError: Phase 1 stub
        """
        raise NotImplementedError(
            "Bitstream deployment will be implemented in Phase 3.\n"
            "This will use Moku CloudCompile API to deploy custom VHDL modules."
        )

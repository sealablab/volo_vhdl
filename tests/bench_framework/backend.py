"""
Backend Abstract Base Class

Defines the interface for both simulation and hardware backends.
All backends must implement setup(), run(), and get_instrument() methods.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Union
from .config import BenchConfig


class Backend(ABC):
    """
    Abstract base class for testbench backends.

    Provides unified interface for both simulation (CocotB + GHDL) and
    hardware (Moku device via MCC API) backends.
    """

    def __init__(self, config: BenchConfig):
        """
        Initialize backend with configuration.

        Args:
            config: BenchConfig instance defining the testbench setup
        """
        self.config = config
        self.instruments: Dict[int, Any] = {}  # Slot number -> instrument instance
        self._setup_complete = False

    @abstractmethod
    async def setup(self) -> None:
        """
        Configure and initialize all instruments and connections.

        This method must:
        1. Create/deploy instruments in configured slots
        2. Establish signal routing connections
        3. Initialize instrument settings
        4. Prepare for data collection

        Raises:
            RuntimeError: If setup fails
        """
        pass

    @abstractmethod
    async def run(self, duration_ms: float) -> Dict[str, Any]:
        """
        Run the configured testbench for specified duration.

        Args:
            duration_ms: Duration to run in milliseconds

        Returns:
            Dictionary containing collected data from all instruments

        Raises:
            RuntimeError: If run() called before setup()
        """
        pass

    @abstractmethod
    def get_instrument(self, slot_or_name: Union[int, str]) -> Any:
        """
        Get instrument instance by slot number or instrument type name.

        Args:
            slot_or_name: Slot number (int) or instrument type (str)

        Returns:
            Instrument instance (simulator or hardware API object)

        Raises:
            KeyError: If slot/instrument not found
        """
        pass

    def validate_setup(self) -> None:
        """
        Validate that setup() has been called.

        Raises:
            RuntimeError: If setup not complete
        """
        if not self._setup_complete:
            raise RuntimeError("Backend setup() must be called before run()")

    async def teardown(self) -> None:
        """
        Clean up resources (optional, may be overridden).

        Default implementation does nothing. Backends can override
        to release hardware resources, close connections, etc.
        """
        pass

    def __repr__(self) -> str:
        """String representation for debugging."""
        platform_name = self.config.platform.get('name', 'Unknown')
        slot_count = len(self.config.slots)
        return f"{self.__class__.__name__}(platform={platform_name}, slots={slot_count})"

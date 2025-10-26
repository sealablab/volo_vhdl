"""
Backend Abstract Base Class

Defines interface for Moku platform simulation and hardware deployment.
"""

from abc import ABC, abstractmethod
from typing import Any
from moku_models.platform_config import MokuPlatformConfig


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
    async def run(self, duration_ms: float) -> dict[str, Any]:
        """Run configured platform for specified duration."""
        pass

    @abstractmethod
    def get_instrument(self, slot_or_name: int | str) -> Any:
        """Get instrument instance by slot number or type name."""
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
        """Clean up resources (optional override)."""
        pass

    def __repr__(self) -> str:
        platform_name = self.config.platform.name
        slot_count = len(self.config.slots)
        return f"{self.__class__.__name__}(platform={platform_name}, slots={slot_count})"

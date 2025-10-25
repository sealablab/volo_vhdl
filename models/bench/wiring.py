"""
Physical Wiring Models

Models for representing physical cable connections between devices and Moku platform.
Includes validation to catch wiring errors at config time instead of runtime.

Key Validation:
- Direction matching: Moku inputs must connect to device outputs (and vice versa)
- Signal existence: Signal names must exist on the device
- Future: Impedance matching, voltage compatibility
"""

from typing import Literal
from pydantic import BaseModel, Field, field_validator, model_validator
from models.device_catalog import get_device
import warnings


class WiredDevice(BaseModel):
    """
    Physical device wired to a Moku port.

    Represents a single cable connection:
    - Device signal → Moku physical port

    Validation:
    - Moku INPUT ports (IN1, IN2) must connect to device OUTPUT signals
    - Moku OUTPUT ports (OUT1, OUT2, DACOut1) must connect to device INPUT signals
    - Signal name must exist on device (if device is in catalog)

    Attributes:
        device: Device identifier (e.g., 'DS1120A')
        signal: Signal name on device (e.g., 'coil_current', 'digital_glitch')
        notes: Optional wiring notes

    Example:
        >>> # DS1120A.coil_current (Output) → Moku IN1 (Input) ✓
        >>> wired = WiredDevice(device='DS1120A', signal='coil_current')
        >>> wired.validate_direction('IN1')  # Pass: Output→Input

        >>> # DS1120A.coil_current (Output) → Moku OUT1 (Output) ✗
        >>> wired.validate_direction('OUT1')  # Error: Output→Output invalid
    """

    device: str = Field(..., description="Device identifier (e.g., 'DS1120A')")
    signal: str = Field(..., description="Signal name on device")
    notes: str | None = Field(default=None, description="Optional wiring notes")

    def validate_direction(self, moku_port: str) -> None:
        """
        Validate signal direction matches Moku port direction.

        Args:
            moku_port: Moku port name (e.g., 'IN1', 'OUT1', 'DACOut1')

        Raises:
            ValueError: If direction mismatch or signal not found
        """
        # Determine Moku port direction
        moku_port_direction = self._get_moku_port_direction(moku_port)

        # Get device model from catalog
        device_model = get_device(self.device)

        if device_model is None:
            # Unknown device - warn but don't fail
            warnings.warn(
                f"Device '{self.device}' not in catalog, skipping validation. "
                f"Consider adding to models/device_catalog.py or using DummyProbe."
            )
            return

        # Validate direction matching
        if moku_port_direction == 'input':
            # Moku input needs device output
            signal_obj = device_model.get_output(self.signal)
            if signal_obj is None:
                available = [o.name for o in device_model.outputs]
                raise ValueError(
                    f"Wiring error: Cannot wire to Moku input port '{moku_port}'.\n"
                    f"  Device '{self.device}' has no OUTPUT signal '{self.signal}'.\n"
                    f"  Available outputs: {available}\n"
                    f"  Hint: Moku INPUT ports read signals FROM devices (device outputs)."
                )
        elif moku_port_direction == 'output':
            # Moku output needs device input
            signal_obj = device_model.get_input(self.signal)
            if signal_obj is None:
                available = [i.name for i in device_model.inputs]
                raise ValueError(
                    f"Wiring error: Cannot wire to Moku output port '{moku_port}'.\n"
                    f"  Device '{self.device}' has no INPUT signal '{self.signal}'.\n"
                    f"  Available inputs: {available}\n"
                    f"  Hint: Moku OUTPUT ports drive signals TO devices (device inputs)."
                )
        else:
            # Unknown port type - warn
            warnings.warn(f"Unknown Moku port type '{moku_port}', skipping direction validation")

    def _get_moku_port_direction(self, moku_port: str) -> Literal['input', 'output', 'unknown']:
        """
        Infer Moku port direction from port name.

        Args:
            moku_port: Moku port name (e.g., 'IN1', 'OUT1', 'DACOut1')

        Returns:
            'input', 'output', or 'unknown'
        """
        port_upper = moku_port.upper()

        # Input patterns
        if port_upper.startswith('IN') and not port_upper.startswith('INPUT'):
            return 'input'  # IN1, IN2
        if port_upper.startswith('INPUT'):
            return 'input'  # InputA, Input1

        # Output patterns
        if port_upper.startswith('OUT'):
            return 'output'  # OUT1, OUT2, OutputA, Output1
        if port_upper.startswith('DAC'):
            return 'output'  # DACOut1, DACOut2

        # DIO could be either - treat as unknown
        if port_upper.startswith('DIO'):
            return 'unknown'

        return 'unknown'

    def get_device_model(self):
        """Get the device model instance from catalog (if available)."""
        return get_device(self.device)

    def __str__(self) -> str:
        """Human-readable representation."""
        return f"{self.device}.{self.signal}"


class PhysicalWiring(BaseModel):
    """
    Complete physical wiring map for a bench.

    Maps Moku physical ports to wired devices. Validates all connections
    to ensure proper signal flow direction.

    Attributes:
        connections: Dict mapping Moku port → WiredDevice

    Example:
        >>> wiring = PhysicalWiring(connections={
        ...     'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        ...     'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch'),
        ...     'DACOut1': WiredDevice(device='DS1120A', signal='pulse_amplitude')
        ... })
        >>> wiring.validate_all()  # Validates all connections
    """

    connections: dict[str, WiredDevice] = Field(
        default_factory=dict,
        description="Moku port → WiredDevice mapping"
    )

    @model_validator(mode='after')
    def validate_all_connections(self):
        """Validate all wiring connections after model creation."""
        for moku_port, wired_device in self.connections.items():
            wired_device.validate_direction(moku_port)
        return self

    def get_wired_device(self, moku_port: str) -> WiredDevice | None:
        """Get device wired to a specific Moku port."""
        return self.connections.get(moku_port)

    def list_wired_ports(self) -> list[str]:
        """List all Moku ports with connections."""
        return list(self.connections.keys())

    def __str__(self) -> str:
        """Human-readable representation."""
        lines = [f"Physical Wiring ({len(self.connections)} connections):"]
        for port, device in self.connections.items():
            lines.append(f"  {port:10s} ← {device}")
        return "\n".join(lines)

"""
Dummy Probe Model

Flexible escape hatch for unknown/custom probes that don't have formal models yet.
Provides the same interface as real probe models (Input/Output/Power) but with
minimal validation.

Use Cases:
- Custom one-off probes
- Third-party hardware without formal specs
- Prototyping new probe integrations
- Quick testing without creating full model

Warning: DummyProbe bypasses validation - use real models when possible!
"""

from typing import Literal
from pydantic import BaseModel, Field
from models.riscure.ds1120a import Input, Output, Power


class DummyProbe(BaseModel):
    """
    Placeholder probe for unknown/custom devices.

    Provides same interface as formal probe models (DS1120A, etc.) but with
    user-defined inputs/outputs. Minimal validation - use with caution!

    Attributes:
        vendor: Vendor name (or 'Custom')
        model: Model identifier
        category: Device category
        inputs: Input signals (driven by controller)
        outputs: Output signals (read by controller)
        power: Power connections

    Example:
        >>> custom_probe = DummyProbe(
        ...     vendor='Custom',
        ...     model='MyEMFI_v1',
        ...     inputs=[
        ...         Input(name='trigger', connector='SMA', voltage_range='0-5V', impedance='50Ohm', description='Trigger')
        ...     ],
        ...     outputs=[
        ...         Output(name='monitor', connector='SMA', voltage_range='-2V to 0V', impedance='50Ohm', description='Monitor', coupling='AC')
        ...     ]
        ... )
    """

    # Identification
    vendor: str = Field(default='Custom', description="Vendor name")
    model: str = Field(..., description="Model identifier")
    category: str = Field(default='probe', description="Device category")

    # Signals (user-defined)
    inputs: list[Input] = Field(default_factory=list, description="Input signals")
    outputs: list[Output] = Field(default_factory=list, description="Output signals")
    power: list[Power] = Field(default_factory=list, description="Power connections")

    def get_input(self, name: str) -> Input | None:
        """Get input signal by name."""
        return next((i for i in self.inputs if i.name == name), None)

    def get_output(self, name: str) -> Output | None:
        """Get output signal by name."""
        return next((o for o in self.outputs if o.name == name), None)

    def get_power(self, name: str) -> Power | None:
        """Get power connection by name."""
        return next((p for p in self.power if p.name == name), None)

    def __str__(self) -> str:
        """Human-readable representation."""
        return f"{self.vendor} {self.model} (DummyProbe): {len(self.inputs)}IN/{len(self.outputs)}OUT"

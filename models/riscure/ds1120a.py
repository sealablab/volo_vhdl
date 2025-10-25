"""
Riscure DS1120A - EMFI Probe Model (Unidirectional)

Physical interface model for the Riscure DS1120A electromagnetic fault injection probe.
This model captures the electrical and physical characteristics needed for bench
configuration and signal routing.

References:
- Serena memory: riscure_ds1120a.md
- Datasheet: docs/datasheets/DS1120A_DS1121A_datasheet.pdf
"""

from typing import Literal
from pydantic import BaseModel, Field


class Input(BaseModel):
    """
    Input signal driven by external controller (Moku, etc.).

    Attributes:
        name: Signal name (e.g., 'digital_glitch', 'pulse_amplitude')
        connector: Physical connector type
        voltage_range: Voltage range
        impedance: Electrical impedance
        description: Signal function description
    """
    name: str = Field(..., description="Signal name")
    connector: Literal['SMA', 'BNC'] = Field(..., description="Physical connector type")
    voltage_range: str = Field(..., description="Voltage range (e.g., '0-3.3V')")
    impedance: str = Field(..., description="Electrical impedance (e.g., '50Ohm')")
    description: str = Field(..., description="Signal function description")


class Output(BaseModel):
    """
    Output signal read by external controller (Moku scope, etc.).

    Attributes:
        name: Signal name (e.g., 'coil_current')
        connector: Physical connector type
        voltage_range: Voltage range
        impedance: Electrical impedance
        description: Signal function description
        coupling: Recommended coupling (AC/DC)
    """
    name: str = Field(..., description="Signal name")
    connector: Literal['SMA', 'BNC'] = Field(..., description="Physical connector type")
    voltage_range: str = Field(..., description="Voltage range (e.g., '-1.4V to 0V')")
    impedance: str = Field(..., description="Electrical impedance (e.g., '50Ohm')")
    description: str = Field(..., description="Signal function description")
    coupling: Literal['AC', 'DC', 'either'] = Field(default='AC', description="Recommended coupling")


class Power(BaseModel):
    """
    Power supply connection (not a signal).

    Attributes:
        name: Power rail name (e.g., 'power_24vdc')
        connector: Physical connector type
        voltage_range: Voltage range
        description: Power supply description
        polarity: Connector polarity (for barrel jacks)
    """
    name: str = Field(..., description="Power rail name")
    connector: Literal['barrel_jack', 'screw_terminal', 'molex'] = Field(..., description="Physical connector type")
    voltage_range: str = Field(..., description="Voltage range (e.g., '24-450V DC')")
    description: str = Field(..., description="Power supply description")
    polarity: str | None = Field(default=None, description="Connector polarity (e.g., 'center-positive')")


class ProbeTip(BaseModel):
    """
    Interchangeable EM probe tip specification.

    Attributes:
        tip_type: Tip type identifier
        diameter_mm: Tip diameter in millimeters
        polarity: Tip polarity variant
        max_current_a: Maximum coil current in amperes
        use_case: Recommended use case
    """
    tip_type: str = Field(..., description="Tip type identifier (e.g., 'small', 'large')")
    diameter_mm: float = Field(..., description="Tip diameter in millimeters")
    polarity: Literal['positive', 'negative', 'n/a'] = Field(..., description="Tip polarity")
    max_current_a: int = Field(..., description="Maximum coil current in amperes")
    use_case: str = Field(..., description="Recommended use case")


class DS1120A(BaseModel):
    """
    Riscure DS1120A EMFI Probe - Physical Interface Model.

    High-power unidirectional electromagnetic fault injection probe for hardware
    security testing. All control and monitoring done through external controller
    (Moku, Riscure Spider, etc.).

    Physical Characteristics:
    - 3 SMA signal connectors (2 inputs, 1 output)
    - 1 barrel jack power connector
    - Interchangeable probe tips (SMA threaded mount)
    - Fixed 50ns pulse width (hardware-determined)

    Attributes:
        vendor: Manufacturer name
        model: Model number
        category: Device category
        variant: Probe variant (unidirectional vs bidirectional)
        inputs: Input signals (driven by controller)
        outputs: Output signals (read by controller)
        power: Power supply connections
        available_tips: Interchangeable probe tip options
        pulse_width_ns: Fixed EM pulse width
        max_voltage_v: Maximum voltage over coil
        max_current_a: Maximum internal current
        max_frequency_mhz: Maximum pulse frequency
        operating_temp_c: Operating temperature range

    Example:
        >>> probe = DS1120A()
        >>> print(f"{probe.vendor} {probe.model}")
        Riscure DS1120A
        >>> trigger = probe.get_input('digital_glitch')
        >>> print(f"Trigger: {trigger.voltage_range} via {trigger.connector}")
        Trigger: 0-3.3V TTL via SMA
    """

    # Identification
    vendor: str = Field(default='Riscure', description="Manufacturer name")
    model: str = Field(default='DS1120A', description="Model number")
    category: str = Field(default='emfi_probe', description="Device category")
    variant: str = Field(default='unidirectional', description="Probe variant")

    # Input signals (driven by controller)
    inputs: list[Input] = Field(
        default_factory=lambda: [
            Input(
                name='digital_glitch',
                connector='SMA',
                voltage_range='0-3.3V TTL',
                impedance='50Ohm',
                description='Trigger pulse (rising edge initiates EM glitch)'
            ),
            Input(
                name='pulse_amplitude',
                connector='SMA',
                voltage_range='0-3.3V analog',
                impedance='50Ohm',
                description='Power level control (5-100% linear mapping)'
            ),
        ],
        description="Input signals driven by controller"
    )

    # Output signals (read by controller)
    outputs: list[Output] = Field(
        default_factory=lambda: [
            Output(
                name='coil_current',
                connector='SMA',
                voltage_range='-1.4V to 0V',
                impedance='50Ohm',
                description='Real-time coil current waveform (transient)',
                coupling='AC'
            ),
        ],
        description="Output signals read by controller"
    )

    # Power connections
    power: list[Power] = Field(
        default_factory=lambda: [
            Power(
                name='power_24vdc',
                connector='barrel_jack',
                voltage_range='24-450V DC',
                description='High-voltage power supply (external PSU required)',
                polarity='center-positive'
            ),
        ],
        description="Power supply connections"
    )

    # Interchangeable probe tips
    available_tips: list[ProbeTip] = Field(
        default_factory=lambda: [
            ProbeTip(
                tip_type='small',
                diameter_mm=1.5,
                polarity='positive',
                max_current_a=48,
                use_case='Precision targeting, de-capped chips'
            ),
            ProbeTip(
                tip_type='small',
                diameter_mm=1.5,
                polarity='negative',
                max_current_a=48,
                use_case='Precision targeting, de-capped chips'
            ),
            ProbeTip(
                tip_type='large',
                diameter_mm=4.0,
                polarity='positive',
                max_current_a=56,
                use_case='Higher field strength, packaged chips'
            ),
            ProbeTip(
                tip_type='large',
                diameter_mm=4.0,
                polarity='negative',
                max_current_a=56,
                use_case='Higher field strength, packaged chips'
            ),
        ],
        description="Interchangeable probe tip options"
    )

    # Electrical specifications
    pulse_width_ns: int = Field(default=50, description="Fixed EM pulse width (not adjustable)")
    max_voltage_v: int = Field(default=450, description="Maximum voltage over coil")
    max_current_a: int = Field(default=64, description="Maximum internal current")
    max_frequency_mhz: float = Field(default=1.0, description="Maximum pulse frequency")
    operating_temp_c: tuple[int, int] = Field(default=(0, 70), description="Operating temperature range")

    # Timing characteristics
    propagation_delay_trigger_to_coil_ns: int = Field(
        default=50,
        description="Propagation delay from trigger to coil current"
    )
    propagation_delay_trigger_to_tip_ns: int = Field(
        default=40,
        description="Propagation delay from trigger to EM tip"
    )

    def get_input(self, name: str) -> Input | None:
        """Get input signal by name."""
        return next((i for i in self.inputs if i.name == name), None)

    def get_output(self, name: str) -> Output | None:
        """Get output signal by name."""
        return next((o for o in self.outputs if o.name == name), None)

    def get_power(self, name: str) -> Power | None:
        """Get power connection by name."""
        return next((p for p in self.power if p.name == name), None)

    def get_tip(self, tip_type: str, polarity: Literal['positive', 'negative'] | None = None) -> ProbeTip | None:
        """
        Get probe tip specification.

        Args:
            tip_type: Tip type ('small', 'large', etc.)
            polarity: Optional polarity filter

        Returns:
            ProbeTip if found, None otherwise
        """
        for tip in self.available_tips:
            if tip.tip_type == tip_type:
                if polarity is None or tip.polarity == polarity:
                    return tip
        return None

    def __str__(self) -> str:
        """Human-readable representation."""
        return f"{self.vendor} {self.model} ({self.variant}): {len(self.inputs)}IN/{len(self.outputs)}OUT, {len(self.available_tips)} tips"


# Convenience constant
DS1120A_PROBE = DS1120A()

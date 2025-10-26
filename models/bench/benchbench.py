"""
BenchBench - Physical Bench Configuration

Represents a complete physical test bench setup. The name parallels "TestBench"
(simulation) - one for hardware, one for VHDL simulation.

A BenchBench captures the physical reality of a workbench:
- Moku device with IP address
- Physical wiring (validated against device specs)
- Power distribution
- Target device (DUT)
- Location and metadata

This is distinct from BenchConfig (runtime test configuration) which includes:
- MCC routing
- Instrument slot configurations
- Frontend settings
- Test-specific parameters
"""

from datetime import date
from pydantic import BaseModel, Field
from moku_models.platforms.moku_go import MokuGoPlatform
from models.bench.wiring import PhysicalWiring, WiredDevice
from models.bench.pdu import PDU
from models.bench.dut import DUT


class BenchBench(BaseModel):
    """
    Physical test bench configuration.

    Represents the complete physical setup of a hardware test bench, including
    all devices, wiring, and infrastructure. Changes slowly (weeks/months) as
    hardware is reconfigured.

    Attributes:
        bench_id: Unique bench identifier (e.g., 'B106')
        location: Physical location description
        moku: Moku platform instance (with IP address)
        physical_wiring: Validated wiring map (device signals → Moku ports)
        pdu: Power distribution unit (optional)
        dut: Device under test (optional)
        owner: Primary user/owner
        last_calibration: Last calibration date (optional)
        notes: General notes about the bench

    Example:
        >>> bench = BenchBench(
        ...     bench_id='B106',
        ...     location='Lab 2, Station 3',
        ...     moku=MokuGoPlatform(
        ...         ip_address='192.168.73.1',
        ...         device_name='MokuB106'
        ...     ),
        ...     physical_wiring=PhysicalWiring(connections={
        ...         'IN1': WiredDevice(device='DS1120A', signal='coil_current'),
        ...         'OUT1': WiredDevice(device='DS1120A', signal='digital_glitch'),
        ...         'DACOut1': WiredDevice(device='DS1120A', signal='pulse_amplitude')
        ...     }),
        ...     pdu=PDU(
        ...         vendor='CyberPower',
        ...         model='PDU41001',
        ...         num_ports=8,
        ...         ip_address='192.168.73.10',
        ...         port_assignments={
        ...             1: 'Moku:Go',
        ...             2: 'DS1120A_PSU',
        ...             3: 'DUT_Power'
        ...         }
        ...     ),
        ...     dut=DUT(
        ...         name='STM32F4_decapped',
        ...         description='STM32F407 with package removed'
        ...     ),
        ...     owner='johny'
        ... )
    """

    # Identification
    bench_id: str = Field(..., description="Unique bench identifier (e.g., 'B106')")
    location: str | None = Field(default=None, description="Physical location")

    # Core hardware
    moku: MokuGoPlatform = Field(..., description="Moku platform instance")

    # Physical wiring (validated)
    physical_wiring: PhysicalWiring = Field(
        default_factory=PhysicalWiring,
        description="Validated physical wiring map"
    )

    # Infrastructure
    pdu: PDU | None = Field(default=None, description="Power distribution unit")
    dut: DUT | None = Field(default=None, description="Device under test")

    # Metadata
    owner: str | None = Field(default=None, description="Primary user/owner")
    last_calibration: date | None = Field(default=None, description="Last calibration date")
    notes: str | None = Field(default=None, description="General notes")

    def get_moku_ip(self) -> str | None:
        """Get Moku IP address."""
        return self.moku.ip_address

    def get_wired_device(self, moku_port: str) -> WiredDevice | None:
        """Get device wired to a specific Moku port."""
        return self.physical_wiring.get_wired_device(moku_port)

    def summary(self) -> str:
        """
        Generate human-readable bench summary.

        Returns:
            Multi-line summary string
        """
        lines = [
            f"BenchBench: {self.bench_id}",
            f"  Location: {self.location or 'Not specified'}",
            f"  Moku: {self.moku}",
            f"  Wiring: {len(self.physical_wiring.connections)} connections",
        ]

        if self.physical_wiring.connections:
            for port, device in self.physical_wiring.connections.items():
                lines.append(f"    {port:10s} ← {device}")

        if self.pdu:
            lines.append(f"  PDU: {self.pdu}")

        if self.dut:
            lines.append(f"  DUT: {self.dut}")

        if self.owner:
            lines.append(f"  Owner: {self.owner}")

        return "\n".join(lines)

    def __str__(self) -> str:
        """Compact string representation."""
        return f"BenchBench({self.bench_id} @ {self.location})"


# Convenience function for YAML/dict loading
def load_benchbench(data: dict) -> BenchBench:
    """
    Load BenchBench from dictionary (e.g., from YAML).

    Args:
        data: Dictionary with bench configuration

    Returns:
        BenchBench instance with validated wiring
    """
    return BenchBench(**data)

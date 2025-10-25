"""
Power Distribution Unit (PDU) Model

Represents network-controlled PDUs for bench power management.
"""

from pydantic import BaseModel, Field


class PDU(BaseModel):
    """
    Network-controlled Power Distribution Unit.

    Attributes:
        vendor: PDU manufacturer
        model: PDU model number
        num_ports: Number of controllable outlets
        ip_address: Network address for control
        port_assignments: Optional mapping of port numbers to device names

    Example:
        >>> pdu = PDU(
        ...     vendor='CyberPower',
        ...     model='PDU41001',
        ...     num_ports=8,
        ...     ip_address='192.168.73.10',
        ...     port_assignments={
        ...         1: 'Moku:Go',
        ...         2: 'DS1120A_PSU',
        ...         3: 'DUT_Power'
        ...     }
        ... )
    """

    vendor: str = Field(..., description="PDU manufacturer")
    model: str = Field(..., description="PDU model number")
    num_ports: int = Field(..., description="Number of controllable outlets")
    ip_address: str | None = Field(default=None, description="Network address for control")
    port_assignments: dict[int, str] = Field(
        default_factory=dict,
        description="Mapping of port numbers to device names"
    )

    def get_assignment(self, port: int) -> str | None:
        """Get device assigned to a specific port."""
        return self.port_assignments.get(port)

    def assign_port(self, port: int, device_name: str) -> None:
        """Assign a device to a port."""
        if port < 1 or port > self.num_ports:
            raise ValueError(f"Port {port} out of range (1-{self.num_ports})")
        self.port_assignments[port] = device_name

    def __str__(self) -> str:
        """Human-readable representation."""
        assigned = len(self.port_assignments)
        ip_str = f" @ {self.ip_address}" if self.ip_address else ""
        return f"{self.vendor} {self.model}{ip_str}: {assigned}/{self.num_ports} ports assigned"

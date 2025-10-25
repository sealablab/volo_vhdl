"""
OLD BenchConfig - ARCHIVED

Replaced by:
- models/moku/platform_config.py (MokuPlatformConfig)
- models/bench/benchbench.py (BenchBench for physical benches)

Date archived: 2025-10-24
Reason: Split into validated models with clear separation:
  - Physical bench reality (BenchBench)
  - Platform deployment config (MokuPlatformConfig)

Original docstring below:
---
Bench Configuration Data Models

Pydantic models for declarative multi-instrument testbench configuration.
These models provide type safety, validation, and serialization for both
simulation and hardware backends.
"""

from typing import Dict, List, Any, Optional, Literal
from pydantic import BaseModel, Field, field_validator


# Platform Definitions
MOKU_GO = {
    'name': 'Moku:Go',
    'slots': 2,
    'inputs': ['Input1', 'Input2'],
    'outputs': ['Output1', 'Output2'],
}

MOKU_PRO = {
    'name': 'Moku:Pro',
    'slots': 4,
    'inputs': ['Input1', 'Input2', 'Input3', 'Input4'],
    'outputs': ['Output1', 'Output2', 'Output3', 'Output4'],
}


class SlotConfig(BaseModel):
    """
    Configuration for a single instrument slot.

    Attributes:
        instrument: Instrument type name (e.g., 'WaveformGenerator', 'Oscilloscope', 'CloudCompile')
        settings: Instrument-specific settings dictionary
        control_registers: Optional register values for CloudCompile slots
        bitstream: Optional bitstream path for CloudCompile slots
    """
    instrument: str = Field(..., description="Instrument type name")
    settings: Dict[str, Any] = Field(default_factory=dict, description="Instrument-specific settings")
    control_registers: Optional[Dict[int, int]] = Field(default=None, description="Control register values (CloudCompile)")
    bitstream: Optional[str] = Field(default=None, description="Bitstream path (CloudCompile)")

    @field_validator('instrument')
    @classmethod
    def validate_instrument_name(cls, v: str) -> str:
        """Validate instrument name is non-empty and valid format."""
        if not v or not v.strip():
            raise ValueError("Instrument name cannot be empty")
        return v.strip()


class Connection(BaseModel):
    """
    Signal routing connection between slots/ports.

    Attributes:
        source: Source port identifier (e.g., 'Input1', 'Slot1OutA')
        destination: Destination port identifier (e.g., 'Output1', 'Slot2InA')
    """
    source: str = Field(..., description="Source port identifier")
    destination: str = Field(..., description="Destination port identifier")

    @field_validator('source', 'destination')
    @classmethod
    def validate_port_name(cls, v: str) -> str:
        """Validate port name is non-empty."""
        if not v or not v.strip():
            raise ValueError("Port name cannot be empty")
        return v.strip()


class ProbeConnection(BaseModel):
    """
    Signal routing between external probe and Moku port.

    Maps probe signal names to Moku physical ports.

    Attributes:
        probe: Signal name on probe (e.g., 'digital_glitch', 'coil_current')
        moku: Moku port name (e.g., 'OutputA', 'InputA', 'DACOut1')

    Example:
        >>> ProbeConnection(probe='digital_glitch', moku='OutputA')
        >>> ProbeConnection(probe='coil_current', moku='InputA')
    """
    probe: str = Field(..., description="Probe signal name")
    moku: str = Field(..., description="Moku port name")

    @field_validator('moku')
    @classmethod
    def validate_moku_port(cls, v: str) -> str:
        """Validate Moku port name is valid."""
        # Valid Moku port names
        valid_ports = {
            'InputA', 'InputB', 'InputC', 'InputD',
            'OutputA', 'OutputB', 'OutputC', 'OutputD',
            'DACOut1', 'DACOut2',
            'Input1', 'Input2', 'Input3', 'Input4',  # Alternative naming
            'Output1', 'Output2', 'Output3', 'Output4'
        }

        if v not in valid_ports:
            raise ValueError(
                f"Invalid Moku port: '{v}'. "
                f"Must be one of: {', '.join(sorted(valid_ports))}"
            )
        return v

    @field_validator('probe')
    @classmethod
    def validate_probe_signal(cls, v: str) -> str:
        """Validate probe signal name is non-empty."""
        if not v or not v.strip():
            raise ValueError("Probe signal name cannot be empty")
        return v.strip()


class ExternalHardware(BaseModel):
    """
    External device connected to Moku (e.g., EMFI probe, sensor).

    External hardware devices are analog peripherals interfaced through Moku
    ports. They do not have independent intelligence - all control is via
    Moku outputs, all sensing is via Moku inputs.

    Attributes:
        device_type: Device catalog reference (e.g., 'riscure_ds1120a')
        name: Optional friendly name for this device instance
        connections: List of signal routings (probe pin → Moku port)
        settings: Freeform metadata (probe tip, calibration, etc.)

    Example:
        >>> ExternalHardware(
        ...     device_type='riscure_ds1120a',
        ...     name='emfi_probe',
        ...     connections=[
        ...         ProbeConnection(probe='digital_glitch', moku='OutputA'),
        ...         ProbeConnection(probe='pulse_amplitude', moku='DACOut1'),
        ...         ProbeConnection(probe='coil_current', moku='InputA')
        ...     ],
        ...     settings={'probe_tip': '4mm_positive'}
        ... )
    """
    device_type: str = Field(..., description="Device catalog reference")
    name: Optional[str] = Field(None, description="Optional friendly name")
    connections: List[ProbeConnection] = Field(..., description="Probe-to-Moku signal routing")
    settings: Dict[str, Any] = Field(
        default_factory=dict,
        description="Freeform metadata (probe tip, calibration, etc.)"
    )

    @field_validator('device_type')
    @classmethod
    def validate_device_type(cls, v: str) -> str:
        """Validate device type references known probe catalog."""
        # Known device types (expandable as catalog grows)
        known_devices = [
            'riscure_ds1120a',  # Unidirectional EMFI probe
            'riscure_ds1121a',  # Bidirectional EMFI probe
        ]

        if v not in known_devices:
            raise ValueError(
                f"Unknown device type: '{v}'. "
                f"Known devices: {', '.join(known_devices)}. "
                f"Check Serena probe catalog (.serena/memories/riscure_*.md)"
            )
        return v

    @field_validator('connections')
    @classmethod
    def validate_no_duplicate_moku_ports(cls, v: List[ProbeConnection]) -> List[ProbeConnection]:
        """Ensure no Moku port is used twice within same device."""
        moku_ports = [conn.moku for conn in v]
        duplicates = set([p for p in moku_ports if moku_ports.count(p) > 1])

        if duplicates:
            raise ValueError(
                f"Moku port(s) used multiple times in same device: {', '.join(duplicates)}"
            )
        return v


class BenchConfig(BaseModel):
    """
    Complete bench configuration for multi-instrument setup.

    This configuration works for both simulation and hardware backends,
    enabling the workflow: Design → Test Locally → Push to Hardware

    Attributes:
        platform: Platform specification (MOKU_GO, MOKU_PRO, etc.)
        slots: Dictionary mapping slot number to SlotConfig
        connections: List of signal routing connections
        external_hardware: List of external devices (probes, sensors, etc.)
        metadata: Optional metadata (name, description, version)
    """
    platform: Dict[str, Any] = Field(..., description="Platform specification")
    slots: Dict[int, SlotConfig] = Field(..., description="Slot configurations")
    connections: List[Connection] = Field(default_factory=list, description="Signal routing")
    external_hardware: List[ExternalHardware] = Field(
        default_factory=list,
        description="External devices connected to Moku ports"
    )
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Optional metadata")

    @field_validator('slots')
    @classmethod
    def validate_slots(cls, v: Dict[int, SlotConfig], info) -> Dict[int, SlotConfig]:
        """Validate slot numbers are within platform limits."""
        if not v:
            raise ValueError("At least one slot must be configured")

        # Get platform from context (available during validation)
        platform = info.data.get('platform', {})
        max_slots = platform.get('slots', 4)  # Default to 4 if not specified

        for slot_num in v.keys():
            if slot_num < 1 or slot_num > max_slots:
                raise ValueError(f"Slot {slot_num} out of range for platform (1-{max_slots})")

        return v

    def to_dict(self) -> Dict[str, Any]:
        """Export configuration as dictionary for serialization."""
        return self.model_dump()

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'BenchConfig':
        """Create configuration from dictionary."""
        return cls(**data)

    def get_slot(self, slot_num: int) -> Optional[SlotConfig]:
        """Get configuration for specific slot number."""
        return self.slots.get(slot_num)

    def get_instrument_slots(self, instrument_type: str) -> List[int]:
        """Get list of slot numbers containing specified instrument type."""
        return [
            slot_num
            for slot_num, config in self.slots.items()
            if config.instrument == instrument_type
        ]

    def validate_connections(self) -> List[str]:
        """
        Validate all connections reference valid ports.
        Returns list of validation errors (empty if valid).
        """
        errors = []

        # Build list of valid port names
        valid_ports = set()

        # Add platform inputs/outputs
        valid_ports.update(self.platform.get('inputs', []))
        valid_ports.update(self.platform.get('outputs', []))

        # Add slot ports (SlotNOutA, SlotNOutB, SlotNInA, SlotNInB)
        for slot_num in self.slots.keys():
            for port_type in ['OutA', 'OutB', 'OutC', 'OutD', 'InA', 'InB', 'InC', 'InD']:
                valid_ports.add(f'Slot{slot_num}{port_type}')

        # Validate each connection
        for idx, conn in enumerate(self.connections):
            if conn.source not in valid_ports:
                errors.append(f"Connection {idx}: Invalid source port '{conn.source}'")
            if conn.destination not in valid_ports:
                errors.append(f"Connection {idx}: Invalid destination port '{conn.destination}'")

        return errors

    def validate_external_hardware_routing(self) -> List[str]:
        """
        Validate external hardware routing has no port conflicts.
        Returns list of validation errors (empty if valid).
        """
        errors = []

        # Collect all Moku ports used by external hardware
        ext_hw_ports = {}  # {port: device_name}
        for device in self.external_hardware:
            device_name = device.name or device.device_type
            for conn in device.connections:
                if conn.moku in ext_hw_ports:
                    errors.append(
                        f"Moku port '{conn.moku}' used by multiple external devices: "
                        f"'{ext_hw_ports[conn.moku]}' and '{device_name}'"
                    )
                else:
                    ext_hw_ports[conn.moku] = device_name

        # Check for conflicts with inter-slot connections
        slot_ports = set()
        for conn in self.connections:
            # Extract port names (may be like 'Input1', 'Output2', 'Slot1OutA', etc.)
            slot_ports.add(conn.source)
            slot_ports.add(conn.destination)

        # Find overlaps
        conflicts = set(ext_hw_ports.keys()) & slot_ports
        if conflicts:
            errors.append(
                f"Moku port(s) used by both external hardware and slot connections: "
                f"{', '.join(sorted(conflicts))}"
            )

        return errors

    def get_signal_flow_graph(self) -> Dict[str, Any]:
        """
        Generate signal flow graph data structure for diagram generation.

        Returns:
            Dictionary with 'nodes' and 'edges' keys suitable for rendering
            in ASCII art, Mermaid, or other diagram formats.

        Example:
            >>> config = BenchConfig(...)
            >>> graph = config.get_signal_flow_graph()
            >>> print(graph['nodes'])
            [{'id': 'slot1', 'label': 'Slot 1: CloudCompile', 'type': 'instrument'}, ...]
        """
        nodes = []
        edges = []

        # Add Moku platform node
        nodes.append({
            'id': 'moku',
            'label': self.platform.get('name', 'Moku'),
            'type': 'platform'
        })

        # Add slot nodes
        for slot_num, slot in self.slots.items():
            nodes.append({
                'id': f'slot{slot_num}',
                'label': f'Slot {slot_num}: {slot.instrument}',
                'type': 'instrument',
                'slot_num': slot_num
            })

        # Add external device nodes
        for idx, device in enumerate(self.external_hardware):
            device_id = f'ext_{idx}'
            device_label = device.name or device.device_type
            nodes.append({
                'id': device_id,
                'label': device_label,
                'type': 'external',
                'device_type': device.device_type
            })

            # Add edges for probe connections
            for conn in device.connections:
                # Determine direction based on port type
                if conn.moku.startswith('Output') or 'DAC' in conn.moku:
                    # Moku → External device (driving probe)
                    edges.append({
                        'source': 'moku',
                        'target': device_id,
                        'label': f"{conn.moku} → {conn.probe}",
                        'moku_port': conn.moku,
                        'probe_signal': conn.probe,
                        'direction': 'output'
                    })
                else:
                    # External device → Moku (reading probe)
                    edges.append({
                        'source': device_id,
                        'target': 'moku',
                        'label': f"{conn.probe} → {conn.moku}",
                        'moku_port': conn.moku,
                        'probe_signal': conn.probe,
                        'direction': 'input'
                    })

        # Add inter-slot connection edges
        for conn in self.connections:
            edges.append({
                'source': conn.source,
                'target': conn.destination,
                'label': 'internal',
                'type': 'slot_connection'
            })

        return {
            'nodes': nodes,
            'edges': edges,
            'platform': self.platform.get('name', 'Moku'),
            'num_slots': len(self.slots),
            'num_external_devices': len(self.external_hardware)
        }

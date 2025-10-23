"""
Bench Configuration Data Models

Pydantic models for declarative multi-instrument testbench configuration.
These models provide type safety, validation, and serialization for both
simulation and hardware backends.
"""

from typing import Dict, List, Any, Optional
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


class BenchConfig(BaseModel):
    """
    Complete bench configuration for multi-instrument setup.

    This configuration works for both simulation and hardware backends,
    enabling the workflow: Design → Test Locally → Push to Hardware

    Attributes:
        platform: Platform specification (MOKU_GO, MOKU_PRO, etc.)
        slots: Dictionary mapping slot number to SlotConfig
        connections: List of signal routing connections
        metadata: Optional metadata (name, description, version)
    """
    platform: Dict[str, Any] = Field(..., description="Platform specification")
    slots: Dict[int, SlotConfig] = Field(..., description="Slot configurations")
    connections: List[Connection] = Field(default_factory=list, description="Signal routing")
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

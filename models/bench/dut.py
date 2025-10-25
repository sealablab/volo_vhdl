"""
Device Under Test (DUT) Model

Placeholder model for target devices.
Will be expanded as needed for specific DUT types.
"""

from pydantic import BaseModel, Field


class DUT(BaseModel):
    """
    Device Under Test - placeholder model.

    Simple representation of the target device being tested.
    Can be expanded later with chip-specific details, pin mappings, etc.

    Attributes:
        name: Short identifier for the DUT
        description: Detailed description
        part_number: Optional part number
        notes: Additional notes

    Example:
        >>> dut = DUT(
        ...     name='STM32F4_decapped',
        ...     description='STM32F407 with package removed, mounted in socket',
        ...     part_number='STM32F407VGT6'
        ... )
    """

    name: str = Field(..., description="Short identifier for the DUT")
    description: str = Field(..., description="Detailed description")
    part_number: str | None = Field(default=None, description="Part number (if applicable)")
    notes: str | None = Field(default=None, description="Additional notes")

    def __str__(self) -> str:
        """Human-readable representation."""
        part_str = f" ({self.part_number})" if self.part_number else ""
        return f"DUT: {self.name}{part_str}"

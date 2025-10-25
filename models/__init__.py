"""
Volo VHDL Data Models

Pure Pydantic models for hardware, benches, instruments, and external devices.
These models are completely separate from implementation code and provide
type-safe, validated data structures for the entire codebase.

Organization:
- models/moku/ - Moku platform models (hardware, routing)
- models/riscure/ - Riscure probe models (DS1120A, DS1121A, etc.)

Usage:
    from models.moku.platforms.moku_go import MokuGoPlatform, MOKU_GO_PLATFORM
    from models.moku.routing import MokuConnection, MokuConnectionList
    from models.riscure.ds1120a import DS1120A, DS1120A_PROBE
"""

__all__ = []

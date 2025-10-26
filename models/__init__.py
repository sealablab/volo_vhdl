"""
Volo VHDL Data Models

Pure Pydantic models for hardware, benches, instruments, and external devices.
These models are completely separate from implementation code and provide
type-safe, validated data structures for the entire codebase.

Organization:
- models/moku-models/ - Moku platform models (git submodule - import via 'moku_models')
- models/riscure/ - Riscure probe models (DS1120A, DS1121A, etc.)
- models/bench/ - BenchBench testbench framework models
- models/dummy/ - Dummy/mock device models for testing
- models/volo/ - VoloApp models

Core Abstraction:
    MokuConfig (from moku_models) - Central deployment model for simulation and hardware

Note: Moku models are now in a separate git submodule package. Import them as:
    from moku_models import MokuConfig, SlotConfig, MokuConnection, MOKU_GO_PLATFORM

Legacy imports from 'models.moku' are deprecated. Use 'moku_models' instead.
"""

__all__ = []

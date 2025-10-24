"""
Bench Configuration Framework

A unified abstraction for multi-instrument testbenches that works with both:
- Simulation Backend: CocotB + GHDL + instrument behavioral models
- Hardware Backend: Real Moku device via MCC Multi-Instrument Mode API

Enables workflow: Design → Test Locally → Push to Hardware
"""

from .config import (
    BenchConfig,
    SlotConfig,
    Connection,
    ProbeConnection,
    ExternalHardware,
    MOKU_GO,
    MOKU_PRO,
)
from .backend import Backend
from .simulation import SimulationBackend
from .hardware import HardwareBackend
from .visualization import (
    generate_ascii_diagram,
    generate_mermaid_diagram,
    generate_summary,
)

__all__ = [
    # Configuration models
    'BenchConfig',
    'SlotConfig',
    'Connection',
    'ProbeConnection',
    'ExternalHardware',
    # Platform definitions
    'MOKU_GO',
    'MOKU_PRO',
    # Backend classes
    'Backend',
    'SimulationBackend',
    'HardwareBackend',
    # Visualization
    'generate_ascii_diagram',
    'generate_mermaid_diagram',
    'generate_summary',
]

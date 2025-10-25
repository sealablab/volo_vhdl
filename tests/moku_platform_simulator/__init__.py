"""
Moku Platform Simulator

Lightweight Moku platform simulator for CocotB testing.

Enables "train like you fight" workflow:
- Same configuration for simulation and hardware
- Test multi-module interactions in simulation
- Deploy identical config to real Moku

Components:
- Backend: Abstract interface for sim/hardware
- SimulationBackend: CocotB behavioral models
- HardwareBackend: Real Moku deployment via MCC API
- Simulators: Behavioral models (oscilloscope, etc.)
"""

from models.moku.platform_config import MokuPlatformConfig, SlotConfig
from models.moku.platforms.moku_go import MokuGoPlatform, MOKU_GO_PLATFORM
from models.moku.routing import MokuConnection

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
    'MokuPlatformConfig',
    'SlotConfig',
    'MokuConnection',
    # Platform models
    'MokuGoPlatform',
    'MOKU_GO_PLATFORM',
    # Backend classes
    'Backend',
    'SimulationBackend',
    'HardwareBackend',
    # Visualization
    'generate_ascii_diagram',
    'generate_mermaid_diagram',
    'generate_summary',
]

"""
Bench Configuration Framework

A unified abstraction for multi-instrument testbenches that works with both:
- Simulation Backend: CocotB + GHDL + instrument behavioral models
- Hardware Backend: Real Moku device via MCC Multi-Instrument Mode API

Enables workflow: Design → Test Locally → Push to Hardware
"""

from .config import BenchConfig, SlotConfig, Connection
from .backend import Backend
from .simulation import SimulationBackend
from .hardware import HardwareBackend

__all__ = [
    'BenchConfig',
    'SlotConfig',
    'Connection',
    'Backend',
    'SimulationBackend',
    'HardwareBackend',
]

"""
Moku Platform Models

Physical hardware models and routing abstractions for Moku devices.
Aligns with the 1st-party moku library conventions.

Core Abstraction:
    MokuConfig - THE central deployment model for this project
"""

from models.moku.platforms.moku_go import MokuGoPlatform, MOKU_GO_PLATFORM
from models.moku.routing import MokuConnection, MokuConnectionList
from models.moku.platform_config import MokuConfig, SlotConfig, MokuPlatformConfig
from models.moku.discovery import MokuDeviceInfo, MokuDeviceCache

__all__ = [
    # Core abstraction (use this!)
    'MokuConfig',
    'SlotConfig',

    # Platform specifications
    'MokuGoPlatform',
    'MOKU_GO_PLATFORM',

    # Routing
    'MokuConnection',
    'MokuConnectionList',

    # Device discovery
    'MokuDeviceInfo',
    'MokuDeviceCache',

    # Backward compatibility (deprecated)
    'MokuPlatformConfig',
]

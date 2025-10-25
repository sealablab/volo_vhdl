"""
Device Catalog

Centralized registry of known probes and external hardware devices.
Used for validation of BenchBench wiring configurations.

Design:
- String-based identifiers in configs (YAML-friendly)
- Model instances for validation
- Expandable as new devices are added
- DummyProbe for unknown devices

Usage:
    from models.device_catalog import DEVICE_CATALOG, get_device

    # Get device for validation
    probe = get_device('DS1120A')
    signal = probe.get_output('coil_current')
"""

from models.riscure.ds1120a import DS1120A, DS1120A_PROBE
from models.dummy.probe import DummyProbe

# Centralized device registry
# Key: String identifier, Value: Device model instance
DEVICE_CATALOG: dict[str, DS1120A | DummyProbe] = {
    'DS1120A': DS1120A_PROBE,
    # Future additions:
    # 'DS1121A': DS1121A_PROBE,
    # 'oscilloscope_trigger': DummyProbe(...),
}


def get_device(device_id: str) -> DS1120A | DummyProbe | None:
    """
    Get device model from catalog.

    Args:
        device_id: Device identifier (e.g., 'DS1120A')

    Returns:
        Device model instance if found, None otherwise
    """
    return DEVICE_CATALOG.get(device_id)


def register_device(device_id: str, device_model: DS1120A | DummyProbe) -> None:
    """
    Register a new device in the catalog.

    Useful for runtime registration of custom probes.

    Args:
        device_id: String identifier
        device_model: Device model instance
    """
    DEVICE_CATALOG[device_id] = device_model


def list_devices() -> list[str]:
    """List all registered device identifiers."""
    return list(DEVICE_CATALOG.keys())

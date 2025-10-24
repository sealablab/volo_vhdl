"""
Diagram Generation for Bench Configuration

Provides ASCII art and Mermaid diagram generation from BenchConfig
signal flow graphs. Useful for documentation, debugging, and understanding
complex bench setups.
"""

from typing import Dict, List, Any
from .config import BenchConfig


def generate_ascii_diagram(config: BenchConfig) -> str:
    """
    Generate ASCII art signal flow diagram from bench configuration.

    Args:
        config: BenchConfig instance

    Returns:
        String containing ASCII art diagram

    Example:
        >>> config = BenchConfig(...)
        >>> print(generate_ascii_diagram(config))
        === Bench Configuration Diagram ===
        ...
    """
    lines = []
    lines.append("=" * 60)
    lines.append("Bench Configuration Diagram")
    lines.append("=" * 60)
    lines.append("")

    # Platform info
    platform_name = config.platform.get('name', 'Moku')
    lines.append(f"Platform: {platform_name}")
    lines.append(f"Slots: {len(config.slots)}")
    lines.append(f"External Devices: {len(config.external_hardware)}")
    lines.append("")

    # External hardware section
    if config.external_hardware:
        lines.append("=" * 60)
        lines.append("External Devices")
        lines.append("=" * 60)
        for device in config.external_hardware:
            device_name = device.name or device.device_type
            lines.append(f"\n  Device: {device_name}")
            lines.append(f"  Type: {device.device_type}")
            if device.settings:
                lines.append(f"  Settings: {device.settings}")
            lines.append("  Connections:")
            for conn in device.connections:
                # Determine arrow direction
                if conn.moku.startswith('Output') or 'DAC' in conn.moku:
                    arrow = f"    [Moku {conn.moku}] ---> [{device_name}.{conn.probe}]"
                else:
                    arrow = f"    [{device_name}.{conn.probe}] ---> [Moku {conn.moku}]"
                lines.append(arrow)
        lines.append("")

    # Slots section
    lines.append("=" * 60)
    lines.append("Moku Slots")
    lines.append("=" * 60)
    for slot_num, slot in config.slots.items():
        lines.append(f"\n  Slot {slot_num}: {slot.instrument}")
        if slot.bitstream:
            lines.append(f"    Bitstream: {slot.bitstream}")
        if slot.control_registers:
            lines.append(f"    Control Registers: {slot.control_registers}")
        if slot.settings:
            lines.append(f"    Settings: {slot.settings}")
    lines.append("")

    # Inter-slot connections
    if config.connections:
        lines.append("=" * 60)
        lines.append("Internal Routing (Slot-to-Slot)")
        lines.append("=" * 60)
        for conn in config.connections:
            lines.append(f"  {conn.source} ---> {conn.destination}")
        lines.append("")

    lines.append("=" * 60)

    return "\n".join(lines)


def generate_mermaid_diagram(config: BenchConfig) -> str:
    """
    Generate Mermaid flowchart diagram from bench configuration.

    Args:
        config: BenchConfig instance

    Returns:
        String containing Mermaid flowchart syntax

    Example:
        >>> config = BenchConfig(...)
        >>> print(generate_mermaid_diagram(config))
        flowchart LR
            moku[Moku:Go]
            ext_0[riscure_ds1120a]
            ...

    Reference:
        https://mermaid.js.org/syntax/flowchart.html
    """
    lines = []
    lines.append("flowchart LR")
    lines.append("")

    # Get signal flow graph
    graph = config.get_signal_flow_graph()

    # Add comment with metadata
    lines.append(f"    %% Platform: {graph['platform']}")
    lines.append(f"    %% Slots: {graph['num_slots']}, External Devices: {graph['num_external_devices']}")
    lines.append("")

    # Define nodes
    lines.append("    %% Nodes")
    for node in graph['nodes']:
        node_id = node['id']
        node_label = node['label']
        node_type = node['type']

        # Different shapes for different node types
        if node_type == 'platform':
            lines.append(f'    {node_id}(["{node_label}"])')  # Stadium shape
        elif node_type == 'instrument':
            lines.append(f'    {node_id}["{node_label}"]')  # Rectangle
        elif node_type == 'external':
            lines.append(f'    {node_id}{{{node_label}}}')  # Rhombus
    lines.append("")

    # Define edges
    lines.append("    %% Connections")
    for edge in graph['edges']:
        source = edge['source']
        target = edge['target']
        label = edge.get('label', '')

        if label:
            lines.append(f'    {source} -->|"{label}"| {target}')
        else:
            lines.append(f'    {source} --> {target}')

    # Styling
    lines.append("")
    lines.append("    %% Styling")
    lines.append("    classDef platform fill:#e1f5ff,stroke:#0288d1,stroke-width:2px")
    lines.append("    classDef instrument fill:#fff9c4,stroke:#f57f17,stroke-width:2px")
    lines.append("    classDef external fill:#ffe0b2,stroke:#e64a19,stroke-width:2px")
    lines.append("    class moku platform")

    # Add class assignments for instruments and external devices
    instrument_nodes = [n['id'] for n in graph['nodes'] if n['type'] == 'instrument']
    if instrument_nodes:
        lines.append(f"    class {','.join(instrument_nodes)} instrument")

    external_nodes = [n['id'] for n in graph['nodes'] if n['type'] == 'external']
    if external_nodes:
        lines.append(f"    class {','.join(external_nodes)} external")

    return "\n".join(lines)


def generate_summary(config: BenchConfig) -> str:
    """
    Generate human-readable summary of bench configuration.

    Args:
        config: BenchConfig instance

    Returns:
        String containing configuration summary

    Example:
        >>> config = BenchConfig(...)
        >>> print(generate_summary(config))
        Bench Configuration Summary
        ===========================
        Platform: Moku:Go
        ...
    """
    lines = []
    lines.append("Bench Configuration Summary")
    lines.append("=" * 40)
    lines.append(f"Platform: {config.platform.get('name', 'Unknown')}")
    lines.append(f"Slots configured: {len(config.slots)}")
    lines.append(f"Inter-slot connections: {len(config.connections)}")
    lines.append(f"External devices: {len(config.external_hardware)}")
    lines.append("")

    # List instruments
    if config.slots:
        lines.append("Instruments:")
        for slot_num, slot in sorted(config.slots.items()):
            lines.append(f"  - Slot {slot_num}: {slot.instrument}")

    # List external devices
    if config.external_hardware:
        lines.append("\nExternal Devices:")
        for device in config.external_hardware:
            device_name = device.name or device.device_type
            num_connections = len(device.connections)
            lines.append(f"  - {device_name} ({num_connections} connection(s))")

    # Validation
    conn_errors = config.validate_connections()
    hw_errors = config.validate_external_hardware_routing()

    if conn_errors or hw_errors:
        lines.append("\n⚠️  Validation Errors:")
        for err in conn_errors + hw_errors:
            lines.append(f"  - {err}")
    else:
        lines.append("\n✓ Configuration valid (no routing conflicts)")

    return "\n".join(lines)

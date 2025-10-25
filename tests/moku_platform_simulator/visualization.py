"""
Diagram Generation for Moku Platform Configuration
"""

from models.moku.platform_config import MokuPlatformConfig


def generate_ascii_diagram(config: MokuPlatformConfig) -> str:
    """Generate ASCII diagram of Moku platform configuration."""
    lines = []
    lines.append("=" * 60)
    lines.append("Moku Platform Configuration")
    lines.append("=" * 60)
    lines.append("")

    # Platform info
    lines.append(f"Platform: {config.platform.name}")
    lines.append(f"Slots: {len(config.slots)}")
    lines.append(f"Routing: {len(config.routing)} connections")
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

    # MCC routing
    if config.routing:
        lines.append("=" * 60)
        lines.append("MCC Routing")
        lines.append("=" * 60)
        for conn in config.routing:
            lines.append(f"  {conn.source} ---> {conn.destination}")
        lines.append("")

    lines.append("=" * 60)

    return "\n".join(lines)


def generate_mermaid_diagram(config: MokuPlatformConfig) -> str:
    """Generate Mermaid flowchart from Moku platform configuration."""
    lines = []
    lines.append("flowchart LR")
    lines.append("")

    # Metadata
    lines.append(f"    %% Platform: {config.platform.name}")
    lines.append(f"    %% Slots: {len(config.slots)}, Routing: {len(config.routing)}")
    lines.append("")

    # Platform node
    lines.append("    %% Platform")
    lines.append(f'    moku(["{config.platform.name}"])')
    lines.append("")

    # Slot nodes
    lines.append("    %% Slots")
    for slot_num, slot in config.slots.items():
        lines.append(f'    slot{slot_num}["Slot {slot_num}: {slot.instrument}"]')
    lines.append("")

    # Routing connections
    if config.routing:
        lines.append("    %% Routing")
        for conn in config.routing:
            # Simplified node IDs
            src_id = conn.source.replace('Slot', 'slot').replace('Input', 'IN').replace('Output', 'OUT')
            dst_id = conn.destination.replace('Slot', 'slot').replace('Input', 'IN').replace('Output', 'OUT')
            lines.append(f'    {src_id} --> {dst_id}')

    # Styling
    lines.append("")
    lines.append("    %% Styling")
    lines.append("    classDef platform fill:#e1f5ff,stroke:#0288d1,stroke-width:2px")
    lines.append("    classDef instrument fill:#fff9c4,stroke:#f57f17,stroke-width:2px")
    lines.append("    class moku platform")

    slot_nodes = [f'slot{n}' for n in config.slots.keys()]
    if slot_nodes:
        lines.append(f"    class {','.join(slot_nodes)} instrument")

    return "\n".join(lines)


def generate_summary(config: MokuPlatformConfig) -> str:
    """Generate human-readable summary."""
    lines = []
    lines.append("Moku Platform Configuration Summary")
    lines.append("=" * 40)
    lines.append(f"Platform: {config.platform.name}")
    lines.append(f"Slots configured: {len(config.slots)}")
    lines.append(f"Routing connections: {len(config.routing)}")
    lines.append("")

    # List instruments
    if config.slots:
        lines.append("Instruments:")
        for slot_num, slot in sorted(config.slots.items()):
            lines.append(f"  - Slot {slot_num}: {slot.instrument}")

    # Validation
    routing_errors = config.validate_routing()
    if routing_errors:
        lines.append("\n⚠️  Validation Errors:")
        for err in routing_errors:
            lines.append(f"  - {err}")
    else:
        lines.append("\n✓ Configuration valid")

    return "\n".join(lines)

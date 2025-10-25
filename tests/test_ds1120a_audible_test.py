"""
DS1120A Audible Test

Fires probe at slow rate (10 Hz) for easy listening.
At 10 Hz you should clearly hear individual clicks.

Usage:
    python test_ds1120a_audible_test.py --config bench_configs/ds1120a_basic.yaml
    python test_ds1120a_audible_test.py  # Uses default config

Arguments:
    --config PATH    Path to BenchConfig YAML file (default: bench_configs/ds1120a_basic.yaml)
"""

import argparse
import time
import yaml
from pathlib import Path

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
except ImportError:
    print("ERROR: Moku API not available")
    exit(1)

# Import bench framework
import sys
sys.path.insert(0, str(Path(__file__).parent))
from bench_framework.config import BenchConfig
from bench_framework.visualization import generate_ascii_diagram


def load_bench_config(config_path: str) -> BenchConfig:
    """Load and parse BenchConfig from YAML file."""
    with open(config_path, 'r') as f:
        data = yaml.safe_load(f)
    return BenchConfig.from_dict(data)


def derive_mcc_routing(config: BenchConfig) -> dict:
    """
    Derive MCC routing from BenchConfig.

    Maps probe connections to instrument slot outputs/inputs.

    Returns:
        Dictionary with:
            - connections: List of MCC connection dicts
            - trigger_slot: Slot number for trigger instrument
            - power_slot: Slot number for power instrument
            - monitor_slot: Slot number for monitor instrument
    """
    # Find the DS1120A probe connections
    probe = None
    for device in config.external_hardware:
        if device.device_type in ['riscure_ds1120a', 'riscure_ds1121a']:
            probe = device
            break

    if not probe:
        raise ValueError("No DS1120A/DS1121A probe found in BenchConfig")

    # Map probe signals to Moku ports
    probe_map = {conn.probe: conn.moku for conn in probe.connections}

    # Get trigger and power Moku ports
    trigger_port = probe_map.get('digital_glitch')  # e.g., 'Output1'
    power_port = probe_map.get('pulse_amplitude')   # e.g., 'Output2'
    monitor_port = probe_map.get('coil_current')    # e.g., 'Input1'

    if not all([trigger_port, power_port, monitor_port]):
        raise ValueError(
            f"Incomplete probe connections. Found: "
            f"trigger={trigger_port}, power={power_port}, monitor={monitor_port}"
        )

    # For this test, we assume:
    # - Slot 1: Oscilloscope (generates trigger, captures monitor)
    # - Slot 2: WaveformGenerator (generates power)

    connections = [
        # Oscilloscope → Physical Output (trigger)
        {'source': 'Slot1OutA', 'destination': trigger_port},

        # WaveformGenerator → Physical Output (power)
        {'source': 'Slot2OutA', 'destination': power_port},

        # Physical Input → Oscilloscope (monitor)
        {'source': monitor_port, 'destination': 'Slot1InA'},
    ]

    return {
        'connections': connections,
        'trigger_slot': 1,
        'power_slot': 2,
        'monitor_slot': 1,
        'trigger_port': trigger_port,
        'power_port': power_port,
        'monitor_port': monitor_port,
    }


def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description='DS1120A Audible Test')
    parser.add_argument(
        '--config',
        default='bench_configs/ds1120a_basic.yaml',
        help='Path to BenchConfig YAML file'
    )
    args = parser.parse_args()

    print("="*70)
    print("DS1120A AUDIBLE TEST")
    print("="*70)
    print("\nThis test fires the probe at 10 Hz (slow enough to hear)")
    print("You should hear distinct CLICKS if the probe is working.\n")

    # Load and validate BenchConfig
    print(f"Loading BenchConfig from: {args.config}")
    try:
        config = load_bench_config(args.config)
    except FileNotFoundError:
        print(f"ERROR: Config file not found: {args.config}")
        exit(1)
    except Exception as e:
        print(f"ERROR: Failed to load config: {e}")
        exit(1)

    print(f"✓ Config loaded: {config.metadata.get('name', 'Unnamed')}\n")

    # Show wiring diagram
    print("="*70)
    print("EXPECTED WIRING (from BenchConfig)")
    print("="*70)
    diagram = generate_ascii_diagram(config)
    print(diagram)
    print()

    # Derive MCC routing from config
    try:
        routing = derive_mcc_routing(config)
    except ValueError as e:
        print(f"ERROR: {e}")
        exit(1)

    print("="*70)
    print("MCC ROUTING (derived from config)")
    print("="*70)
    for conn in routing['connections']:
        print(f"  {conn['source']:15s} → {conn['destination']}")
    print()

    # Connect to Moku
    moku_ip = config.platform['ip']
    print(f"Connecting to Moku at {moku_ip}...")
    m = MultiInstrument(moku_ip, platform_id=2, force_connect=True)
    print("✓ Connected\n")

    # Deploy instruments
    osc = m.set_instrument(routing['trigger_slot'], Oscilloscope)
    wg = m.set_instrument(routing['power_slot'], WaveformGenerator)
    print("✓ Instruments deployed\n")

    # Apply MCC routing
    m.set_connections(connections=routing['connections'])
    print("✓ Routing configured\n")

    # Set 50% power for maximum effect
    wg.generate_waveform(1, type='DC', dc_level=1.65)
    print("✓ Power set to 50% (maximum)")

    # Slow trigger for audible clicks
    osc.generate_waveform(1, type='Square', amplitude=1.65, frequency=10, duty=50)
    print("✓ Trigger set to 10 Hz (slow)\n")

    print("="*70)
    print("🔊 LISTENING TEST")
    print("="*70)
    print("\nProbe should be firing at 10 Hz (10 clicks per second)")
    print("\nPUT YOUR EAR NEAR THE PROBE (safely!)")
    print("Do you hear clicking/ticking sounds?\n")

    print("Firing for 10 seconds...\n")

    for i in range(10, 0, -1):
        print(f"  {i} seconds remaining...")
        time.sleep(1)

    print("\n" + "="*70)
    print("TEST COMPLETE")
    print("="*70)
    print("\nDid you hear clicking?")
    print("  ✅ YES → Probe IS working, current monitor issue")
    print("  ❌ NO  → Probe NOT firing, check:")
    print("           - Probe tip installed?")
    print("           - 24V PSU voltage correct?")
    print("           - Probe internal fault?")

    # Cleanup
    print("\nStopping...")
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    osc.generate_waveform(1, type='DC', dc_level=0.0)
    print("✓ Done\n")


if __name__ == '__main__':
    main()

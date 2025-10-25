#!/usr/bin/env python3
"""
MokuBench Data Logger Test - Simple Counter Time-Series Capture

This script demonstrates continuous data logging from a custom VHDL module:
1. Deploy CloudCompile bitstream (simple_counter) to slot 1
2. Deploy Data Logger to slot 2
3. Configure signal routing
4. Stream time-series data continuously
5. Collect and analyze counter behavior over time

Usage:
    python mokubench_datalogger_test.py --ip 192.168.13.159
    python mokubench_datalogger_test.py --ip 192.168.13.159 --duration 30  # Stream for 30s
    python mokubench_datalogger_test.py --ip 192.168.13.159 --sample-rate 10000  # 10 kSa/s

Requirements:
    - Moku device on network with known IP
    - simple_counter.tar.gz bitstream in bitstreams/
    - uv run python mokubench_datalogger_test.py --ip <ip>
"""

import argparse
import asyncio
import sys
from pathlib import Path

# Add bench_framework to path
sys.path.insert(0, str(Path(__file__).parent))

from bench_framework import HardwareBackend, BenchConfig, SlotConfig, Connection

# Platform definitions (must match config.py format)
MOKU_GO = {
    'id': 2,
    'name': 'Moku:Go',
    'slots': 2,
    'inputs': ['Input1', 'Input2'],
    'outputs': ['Output1', 'Output2'],
    'clock': 125e6
}

MOKU_PRO = {
    'id': 3,
    'name': 'Moku:Pro',
    'slots': 4,
    'inputs': ['Input1', 'Input2', 'Input3', 'Input4'],
    'outputs': ['Output1', 'Output2', 'Output3', 'Output4'],
    'clock': 500e6
}


def create_datalogger_config(platform_id: int = 2, duration: float = 10.0, sample_rate: float = 1e3) -> BenchConfig:
    """
    Create BenchConfig for simple_counter with Data Logger.

    Configuration:
    - Slot 1: CloudCompile with simple_counter bitstream
      - Control0[31] = MCC_READY (auto-set by platform)
      - Control0[30] = User Enable (1=enable counter)
      - Control0[29] = Clock Enable (1=run, 0=freeze)
    - Slot 2: Data Logger
      - Sample rate: Configurable (default 1 kSa/s)
      - Streaming: Enabled for continuous capture
      - Captures counter output over time

    Args:
        platform_id: Platform ID (2=Moku:Go, 3=Moku:Pro)
        duration: Streaming duration in seconds
        sample_rate: Sample rate in Sa/s (e.g., 1e3 = 1 kSa/s, 1e6 = 1 MSa/s)

    Returns:
        BenchConfig instance
    """
    platform = MOKU_GO if platform_id == 2 else MOKU_PRO

    config = BenchConfig(
        platform=platform,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                bitstream='bitstreams/simple_counter.tar.gz',
                control_registers={
                    # Control0: [MCC_READY | Enable | ClkEn | Reserved]
                    # Bit 31: MCC_READY (auto-set by platform)
                    # Bit 30: User Enable (1=enable counter)
                    # Bit 29: Clock Enable (1=run counter, 0=freeze)
                    0: 0xE0000000  # MCC_READY + Enable + ClkEn
                }
            ),
            2: SlotConfig(
                instrument='Datalogger',
                settings={
                    'streaming': {
                        'enabled': True,
                        'duration': duration,
                        'sample_rate': sample_rate
                    }
                }
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),  # 16-bit counter value
            Connection(source='Slot1OutB', destination='Slot2InB'),  # Counter MSB
        ],
        metadata={
            'test': 'simple_counter_datalogger',
            'description': 'Time-series capture of counter behavior',
            'version': '1.0'
        }
    )

    return config


async def run_datalogger_test(ip_address: str, platform_id: int = 2, duration: float = 10.0, sample_rate: float = 1e3):
    """
    Run Data Logger deployment test with continuous streaming.

    Args:
        ip_address: IP address of Moku device (e.g., '192.168.13.159')
        platform_id: Platform ID (2=Moku:Go, 3=Moku:Pro)
        duration: Streaming duration in seconds
        sample_rate: Sample rate in Sa/s
    """
    platform_name = MOKU_GO['name'] if platform_id == 2 else MOKU_PRO['name']

    print("=" * 80)
    print(f"MokuBench Data Logger Test - Simple Counter Time-Series Capture")
    print("=" * 80)
    print(f"Target Platform: {platform_name} (ID={platform_id})")
    print(f"IP Address: {ip_address}")
    print(f"Bitstream: bitstreams/simple_counter.tar.gz")
    print(f"Duration: {duration}s")
    print(f"Sample Rate: {sample_rate/1e3:.1f} kSa/s" if sample_rate < 1e6 else f"{sample_rate/1e6:.1f} MSa/s")
    print()

    # Step 1: Create configuration
    print("[1/5] Creating BenchConfig...")
    config = create_datalogger_config(platform_id, duration, sample_rate)
    print(f"  ✓ Config created: {len(config.slots)} slots, {len(config.connections)} connections")
    print()

    # Step 2: Create HardwareBackend
    print("[2/5] Creating HardwareBackend...")
    backend = HardwareBackend.from_config(config, ip_address=ip_address, platform_id=platform_id)
    print("  ✓ Backend created")
    print()

    # Step 3: Setup (connect, deploy, configure)
    print("[3/5] Deploying to hardware...")
    try:
        await backend.setup()
        print()
    except Exception as e:
        print(f"\n✗ Deployment failed: {e}")
        print("\nTroubleshooting:")
        print("  - Check IP address is correct")
        print("  - Verify Moku is on same network")
        print("  - Ensure bitstream file exists: bitstreams/simple_counter.tar.gz")
        print("  - Try: python mokubench_connection_test.py --ip <ip>")
        return False

    # Step 4: Run and collect streaming data
    print("[4/5] Streaming data from Data Logger...")
    print(f"  (This will take {duration}s - counter is running continuously)")
    try:
        # Give Data Logger time to accumulate streaming data
        data = await backend.run(duration_ms=duration * 1000)
        print()

        # Verify data logger data
        if 2 in data:
            dl_data = data[2]
            ch1_samples = len(dl_data.get('ch1', []))
            ch2_samples = len(dl_data.get('ch2', []))
            time_points = len(dl_data.get('time', []))

            print(f"  Data Logger Streaming Results:")
            print(f"    Channel 1 (Counter): {ch1_samples} samples")
            print(f"    Channel 2 (Counter MSB): {ch2_samples} samples")
            print(f"    Time points: {time_points}")

            if ch1_samples > 0:
                print(f"  ✓ Successfully captured time-series data!")

                # Show some statistics
                ch1_values = dl_data['ch1']
                if len(ch1_values) >= 2:
                    first_val = ch1_values[0]
                    last_val = ch1_values[-1]
                    print(f"\n  Data Analysis:")
                    print(f"    First value: {first_val}")
                    print(f"    Last value: {last_val}")
                    print(f"    Change: {last_val - first_val}")

                    # Check if counter is incrementing
                    is_incrementing = last_val > first_val
                    if is_incrementing:
                        print(f"  ✓ Counter is incrementing correctly!")
                    else:
                        print(f"  ⚠ Counter may not be incrementing (check configuration)")
            else:
                print(f"  ⚠ No data captured - check Data Logger streaming configuration")
        print()

    except Exception as e:
        print(f"\n✗ Run failed: {e}")
        await backend.teardown()
        return False

    # Step 5: Teardown
    print("[5/5] Cleaning up...")
    await backend.teardown()
    print()

    print("=" * 80)
    print("✓ MokuBench Data Logger Test PASSED")
    print("=" * 80)
    print()
    print("Next steps:")
    print("  - Increase sample rate for higher resolution: --sample-rate 10000")
    print("  - Extend duration for longer captures: --duration 60")
    print("  - Compare with Oscilloscope results (mokubench_deployment_test.py)")
    print("  - Try logging to file instead of streaming")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(
        description='MokuBench Data Logger Test - Simple Counter Time-Series Capture',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--ip', required=True, help='IP address of Moku device (e.g., 192.168.13.159)')
    parser.add_argument('--platform', type=int, default=2, choices=[1, 2, 3],
                        help='Platform ID: 1=Moku:Lab, 2=Moku:Go (default), 3=Moku:Pro')
    parser.add_argument('--duration', type=float, default=10.0,
                        help='Streaming duration in seconds (default: 10.0)')
    parser.add_argument('--sample-rate', type=float, default=1000.0,
                        help='Sample rate in Sa/s (default: 1000 = 1 kSa/s)')

    args = parser.parse_args()

    # Verify bitstream exists
    bitstream_path = Path('bitstreams/simple_counter.tar.gz')
    if not bitstream_path.exists():
        print(f"Error: Bitstream not found: {bitstream_path}")
        print("\nExpected location: bitstreams/simple_counter.tar.gz")
        print("Have you run the CloudCompile build and downloaded the bitstream?")
        sys.exit(1)

    # Run async deployment test
    success = asyncio.run(run_datalogger_test(args.ip, args.platform, args.duration, args.sample_rate))
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
MokuBench Deployment Test - Simple Counter PoC

This script demonstrates the complete MokuBench workflow:
1. Deploy CloudCompile bitstream (simple_counter) to slot 1
2. Deploy Oscilloscope to slot 2
3. Configure signal routing
4. Apply control registers
5. Capture and verify counter behavior

Usage:
    python mokubench_deployment_test.py --ip 192.168.1.100
    python mokubench_deployment_test.py --ip 192.168.1.100 --platform 2  # Moku:Go (default)
    python mokubench_deployment_test.py --ip 192.168.1.100 --platform 3  # Moku:Pro

Requirements:
    - Moku device on network with known IP
    - simple_counter.tar.gz bitstream in bitstreams/
    - uv run python mokubench_deployment_test.py --ip <ip>
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


def create_simple_counter_config(platform_id: int = 2) -> BenchConfig:
    """
    Create BenchConfig for simple_counter deployment.

    Configuration:
    - Slot 1: CloudCompile with simple_counter bitstream
      - Control0[31] = MCC_READY (auto-set by platform)
      - Control0[30] = User Enable (1=enable counter)
      - Control0[29] = Clock Enable (1=run, 0=freeze)
    - Slot 2: Oscilloscope
      - Timebase: ±5ms window
      - Input A: Counter output (16-bit value)
      - Input B: Counter MSB (for visibility)

    Args:
        platform_id: Platform ID (2=Moku:Go, 3=Moku:Pro)

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
                instrument='Oscilloscope',
                settings={
                    'timebase': (-5e-3, 5e-3)  # ±5ms window
                }
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),  # 16-bit counter value
            Connection(source='Slot1OutB', destination='Slot2InB'),  # Counter MSB
        ],
        metadata={
            'test': 'simple_counter_poc',
            'description': 'MokuBench Phase 3 proof of concept',
            'version': '1.0'
        }
    )

    return config


async def run_deployment_test(ip_address: str, platform_id: int = 2):
    """
    Run complete MokuBench deployment test.

    Args:
        ip_address: IP address of Moku device (e.g., '192.168.1.100')
        platform_id: Platform ID (2=Moku:Go, 3=Moku:Pro)
    """
    platform_name = MOKU_GO['name'] if platform_id == 2 else MOKU_PRO['name']

    print("=" * 80)
    print(f"MokuBench Deployment Test - Simple Counter PoC")
    print("=" * 80)
    print(f"Target Platform: {platform_name} (ID={platform_id})")
    print(f"IP Address: {ip_address}")
    print(f"Bitstream: bitstreams/simple_counter.tar.gz")
    print()

    # Step 1: Create configuration
    print("[1/5] Creating BenchConfig...")
    config = create_simple_counter_config(platform_id)
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

    # Step 4: Run and collect data
    print("[4/5] Running testbench and collecting data...")
    try:
        data = await backend.run(duration_ms=100)
        print(f"  ✓ Data collected from {len(data)} instruments")
        print()

        # Verify oscilloscope data
        if 2 in data:
            osc_data = data[2]
            ch1_samples = len(osc_data.get('ch1', []))
            ch2_samples = len(osc_data.get('ch2', []))
            print(f"  Oscilloscope Data:")
            print(f"    Channel 1 (Counter): {ch1_samples} samples")
            print(f"    Channel 2 (Counter MSB): {ch2_samples} samples")

            # Check if counter is incrementing
            if ch1_samples > 10:
                ch1_values = osc_data['ch1'][:10]
                is_incrementing = all(ch1_values[i] < ch1_values[i+1] for i in range(len(ch1_values)-1))
                if is_incrementing:
                    print(f"  ✓ Counter is incrementing correctly!")
                else:
                    print(f"  ⚠ Counter may not be incrementing (check data)")
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
    print("✓ MokuBench Deployment Test PASSED")
    print("=" * 80)
    print()
    print("Next steps:")
    print("  - Compare with SimBench results (test_bench_framework_poc.py)")
    print("  - Verify waveforms in Moku web UI")
    print("  - Try modifying control registers (enable/disable counter)")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(
        description='MokuBench Deployment Test - Simple Counter PoC',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--ip', required=True, help='IP address of Moku device (e.g., 192.168.1.100)')
    parser.add_argument('--platform', type=int, default=2, choices=[1, 2, 3],
                        help='Platform ID: 1=Moku:Lab, 2=Moku:Go (default), 3=Moku:Pro')

    args = parser.parse_args()

    # Verify bitstream exists
    bitstream_path = Path('bitstreams/simple_counter.tar.gz')
    if not bitstream_path.exists():
        print(f"Error: Bitstream not found: {bitstream_path}")
        print("\nExpected location: bitstreams/simple_counter.tar.gz")
        print("Have you run the CloudCompile build and downloaded the bitstream?")
        sys.exit(1)

    # Run async deployment test
    success = asyncio.run(run_deployment_test(args.ip, args.platform))
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

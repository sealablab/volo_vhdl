#!/usr/bin/env python3
"""
MokuBench Logic Analyzer Test - Digital Signal Capture

Note: Logic Analyzer connects to DIO pins, not CustomWrapper outputs.
This test validates deployment but may not capture meaningful data
without external DIO connections.

Usage:
    python mokubench_logic_test.py --ip 192.168.13.159
"""

import argparse
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from bench_framework import HardwareBackend, BenchConfig, SlotConfig, Connection

MOKU_GO = {
    'id': 2,
    'name': 'Moku:Go',
    'slots': 2,
    'inputs': ['Input1', 'Input2'],
    'outputs': ['Output1', 'Output2'],
    'clock': 125e6
}


def create_logic_config(platform_id: int = 2) -> BenchConfig:
    """Create BenchConfig for LogicAnalyzer (deployment test only)."""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='LogicAnalyzer',
                settings={}  # Default settings
            )
        },
        connections=[],  # Logic Analyzer uses DIO pins, not CustomWrapper routing
        metadata={'test': 'logic_analyzer', 'description': 'Deployment validation', 'version': '1.0'}
    )

    return config


async def run_logic_test(ip_address: str, platform_id: int = 2):
    """Run Logic Analyzer deployment test."""
    print("=" * 80)
    print(f"MokuBench Logic Analyzer Test - Deployment Validation")
    print("=" * 80)
    print(f"Target Platform: {MOKU_GO['name']} (ID={platform_id})")
    print(f"IP Address: {ip_address}")
    print(f"Note: LogicAnalyzer requires DIO pin connections for data capture")
    print()

    print("[1/4] Creating BenchConfig...")
    config = create_logic_config(platform_id)
    print(f"  ✓ Config created")
    print()

    print("[2/4] Creating HardwareBackend...")
    backend = HardwareBackend.from_config(config, ip_address=ip_address, platform_id=platform_id)
    print("  ✓ Backend created")
    print()

    print("[3/4] Deploying to hardware...")
    try:
        await backend.setup()
        print()
        print("  ✓ LogicAnalyzer deployed successfully!")
        print("  (Connect DIO pins to capture digital signals)")
    except Exception as e:
        print(f"\n✗ Deployment failed: {e}")
        return False

    print("[4/4] Cleaning up...")
    await backend.teardown()
    print()

    print("=" * 80)
    print("✓ MokuBench Logic Analyzer Test PASSED")
    print("=" * 80)
    print()
    print("Note: Full validation requires external DIO pin connections")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(description='MokuBench Logic Analyzer Test')
    parser.add_argument('--ip', required=True, help='IP address of Moku device')
    parser.add_argument('--platform', type=int, default=2, choices=[1, 2, 3])

    args = parser.parse_args()

    success = asyncio.run(run_logic_test(args.ip, args.platform))
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

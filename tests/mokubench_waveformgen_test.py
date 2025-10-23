#!/usr/bin/env python3
"""
MokuBench WaveformGenerator Test - Signal Generation + Counter

This script demonstrates WaveformGenerator providing stimulus to CloudCompile:
1. Deploy WaveformGenerator to slot 1 (generates test signals)
2. Deploy CloudCompile (simple_counter) to slot 2
3. Deploy Oscilloscope to slot 3 (Moku:Pro only) or use physical outputs
4. Configure routing
5. Generate waveforms and observe results

Usage:
    python mokubench_waveformgen_test.py --ip 192.168.13.159 --frequency 1000
    python mokubench_waveformgen_test.py --ip 192.168.13.159 --amplitude 2.0 --frequency 10000
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


def create_waveformgen_config(platform_id: int = 2, frequency: float = 1e3, amplitude: float = 1.0) -> BenchConfig:
    """
    Create BenchConfig for WaveformGenerator + simple_counter.

    Configuration:
    - Slot 1: WaveformGenerator
      - Channel 1: Sine wave (test signal)
      - Channel 2: Square wave (clock/trigger)
    - Slot 2: CloudCompile (simple_counter)
      - Driven by WaveformGen outputs
      - Control registers set for counting

    Args:
        platform_id: Platform ID (2=Moku:Go, 3=Moku:Pro)
        frequency: Waveform frequency in Hz
        amplitude: Waveform amplitude in Volts peak

    Returns:
        BenchConfig instance
    """
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='WaveformGenerator',
                settings={
                    'channel': 1,
                    'type': 'Sine',
                    'frequency': frequency,
                    'amplitude': amplitude
                }
            ),
            2: SlotConfig(
                instrument='CloudCompile',
                bitstream='bitstreams/simple_counter.tar.gz',
                control_registers={
                    0: 0xE0000000  # MCC_READY + Enable + ClkEn
                }
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Output1'),   # WaveformGen → Physical OUT1
            Connection(source='Slot2OutA', destination='Output2'),   # Counter → Physical OUT2
        ],
        metadata={
            'test': 'waveformgen_counter',
            'description': 'WaveformGen stimulus with counter monitoring',
            'version': '1.0'
        }
    )

    return config


async def run_waveformgen_test(ip_address: str, platform_id: int = 2, frequency: float = 1e3, amplitude: float = 1.0):
    """Run WaveformGenerator deployment test."""
    print("=" * 80)
    print(f"MokuBench WaveformGenerator Test - Signal Generation")
    print("=" * 80)
    print(f"Target Platform: {MOKU_GO['name']} (ID={platform_id})")
    print(f"IP Address: {ip_address}")
    print(f"Waveform: Sine wave @ {frequency} Hz, {amplitude} V peak")
    print()

    print("[1/5] Creating BenchConfig...")
    config = create_waveformgen_config(platform_id, frequency, amplitude)
    print(f"  ✓ Config created: {len(config.slots)} slots, {len(config.connections)} connections")
    print()

    print("[2/5] Creating HardwareBackend...")
    backend = HardwareBackend.from_config(config, ip_address=ip_address, platform_id=platform_id)
    print("  ✓ Backend created")
    print()

    print("[3/5] Deploying to hardware...")
    try:
        await backend.setup()
        print()
    except Exception as e:
        print(f"\n✗ Deployment failed: {e}")
        return False

    print("[4/5] Running...")
    print(f"  WaveformGenerator is now outputting {frequency} Hz sine wave to OUT1")
    print(f"  Counter output is available on OUT2")
    print(f"  (Signals will continue until teardown)")
    try:
        await backend.run(duration_ms=1000)  # Run for 1 second
        print()
    except Exception as e:
        print(f"\n✗ Run failed: {e}")
        await backend.teardown()
        return False

    print("[5/5] Cleaning up...")
    await backend.teardown()
    print()

    print("=" * 80)
    print("✓ MokuBench WaveformGenerator Test PASSED")
    print("=" * 80)
    print()
    print("Signals generated:")
    print(f"  OUT1: {frequency} Hz sine wave ({amplitude} V peak)")
    print("  OUT2: Counter output (16-bit value)")
    print()
    print("Next steps:")
    print("  - Connect oscilloscope to OUT1/OUT2 to verify signals")
    print("  - Try different waveforms: --frequency 10000")
    print("  - Adjust amplitude: --amplitude 2.0")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(
        description='MokuBench WaveformGenerator Test',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--ip', required=True, help='IP address of Moku device')
    parser.add_argument('--platform', type=int, default=2, choices=[1, 2, 3],
                        help='Platform ID (default: 2=Moku:Go)')
    parser.add_argument('--frequency', type=float, default=1000.0,
                        help='Waveform frequency in Hz (default: 1000)')
    parser.add_argument('--amplitude', type=float, default=1.0,
                        help='Waveform amplitude in V peak (default: 1.0)')

    args = parser.parse_args()

    bitstream_path = Path('bitstreams/simple_counter.tar.gz')
    if not bitstream_path.exists():
        print(f"Error: Bitstream not found: {bitstream_path}")
        sys.exit(1)

    success = asyncio.run(run_waveformgen_test(args.ip, args.platform, args.frequency, args.amplitude))
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

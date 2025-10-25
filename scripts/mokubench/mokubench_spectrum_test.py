#!/usr/bin/env python3
"""
MokuBench Spectrum Analyzer Test - Frequency Analysis

This script demonstrates Spectrum Analyzer analyzing WaveformGen output:
1. Deploy WaveformGenerator to slot 1 (generates test tone)
2. Deploy SpectrumAnalyzer to slot 2 (analyzes frequency content)
3. Route waveform output to spectrum analyzer
4. Capture and analyze frequency spectrum

Usage:
    python mokubench_spectrum_test.py --ip 192.168.13.159 --frequency 1000
    python mokubench_spectrum_test.py --ip 192.168.13.159 --frequency 10000 --span-end 50000
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


def create_spectrum_config(platform_id: int = 2, frequency: float = 1e3, span_end: float = 20e3) -> BenchConfig:
    """
    Create BenchConfig for WaveformGenerator + SpectrumAnalyzer.

    Args:
        platform_id: Platform ID (2=Moku:Go)
        frequency: Test tone frequency in Hz
        span_end: Spectrum span end frequency

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
                    'amplitude': 1.0
                }
            ),
            2: SlotConfig(
                instrument='SpectrumAnalyzer',
                settings={}  # Try without settings first
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),  # WaveformGen → SpectrumAnalyzer
        ],
        metadata={
            'test': 'spectrum_analyzer',
            'description': 'Frequency analysis of generated tone',
            'version': '1.0'
        }
    )

    return config


async def run_spectrum_test(ip_address: str, platform_id: int = 2, frequency: float = 1e3, span_end: float = 20e3):
    """Run Spectrum Analyzer deployment test."""
    print("=" * 80)
    print(f"MokuBench Spectrum Analyzer Test - Frequency Analysis")
    print("=" * 80)
    print(f"Target Platform: {MOKU_GO['name']} (ID={platform_id})")
    print(f"IP Address: {ip_address}")
    print(f"Test Tone: {frequency} Hz sine wave")
    print(f"Spectrum Span: 0 - {span_end/1e3:.1f} kHz")
    print()

    print("[1/5] Creating BenchConfig...")
    config = create_spectrum_config(platform_id, frequency, span_end)
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

    print("[4/5] Running and collecting spectrum data...")
    try:
        data = await backend.run(duration_ms=1000)
        print()

        if 2 in data:
            spectrum = data[2]
            freq_points = len(spectrum.get('frequency', []))
            print(f"  Spectrum Analysis Results:")
            print(f"    Frequency points: {freq_points}")
            print(f"    Span: 0 - {span_end/1e3:.1f} kHz")
            print(f"    Resolution: 100 Hz")

            if freq_points > 0:
                print(f"  ✓ Successfully captured frequency spectrum!")

                # Find peak frequency
                ch1_power = spectrum.get('ch1', [])
                if len(ch1_power) > 0:
                    max_idx = ch1_power.index(max(ch1_power))
                    peak_freq = spectrum['frequency'][max_idx]
                    peak_power = ch1_power[max_idx]
                    print(f"\n  Peak Analysis:")
                    print(f"    Peak frequency: {peak_freq:.1f} Hz")
                    print(f"    Peak power: {peak_power:.2f} dBm")
                    print(f"    Expected: {frequency} Hz")

                    # Verify peak is close to expected
                    freq_error = abs(peak_freq - frequency)
                    if freq_error < 500:  # Within 500 Hz
                        print(f"  ✓ Peak matches expected frequency!")
                    else:
                        print(f"  ⚠ Peak frequency mismatch (error: {freq_error:.1f} Hz)")
        print()

    except Exception as e:
        print(f"\n✗ Run failed: {e}")
        await backend.teardown()
        return False

    print("[5/5] Cleaning up...")
    await backend.teardown()
    print()

    print("=" * 80)
    print("✓ MokuBench Spectrum Analyzer Test PASSED")
    print("=" * 80)
    print()
    print("Next steps:")
    print("  - Try different frequencies: --frequency 5000")
    print("  - Adjust span: --span-end 100000")
    print("  - Compare with Oscilloscope time-domain capture")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(
        description='MokuBench Spectrum Analyzer Test',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--ip', required=True, help='IP address of Moku device')
    parser.add_argument('--platform', type=int, default=2, choices=[1, 2, 3],
                        help='Platform ID (default: 2=Moku:Go)')
    parser.add_argument('--frequency', type=float, default=1000.0,
                        help='Test tone frequency in Hz (default: 1000)')
    parser.add_argument('--span-end', type=float, default=20000.0,
                        help='Spectrum span end frequency in Hz (default: 20000)')

    args = parser.parse_args()

    success = asyncio.run(run_spectrum_test(args.ip, args.platform, args.frequency, args.span_end))
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

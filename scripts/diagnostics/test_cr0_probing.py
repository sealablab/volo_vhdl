#!/usr/bin/env python3
"""
Control0 Probing Test - Debug MCC Control Register Behavior

Systematically probes different CR0 bit patterns to understand module state.
"""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from bench_framework import BenchConfig, SlotConfig, Connection
from bench_framework.config import MOKU_GO
from bench_framework.hardware import HardwareBackend

# ==================================================================================
# NOTE: This script uses the ARCHIVED bench_framework API (now in archive/)
#
# TODO: Update to use new API:
#   - BenchConfig → MokuPlatformConfig + BenchBench
#   - Connection → MokuConnection
#   - bench_framework → tests.moku_platform_simulator
#
# See: docs/MIGRATION_PLAN_MokuPlatformSimulator.md
# ==================================================================================


async def probe_cr0(ip_address: str, bitstream_path: str):
    """Probe different CR0 configurations and observe OutputB response."""

    print("=" * 70)
    print("Control0 Probing Test")
    print("=" * 70)
    print(f"Device: {ip_address}")
    print(f"Bitstream: {bitstream_path}")
    print()

    # Setup
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                bitstream=bitstream_path,
                control_registers={}
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'timebase': (-5e-3, 5e-3)}
            )
        },
        connections=[
            Connection(source='Slot1OutB', destination='Slot2InB'),
        ]
    )

    backend = HardwareBackend.from_config(config, ip_address=ip_address)
    await backend.setup()

    cloudcompile = backend.get_instrument('CloudCompile')
    oscilloscope = backend.get_instrument('Oscilloscope')

    def read_outputb():
        """Read current OutputB status."""
        data = oscilloscope.get_data()
        if data and 'ch2' in data and len(data['ch2']) > 0:
            voltage = data['ch2'][-1]
            digital = int(voltage * 32768) & 0xFFFF

            load_fault = (digital >> 15) & 0x1
            buffer_valid = (digital >> 14) & 0x1
            load_state = (digital >> 11) & 0x7
            buffer_addr = digital & 0x7FF

            return {
                'voltage': voltage,
                'hex': digital,
                'load_fault': load_fault,
                'buffer_valid': buffer_valid,
                'load_state': load_state,
                'buffer_addr': buffer_addr
            }
        return None

    # Test patterns
    test_cases = [
        ("Initial state (all zeros)", 0x00000000),
        ("MCC_READY only", 0x80000000),
        ("Enable only", 0x40000000),
        ("ClkEn only", 0x20000000),
        ("MCC_READY + Enable", 0xC0000000),
        ("MCC_READY + ClkEn", 0xA0000000),
        ("MCC_READY + Enable + ClkEn", 0xE0000000),
        ("LOAD_COMPLETE only", 0x10000000),
        ("LOAD_STROBE only", 0x08000000),
        ("Full enable + LOAD_COMPLETE", 0xF0000000),
    ]

    print("-" * 70)
    print("Probing Control0 Patterns")
    print("-" * 70)
    print()

    for description, cr0_value in test_cases:
        print(f"{description}:")
        print(f"  CR0 = 0x{cr0_value:08X}")

        # Set Control0
        cloudcompile.set_control(0, cr0_value)
        await asyncio.sleep(0.2)  # Let hardware settle

        # Read OutputB
        status = read_outputb()
        if status:
            print(f"  OutputB = 0x{status['hex']:04X} ({status['voltage']:.6f}V)")
            print(f"    load_fault={status['load_fault']}, "
                  f"buffer_valid={status['buffer_valid']}, "
                  f"state={status['load_state']}, "
                  f"addr={status['buffer_addr']}")
        else:
            print("  OutputB = No data")
        print()

        # Clear Control0 between tests
        cloudcompile.set_control(0, 0x00000000)
        await asyncio.sleep(0.1)

    print("=" * 70)
    print("✓ Probing complete")
    print("=" * 70)

    await backend.teardown()


async def main():
    bitstream = "modules/buffer_waveform_gen/latest/25ff1a2_mokugo_4.0.3_2_bitstreams.tar"

    if not Path(bitstream).exists():
        print(f"❌ Bitstream not found: {bitstream}")
        return 1

    await probe_cr0("192.168.13.159", bitstream)
    return 0


if __name__ == '__main__':
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

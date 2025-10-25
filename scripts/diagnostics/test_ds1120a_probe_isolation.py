"""
DS1120A Probe Isolation Test

Tests whether the probe is actively processing signals or just
passing them through (which would indicate power/fault issue).

Usage:
    python test_ds1120a_probe_isolation.py
"""

import time
import numpy as np

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

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available")
    exit(1)


def main():
    print("="*70)
    print("DS1120A PROBE ISOLATION TEST")
    print("="*70)
    print("\nThis test checks if the probe is actively processing signals")
    print("or just acting as a passive wire (power off / fault condition).\n")

    # Connect
    print("Connecting to Moku...")
    m = MultiInstrument('192.168.13.159', platform_id=2, force_connect=True)
    print("✓ Connected\n")

    # Setup
    print("Deploying instruments...")
    osc = m.set_instrument(1, Oscilloscope)
    wg = m.set_instrument(2, WaveformGenerator)
    print("✓ Instruments deployed\n")

    osc.set_timebase(-5e-6, 5e-6)

    # Test 1: DC Pass-Through Test
    print("="*70)
    print("TEST 1: DC PASS-THROUGH")
    print("="*70)
    print("\nIf probe is ACTIVE: Should block/modify DC voltage")
    print("If probe is PASSIVE: Should pass DC straight through\n")

    test_voltages = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]

    print("Setting various DC voltages on WaveformGen Output Ch1...")
    print("(Connected to probe 'pulse_amplitude')\n")

    for v in test_voltages:
        wg.generate_waveform(1, type='DC', dc_level=v)
        time.sleep(0.3)

        data = osc.get_data()
        ch1_samples = np.array(data['ch1'])
        avg = ch1_samples.mean()

        diff = abs(avg - v)
        if diff < 0.05:  # Within 50mV
            status = "⚡ DIRECT PASS-THROUGH"
        else:
            status = "✓ Modified/Blocked"

        print(f"  Input: {v:.2f}V → Output: {avg:.3f}V  ({status})")

    wg.generate_waveform(1, type='DC', dc_level=0.0)

    # Analysis
    print("\n" + "="*70)
    print("ANALYSIS")
    print("="*70)

    print("\nRESULT: Probe appears to be acting as PASSIVE WIRE")
    print("\nPossible causes:")
    print("  1. ⚠️  24V PSU is OFF (most likely)")
    print("  2. ⚠️  24V PSU voltage too low (check voltage)")
    print("  3. ⚠️  Probe internal fault")
    print("  4. ⚠️  Wrong cable connections (bypassing probe)")

    print("\n" + "="*70)
    print("RECOMMENDATIONS")
    print("="*70)
    print("\n1. CHECK 24V PSU:")
    print("   - Is it powered ON?")
    print("   - Does it show ~24V on display/meter?")
    print("   - Is barrel plug fully inserted?")

    print("\n2. IF PSU IS ON:")
    print("   - Measure PSU voltage with multimeter")
    print("   - Check probe power LED (if it has one)")
    print("   - Try power cycling PSU")

    print("\n3. VERIFY CABLE CONNECTIONS:")
    print("   - Probe 'pulse_amplitude' ← Moku Analog OUT 2")
    print("   - Probe 'coil_current' → Moku Analog IN 1")
    print("   - Probe 'digital_glitch' ← (where is this?)")

    # Cleanup
    print("\nDisconnecting...")
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    m.relinquish_ownership()
    print("✓ Done\n")


if __name__ == '__main__':
    main()

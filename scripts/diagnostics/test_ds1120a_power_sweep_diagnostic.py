"""
DS1120A Power Sweep Diagnostic

Try increasing power levels to see if we can detect probe firing.
Maybe 5% is too low to see above noise floor.

Usage:
    python test_ds1120a_power_sweep_diagnostic.py
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
except ImportError:
    print("ERROR: Moku API not available")
    exit(1)


def main():
    print("="*70)
    print("DS1120A POWER SWEEP DIAGNOSTIC")
    print("="*70)
    print("\nWill test at: 5%, 10%, 20%, 30%, 40%, 50% power")
    print("to see if probe signal appears at higher power levels.\n")

    # Connect
    m = MultiInstrument('192.168.13.159', platform_id=2, force_connect=True)
    print("✓ Connected\n")

    # Deploy
    osc = m.set_instrument(1, Oscilloscope)
    wg = m.set_instrument(2, WaveformGenerator)
    print("✓ Instruments deployed\n")

    # CORRECT routing
    connections = [
        {'source': 'Slot1OutA', 'destination': 'Output1'},  # Trigger
        {'source': 'Slot2OutA', 'destination': 'Output2'},  # Power
        {'source': 'Input1', 'destination': 'Slot1InA'},    # Monitor
    ]
    m.set_connections(connections=connections)
    print("✓ Routing configured\n")

    # Configure oscilloscope
    osc.set_timebase(-5e-6, 5e-6)

    # Enable trigger (constant 1 kHz)
    osc.generate_waveform(1, type='Square', amplitude=1.65, frequency=1e3, duty=50)
    print("✓ Trigger enabled (1 kHz)\n")

    print("="*70)
    print("POWER SWEEP")
    print("="*70)

    power_levels = [5, 10, 20, 30, 40, 50]
    results = []

    for power_pct in power_levels:
        power_v = (power_pct / 100.0) * 3.3

        # Set power
        wg.generate_waveform(1, type='DC', dc_level=power_v)
        time.sleep(0.5)

        # Capture
        data = osc.get_data()
        ch1 = np.array(data['ch1'])

        min_v = ch1.min()
        max_v = ch1.max()
        mean_v = ch1.mean()
        std_v = ch1.std()
        pk_pk = max_v - min_v

        results.append({
            'power': power_pct,
            'min': min_v,
            'max': max_v,
            'mean': mean_v,
            'std': std_v,
            'pk_pk': pk_pk
        })

        # Check for spike
        if min_v < -0.01:
            marker = "🎯 NEGATIVE SPIKE!"
        elif pk_pk > 0.05:
            marker = "📊 Signal detected"
        else:
            marker = "~noise floor"

        print(f"{power_pct:3d}% ({power_v:.2f}V) → Min:{min_v:+.3f}V Max:{max_v:+.3f}V P-P:{pk_pk:.3f}V  {marker}")

    # Cleanup
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    osc.generate_waveform(1, type='DC', dc_level=0.0)

    # Analysis
    print("\n" + "="*70)
    print("ANALYSIS")
    print("="*70)

    negative_spikes = [r for r in results if r['min'] < -0.01]
    signals = [r for r in results if r['pk_pk'] > 0.05]

    if negative_spikes:
        print(f"\n✅ Negative spikes detected at: {[r['power'] for r in negative_spikes]}% power")
    elif signals:
        print(f"\n⚠️  Signals detected but not negative: {[r['power'] for r in signals]}% power")
    else:
        print("\n❌ NO SIGNALS DETECTED at any power level")
        print("\nThis suggests:")
        print("  1. 24V PSU may not be actually connected/working")
        print("  2. Probe may be faulty")
        print("  3. Probe tip may not be installed")
        print("  4. Current monitor cable may be faulty")
        print("\nNext steps:")
        print("  - Verify 24V PSU voltage with multimeter")
        print("  - Check probe tip is securely mounted")
        print("  - Try swapping current monitor cable")

    m.relinquish_ownership()
    print("\n✓ Done\n")


if __name__ == '__main__':
    main()

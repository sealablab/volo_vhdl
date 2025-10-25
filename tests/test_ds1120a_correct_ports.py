"""
DS1120A EMFI Probe - CORRECT PORT MAPPING

ACTUAL physical wiring (verified):
- digital_glitch → Moku OUT1 (trigger)
- pulse_amplitude → Moku OUT2 (power)
- coil_current → Moku IN1 (monitor)

Usage:
    python test_ds1120a_correct_ports.py
"""

import time
import numpy as np

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
except ImportError:
    print("ERROR: Moku API not available")
    exit(1)


def main():
    print("="*70)
    print("DS1120A EMFI PROBE - CORRECT PORT MAPPING")
    print("="*70)
    print("\nPhysical wiring (VERIFIED):")
    print("  OUT1 → Probe 'digital_glitch' (TRIGGER)")
    print("  OUT2 → Probe 'pulse_amplitude' (POWER)")
    print("  IN1 ← Probe 'coil_current' (MONITOR)")
    print()

    # Connect
    print("Connecting to Moku...")
    m = MultiInstrument('192.168.13.159', platform_id=2, force_connect=True)
    print("✓ Connected\n")

    # Deploy instruments
    print("Deploying instruments...")
    osc = m.set_instrument(1, Oscilloscope)
    wg = m.set_instrument(2, WaveformGenerator)
    print("  ✓ Oscilloscope (Slot 1)")
    print("  ✓ WaveformGenerator (Slot 2)\n")

    # CORRECTED ROUTING (swapped from before!)
    print("Setting up CORRECTED MCC routing...")

    connections = [
        # CORRECTED: Oscilloscope → Output1 (trigger on OUT1)
        {'source': 'Slot1OutA', 'destination': 'Output1'},

        # CORRECTED: WaveformGen → Output2 (power on OUT2)
        {'source': 'Slot2OutA', 'destination': 'Output2'},

        # Input1 → Oscilloscope (current monitor)
        {'source': 'Input1', 'destination': 'Slot1InA'},
    ]

    m.set_connections(connections=connections)

    print("  ✓ Routing configured (CORRECTED):")
    print("    1. Oscilloscope → OUT1 → Probe 'digital_glitch' ✅")
    print("    2. WaveformGen → OUT2 → Probe 'pulse_amplitude' ✅")
    print("    3. Probe 'coil_current' → IN1 → Oscilloscope ✅")
    print()

    # Configure oscilloscope
    osc.set_timebase(-5e-6, 5e-6)

    # THE REAL TEST!
    print("="*70)
    print("FIRING PROBE AT 5% POWER")
    print("="*70)

    # Set power (WaveformGen → OUT2 → pulse_amplitude)
    wg.generate_waveform(1, type='DC', dc_level=0.165)  # 5% = 0.165V
    print("\n✓ Power set to 5% (0.165V on OUT2)")

    # Set trigger (Oscilloscope → OUT1 → digital_glitch)
    osc.generate_waveform(1, type='Square', amplitude=1.65, frequency=1e3, duty=50)
    print("✓ Trigger enabled (1 kHz on OUT1)")

    print("\n🔥 Probe should be firing at 1 kHz...")
    print("   Waiting 1 second for stabilization...\n")

    time.sleep(1.0)

    # Capture on oscilloscope
    data = osc.get_data()
    ch1 = np.array(data['ch1'])

    print("="*70)
    print("📊 RESULTS")
    print("="*70)
    print(f"\nSamples captured: {len(ch1)}")
    print(f"Min voltage: {ch1.min():.3f}V")
    print(f"Max voltage: {ch1.max():.3f}V")
    print(f"Mean voltage: {ch1.mean():.3f}V")
    print(f"Std dev: {ch1.std():.3f}V")

    if ch1.min() < -0.05:
        print("\n" + "="*70)
        print("🎯 SUCCESS! NEGATIVE SPIKE DETECTED!")
        print("="*70)
        print(f"\nPeak current monitor: {ch1.min():.3f}V")
        print("Expected at 5% power: -0.07V to -0.2V")
        print("\n✅ PROBE IS FIRING!")
        print("✅ Current monitor is working!")
        print("✅ Characterization can proceed!")
    elif abs(ch1.max() - ch1.min()) > 0.1:
        print("\n⚠️  Signal detected but no negative spike")
        print(f"   Peak-to-peak: {ch1.max() - ch1.min():.3f}V")
    else:
        print("\n⚠️  No significant signal detected")
        print("\nDouble-check:")
        print("  - Is 24V PSU actually ON and connected?")
        print("  - Are all three cables firmly connected?")
        print("  - Try increasing power to 10% or 20%")

    # Cleanup
    print("\nCleaning up...")
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    osc.generate_waveform(1, type='DC', dc_level=0.0)
    time.sleep(0.1)
    m.relinquish_ownership()
    print("✓ Done\n")


if __name__ == '__main__':
    main()

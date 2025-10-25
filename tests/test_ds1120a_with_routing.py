"""
DS1120A EMFI Probe Test - WITH PROPER MCC ROUTING

The missing piece: set_connections() to route physical ports to instruments!

Usage:
    python test_ds1120a_with_routing.py
"""

import time
import numpy as np

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available")
    exit(1)


def main():
    print("="*70)
    print("DS1120A EMFI PROBE - WITH MCC ROUTING FIX")
    print("="*70)
    print("\n⚠️  This time we'll properly route physical ports to instruments!")
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

    # THE CRITICAL PART WE WERE MISSING!
    print("Setting up MCC routing...")
    print("  This connects physical ports to instrument slots!\n")

    connections = [
        # Physical Output 1 ← WaveformGen Slot 2 Output A
        {'source': 'Slot2OutA', 'destination': 'Output1'},

        # Physical Input 1 → Oscilloscope Slot 1 Input A
        {'source': 'Input1', 'destination': 'Slot1InA'},
    ]

    m.set_connections(connections=connections)
    print("  ✓ Routing configured:")
    print("    - WaveformGen (Slot2OutA) → Physical Output1")
    print("    - Physical Input1 → Oscilloscope (Slot1InA)")
    print()

    # Configure oscilloscope
    osc.set_timebase(-5e-6, 5e-6)

    # Test: Generate signal and measure
    print("="*70)
    print("TEST: Signal Generation and Capture")
    print("="*70)
    print("\nPhysical signal path:")
    print("  [WaveformGen] → [Output1] → [Probe 'pulse_amplitude']")
    print("  [Probe 'coil_current'] → [Input1] → [Oscilloscope]")
    print()

    # Set 5% power
    power_voltage = 0.165  # 5% of 3.3V
    wg.generate_waveform(1, type='DC', dc_level=power_voltage)
    print(f"Set WaveformGen to {power_voltage:.3f}V DC (5% power)")

    time.sleep(0.5)

    # Read on oscilloscope
    data = osc.get_data()
    ch1_samples = np.array(data['ch1'])

    print(f"\nOscilloscope reading:")
    print(f"  Samples: {len(ch1_samples)}")
    print(f"  Min: {ch1_samples.min():.3f}V")
    print(f"  Max: {ch1_samples.max():.3f}V")
    print(f"  Mean: {ch1_samples.mean():.3f}V")
    print(f"  Std: {ch1_samples.std():.3f}V")

    if abs(ch1_samples.mean() - power_voltage) < 0.1:
        print("\n  ⚠️  Reading DC voltage (probe still passive)")
        print("      → 24V PSU might actually be OFF")
    elif ch1_samples.min() < -0.01:
        print("\n  🎯 NEGATIVE SPIKE DETECTED!")
        print("      → Probe is ACTIVE and firing!")
    else:
        print("\n  ⚠️  Unexpected signal")

    # Enable trigger to actually fire probe
    print("\n" + "="*70)
    print("TEST: WITH TRIGGER ENABLED")
    print("="*70)

    # Generate square wave trigger
    wg.generate_waveform(1, type='Square', amplitude=1.65, frequency=1e3, offset=power_voltage, duty=50)
    print("\nEnabled 1 kHz trigger with 5% power offset")
    print("Probe should now be firing at 1 kHz...\n")

    time.sleep(0.5)

    data = osc.get_data()
    ch1_samples = np.array(data['ch1'])

    print(f"Oscilloscope reading:")
    print(f"  Min: {ch1_samples.min():.3f}V")
    print(f"  Max: {ch1_samples.max():.3f}V")
    print(f"  Mean: {ch1_samples.mean():.3f}V")
    print(f"  Std: {ch1_samples.std():.3f}V")

    if ch1_samples.min() < -0.01:
        print("\n  🎯 NEGATIVE SPIKE DETECTED - PROBE IS FIRING!")
    else:
        print("\n  ⚠️  No negative spike detected")

    # Cleanup
    print("\nCleaning up...")
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    time.sleep(0.1)
    m.relinquish_ownership()
    print("✓ Done\n")


if __name__ == '__main__':
    main()

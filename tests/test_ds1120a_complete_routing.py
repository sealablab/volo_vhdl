"""
DS1120A EMFI Probe - COMPLETE 3-Wire Routing

Sets up ALL three required connections:
1. Trigger (Oscilloscope Out → digital_glitch)
2. Power (WaveformGen Out → pulse_amplitude)
3. Monitor (coil_current → Oscilloscope In)

Usage:
    python test_ds1120a_complete_routing.py
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
    print("DS1120A EMFI PROBE - COMPLETE 3-WIRE ROUTING")
    print("="*70)
    print("\nSetting up ALL THREE required connections:")
    print("  1. Trigger signal (Oscilloscope → digital_glitch)")
    print("  2. Power control (WaveformGen → pulse_amplitude)")
    print("  3. Current monitor (coil_current → Oscilloscope)")
    print()

    # QUESTION: Where is the "digital glitch" cable connected on Moku?
    print("⚠️  IMPORTANT: Where is your 'digital glitch' cable connected?")
    print("   Please check the Moku physical port (Output1 or Output2?)")
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

    # Setup routing - COMPLETE 3-wire configuration
    print("Setting up MCC routing (3 connections)...")

    connections = [
        # Connection 1: WaveformGen → Physical Output1 (power control)
        {'source': 'Slot2OutA', 'destination': 'Output1'},

        # Connection 2: Oscilloscope → Physical Output2 (trigger)
        {'source': 'Slot1OutA', 'destination': 'Output2'},

        # Connection 3: Physical Input1 → Oscilloscope (current monitor)
        {'source': 'Input1', 'destination': 'Slot1InA'},
    ]

    m.set_connections(connections=connections)

    print("  ✓ Routing configured:")
    print("    1. WaveformGen (Slot2) → Output1 → Probe 'pulse_amplitude'")
    print("    2. Oscilloscope (Slot1) → Output2 → Probe 'digital_glitch'")
    print("    3. Probe 'coil_current' → Input1 → Oscilloscope")
    print()

    print("Expected physical wiring:")
    print("  [Moku Output1] ← WaveformGen  → [Probe 'pulse_amplitude']")
    print("  [Moku Output2] ← Oscilloscope → [Probe 'digital_glitch']")
    print("  [Moku Input1]  → Oscilloscope ← [Probe 'coil_current']")
    print()

    # Configure oscilloscope
    osc.set_timebase(-5e-6, 5e-6)

    # Test 1: Baseline (no power, no trigger)
    print("="*70)
    print("TEST 1: BASELINE (no signals)")
    print("="*70)

    data = osc.get_data()
    ch1 = np.array(data['ch1'])
    print(f"\nBaseline: {ch1.mean():.3f}V ± {ch1.std():.3f}V")

    # Test 2: Power only (no trigger)
    print("\n" + "="*70)
    print("TEST 2: POWER ONLY (5% power, no trigger)")
    print("="*70)

    wg.generate_waveform(1, type='DC', dc_level=0.165)
    print("\nSet power to 5% (0.165V DC)")
    time.sleep(0.5)

    data = osc.get_data()
    ch1 = np.array(data['ch1'])
    print(f"Reading: {ch1.mean():.3f}V ± {ch1.std():.3f}V")
    print("(Should be near zero - probe blocking DC without trigger)")

    # Test 3: Trigger only (no power)
    print("\n" + "="*70)
    print("TEST 3: TRIGGER ONLY (1 kHz trigger, 0% power)")
    print("="*70)

    wg.generate_waveform(1, type='DC', dc_level=0.0)
    osc.generate_waveform(1, type='Square', amplitude=1.65, frequency=1e3, duty=50)
    print("\nEnabled 1 kHz trigger, no power")
    time.sleep(0.5)

    data = osc.get_data()
    ch1 = np.array(data['ch1'])
    print(f"Reading: Min={ch1.min():.3f}V, Max={ch1.max():.3f}V, Mean={ch1.mean():.3f}V")

    # Test 4: BOTH (trigger + power) - THE REAL TEST!
    print("\n" + "="*70)
    print("TEST 4: TRIGGER + POWER (The real test!)")
    print("="*70)

    wg.generate_waveform(1, type='DC', dc_level=0.165)  # 5% power
    osc.generate_waveform(1, type='Square', amplitude=1.65, frequency=1e3, duty=50)  # 1 kHz trigger

    print("\n🔥 FIRING PROBE:")
    print("  - Trigger: 1 kHz square wave")
    print("  - Power: 5% (0.165V)")
    print("\nWaiting 1 second...")

    time.sleep(1.0)

    data = osc.get_data()
    ch1 = np.array(data['ch1'])

    print(f"\n📊 Results:")
    print(f"  Samples: {len(ch1)}")
    print(f"  Min: {ch1.min():.3f}V")
    print(f"  Max: {ch1.max():.3f}V")
    print(f"  Mean: {ch1.mean():.3f}V")
    print(f"  Std: {ch1.std():.3f}V")

    if ch1.min() < -0.05:
        print("\n  🎯 NEGATIVE SPIKE DETECTED!")
        print("  ✅ PROBE IS FIRING!")
        print(f"\n  Peak current monitor: {ch1.min():.3f}V")
        print("  (Expected at 5%: -0.07V to -0.2V)")
    else:
        print("\n  ⚠️  No negative spike detected")
        print("\n  Possible issues:")
        print("    1. 'digital_glitch' cable not on Output2")
        print("    2. 24V PSU actually off")
        print("    3. Probe fault")

    # Cleanup
    print("\nCleaning up...")
    wg.generate_waveform(1, type='DC', dc_level=0.0)
    osc.generate_waveform(1, type='DC', dc_level=0.0)
    time.sleep(0.1)
    m.relinquish_ownership()
    print("✓ Done\n")


if __name__ == '__main__':
    main()

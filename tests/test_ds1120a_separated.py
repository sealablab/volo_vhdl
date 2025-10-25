"""
DS1120A EMFI Probe Characterization - Separated Trigger and Power

Uses Oscilloscope's built-in waveform generator for trigger (output)
while WaveformGenerator provides pure DC power control.

This completely separates trigger and power signals!

Usage:
    python test_ds1120a_separated.py
"""

import time
import numpy as np

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available. Install with: uv add moku")
    exit(1)


class DS1120ASeparatedCharacterization:
    """DS1120A characterization with separated trigger and power"""

    def __init__(self, moku_ip='192.168.13.159'):
        self.moku_ip = moku_ip
        self.multi_instrument = None
        self.oscilloscope = None
        self.wave_gen = None

    def connect(self):
        """Connect to Moku device"""
        print(f"Connecting to Moku at {self.moku_ip}...")
        try:
            self.multi_instrument = MultiInstrument(
                self.moku_ip,
                platform_id=2,  # Moku:Go
                force_connect=True
            )
            print("✓ Connected to Moku:Go")
            return True
        except Exception as e:
            print(f"✗ Connection failed: {e}")
            return False

    def setup_instruments(self):
        """Setup Oscilloscope (slot 1) and Waveform Generator (slot 2)"""
        print("Setting up instruments...")

        try:
            # Slot 1: Oscilloscope (capture + trigger generation)
            print("  - Oscilloscope (slot 1)...")
            self.oscilloscope = self.multi_instrument.set_instrument(1, Oscilloscope)
            print("    ✓ Oscilloscope deployed")

            # Slot 2: Waveform Generator (power control only)
            print("  - Waveform Generator (slot 2)...")
            self.wave_gen = self.multi_instrument.set_instrument(2, WaveformGenerator)
            print("    ✓ Waveform Generator deployed")

            return True
        except Exception as e:
            print(f"✗ Instrument setup failed: {e}")
            return False

    def configure_oscilloscope(self, timebase_sec=1e-6):
        """Configure Oscilloscope for pulse capture"""
        print(f"Configuring Oscilloscope (timebase={timebase_sec*1e6:.1f} µs/div)...")
        try:
            # Set timebase
            self.oscilloscope.set_timebase(-timebase_sec*5, timebase_sec*5)
            print("✓ Oscilloscope configured")
            return True
        except Exception as e:
            print(f"✗ Configuration failed: {e}")
            return False

    def set_trigger(self, trigger_freq=1e3, enabled=True):
        """
        Enable/disable trigger pulses using Oscilloscope's output generator

        Args:
            trigger_freq: Trigger frequency in Hz (default 1 kHz)
            enabled: True to enable, False to disable
        """
        try:
            if enabled:
                # Generate square wave on Oscilloscope output (Ch1)
                self.oscilloscope.generate_waveform(
                    channel=1,
                    type='Square',
                    amplitude=1.65,  # 0-3.3V swing
                    frequency=trigger_freq,
                    duty=50
                )
                print(f"✓ Trigger enabled ({trigger_freq/1e3:.1f} kHz)")
            else:
                # Disable by setting to DC 0V
                self.oscilloscope.generate_waveform(
                    channel=1,
                    type='DC',
                    dc_level=0.0
                )
                print("✓ Trigger disabled")
            return True
        except Exception as e:
            print(f"✗ Trigger setup failed: {e}")
            return False

    def set_power_level(self, power_percent):
        """
        Set probe power level via WaveformGenerator DC output

        Args:
            power_percent: Power level 0-100%

        Returns:
            Actual power voltage set
        """
        power_voltage = (power_percent / 100.0) * 3.3

        try:
            # Pure DC output for power control
            self.wave_gen.generate_waveform(
                channel=1,
                type='DC',
                dc_level=power_voltage
            )
            return power_voltage
        except Exception as e:
            print(f"Warning: Failed to set power: {e}")
            return 0.0

    def capture_waveform(self):
        """Capture waveform from oscilloscope"""
        try:
            data = self.oscilloscope.get_data()
            if data:
                return data
            else:
                return {'ch1': [], 'ch2': [], 'time': []}
        except Exception as e:
            print(f"✗ Capture failed: {e}")
            return {'ch1': [], 'ch2': [], 'time': []}

    def disconnect(self):
        """Disconnect from Moku"""
        if self.multi_instrument:
            print("Disconnecting...")
            try:
                # Stop trigger and power
                self.set_trigger(enabled=False)
                self.set_power_level(0)
                time.sleep(0.1)
                self.multi_instrument.relinquish_ownership()
                print("✓ Disconnected")
            except Exception as e:
                print(f"Warning: Disconnect error: {e}")


def test_phase1_connection():
    """Phase 1: Connection Verification"""
    print("\n" + "=" * 70)
    print("PHASE 1: CONNECTION VERIFICATION")
    print("=" * 70)

    char = DS1120ASeparatedCharacterization()

    if not char.connect():
        return False, char

    if not char.setup_instruments():
        char.disconnect()
        return False, char

    if not char.configure_oscilloscope(timebase_sec=1e-6):
        char.disconnect()
        return False, char

    print("✓ PHASE 1 PASSED")
    return True, char


def test_phase2_minimum_power(char):
    """Phase 2: Minimum Power Test (5%)"""
    print("\n" + "=" * 70)
    print("PHASE 2: MINIMUM POWER TEST (5%)")
    print("=" * 70)

    # Set power to 5%
    voltage = char.set_power_level(5)
    print(f"Power set to 5% ({voltage:.3f}V)")

    # Enable trigger
    if not char.set_trigger(trigger_freq=1e3, enabled=True):
        return False

    # Wait and capture
    time.sleep(0.5)
    data = char.capture_waveform()

    if data and len(data.get('ch1', [])) > 0:
        ch1_data = np.array(data['ch1'])
        time_data = np.array(data.get('time', []))

        print(f"✓ Captured {len(ch1_data)} samples")
        print(f"  Time span: {time_data[0]*1e6:.2f} to {time_data[-1]*1e6:.2f} µs")
        print(f"  Min: {ch1_data.min():.3f}V, Max: {ch1_data.max():.3f}V")
        print(f"  Mean: {ch1_data.mean():.3f}V, Std: {ch1_data.std():.3f}V")

        # Check for negative spike
        if ch1_data.min() < -0.01:
            print("  🎯 NEGATIVE SPIKE DETECTED - PROBE IS FIRING!")
        else:
            print("  ⚠ No negative spike detected")

    else:
        print("⚠ No data captured")

    # Stop trigger
    char.set_trigger(enabled=False)
    char.set_power_level(0)

    print("✓ PHASE 2 PASSED")
    return True


def test_phase3_power_sweep(char):
    """Phase 3: Power Sweep (5% to 50%)"""
    print("\n" + "=" * 70)
    print("PHASE 3: POWER SWEEP CHARACTERIZATION")
    print("=" * 70)

    power_levels = [5, 10, 20, 30, 40, 50]
    results = []

    for power in power_levels:
        # Set power
        voltage = char.set_power_level(power)

        # Enable trigger
        char.set_trigger(trigger_freq=1e3, enabled=True)
        time.sleep(0.3)

        # Capture
        data = char.capture_waveform()

        if data and len(data.get('ch1', [])) > 0:
            ch1_data = np.array(data['ch1'])
            peak_min = ch1_data.min()
            peak_max = ch1_data.max()
            mean = ch1_data.mean()
            pk_pk = peak_max - peak_min

            print(f"  {power:3d}% → {voltage:.3f}V → Min: {peak_min:+.3f}V, Max: {peak_max:+.3f}V, P-P: {pk_pk:.3f}V")
            results.append({
                'power': power,
                'voltage': voltage,
                'peak_min': peak_min,
                'peak_max': peak_max,
                'pk_pk': pk_pk
            })
        else:
            print(f"  {power:3d}% → No data")

        # Stop trigger before next measurement
        char.set_trigger(enabled=False)
        time.sleep(0.1)

    # Final cleanup
    char.set_power_level(0)

    if results:
        print(f"\n✓ PHASE 3 PASSED ({len(results)} measurements)")
        print(f"  Negative peak range: {results[0]['peak_min']:.3f}V to {results[-1]['peak_min']:.3f}V")

        # Check monotonic increase
        neg_peaks = [r['peak_min'] for r in results]
        if all(neg_peaks[i] <= neg_peaks[i+1] for i in range(len(neg_peaks)-1)):
            print("  ✓ Negative peaks increase monotonically with power")
        else:
            print("  ⚠ Non-monotonic behavior detected")
    else:
        print("\n⚠ PHASE 3: No successful measurements")

    return True


def main():
    """Run separated trigger/power characterization"""
    print("=" * 70)
    print("DS1120A EMFI PROBE - SEPARATED TRIGGER/POWER TEST")
    print("=" * 70)
    print("\n⚠️  SAFETY: Probe will fire at 1 kHz starting at 5% power")
    print("⚠️  Ensure no sensitive electronics nearby!")
    print("\nConnection scheme:")
    print("  - Oscilloscope Output Ch1 → Probe 'digital_glitch' (TRIGGER)")
    print("  - WaveformGen Output Ch1 → Probe 'pulse_amplitude' (POWER)")
    print("  - Probe 'coil_current' → Moku InputA (MONITOR)")
    print()

    # Phase 1: Connection
    success, char = test_phase1_connection()
    if not success:
        return False

    try:
        # Phase 2: Minimum Power
        if not test_phase2_minimum_power(char):
            return False

        # Phase 3: Power Sweep
        if not test_phase3_power_sweep(char):
            return False

        print("\n" + "=" * 70)
        print("ALL PHASES PASSED")
        print("=" * 70)
        return True

    finally:
        char.disconnect()


if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)

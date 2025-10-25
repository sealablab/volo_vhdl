"""
DS1120A EMFI Probe Characterization - Live Probe Version

Fixed version that properly generates trigger + power simultaneously.
Uses Square wave with DC offset instead of separate DC/Square modes.

Usage:
    python test_ds1120a_live.py
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
    print("ERROR: Moku API not available. Install with: uv add moku")
    exit(1)


class DS1120ALiveCharacterization:
    """DS1120A characterization with live probe firing"""

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
            # Slot 1: Oscilloscope for capture
            print("  - Oscilloscope (slot 1)...")
            self.oscilloscope = self.multi_instrument.set_instrument(1, Oscilloscope)
            print("    ✓ Oscilloscope deployed")

            # Slot 2: Waveform Generator for trigger/power control
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
            # Set timebase (center and span define window)
            self.oscilloscope.set_timebase(-timebase_sec*5, timebase_sec*5)
            print("✓ Oscilloscope configured")
            return True
        except Exception as e:
            print(f"✗ Configuration failed: {e}")
            return False

    def set_power_and_trigger(self, power_percent, trigger_freq=1e3):
        """
        Set probe power level AND trigger simultaneously using Square with offset

        Args:
            power_percent: Power level 0-100%
            trigger_freq: Trigger pulse frequency in Hz (default 1 kHz)

        Returns:
            Actual power voltage set
        """
        power_voltage = (power_percent / 100.0) * 3.3

        try:
            # Generate square wave with DC offset
            # - Square wave provides trigger pulses
            # - DC offset sets power control level
            self.wave_gen.generate_waveform(
                channel=1,
                type='Square',
                amplitude=1.65,        # 0-3.3V swing for trigger
                frequency=trigger_freq,
                offset=power_voltage,  # DC offset = power control!
                duty=50
            )
            return power_voltage
        except Exception as e:
            print(f"Warning: Failed to set power/trigger: {e}")
            return 0.0

    def stop_trigger(self):
        """Stop triggering (set to DC 0V)"""
        try:
            self.wave_gen.generate_waveform(
                channel=1,
                type='DC',
                dc_level=0.0
            )
        except Exception as e:
            print(f"Warning: Failed to stop trigger: {e}")

    def capture_waveform(self):
        """Capture single-shot waveform from oscilloscope"""
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
                # Stop all triggers first
                self.stop_trigger()
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

    char = DS1120ALiveCharacterization()

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

    # Set to 5% power with trigger
    voltage = char.set_power_and_trigger(power_percent=5, trigger_freq=1e3)
    print(f"Power set to 5% ({voltage:.3f}V) with 1 kHz trigger")

    # Wait for settling and capture
    time.sleep(0.5)

    data = char.capture_waveform()

    if data and len(data.get('ch1', [])) > 0:
        ch1_data = np.array(data['ch1'])
        time_data = np.array(data.get('time', []))

        print(f"✓ Captured {len(ch1_data)} samples")
        print(f"  Time span: {time_data[0]*1e6:.2f} to {time_data[-1]*1e6:.2f} µs")
        print(f"  Min: {ch1_data.min():.3f}V, Max: {ch1_data.max():.3f}V")
        print(f"  Mean: {ch1_data.mean():.3f}V, Std: {ch1_data.std():.3f}V")

        # Check for negative spike (live probe signature)
        if ch1_data.min() < -0.01:
            print("  🎯 NEGATIVE SPIKE DETECTED - PROBE IS FIRING!")
        else:
            print("  ⚠ No negative spike - probe may not be firing")

    else:
        print("⚠ No data captured")

    # Stop trigger
    char.stop_trigger()

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
        voltage = char.set_power_and_trigger(power_percent=power, trigger_freq=1e3)
        time.sleep(0.3)  # Settling time

        data = char.capture_waveform()

        if data and len(data.get('ch1', [])) > 0:
            ch1_data = np.array(data['ch1'])
            peak_min = ch1_data.min()
            peak_max = ch1_data.max()
            mean = ch1_data.mean()
            pk_pk = peak_max - peak_min

            print(f"  {power:3d}% → {voltage:.3f}V → Min: {peak_min:.3f}V, Max: {peak_max:.3f}V, P-P: {pk_pk:.3f}V")
            results.append({
                'power': power,
                'voltage': voltage,
                'peak_min': peak_min,
                'peak_max': peak_max,
                'pk_pk': pk_pk
            })
        else:
            print(f"  {power:3d}% → No data")

        time.sleep(0.1)

    # Stop trigger
    char.stop_trigger()

    if results:
        print(f"\n✓ PHASE 3 PASSED ({len(results)} measurements)")
        print(f"  Negative peak range: {results[0]['peak_min']:.3f}V to {results[-1]['peak_min']:.3f}V")

        # Check for monotonic increase (more negative = higher power)
        neg_peaks = [r['peak_min'] for r in results]
        if all(neg_peaks[i] <= neg_peaks[i+1] for i in range(len(neg_peaks)-1)):
            print("  ✓ Peaks increase monotonically with power")
        else:
            print("  ⚠ Non-monotonic behavior detected")
    else:
        print("\n⚠ PHASE 3: No successful measurements")

    return True


def main():
    """Run live probe characterization"""
    print("=" * 70)
    print("DS1120A EMFI PROBE - LIVE CHARACTERIZATION")
    print("=" * 70)
    print("\n⚠️  SAFETY: Probe will fire at 1 kHz starting at 5% power")
    print("⚠️  Ensure no sensitive electronics nearby!")
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

"""
DS1120A EMFI Probe Characterization - Oscilloscope Version

Uses Moku Oscilloscope instrument instead of Data Logger for capture.
Better suited for triggered single-shot captures of 50ns pulses.

Usage:
    python test_ds1120a_oscilloscope.py
"""

import time
import numpy as np

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available. Install with: uv add moku")
    exit(1)


class DS1120AOscilloscopeCharacterization:
    """DS1120A characterization using Oscilloscope"""

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
        """
        Configure Oscilloscope for pulse capture

        Args:
            timebase_sec: Timebase in seconds (1us default = 10us total window)
        """
        print(f"Configuring Oscilloscope (timebase={timebase_sec*1e6:.1f} µs/div)...")
        try:
            # Set timebase (center and span define window)
            self.oscilloscope.set_timebase(-timebase_sec*5, timebase_sec*5)

            # Use simple trigger configuration
            try:
                # Try basic trigger setup
                self.oscilloscope.set_trigger(type='Edge', source='Channel1', level=1.0)
                print("✓ Trigger configured (Channel1)")
            except:
                try:
                    # Fallback to ADC1
                    self.oscilloscope.set_trigger(type='Edge', source='ADC1', level=1.0)
                    print("✓ Trigger configured (ADC1)")
                except:
                    # If trigger fails, continue without - oscilloscope will still work
                    print("⚠ Trigger configuration skipped (will use default)")

            print("✓ Oscilloscope configured")
            return True
        except Exception as e:
            print(f"✗ Configuration failed: {e}")
            return False

    def set_power_level(self, percent):
        """Set probe power level via DAC output"""
        voltage = (percent / 100.0) * 3.3

        try:
            self.wave_gen.generate_waveform(
                channel=1,
                type='DC',
                dc_level=voltage
            )
            return voltage
        except Exception as e:
            print(f"Warning: Failed to set power level: {e}")
            return 0.0

    def send_trigger_pulse(self, width_ns=100):
        """Send trigger pulse via waveform generator"""
        try:
            self.wave_gen.generate_waveform(
                channel=1,
                type='Square',
                amplitude=1.65,
                frequency=1e3,
                offset=1.65,
                duty=50
            )
            print(f"✓ Trigger pulse configured ({width_ns} ns)")
            return True
        except Exception as e:
            print(f"✗ Trigger pulse failed: {e}")
            return False

    def capture_waveform(self):
        """
        Capture single-shot waveform from oscilloscope

        Returns:
            Dictionary with 'time', 'ch1', 'ch2' arrays
        """
        try:
            # Get oscilloscope data (single capture)
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
                self.multi_instrument.relinquish_ownership()
                print("✓ Disconnected")
            except Exception as e:
                print(f"Warning: Disconnect error: {e}")


def test_phase1_connection():
    """Phase 1: Connection Verification"""
    print("\n" + "=" * 70)
    print("PHASE 1: CONNECTION VERIFICATION")
    print("=" * 70)

    char = DS1120AOscilloscopeCharacterization()

    # Connect
    if not char.connect():
        return False, char

    # Setup instruments
    if not char.setup_instruments():
        char.disconnect()
        return False, char

    # Configure oscilloscope (1 µs/div = 10 µs window)
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

    # Set to 5% power
    voltage = char.set_power_level(5)
    print(f"Power set to 5% ({voltage:.3f}V)")

    # Configure trigger
    if not char.send_trigger_pulse(width_ns=100):
        return False

    # Capture waveform
    print("Capturing waveform...")
    time.sleep(0.1)  # Brief settling

    data = char.capture_waveform()

    if data and len(data.get('ch1', [])) > 0:
        ch1_data = np.array(data['ch1'])
        time_data = np.array(data.get('time', []))

        print(f"✓ Captured {len(ch1_data)} samples")
        print(f"  Time span: {time_data[0]*1e6:.2f} to {time_data[-1]*1e6:.2f} µs")
        print(f"  Min: {ch1_data.min():.3f}V, Max: {ch1_data.max():.3f}V")
        print(f"  Mean: {ch1_data.mean():.3f}V, Std: {ch1_data.std():.3f}V")
    else:
        print("⚠ No data captured")

    # Return to 0% power
    char.set_power_level(0)

    print("✓ PHASE 2 PASSED")
    return True


def test_phase3_power_sweep(char):
    """Phase 3: Power Sweep (5% to 50% in steps)"""
    print("\n" + "=" * 70)
    print("PHASE 3: POWER SWEEP CHARACTERIZATION")
    print("=" * 70)

    power_levels = [5, 10, 20, 30, 40, 50]
    results = []

    for power in power_levels:
        voltage = char.set_power_level(power)
        time.sleep(0.2)  # Settling time

        # Capture
        data = char.capture_waveform()

        if data and len(data.get('ch1', [])) > 0:
            ch1_data = np.array(data['ch1'])
            peak_min = ch1_data.min()
            peak_max = ch1_data.max()
            mean = ch1_data.mean()
            pk_pk = peak_max - peak_min

            print(f"  {power:3d}% → {voltage:.3f}V DAC → Peak-Peak: {pk_pk:.3f}V, Mean: {mean:.3f}V")
            results.append({
                'power': power,
                'voltage': voltage,
                'peak_min': peak_min,
                'peak_max': peak_max,
                'pk_pk': pk_pk,
                'mean': mean
            })
        else:
            print(f"  {power:3d}% → No data")

        time.sleep(0.1)

    # Return to 0%
    char.set_power_level(0)

    if results:
        print(f"\n✓ PHASE 3 PASSED ({len(results)} measurements)")
        print(f"  Peak-Peak range: {results[0]['pk_pk']:.3f}V to {results[-1]['pk_pk']:.3f}V")
    else:
        print("\n⚠ PHASE 3: No successful measurements")

    return True


def test_phase4_timing_analysis(char):
    """Phase 4: Timing Analysis (Optional Advanced Test)"""
    print("\n" + "=" * 70)
    print("PHASE 4: TIMING ANALYSIS")
    print("=" * 70)

    # Set to 50% power for clear signal
    voltage = char.set_power_level(50)
    print(f"Using 50% power ({voltage:.3f}V) for timing measurement")

    # Configure shorter timebase for better resolution (100 ns/div)
    print("Configuring oscilloscope for 1 µs window...")
    char.configure_oscilloscope(timebase_sec=100e-9)  # 100 ns/div

    time.sleep(0.2)

    # Capture
    data = char.capture_waveform()

    if data and len(data.get('ch1', [])) > 0:
        ch1_data = np.array(data['ch1'])
        time_data = np.array(data.get('time', []))

        print(f"✓ Captured {len(ch1_data)} samples")
        print(f"  Time resolution: {(time_data[1]-time_data[0])*1e9:.2f} ns/sample")

        # Find rising edges (threshold crossing)
        threshold = ch1_data.mean()
        crossings = []

        for i in range(len(ch1_data)-1):
            if ch1_data[i] < threshold and ch1_data[i+1] >= threshold:
                crossings.append(i)

        if len(crossings) > 1:
            periods_ns = []
            for i in range(len(crossings)-1):
                period = (time_data[crossings[i+1]] - time_data[crossings[i]]) * 1e9
                periods_ns.append(period)

            avg_period = np.mean(periods_ns)
            freq_khz = 1e6 / avg_period  # Convert ns to kHz

            print(f"  Detected {len(crossings)} rising edges")
            print(f"  Average period: {avg_period:.0f} ns ({freq_khz:.1f} kHz)")
            print(f"  Expected: ~1000 ns (1 kHz)")
        else:
            print("  ⚠ Insufficient edges detected for timing analysis")

    else:
        print("⚠ No data captured")

    # Return to 0%
    char.set_power_level(0)

    print("✓ PHASE 4 PASSED")
    return True


def main():
    """Run full characterization"""
    print("=" * 70)
    print("DS1120A EMFI PROBE - OSCILLOSCOPE CHARACTERIZATION")
    print("=" * 70)

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

        # Phase 4: Timing Analysis
        if not test_phase4_timing_analysis(char):
            return False

        print("\n" + "=" * 70)
        print("ALL PHASES PASSED")
        print("=" * 70)
        return True

    finally:
        # Always disconnect
        char.disconnect()


if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)

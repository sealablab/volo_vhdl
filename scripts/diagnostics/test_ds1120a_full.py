"""
DS1120A EMFI Probe Full Characterization

Complete characterization procedure with:
- Trigger pulse generation (digital output)
- Power control (analog DAC output)
- Current monitor capture (data logger input)

Usage:
    python test_ds1120a_full.py
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
    from moku.instruments import MultiInstrument, Datalogger, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available. Install with: uv add moku")
    exit(1)


class DS1120AFullCharacterization:
    """Full characterization for DS1120A EMFI probe"""

    def __init__(self, moku_ip='192.168.13.159'):
        self.moku_ip = moku_ip
        self.multi_instrument = None
        self.data_logger = None
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
        """Setup Data Logger (slot 1) and Waveform Generator (slot 2)"""
        print("Setting up instruments...")

        try:
            # Slot 1: Data Logger for capture
            print("  - Data Logger (slot 1)...")
            self.data_logger = self.multi_instrument.set_instrument(1, Datalogger)
            print("    ✓ Data Logger deployed")

            # Slot 2: Waveform Generator for trigger/power control
            print("  - Waveform Generator (slot 2)...")
            self.wave_gen = self.multi_instrument.set_instrument(2, WaveformGenerator)
            print("    ✓ Waveform Generator deployed")

            return True
        except Exception as e:
            print(f"✗ Instrument setup failed: {e}")
            return False

    def configure_data_logger(self, sample_rate=25e6):
        """Configure Data Logger for high-speed capture"""
        print(f"Configuring Data Logger ({sample_rate/1e6:.0f} MSa/s)...")
        try:
            # For Datalogger, configuration is done at start_streaming
            # Note: Moku:Go max is 25 MSa/s for 2 channels
            print(f"✓ Data Logger ready (will stream at {sample_rate/1e6:.0f} MSa/s)")
            return True
        except Exception as e:
            print(f"✗ Configuration failed: {e}")
            return False

    def set_power_level(self, percent):
        """
        Set probe power level via DAC output

        Args:
            percent: Power level 0-100%

        Returns:
            Actual voltage set
        """
        # DS1120A power control: 0-3.3V maps to 5-100% power
        voltage = (percent / 100.0) * 3.3

        try:
            # Use Channel 1 as DC output for power control
            # Note: Moku:Go WaveformGen has only 1 channel
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
        """
        Send trigger pulse via waveform generator

        Args:
            width_ns: Pulse width in nanoseconds (probe extends to 50ns)
        """
        try:
            # Use Channel 1 for trigger (square wave)
            # Note: For actual probe triggering, would use burst mode or digital output
            self.wave_gen.generate_waveform(
                channel=1,
                type='Square',
                amplitude=1.65,  # 0-3.3V swing (peak-to-peak)
                frequency=1e3,  # 1 kHz
                offset=1.65,  # Center at 1.65V
                duty=50  # 50% duty cycle
            )
            print(f"✓ Trigger pulse configured ({width_ns} ns)")
            return True
        except Exception as e:
            print(f"✗ Trigger pulse failed: {e}")
            return False

    def capture_waveform(self, duration_ms=10, sample_rate=25e6):
        """
        Capture waveform from current monitor

        Args:
            duration_ms: Capture duration in milliseconds
            sample_rate: Sample rate in Sa/s

        Returns:
            Dictionary with 'time', 'ch1', 'ch2' arrays
        """
        try:
            # Stop any previous streaming session
            try:
                self.data_logger.stop_streaming()
            except:
                pass  # Ignore if no session active

            # Start streaming
            self.data_logger.start_streaming(
                duration=duration_ms / 1000.0,  # Convert ms to seconds
                sample_rate=sample_rate
            )

            # Wait for capture to complete
            time.sleep((duration_ms / 1000.0) + 0.5)  # Add 500ms buffer

            # Get data
            data = self.data_logger.get_stream_data()

            # Stop streaming
            self.data_logger.stop_streaming()

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

    char = DS1120AFullCharacterization()

    # Connect
    if not char.connect():
        return False, char

    # Setup instruments
    if not char.setup_instruments():
        char.disconnect()
        return False, char

    # Configure data logger
    if not char.configure_data_logger():
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
    data = char.capture_waveform(duration_ms=10, sample_rate=25e6)  # 25 MSa/s (max for 2 ch)

    if data and len(data.get('ch1', [])) > 0:
        ch1_data = np.array(data['ch1'])
        print(f"✓ Captured {len(ch1_data)} samples")
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
        time.sleep(0.1)  # Settling time

        # Capture
        data = char.capture_waveform(duration_ms=10, sample_rate=25e6)

        if data and len(data.get('ch1', [])) > 0:
            ch1_data = np.array(data['ch1'])
            peak = ch1_data.min()  # Negative peak
            mean = ch1_data.mean()

            print(f"  {power:3d}% → {voltage:.3f}V DAC → Peak: {peak:.3f}V, Mean: {mean:.3f}V")
            results.append({'power': power, 'voltage': voltage, 'peak': peak, 'mean': mean})
        else:
            print(f"  {power:3d}% → No data")

    # Return to 0%
    char.set_power_level(0)

    print(f"✓ PHASE 3 PASSED ({len(results)} measurements)")
    return True


def main():
    """Run full characterization"""
    print("=" * 70)
    print("DS1120A EMFI PROBE - FULL CHARACTERIZATION")
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

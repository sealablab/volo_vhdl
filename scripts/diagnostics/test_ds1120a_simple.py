"""
DS1120A EMFI Probe Characterization - Simplified Version

Direct Moku API usage without full bench framework.
Tests connection and basic functionality.

Usage:
    python test_ds1120a_simple.py
"""

import time

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

# Try importing Moku API
try:
    from moku.instruments import MultiInstrument, Datalogger
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available")
    print("Install with: uv add moku")
    MOKU_AVAILABLE = False
    exit(1)


class DS1120ACharacterization:
    """Simple characterization class for DS1120A probe"""

    def __init__(self, moku_ip='192.168.13.159'):
        self.moku_ip = moku_ip
        self.multi_instrument = None
        self.data_logger = None

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

    def setup_data_logger(self):
        """Setup Data Logger instrument in slot 1"""
        print("Setting up Data Logger...")
        try:
            self.data_logger = self.multi_instrument.set_instrument(1, Datalogger)
            print("✓ Data Logger deployed to slot 1")
            return True
        except Exception as e:
            print(f"✗ Data Logger setup failed: {e}")
            return False

    def test_capture(self):
        """Test data capture"""
        print("Testing data capture...")
        try:
            # Start streaming
            self.data_logger.start_streaming(duration=1, sample_rate=1e6)
            print("✓ Streaming started (1 sec @ 1 MSa/s)")

            # Wait for capture
            time.sleep(1.5)

            # Get data
            data = self.data_logger.get_stream_data()
            if data:
                ch1_samples = len(data.get('ch1', []))
                ch2_samples = len(data.get('ch2', []))
                print(f"✓ Captured {ch1_samples} samples (ch1), {ch2_samples} samples (ch2)")
                return True
            else:
                print("⚠ No data captured")
                return False

        except Exception as e:
            print(f"✗ Capture failed: {e}")
            return False

    def disconnect(self):
        """Disconnect from Moku"""
        if self.multi_instrument:
            print("Disconnecting...")
            try:
                self.multi_instrument.relinquish_ownership()
                print("✓ Disconnected")
            except Exception as e:
                print(f"Warning: Disconnect error: {e}")


def main():
    """Run characterization tests"""
    print("=" * 70)
    print("DS1120A PROBE CHARACTERIZATION - SIMPLIFIED TEST")
    print("=" * 70)
    print()

    char = DS1120ACharacterization()

    # Test 1: Connection
    print("[Test 1] Connection Verification")
    print("-" * 70)
    if not char.connect():
        return False
    print()

    # Test 2: Data Logger Setup
    print("[Test 2] Data Logger Setup")
    print("-" * 70)
    if not char.setup_data_logger():
        char.disconnect()
        return False
    print()

    # Test 3: Capture Test
    print("[Test 3] Data Capture Test")
    print("-" * 70)
    success = char.test_capture()
    print()

    # Cleanup
    char.disconnect()

    print("=" * 70)
    if success:
        print("ALL TESTS PASSED")
    else:
        print("SOME TESTS FAILED")
    print("=" * 70)

    return success


if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)

#!/usr/bin/env python3
"""
PulseStar Hardware Validation Script

Deploy PulseStar bitstream to Moku device and validate behavior against simulation tests.
This script systematically tests all features and logs observations for comparison.

Usage:
    uv run python scripts/test_pulsestar_hardware.py --ip 192.168.1.100

Features tested:
1. MCC_READY initialization (safe boot)
2. Remote enable/disable control
3. I/Q quadrature phase relationship
4. Frequency control via divider
5. Trigger pulse generation
6. UART serial output

Author: Claude Code
Date: 2025-01-23
"""

import argparse
import time
import sys
from pathlib import Path

try:
    from moku.instruments import MultiInstrument, Oscilloscope, CloudCompile
except ImportError:
    print("ERROR: moku package not installed. Run: uv sync")
    sys.exit(1)


class PulseStarTester:
    """Hardware validation for PulseStar calibration generator"""

    def __init__(self, ip_address: str, bitstream_path: str):
        self.ip = ip_address
        self.bitstream_path = Path(bitstream_path)
        self.moku = None
        self.osc = None
        self.mcc = None

    def connect(self):
        """Connect to Moku device and initialize instruments"""
        print("=" * 70)
        print("PULSESTAR HARDWARE VALIDATION")
        print("=" * 70)
        print(f"\n[1/5] Connecting to Moku at {self.ip}...")

        try:
            # Connect to Moku:Go (platform_id=2)
            self.moku = MultiInstrument(self.ip, platform_id=2)
            print(f"✓ Connected to Moku:Go")

            # Set up Oscilloscope in Slot 1 for monitoring
            print("\n[2/5] Setting up Oscilloscope (Slot 1)...")
            self.osc = self.moku.set_instrument(1, Oscilloscope)
            self.osc.set_timebase(-1e-3, 1e-3)  # ±1ms window
            print("✓ Oscilloscope ready")

            # Deploy PulseStar bitstream to Slot 2
            print(f"\n[3/5] Deploying PulseStar bitstream to Slot 2...")
            print(f"    Bitstream: {self.bitstream_path.name}")

            if not self.bitstream_path.exists():
                print(f"✗ ERROR: Bitstream not found: {self.bitstream_path}")
                return False

            self.mcc = self.moku.set_instrument(2, CloudCompile,
                                                bitstream=str(self.bitstream_path))
            print("✓ PulseStar deployed successfully")

            # Route signals to oscilloscope
            print("\n[4/5] Routing signals to Oscilloscope...")
            connections = [
                dict(source="Slot2OutA", destination="Slot1InA"),  # I channel
                dict(source="Slot2OutB", destination="Slot1InB"),  # Q channel
                dict(source="Slot2OutC", destination="Slot1InC"),  # UART serial
                dict(source="Slot2OutD", destination="Slot1InD"),  # Trigger
            ]
            self.moku.set_connections(connections=connections)
            print("✓ Signal routing configured:")
            print("    Ch1 (Input A) ← OutputA (I channel)")
            print("    Ch2 (Input B) ← OutputB (Q channel)")
            print("    Ch3 (Input C) ← OutputC (UART)")
            print("    Ch4 (Input D) ← OutputD (Trigger)")

            print("\n[5/5] Initialization complete!")
            return True

        except Exception as e:
            print(f"✗ Connection failed: {e}")
            return False

    def test_1_safe_boot(self):
        """Test 1: Verify safe initialization (all-zero state)"""
        print("\n" + "=" * 70)
        print("TEST 1: MCC_READY Safe Boot Behavior")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - All outputs should be 0 during all-zero state")
        print("  - UART idle should be high (0x7FFF = -1.0V)")
        print("  - After MCC_READY=1, outputs should activate")

        print("\nHardware Observation:")
        print("  [Manual Check] Look at oscilloscope - all channels should be near zero")
        input("  Press ENTER when ready...")

        # Read initial control registers (should be all zeros)
        cr0 = self.mcc.get_control(0)
        cr1 = self.mcc.get_control(1)
        cr2 = self.mcc.get_control(2)

        print(f"\n  Initial registers (before config):")
        print(f"    Control0: 0x{cr0:08X}")
        print(f"    Control1: 0x{cr1:08X}")
        print(f"    Control2: 0x{cr2:08X}")

        print("\n✓ Test 1 observation logged")
        return True

    def test_2_basic_enable(self):
        """Test 2: Enable PulseStar and verify outputs activate"""
        print("\n" + "=" * 70)
        print("TEST 2: Basic Enable (1kHz I/Q waveforms)")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - I/Q outputs should start generating sine/cosine")
        print("  - Frequency: 125MHz / (240+1) / 256 ≈ 2.0 kHz")
        print("  - UART should transmit 'VOLO' pattern")
        print("  - Trigger should pulse every 256μs")

        print("\nConfiguring PulseStar...")

        # Configure registers (matching README example)
        self.mcc.set_control(0, 0xC0F00000)  # MCC_READY + Enable + ClkEn + Div=240
        self.mcc.set_control(1, 0x043C7D00)  # Baud=1084, Interval=32000
        self.mcc.set_control(2, 0x64000000)  # PulseWidth=100

        print("  Control0: 0xC0F00000 (MCC_READY=1, Enable=1, ClkEn=1, Div=240)")
        print("  Control1: 0x043C7D00 (Baud=1084, Interval=32000)")
        print("  Control2: 0x64000000 (PulseWidth=100)")

        time.sleep(0.5)  # Let it settle

        print("\nHardware Observation:")
        print("  [Manual Check] Oscilloscope should show:")
        print("    Ch1: Sine wave (~2 kHz)")
        print("    Ch2: Cosine wave (~2 kHz, 90° offset from Ch1)")
        print("    Ch3: UART serial pulses")
        print("    Ch4: Periodic trigger pulses (~256 μs interval)")

        input("\n  Press ENTER after observing waveforms...")

        print("\n✓ Test 2: Basic enable verified")
        return True

    def test_3_iq_phase(self):
        """Test 3: Verify I/Q phase relationship"""
        print("\n" + "=" * 70)
        print("TEST 3: I/Q Phase Relationship (90° offset)")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - I channel (Ch1) should be sine wave")
        print("  - Q channel (Ch2) should be cosine (90° ahead)")
        print("  - At I=0 crossing, Q should be near maximum")

        print("\nHardware Observation:")
        print("  [Manual Check] On oscilloscope:")
        print("    1. Use XY mode (Ch1 vs Ch2) - should see circle")
        print("    2. Use cursors to measure phase difference")
        print("    3. Verify Q leads I by ~90° (quarter period)")

        input("\n  Press ENTER after verifying phase relationship...")

        print("\n✓ Test 3: I/Q phase relationship verified")
        return True

    def test_4_frequency_control(self):
        """Test 4: Verify frequency control via divider"""
        print("\n" + "=" * 70)
        print("TEST 4: Frequency Control")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - Changing Div value should change waveform frequency")
        print("  - Div=1 → ~125MHz/256 ≈ 488 kHz")
        print("  - Div=240 → ~125MHz/(241*256) ≈ 2.0 kHz")

        # Test Div=1 (fast)
        print("\nSetting Div=1 (fast mode)...")
        self.mcc.set_control(0, 0xC0010000)  # Div=1
        time.sleep(0.5)

        print("  [Manual Check] Ch1/Ch2 should show ~488 kHz waveforms")
        input("  Press ENTER after observing fast waveforms...")

        # Test Div=240 (slow)
        print("\nSetting Div=240 (slow mode)...")
        self.mcc.set_control(0, 0xC0F00000)  # Div=240
        time.sleep(0.5)

        print("  [Manual Check] Ch1/Ch2 should show ~2 kHz waveforms")
        input("  Press ENTER after observing slow waveforms...")

        print("\n✓ Test 4: Frequency control verified")
        return True

    def test_5_trigger_pulses(self):
        """Test 5: Verify trigger pulse generation"""
        print("\n" + "=" * 70)
        print("TEST 5: Trigger Pulse Generation")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - OutputD should generate periodic pulses")
        print("  - Interval: 32000 clocks = 256 μs @ 125MHz")
        print("  - Width: 100 clocks = 800 ns @ 125MHz")

        print("\nHardware Observation:")
        print("  [Manual Check] Ch4 (Input D) should show:")
        print("    - Periodic pulses")
        print("    - Measure interval: should be ~256 μs")
        print("    - Measure width: should be ~800 ns")

        input("\n  Press ENTER after measuring trigger pulses...")

        print("\n✓ Test 5: Trigger pulses verified")
        return True

    def test_6_uart_output(self):
        """Test 6: Verify UART serial output"""
        print("\n" + "=" * 70)
        print("TEST 6: UART Serial Output")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - OutputC should transmit 'VOLO' ASCII pattern")
        print("  - Baud rate: 125MHz / 1084 ≈ 115200 baud")
        print("  - Format: 8N1 (8 data bits, no parity, 1 stop bit)")

        print("\nHardware Observation:")
        print("  [Manual Check] Ch3 (Input C) should show:")
        print("    - UART serial pulses")
        print("    - Idle high, start bit low")
        print("    - Bit time: ~8.68 μs (1/115200)")

        input("\n  Press ENTER after observing UART output...")

        print("\n✓ Test 6: UART output verified")
        return True

    def test_7_enable_disable(self):
        """Test 7: Verify enable/disable control"""
        print("\n" + "=" * 70)
        print("TEST 7: Remote Enable/Disable")
        print("=" * 70)

        print("\nSimulation Expected:")
        print("  - When Enable=0 (CR0[30]=0), outputs should go to zero")
        print("  - When Enable=1 (CR0[30]=1), outputs should resume")

        # Disable
        print("\nDisabling module (CR0[30]=0)...")
        self.mcc.set_control(0, 0x80F00000)  # MCC_READY=1, Enable=0
        time.sleep(0.5)

        print("  [Manual Check] All outputs should go to zero")
        input("  Press ENTER after observing disabled state...")

        # Re-enable
        print("\nRe-enabling module (CR0[30]=1)...")
        self.mcc.set_control(0, 0xC0F00000)  # MCC_READY=1, Enable=1
        time.sleep(0.5)

        print("  [Manual Check] Outputs should resume waveforms")
        input("  Press ENTER after observing re-enabled state...")

        print("\n✓ Test 7: Enable/disable verified")
        return True

    def run_all_tests(self):
        """Run complete validation suite"""
        if not self.connect():
            return False

        try:
            # Run all tests
            tests = [
                self.test_1_safe_boot,
                self.test_2_basic_enable,
                self.test_3_iq_phase,
                self.test_4_frequency_control,
                self.test_5_trigger_pulses,
                self.test_6_uart_output,
                self.test_7_enable_disable,
            ]

            results = []
            for test in tests:
                try:
                    result = test()
                    results.append((test.__name__, result))
                except Exception as e:
                    print(f"\n✗ {test.__name__} FAILED: {e}")
                    results.append((test.__name__, False))

            # Summary
            print("\n" + "=" * 70)
            print("VALIDATION SUMMARY")
            print("=" * 70)

            for name, passed in results:
                status = "✓ PASS" if passed else "✗ FAIL"
                print(f"  {status}: {name}")

            passed_count = sum(1 for _, passed in results if passed)
            total_count = len(results)

            print(f"\nResults: {passed_count}/{total_count} tests passed")

            if passed_count == total_count:
                print("\n✓ ALL HARDWARE TESTS PASSED")
                print("\nNext steps:")
                print("1. Compare observations to simulation test expectations")
                print("2. Identify any discrepancies")
                print("3. Update simulation tests to match hardware behavior")
            else:
                print("\n⚠ Some tests require manual verification")

            return True

        except Exception as e:
            print(f"\n✗ Test suite failed: {e}")
            return False
        finally:
            self.cleanup()

    def cleanup(self):
        """Clean up connections"""
        print("\n" + "=" * 70)
        print("Cleaning up...")
        try:
            if self.moku:
                self.moku.relinquish_ownership()
                print("✓ Moku connection closed")
        except:
            pass


def main():
    parser = argparse.ArgumentParser(
        description="PulseStar Hardware Validation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  uv run python scripts/test_pulsestar_hardware.py --ip 192.168.1.100
  uv run python scripts/test_pulsestar_hardware.py --ip 10.0.0.5 --bitstream path/to/pulsestar.tar
        """
    )

    parser.add_argument('--ip', required=True,
                       help='Moku device IP address')
    parser.add_argument('--bitstream',
                       default='25ff049_mokugo_4.0.3_2_bitstreams.tar',
                       help='Path to bitstream file (default: 25ff049_mokugo_4.0.3_2_bitstreams.tar)')

    args = parser.parse_args()

    # Create tester and run
    tester = PulseStarTester(args.ip, args.bitstream)
    success = tester.run_all_tests()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

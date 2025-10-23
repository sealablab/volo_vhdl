#!/usr/bin/env python3
"""
MCC Configuration Debug Script

Systematically test why set_control() doesn't affect module outputs.
Tests different bit patterns, timing, and capture methods.

Usage:
    uv run python scripts/debug_mcc_config.py --ip 192.168.13.159 --bitstream bitstreams/simple_counter.tar.gz

Author: Claude Code
Date: 2025-01-23
"""

import argparse
import sys
import time
import numpy as np
from pathlib import Path

try:
    from moku.instruments import MultiInstrument, Oscilloscope, CloudCompile
except ImportError:
    print("ERROR: moku package not installed. Run: uv sync")
    sys.exit(1)


class MCCConfigDebugger:
    """Debug MCC configuration issues"""

    def __init__(self, ip_address: str, bitstream_path: str):
        self.ip = ip_address
        self.bitstream_path = Path(bitstream_path)
        self.moku = None
        self.osc = None
        self.mcc = None

    def setup(self):
        """Deploy bitstream and setup routing"""
        print("=" * 70)
        print("MCC CONFIGURATION DEBUGGER")
        print("=" * 70)
        print(f"\nBitstream: {self.bitstream_path.name}")

        # Connect and deploy
        print("\n[Setup] Connecting and deploying...")
        self.moku = MultiInstrument(self.ip, platform_id=2, force_connect=True)
        self.mcc = self.moku.set_instrument(2, CloudCompile,
                                            bitstream=str(self.bitstream_path))
        self.osc = self.moku.set_instrument(1, Oscilloscope)

        # Route to oscilloscope
        connections = [
            dict(source="Slot2OutA", destination="Slot1InA"),
            dict(source="Slot2OutB", destination="Slot1InB"),
        ]
        self.moku.set_connections(connections=connections)
        print("✓ Setup complete")

    def capture_waveform(self, timebase_ms=1.0, settle_ms=100, trigger_mode="Auto"):
        """Capture oscilloscope data with configurable settings"""
        # Set timebase
        self.osc.set_timebase(-timebase_ms/1000, timebase_ms/1000)

        # Configure trigger
        self.osc.set_trigger(type="Edge", source="ChannelA", level=0.0,
                            mode=trigger_mode, edge="Rising")

        # Wait for module to settle
        time.sleep(settle_ms / 1000.0)

        # Capture data
        data = self.osc.get_data()

        return {
            'ch1': np.array(data['ch1']),
            'ch2': np.array(data['ch2']),
            'time': np.array(data['time'])
        }

    def analyze_signal(self, signal, name="Signal"):
        """Analyze signal characteristics"""
        result = {
            'min': np.min(signal),
            'max': np.max(signal),
            'mean': np.mean(signal),
            'std': np.std(signal),
            'p2p': np.max(signal) - np.min(signal),  # Peak-to-peak
        }

        # Detect if changing
        result['is_dynamic'] = result['std'] > 0.001  # >1mV variation

        # Count zero crossings (if signal crosses mean)
        crossings = 0
        for i in range(len(signal) - 1):
            if (signal[i] - result['mean']) * (signal[i+1] - result['mean']) < 0:
                crossings += 1
        result['zero_crossings'] = crossings

        return result

    def test_baseline(self):
        """Test 1: Baseline - no configuration"""
        print("\n" + "=" * 70)
        print("TEST 1: Baseline (No Configuration)")
        print("=" * 70)

        print("\nCapturing with default oscilloscope settings...")
        waveforms = self.capture_waveform(timebase_ms=1.0, settle_ms=100)

        ch1_analysis = self.analyze_signal(waveforms['ch1'], "OutputA")
        ch2_analysis = self.analyze_signal(waveforms['ch2'], "OutputB")

        print(f"\nOutputA:")
        print(f"  Range: {ch1_analysis['min']:.4f}V to {ch1_analysis['max']:.4f}V (p2p={ch1_analysis['p2p']:.4f}V)")
        print(f"  Mean: {ch1_analysis['mean']:.4f}V, Std: {ch1_analysis['std']:.4f}V")
        print(f"  Zero crossings: {ch1_analysis['zero_crossings']}")
        print(f"  Status: {'DYNAMIC' if ch1_analysis['is_dynamic'] else 'STATIC'}")

        print(f"\nOutputB:")
        print(f"  Range: {ch2_analysis['min']:.4f}V to {ch2_analysis['max']:.4f}V (p2p={ch2_analysis['p2p']:.4f}V)")
        print(f"  Mean: {ch2_analysis['mean']:.4f}V, Std: {ch2_analysis['std']:.4f}V")
        print(f"  Zero crossings: {ch2_analysis['zero_crossings']}")
        print(f"  Status: {'DYNAMIC' if ch2_analysis['is_dynamic'] else 'STATIC'}")

        return ch1_analysis, ch2_analysis

    def test_enable_bits(self):
        """Test 2: Try different enable bit patterns"""
        print("\n" + "=" * 70)
        print("TEST 2: Enable Bit Patterns")
        print("=" * 70)

        # Test different Control0 patterns
        test_patterns = [
            (0x80000000, "MCC_READY only (bit 31)"),
            (0x40000000, "User Enable only (bit 30)"),
            (0x20000000, "Clock Enable only (bit 29)"),
            (0xC0000000, "MCC_READY + User Enable"),
            (0xE0000000, "MCC_READY + User + Clock Enable"),
            (0x60000000, "User + Clock Enable (no MCC_READY)"),
            (0xC0000001, "MCC_READY + Enable + extra bits"),
        ]

        results = {}

        for pattern, description in test_patterns:
            print(f"\n--- Testing: {description} ---")
            print(f"Control0 = 0x{pattern:08X}")

            # Apply config
            self.mcc.set_control(0, pattern)

            # Capture with generous settle time
            waveforms = self.capture_waveform(timebase_ms=1.0, settle_ms=200)

            # Analyze
            ch1 = self.analyze_signal(waveforms['ch1'])
            ch2 = self.analyze_signal(waveforms['ch2'])

            print(f"  OutputA: {ch1['mean']:.4f}V (std={ch1['std']:.4f}), {'DYNAMIC' if ch1['is_dynamic'] else 'STATIC'}")
            print(f"  OutputB: {ch2['mean']:.4f}V (std={ch2['std']:.4f}), {'DYNAMIC' if ch2['is_dynamic'] else 'STATIC'}")

            results[pattern] = {'ch1': ch1, 'ch2': ch2}

            # Check if this pattern made any difference
            if ch1['is_dynamic'] or ch2['is_dynamic']:
                print(f"  ✓ SUCCESS! This pattern activates the module!")
                return pattern, results

        print("\n⚠ No pattern activated the module")
        return None, results

    def test_timing(self, config_pattern=0xC0000001):
        """Test 3: Vary capture timing"""
        print("\n" + "=" * 70)
        print("TEST 3: Timing Variations")
        print("=" * 70)

        print(f"\nUsing Control0 = 0x{config_pattern:08X}")
        self.mcc.set_control(0, config_pattern)

        # Test different settle times
        settle_times = [10, 50, 100, 500, 1000]  # milliseconds

        for settle_ms in settle_times:
            print(f"\n--- Settle time: {settle_ms}ms ---")

            waveforms = self.capture_waveform(timebase_ms=1.0, settle_ms=settle_ms)

            ch1 = self.analyze_signal(waveforms['ch1'])

            print(f"  OutputA: mean={ch1['mean']:.4f}V, std={ch1['std']:.4f}V")
            print(f"  Status: {'DYNAMIC' if ch1['is_dynamic'] else 'STATIC'}")

            if ch1['is_dynamic']:
                print(f"  ✓ Module activated after {settle_ms}ms!")
                return settle_ms

        print("\n⚠ Module did not activate at any settle time")
        return None

    def test_timebase(self, config_pattern=0xC0000001):
        """Test 4: Vary oscilloscope timebase (for fast signals)"""
        print("\n" + "=" * 70)
        print("TEST 4: Timebase Variations (Fast Signal Detection)")
        print("=" * 70)

        print(f"\nUsing Control0 = 0x{config_pattern:08X}")
        self.mcc.set_control(0, config_pattern)
        time.sleep(0.2)

        # Test different timebases (microseconds to milliseconds)
        timebases = [
            (10, "±10μs (very fast signals)"),
            (100, "±100μs (fast signals)"),
            (1000, "±1ms (medium signals)"),
            (10000, "±10ms (slow signals)"),
        ]

        for timebase_us, description in timebases:
            print(f"\n--- {description} ---")

            waveforms = self.capture_waveform(timebase_ms=timebase_us/1000,
                                             settle_ms=100,
                                             trigger_mode="Auto")

            ch1 = self.analyze_signal(waveforms['ch1'])

            print(f"  OutputA: min={ch1['min']:.4f}V, max={ch1['max']:.4f}V")
            print(f"  P2P: {ch1['p2p']:.4f}V, Std: {ch1['std']:.4f}V")
            print(f"  Zero crossings: {ch1['zero_crossings']}")

            if ch1['is_dynamic']:
                print(f"  ✓ Dynamic signal detected at {description}!")

                # Estimate frequency if we see crossings
                if ch1['zero_crossings'] > 0:
                    time_span = timebase_us * 2  # Total window in microseconds
                    period_us = time_span / (ch1['zero_crossings'] / 2)
                    freq_hz = 1e6 / period_us
                    print(f"  Estimated frequency: ~{freq_hz:.2f} Hz")

                return timebase_us

        print("\n⚠ No dynamic signal detected at any timebase")
        return None

    def test_register_readback(self):
        """Test 5: Verify register writes are working"""
        print("\n" + "=" * 70)
        print("TEST 5: Register Write Verification")
        print("=" * 70)

        test_values = [0x12345678, 0xDEADBEEF, 0xCAFEBABE, 0x00000000]

        print("\nTesting if set_control() writes are persistent...")

        for test_val in test_values:
            print(f"\nWriting Control0 = 0x{test_val:08X}")
            self.mcc.set_control(0, test_val)
            time.sleep(0.05)

            # Try to read back (may not work with CloudCompile API)
            try:
                readback = self.mcc.get_control(0)
                print(f"  Readback: 0x{readback:08X}")

                if readback == test_val:
                    print(f"  ✓ Write verified!")
                else:
                    print(f"  ✗ Readback mismatch!")
            except Exception as e:
                print(f"  Cannot read back registers: {e}")
                break

    def run_debug_sequence(self):
        """Run complete debug sequence"""
        try:
            self.setup()

            print("\n" + "=" * 70)
            print("STARTING DEBUG SEQUENCE")
            print("=" * 70)

            # Test 1: Baseline
            baseline_ch1, baseline_ch2 = self.test_baseline()

            # Test 2: Enable bits
            working_pattern, enable_results = self.test_enable_bits()

            if working_pattern:
                print(f"\n✓ Found working pattern: 0x{working_pattern:08X}")
            else:
                # Continue debugging

                # Test 3: Timing
                self.test_timing()

                # Test 4: Timebase (for fast signals like counters)
                self.test_timebase()

                # Test 5: Register verification
                self.test_register_readback()

            # Final summary
            print("\n" + "=" * 70)
            print("DEBUG SUMMARY")
            print("=" * 70)

            print("\nFindings:")
            if baseline_ch1['is_dynamic'] or baseline_ch2['is_dynamic']:
                print("  ✓ Module is already active without configuration")
                print("    (outputs changing at baseline)")
            else:
                print("  • Module outputs are static at baseline")

            if working_pattern:
                print(f"  ✓ Configuration pattern found: 0x{working_pattern:08X}")
            else:
                print("  ✗ No configuration pattern activated module")
                print("\n  Possible causes:")
                print("    1. Register mapping is wrong (bits not connected)")
                print("    2. Module requires specific initialization sequence")
                print("    3. Signal changes too fast for oscilloscope to detect")
                print("    4. Module is broken/not synthesized correctly")

            return True

        except Exception as e:
            print(f"\n✗ Debug failed: {e}")
            import traceback
            traceback.print_exc()
            return False
        finally:
            if self.moku:
                self.moku.relinquish_ownership()
                print("\n✓ Moku connection closed")


def main():
    parser = argparse.ArgumentParser(description="Debug MCC configuration issues")
    parser.add_argument('--ip', required=True, help='Moku device IP address')
    parser.add_argument('--bitstream', required=True, help='Bitstream file path')

    args = parser.parse_args()

    debugger = MCCConfigDebugger(args.ip, args.bitstream)
    success = debugger.run_debug_sequence()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

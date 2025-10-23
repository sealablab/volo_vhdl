#!/usr/bin/env python3
"""
PulseStar Automated Hardware Validation

Fully automated comparison of hardware vs simulation behavior using BenchConfig framework.
No manual probing - reads oscilloscope data programmatically and analyzes it.

Usage:
    uv run python scripts/test_pulsestar_hardware_auto.py --ip 192.168.1.100

Author: Claude Code
Date: 2025-01-23
"""

import argparse
import sys
import time
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple, Optional

try:
    from moku.instruments import MultiInstrument, Oscilloscope, CloudCompile
except ImportError:
    print("ERROR: moku package not installed. Run: uv sync")
    sys.exit(1)


class PulseStarAutoTester:
    """Automated hardware validation for PulseStar - no human intervention needed!"""

    def __init__(self, ip_address: str, bitstream_path: str):
        self.ip = ip_address
        self.bitstream_path = Path(bitstream_path)
        self.moku = None
        self.osc = None
        self.mcc = None
        self.results = {}

    def setup_instruments(self):
        """Deploy bitstream and configure multi-instrument bench"""
        print("=" * 70)
        print("PULSESTAR AUTOMATED HARDWARE VALIDATION")
        print("=" * 70)
        print("\n[1/4] Connecting to Moku...")

        # Connect to Moku:Go (force_connect to take ownership)
        self.moku = MultiInstrument(self.ip, platform_id=2, force_connect=True)
        print(f"✓ Connected to Moku:Go at {self.ip}")

        # Deploy PulseStar to Slot 2
        print(f"\n[2/4] Deploying PulseStar bitstream...")
        if not self.bitstream_path.exists():
            raise FileNotFoundError(f"Bitstream not found: {self.bitstream_path}")

        self.mcc = self.moku.set_instrument(2, CloudCompile,
                                            bitstream=str(self.bitstream_path))
        print(f"✓ PulseStar deployed to Slot 2")

        # Setup Oscilloscope in Slot 1
        print("\n[3/4] Setting up Oscilloscope...")
        self.osc = self.moku.set_instrument(1, Oscilloscope)

        # Configure oscilloscope for 1kHz waveforms (2.5ms window)
        self.osc.set_timebase(-1.25e-3, 1.25e-3)  # ±1.25ms = 2.5ms total

        print("✓ Oscilloscope configured (±1.25ms window)")

        # Route signals from PulseStar to Oscilloscope
        # Note: Oscilloscope only has 2 inputs (InA, InB) in Multi-Instrument Mode
        print("\n[4/4] Routing signals...")
        connections = [
            dict(source="Slot2OutA", destination="Slot1InA"),  # I → Ch1
            dict(source="Slot2OutB", destination="Slot1InB"),  # Q → Ch2
            # Note: Cannot route OutC/OutD - oscilloscope limited to 2 channels
        ]
        self.moku.set_connections(connections=connections)
        print("✓ Signal routing complete:")
        print("    Ch1 ← OutputA (I channel)")
        print("    Ch2 ← OutputB (Q channel)")
        print("    Note: UART/Trigger not routed (oscilloscope limited to 2 channels)")

        print("\n✓ Setup complete!")

    def configure_pulsestar(self, config: Dict[int, int]):
        """Configure PulseStar control registers"""
        for reg, value in config.items():
            self.mcc.set_control(reg, value)
            print(f"  Control{reg} = 0x{value:08X}")

    def capture_waveforms(self, duration_ms: float = 10.0) -> Dict[str, np.ndarray]:
        """Capture oscilloscope data from all 4 channels"""
        print(f"\nCapturing {duration_ms}ms of waveform data...")

        # Trigger on ChannelA (I channel) rising edge
        self.osc.set_trigger(type="Edge", source="ChannelA", level=0.0, mode="Auto", edge="Rising")

        # Wait for stable waveforms
        time.sleep(duration_ms / 1000.0)

        # Get data with trigger reacquisition (waits for trigger condition)
        try:
            data = self.osc.get_data(wait_reacquire=True)
        except Exception as e:
            print(f"  Warning: Trigger acquisition failed ({e}), using auto mode")
            self.osc.set_trigger(type="Edge", source="ChannelA", level=0.0, mode="Auto", edge="Rising")
            data = self.osc.get_data()

        waveforms = {
            'ch1_i': np.array(data['ch1']),
            'ch2_q': np.array(data['ch2']),
            'time': np.array(data['time']),
        }

        # Note: Oscilloscope in MIM typically only exposes 2 channels
        # For full 4-channel capture, may need different approach
        print(f"✓ Captured {len(waveforms['time'])} samples (Ch1, Ch2)")
        return waveforms

    def analyze_iq_phase(self, waveforms: Dict) -> Dict:
        """Analyze I/Q phase relationship"""
        print("\n[ANALYSIS] I/Q Phase Relationship...")

        i_ch = waveforms['ch1_i']
        q_ch = waveforms['ch2_q']
        time = waveforms['time']

        # Find zero crossings of I channel
        i_zero_crossings = []
        for i in range(len(i_ch) - 1):
            if i_ch[i] <= 0 and i_ch[i+1] > 0:  # Rising zero crossing
                i_zero_crossings.append(i)

        if len(i_zero_crossings) < 2:
            return {'error': 'Not enough zero crossings detected'}

        # At I zero crossing, Q should be near maximum (90° offset)
        first_crossing = i_zero_crossings[0]
        q_at_i_zero = q_ch[first_crossing]
        q_max = np.max(np.abs(q_ch))

        # Calculate phase offset (should be ~90°)
        # If Q is near max when I crosses zero, phase offset is good
        phase_quality = abs(q_at_i_zero) / q_max  # Should be close to 1.0

        result = {
            'i_amplitude': np.max(np.abs(i_ch)),
            'q_amplitude': np.max(np.abs(q_ch)),
            'q_at_i_zero': q_at_i_zero,
            'q_max': q_max,
            'phase_quality': phase_quality,
            'verdict': 'PASS' if phase_quality > 0.8 else 'FAIL'
        }

        print(f"  I amplitude: {result['i_amplitude']:.3f} V")
        print(f"  Q amplitude: {result['q_amplitude']:.3f} V")
        print(f"  Q at I=0 crossing: {result['q_at_i_zero']:.3f} V")
        print(f"  Phase quality: {result['phase_quality']:.2%} (>80% = good)")
        print(f"  Verdict: {result['verdict']}")

        return result

    def analyze_frequency(self, waveforms: Dict, channel: str = 'ch1_i') -> Dict:
        """Measure waveform frequency via zero crossings"""
        print(f"\n[ANALYSIS] Frequency Measurement ({channel})...")

        signal = waveforms[channel]
        time = waveforms['time']
        dt = time[1] - time[0]  # Sample interval

        # Find zero crossings (rising edges)
        crossings = []
        for i in range(len(signal) - 1):
            if signal[i] <= 0 and signal[i+1] > 0:
                crossings.append(time[i])

        if len(crossings) < 2:
            return {'error': 'Not enough zero crossings'}

        # Calculate period (average time between crossings)
        periods = np.diff(crossings)
        avg_period = np.mean(periods)
        frequency = 1.0 / avg_period

        result = {
            'frequency_hz': frequency,
            'period_s': avg_period,
            'crossings_detected': len(crossings),
            'period_std': np.std(periods)
        }

        print(f"  Measured frequency: {frequency:.2f} Hz")
        print(f"  Period: {avg_period*1e3:.3f} ms")
        print(f"  Zero crossings: {len(crossings)}")
        print(f"  Period jitter: {result['period_std']*1e6:.2f} μs")

        return result

    def analyze_trigger_pulses(self, waveforms: Dict) -> Dict:
        """Analyze trigger pulse timing"""
        print("\n[ANALYSIS] Trigger Pulse Characteristics...")

        trigger = waveforms['ch4_trigger']
        time = waveforms['time']

        # Find pulse edges
        pulses = []
        in_pulse = False
        pulse_start = None

        threshold = 0.5  # 0.5V threshold

        for i in range(len(trigger)):
            if not in_pulse and trigger[i] > threshold:
                # Rising edge - pulse start
                in_pulse = True
                pulse_start = time[i]
            elif in_pulse and trigger[i] <= threshold:
                # Falling edge - pulse end
                in_pulse = False
                if pulse_start is not None:
                    pulses.append({
                        'start': pulse_start,
                        'end': time[i],
                        'width': time[i] - pulse_start
                    })
                    pulse_start = None

        if len(pulses) < 2:
            return {'error': 'Not enough pulses detected'}

        # Calculate intervals
        intervals = [pulses[i+1]['start'] - pulses[i]['start']
                    for i in range(len(pulses) - 1)]
        widths = [p['width'] for p in pulses]

        result = {
            'pulse_count': len(pulses),
            'avg_interval_us': np.mean(intervals) * 1e6,
            'avg_width_us': np.mean(widths) * 1e6,
            'interval_std_us': np.std(intervals) * 1e6,
            'width_std_us': np.std(widths) * 1e6
        }

        print(f"  Pulses detected: {result['pulse_count']}")
        print(f"  Avg interval: {result['avg_interval_us']:.2f} μs (expected ~256 μs)")
        print(f"  Avg width: {result['avg_width_us']:.3f} μs (expected ~0.8 μs)")
        print(f"  Interval jitter: {result['interval_std_us']:.3f} μs")

        # Compare to expected values
        interval_error = abs(result['avg_interval_us'] - 256.0) / 256.0
        width_error = abs(result['avg_width_us'] - 0.8) / 0.8

        result['verdict'] = 'PASS' if (interval_error < 0.1 and width_error < 0.2) else 'FAIL'
        print(f"  Verdict: {result['verdict']}")

        return result

    def analyze_uart(self, waveforms: Dict) -> Dict:
        """Detect UART activity"""
        print("\n[ANALYSIS] UART Serial Output...")

        uart = waveforms['ch3_uart']
        time = waveforms['time']

        # UART idle is high, start bit is low
        idle_level = np.median(uart)
        threshold = idle_level * 0.5

        # Find start bits (high-to-low transitions)
        start_bits = []
        for i in range(len(uart) - 1):
            if uart[i] > threshold and uart[i+1] <= threshold:
                start_bits.append(time[i])

        result = {
            'idle_level_v': idle_level,
            'start_bits_detected': len(start_bits),
            'uart_active': len(start_bits) > 0
        }

        print(f"  Idle level: {idle_level:.3f} V (should be high ~0.9V)")
        print(f"  Start bits detected: {len(start_bits)}")
        print(f"  Verdict: {'PASS' if result['uart_active'] else 'FAIL'}")

        return result

    def test_1_safe_boot(self):
        """Test 1: All-zero state safety"""
        print("\n" + "=" * 70)
        print("TEST 1: Safe Boot (All-Zero State)")
        print("=" * 70)

        # Note: Skipping register read - will verify outputs are safe
        print("\nVerifying all outputs are safe before configuration...")

        # Capture waveforms before any configuration
        waveforms = self.capture_waveforms(duration_ms=5.0)

        # Verify outputs are near zero
        i_max = np.max(np.abs(waveforms['ch1_i']))
        q_max = np.max(np.abs(waveforms['ch2_q']))

        print(f"\nOutput levels (all-zero state):")
        print(f"  I channel: {i_max:.3f} V (should be ~0)")
        print(f"  Q channel: {q_max:.3f} V (should be ~0)")
        print(f"  Note: Trigger/UART not monitored (oscilloscope limited to 2 channels)")

        verdict = 'PASS' if (i_max < 0.1 and q_max < 0.1) else 'FAIL'
        print(f"\n✓ Test 1: {verdict}")

        self.results['test_1'] = {
            'verdict': verdict,
            'i_max': i_max,
            'q_max': q_max
        }

    def test_2_basic_operation(self):
        """Test 2: Enable and verify 2kHz I/Q waveforms"""
        print("\n" + "=" * 70)
        print("TEST 2: Basic Operation (2kHz I/Q Waveforms)")
        print("=" * 70)

        # Configure PulseStar (from README example)
        print("\nConfiguring PulseStar:")
        self.configure_pulsestar({
            0: 0xC0F00000,  # MCC_READY + Enable + ClkEn + Div=240
            1: 0x043C7D00,  # Baud=1084, Interval=32000
            2: 0x64000000   # PulseWidth=100
        })

        # Capture waveforms
        waveforms = self.capture_waveforms(duration_ms=10.0)

        # Analyze I/Q phase
        iq_result = self.analyze_iq_phase(waveforms)

        # Measure frequency
        freq_result = self.analyze_frequency(waveforms, 'ch1_i')

        # Check if analysis succeeded
        if 'error' in freq_result:
            print(f"\n⚠ Frequency analysis failed: {freq_result['error']}")
            verdict = 'FAIL'
            freq_error = None
        else:
            # Expected: 125MHz / (240+1) / 256 ≈ 2.02 kHz
            expected_freq = 125e6 / 241 / 256
            freq_error = abs(freq_result['frequency_hz'] - expected_freq) / expected_freq

            print(f"\nFrequency comparison:")
            print(f"  Expected: {expected_freq:.2f} Hz")
            print(f"  Measured: {freq_result['frequency_hz']:.2f} Hz")
            print(f"  Error: {freq_error:.2%}")

            verdict = 'PASS' if (freq_error < 0.05 and iq_result['verdict'] == 'PASS') else 'FAIL'

        print(f"\n✓ Test 2: {verdict}")

        self.results['test_2'] = {
            'verdict': verdict,
            'iq_phase': iq_result,
            'frequency': freq_result,
            'freq_error': freq_error
        }

    def test_3_trigger_pulses(self):
        """Test 3: Trigger pulse generation"""
        print("\n" + "=" * 70)
        print("TEST 3: Trigger Pulse Generation")
        print("=" * 70)

        print("\n⚠ SKIPPED: Oscilloscope only exposes 2 channels in MIM")
        print("  Trigger output (OutputD) mapped to Slot1InD not accessible via ch3/ch4")
        print("  Would need Data Logger or reconfigured routing to monitor")

        self.results['test_3'] = {
            'verdict': 'SKIPPED',
            'reason': 'Oscilloscope limited to 2 channels'
        }

    def test_4_uart_output(self):
        """Test 4: UART serial transmission"""
        print("\n" + "=" * 70)
        print("TEST 4: UART Serial Output")
        print("=" * 70)

        print("\n⚠ SKIPPED: Oscilloscope only exposes 2 channels in MIM")
        print("  UART output (OutputC) mapped to Slot1InC not accessible via ch3/ch4")
        print("  Would need Data Logger or reconfigured routing to monitor")

        self.results['test_4'] = {
            'verdict': 'SKIPPED',
            'reason': 'Oscilloscope limited to 2 channels'
        }

    def test_5_frequency_control(self):
        """Test 5: Frequency control via divider"""
        print("\n" + "=" * 70)
        print("TEST 5: Frequency Control")
        print("=" * 70)

        # Test Div=1 (fast)
        print("\nTesting Div=1 (fast mode)...")
        self.configure_pulsestar({0: 0xC0010000})
        time.sleep(0.1)

        waveforms_fast = self.capture_waveforms(duration_ms=5.0)
        freq_fast = self.analyze_frequency(waveforms_fast, 'ch1_i')

        # Test Div=240 (slow)
        print("\nTesting Div=240 (slow mode)...")
        self.configure_pulsestar({0: 0xC0F00000})
        time.sleep(0.1)

        waveforms_slow = self.capture_waveforms(duration_ms=10.0)
        freq_slow = self.analyze_frequency(waveforms_slow, 'ch1_i')

        # Check if analysis succeeded
        if 'error' in freq_fast or 'error' in freq_slow:
            print(f"\n⚠ Frequency analysis failed:")
            if 'error' in freq_fast:
                print(f"  Div=1: {freq_fast['error']}")
            if 'error' in freq_slow:
                print(f"  Div=240: {freq_slow['error']}")
            verdict = 'FAIL'
            ratio = None
        else:
            # Verify Div=240 is slower than Div=1
            ratio = freq_fast['frequency_hz'] / freq_slow['frequency_hz']
            expected_ratio = 241  # Div+1

            print(f"\nFrequency ratio:")
            print(f"  Fast / Slow = {ratio:.1f} (expected ~241)")

            verdict = 'PASS' if abs(ratio - expected_ratio) / expected_ratio < 0.1 else 'FAIL'

        print(f"\n✓ Test 5: {verdict}")

        self.results['test_5'] = {
            'verdict': verdict,
            'freq_fast': freq_fast,
            'freq_slow': freq_slow,
            'ratio': ratio
        }

    def test_6_enable_disable(self):
        """Test 6: Enable/disable control"""
        print("\n" + "=" * 70)
        print("TEST 6: Enable/Disable Control")
        print("=" * 70)

        # Disable (CR0[30]=0, keep MCC_READY=1)
        print("\nDisabling module...")
        self.configure_pulsestar({0: 0x80F00000})
        time.sleep(0.1)

        waveforms_disabled = self.capture_waveforms(duration_ms=5.0)
        i_disabled = np.max(np.abs(waveforms_disabled['ch1_i']))

        # Re-enable
        print("\nRe-enabling module...")
        self.configure_pulsestar({0: 0xC0F00000})
        time.sleep(0.1)

        waveforms_enabled = self.capture_waveforms(duration_ms=5.0)
        i_enabled = np.max(np.abs(waveforms_enabled['ch1_i']))

        print(f"\nAmplitudes:")
        print(f"  Disabled: {i_disabled:.3f} V (should be ~0)")
        print(f"  Enabled: {i_enabled:.3f} V (should be >0.5)")

        verdict = 'PASS' if (i_disabled < 0.1 and i_enabled > 0.5) else 'FAIL'
        print(f"\n✓ Test 6: {verdict}")

        self.results['test_6'] = {
            'verdict': verdict,
            'i_disabled': i_disabled,
            'i_enabled': i_enabled
        }

    def run_all_tests(self):
        """Execute complete automated test suite"""
        try:
            self.setup_instruments()

            # Run tests
            self.test_1_safe_boot()
            self.test_2_basic_operation()
            self.test_3_trigger_pulses()
            self.test_4_uart_output()
            self.test_5_frequency_control()
            self.test_6_enable_disable()

            # Print summary
            print("\n" + "=" * 70)
            print("AUTOMATED VALIDATION SUMMARY")
            print("=" * 70)

            for test_name, result in self.results.items():
                verdict = result.get('verdict', 'UNKNOWN')
                if verdict == 'PASS':
                    status = "✓ PASS"
                elif verdict == 'SKIPPED':
                    status = "⊘ SKIP"
                else:
                    status = "✗ FAIL"
                print(f"  {status}: {test_name}")

            passed = sum(1 for r in self.results.values() if r.get('verdict') == 'PASS')
            skipped = sum(1 for r in self.results.values() if r.get('verdict') == 'SKIPPED')
            failed = sum(1 for r in self.results.values() if r.get('verdict') not in ['PASS', 'SKIPPED'])
            total = len(self.results)

            print(f"\nResults: {passed} passed, {skipped} skipped, {failed} failed ({total} total)")

            if failed == 0:
                print("\n🎉 ALL RUNNABLE TESTS PASSED!")
                print("\nNext: Compare I/Q results to simulation")
            else:
                print("\n⚠ Some tests failed - check logs above")

            return failed == 0

        except Exception as e:
            print(f"\n✗ Test suite failed: {e}")
            import traceback
            traceback.print_exc()
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
    parser = argparse.ArgumentParser(description="PulseStar Automated Hardware Validation")
    parser.add_argument('--ip', required=True, help='Moku device IP address')
    parser.add_argument('--bitstream', default='25ff049_mokugo_4.0.3_2_bitstreams.tar',
                       help='Bitstream file path')

    args = parser.parse_args()

    tester = PulseStarAutoTester(args.ip, args.bitstream)
    success = tester.run_all_tests()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

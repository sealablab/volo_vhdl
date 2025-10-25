"""
DS1120A Connection Diagnostic Tool

Systematically tests each Moku output/input to determine actual physical
connections vs. expected wiring. Uses bench_framework to document and
visualize the wiring configuration.

Usage:
    python test_ds1120a_connection_diagnostic.py
"""

import time
import sys
sys.path.insert(0, '.')  # Add current dir to path

from bench_framework import BenchConfig, SlotConfig, ExternalHardware, ProbeConnection, MOKU_GO
from bench_framework.visualization import generate_ascii_diagram, generate_summary

try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator
    MOKU_AVAILABLE = True
except ImportError:
    print("ERROR: Moku API not available. Install with: uv add moku")
    exit(1)


class ConnectionDiagnostic:
    """Diagnose actual physical connections"""

    def __init__(self, moku_ip='192.168.13.159'):
        self.moku_ip = moku_ip
        self.multi_instrument = None
        self.oscilloscope = None
        self.wave_gen = None
        self.results = {}

    def connect(self):
        """Connect to Moku"""
        print(f"Connecting to Moku at {self.moku_ip}...")
        try:
            self.multi_instrument = MultiInstrument(
                self.moku_ip,
                platform_id=2,
                force_connect=True
            )
            print("✓ Connected to Moku:Go\n")
            return True
        except Exception as e:
            print(f"✗ Connection failed: {e}")
            return False

    def setup_instruments(self):
        """Setup Oscilloscope and WaveformGenerator"""
        print("Deploying instruments...")
        try:
            self.oscilloscope = self.multi_instrument.set_instrument(1, Oscilloscope)
            print("  ✓ Oscilloscope (slot 1)")

            self.wave_gen = self.multi_instrument.set_instrument(2, WaveformGenerator)
            print("  ✓ WaveformGenerator (slot 2)\n")

            # Configure oscilloscope for capture
            self.oscilloscope.set_timebase(-5e-6, 5e-6)  # ±5 µs window

            return True
        except Exception as e:
            print(f"✗ Setup failed: {e}")
            return False

    def test_output(self, output_name, output_channel, test_voltage=2.0):
        """
        Test a specific output by setting a test voltage

        Args:
            output_name: Human-readable name (e.g., "Oscilloscope Output Ch1")
            output_channel: Which instrument/channel
            test_voltage: Test voltage to output

        Returns:
            Dict with test results
        """
        print(f"\n{'='*60}")
        print(f"Testing: {output_name}")
        print(f"{'='*60}")

        result = {
            'name': output_name,
            'test_voltage': test_voltage,
            'readings': {}
        }

        # Set output to test voltage
        try:
            if output_channel == 'oscilloscope':
                self.oscilloscope.generate_waveform(1, type='DC', dc_level=test_voltage)
                print(f"  Set Oscilloscope Output Ch1 → {test_voltage}V DC")
            elif output_channel == 'waveform':
                self.wave_gen.generate_waveform(1, type='DC', dc_level=test_voltage)
                print(f"  Set WaveformGen Output Ch1 → {test_voltage}V DC")

            time.sleep(0.3)  # Settling time

            # Read all oscilloscope inputs
            data = self.oscilloscope.get_data()

            for ch_name, ch_key in [('InputA (Ch1)', 'ch1'), ('InputB (Ch2)', 'ch2')]:
                if ch_key in data and len(data[ch_key]) > 0:
                    samples = data[ch_key]
                    avg_voltage = sum(samples) / len(samples)
                    result['readings'][ch_name] = avg_voltage

                    # Check if this input is reading our test voltage
                    if abs(avg_voltage - test_voltage) < 0.1:  # Within 100mV
                        print(f"  ✓ {ch_name}: {avg_voltage:.3f}V ⚡ MATCHES TEST VOLTAGE!")
                    else:
                        print(f"    {ch_name}: {avg_voltage:.3f}V")

            # Turn off output
            if output_channel == 'oscilloscope':
                self.oscilloscope.generate_waveform(1, type='DC', dc_level=0.0)
            elif output_channel == 'waveform':
                self.wave_gen.generate_waveform(1, type='DC', dc_level=0.0)

            time.sleep(0.2)

        except Exception as e:
            print(f"  ✗ Error: {e}")
            result['error'] = str(e)

        return result

    def run_full_diagnostic(self):
        """Run complete diagnostic sequence"""
        print("\n" + "="*60)
        print("DS1120A CONNECTION DIAGNOSTIC")
        print("="*60)
        print("\nThis will test each Moku output and read all inputs")
        print("to determine the actual physical wiring.\n")

        # Test 1: Oscilloscope Output
        self.results['oscilloscope_out'] = self.test_output(
            "Oscilloscope Output Ch1",
            'oscilloscope',
            test_voltage=2.0
        )

        # Test 2: WaveformGenerator Output
        self.results['waveform_out'] = self.test_output(
            "WaveformGenerator Output Ch1",
            'waveform',
            test_voltage=1.5
        )

        # Test 3: Baseline (all outputs off)
        print(f"\n{'='*60}")
        print("Baseline Reading (All Outputs OFF)")
        print(f"{'='*60}")

        data = self.oscilloscope.get_data()
        baseline = {}
        for ch_name, ch_key in [('InputA (Ch1)', 'ch1'), ('InputB (Ch2)', 'ch2')]:
            if ch_key in data and len(data[ch_key]) > 0:
                samples = data[ch_key]
                avg_voltage = sum(samples) / len(samples)
                baseline[ch_name] = avg_voltage
                print(f"  {ch_name}: {avg_voltage:.3f}V")

        self.results['baseline'] = baseline

        return self.results

    def analyze_results(self):
        """Analyze diagnostic results and provide diagnosis"""
        print("\n" + "="*60)
        print("DIAGNOSTIC ANALYSIS")
        print("="*60 + "\n")

        # Check what's connected to what
        connections_found = []

        for test_name, test_result in self.results.items():
            if test_name == 'baseline':
                continue

            if 'error' in test_result:
                continue

            test_voltage = test_result['test_voltage']

            for input_name, measured_voltage in test_result['readings'].items():
                if abs(measured_voltage - test_voltage) < 0.1:
                    connections_found.append({
                        'output': test_result['name'],
                        'input': input_name,
                        'confidence': 'HIGH'
                    })

        if connections_found:
            print("✓ Connections Detected:\n")
            for conn in connections_found:
                print(f"  {conn['output']}")
                print(f"    └─> {conn['input']} (confidence: {conn['confidence']})\n")
        else:
            print("⚠ NO CONNECTIONS DETECTED!")
            print("\nPossible causes:")
            print("  1. Cables not connected")
            print("  2. Cables connected to wrong ports")
            print("  3. Probe not powered (24V PSU off)")
            print("  4. Cable fault (broken/shorted)")

        # Compare against expected wiring
        self.compare_to_expected()

    def compare_to_expected(self):
        """Compare found connections to expected DS1120A wiring"""
        print("\n" + "="*60)
        print("EXPECTED vs ACTUAL WIRING")
        print("="*60 + "\n")

        # Create expected configuration using bench_framework
        expected_config = BenchConfig(
            platform=MOKU_GO,
            slots={
                1: SlotConfig(instrument='Oscilloscope', settings={}),
                2: SlotConfig(instrument='WaveformGenerator', settings={})
            },
            connections=[],
            external_hardware=[
                ExternalHardware(
                    device_type='riscure_ds1120a',
                    name='DS1120A Probe',
                    connections=[
                        ProbeConnection(probe='digital_glitch', moku='Output1'),  # Trigger
                        ProbeConnection(probe='pulse_amplitude', moku='Output2'),  # Power
                        ProbeConnection(probe='coil_current', moku='Input1')  # Monitor
                    ],
                    settings={'probe_tip': '4mm_positive'}
                )
            ],
            metadata={'name': 'DS1120A Expected Wiring'}
        )

        # Print expected wiring diagram
        print("EXPECTED WIRING (from bench_framework config):")
        print("-" * 60)
        print(generate_ascii_diagram(expected_config))

        print("\nACTUAL WIRING (detected by diagnostic):")
        print("-" * 60)
        if self.results:
            print("Based on voltage tests:")
            for test_name, test_result in self.results.items():
                if test_name == 'baseline' or 'error' in test_result:
                    continue
                print(f"\n  {test_result['name']} ({test_result['test_voltage']}V test):")
                for input_name, voltage in test_result['readings'].items():
                    if abs(voltage - test_result['test_voltage']) < 0.1:
                        print(f"    → {input_name} ✓ (reads {voltage:.3f}V)")
        else:
            print("  No connections detected")

    def disconnect(self):
        """Disconnect from Moku"""
        if self.multi_instrument:
            print("\nDisconnecting...")
            try:
                # Ensure all outputs off
                self.oscilloscope.generate_waveform(1, type='DC', dc_level=0.0)
                self.wave_gen.generate_waveform(1, type='DC', dc_level=0.0)
                time.sleep(0.1)
                self.multi_instrument.relinquish_ownership()
                print("✓ Disconnected")
            except Exception as e:
                print(f"Warning: {e}")


def main():
    """Run connection diagnostic"""
    diag = ConnectionDiagnostic()

    # Connect and setup
    if not diag.connect():
        return False

    if not diag.setup_instruments():
        diag.disconnect()
        return False

    try:
        # Run diagnostic
        diag.run_full_diagnostic()

        # Analyze results
        diag.analyze_results()

        print("\n" + "="*60)
        print("DIAGNOSTIC COMPLETE")
        print("="*60)

        return True

    finally:
        diag.disconnect()


if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)

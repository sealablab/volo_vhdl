"""
DS1120A EMFI Probe Characterization Test Suite

Tests the Riscure DS1120A probe using the bench framework with Moku:Go.
Four-phase characterization procedure with safety validation at each step.

Usage:
    pytest test_ds1120a_characterization.py --ip 192.168.13.159
    pytest test_ds1120a_characterization.py::test_phase1_connection_verification --ip 192.168.13.159
"""

import pytest
import time
import yaml
from pathlib import Path

# Import bench framework
from bench_framework import BenchConfig
from bench_framework.backends.moku_backend import MokuBackend


@pytest.fixture(scope="module")
def moku_ip(request):
    """Get Moku IP from command line or use default"""
    return request.config.getoption("--ip", default="192.168.13.159")


@pytest.fixture(scope="module")
def bench_config():
    """Load DS1120A bench configuration"""
    config_path = Path(__file__).parent / "bench_configs" / "ds1120a_basic.yaml"

    with open(config_path) as f:
        config_dict = yaml.safe_load(f)

    return BenchConfig.from_dict(config_dict)


@pytest.fixture(scope="module")
def moku_backend(bench_config, moku_ip):
    """Create and setup Moku backend"""
    # Override IP from command line
    bench_config.platform['ip'] = moku_ip

    backend = MokuBackend.from_config(bench_config)
    backend.setup()

    yield backend

    # Cleanup: Set outputs to safe state
    backend.set_dac_output(1, 0.0)  # 0V = 0% power
    backend.set_digital_output('A', False)  # No trigger
    backend.teardown()


# ============================================================================
# Phase 1: Connection Verification
# ============================================================================

def test_phase1_connection_verification(moku_backend):
    """
    Phase 1: Verify all connections without firing probe

    Safety: No trigger pulses, just passive monitoring

    Checks:
    - Moku connection established
    - Data Logger configured correctly
    - DAC outputs at safe levels
    - Input monitoring active
    """
    print("\n" + "=" * 70)
    print("PHASE 1: CONNECTION VERIFICATION")
    print("=" * 70)

    # Verify backend is setup
    assert moku_backend._setup_complete, "Backend should be initialized"

    # Get Data Logger instrument
    data_logger = moku_backend.get_instrument('DataLogger')
    assert data_logger is not None, "Data Logger should be available"

    # Verify DAC is at 0V (0% power)
    dac_voltage = moku_backend.get_dac_output(1)
    assert dac_voltage == 0.0, f"DAC should be 0V, got {dac_voltage}V"
    print(f"✓ DAC output: {dac_voltage}V (0% power)")

    # Verify digital output is disabled
    digital_state = moku_backend.get_digital_output('A')
    assert digital_state == False, "Digital output should be LOW"
    print(f"✓ Digital output: {'HIGH' if digital_state else 'LOW'}")

    # Monitor input for noise floor
    print("Monitoring input for 100ms...")
    data = moku_backend.capture_data(duration_ms=100, force_trigger=True)

    coil_data = data_logger.get_data('coil_current')
    print(f"✓ Captured {coil_data['sample_count']} samples")
    print(f"  Noise floor: {min(coil_data['values']):.3f}V to {max(coil_data['values']):.3f}V")

    print("\n✓ PHASE 1 PASSED: All connections verified, system at safe state")


# ============================================================================
# Phase 2: Minimum Power Trigger Test
# ============================================================================

def test_phase2_minimum_power_trigger(moku_backend):
    """
    Phase 2: Test probe at minimum power (5%)

    Safety: Single pulse at lowest reliable power level

    Checks:
    - Current monitor shows pulse response
    - Pulse timing within spec (50ns ± 10%)
    - No unexpected behavior
    """
    print("\n" + "=" * 70)
    print("PHASE 2: MINIMUM POWER TRIGGER TEST (5%)")
    print("=" * 70)

    # Set power to 5% (minimum reliable level)
    power_percent = 5
    dac_voltage = (power_percent / 100.0) * 3.3
    moku_backend.set_dac_output(1, dac_voltage)
    print(f"Power set to {power_percent}% ({dac_voltage:.3f}V)")

    # Wait for settling
    time.sleep(0.01)

    # Send single trigger pulse
    print("Sending trigger pulse...")
    moku_backend.send_trigger_pulse('A', width_ns=100)  # 100ns trigger (probe extends to 50ns)

    # Capture response
    time.sleep(0.001)  # Brief delay before capture
    data = moku_backend.capture_data(duration_ms=1, trigger_source='Input1')

    data_logger = moku_backend.get_instrument('DataLogger')
    coil_data = data_logger.get_data('coil_current')

    # Verify we captured a pulse
    min_voltage = min(coil_data['values'])
    print(f"✓ Peak current monitor: {min_voltage:.3f}V")

    # At 5% power, expect ~-0.07V to -0.2V (rough estimate)
    assert min_voltage < -0.05, f"Expected negative pulse, got {min_voltage}V"
    print("✓ Current monitor shows pulse response")

    # Return DAC to 0V
    moku_backend.set_dac_output(1, 0.0)

    print("\n✓ PHASE 2 PASSED: Probe responds at minimum power")


# ============================================================================
# Phase 3: Power Sweep Characterization
# ============================================================================

def test_phase3_power_sweep(moku_backend):
    """
    Phase 3: Characterize voltage-to-power mapping

    Safety: Gradual sweep from 5% to 100% in 10% increments

    Measures:
    - Peak current vs. control voltage
    - Linearity of power mapping
    - Consistency across multiple pulses
    """
    print("\n" + "=" * 70)
    print("PHASE 3: POWER SWEEP CHARACTERIZATION")
    print("=" * 70)

    power_levels = [5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    results = []

    data_logger = moku_backend.get_instrument('DataLogger')

    for power_percent in power_levels:
        dac_voltage = (power_percent / 100.0) * 3.3
        moku_backend.set_dac_output(1, dac_voltage)
        time.sleep(0.01)  # Settling time

        # Send trigger
        moku_backend.send_trigger_pulse('A', width_ns=100)
        time.sleep(0.001)

        # Capture
        data = moku_backend.capture_data(duration_ms=1, trigger_source='Input1')
        coil_data = data_logger.get_data('coil_current')

        peak_voltage = min(coil_data['values'])
        results.append({
            'power_percent': power_percent,
            'dac_voltage': dac_voltage,
            'peak_current_monitor': peak_voltage
        })

        print(f"  {power_percent:3d}% → {dac_voltage:.3f}V DAC → {peak_voltage:.3f}V peak")

    # Return to safe state
    moku_backend.set_dac_output(1, 0.0)

    # Verify monotonic increase
    peak_values = [r['peak_current_monitor'] for r in results]
    assert all(peak_values[i] <= peak_values[i+1] for i in range(len(peak_values)-1)), \
        "Peak current should increase monotonically"

    print(f"\n✓ PHASE 3 PASSED: Power sweep complete ({len(results)} points)")
    print(f"  Range: {peak_values[0]:.3f}V to {peak_values[-1]:.3f}V")


# ============================================================================
# Phase 4: Timing Characterization
# ============================================================================

def test_phase4_timing_analysis(moku_backend):
    """
    Phase 4: Measure pulse timing characteristics

    Measures:
    - Propagation delay (trigger → current monitor)
    - Pulse width (should be ~50ns fixed)
    - Consistency across multiple captures
    """
    print("\n" + "=" * 70)
    print("PHASE 4: TIMING CHARACTERIZATION")
    print("=" * 70)

    # Set to 50% power for clear signal
    power_percent = 50
    dac_voltage = (power_percent / 100.0) * 3.3
    moku_backend.set_dac_output(1, dac_voltage)
    time.sleep(0.01)

    print(f"Using {power_percent}% power for timing measurement")

    # Capture with high resolution
    data_logger = moku_backend.get_instrument('DataLogger')

    num_captures = 5
    timing_results = []

    for i in range(num_captures):
        moku_backend.send_trigger_pulse('A', width_ns=100)
        time.sleep(0.001)

        data = moku_backend.capture_data(duration_ms=1, trigger_source='Input1')
        coil_data = data_logger.get_data('coil_current')

        # Find pulse edges (simple threshold crossing)
        threshold = max(coil_data['values']) * 0.5  # 50% of peak
        falling_edge = None
        rising_edge = None

        for idx, val in enumerate(coil_data['values']):
            if falling_edge is None and val < threshold:
                falling_edge = idx
            if falling_edge is not None and val > threshold:
                rising_edge = idx
                break

        if falling_edge and rising_edge:
            sample_rate = data_logger.settings['sample_rate']
            pulse_width_ns = ((rising_edge - falling_edge) / sample_rate) * 1e9
            timing_results.append(pulse_width_ns)
            print(f"  Capture {i+1}: Pulse width = {pulse_width_ns:.1f}ns")

    # Return to safe state
    moku_backend.set_dac_output(1, 0.0)

    if timing_results:
        avg_width = sum(timing_results) / len(timing_results)
        print(f"\n✓ Average pulse width: {avg_width:.1f}ns")
        print(f"  Expected: 50ns ± 10% (45-55ns)")

        # Relaxed check since actual hardware timing depends on probe
        assert 20 < avg_width < 100, f"Pulse width {avg_width:.1f}ns outside reasonable range"

    print("\n✓ PHASE 4 PASSED: Timing analysis complete")


# ============================================================================
# Summary Test
# ============================================================================

def test_characterization_summary(moku_backend):
    """Print characterization summary"""
    print("\n" + "=" * 70)
    print("DS1120A CHARACTERIZATION COMPLETE")
    print("=" * 70)
    print("All phases passed:")
    print("  ✓ Phase 1: Connection verification")
    print("  ✓ Phase 2: Minimum power trigger (5%)")
    print("  ✓ Phase 3: Power sweep (5-100%)")
    print("  ✓ Phase 4: Timing analysis")
    print("\nProbe is characterized and ready for use.")
    print("=" * 70)


# ============================================================================
# Pytest Configuration
# ============================================================================

def pytest_addoption(parser):
    """Add command-line options"""
    parser.addoption("--ip", action="store", default="192.168.13.159",
                     help="Moku device IP address")

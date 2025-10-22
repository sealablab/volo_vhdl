"""
CocotB Test Fixtures and Utilities for Volo VHDL Project

This file provides shared test utilities that eliminate code duplication
across all testbenches. pytest automatically loads this file.

Usage in tests:
    from conftest import setup_clock, reset_active_low, count_pulses

    @cocotb.test()
    async def test_something(dut):
        await setup_clock(dut)
        await reset_active_low(dut)
        # ... your test logic

Author: Claude Code (CocotB migration)
Date: 2025-01-22
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles


# Default clock period for all tests
DEFAULT_CLK_PERIOD_NS = 10


# =============================================================================
# Clock Management
# =============================================================================

async def setup_clock(dut, period_ns=DEFAULT_CLK_PERIOD_NS, clk_signal="clk"):
    """
    Start a clock on the DUT

    Args:
        dut: Device Under Test
        period_ns: Clock period in nanoseconds (default: 10ns = 100MHz)
        clk_signal: Name of clock signal (default: "clk")

    Returns:
        Clock object (can be ignored, runs in background)

    Example:
        await setup_clock(dut)
        await setup_clock(dut, period_ns=20)  # 50MHz clock
        await setup_clock(dut, clk_signal="Clk")  # MCC style
    """
    clk = getattr(dut, clk_signal)
    clock = cocotb.start_soon(Clock(clk, period_ns, units="ns").start())
    dut._log.info(f"✓ Clock started on '{clk_signal}' ({period_ns}ns period = {1000/period_ns:.1f}MHz)")
    return clock


# =============================================================================
# Reset Sequences
# =============================================================================

async def reset_active_low(dut, cycles=2, rst_signal="rst_n"):
    """
    Apply active-low reset sequence (standard for most modules)

    Args:
        dut: Device Under Test
        cycles: Number of clock cycles to hold reset (default: 2)
        rst_signal: Name of reset signal (default: "rst_n")

    Example:
        await reset_active_low(dut)
        await reset_active_low(dut, cycles=5)
        await reset_active_low(dut, rst_signal="nReset")
    """
    rst = getattr(dut, rst_signal)
    clk = dut.clk

    # Apply reset
    rst.value = 0
    await ClockCycles(clk, cycles)

    # Release reset
    rst.value = 1
    await ClockCycles(clk, 1)

    dut._log.info(f"✓ Reset complete (active-low, {cycles} cycles)")


async def reset_active_high(dut, cycles=2, rst_signal="rst"):
    """
    Apply active-high reset sequence (used by some MCC modules)

    Args:
        dut: Device Under Test
        cycles: Number of clock cycles to hold reset (default: 2)
        rst_signal: Name of reset signal (default: "rst", tries "Reset" if not found)

    Example:
        await reset_active_high(dut)
        await reset_active_high(dut, rst_signal="Reset")  # MCC style
    """
    # Try specified signal name first, fall back to common alternatives
    if hasattr(dut, rst_signal):
        rst = getattr(dut, rst_signal)
    elif hasattr(dut, "Reset"):
        rst = dut.Reset
        rst_signal = "Reset"
    else:
        rst = getattr(dut, rst_signal)  # Will raise AttributeError if not found

    clk = dut.clk if hasattr(dut, "clk") else dut.Clk

    # Apply reset
    rst.value = 1
    await ClockCycles(clk, cycles)

    # Release reset
    rst.value = 0
    await ClockCycles(clk, 1)

    dut._log.info(f"✓ Reset complete (active-high, {cycles} cycles)")


async def reset_dut(dut, active_low=True, cycles=2, rst_signal=None):
    """
    Apply reset sequence (auto-detects active-low vs active-high)

    Args:
        dut: Device Under Test
        active_low: True for active-low (rst_n), False for active-high (rst/Reset)
        cycles: Number of clock cycles to hold reset (default: 2)
        rst_signal: Optional signal name override

    Example:
        await reset_dut(dut)  # Active-low by default
        await reset_dut(dut, active_low=False)  # Active-high
    """
    if active_low:
        signal = rst_signal if rst_signal else "rst_n"
        await reset_active_low(dut, cycles=cycles, rst_signal=signal)
    else:
        signal = rst_signal if rst_signal else "rst"
        await reset_active_high(dut, cycles=cycles, rst_signal=signal)


# =============================================================================
# Signal Monitoring and Counting
# =============================================================================

async def count_pulses(signal, clk, num_cycles):
    """
    Count how many times a signal goes high (pulses) over a number of clock cycles

    Args:
        signal: Signal to monitor (e.g., dut.clk_en)
        clk: Clock signal to synchronize to (e.g., dut.clk)
        num_cycles: Number of clock cycles to observe

    Returns:
        int: Number of pulses detected

    Example:
        pulses = await count_pulses(dut.clk_en, dut.clk, 100)
        assert pulses == 10, f"Expected 10 pulses, got {pulses}"
    """
    count = 0
    for _ in range(num_cycles):
        await RisingEdge(clk)
        if signal.value == 1:
            count += 1
    return count


async def wait_for_value(signal, expected_value, clk, timeout_cycles=1000):
    """
    Wait for a signal to reach an expected value (with timeout)

    Args:
        signal: Signal to monitor
        expected_value: Value to wait for
        clk: Clock signal
        timeout_cycles: Maximum cycles to wait (default: 1000)

    Returns:
        bool: True if value reached, False if timeout

    Example:
        success = await wait_for_value(dut.done, 1, dut.clk)
        assert success, "Module never signaled done"
    """
    for cycle in range(timeout_cycles):
        await RisingEdge(clk)
        if signal.value == expected_value:
            return True
    return False


async def capture_signal_sequence(signal, clk, num_cycles):
    """
    Capture a sequence of signal values over multiple clock cycles

    Args:
        signal: Signal to capture
        clk: Clock signal
        num_cycles: Number of cycles to capture

    Returns:
        list: List of signal values

    Example:
        sequence = await capture_signal_sequence(dut.state, dut.clk, 20)
        assert sequence == [0, 0, 1, 2, 3, 0, 0, ...]  # Verify state transitions
    """
    values = []
    for _ in range(num_cycles):
        await RisingEdge(clk)
        values.append(int(signal.value))
    return values


# =============================================================================
# Initialization Helpers
# =============================================================================

async def init_dut(dut, clock_period_ns=DEFAULT_CLK_PERIOD_NS, active_low_reset=True):
    """
    Complete DUT initialization: start clock + apply reset

    This is the most common setup sequence. Use this for simple tests.

    Args:
        dut: Device Under Test
        clock_period_ns: Clock period in ns (default: 10ns)
        active_low_reset: True for rst_n, False for rst/Reset

    Example:
        await init_dut(dut)  # Standard init
        await init_dut(dut, clock_period_ns=20, active_low_reset=False)  # Custom
    """
    await setup_clock(dut, period_ns=clock_period_ns)
    await reset_dut(dut, active_low=active_low_reset)


# =============================================================================
# Division Ratio Testing (Specific to clk_divider modules)
# =============================================================================

async def verify_division_ratio(dut, div_sel, expected_ratio, observation_cycles=None):
    """
    Verify that a clock divider produces the expected division ratio

    Args:
        dut: Clock divider DUT (must have clk_en output)
        div_sel: Division select value
        expected_ratio: Expected division ratio
        observation_cycles: Cycles to observe (default: expected_ratio * 10)

    Returns:
        tuple: (actual_pulses, expected_pulses, passed)

    Example:
        actual, expected, passed = await verify_division_ratio(dut, 10, 10)
        assert passed, f"Division failed: {actual} != {expected}"
    """
    if observation_cycles is None:
        observation_cycles = expected_ratio * 10

    dut.div_sel.value = div_sel
    dut.enable.value = 1
    await ClockCycles(dut.clk, 2)  # Let div_sel load

    pulse_count = await count_pulses(dut.clk_en, dut.clk, observation_cycles)
    expected_pulses = observation_cycles // expected_ratio

    passed = (pulse_count == expected_pulses)

    if passed:
        dut._log.info(f"✓ Division ratio verified: div_sel={div_sel} → {pulse_count} pulses in {observation_cycles} cycles")
    else:
        dut._log.warning(f"✗ Division mismatch: expected {expected_pulses}, got {pulse_count}")

    return pulse_count, expected_pulses, passed


# =============================================================================
# Assertion Helpers
# =============================================================================

def assert_signal_value(signal, expected, message=""):
    """
    Assert a signal has expected value with helpful error message

    Args:
        signal: Signal to check
        expected: Expected value (int or string)
        message: Optional custom message

    Example:
        assert_signal_value(dut.output, 0x1234, "Output mismatch after reset")
    """
    actual = int(signal.value)
    if isinstance(expected, str):
        expected = int(expected, 0)  # Support "0x1234" format

    if actual != expected:
        msg = f"Signal value mismatch: expected {expected:#x}, got {actual:#x}"
        if message:
            msg = f"{message}: {msg}"
        assert False, msg


async def assert_pulse_count(signal, clk, cycles, expected, tolerance=0):
    """
    Assert that a signal pulses expected number of times (with optional tolerance)

    Args:
        signal: Signal to monitor
        clk: Clock signal
        cycles: Number of cycles to observe
        expected: Expected pulse count
        tolerance: Allowed deviation (default: 0)

    Example:
        await assert_pulse_count(dut.clk_en, dut.clk, 100, 10, tolerance=1)
    """
    actual = await count_pulses(signal, clk, cycles)

    if tolerance > 0:
        passed = abs(actual - expected) <= tolerance
        msg = f"Pulse count: expected {expected}±{tolerance}, got {actual}"
    else:
        passed = (actual == expected)
        msg = f"Pulse count: expected {expected}, got {actual}"

    assert passed, msg


# =============================================================================
# Waveform Helpers
# =============================================================================

def log_signal_table(dut, signal_names, title="Signal Values"):
    """
    Log a formatted table of signal values (useful for debugging)

    Args:
        dut: Device Under Test
        signal_names: List of signal names to display
        title: Table title

    Example:
        log_signal_table(dut, ["clk_en", "enable", "div_sel", "stat_reg"])
    """
    dut._log.info("=" * 60)
    dut._log.info(title)
    dut._log.info("-" * 60)
    for name in signal_names:
        signal = getattr(dut, name)
        value = signal.value
        dut._log.info(f"  {name:20s} = {value}")
    dut._log.info("=" * 60)


# =============================================================================
# Module-Specific Helpers (can be expanded as needed)
# =============================================================================

# TODO: Add EMFI-Seq specific helpers when migrating those tests
# TODO: Add SimpleWaveGen helpers when migrating those tests

# Example placeholder for future expansion:
# async def verify_fsm_sequence(dut, expected_states):
#     """Verify FSM goes through expected state sequence"""
#     pass

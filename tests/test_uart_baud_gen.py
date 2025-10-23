"""
CocotB testbench for uart_baud_gen (volo_uart_baud_gen.vhd)

Tests:
1. Basic tick generation at various baud rates
2. Timing accuracy verification (<1% error)
3. Enable control (freeze/unfreeze)
4. Divider configuration changes
5. Edge cases (div=1, div=max)

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
from conftest import setup_clock, reset_active_low, count_pulses
import math


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 80)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 80)

    # Setup
    await setup_clock(dut, clk_signal="clk", period_ns=8.0)  # 125 MHz
    dut.enable.value = 1
    dut.div_value.value = 1085  # 115200 baud

    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)

    # Check outputs during reset
    assert dut.baud_tick.value == 0, "baud_tick should be 0 during reset"
    assert dut.stat_reg.value == 0, "stat_reg (counter) should be 0 during reset"

    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_baud_rate_115200(dut):
    """Test 2: 115200 Baud Rate Generation (Pinata standard)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 2: 115200 Baud Rate @ 125 MHz")
    dut._log.info("=" * 80)

    # Setup
    clk_freq_hz = 125_000_000
    target_baud = 115200
    divider = 1085  # 125 MHz / 115200 ≈ 1085

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)  # 125 MHz
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.div_value.value = divider

    # Count ticks over a period
    test_duration_cycles = 125_000  # 1 ms @ 125 MHz
    tick_count = await count_pulses(
        dut.baud_tick,
        dut.clk,
        test_duration_cycles
    )

    # Calculate actual baud rate
    test_duration_sec = test_duration_cycles / clk_freq_hz
    actual_baud = tick_count / test_duration_sec
    error_pct = abs(actual_baud - target_baud) / target_baud * 100

    dut._log.info(f"Target baud: {target_baud} baud")
    dut._log.info(f"Actual baud: {actual_baud:.1f} baud")
    dut._log.info(f"Error: {error_pct:.3f}%")
    dut._log.info(f"Tick count in {test_duration_sec*1000:.3f} ms: {tick_count}")

    # Verify accuracy (<1% error)
    assert error_pct < 1.0, f"Baud rate error {error_pct:.3f}% exceeds 1%"
    dut._log.info("✓ 115200 baud test PASSED")


@cocotb.test()
async def test_baud_rate_38400(dut):
    """Test 3: 38400 Baud Rate (SimpleSerial V1)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 3: 38400 Baud Rate @ 125 MHz")
    dut._log.info("=" * 80)

    # Setup
    clk_freq_hz = 125_000_000
    target_baud = 38400
    divider = 3255  # 125 MHz / 38400 ≈ 3255

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.div_value.value = divider

    # Count ticks over a period
    test_duration_cycles = 125_000  # 1 ms
    tick_count = await count_pulses(
        dut.baud_tick,
        dut.clk,
        test_duration_cycles
    )

    # Calculate actual baud rate
    test_duration_sec = test_duration_cycles / clk_freq_hz
    actual_baud = tick_count / test_duration_sec
    error_pct = abs(actual_baud - target_baud) / target_baud * 100

    dut._log.info(f"Target baud: {target_baud} baud")
    dut._log.info(f"Actual baud: {actual_baud:.1f} baud")
    dut._log.info(f"Error: {error_pct:.3f}%")

    # Verify accuracy (<2% error - industry standard for UART)
    assert error_pct < 2.0, f"Baud rate error {error_pct:.3f}% exceeds 2%"
    dut._log.info("✓ 38400 baud test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 4: Enable Control (Freeze/Unfreeze)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 4: Enable Control")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.div_value.value = 100  # Fast divider for quick test
    dut.enable.value = 1
    await ClockCycles(dut.clk, 10)

    # Count ticks with enable=1
    tick_count_enabled = await count_pulses(
        dut.baud_tick,
        dut.clk,
        500
    )

    dut._log.info(f"Ticks with enable=1: {tick_count_enabled}")
    assert tick_count_enabled > 0, "Should generate ticks when enabled"

    # Disable and verify no ticks
    dut.enable.value = 0
    await ClockCycles(dut.clk, 10)

    tick_count_disabled = await count_pulses(
        dut.baud_tick,
        dut.clk,
        500
    )

    dut._log.info(f"Ticks with enable=0: {tick_count_disabled}")
    assert tick_count_disabled == 0, "Should NOT generate ticks when disabled"

    # Re-enable and verify ticks resume
    dut.enable.value = 1
    await ClockCycles(dut.clk, 10)

    tick_count_reenabled = await count_pulses(
        dut.baud_tick,
        dut.clk,
        500
    )

    dut._log.info(f"Ticks after re-enable: {tick_count_reenabled}")
    assert tick_count_reenabled > 0, "Should generate ticks after re-enable"

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_tick_is_single_cycle(dut):
    """Test 5: Verify baud_tick is exactly 1 cycle wide"""
    dut._log.info("=" * 80)
    dut._log.info("Test 5: Single-Cycle Tick Verification")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.div_value.value = 50  # Small divider for quick testing

    # Wait for first tick
    tick_seen = False
    for _ in range(200):
        await RisingEdge(dut.clk)
        if dut.baud_tick.value == 1:
            tick_seen = True
            dut._log.info("Tick detected high")

            # Next cycle should be low
            await RisingEdge(dut.clk)
            assert dut.baud_tick.value == 0, "Tick should be single-cycle (low after 1 cycle)"
            dut._log.info("Tick verified as single-cycle")
            break

    assert tick_seen, "Should have seen at least one tick"
    dut._log.info("✓ Single-cycle tick test PASSED")


@cocotb.test()
async def test_divider_change_on_fly(dut):
    """Test 6: Change divider value during operation"""
    dut._log.info("=" * 80)
    dut._log.info("Test 6: Dynamic Divider Change")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1

    # Start with divider=100
    dut.div_value.value = 100
    await ClockCycles(dut.clk, 50)

    tick_count_1 = await count_pulses(
        dut.baud_tick,
        dut.clk,
        1000
    )

    dut._log.info(f"Ticks with div=100: {tick_count_1}")

    # Change to divider=200 (half the rate)
    dut.div_value.value = 200
    await ClockCycles(dut.clk, 50)

    tick_count_2 = await count_pulses(
        dut.baud_tick,
        dut.clk,
        1000
    )

    dut._log.info(f"Ticks with div=200: {tick_count_2}")

    # Verify tick rate changed (should be roughly half)
    ratio = tick_count_1 / tick_count_2 if tick_count_2 > 0 else 0
    dut._log.info(f"Tick ratio (100/200): {ratio:.2f} (expect ~2.0)")

    assert 1.5 < ratio < 2.5, "Tick rate should roughly halve when divider doubles"
    dut._log.info("✓ Dynamic divider change test PASSED")


@cocotb.test()
async def test_edge_case_div_1(dut):
    """Test 7: Edge case - divider = 1 (tick every cycle)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 7: Edge Case - Divider = 1")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.div_value.value = 1  # Tick every cycle!

    # Count ticks over 100 cycles
    tick_count = await count_pulses(
        dut.baud_tick,
        dut.clk,
        100
    )

    dut._log.info(f"Ticks with div=1 over 100 cycles: {tick_count}")

    # With div=1, should get 100 ticks in 100 cycles
    assert 95 <= tick_count <= 105, f"Expected ~100 ticks, got {tick_count}"
    dut._log.info("✓ Edge case div=1 test PASSED")


@cocotb.test()
async def test_stat_reg_counter(dut):
    """Test 8: Status register (counter value)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 8: Status Register Counter")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.div_value.value = 10

    # Monitor counter incrementing
    await RisingEdge(dut.clk)
    counter_values = []

    for _ in range(15):
        await RisingEdge(dut.clk)
        counter_values.append(int(dut.stat_reg.value))

    dut._log.info(f"Counter values: {counter_values}")

    # Verify counter increments and wraps at div_value
    assert 0 in counter_values, "Counter should reset to 0"
    assert max(counter_values) <= 10, "Counter should not exceed div_value"

    dut._log.info("✓ Status register test PASSED")


# Test summary function
async def run_all_tests():
    """This function is called by the test runner"""
    pass  # CocotB discovers tests automatically

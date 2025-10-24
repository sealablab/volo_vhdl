"""
CocotB tests for volo_voltage_threshold_trigger_core.vhd

Pattern: Digital comparator + edge detection
Expected: 95%+ test success

Moku voltage range: -5.0V to +5.0V (16-bit signed: -32768 to +32767)
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock

# Moku voltage constants (from Moku_Voltage_pkg.vhd)
MOKU_DIGITAL_3V3 = 21627   # 3.3V
MOKU_DIGITAL_3V = 19661    # 3.0V
MOKU_DIGITAL_2V5 = 16384   # 2.5V
MOKU_DIGITAL_1V = 6554     # 1.0V
MOKU_DIGITAL_ZERO = 0      # 0.0V

# Modes
MODE_RISING = 0
MODE_FALLING = 1


async def reset_dut(dut):
    """Reset the DUT"""
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 1)


def signed_to_int(value, width=16):
    """Convert unsigned value to signed integer"""
    if value >= (1 << (width - 1)):
        return value - (1 << width)
    return value


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset clears state"""
    dut._log.info("Test 1: Reset behavior")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.voltage_in.value = 0
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    assert int(dut.above_threshold.value) == 0, "above_threshold should be 0"
    assert int(dut.trigger_out.value) == 0, "trigger_out should be 0"
    assert int(dut.crossing_count.value) == 0, "crossing_count should be 0"

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_rising_edge_trigger(dut):
    """Test 2: Rising edge trigger (voltage crosses above threshold)"""
    dut._log.info("Test 2: Rising edge trigger")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Start below threshold
    dut.voltage_in.value = MOKU_DIGITAL_1V
    await RisingEdge(dut.clk)

    assert int(dut.above_threshold.value) == 0, "Should be below threshold"
    assert int(dut.trigger_out.value) == 0, "No trigger yet"

    # Cross above threshold
    dut.voltage_in.value = MOKU_DIGITAL_3V3
    await RisingEdge(dut.clk)

    # Trigger should pulse for 1 cycle
    await RisingEdge(dut.clk)
    assert int(dut.trigger_out.value) == 1, "Trigger should fire"
    assert int(dut.above_threshold.value) == 1, "Should be above threshold"

    await RisingEdge(dut.clk)
    assert int(dut.trigger_out.value) == 0, "Trigger should be 1 cycle only"

    dut._log.info("✓ Rising edge trigger test PASSED")


@cocotb.test()
async def test_falling_edge_trigger(dut):
    """Test 3: Falling edge trigger (voltage crosses below threshold)"""
    dut._log.info("Test 3: Falling edge trigger")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_FALLING

    await reset_dut(dut)

    # Start above threshold
    dut.voltage_in.value = MOKU_DIGITAL_3V3
    await ClockCycles(dut.clk, 3)

    assert int(dut.above_threshold.value) == 1, "Should be above threshold"

    # Cross below threshold
    dut.voltage_in.value = MOKU_DIGITAL_1V
    await RisingEdge(dut.clk)

    # Trigger should pulse
    await RisingEdge(dut.clk)
    assert int(dut.trigger_out.value) == 1, "Trigger should fire on falling edge"

    await RisingEdge(dut.clk)
    assert int(dut.trigger_out.value) == 0, "Trigger should be 1 cycle only"

    dut._log.info("✓ Falling edge trigger test PASSED")


@cocotb.test()
async def test_hysteresis(dut):
    """Test 4: Hysteresis prevents glitchy triggers"""
    dut._log.info("Test 4: Hysteresis")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Start below
    dut.voltage_in.value = MOKU_DIGITAL_1V
    await ClockCycles(dut.clk, 2)

    # Cross above high threshold
    dut.voltage_in.value = MOKU_DIGITAL_3V3
    await ClockCycles(dut.clk, 2)
    assert int(dut.above_threshold.value) == 1, "Should be above"

    # Drop to middle of hysteresis band (between high and low)
    # State should STAY high (hysteresis prevents flip-flop)
    dut.voltage_in.value = (MOKU_DIGITAL_3V + MOKU_DIGITAL_2V5) // 2
    await ClockCycles(dut.clk, 2)
    assert int(dut.above_threshold.value) == 1, "Should stay above (hysteresis)"

    # Only cross below LOW threshold to change state
    dut.voltage_in.value = MOKU_DIGITAL_1V
    await ClockCycles(dut.clk, 2)
    assert int(dut.above_threshold.value) == 0, "Now below"

    dut._log.info("✓ Hysteresis test PASSED")


@cocotb.test()
async def test_crossing_counter(dut):
    """Test 5: Crossing counter increments"""
    dut._log.info("Test 5: Crossing counter")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Cross threshold multiple times
    for i in range(5):
        # Low
        dut.voltage_in.value = MOKU_DIGITAL_1V
        await ClockCycles(dut.clk, 3)

        # High
        dut.voltage_in.value = MOKU_DIGITAL_3V3
        await ClockCycles(dut.clk, 3)

    # Should have 10 crossings (5 up, 5 down)
    count = int(dut.crossing_count.value)
    assert count == 10, f"Expected 10 crossings, got {count}"

    dut._log.info(f"  Counted {count} crossings ✓")
    dut._log.info("✓ Crossing counter test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 6: Enable control"""
    dut._log.info("Test 6: Enable control")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.voltage_in.value = MOKU_DIGITAL_1V
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Disable module
    dut.enable.value = 0
    dut.voltage_in.value = MOKU_DIGITAL_3V3
    await ClockCycles(dut.clk, 5)

    # Trigger should NOT fire when disabled
    assert int(dut.trigger_out.value) == 0, "Trigger should not fire when disabled"

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_zero_crossing(dut):
    """Test 7: Zero voltage crossing"""
    dut._log.info("Test 7: Zero crossing")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_1V   # Positive threshold
    dut.threshold_low.value = -MOKU_DIGITAL_1V   # Negative threshold
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Start negative
    dut.voltage_in.value = signed_to_int(-MOKU_DIGITAL_3V)
    await ClockCycles(dut.clk, 2)

    # Cross to positive
    dut.voltage_in.value = MOKU_DIGITAL_3V
    await ClockCycles(dut.clk, 3)

    assert int(dut.crossing_count.value) > 0, "Should count zero crossing"

    dut._log.info("✓ Zero crossing test PASSED")


@cocotb.test()
async def test_rapid_oscillation(dut):
    """Test 8: Rapid voltage oscillations (glitch detection)"""
    dut._log.info("Test 8: Rapid oscillation")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.enable.value = 1
    dut.threshold_high.value = MOKU_DIGITAL_3V
    dut.threshold_low.value = MOKU_DIGITAL_2V5
    dut.mode.value = MODE_RISING

    await reset_dut(dut)

    # Rapidly oscillate voltage
    for i in range(20):
        if i % 2 == 0:
            dut.voltage_in.value = MOKU_DIGITAL_1V
        else:
            dut.voltage_in.value = MOKU_DIGITAL_3V3
        await RisingEdge(dut.clk)

    # Crossing count should reflect rapid changes
    count = int(dut.crossing_count.value)
    dut._log.info(f"  Detected {count} crossings in oscillation")
    assert count > 10, f"Should detect multiple crossings, got {count}"

    dut._log.info("✓ Rapid oscillation test PASSED")

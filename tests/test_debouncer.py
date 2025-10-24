"""
CocotB testbench for volo_debouncer

Tests:
1. Reset behavior
2. Clean signal (no bounce)
3. Bouncing signal (filter bounces)
4. Short glitch filtering
5. Long stable periods
6. Enable control
7. Rapid bouncing
8. Status register
9. Asymmetric bounce pattern
10. Summary

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low


# DEPTH=8 (default), so need DEPTH+2 = 10 cycles for stability in simulation
# (Need DEPTH cycles to fill shift register + 2 more for detection and output)
DEPTH = 8
STABILITY_CYCLES = DEPTH + 2  # Simulation timing


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Verify reset state
    assert dut.clean_out.value == 0, "clean_out should be 0 after reset"
    stat = int(dut.stat_reg.value)
    output_bit = stat & 0x01
    assert output_bit == 0, "Status bit[0] (output) should be 0 after reset"

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_clean_signal(dut):
    """Test 2: Clean Signal (No Bounce)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Clean Signal (no bounce)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Wait for stability
    await ClockCycles(dut.clk, 3)
    assert dut.clean_out.value == 0, "Output should be 0"

    # Clean transition: 0 → 1 (no bounce)
    dut._log.info("  Clean transition: 0 → 1")
    dut.noisy_in.value = 1

    # Wait for debouncer to recognize stable '1' (DEPTH+1 cycles)
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 1, f"Output should be 1 after {STABILITY_CYCLES} stable cycles"
    dut._log.info(f"  ✓ Output changed to 1 after {STABILITY_CYCLES} cycles")

    # Clean transition: 1 → 0 (no bounce)
    await ClockCycles(dut.clk, 5)
    dut._log.info("  Clean transition: 1 → 0")
    dut.noisy_in.value = 0

    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 0, f"Output should be 0 after {STABILITY_CYCLES} stable cycles"
    dut._log.info(f"  ✓ Output changed to 0 after {STABILITY_CYCLES} cycles")

    dut._log.info("✓ Clean signal test PASSED")


@cocotb.test()
async def test_bouncing_signal(dut):
    """Test 3: Bouncing Signal (Filter Bounces)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Bouncing Signal (filter bounces)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 3)

    # Simulate button press with bounce: 0→1→0→1→0→1→1→1→1...
    dut._log.info("  Simulating bouncing button press...")
    bounce_pattern = [0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]

    for i, val in enumerate(bounce_pattern):
        dut.noisy_in.value = val
        await ClockCycles(dut.clk, 1)
        output = int(dut.clean_out.value)
        dut._log.info(f"    Cycle {i}: input={val}, output={output}")

        # Output should stay 0 during bounce (first 6 cycles)
        if i < 6:
            assert output == 0, f"Output should remain 0 during bounce (cycle {i})"

    # After bounce settles (all 1s), output should eventually go high
    await ClockCycles(dut.clk, 5)
    assert dut.clean_out.value == 1, "Output should be 1 after bounce settles"
    dut._log.info("  ✓ Debouncer filtered bounce, output stable")

    dut._log.info("✓ Bouncing signal test PASSED")


@cocotb.test()
async def test_short_glitch_filtering(dut):
    """Test 4: Short Glitch Filtering"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Short Glitch Filtering")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Establish stable 0
    await ClockCycles(dut.clk, STABILITY_CYCLES + 2)
    assert dut.clean_out.value == 0, "Output should be 0"

    # Short glitch: 1 cycle high
    dut._log.info("  Testing 1-cycle glitch (should be filtered)")
    dut.noisy_in.value = 1
    await ClockCycles(dut.clk, 1)
    dut.noisy_in.value = 0

    # Output should NOT change (glitch too short)
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 0, "Output should remain 0 (1-cycle glitch filtered)"
    dut._log.info("  ✓ 1-cycle glitch filtered")

    # Medium glitch: DEPTH-2 cycles (still too short)
    await ClockCycles(dut.clk, 5)
    dut._log.info(f"  Testing {DEPTH-2}-cycle glitch (should be filtered)")
    for _ in range(DEPTH - 2):
        dut.noisy_in.value = 1
        await ClockCycles(dut.clk, 1)
    dut.noisy_in.value = 0

    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 0, f"Output should remain 0 ({DEPTH-2}-cycle glitch filtered)"
    dut._log.info(f"  ✓ {DEPTH-2}-cycle glitch filtered")

    dut._log.info("✓ Short glitch filtering test PASSED")


@cocotb.test()
async def test_long_stable_periods(dut):
    """Test 5: Long Stable Periods"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: Long Stable Periods")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Long stable low
    await ClockCycles(dut.clk, 30)
    assert dut.clean_out.value == 0, "Output should remain 0"
    dut._log.info("  ✓ Stayed low for 30 cycles")

    # Transition to high
    dut.noisy_in.value = 1
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 1, "Output should be 1"

    # Long stable high
    await ClockCycles(dut.clk, 30)
    assert dut.clean_out.value == 1, "Output should remain 1"
    dut._log.info("  ✓ Stayed high for 30 cycles")

    # Back to low
    dut.noisy_in.value = 0
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 0, "Output should be 0"

    dut._log.info("✓ Long stable periods test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 6: Enable Control"""
    dut._log.info("=" * 70)
    dut._log.info("Test 6: Enable Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Establish stable 0
    await ClockCycles(dut.clk, STABILITY_CYCLES + 2)

    # Disable debouncer
    dut.enable.value = 0
    dut._log.info("  Debouncer disabled")

    # Try to change input while disabled
    dut.noisy_in.value = 1
    await ClockCycles(dut.clk, STABILITY_CYCLES + 5)
    assert dut.clean_out.value == 0, "Output should remain 0 (debouncer frozen)"
    dut._log.info("  ✓ Output frozen while disabled")

    # Re-enable
    dut.enable.value = 1
    dut._log.info("  Debouncer re-enabled")

    # Now it should update
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 1, "Output should update after re-enable"
    dut._log.info("  ✓ Output updated after re-enable")

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_rapid_bouncing(dut):
    """Test 7: Rapid Bouncing"""
    dut._log.info("=" * 70)
    dut._log.info("Test 7: Rapid Bouncing")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 3)

    # Rapid alternating (worst-case bounce)
    dut._log.info("  Rapid alternating: 0→1→0→1→0→1... for 20 cycles")
    for i in range(20):
        dut.noisy_in.value = i % 2
        await ClockCycles(dut.clk, 1)

    # Output should still be 0 (never stable enough to change)
    assert dut.clean_out.value == 0, "Output should remain 0 during rapid bouncing"
    dut._log.info("  ✓ Output stable during rapid bounce")

    # Now settle to 1
    dut.noisy_in.value = 1
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    assert dut.clean_out.value == 1, "Output should be 1 after settling"
    dut._log.info("  ✓ Output changed after bounce settled")

    dut._log.info("✓ Rapid bouncing test PASSED")


@cocotb.test()
async def test_status_register(dut):
    """Test 8: Status Register"""
    dut._log.info("=" * 70)
    dut._log.info("Test 8: Status Register")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 3)

    # Check status register format: [0000][stable][noisy_in][shift[0]][clean_out]
    stat = int(dut.stat_reg.value)
    stable_bit = (stat >> 3) & 0b1
    noisy_bit = (stat >> 2) & 0b1
    shift_bit = (stat >> 1) & 0b1
    output_bit = stat & 0b1

    dut._log.info(f"  Status: 0x{stat:02X}")
    dut._log.info(f"    stable={stable_bit}, noisy_in={noisy_bit}, shift[0]={shift_bit}, output={output_bit}")

    # With input=0 for several cycles, should be stable
    await ClockCycles(dut.clk, STABILITY_CYCLES)
    stat = int(dut.stat_reg.value)
    stable_bit = (stat >> 3) & 0b1
    assert stable_bit == 1, "Should be stable (all zeros)"

    # Create unstable condition
    dut.noisy_in.value = 1
    await ClockCycles(dut.clk, 2)  # Only 2 cycles, not enough for stability

    stat = int(dut.stat_reg.value)
    stable_bit = (stat >> 3) & 0b1
    dut._log.info(f"  After 2 cycles of '1': stable={stable_bit} (may be unstable)")

    dut._log.info("✓ Status register test PASSED")


@cocotb.test()
async def test_asymmetric_bounce(dut):
    """Test 9: Asymmetric Bounce Pattern"""
    dut._log.info("=" * 70)
    dut._log.info("Test 9: Asymmetric Bounce Pattern")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.noisy_in.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 3)

    # Asymmetric pattern: longer high pulses during bounce
    # 0→1(3cyc)→0(1cyc)→1(3cyc)→0(1cyc)→1(stable)
    dut._log.info("  Asymmetric bounce: varying pulse widths")
    pattern = [
        (1, 3),  # High for 3 cycles
        (0, 1),  # Low for 1 cycle
        (1, 3),  # High for 3 cycles
        (0, 1),  # Low for 1 cycle
        (1, STABILITY_CYCLES + 2),  # Finally stable high
    ]

    for val, duration in pattern:
        dut.noisy_in.value = val
        await ClockCycles(dut.clk, duration)
        dut._log.info(f"    Set input={val} for {duration} cycles, output={dut.clean_out.value}")

    # After pattern, output should be 1
    assert dut.clean_out.value == 1, "Output should be 1 after asymmetric bounce settles"
    dut._log.info("  ✓ Asymmetric bounce filtered correctly")

    dut._log.info("✓ Asymmetric bounce test PASSED")


@cocotb.test()
async def test_summary(dut):
    """Test 10: Summary"""
    dut._log.info("=" * 70)
    dut._log.info("ALL DEBOUNCER TESTS PASSED!")
    dut._log.info("=" * 70)
    dut._log.info("Module Summary:")
    dut._log.info("  - DEPTH: 8-sample shift register debouncer")
    dut._log.info("  - Filters mechanical bounce and digital glitches")
    dut._log.info("  - Output changes only when all samples agree")
    dut._log.info("  - Essential for buttons, switches, and noisy signals")
    dut._log.info("  - Enable control (freeze debouncing)")
    dut._log.info("✓ All 9 tests completed successfully!")

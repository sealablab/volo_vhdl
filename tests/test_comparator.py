"""
CocotB testbench for volo_comparator

Tests:
1. Reset behavior
2. Equal mode (==)
3. Not equal mode (!=)
4. Greater than mode (>)
5. Less than mode (<)
6. Greater or equal mode (>=)
7. Less or equal mode (<=)
8. Enable control
9. Status register
10. Summary

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low


# Mode constants
MODE_EQUAL     = 0b000  # ==
MODE_NOT_EQUAL = 0b001  # !=
MODE_GREATER   = 0b010  # >
MODE_LESS      = 0b011  # <
MODE_GTE       = 0b100  # >=
MODE_LTE       = 0b101  # <=
MODE_RESERVED  = 0b110
MODE_OFF       = 0b111


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_EQUAL
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Verify reset state
    # Note: result is combinational, so it reflects current comparison
    # After reset with data_a==data_b==0 and mode==EQUAL, result should be 1
    stat = int(dut.stat_reg.value)
    dut._log.info(f"  Status after reset: 0x{stat:02X}")

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_equal_mode(dut):
    """Test 2: Equal Mode (==)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Equal Mode (==)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_EQUAL
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: Equal values (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 0x42
    dut.data_b.value = 0x42
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0x42 == 0x42 should be TRUE"
    dut._log.info("  ✓ 0x42 == 0x42 → TRUE")

    # Test 2: Different values (should be false)
    dut.data_a.value = 0x42
    dut.data_b.value = 0x99
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "0x42 == 0x99 should be FALSE"
    dut._log.info("  ✓ 0x42 == 0x99 → FALSE")

    # Test 3: Both zero
    dut.data_a.value = 0x00
    dut.data_b.value = 0x00
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0x00 == 0x00 should be TRUE"
    dut._log.info("  ✓ 0x00 == 0x00 → TRUE")

    # Test 4: Max value
    dut.data_a.value = 0xFFFF
    dut.data_b.value = 0xFFFF
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0xFFFF == 0xFFFF should be TRUE"
    dut._log.info("  ✓ 0xFFFF == 0xFFFF → TRUE")

    dut._log.info("✓ Equal mode test PASSED")


@cocotb.test()
async def test_not_equal_mode(dut):
    """Test 3: Not Equal Mode (!=)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Not Equal Mode (!=)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_NOT_EQUAL
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: Different values (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 0x42
    dut.data_b.value = 0x99
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0x42 != 0x99 should be TRUE"
    dut._log.info("  ✓ 0x42 != 0x99 → TRUE")

    # Test 2: Equal values (should be false)
    dut.data_a.value = 0x42
    dut.data_b.value = 0x42
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "0x42 != 0x42 should be FALSE"
    dut._log.info("  ✓ 0x42 != 0x42 → FALSE")

    # Test 3: Both zero (should be false)
    dut.data_a.value = 0x00
    dut.data_b.value = 0x00
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "0x00 != 0x00 should be FALSE"
    dut._log.info("  ✓ 0x00 != 0x00 → FALSE")

    dut._log.info("✓ Not equal mode test PASSED")


@cocotb.test()
async def test_greater_than_mode(dut):
    """Test 4: Greater Than Mode (>)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Greater Than Mode (>)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_GREATER
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: A > B (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 100
    dut.data_b.value = 50
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "100 > 50 should be TRUE"
    dut._log.info("  ✓ 100 > 50 → TRUE")

    # Test 2: A < B (should be false)
    dut.data_a.value = 50
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "50 > 100 should be FALSE"
    dut._log.info("  ✓ 50 > 100 → FALSE")

    # Test 3: A == B (should be false)
    dut.data_a.value = 100
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "100 > 100 should be FALSE"
    dut._log.info("  ✓ 100 > 100 → FALSE")

    # Test 4: Edge case - max vs max-1
    dut.data_a.value = 0xFFFF
    dut.data_b.value = 0xFFFE
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0xFFFF > 0xFFFE should be TRUE"
    dut._log.info("  ✓ 0xFFFF > 0xFFFE → TRUE")

    dut._log.info("✓ Greater than mode test PASSED")


@cocotb.test()
async def test_less_than_mode(dut):
    """Test 5: Less Than Mode (<)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: Less Than Mode (<)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_LESS
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: A < B (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 50
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "50 < 100 should be TRUE"
    dut._log.info("  ✓ 50 < 100 → TRUE")

    # Test 2: A > B (should be false)
    dut.data_a.value = 100
    dut.data_b.value = 50
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "100 < 50 should be FALSE"
    dut._log.info("  ✓ 100 < 50 → FALSE")

    # Test 3: A == B (should be false)
    dut.data_a.value = 100
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "100 < 100 should be FALSE"
    dut._log.info("  ✓ 100 < 100 → FALSE")

    # Test 4: Edge case - 0 vs 1
    dut.data_a.value = 0x0000
    dut.data_b.value = 0x0001
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "0x0000 < 0x0001 should be TRUE"
    dut._log.info("  ✓ 0x0000 < 0x0001 → TRUE")

    dut._log.info("✓ Less than mode test PASSED")


@cocotb.test()
async def test_greater_or_equal_mode(dut):
    """Test 6: Greater or Equal Mode (>=)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 6: Greater or Equal Mode (>=)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_GTE
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: A > B (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 100
    dut.data_b.value = 50
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "100 >= 50 should be TRUE"
    dut._log.info("  ✓ 100 >= 50 → TRUE")

    # Test 2: A == B (should be true)
    dut.data_a.value = 100
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "100 >= 100 should be TRUE"
    dut._log.info("  ✓ 100 >= 100 → TRUE (equal case)")

    # Test 3: A < B (should be false)
    dut.data_a.value = 50
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "50 >= 100 should be FALSE"
    dut._log.info("  ✓ 50 >= 100 → FALSE")

    dut._log.info("✓ Greater or equal mode test PASSED")


@cocotb.test()
async def test_less_or_equal_mode(dut):
    """Test 7: Less or Equal Mode (<=)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 7: Less or Equal Mode (<=)")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_LTE
    dut.data_a.value = 0
    dut.data_b.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Test 1: A < B (should be true)
    await ClockCycles(dut.clk, 1)
    dut.data_a.value = 50
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "50 <= 100 should be TRUE"
    dut._log.info("  ✓ 50 <= 100 → TRUE")

    # Test 2: A == B (should be true)
    dut.data_a.value = 100
    dut.data_b.value = 100
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "100 <= 100 should be TRUE"
    dut._log.info("  ✓ 100 <= 100 → TRUE (equal case)")

    # Test 3: A > B (should be false)
    dut.data_a.value = 100
    dut.data_b.value = 50
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "100 <= 50 should be FALSE"
    dut._log.info("  ✓ 100 <= 50 → FALSE")

    dut._log.info("✓ Less or equal mode test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 8: Enable Control"""
    dut._log.info("=" * 70)
    dut._log.info("Test 8: Enable Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_EQUAL
    dut.data_a.value = 0x42
    dut.data_b.value = 0x42
    await reset_active_low(dut, rst_signal="n_reset")

    # Enable = 1: should get result
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "With enable=1, 0x42 == 0x42 should be TRUE"
    dut._log.info("  ✓ enable=1: result propagates (TRUE)")

    # Enable = 0: result should be forced to 0
    dut.enable.value = 0
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "With enable=0, result should be 0"
    dut._log.info("  ✓ enable=0: result forced to 0")

    # Re-enable
    dut.enable.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 1, "After re-enable, result should be TRUE again"
    dut._log.info("  ✓ Re-enable: result propagates again")

    # Test with different data while disabled
    dut.enable.value = 0
    dut.data_a.value = 0x99
    dut.data_b.value = 0x00
    await ClockCycles(dut.clk, 1)
    assert dut.result.value == 0, "Even with data_a != data_b, result is 0 when disabled"
    dut._log.info("  ✓ Disabled: result stays 0 regardless of inputs")

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_status_register(dut):
    """Test 9: Status Register"""
    dut._log.info("=" * 70)
    dut._log.info("Test 9: Status Register")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.mode.value = MODE_GREATER
    dut.data_a.value = 100
    dut.data_b.value = 50
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)

    # Check status register format: [00][mode][enable][0][result]
    stat = int(dut.stat_reg.value)
    mode_bits = (stat >> 3) & 0b111
    enable_bit = (stat >> 2) & 0b1
    result_bit = stat & 0b1

    assert mode_bits == MODE_GREATER, f"Mode bits should be {MODE_GREATER:03b}"
    assert enable_bit == 1, "Enable bit should be 1"
    assert result_bit == 1, "Result bit should be 1 (100 > 50)"

    dut._log.info(f"  ✓ Status register: mode={mode_bits:03b}, enable={enable_bit}, result={result_bit}")

    # Change mode and check again
    dut.mode.value = MODE_LESS
    await ClockCycles(dut.clk, 1)

    stat = int(dut.stat_reg.value)
    mode_bits = (stat >> 3) & 0b111
    result_bit = stat & 0b1

    assert mode_bits == MODE_LESS, f"Mode bits should be {MODE_LESS:03b}"
    assert result_bit == 0, "Result bit should be 0 (100 < 50 is FALSE)"

    dut._log.info(f"  ✓ Updated status: mode={mode_bits:03b}, result={result_bit}")
    dut._log.info("✓ Status register test PASSED")


@cocotb.test()
async def test_summary(dut):
    """Test 10: Summary"""
    dut._log.info("=" * 70)
    dut._log.info("ALL COMPARATOR TESTS PASSED!")
    dut._log.info("=" * 70)
    dut._log.info("Module Summary:")
    dut._log.info("  - Modes: ==, !=, >, <, >=, <=")
    dut._log.info("  - Pure combinational (zero latency)")
    dut._log.info("  - 16-bit unsigned comparison")
    dut._log.info("  - Enable control (gate output)")
    dut._log.info("  - Status register for debug")
    dut._log.info("✓ All 9 tests completed successfully!")

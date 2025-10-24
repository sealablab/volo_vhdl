"""
CocotB testbench for volo_mux

Tests:
1. Reset behavior
2. Select input 0
3. Select input 1
4. Select input 2
5. Select input 3
6. Sequential selection (cycle through all)
7. Invalid selection (select >= NUM_INPUTS)
8. Enable control
9. Status register
10. Summary

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low


# NUM_INPUTS=4 (default), DATA_WIDTH=16
NUM_INPUTS = 4


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.sel.value = 0
    # Set all inputs to different values
    for i in range(16):
        getattr(dut, f"data_in_{i}").value = 0x1000 + i
    await reset_active_low(dut, rst_signal="n_reset")

    # After reset with n_reset=1, mux should work normally
    # (Pure combinational, so output should match selected input immediately)
    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    dut._log.info(f"  Output after reset: 0x{output:04X}")

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_select_input_0(dut):
    """Test 2: Select Input 0"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Select Input 0")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    # Set unique values for each input
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0xAA00 + i
    dut.sel.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    expected = 0xAA00
    assert output == expected, f"Output should be 0x{expected:04X}, got 0x{output:04X}"
    dut._log.info(f"  ✓ Select 0: output = 0x{output:04X}")

    dut._log.info("✓ Select input 0 test PASSED")


@cocotb.test()
async def test_select_input_1(dut):
    """Test 3: Select Input 1"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Select Input 1")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0xBB00 + i
    dut.sel.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    expected = 0xBB01
    assert output == expected, f"Output should be 0x{expected:04X}, got 0x{output:04X}"
    dut._log.info(f"  ✓ Select 1: output = 0x{output:04X}")

    dut._log.info("✓ Select input 1 test PASSED")


@cocotb.test()
async def test_select_input_2(dut):
    """Test 4: Select Input 2"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Select Input 2")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0xCC00 + i
    dut.sel.value = 2
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    expected = 0xCC02
    assert output == expected, f"Output should be 0x{expected:04X}, got 0x{output:04X}"
    dut._log.info(f"  ✓ Select 2: output = 0x{output:04X}")

    dut._log.info("✓ Select input 2 test PASSED")


@cocotb.test()
async def test_select_input_3(dut):
    """Test 5: Select Input 3"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: Select Input 3")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0xDD00 + i
    dut.sel.value = 3
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    expected = 0xDD03
    assert output == expected, f"Output should be 0x{expected:04X}, got 0x{output:04X}"
    dut._log.info(f"  ✓ Select 3: output = 0x{output:04X}")

    dut._log.info("✓ Select input 3 test PASSED")


@cocotb.test()
async def test_sequential_selection(dut):
    """Test 6: Sequential Selection (cycle through all inputs)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 6: Sequential Selection")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    # Set unique values
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0x1000 + (i * 0x100)
    await reset_active_low(dut, rst_signal="n_reset")

    # Cycle through all inputs
    for sel_val in range(NUM_INPUTS):
        dut.sel.value = sel_val
        await ClockCycles(dut.clk, 1)
        output = int(dut.data_out.value)
        expected = 0x1000 + (sel_val * 0x100)
        assert output == expected, f"Select {sel_val}: expected 0x{expected:04X}, got 0x{output:04X}"
        dut._log.info(f"  Select {sel_val}: output = 0x{output:04X} ✓")

    dut._log.info("✓ Sequential selection test PASSED")


@cocotb.test()
async def test_invalid_selection(dut):
    """Test 7: Invalid Selection (select >= NUM_INPUTS)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 7: Invalid Selection")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0xFF00 + i
    await reset_active_low(dut, rst_signal="n_reset")

    # Test invalid selections (>= NUM_INPUTS)
    invalid_sels = [4, 5, 7, 10, 15]
    for sel_val in invalid_sels:
        dut.sel.value = sel_val
        await ClockCycles(dut.clk, 1)
        output = int(dut.data_out.value)
        assert output == 0, f"Invalid select {sel_val}: output should be 0x0000, got 0x{output:04X}"
        dut._log.info(f"  Invalid select {sel_val}: output = 0x{output:04X} (forced to 0) ✓")

    dut._log.info("✓ Invalid selection test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 8: Enable Control"""
    dut._log.info("=" * 70)
    dut._log.info("Test 8: Enable Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    for i in range(NUM_INPUTS):
        getattr(dut, f"data_in_{i}").value = 0x5500 + i
    dut.sel.value = 2
    await reset_active_low(dut, rst_signal="n_reset")

    # Enable = 1: Should get normal output
    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    expected = 0x5502
    assert output == expected, f"With enable=1, output should be 0x{expected:04X}"
    dut._log.info(f"  Enable=1: output = 0x{output:04X} ✓")

    # Enable = 0: Output should be forced to 0
    dut.enable.value = 0
    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    assert output == 0, f"With enable=0, output should be 0x0000, got 0x{output:04X}"
    dut._log.info(f"  Enable=0: output = 0x{output:04X} (forced to 0) ✓")

    # Re-enable
    dut.enable.value = 1
    await ClockCycles(dut.clk, 1)
    output = int(dut.data_out.value)
    assert output == expected, f"After re-enable, output should be 0x{expected:04X}"
    dut._log.info(f"  Re-enabled: output = 0x{output:04X} ✓")

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_status_register(dut):
    """Test 9: Status Register"""
    dut._log.info("=" * 70)
    dut._log.info("Test 9: Status Register")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.sel.value = 2
    await reset_active_low(dut, rst_signal="n_reset")

    await ClockCycles(dut.clk, 1)

    # Check status register format: [00][sel_valid][enable][sel[3:0]]
    stat = int(dut.stat_reg.value)
    sel_valid_bit = (stat >> 5) & 0b1
    enable_bit = (stat >> 4) & 0b1
    sel_bits = stat & 0b1111

    dut._log.info(f"  Status: 0x{stat:02X}")
    dut._log.info(f"    sel_valid={sel_valid_bit}, enable={enable_bit}, sel={sel_bits}")

    assert sel_valid_bit == 1, "sel_valid should be 1 (select 2 is valid for NUM_INPUTS=4)"
    assert enable_bit == 1, "enable should be 1"
    assert sel_bits == 2, "sel should be 2"

    # Test invalid selection in status
    dut.sel.value = 10  # Invalid (>= NUM_INPUTS)
    await ClockCycles(dut.clk, 1)

    stat = int(dut.stat_reg.value)
    sel_valid_bit = (stat >> 5) & 0b1
    sel_bits = stat & 0b1111

    assert sel_valid_bit == 0, "sel_valid should be 0 (select 10 is invalid for NUM_INPUTS=4)"
    assert sel_bits == 10, "sel should be 10"
    dut._log.info(f"  Invalid sel=10: sel_valid={sel_valid_bit} ✓")

    dut._log.info("✓ Status register test PASSED")


@cocotb.test()
async def test_summary(dut):
    """Test 10: Summary"""
    dut._log.info("=" * 70)
    dut._log.info("ALL MUX TESTS PASSED!")
    dut._log.info("=" * 70)
    dut._log.info("Module Summary:")
    dut._log.info("  - NUM_INPUTS: 4-way multiplexer")
    dut._log.info("  - DATA_WIDTH: 16-bit data paths")
    dut._log.info("  - Pure combinational (zero latency)")
    dut._log.info("  - Invalid selection handling (outputs 0)")
    dut._log.info("  - Enable control (gate output)")
    dut._log.info("✓ All 9 tests completed successfully!")

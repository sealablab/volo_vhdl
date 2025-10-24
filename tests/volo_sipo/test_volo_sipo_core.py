"""
CocotB tests for volo_sipo_core.vhd (SIMPLIFIED VERSION)

Pattern: Shift Register (Tier 2)
Behavior: ALWAYS SHIFT LEFT (serial_in → LSB, MSB falls off)
Expected: 95-100% test success

No endianness modes - just shift left!
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock


async def reset_dut(dut):
    """Reset the DUT"""
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 1)


async def shift_in_bits(dut, bits):
    """
    Shift in a list of bits (LSB to MSB order)

    Example: shift_in_bits(dut, [1, 0, 1, 0, 0, 0, 1, 1])
    Shifts in: bit0=1, bit1=0, bit2=1... bit7=1
    Result: 0b11000101 (reading left-to-right: MSB...LSB)
    """
    for bit in bits:
        dut.serial_in.value = bit
        dut.shift_enable.value = 1
        await RisingEdge(dut.clk)

    dut.shift_enable.value = 0
    # Wait one more cycle for last bit to propagate
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset clears shift register"""
    dut._log.info("Test 1: Reset behavior")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    assert int(dut.parallel_out.value) == 0, "Parallel output should be 0 after reset"
    assert int(dut.bit_count.value) == 0, "Bit count should be 0 after reset"
    assert int(dut.done.value) == 0, "Done flag should be 0 after reset"

    dut._log.info("✓ Reset behavior test PASSED")


@cocotb.test()
async def test_shift_single_byte_pattern1(dut):
    """Test 2: Shift in 0xA5 = 0b10100101"""
    dut._log.info("Test 2: Shift in 0xA5 (0b10100101)")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in 0xA5 = 0b10100101
    # Bit order: [bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7]
    #          = [1, 0, 1, 0, 0, 1, 0, 1]
    # After shifting left 8 times: 0b10100101
    bits = [1, 0, 1, 0, 0, 1, 0, 1]
    await shift_in_bits(dut, bits)

    result = int(dut.parallel_out.value)
    expected = 0xA5

    assert result == expected, f"Expected 0x{expected:02x}, got 0x{result:02x}"
    assert int(dut.bit_count.value) == 8, "Bit count should be 8"
    assert int(dut.done.value) == 1, "Done flag should be set"

    dut._log.info(f"  Shifted 0b10100101, got 0x{result:02x} ✓")
    dut._log.info("✓ Pattern 0xA5 test PASSED")


@cocotb.test()
async def test_shift_single_byte_pattern2(dut):
    """Test 3: Shift in 0x5A = 0b01011010"""
    dut._log.info("Test 3: Shift in 0x5A (0b01011010)")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in 0x5A = 0b01011010
    # Bits: [0, 1, 0, 1, 1, 0, 1, 0]
    bits = [0, 1, 0, 1, 1, 0, 1, 0]
    await shift_in_bits(dut, bits)

    result = int(dut.parallel_out.value)
    expected = 0x5A

    assert result == expected, f"Expected 0x{expected:02x}, got 0x{result:02x}"
    dut._log.info(f"  Shifted 0b01011010, got 0x{result:02x} ✓")
    dut._log.info("✓ Pattern 0x5A test PASSED")


@cocotb.test()
async def test_clear_function(dut):
    """Test 4: Clear function"""
    dut._log.info("Test 4: Clear function")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in all ones
    await shift_in_bits(dut, [1, 1, 1, 1, 1, 1, 1, 1])

    assert int(dut.parallel_out.value) == 0xFF, "Should have 0xFF before clear"

    # Clear
    dut.clear.value = 1
    await RisingEdge(dut.clk)
    dut.clear.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.parallel_out.value) == 0, "Should be cleared"
    assert int(dut.bit_count.value) == 0, "Bit count should be 0"
    assert int(dut.done.value) == 0, "Done should be 0"

    dut._log.info("✓ Clear function test PASSED")


@cocotb.test()
async def test_bit_counter(dut):
    """Test 5: Bit counter increments correctly"""
    dut._log.info("Test 5: Bit counter")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in bits one at a time
    for i in range(1, 9):
        dut.serial_in.value = 1
        dut.shift_enable.value = 1
        await RisingEdge(dut.clk)
        dut.shift_enable.value = 0
        await RisingEdge(dut.clk)  # Wait for count to update

        count = int(dut.bit_count.value)
        assert count == i, f"After {i} shifts, count should be {i}, got {count}"
        dut._log.info(f"  After shift {i}: count={count} ✓")

    dut._log.info("✓ Bit counter test PASSED")


@cocotb.test()
async def test_done_flag(dut):
    """Test 6: Done flag timing"""
    dut._log.info("Test 6: Done flag")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift 7 bits - done should be 0
    for i in range(7):
        dut.serial_in.value = 1
        dut.shift_enable.value = 1
        await RisingEdge(dut.clk)
        dut.shift_enable.value = 0
        await RisingEdge(dut.clk)  # Wait for done to update

    assert int(dut.done.value) == 0, "Done should be 0 after 7 bits"

    # Shift 8th bit - done should be 1
    dut.serial_in.value = 1
    dut.shift_enable.value = 1
    await RisingEdge(dut.clk)
    dut.shift_enable.value = 0
    await RisingEdge(dut.clk)  # Wait for done to update

    assert int(dut.done.value) == 1, "Done should be 1 after 8 bits"

    dut._log.info("✓ Done flag test PASSED")


@cocotb.test()
async def test_all_zeros(dut):
    """Test 7: All zeros"""
    dut._log.info("Test 7: All zeros")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    await shift_in_bits(dut, [0, 0, 0, 0, 0, 0, 0, 0])

    result = int(dut.parallel_out.value)
    assert result == 0x00, f"Expected 0x00, got 0x{result:02x}"

    dut._log.info("✓ All zeros test PASSED")


@cocotb.test()
async def test_all_ones(dut):
    """Test 8: All ones"""
    dut._log.info("Test 8: All ones")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    await shift_in_bits(dut, [1, 1, 1, 1, 1, 1, 1, 1])

    result = int(dut.parallel_out.value)
    assert result == 0xFF, f"Expected 0xFF, got 0x{result:02x}"

    dut._log.info("✓ All ones test PASSED")


@cocotb.test()
async def test_alternating_bits(dut):
    """Test 9: Alternating bits 0xAA = 0b10101010"""
    dut._log.info("Test 9: Alternating bits 0xAA")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # 0xAA = 0b10101010 = bits [0,1,0,1,0,1,0,1]
    await shift_in_bits(dut, [0, 1, 0, 1, 0, 1, 0, 1])

    result = int(dut.parallel_out.value)
    assert result == 0xAA, f"Expected 0xAA, got 0x{result:02x}"

    dut._log.info("✓ Alternating bits test PASSED")


@cocotb.test()
async def test_multiple_bytes(dut):
    """Test 10: Multiple consecutive bytes"""
    dut._log.info("Test 10: Multiple bytes")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    test_bytes = [
        ([0, 1, 0, 0, 1, 0, 0, 0], 0x12),  # 0x12 = 0b00010010
        ([0, 0, 1, 0, 1, 1, 0, 0], 0x34),  # 0x34 = 0b00110100
        ([0, 1, 1, 0, 1, 0, 1, 0], 0x56),  # 0x56 = 0b01010110
        ([0, 0, 0, 1, 1, 1, 1, 0], 0x78),  # 0x78 = 0b01111000
    ]

    for bits, expected in test_bytes:
        # Clear before each byte
        dut.clear.value = 1
        await RisingEdge(dut.clk)
        dut.clear.value = 0
        await RisingEdge(dut.clk)

        # Shift in byte
        await shift_in_bits(dut, bits)

        result = int(dut.parallel_out.value)
        assert result == expected, f"Expected 0x{expected:02x}, got 0x{result:02x}"
        dut._log.info(f"  Byte 0x{expected:02x}: PASS ✓")

    dut._log.info("✓ Multiple bytes test PASSED")


@cocotb.test()
async def test_partial_shift(dut):
    """Test 11: Partial shift (less than 8 bits)"""
    dut._log.info("Test 11: Partial shift")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in only 4 bits: [1, 1, 1, 1]
    await shift_in_bits(dut, [1, 1, 1, 1])

    result = int(dut.parallel_out.value)
    count = int(dut.bit_count.value)
    done = int(dut.done.value)

    # After 4 shifts left: 0b00001111
    assert result == 0x0F, f"Expected 0x0F, got 0x{result:02x}"
    assert count == 4, f"Bit count should be 4, got {count}"
    assert done == 0, "Done should be 0 (not full byte yet)"

    dut._log.info(f"  Partial shift: 0x{result:02x}, count={count}, done={done} ✓")
    dut._log.info("✓ Partial shift test PASSED")


@cocotb.test()
async def test_continuous_shifting(dut):
    """Test 12: Continue shifting past 8 bits (counter wrap)"""
    dut._log.info("Test 12: Continuous shifting")

    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())

    dut.shift_enable.value = 0
    dut.clear.value = 0
    dut.serial_in.value = 0

    await reset_dut(dut)

    # Shift in 10 bits total (should wrap counter)
    all_bits = [1, 0, 1, 0, 1, 0, 1, 0, 1, 1]
    await shift_in_bits(dut, all_bits)

    result = int(dut.parallel_out.value)
    count = int(dut.bit_count.value)

    # After 10 shifts: oldest 2 bits (1,0) fell off
    # Remaining: [1,0,1,0,1,0,1,1] = 0b11010101
    assert result == 0xD5, f"Expected 0xD5 (after wrap), got 0x{result:02x}"
    assert count == 2, f"Count should wrap to 2, got {count}"

    dut._log.info(f"  After 10 shifts: 0x{result:02x}, count={count} ✓")
    dut._log.info("✓ Continuous shifting test PASSED")

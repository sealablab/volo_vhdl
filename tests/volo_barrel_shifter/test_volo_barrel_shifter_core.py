"""
CocotB tests for volo_barrel_shifter_core.vhd

Pattern: Pure Combinational Logic
Expected: 100% test success, zero timing issues
"""

import cocotb
from cocotb.triggers import Timer
import random

# Mode constants
MODE_LOGICAL = 0b00
MODE_ARITHMETIC = 0b01
MODE_ROTATE = 0b10

# Direction constants
DIR_LEFT = 0
DIR_RIGHT = 1


def logical_left_shift(value, amount, width=16):
    """Software model: Logical left shift"""
    mask = (1 << width) - 1
    return (value << amount) & mask


def logical_right_shift(value, amount, width=16):
    """Software model: Logical right shift"""
    return value >> amount


def arithmetic_right_shift(value, amount, width=16):
    """Software model: Arithmetic right shift"""
    sign_bit = (value >> (width - 1)) & 1
    result = value >> amount
    if sign_bit:
        # Fill with ones from left
        mask = ((1 << amount) - 1) << (width - amount)
        result |= mask
    mask = (1 << width) - 1
    return result & mask


def rotate_left(value, amount, width=16):
    """Software model: Rotate left"""
    amount = amount % width
    mask = (1 << width) - 1
    return ((value << amount) | (value >> (width - amount))) & mask


def rotate_right(value, amount, width=16):
    """Software model: Rotate right"""
    amount = amount % width
    mask = (1 << width) - 1
    return ((value >> amount) | (value << (width - amount))) & mask


@cocotb.test()
async def test_no_shift(dut):
    """Test 1: Zero shift amount - data should pass through"""
    dut._log.info("Test 1: No shift (amount=0)")

    test_value = 0x1234
    dut.data_in.value = test_value
    dut.shift_amount.value = 0
    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')

    assert dut.data_out.value == test_value, \
        f"No shift should preserve data, got 0x{dut.data_out.value:04x}"

    dut._log.info("✓ No shift test PASSED")


@cocotb.test()
async def test_logical_left_shift(dut):
    """Test 2: Logical left shift"""
    dut._log.info("Test 2: Logical left shift")

    test_cases = [
        (0x0001, 1, 0x0002, "Shift 1 position"),
        (0x0001, 4, 0x0010, "Shift 4 positions"),
        (0x0001, 8, 0x0100, "Shift 8 positions"),
        (0x00FF, 8, 0xFF00, "Shift byte"),
        (0x1234, 1, 0x2468, "Shift multi-bit"),
    ]

    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: 0x{data:04x} << {shift} = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Logical left shift test PASSED")


@cocotb.test()
async def test_logical_right_shift(dut):
    """Test 3: Logical right shift"""
    dut._log.info("Test 3: Logical right shift")

    test_cases = [
        (0x8000, 1, 0x4000, "Shift MSB right"),
        (0x0010, 4, 0x0001, "Shift 4 positions"),
        (0xFF00, 8, 0x00FF, "Shift byte"),
        (0x1234, 1, 0x091A, "Shift multi-bit"),
        (0xFFFF, 1, 0x7FFF, "All ones, shift 1"),
    ]

    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_LOGICAL

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: 0x{data:04x} >> {shift} = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Logical right shift test PASSED")


@cocotb.test()
async def test_arithmetic_right_shift_positive(dut):
    """Test 4: Arithmetic right shift (positive numbers)"""
    dut._log.info("Test 4: Arithmetic right shift (positive)")

    test_cases = [
        (0x7FFF, 1, 0x3FFF, "Max positive >> 1"),
        (0x1234, 1, 0x091A, "Positive >> 1"),
        (0x7000, 4, 0x0700, "Positive >> 4"),
    ]

    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_ARITHMETIC

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: 0x{data:04x} >>> {shift} = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Arithmetic right shift (positive) test PASSED")


@cocotb.test()
async def test_arithmetic_right_shift_negative(dut):
    """Test 5: Arithmetic right shift (negative numbers - sign extend)"""
    dut._log.info("Test 5: Arithmetic right shift (negative)")

    test_cases = [
        (0x8000, 1, 0xC000, "Min negative >> 1 (sign extend)"),
        (0x8000, 4, 0xF800, "Min negative >> 4 (sign extend)"),
        (0xFFFF, 1, 0xFFFF, "All ones >> 1 (stays all ones)"),
        (0x9000, 4, 0xF900, "Negative >> 4"),
    ]

    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_ARITHMETIC

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: 0x{data:04x} >>> {shift} = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Arithmetic right shift (negative) test PASSED")


@cocotb.test()
async def test_rotate_left(dut):
    """Test 6: Rotate left"""
    dut._log.info("Test 6: Rotate left")

    test_cases = [
        (0x0001, 1, 0x0002, "Rotate 1 left by 1"),
        (0x8000, 1, 0x0001, "MSB rotates to LSB"),
        (0x1234, 4, 0x2341, "Multi-bit rotate"),
        (0xF000, 4, 0x000F, "Nibble rotate"),
        (0x0001, 15, 0x8000, "Rotate almost full circle"),
    ]

    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_ROTATE

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: ROL(0x{data:04x}, {shift}) = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Rotate left test PASSED")


@cocotb.test()
async def test_rotate_right(dut):
    """Test 7: Rotate right"""
    dut._log.info("Test 7: Rotate right")

    test_cases = [
        (0x8000, 1, 0x4000, "Rotate MSB right by 1"),
        (0x0001, 1, 0x8000, "LSB rotates to MSB"),
        (0x1234, 4, 0x4123, "Multi-bit rotate"),
        (0x000F, 4, 0xF000, "Nibble rotate"),
        (0x8000, 15, 0x0001, "Rotate almost full circle"),
    ]

    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_ROTATE

    for data, shift, expected, desc in test_cases:
        dut.data_in.value = data
        dut.shift_amount.value = shift
        await Timer(1, unit='ns')

        assert dut.data_out.value == expected, \
            f"{desc}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  {desc}: ROR(0x{data:04x}, {shift}) = 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Rotate right test PASSED")


@cocotb.test()
async def test_edge_cases(dut):
    """Test 8: Edge cases"""
    dut._log.info("Test 8: Edge cases")

    # All zeros
    dut.data_in.value = 0x0000
    dut.shift_amount.value = 8
    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')
    assert dut.data_out.value == 0x0000, "All zeros shifted should stay zero"
    dut._log.info("  All zeros: 0x0000 ✓")

    # All ones logical left
    dut.data_in.value = 0xFFFF
    dut.shift_amount.value = 4
    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')
    assert dut.data_out.value == 0xFFF0, "All ones << 4 should be 0xFFF0"
    dut._log.info("  All ones left: 0xFFF0 ✓")

    # All ones logical right
    dut.data_in.value = 0xFFFF
    dut.shift_amount.value = 4
    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')
    assert dut.data_out.value == 0x0FFF, "All ones >> 4 should be 0x0FFF"
    dut._log.info("  All ones right: 0x0FFF ✓")

    dut._log.info("✓ Edge cases test PASSED")


@cocotb.test()
async def test_walking_bit_left(dut):
    """Test 9: Walking bit pattern (left shift)"""
    dut._log.info("Test 9: Walking bit left")

    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL

    for i in range(15):
        dut.data_in.value = 0x0001
        dut.shift_amount.value = i
        await Timer(1, unit='ns')

        expected = 1 << i
        assert dut.data_out.value == expected, \
            f"Shift {i}: Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
        dut._log.info(f"  Shift {i:2d}: 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Walking bit left test PASSED")


@cocotb.test()
async def test_random_operations(dut):
    """Test 10: Random operations (comprehensive)"""
    dut._log.info("Test 10: Random operations (100 iterations)")

    modes = [MODE_LOGICAL, MODE_ARITHMETIC, MODE_ROTATE]
    directions = [DIR_LEFT, DIR_RIGHT]

    for iteration in range(100):
        data = random.randint(0, 0xFFFF)
        shift = random.randint(0, 15)
        mode = random.choice(modes)
        direction = random.choice(directions)

        dut.data_in.value = data
        dut.shift_amount.value = shift
        dut.shift_dir.value = direction
        dut.shift_mode.value = mode
        await Timer(1, unit='ns')

        # Calculate expected using software models
        if direction == DIR_LEFT:
            if mode == MODE_ROTATE:
                expected = rotate_left(data, shift)
            else:  # Logical or arithmetic (same for left)
                expected = logical_left_shift(data, shift)
        else:  # DIR_RIGHT
            if mode == MODE_LOGICAL:
                expected = logical_right_shift(data, shift)
            elif mode == MODE_ARITHMETIC:
                expected = arithmetic_right_shift(data, shift)
            else:  # MODE_ROTATE
                expected = rotate_right(data, shift)

        result = int(dut.data_out.value)
        assert result == expected, \
            f"Iter {iteration}: data=0x{data:04x}, shift={shift}, mode={mode}, dir={direction}, " \
            f"expected=0x{expected:04x}, got=0x{result:04x}"

    dut._log.info("✓ Random operations test PASSED (100/100)")


@cocotb.test()
async def test_full_width_shifts(dut):
    """Test 11: Full width and beyond shifts"""
    dut._log.info("Test 11: Full width shifts")

    # Left shift by 16 (full width) - should zero out
    dut.data_in.value = 0xFFFF
    dut.shift_amount.value = 16
    dut.shift_dir.value = DIR_LEFT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')
    # Implementation clamps to WIDTH-1, so shift by 15
    expected = 0x8000  # 0xFFFF << 15
    assert dut.data_out.value == expected, \
        f"Left shift by 16 (clamped to 15): Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
    dut._log.info(f"  Left shift full width: 0x{int(dut.data_out.value):04x} ✓")

    # Right shift by 16 (full width)
    dut.data_in.value = 0xFFFF
    dut.shift_amount.value = 16
    dut.shift_dir.value = DIR_RIGHT
    dut.shift_mode.value = MODE_LOGICAL
    await Timer(1, unit='ns')
    expected = 0x0001  # 0xFFFF >> 15 (clamped)
    assert dut.data_out.value == expected, \
        f"Right shift by 16 (clamped to 15): Expected 0x{expected:04x}, got 0x{dut.data_out.value:04x}"
    dut._log.info(f"  Right shift full width: 0x{int(dut.data_out.value):04x} ✓")

    dut._log.info("✓ Full width shifts test PASSED")

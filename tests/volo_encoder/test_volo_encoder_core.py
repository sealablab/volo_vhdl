"""
CocotB tests for volo_encoder_core.vhd

Pattern: Pure Combinational Logic
Expected: 100% test success, zero timing issues
"""

import cocotb
from cocotb.triggers import Timer
import random


@cocotb.test()
async def test_all_zeros(dut):
    """Test 1: All zeros input - valid should be 0"""
    dut._log.info("Test 1: All zeros input")

    dut.data_in.value = 0x00
    await Timer(1, units='ns')  # Pure combinational propagation

    assert dut.valid.value == 0, f"Valid should be 0 for all-zero input, got {dut.valid.value}"
    assert dut.encoded.value == 0, f"Encoded should be 0 for all-zero input, got {dut.encoded.value}"

    dut._log.info("✓ All zeros test PASSED")


@cocotb.test()
async def test_single_bit_positions(dut):
    """Test 2: Single bit set at each position"""
    dut._log.info("Test 2: Single bit positions (0-7)")

    for i in range(8):
        dut.data_in.value = (1 << i)
        await Timer(1, units='ns')

        assert dut.valid.value == 1, f"Valid should be 1 for bit {i}"
        assert dut.encoded.value == i, f"Encoded should be {i}, got {dut.encoded.value}"
        dut._log.info(f"  Bit {i}: encoded={dut.encoded.value} ✓")

    dut._log.info("✓ Single bit positions test PASSED")


@cocotb.test()
async def test_priority_encoding(dut):
    """Test 3: Priority encoding - highest bit wins"""
    dut._log.info("Test 3: Priority encoding (MSB wins)")

    test_cases = [
        (0b11111111, 7, "All bits set"),
        (0b11110000, 7, "Upper nibble set"),
        (0b10101010, 7, "Alternating bits"),
        (0b01010101, 6, "Alternating bits (shifted)"),
        (0b00001111, 3, "Lower nibble set"),
        (0b00000011, 1, "Two LSBs set"),
    ]

    for data, expected, description in test_cases:
        dut.data_in.value = data
        await Timer(1, units='ns')

        assert dut.valid.value == 1, f"{description}: Valid should be 1"
        assert dut.encoded.value == expected, \
            f"{description}: Expected {expected}, got {dut.encoded.value}"
        dut._log.info(f"  {description}: 0b{data:08b} -> {expected} ✓")

    dut._log.info("✓ Priority encoding test PASSED")


@cocotb.test()
async def test_lsb_only(dut):
    """Test 4: LSB only (bit 0)"""
    dut._log.info("Test 4: LSB only")

    dut.data_in.value = 0b00000001
    await Timer(1, units='ns')

    assert dut.valid.value == 1, "Valid should be 1"
    assert dut.encoded.value == 0, f"Encoded should be 0, got {dut.encoded.value}"

    dut._log.info("✓ LSB only test PASSED")


@cocotb.test()
async def test_msb_only(dut):
    """Test 5: MSB only (bit 7)"""
    dut._log.info("Test 5: MSB only")

    dut.data_in.value = 0b10000000
    await Timer(1, units='ns')

    assert dut.valid.value == 1, "Valid should be 1"
    assert dut.encoded.value == 7, f"Encoded should be 7, got {dut.encoded.value}"

    dut._log.info("✓ MSB only test PASSED")


@cocotb.test()
async def test_random_patterns(dut):
    """Test 6: Random bit patterns"""
    dut._log.info("Test 6: Random patterns (100 iterations)")

    for iteration in range(100):
        # Generate random 8-bit pattern
        data = random.randint(0, 255)
        dut.data_in.value = data
        await Timer(1, units='ns')

        # Calculate expected result
        if data == 0:
            expected_valid = 0
            expected_encoded = 0
        else:
            # Find MSB
            for i in range(7, -1, -1):
                if (data >> i) & 1:
                    expected_valid = 1
                    expected_encoded = i
                    break

        assert dut.valid.value == expected_valid, \
            f"Iter {iteration}: data=0x{data:02x}, expected valid={expected_valid}, got {dut.valid.value}"
        if expected_valid:
            assert dut.encoded.value == expected_encoded, \
                f"Iter {iteration}: data=0x{data:02x}, expected {expected_encoded}, got {dut.encoded.value}"

    dut._log.info("✓ Random patterns test PASSED (100/100)")


@cocotb.test()
async def test_alternating_high_low(dut):
    """Test 7: Alternating between 0xFF and 0x00"""
    dut._log.info("Test 7: Alternating high/low")

    for i in range(10):
        # All high
        dut.data_in.value = 0xFF
        await Timer(1, units='ns')
        assert dut.valid.value == 1 and dut.encoded.value == 7, "0xFF should encode to 7"

        # All low
        dut.data_in.value = 0x00
        await Timer(1, units='ns')
        assert dut.valid.value == 0, "0x00 should have valid=0"

    dut._log.info("✓ Alternating high/low test PASSED")


@cocotb.test()
async def test_walking_ones(dut):
    """Test 8: Walking ones pattern"""
    dut._log.info("Test 8: Walking ones (0x01 -> 0x80)")

    for i in range(8):
        pattern = 1 << i
        dut.data_in.value = pattern
        await Timer(1, units='ns')

        assert dut.valid.value == 1, f"Bit {i}: Valid should be 1"
        assert dut.encoded.value == i, f"Bit {i}: Should encode to {i}, got {dut.encoded.value}"
        dut._log.info(f"  Walking bit {i}: 0x{pattern:02x} -> {i} ✓")

    dut._log.info("✓ Walking ones test PASSED")


@cocotb.test()
async def test_cascading_bits(dut):
    """Test 9: Cascading bits (accumulating from LSB)"""
    dut._log.info("Test 9: Cascading bits")

    accumulator = 0
    for i in range(8):
        accumulator |= (1 << i)
        dut.data_in.value = accumulator
        await Timer(1, units='ns')

        # Highest bit should always win
        assert dut.valid.value == 1, f"Step {i}: Valid should be 1"
        assert dut.encoded.value == i, f"Step {i}: Should encode to {i}, got {dut.encoded.value}"
        dut._log.info(f"  Cascade step {i}: 0x{accumulator:02x} -> {i} ✓")

    dut._log.info("✓ Cascading bits test PASSED")


@cocotb.test()
async def test_nibble_patterns(dut):
    """Test 10: Specific nibble patterns"""
    dut._log.info("Test 10: Nibble patterns")

    nibble_tests = [
        (0x0F, 3, "Lower nibble only"),
        (0xF0, 7, "Upper nibble only"),
        (0x33, 5, "Bit pattern 0011_0011"),
        (0xCC, 7, "Bit pattern 1100_1100"),
        (0x55, 6, "Bit pattern 0101_0101"),
        (0xAA, 7, "Bit pattern 1010_1010"),
    ]

    for data, expected, description in nibble_tests:
        dut.data_in.value = data
        await Timer(1, units='ns')

        assert dut.valid.value == 1, f"{description}: Valid should be 1"
        assert dut.encoded.value == expected, \
            f"{description}: Expected {expected}, got {dut.encoded.value}"
        dut._log.info(f"  {description}: 0x{data:02x} -> {expected} ✓")

    dut._log.info("✓ Nibble patterns test PASSED")


@cocotb.test()
async def test_rapid_transitions(dut):
    """Test 11: Rapid input transitions"""
    dut._log.info("Test 11: Rapid transitions (1000 cycles)")

    for _ in range(1000):
        data = random.randint(0, 255)
        dut.data_in.value = data
        await Timer(1, units='ns')

        # Just verify valid flag is consistent
        if data == 0:
            assert dut.valid.value == 0, "Zero input should have valid=0"
        else:
            assert dut.valid.value == 1, f"Non-zero input 0x{data:02x} should have valid=1"

    dut._log.info("✓ Rapid transitions test PASSED (1000/1000)")

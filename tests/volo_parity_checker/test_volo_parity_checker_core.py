"""
CocotB tests for volo_parity_checker_core.vhd

Pattern: Pure Combinational Logic
Expected: 100% test success, zero timing issues
"""

import cocotb
from cocotb.triggers import Timer
import random

# Mode constants
MODE_EVEN = 0
MODE_ODD = 1


def calculate_parity(data, width=8, mode=MODE_EVEN):
    """Software model for parity calculation"""
    xor_result = 0
    for i in range(width):
        xor_result ^= (data >> i) & 1

    if mode == MODE_ODD:
        return 1 - xor_result  # Odd parity
    else:
        return xor_result      # Even parity


@cocotb.test()
async def test_even_parity_all_zeros(dut):
    """Test 1: Even parity - all zeros"""
    dut._log.info("Test 1: Even parity - all zeros")

    dut.data_in.value = 0x00
    dut.parity_in.value = 0
    dut.mode.value = MODE_EVEN
    await Timer(1, unit='ns')

    assert int(dut.parity_out.value) == 0, f"Even parity of 0x00 should be 0, got {dut.parity_out.value}"
    assert int(dut.parity_error.value) == 0, "Parity check should pass"

    dut._log.info("✓ Even parity all zeros test PASSED")


@cocotb.test()
async def test_even_parity_single_bit(dut):
    """Test 2: Even parity - single bit set"""
    dut._log.info("Test 2: Even parity - single bit")

    for i in range(8):
        data = 1 << i
        dut.data_in.value = data
        dut.parity_in.value = 1  # Odd number of bits = parity 1
        dut.mode.value = MODE_EVEN
        await Timer(1, unit='ns')

        assert int(dut.parity_out.value) == 1, f"Bit {i}: Even parity should be 1"
        assert int(dut.parity_error.value) == 0, f"Bit {i}: Parity check should pass"
        dut._log.info(f"  Bit {i}: 0x{data:02x} -> parity=1 ✓")

    dut._log.info("✓ Even parity single bit test PASSED")


@cocotb.test()
async def test_even_parity_patterns(dut):
    """Test 3: Even parity - various patterns"""
    dut._log.info("Test 3: Even parity patterns")

    test_cases = [
        (0b00000000, 0, "All zeros"),
        (0b00000001, 1, "One bit"),
        (0b00000011, 0, "Two bits"),
        (0b00000111, 1, "Three bits"),
        (0b00001111, 0, "Four bits"),
        (0b11111111, 0, "All ones (8 bits)"),
        (0b10101010, 0, "Alternating (4 bits)"),
        (0b01010101, 0, "Alternating (4 bits)"),
    ]

    dut.mode.value = MODE_EVEN

    for data, expected_parity, desc in test_cases:
        dut.data_in.value = data
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        result = int(dut.parity_out.value)
        error = int(dut.parity_error.value)

        assert result == expected_parity, \
            f"{desc}: Expected parity={expected_parity}, got {result}"
        assert error == 0, f"{desc}: Parity check should pass"
        dut._log.info(f"  {desc}: 0b{data:08b} -> parity={result} ✓")

    dut._log.info("✓ Even parity patterns test PASSED")


@cocotb.test()
async def test_odd_parity_patterns(dut):
    """Test 4: Odd parity - various patterns"""
    dut._log.info("Test 4: Odd parity patterns")

    test_cases = [
        (0b00000000, 1, "All zeros"),
        (0b00000001, 0, "One bit"),
        (0b00000011, 1, "Two bits"),
        (0b00000111, 0, "Three bits"),
        (0b00001111, 1, "Four bits"),
        (0b11111111, 1, "All ones (8 bits)"),
        (0b10101010, 1, "Alternating (4 bits)"),
        (0b01010101, 1, "Alternating (4 bits)"),
    ]

    dut.mode.value = MODE_ODD

    for data, expected_parity, desc in test_cases:
        dut.data_in.value = data
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        result = int(dut.parity_out.value)
        error = int(dut.parity_error.value)

        assert result == expected_parity, \
            f"{desc}: Expected parity={expected_parity}, got {result}"
        assert error == 0, f"{desc}: Parity check should pass"
        dut._log.info(f"  {desc}: 0b{data:08b} -> parity={result} ✓")

    dut._log.info("✓ Odd parity patterns test PASSED")


@cocotb.test()
async def test_parity_error_detection(dut):
    """Test 5: Parity error detection"""
    dut._log.info("Test 5: Parity error detection")

    test_cases = [
        (0x00, 1, 1, "All zeros, wrong parity (sent 1, expect 0)"),
        (0x01, 0, 1, "Single bit, wrong parity (sent 0, expect 1)"),
        (0xFF, 1, 1, "All ones, wrong parity (sent 1, expect 0)"),
        (0xAA, 1, 1, "0xAA, wrong parity (sent 1, expect 0)"),
    ]

    dut.mode.value = MODE_EVEN

    for data, parity_in, expected_error, desc in test_cases:
        dut.data_in.value = data
        dut.parity_in.value = parity_in
        await Timer(1, unit='ns')

        error = int(dut.parity_error.value)
        assert error == expected_error, \
            f"{desc}: Expected error={expected_error}, got {error}"
        dut._log.info(f"  {desc}: error={error} ✓")

    dut._log.info("✓ Parity error detection test PASSED")


@cocotb.test()
async def test_random_even_parity(dut):
    """Test 6: Random data - even parity (100 iterations)"""
    dut._log.info("Test 6: Random even parity (100 iterations)")

    dut.mode.value = MODE_EVEN

    for iteration in range(100):
        data = random.randint(0, 255)
        expected_parity = calculate_parity(data, 8, MODE_EVEN)

        dut.data_in.value = data
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        result = int(dut.parity_out.value)
        error = int(dut.parity_error.value)

        assert result == expected_parity, \
            f"Iter {iteration}: data=0x{data:02x}, expected parity={expected_parity}, got {result}"
        assert error == 0, f"Iter {iteration}: Parity check should pass"

    dut._log.info("✓ Random even parity test PASSED (100/100)")


@cocotb.test()
async def test_random_odd_parity(dut):
    """Test 7: Random data - odd parity (100 iterations)"""
    dut._log.info("Test 7: Random odd parity (100 iterations)")

    dut.mode.value = MODE_ODD

    for iteration in range(100):
        data = random.randint(0, 255)
        expected_parity = calculate_parity(data, 8, MODE_ODD)

        dut.data_in.value = data
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        result = int(dut.parity_out.value)
        error = int(dut.parity_error.value)

        assert result == expected_parity, \
            f"Iter {iteration}: data=0x{data:02x}, expected parity={expected_parity}, got {result}"
        assert error == 0, f"Iter {iteration}: Parity check should pass"

    dut._log.info("✓ Random odd parity test PASSED (100/100)")


@cocotb.test()
async def test_random_error_detection(dut):
    """Test 8: Random error detection (100 iterations)"""
    dut._log.info("Test 8: Random error detection (100 iterations)")

    dut.mode.value = MODE_EVEN

    for iteration in range(100):
        data = random.randint(0, 255)
        correct_parity = calculate_parity(data, 8, MODE_EVEN)
        wrong_parity = 1 - correct_parity  # Flip it

        dut.data_in.value = data
        dut.parity_in.value = wrong_parity
        await Timer(1, unit='ns')

        error = int(dut.parity_error.value)
        assert error == 1, \
            f"Iter {iteration}: data=0x{data:02x}, wrong parity should trigger error"

    dut._log.info("✓ Random error detection test PASSED (100/100)")


@cocotb.test()
async def test_alternating_modes(dut):
    """Test 9: Alternating between even/odd modes"""
    dut._log.info("Test 9: Alternating modes")

    data = 0b10101010  # 4 bits set

    # Even parity
    dut.data_in.value = data
    dut.mode.value = MODE_EVEN
    await Timer(1, unit='ns')
    even_parity = int(dut.parity_out.value)
    assert even_parity == 0, "Even parity of 0xAA should be 0"
    dut._log.info(f"  Even mode: 0x{data:02x} -> parity={even_parity} ✓")

    # Odd parity (same data)
    dut.mode.value = MODE_ODD
    await Timer(1, unit='ns')
    odd_parity = int(dut.parity_out.value)
    assert odd_parity == 1, "Odd parity of 0xAA should be 1"
    dut._log.info(f"  Odd mode:  0x{data:02x} -> parity={odd_parity} ✓")

    # Verify they're inverses
    assert even_parity != odd_parity, "Even and odd parity should be inverses"

    dut._log.info("✓ Alternating modes test PASSED")


@cocotb.test()
async def test_walking_ones(dut):
    """Test 10: Walking ones pattern"""
    dut._log.info("Test 10: Walking ones (even parity)")

    dut.mode.value = MODE_EVEN

    for i in range(8):
        data = 1 << i
        expected_parity = 1  # Single bit = odd number of bits = parity 1

        dut.data_in.value = data
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        result = int(dut.parity_out.value)
        error = int(dut.parity_error.value)

        assert result == expected_parity, f"Bit {i}: Expected parity=1"
        assert error == 0, f"Bit {i}: Parity check should pass"
        dut._log.info(f"  Bit {i}: 0x{data:02x} -> parity={result} ✓")

    dut._log.info("✓ Walking ones test PASSED")


@cocotb.test()
async def test_uart_scenario(dut):
    """Test 11: UART-like scenario (8-bit data + parity)"""
    dut._log.info("Test 11: UART scenario (8N1 with parity)")

    # Simulate sending/receiving bytes with even parity
    dut.mode.value = MODE_EVEN

    uart_bytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  # "Hello"

    for byte_val in uart_bytes:
        # Calculate parity
        expected_parity = calculate_parity(byte_val, 8, MODE_EVEN)

        # Transmit (generate parity)
        dut.data_in.value = byte_val
        dut.parity_in.value = expected_parity
        await Timer(1, unit='ns')

        tx_parity = int(dut.parity_out.value)
        rx_error = int(dut.parity_error.value)

        assert tx_parity == expected_parity, \
            f"Byte 0x{byte_val:02x}: Generated parity mismatch"
        assert rx_error == 0, f"Byte 0x{byte_val:02x}: Parity check should pass"

        dut._log.info(f"  TX/RX: 0x{byte_val:02x} ('{chr(byte_val)}') parity={tx_parity} ✓")

    dut._log.info("✓ UART scenario test PASSED")

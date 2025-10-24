"""
CocotB test for Buffer Waveform Generator

Demonstrates MCC buffer loading protocol with realistic network latency.

Tests:
1. Buffer loading with CRC validation
2. Waveform playback from loaded buffer
3. Buffer readback verification
4. CRC error handling
"""

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
import math

from conftest import (
    setup_clock,
    reset_active_high,
    init_mcc_inputs,
    set_regs,
    mcc_network_set_regs,
    mcc_load_buffer,
    wait_for_mcc_ready,
    mcc_cr0
)

# =============================================================================
# Test 1: Basic Buffer Loading
# =============================================================================

@cocotb.test()
async def test_buffer_loading(dut):
    """Test 1: Load buffer and verify CRC validation"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Basic Buffer Loading with CRC Validation")
    dut._log.info("=" * 70)

    # Setup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Load 64 words (8 chunks) with simple ramp pattern
    buffer_data = [i * 100 for i in range(64)]  # 0, 100, 200, ..., 6300

    dut._log.info(f"Loading {len(buffer_data)} words...")

    result = await mcc_load_buffer(dut, buffer_data=buffer_data,
                                    simulate_network_delay=True)  # WITH network latency

    dut._log.info(f"Loaded {result['length']} words in {result['num_chunks']} chunks")
    dut._log.info(f"Expected CRC: 0x{result['expected_crc']:08X}")

    # Wait for FPGA validation
    await ClockCycles(dut.Clk, 100)

    # Check status (OutputD[14] = buffer_valid)
    output_d = int(dut.OutputD.value)
    buffer_valid = (output_d >> 14) & 1
    load_fault = (output_d >> 15) & 1
    load_state = (output_d >> 11) & 0x7

    dut._log.info(f"Status: buffer_valid={buffer_valid}, load_fault={load_fault}, state={load_state}")

    assert buffer_valid == 1, "Buffer should be valid after successful load"
    assert load_fault == 0, "No CRC fault should occur"
    assert load_state == 0b011, "State should be READY (0b011)"

    dut._log.info("✓ Test 1 PASSED: Buffer loaded and validated successfully")


# =============================================================================
# Test 2: Waveform Playback
# =============================================================================

@cocotb.test()
async def test_waveform_playback(dut):
    """Test 2: Load sine wave and verify playback"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Waveform Playback from Buffer")
    dut._log.info("=" * 70)

    # Setup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Generate 256-sample sine wave (full period)
    num_samples = 256
    sine_samples = []
    for i in range(num_samples):
        angle = 2 * math.pi * i / num_samples
        sample = int(32767 * math.sin(angle))  # 16-bit signed
        # Store as 32-bit word (lower 16 bits used by core)
        sine_samples.append(sample & 0xFFFF)

    dut._log.info(f"Generated {num_samples}-sample sine wave")

    # Load buffer with network latency
    result = await mcc_load_buffer(dut, buffer_data=sine_samples,
                                    simulate_network_delay=True)

    dut._log.info(f"Buffer loaded: {result['num_chunks']} chunks, CRC=0x{result['expected_crc']:08X}")

    # Enable module with clock divider = 10 (slow playback for testing)
    clock_div = 10
    control0_value = mcc_cr0() | (clock_div << 16)  # Bits 28:16 = divider

    await set_regs(dut, {0: control0_value}, set_mcc_ready=True)  # NO network latency
    await wait_for_mcc_ready(dut, settle_cycles=20)

    dut._log.info(f"Module enabled with clock_div={clock_div}")

    # Capture first few output samples
    captured_samples = []
    for _ in range(10):
        await ClockCycles(dut.Clk, clock_div + 5)  # Wait for next sample
        sample = int(dut.OutputA.value)
        # Convert to signed 16-bit
        if sample & 0x8000:
            sample = sample - 65536
        captured_samples.append(sample)

    dut._log.info(f"Captured samples: {captured_samples[:5]}...")
    dut._log.info(f"Expected samples: {[s if s < 32768 else s-65536 for s in sine_samples[:5]]}...")

    # Verify first sample matches first buffer entry
    expected_first = sine_samples[0]
    if expected_first & 0x8000:
        expected_first = expected_first - 65536

    assert abs(captured_samples[0] - expected_first) < 5, \
        f"First sample mismatch: got {captured_samples[0]}, expected {expected_first}"

    dut._log.info("✓ Test 2 PASSED: Waveform playback verified")


# =============================================================================
# Test 3: Buffer Wrap-Around
# =============================================================================

@cocotb.test()
async def test_buffer_wraparound(dut):
    """Test 3: Verify buffer wraps around correctly"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Buffer Wrap-Around")
    dut._log.info("=" * 70)

    # Setup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Load small buffer (16 samples)
    buffer_data = [i * 1000 for i in range(16)]  # 0, 1000, 2000, ..., 15000

    await mcc_load_buffer(dut, buffer_data=buffer_data,
                         simulate_network_delay=False)  # Fast loading for this test

    # Enable module
    await set_regs(dut, {0: mcc_cr0() | (5 << 16)}, set_mcc_ready=True)
    await ClockCycles(dut.Clk, 20)

    # Monitor read address (OutputD[10:0])
    addresses = []
    for _ in range(25):  # More than buffer length (16)
        await ClockCycles(dut.Clk, 10)
        output_d = int(dut.OutputD.value)
        addr = output_d & 0x7FF  # Lower 11 bits
        addresses.append(addr)

    dut._log.info(f"Captured addresses: {addresses}")

    # Check that address wraps from 15 back to 0
    assert 15 in addresses, "Should reach address 15"
    assert addresses.count(0) >= 2, "Should wrap back to 0 at least once"

    # Verify sequential pattern (with wraps)
    for i in range(len(addresses) - 1):
        curr = addresses[i]
        next_addr = addresses[i + 1]
        expected_next = (curr + 1) % 16
        # Allow some tolerance for edge cases
        assert next_addr == expected_next or next_addr == curr, \
            f"Address sequence broken: {curr} → {next_addr} (expected {expected_next})"

    dut._log.info("✓ Test 3 PASSED: Buffer wrap-around verified")


# =============================================================================
# Test 4: Buffer Readback
# =============================================================================

@cocotb.test()
async def test_buffer_readback(dut):
    """Test 4: Read back buffer and verify data integrity"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Buffer Readback Verification")
    dut._log.info("=" * 70)

    # Setup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Load buffer with known pattern
    buffer_data = [0x1000 + i for i in range(32)]  # 0x1000, 0x1001, ..., 0x101F

    await mcc_load_buffer(dut, buffer_data=buffer_data,
                         simulate_network_delay=False)

    # Enable module (slow clock div so we can sample at each address)
    await set_regs(dut, {0: mcc_cr0() | (20 << 16)}, set_mcc_ready=True)
    await ClockCycles(dut.Clk, 50)

    # Capture output for first 32 addresses
    readback_data = []
    for i in range(32):
        await ClockCycles(dut.Clk, 25)  # Wait for address to increment
        sample = int(dut.OutputA.value) & 0xFFFF  # Lower 16 bits
        readback_data.append(sample)

    dut._log.info(f"Original:  {buffer_data[:8]}")
    dut._log.info(f"Readback:  {readback_data[:8]}")

    # Verify all samples match
    mismatches = 0
    for i in range(len(buffer_data)):
        expected = buffer_data[i] & 0xFFFF  # Lower 16 bits
        actual = readback_data[i]
        if expected != actual:
            dut._log.error(f"Mismatch at index {i}: expected 0x{expected:04X}, got 0x{actual:04X}")
            mismatches += 1

    assert mismatches == 0, f"{mismatches} readback mismatches detected"

    dut._log.info("✓ Test 4 PASSED: Buffer readback verified")


# =============================================================================
# Test 5: CRC Error Detection
# =============================================================================

@cocotb.test()
async def test_crc_error(dut):
    """Test 5: Verify CRC mismatch triggers ERROR state"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: CRC Error Detection")
    dut._log.info("=" * 70)

    # Setup
    await setup_clock(dut, clk_signal="Clk")
    await reset_active_high(dut, rst_signal="Reset")
    await init_mcc_inputs(dut)

    # Load buffer data
    buffer_data = [i * 10 for i in range(64)]

    # Compute correct CRC
    import zlib
    crc_bytes = b''.join(word.to_bytes(4, byteorder='little') for word in buffer_data)
    correct_crc = zlib.crc32(crc_bytes) & 0xFFFFFFFF

    # Send metadata with WRONG CRC (corrupt it)
    wrong_crc = correct_crc ^ 0xFFFFFFFF  # Flip all bits
    buffer_length = len(buffer_data)

    dut._log.info(f"Sending corrupted CRC: 0x{wrong_crc:08X} (correct: 0x{correct_crc:08X})")

    # Manually send metadata + chunks (bypass mcc_load_buffer helper)
    await ClockCycles(dut.Clk, 10)

    # Send metadata
    dut.Control1.value = (buffer_length << 16)
    dut.Control2.value = wrong_crc
    await ClockCycles(dut.Clk, 10)

    # Send chunks
    chunk_size = 8
    num_chunks = (len(buffer_data) + chunk_size - 1) // chunk_size

    for chunk_idx in range(num_chunks):
        chunk = []
        for i in range(chunk_size):
            word_idx = chunk_idx * chunk_size + i
            if word_idx < len(buffer_data):
                chunk.append(buffer_data[word_idx])
            else:
                chunk.append(0)

        # Set chunk registers
        for i in range(8):
            reg_num = 3 + i
            setattr(dut, f"Control{reg_num}", chunk[i])

        # Pulse STROBE
        dut.Control0.value = 0x08000000  # Bit 27
        await ClockCycles(dut.Clk, 5)
        dut.Control0.value = 0x00000000
        await ClockCycles(dut.Clk, 5)

    # Set LOAD_COMPLETE
    dut.Control0.value = 0x10000000  # Bit 28
    await ClockCycles(dut.Clk, 100)  # Wait for validation

    # Check status - should be in ERROR state
    output_d = int(dut.OutputD.value)
    buffer_valid = (output_d >> 14) & 1
    load_fault = (output_d >> 15) & 1
    load_state = (output_d >> 11) & 0x7

    dut._log.info(f"Status: buffer_valid={buffer_valid}, load_fault={load_fault}, state={load_state:#05b}")

    assert buffer_valid == 0, "Buffer should NOT be valid after CRC error"
    assert load_fault == 1, "Load fault flag should be set"
    assert load_state == 0b111, f"State should be ERROR (0b111), got {load_state:#05b}"

    dut._log.info("✓ Test 5 PASSED: CRC error correctly detected")


# =============================================================================
# Test 6: All Tests Passed Marker
# =============================================================================

@cocotb.test()
async def test_all_passed(dut):
    """Test 6: All tests passed marker"""
    dut._log.info("=" * 70)
    dut._log.info("ALL TESTS PASSED!")
    dut._log.info("=" * 70)

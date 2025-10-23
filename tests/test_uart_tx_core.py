"""
CocotB testbench for uart_tx_core (volo_uart_tx_core.vhd)

Tests:
1. Reset behavior
2. Single byte transmission (8N1 frame format)
3. UART frame timing (start, data, stop bits)
4. Multiple back-to-back transmissions
5. Enable control (freeze during transmission)
6. TX busy flag behavior
7. TX done pulse verification
8. Idle state (TX line high)

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, FallingEdge
from cocotb.clock import Clock
from conftest import setup_clock, reset_active_low
import math


async def wait_for_tx_done(dut, max_cycles=20000):
    """Wait for transmission to complete (tx_busy goes low)"""
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 0:
            return
    raise TimeoutError("TX never completed")


async def capture_uart_frame(dut, expected_bits=10):
    """
    Capture a UART frame by monitoring TX line.
    Returns list of bit values [start, d0, d1, ..., d7, stop]
    """
    bits = []

    # Wait for start bit (falling edge on TX)
    while dut.tx.value == 1:
        await RisingEdge(dut.clk)

    dut._log.info("Start bit detected (TX went low)")

    # Sample at baud rate (divider = 1085 for 115200 @ 125MHz)
    baud_divider = 1085
    half_bit = baud_divider // 2  # Sample in middle of bit

    # Capture 10 bits (start + 8 data + stop)
    for bit_idx in range(expected_bits):
        # Wait to middle of bit period
        # First sample: wait half bit (we're at start of start bit)
        # Subsequent samples: wait full bit
        if bit_idx == 0:
            await ClockCycles(dut.clk, half_bit)
        else:
            await ClockCycles(dut.clk, baud_divider)

        bit_value = int(dut.tx.value)
        bits.append(bit_value)
        dut._log.info(f"Bit {bit_idx}: {bit_value}")

    return bits


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 80)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 80)

    # Setup
    await setup_clock(dut, clk_signal="clk", period_ns=8.0)  # 125 MHz
    dut.enable.value = 1
    dut.data_in.value = 0
    dut.send_valid.value = 0

    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)

    # Check outputs during reset
    assert dut.tx.value == 1, "TX should idle high during reset"
    assert dut.tx_busy.value == 0, "tx_busy should be 0 during reset"
    assert dut.tx_done.value == 0, "tx_done should be 0 during reset"

    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # Verify idle state
    assert dut.tx.value == 1, "TX should remain high after reset"
    assert dut.tx_busy.value == 0, "Should not be busy after reset"

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_idle_state(dut):
    """Test 2: UART Idle State (TX line should be high)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 2: Idle State Verification")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.data_in.value = 0
    dut.send_valid.value = 0

    # TX should remain high when idle
    for _ in range(100):
        await RisingEdge(dut.clk)
        assert dut.tx.value == 1, "TX should idle high"
        assert dut.tx_busy.value == 0, "Should not be busy when idle"

    dut._log.info("✓ Idle state test PASSED")


@cocotb.test()
async def test_single_byte_transmission(dut):
    """Test 3: Single Byte Transmission (0x74 = 't' trigger command)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 3: Single Byte Transmission (0x74 = 't')")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.data_in.value = 0x74  # 't' command (Pinata trigger)
    dut.send_valid.value = 0

    await ClockCycles(dut.clk, 10)

    # Pulse send_valid to start transmission
    dut.send_valid.value = 1
    await RisingEdge(dut.clk)
    dut.send_valid.value = 0

    # Verify tx_busy goes high
    await ClockCycles(dut.clk, 5)
    assert dut.tx_busy.value == 1, "tx_busy should be high during transmission"

    # Wait for transmission to complete
    await wait_for_tx_done(dut)

    dut._log.info("Transmission completed")
    assert dut.tx_busy.value == 0, "tx_busy should be low after completion"
    assert dut.tx.value == 1, "TX should return to idle (high) state"

    dut._log.info("✓ Single byte transmission test PASSED")


@cocotb.test()
async def test_uart_frame_format(dut):
    """Test 4: Verify UART 8N1 Frame Format"""
    dut._log.info("=" * 80)
    dut._log.info("Test 4: UART Frame Format (8N1)")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    test_byte = 0xA5  # 10100101 (good test pattern)
    dut.data_in.value = test_byte
    dut.send_valid.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_valid.value = 1
    await RisingEdge(dut.clk)
    dut.send_valid.value = 0

    # Capture UART frame
    try:
        frame_bits = await capture_uart_frame(dut, expected_bits=10)
    except Exception as e:
        dut._log.error(f"Failed to capture frame: {e}")
        assert False, "Frame capture failed"

    dut._log.info(f"Captured frame: {frame_bits}")

    # Verify frame structure
    assert frame_bits[0] == 0, "Start bit should be 0"
    assert frame_bits[9] == 1, "Stop bit should be 1"

    # Verify data bits (LSB first)
    data_bits = frame_bits[1:9]  # Bits 1-8 are data
    received_byte = 0
    for i, bit in enumerate(data_bits):
        received_byte |= (bit << i)  # LSB first

    dut._log.info(f"Sent: 0x{test_byte:02X}, Received: 0x{received_byte:02X}")
    assert received_byte == test_byte, f"Data mismatch! Expected 0x{test_byte:02X}, got 0x{received_byte:02X}"

    dut._log.info("✓ UART frame format test PASSED")


@cocotb.test()
async def test_tx_busy_flag(dut):
    """Test 5: TX Busy Flag Behavior"""
    dut._log.info("=" * 80)
    dut._log.info("Test 5: TX Busy Flag")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.data_in.value = 0x42
    dut.send_valid.value = 0

    await ClockCycles(dut.clk, 10)

    # Initial state: not busy
    assert dut.tx_busy.value == 0, "Should not be busy initially"

    # Start transmission
    dut.send_valid.value = 1
    await RisingEdge(dut.clk)
    dut.send_valid.value = 0

    # Should become busy
    await ClockCycles(dut.clk, 5)
    assert dut.tx_busy.value == 1, "Should be busy during transmission"

    # Monitor busy flag throughout transmission
    busy_cycles = 0
    max_cycles = 20000
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 1:
            busy_cycles += 1
        else:
            break  # Transmission complete

    dut._log.info(f"TX was busy for {busy_cycles} cycles")

    # Should take approximately 10 bits * 1085 cycles/bit = 10850 cycles
    expected_busy_cycles = 10 * 1085
    assert 0.9 * expected_busy_cycles < busy_cycles < 1.1 * expected_busy_cycles, \
        f"Busy duration {busy_cycles} not close to expected {expected_busy_cycles}"

    # Should be idle now
    assert dut.tx_busy.value == 0, "Should not be busy after completion"

    dut._log.info("✓ TX busy flag test PASSED")


@cocotb.test()
async def test_tx_done_pulse(dut):
    """Test 6: TX Done Pulse (single-cycle)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 6: TX Done Pulse")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.data_in.value = 0x55
    dut.send_valid.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_valid.value = 1
    await RisingEdge(dut.clk)
    dut.send_valid.value = 0

    # Wait for tx_done pulse
    done_seen = False
    for _ in range(20000):
        await RisingEdge(dut.clk)
        if dut.tx_done.value == 1:
            done_seen = True
            dut._log.info("tx_done pulse detected")

            # Should be single-cycle (low next cycle)
            await RisingEdge(dut.clk)
            assert dut.tx_done.value == 0, "tx_done should be single-cycle pulse"
            break

    assert done_seen, "tx_done pulse never appeared"
    dut._log.info("✓ TX done pulse test PASSED")


@cocotb.test()
async def test_back_to_back_transmissions(dut):
    """Test 7: Multiple Back-to-Back Transmissions"""
    dut._log.info("=" * 80)
    dut._log.info("Test 7: Back-to-Back Transmissions")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.send_valid.value = 0

    test_bytes = [0x74, 0x65, 0x64]  # 't', 'e', 'd'

    for byte_val in test_bytes:
        dut._log.info(f"Transmitting 0x{byte_val:02X}")

        # Wait for idle
        while dut.tx_busy.value == 1:
            await RisingEdge(dut.clk)

        # Send byte
        dut.data_in.value = byte_val
        dut.send_valid.value = 1
        await RisingEdge(dut.clk)
        dut.send_valid.value = 0

        # Wait for completion
        await wait_for_tx_done(dut)
        dut._log.info(f"0x{byte_val:02X} transmitted")

    dut._log.info("✓ Back-to-back transmissions test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 8: Enable Control (Freeze FSM)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 8: Enable Control")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="rst_n")

    dut.enable.value = 1
    dut.data_in.value = 0xAA
    dut.send_valid.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_valid.value = 1
    await RisingEdge(dut.clk)
    dut.send_valid.value = 0

    # Wait until busy
    await ClockCycles(dut.clk, 100)
    assert dut.tx_busy.value == 1, "Should be busy"

    # Freeze FSM by disabling
    dut.enable.value = 0
    tx_value_before = int(dut.tx.value)
    stat_before = int(dut.stat_reg.value)

    await ClockCycles(dut.clk, 100)

    tx_value_after = int(dut.tx.value)
    stat_after = int(dut.stat_reg.value)

    # TX and state should be frozen
    assert tx_value_before == tx_value_after, "TX should not change when disabled"
    assert stat_before == stat_after, "State should not change when disabled"
    dut._log.info("FSM successfully frozen")

    # Re-enable and let it complete
    dut.enable.value = 1
    await wait_for_tx_done(dut)

    dut._log.info("✓ Enable control test PASSED")


# Test summary
async def run_all_tests():
    """Called by test runner"""
    pass

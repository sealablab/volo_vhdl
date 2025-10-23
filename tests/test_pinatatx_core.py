"""
CocotB testbench for PinataTX_core

Tests:
1. Reset behavior
2. Single command transmission (Pinata 't' trigger)
3. UART frame format verification
4. TX busy flag behavior
5. TX done pulse
6. Back-to-back commands (rapid fire)
7. Enable control (freeze FSM)

Pinata Protocol:
- 115200 baud, 8N1
- Raw binary (no hex encoding)
- Commands: 't'=0x74 trigger, 'p'=0x70 ping, 'x'=0x78 reset, 'k'=0x6B glitch

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low


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
    while dut.uart_tx.value == 1:
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

        bit_value = int(dut.uart_tx.value)
        bits.append(bit_value)
        dut._log.info(f"Bit {bit_idx}: {bit_value}")

    return bits


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 80)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)  # 125 MHz
    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0
    dut.send_pulse.value = 0

    # Apply reset
    dut.n_reset.value = 0
    await ClockCycles(dut.clk, 5)

    # Check outputs during reset
    assert dut.uart_tx.value == 1, "UART TX should idle high during reset"
    assert dut.tx_busy.value == 0, "tx_busy should be 0 during reset"

    # Release reset
    dut.n_reset.value = 1
    await ClockCycles(dut.clk, 5)

    assert dut.uart_tx.value == 1, "UART TX should remain idle high after reset"
    assert dut.tx_busy.value == 0, "tx_busy should remain 0 after reset"

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_idle_state(dut):
    """Test 2: UART Idle State"""
    dut._log.info("=" * 80)
    dut._log.info("Test 2: Idle State Verification")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0
    dut.send_pulse.value = 0

    # TX should remain high when idle
    for _ in range(100):
        await RisingEdge(dut.clk)
        assert dut.uart_tx.value == 1, "UART TX should idle high"
        assert dut.tx_busy.value == 0, "Should not be busy when idle"

    dut._log.info("✓ Idle state test PASSED")


@cocotb.test()
async def test_trigger_command(dut):
    """Test 3: Pinata Trigger Command ('t' = 0x74)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 3: Pinata Trigger Command (0x74 = 't')")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0x74  # 't' trigger command
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Pulse send to start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Verify tx_busy goes high
    await ClockCycles(dut.clk, 5)
    assert dut.tx_busy.value == 1, "tx_busy should be high during transmission"

    # Wait for transmission to complete
    await wait_for_tx_done(dut)

    dut._log.info("Transmission completed")
    assert dut.tx_busy.value == 0, "tx_busy should be low after completion"
    assert dut.uart_tx.value == 1, "UART TX should return to idle (high) state"

    dut._log.info("✓ Trigger command test PASSED")


@cocotb.test()
async def test_uart_frame_format(dut):
    """Test 4: Verify UART 8N1 Frame Format for Pinata"""
    dut._log.info("=" * 80)
    dut._log.info("Test 4: UART Frame Format (8N1)")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    test_cmd = 0x70  # 'p' ping command (0111 0000 binary)
    dut.cmd_byte.value = test_cmd
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

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

    dut._log.info(f"Sent: 0x{test_cmd:02X} ('{chr(test_cmd)}'), Received: 0x{received_byte:02X}")
    assert received_byte == test_cmd, f"Data mismatch! Expected 0x{test_cmd:02X}, got 0x{received_byte:02X}"

    dut._log.info("✓ UART frame format test PASSED")


@cocotb.test()
async def test_tx_busy_flag(dut):
    """Test 5: TX Busy Flag Behavior"""
    dut._log.info("=" * 80)
    dut._log.info("Test 5: TX Busy Flag")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0x6B  # 'k' glitch test command
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Initial state: not busy
    assert dut.tx_busy.value == 0, "Should not be busy initially"

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Should become busy
    await ClockCycles(dut.clk, 5)
    assert dut.tx_busy.value == 1, "Should be busy after send pulse"

    # Count how long busy lasts
    busy_cycles = 0
    while dut.tx_busy.value == 1:
        await RisingEdge(dut.clk)
        busy_cycles += 1
        if busy_cycles > 15000:  # Safety timeout
            break

    dut._log.info(f"TX was busy for {busy_cycles} cycles")

    # Should be idle again
    assert dut.tx_busy.value == 0, "Should not be busy after transmission"

    # Expected: 10 bits * 1085 cycles/bit ≈ 10850 cycles
    assert 10000 < busy_cycles < 12000, f"Busy duration unexpected: {busy_cycles} cycles"

    dut._log.info("✓ TX busy flag test PASSED")


@cocotb.test()
async def test_tx_done_pulse(dut):
    """Test 6: TX Done Pulse (single-cycle)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 6: TX Done Pulse")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0x78  # 'x' reset target command
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Wait for tx_done pulse
    done_seen = False
    for _ in range(15000):
        await RisingEdge(dut.clk)
        if dut.tx_done.value == 1:
            done_seen = True
            dut._log.info("tx_done pulse detected")

            # Next cycle should be low (single-cycle pulse)
            await RisingEdge(dut.clk)
            assert dut.tx_done.value == 0, "tx_done should be single-cycle pulse"
            break

    assert done_seen, "Should have seen tx_done pulse"
    dut._log.info("✓ TX done pulse test PASSED")


@cocotb.test()
async def test_back_to_back_commands(dut):
    """Test 7: Multiple Back-to-Back Transmissions"""
    dut._log.info("=" * 80)
    dut._log.info("Test 7: Back-to-Back Commands (t, p, x)")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.send_pulse.value = 0

    commands = [
        (0x74, 't'),  # Trigger
        (0x70, 'p'),  # Ping
        (0x78, 'x'),  # Reset
    ]

    for cmd_byte, cmd_char in commands:
        dut.cmd_byte.value = cmd_byte
        dut._log.info(f"Transmitting 0x{cmd_byte:02X} ('{cmd_char}')")

        # Pulse send
        dut.send_pulse.value = 1
        await RisingEdge(dut.clk)
        dut.send_pulse.value = 0

        # Wait for completion
        await wait_for_tx_done(dut)
        dut._log.info(f"0x{cmd_byte:02X} transmitted")

    dut._log.info("✓ Back-to-back commands test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 8: Enable Control (Freeze FSM)"""
    dut._log.info("=" * 80)
    dut._log.info("Test 8: Enable Control")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = 0x74
    dut.send_pulse.value = 0

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Wait a bit
    await ClockCycles(dut.clk, 100)
    assert dut.tx_busy.value == 1, "Should be busy during transmission"

    # Disable module
    dut.enable.value = 0
    await ClockCycles(dut.clk, 100)

    # FSM should freeze (busy stays high, transmission paused)
    assert dut.tx_busy.value == 1, "Should remain busy when disabled (FSM frozen)"
    dut._log.info("FSM successfully frozen")

    # Re-enable
    dut.enable.value = 1
    await ClockCycles(dut.clk, 100)

    # Should resume and complete
    await wait_for_tx_done(dut)
    dut._log.info("✓ Enable control test PASSED")


# Test summary function
async def run_all_tests():
    """This function is called by the test runner"""
    pass  # CocotB discovers tests automatically

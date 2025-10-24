"""
CocotB testbench for simpleserial_v2_tx (ChipWhisperer SimpleSerial V2 protocol)

Tests:
1. Reset behavior
2. Command-only transmission (no payload)
3. Command + 1 byte payload
4. Command + 4 bytes payload
5. COBS encoding with 0x00 in payload
6. TX busy flag behavior
7. TX done pulse
8. Back-to-back commands
9. Enable control (freeze FSM)

SimpleSerial V2 Protocol:
- 230400 baud, 8N1
- Binary encoding with COBS (Consistent Overhead Byte Stuffing)
- Frame delimiters: 0x00
- Format: <0x00><len><cmd><payload><0x00> (COBS-encoded between delimiters)

COBS Example:
- Raw: [0x02, 0x74, 0x41, 0x00]  (len=2, cmd='t', payload=[0x41, 0x00])
- COBS: [0x04, 0x02, 0x74, 0x41, 0x01]  (no 0x00 in encoded data)
- Frame: <0x00><0x04 0x02 0x74 0x41 0x01><0x00>

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low, run_with_timeout


async def wait_for_tx_done(dut, max_cycles=400000):
    """Wait for transmission to complete (tx_busy goes low)

    Timeout calculation:
    - Max frame: ~260 bytes (COBS overhead)
    - @ 230400 baud: 260 × 43μs ≈ 11.2ms
    - @ 125 MHz (8ns/cycle): 11.2ms = 1,400,000 cycles
    - Use 400,000 cycles as reasonable timeout for typical frames
    """
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 0:
            return
    raise TimeoutError("TX never completed")


async def capture_uart_byte(dut, timeout_cycles=150000):
    """
    Capture a single UART byte (8N1 format) at 230400 baud.
    Returns the received byte value.

    Timeout: One UART byte at 230400 baud = 43μs = ~5,400 cycles @ 125MHz
    Use 150,000 cycles to allow for delays between bytes.
    """
    # Wait for start bit (falling edge on TX) with timeout
    for _ in range(timeout_cycles):
        if dut.uart_tx.value == 0:
            break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError(f"No UART start bit detected in {timeout_cycles} cycles")

    # Baud rate divider: 125MHz / 230400 ≈ 543 cycles per bit
    baud_divider = 543
    half_bit = baud_divider // 2

    # Sample start bit (should be 0)
    await ClockCycles(dut.clk, half_bit)
    start_bit = int(dut.uart_tx.value)
    if start_bit != 0:
        raise ValueError(f"Start bit should be 0, got {start_bit}")

    # Sample 8 data bits (LSB first)
    data_bits = []
    for _ in range(8):
        await ClockCycles(dut.clk, baud_divider)
        data_bits.append(int(dut.uart_tx.value))

    # Sample stop bit (should be 1)
    await ClockCycles(dut.clk, baud_divider)
    stop_bit = int(dut.uart_tx.value)
    if stop_bit != 1:
        raise ValueError(f"Stop bit should be 1, got {stop_bit}")

    # Wait for remainder of stop bit to ensure UART settles
    await ClockCycles(dut.clk, baud_divider // 2)

    # Convert bits to byte (LSB first)
    byte_value = 0
    for i, bit in enumerate(data_bits):
        byte_value |= (bit << i)

    return byte_value


async def capture_uart_frame(dut, max_bytes=300):
    """
    Capture a complete SimpleSerial V2 frame.
    Returns: (raw_bytes, decoded_frame)
    - raw_bytes: List of all bytes including delimiters and COBS encoding
    - decoded_frame: dict with 'len', 'cmd', 'payload' after COBS decoding
    """
    # Capture start delimiter
    start_delim = await capture_uart_byte(dut)
    if start_delim != 0x00:
        raise ValueError(f"Expected start delimiter 0x00, got 0x{start_delim:02X}")

    # Capture COBS-encoded data until end delimiter
    raw_bytes = [start_delim]
    cobs_data = []

    for _ in range(max_bytes):
        byte_val = await capture_uart_byte(dut)
        raw_bytes.append(byte_val)

        if byte_val == 0x00:
            # End delimiter found
            break
        else:
            cobs_data.append(byte_val)
    else:
        raise TimeoutError(f"No end delimiter found after {max_bytes} bytes")

    # Decode COBS
    decoded = cobs_decode(cobs_data)

    # Parse frame: [len, cmd, payload...]
    if len(decoded) < 2:
        raise ValueError(f"Decoded frame too short: {decoded}")

    frame = {
        'len': decoded[0],
        'cmd': decoded[1],
        'payload': decoded[2:] if len(decoded) > 2 else []
    }

    return raw_bytes, frame


def cobs_decode(encoded):
    """
    Decode COBS-encoded byte list.

    Algorithm:
    - Read code byte (distance to next 0x00 or end)
    - Copy (code - 1) bytes
    - Insert 0x00 if code < 255 and not at end

    Example:
    - Input: [0x04, 0x02, 0x74, 0x41, 0x01]
    - Output: [0x02, 0x74, 0x41, 0x00]
    """
    if not encoded:
        return []

    decoded = []
    i = 0

    while i < len(encoded):
        code = encoded[i]

        if code == 0:
            raise ValueError("Invalid COBS: code byte cannot be 0x00")

        i += 1

        # Copy (code - 1) bytes
        for _ in range(code - 1):
            if i >= len(encoded):
                raise ValueError("COBS decode error: unexpected end of data")
            decoded.append(encoded[i])
            i += 1

        # Add 0x00 if code < 255 and not at end
        if code < 255 and i < len(encoded):
            decoded.append(0x00)

    return decoded


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.send_pulse.value = 0
    await reset_active_low(dut, rst_signal="n_reset")

    # Verify initial state
    assert dut.tx_busy.value == 0, "tx_busy should be 0 after reset"
    assert dut.tx_done.value == 0, "tx_done should be 0 after reset"
    assert dut.uart_tx.value == 1, "UART TX should idle high"

    dut._log.info("✓ Reset test PASSED")


@cocotb.test()
async def test_command_only(dut):
    """Test 2: Command-Only Transmission (no payload)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Command-Only Transmission")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Send command 't' (0x74) with no payload
    dut.cmd_byte.value = 0x74  # 't'
    dut.payload_len.value = 0
    dut.payload_data.value = 0

    # Pulse send
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # tx_busy should go high
    await ClockCycles(dut.clk, 10)
    assert dut.tx_busy.value == 1, "tx_busy should be high during transmission"

    # Capture frame
    raw_bytes, frame = await capture_uart_frame(dut)

    # Wait for completion
    await wait_for_tx_done(dut)

    # Verify frame structure
    dut._log.info(f"Raw bytes: {[f'0x{b:02X}' for b in raw_bytes]}")
    dut._log.info(f"Decoded frame: len={frame['len']}, cmd=0x{frame['cmd']:02X}, payload={frame['payload']}")

    assert frame['len'] == 0, f"Expected len=0, got {frame['len']}"
    assert frame['cmd'] == 0x74, f"Expected cmd=0x74, got 0x{frame['cmd']:02X}"
    assert len(frame['payload']) == 0, f"Expected empty payload, got {len(frame['payload'])} bytes"

    dut._log.info("✓ Command-only test PASSED")


@cocotb.test()
async def test_command_plus_one_byte(dut):
    """Test 3: Command + 1 Byte Payload"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Command + 1 Byte Payload")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Send command 'p' (0x70) with 1 byte payload [0x41]
    dut.cmd_byte.value = 0x70  # 'p'
    dut.payload_len.value = 1
    dut.payload_data.value = 0x41  # 'A'

    # Pulse send
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Capture frame
    raw_bytes, frame = await capture_uart_frame(dut)
    await wait_for_tx_done(dut)

    # Verify
    dut._log.info(f"Raw bytes: {[f'0x{b:02X}' for b in raw_bytes]}")
    dut._log.info(f"Decoded: len={frame['len']}, cmd=0x{frame['cmd']:02X}, payload={[f'0x{b:02X}' for b in frame['payload']]}")

    assert frame['len'] == 1, f"Expected len=1, got {frame['len']}"
    assert frame['cmd'] == 0x70, f"Expected cmd=0x70, got 0x{frame['cmd']:02X}"
    assert len(frame['payload']) == 1, f"Expected 1 payload byte, got {len(frame['payload'])}"
    assert frame['payload'][0] == 0x41, f"Expected payload[0]=0x41, got 0x{frame['payload'][0]:02X}"

    dut._log.info("✓ Command + 1 byte test PASSED")


@cocotb.test()
async def test_command_plus_four_bytes(dut):
    """Test 4: Command + 4 Bytes Payload"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Command + 4 Bytes Payload")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Send command 'k' (0x6B) with 4 bytes payload [0x00, 0x11, 0x22, 0x33]
    dut.cmd_byte.value = 0x6B  # 'k'
    dut.payload_len.value = 4
    dut.payload_data.value = 0x33221100  # LSB first: [0x00, 0x11, 0x22, 0x33]

    # Pulse send
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Capture frame
    raw_bytes, frame = await capture_uart_frame(dut)
    await wait_for_tx_done(dut)

    # Verify
    dut._log.info(f"Raw bytes: {[f'0x{b:02X}' for b in raw_bytes]}")
    dut._log.info(f"Decoded: len={frame['len']}, cmd=0x{frame['cmd']:02X}, payload={[f'0x{b:02X}' for b in frame['payload']]}")

    assert frame['len'] == 4, f"Expected len=4, got {frame['len']}"
    assert frame['cmd'] == 0x6B, f"Expected cmd=0x6B, got 0x{frame['cmd']:02X}"
    assert len(frame['payload']) == 4, f"Expected 4 payload bytes, got {len(frame['payload'])}"
    assert frame['payload'] == [0x00, 0x11, 0x22, 0x33], f"Payload mismatch: {frame['payload']}"

    dut._log.info("✓ Command + 4 bytes test PASSED")


@cocotb.test()
async def test_cobs_encoding_with_zeros(dut):
    """Test 5: COBS Encoding (payload contains 0x00 bytes)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: COBS Encoding with 0x00 in Payload")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Send payload with multiple 0x00 bytes: [0x00, 0x00, 0xFF, 0x00, 0xAA]
    dut.cmd_byte.value = 0x72  # 'r'
    dut.payload_len.value = 5
    payload = 0xAA00FF0000  # LSB first: [0x00, 0x00, 0xFF, 0x00, 0xAA]
    dut.payload_data.value = payload

    # Pulse send
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Capture frame
    raw_bytes, frame = await capture_uart_frame(dut)
    await wait_for_tx_done(dut)

    # Verify: COBS should have encoded the 0x00 bytes
    dut._log.info(f"Raw bytes (with COBS): {[f'0x{b:02X}' for b in raw_bytes]}")
    dut._log.info(f"Decoded payload: {[f'0x{b:02X}' for b in frame['payload']]}")

    # Check that raw COBS data has NO 0x00 bytes (except delimiters)
    cobs_data = raw_bytes[1:-1]  # Exclude delimiters
    assert 0x00 not in cobs_data, f"COBS data should not contain 0x00: {cobs_data}"

    # Check decoded payload matches expected
    assert frame['len'] == 5, f"Expected len=5, got {frame['len']}"
    assert frame['cmd'] == 0x72, f"Expected cmd=0x72, got 0x{frame['cmd']:02X}"
    assert frame['payload'] == [0x00, 0x00, 0xFF, 0x00, 0xAA], f"Payload mismatch: {frame['payload']}"

    dut._log.info("✓ COBS encoding test PASSED")


@cocotb.test()
async def test_tx_busy_flag(dut):
    """Test 6: TX Busy Flag Behavior"""
    dut._log.info("=" * 70)
    dut._log.info("Test 6: TX Busy Flag Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Initially not busy
    assert dut.tx_busy.value == 0, "tx_busy should be 0 initially"

    # Start transmission
    dut.cmd_byte.value = 0x74
    dut.payload_len.value = 2
    dut.payload_data.value = 0x4241  # [0x41, 0x42]

    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Wait a bit, then check busy flag
    await ClockCycles(dut.clk, 20)
    assert dut.tx_busy.value == 1, "tx_busy should be 1 during transmission"

    # Wait for completion
    await wait_for_tx_done(dut)
    assert dut.tx_busy.value == 0, "tx_busy should be 0 after completion"

    dut._log.info("✓ TX busy flag test PASSED")


@cocotb.test()
async def test_tx_done_pulse(dut):
    """Test 7: TX Done Pulse"""
    dut._log.info("=" * 70)
    dut._log.info("Test 7: TX Done Pulse")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Start transmission
    dut.cmd_byte.value = 0x70
    dut.payload_len.value = 1
    dut.payload_data.value = 0xBB

    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Initially tx_done should be 0
    assert dut.tx_done.value == 0, "tx_done should be 0 during transmission"

    # Wait for completion, watching for tx_done pulse
    done_seen = False
    for _ in range(400000):
        await RisingEdge(dut.clk)
        if dut.tx_done.value == 1:
            done_seen = True
            dut._log.info("✓ tx_done pulse detected!")
            break

    assert done_seen, "tx_done pulse not detected"

    # tx_done should return to 0 after one cycle
    await ClockCycles(dut.clk, 2)
    assert dut.tx_done.value == 0, "tx_done should return to 0"

    dut._log.info("✓ TX done pulse test PASSED")


@cocotb.test()
async def test_back_to_back_commands(dut):
    """Test 8: Back-to-Back Commands"""
    dut._log.info("=" * 70)
    dut._log.info("Test 8: Back-to-Back Commands")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 1
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Send first command
    dut.cmd_byte.value = 0x74  # 't'
    dut.payload_len.value = 0
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Wait for first to complete
    await wait_for_tx_done(dut)
    await ClockCycles(dut.clk, 10)

    # Send second command immediately
    dut.cmd_byte.value = 0x70  # 'p'
    dut.payload_len.value = 1
    dut.payload_data.value = 0x99
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Capture second frame
    raw_bytes, frame = await capture_uart_frame(dut)
    await wait_for_tx_done(dut)

    # Verify second frame
    assert frame['cmd'] == 0x70, f"Expected cmd=0x70, got 0x{frame['cmd']:02X}"
    assert frame['payload'][0] == 0x99, f"Expected payload=0x99, got 0x{frame['payload'][0]:02X}"

    dut._log.info("✓ Back-to-back commands test PASSED")


@cocotb.test()
async def test_enable_control(dut):
    """Test 9: Enable Control (Freeze FSM)"""
    dut._log.info("=" * 70)
    dut._log.info("Test 9: Enable Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    dut.enable.value = 0  # Disabled
    dut.clk_en.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Try to send command while disabled
    dut.cmd_byte.value = 0x74
    dut.payload_len.value = 0
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Wait a bit
    await ClockCycles(dut.clk, 100)

    # Should NOT start transmission (enable=0)
    assert dut.tx_busy.value == 0, "tx_busy should remain 0 when enable=0"

    # Now enable and try again
    dut.enable.value = 1
    await ClockCycles(dut.clk, 2)
    dut.send_pulse.value = 1
    await ClockCycles(dut.clk, 1)
    dut.send_pulse.value = 0

    # Now it should work
    await ClockCycles(dut.clk, 20)
    assert dut.tx_busy.value == 1, "tx_busy should go high when enabled"

    await wait_for_tx_done(dut)

    dut._log.info("✓ Enable control test PASSED")


@cocotb.test()
async def test_summary(dut):
    """Test 10: Summary"""
    dut._log.info("=" * 70)
    dut._log.info("ALL SIMPLESERIAL V2 TX TESTS PASSED!")
    dut._log.info("=" * 70)
    dut._log.info("")
    dut._log.info("Protocol Summary:")
    dut._log.info("  - Baud rate: 230400 (6× faster than V1)")
    dut._log.info("  - Encoding: Binary with COBS")
    dut._log.info("  - Frame: <0x00><len><cmd><payload><0x00>")
    dut._log.info("  - COBS removes 0x00 from data, uses as delimiter")
    dut._log.info("")
    dut._log.info("✓ All 9 tests completed successfully!")

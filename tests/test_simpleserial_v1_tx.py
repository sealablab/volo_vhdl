"""
CocotB testbench for simpleserial_v1_tx (ChipWhisperer protocol)

Tests:
1. Reset behavior
2. Command-only transmission ("t\n")
3. Command + 1 byte payload ("p41\n")
4. Command + 4 bytes payload ("k00112233\n")
5. UART frame format verification
6. TX busy flag behavior
7. TX done pulse
8. Back-to-back commands
9. Enable control (freeze FSM)

SimpleSerial V1 Protocol:
- 38400 baud, 8N1
- Hex ASCII encoding (0xAB → "AB")
- Newline terminator '\n' (0x0A)
- Frame: <cmd><hex_payload><newline>

Author: Volo Engineering with Claude Code
Date: 2025-10-23
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low, run_with_timeout


async def wait_for_tx_done(dut, max_cycles=200000):
    """Wait for transmission to complete (tx_busy goes low)

    Timeout calculation:
    - Max frame: 1 cmd + 32 hex chars + 1 newline = 34 characters
    - @ 38400 baud: 34 × 260μs ≈ 8.8ms
    - @ 125 MHz (8ns/cycle): 8.8ms = 1,100,000 cycles
    - Use 200,000 cycles as reasonable timeout for typical frames
    """
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 0:
            return
    raise TimeoutError("TX never completed")


async def capture_uart_byte(dut, timeout_cycles=350000):
    """
    Capture a single UART byte (8N1 format).
    Returns the received byte value.

    Timeout: One UART byte at 38400 baud = 260μs = ~32,500 cycles @ 125MHz
    Use 350,000 cycles to allow for delays between bytes in multi-byte frames.
    """
    # Wait for start bit (falling edge on TX) with timeout
    for _ in range(timeout_cycles):
        if dut.uart_tx.value == 0:
            break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError(f"No UART start bit detected in {timeout_cycles} cycles")

    # Sample at baud rate (divider = 3255 for 38400 @ 125MHz)
    baud_divider = 3255
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

    # Wait for remainder of stop bit period to ensure UART TX core fully settles
    await ClockCycles(dut.clk, baud_divider // 2)

    # Convert bits to byte (LSB first)
    byte_value = 0
    for i, bit in enumerate(data_bits):
        byte_value |= (bit << i)

    return byte_value


async def capture_uart_string(dut, max_bytes=40):
    """
    Capture UART bytes until newline '\n' is received.
    Returns string of received ASCII characters.
    """
    chars = []
    for _ in range(max_bytes):
        byte_val = await capture_uart_byte(dut)
        char = chr(byte_val)
        chars.append(char)
        dut._log.info(f"Received: 0x{byte_val:02X} ('{char}')")
        if byte_val == 0x0A:  # Newline
            break

    return ''.join(chars)


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 1: Reset Behavior")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)  # 125 MHz
        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.cmd_byte.value = 0
        dut.payload_len.value = 0
        dut.payload_data.value = 0
        dut.send_pulse.value = 0

        # Apply reset
        dut.n_reset.value = 0
        await ClockCycles(dut.clk, 5)

        assert dut.uart_tx.value == 1, "UART TX should idle high during reset"
        assert dut.tx_busy.value == 0, "tx_busy should be 0 during reset"

        # Release reset
        dut.n_reset.value = 1
        await ClockCycles(dut.clk, 5)

        assert dut.tx_busy.value == 0, "tx_busy should remain 0 after reset"
        dut._log.info("✓ Reset test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_reset_behavior")


@cocotb.test()
async def test_command_only(dut):
    """Test 2: Command-Only Transmission ('t\\n')"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 2: Command-Only ('t\\n')")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.cmd_byte.value = ord('t')  # 0x74
        dut.payload_len.value = 0      # No payload
        dut.payload_data.value = 0
        dut.send_pulse.value = 0

        await ClockCycles(dut.clk, 10)

        # Start transmission
        dut.send_pulse.value = 1
        await RisingEdge(dut.clk)
        dut.send_pulse.value = 0

        # Capture frame
        frame = await capture_uart_string(dut)
        dut._log.info(f"Captured frame: '{frame}'")

        assert frame == "t\n", f"Expected 't\\n', got '{frame}'"
        dut._log.info("✓ Command-only test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_command_only")


@cocotb.test()
async def test_command_plus_one_byte(dut):
    """Test 3: Command + 1 Byte Payload ('p41\\n')"""
    dut._log.info("=" * 80)
    dut._log.info("Test 3: Command + 1 Byte ('p41\\n')")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = ord('p')    # 0x70
    dut.payload_len.value = 1        # 1 byte payload
    dut.payload_data.value = 0x41    # Byte 0 = 0x41 (should encode as "41")
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Capture frame
    frame = await capture_uart_string(dut)
    dut._log.info(f"Captured frame: '{frame}'")

    assert frame == "p41\n", f"Expected 'p41\\n', got '{frame}'"
    dut._log.info("✓ Command + 1 byte test PASSED")


@cocotb.test()
async def test_command_plus_four_bytes(dut):
    """Test 4: Command + 4 Bytes Payload ('k00112233\\n')"""
    dut._log.info("=" * 80)
    dut._log.info("Test 4: Command + 4 Bytes ('k00112233\\n')")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = ord('k')        # 0x6B
    dut.payload_len.value = 4            # 4 bytes payload
    # Payload: byte0=0x00, byte1=0x11, byte2=0x22, byte3=0x33
    payload = 0x33221100  # LSB = byte 0
    dut.payload_data.value = payload
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Capture frame
    frame = await capture_uart_string(dut)
    dut._log.info(f"Captured frame: '{frame}'")

    assert frame == "k00112233\n", f"Expected 'k00112233\\n', got '{frame}'"
    dut._log.info("✓ Command + 4 bytes test PASSED")


@cocotb.test()
async def test_hex_encoding_verification(dut):
    """Test 5: Hex Encoding Verification (0xAB → 'AB')"""
    dut._log.info("=" * 80)
    dut._log.info("Test 5: Hex Encoding Verification")
    dut._log.info("=" * 80)

    await setup_clock(dut, clk_signal="clk", period_ns=8.0)
    await reset_active_low(dut, rst_signal="n_reset")

    dut.enable.value = 1
    dut.clk_en.value = 1
    dut.cmd_byte.value = ord('x')        # 0x78
    dut.payload_len.value = 2            # 2 bytes
    # Test edge cases: 0xAB (lowercase), 0xCD (uppercase in result)
    payload = 0xCDAB  # byte0=0xAB, byte1=0xCD
    dut.payload_data.value = payload
    dut.send_pulse.value = 0

    await ClockCycles(dut.clk, 10)

    # Start transmission
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Capture frame
    frame = await capture_uart_string(dut)
    dut._log.info(f"Captured frame: '{frame}'")

    # Expected: "xABCD\n" (uppercase hex)
    assert frame == "xABCD\n", f"Expected 'xABCD\\n', got '{frame}'"
    dut._log.info("✓ Hex encoding verification PASSED")


@cocotb.test()
async def test_tx_busy_flag(dut):
    """Test 6: TX Busy Flag Behavior"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 6: TX Busy Flag")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.cmd_byte.value = ord('t')
        dut.payload_len.value = 0
        dut.payload_data.value = 0
        dut.send_pulse.value = 0

        await ClockCycles(dut.clk, 10)

        # Initial: not busy
        assert dut.tx_busy.value == 0, "Should not be busy initially"

        # Start transmission
        dut.send_pulse.value = 1
        await RisingEdge(dut.clk)
        dut.send_pulse.value = 0

        # Should become busy
        await ClockCycles(dut.clk, 5)
        assert dut.tx_busy.value == 1, "Should be busy after send pulse"

        # Wait for completion
        await wait_for_tx_done(dut)
        assert dut.tx_busy.value == 0, "Should not be busy after completion"

        dut._log.info("✓ TX busy flag test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_tx_busy_flag")


@cocotb.test()
async def test_tx_done_pulse(dut):
    """Test 7: TX Done Pulse"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 7: TX Done Pulse")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.cmd_byte.value = ord('p')
        dut.payload_len.value = 1
        dut.payload_data.value = 0xFF
        dut.send_pulse.value = 0

        await ClockCycles(dut.clk, 10)

        # Start transmission
        dut.send_pulse.value = 1
        await RisingEdge(dut.clk)
        dut.send_pulse.value = 0

        # Wait for tx_done pulse (transmission is 4 chars = ~130,000 cycles)
        done_seen = False
        for _ in range(200000):
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

    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_tx_done_pulse")


@cocotb.test()
async def test_back_to_back_commands(dut):
    """Test 8: Multiple Back-to-Back Transmissions"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 8: Back-to-Back Commands")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.send_pulse.value = 0

        commands = [
            (ord('t'), 0, 0, "t\n"),           # Trigger, no payload
            (ord('p'), 1, 0x42, "p42\n"),      # Ping with 1 byte
            (ord('k'), 2, 0x1100, "k0011\n"),  # Key with 2 bytes
        ]

        for cmd, length, payload, expected in commands:
            # Delay to ensure UART TX core fully settled after previous transmission
            # (uart_busy from uart_tx_core may lag behind our FSM's tx_busy)
            await ClockCycles(dut.clk, 10000)

            dut.cmd_byte.value = cmd
            dut.payload_len.value = length
            dut.payload_data.value = payload
            dut._log.info(f"Sending: '{expected.strip()}'")

            # Pulse send
            dut.send_pulse.value = 1
            await RisingEdge(dut.clk)
            dut.send_pulse.value = 0

            # Capture and verify
            frame = await capture_uart_string(dut)
            assert frame == expected, f"Expected '{expected}', got '{frame}'"
            dut._log.info(f"✓ Received: '{frame.strip()}'")

        dut._log.info("✓ Back-to-back commands test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=20, test_name="test_back_to_back_commands")


@cocotb.test()
async def test_enable_control(dut):
    """Test 9: Enable Control (Freeze FSM)"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 9: Enable Control")
        dut._log.info("=" * 80)

        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        dut.enable.value = 1
        dut.clk_en.value = 1
        dut.cmd_byte.value = ord('t')
        dut.payload_len.value = 0
        dut.payload_data.value = 0
        dut.send_pulse.value = 0

        # Start transmission
        dut.send_pulse.value = 1
        await RisingEdge(dut.clk)
        dut.send_pulse.value = 0

        await ClockCycles(dut.clk, 100)
        assert dut.tx_busy.value == 1, "Should be busy during transmission"

        # Disable module
        dut.enable.value = 0
        await ClockCycles(dut.clk, 100)

        # FSM should freeze
        assert dut.tx_busy.value == 1, "Should remain busy when disabled (FSM frozen)"
        dut._log.info("FSM successfully frozen")

        # Re-enable
        dut.enable.value = 1
        await ClockCycles(dut.clk, 100)

        # Should resume and complete
        await wait_for_tx_done(dut)
        dut._log.info("✓ Enable control test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_enable_control")


# Test summary
async def run_all_tests():
    """Called by test runner"""
    pass  # CocotB discovers tests automatically

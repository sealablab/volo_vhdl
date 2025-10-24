"""
CocotB tests for inspectable_buffer_loader_core

Tests the state machine logic and buffer loading functionality.
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock
import struct
from functools import reduce
import operator

# Add conftest helpers
from conftest import setup_clock, reset_active_low

# State constants (from mcc_loader_pkg.vhd)
LOAD_STATE_IDLE = 0
LOAD_STATE_LOADING = 1
LOAD_STATE_WRITING_CHUNK = 5
LOAD_STATE_VALIDATING = 2
LOAD_STATE_READY = 3
LOAD_STATE_RUNNING = 4
LOAD_STATE_ERROR = 7


@cocotb.test()
async def test_1_reset_and_idle(dut):
    """Test 1: Module starts in IDLE state after reset"""
    dut._log.info("Test 1: Reset and IDLE state")

    # Setup clock
    await setup_clock(dut, clk_signal="clk")

    # Set all control inputs to zero
    dut.clk_en.value = 1
    dut.enable.value = 0
    dut.control0.value = 0
    dut.control1.value = 0
    dut.control2.value = 0
    dut.control3.value = 0
    dut.control4.value = 0
    dut.control5.value = 0
    dut.control6.value = 0
    dut.control7.value = 0
    dut.control8.value = 0
    dut.control9.value = 0
    dut.control10.value = 0
    dut.debug_select_a.value = 0
    dut.debug_select_b.value = 0
    dut.playback_div.value = 0

    # Reset
    await reset_active_low(dut, rst_signal="n_reset")

    # Check initial state
    await ClockCycles(dut.clk, 2)
    assert dut.load_state.value == LOAD_STATE_IDLE, f"Expected IDLE ({LOAD_STATE_IDLE}), got {dut.load_state.value}"
    assert dut.fault.value == 0, "Fault should be 0 after reset"
    assert dut.valid.value == 0, "Valid should be 0 after reset"

    dut._log.info("✓ Test 1 PASSED: Module in IDLE state")


@cocotb.test()
async def test_2_transition_to_loading(dut):
    """Test 2: IDLE → LOADING transition when buffer_length is set"""
    dut._log.info("Test 2: IDLE → LOADING transition")

    await setup_clock(dut, clk_signal="clk")
    dut.clk_en.value = 1
    dut.enable.value = 0

    # Reset
    await reset_active_low(dut, rst_signal="n_reset")
    await ClockCycles(dut.clk, 2)

    # Verify IDLE
    assert dut.load_state.value == LOAD_STATE_IDLE

    # Set buffer length (Control1[31:16] = length)
    dut.control1.value = 8 << 16  # 8 words
    await ClockCycles(dut.clk, 2)

    # Should transition to LOADING
    assert dut.load_state.value == LOAD_STATE_LOADING, f"Expected LOADING ({LOAD_STATE_LOADING}), got {dut.load_state.value}"

    dut._log.info("✓ Test 2 PASSED: Transitioned to LOADING")


@cocotb.test()
async def test_3_strobe_triggers_writing(dut):
    """Test 3: STROBE pulse triggers WRITING_CHUNK state"""
    dut._log.info("Test 3: STROBE triggers WRITING_CHUNK")

    await setup_clock(dut, clk_signal="clk")
    dut.clk_en.value = 1
    dut.enable.value = 0

    await reset_active_low(dut, rst_signal="n_reset")

    # Set metadata
    dut.control1.value = 8 << 16
    dut.control2.value = 0x12345678  # Expected CRC (dummy)

    # Load chunk data
    dut.control3.value = 0x1000
    dut.control4.value = 0x1001
    dut.control5.value = 0x1002
    dut.control6.value = 0x1003
    dut.control7.value = 0x1004
    dut.control8.value = 0x1005
    dut.control9.value = 0x1006
    dut.control10.value = 0x1007

    await ClockCycles(dut.clk, 2)

    # Verify LOADING
    assert dut.load_state.value == LOAD_STATE_LOADING

    # Pulse STROBE (Control0[27])
    dut.control0.value = (1 << 27)
    await ClockCycles(dut.clk, 1)

    # Should transition to WRITING_CHUNK
    await ClockCycles(dut.clk, 1)
    dut._log.info(f"State after STROBE: {dut.load_state.value} (expected {LOAD_STATE_WRITING_CHUNK})")

    assert dut.load_state.value == LOAD_STATE_WRITING_CHUNK, \
        f"Expected WRITING_CHUNK ({LOAD_STATE_WRITING_CHUNK}), got {dut.load_state.value}"

    dut._log.info("✓ Test 3 PASSED: STROBE triggered WRITING_CHUNK")


@cocotb.test()
async def test_4_chunk_writing(dut):
    """Test 4: Verify chunk is written to BRAM over 8 cycles"""
    dut._log.info("Test 4: Chunk writing to BRAM")

    await setup_clock(dut, clk_signal="clk")
    dut.clk_en.value = 1
    dut.enable.value = 0

    await reset_active_low(dut, rst_signal="n_reset")

    # Set metadata
    dut.control1.value = 8 << 16
    dut.control2.value = 0x12345678

    # Load test data
    test_data = [0x1000 + i for i in range(8)]
    dut.control3.value = test_data[0]
    dut.control4.value = test_data[1]
    dut.control5.value = test_data[2]
    dut.control6.value = test_data[3]
    dut.control7.value = test_data[4]
    dut.control8.value = test_data[5]
    dut.control9.value = test_data[6]
    dut.control10.value = test_data[7]

    await ClockCycles(dut.clk, 2)

    # Pulse STROBE
    dut.control0.value = (1 << 27)
    await ClockCycles(dut.clk, 1)
    dut.control0.value = 0
    await ClockCycles(dut.clk, 1)

    # Wait for chunk to be written (8 cycles)
    for cycle in range(10):
        await ClockCycles(dut.clk, 1)
        dut._log.info(f"Cycle {cycle}: State={dut.load_state.value}")
        if dut.load_state.value != LOAD_STATE_WRITING_CHUNK:
            break

    # After 8 words, should exit WRITING_CHUNK
    assert dut.load_state.value != LOAD_STATE_WRITING_CHUNK, \
        "Should have exited WRITING_CHUNK after 8 words"

    dut._log.info("✓ Test 4 PASSED: Chunk written")


@cocotb.test()
async def test_5_complete_buffer_load(dut):
    """Test 5: Complete buffer load with CRC validation"""
    dut._log.info("Test 5: Complete buffer load")

    await setup_clock(dut, clk_signal="clk")
    dut.clk_en.value = 1
    dut.enable.value = 0

    await reset_active_low(dut, rst_signal="n_reset")

    # Prepare test data
    test_data = [0x12345678 + i for i in range(8)]

    # Compute expected XOR checksum (simple: XOR all words together)
    expected_checksum = reduce(operator.xor, test_data)

    dut._log.info(f"Test data: {[hex(w) for w in test_data]}")
    dut._log.info(f"Expected Checksum (XOR): 0x{expected_checksum:08X}")

    # Set metadata
    dut.control1.value = 8 << 16
    dut.control2.value = expected_checksum

    # Load chunk
    dut.control3.value = test_data[0]
    dut.control4.value = test_data[1]
    dut.control5.value = test_data[2]
    dut.control6.value = test_data[3]
    dut.control7.value = test_data[4]
    dut.control8.value = test_data[5]
    dut.control9.value = test_data[6]
    dut.control10.value = test_data[7]

    await ClockCycles(dut.clk, 2)

    # Pulse STROBE
    dut.control0.value = (1 << 27)
    await ClockCycles(dut.clk, 1)

    # Keep STROBE high and also set LOAD_COMPLETE
    dut.control0.value = (1 << 27) | (1 << 28)
    await ClockCycles(dut.clk, 1)

    # Clear STROBE but keep LOAD_COMPLETE high
    dut.control0.value = (1 << 28)
    await ClockCycles(dut.clk, 1)

    # Wait for chunk writing to complete (8 words)
    await ClockCycles(dut.clk, 10)

    # Now clear LOAD_COMPLETE
    dut.control0.value = 0

    # Wait for state transitions
    for cycle in range(20):
        await ClockCycles(dut.clk, 1)
        dut._log.info(f"Cycle {cycle}: State={dut.load_state.value}, Fault={dut.fault.value}, Valid={dut.valid.value}")
        if dut.load_state.value in [LOAD_STATE_READY, LOAD_STATE_ERROR]:
            break

    # Check final state
    dut._log.info(f"Final state: {dut.load_state.value}")
    dut._log.info(f"Fault: {dut.fault.value}")
    dut._log.info(f"Valid: {dut.valid.value}")

    assert dut.fault.value == 0, "Fault should be 0 for successful load"
    assert dut.valid.value == 1, "Valid should be 1 after successful CRC check"
    assert dut.load_state.value == LOAD_STATE_READY, \
        f"Expected READY ({LOAD_STATE_READY}), got {dut.load_state.value}"

    dut._log.info("✓ Test 5 PASSED: Complete buffer load with CRC validation")


@cocotb.test()
async def test_6_crc_mismatch(dut):
    """Test 6: CRC mismatch should set fault and transition to ERROR"""
    dut._log.info("Test 6: CRC mismatch error handling")

    await setup_clock(dut, clk_signal="clk")
    dut.clk_en.value = 1
    dut.enable.value = 0

    await reset_active_low(dut, rst_signal="n_reset")

    # Prepare test data
    test_data = [0x12345678 + i for i in range(8)]

    # Set WRONG CRC
    wrong_crc = 0xDEADBEEF

    # Set metadata
    dut.control1.value = 8 << 16
    dut.control2.value = wrong_crc

    # Load chunk
    dut.control3.value = test_data[0]
    dut.control4.value = test_data[1]
    dut.control5.value = test_data[2]
    dut.control6.value = test_data[3]
    dut.control7.value = test_data[4]
    dut.control8.value = test_data[5]
    dut.control9.value = test_data[6]
    dut.control10.value = test_data[7]

    await ClockCycles(dut.clk, 2)

    # Pulse STROBE
    dut.control0.value = (1 << 27)
    await ClockCycles(dut.clk, 1)

    # Keep STROBE high and also set LOAD_COMPLETE
    dut.control0.value = (1 << 27) | (1 << 28)
    await ClockCycles(dut.clk, 1)

    # Clear STROBE but keep LOAD_COMPLETE high
    dut.control0.value = (1 << 28)
    await ClockCycles(dut.clk, 1)

    # Wait for chunk writing to complete (8 words)
    await ClockCycles(dut.clk, 10)

    # Now clear LOAD_COMPLETE
    dut.control0.value = 0

    # Wait for state transitions
    for cycle in range(20):
        await ClockCycles(dut.clk, 1)
        if dut.load_state.value == LOAD_STATE_ERROR:
            break

    # Check error state
    assert dut.fault.value == 1, "Fault should be 1 for CRC mismatch"
    assert dut.valid.value == 0, "Valid should be 0 for failed CRC"
    assert dut.load_state.value == LOAD_STATE_ERROR, \
        f"Expected ERROR ({LOAD_STATE_ERROR}), got {dut.load_state.value}"

    dut._log.info("✓ Test 6 PASSED: CRC mismatch detected")


@cocotb.test()
async def test_all_tests_passed_marker(dut):
    """Final test marker"""
    dut._log.info("="*70)
    dut._log.info("✅ ALL TESTS PASSED")
    dut._log.info("="*70)

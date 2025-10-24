"""
Minimal debug test for inspectable_buffer_loader_core
Focuses on understanding why module gets stuck in WRITING_CHUNK state
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low

# State constants
LOAD_STATE_IDLE = 0
LOAD_STATE_LOADING = 1
LOAD_STATE_WRITING_CHUNK = 5

# Debug View 2: Write Activity
# Bit[15:12] = chunk_word_idx (4 bits)
# Bit[11]    = "0" (spacing)
# Bit[10:0]  = write_ptr (11 bits)
def decode_write_activity(debug_value):
    """Decode View 2: Write Activity"""
    unsigned = int(debug_value) & 0xFFFF
    chunk_word_idx = (unsigned >> 12) & 0xF
    write_ptr = unsigned & 0x7FF
    return {'chunk_word_idx': chunk_word_idx, 'write_ptr': write_ptr}


@cocotb.test()
async def test_debug_chunk_writing(dut):
    """Minimal test: Watch chunk_word_idx increment"""
    dut._log.info("DEBUG: Minimal chunk writing test")

    # Setup
    await setup_clock(dut, clk_signal="clk")
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

    # Set debug view to Write Activity (View 2)
    dut.debug_select_a.value = 2

    await reset_active_low(dut, rst_signal="n_reset")
    await ClockCycles(dut.clk, 2)

    # Set metadata: buffer length = 8
    dut.control1.value = 8 << 16
    dut.control2.value = 0xDEADBEEF  # CRC (doesn't matter for this test)

    # Load test data
    for i in range(8):
        getattr(dut, f'control{3+i}').value = 0x1000 + i

    await ClockCycles(dut.clk, 2)

    # Check initial state
    dut._log.info(f"Initial State: {dut.load_state.value}")
    assert dut.load_state.value == LOAD_STATE_LOADING

    # Pulse STROBE
    dut.control0.value = (1 << 27)
    await ClockCycles(dut.clk, 1)
    dut.control0.value = 0
    await ClockCycles(dut.clk, 1)

    # Monitor chunk writing for 15 cycles
    dut._log.info("="*70)
    dut._log.info("MONITORING CHUNK WRITING:")
    dut._log.info("="*70)

    for cycle in range(15):
        await ClockCycles(dut.clk, 1)

        state = int(dut.load_state.value)
        fault = int(dut.fault.value)

        # Decode debug view
        write_activity = decode_write_activity(dut.debug_out_a.value)

        dut._log.info(f"Cycle {cycle:2d}: State={state}, Fault={fault}, "
                      f"chunk_word_idx={write_activity['chunk_word_idx']}, "
                      f"write_ptr={write_activity['write_ptr']}")

        if state != LOAD_STATE_WRITING_CHUNK:
            dut._log.info(f"Exited WRITING_CHUNK at cycle {cycle}")
            break

    dut._log.info("="*70)
    dut._log.info("DEBUG TEST COMPLETE")
    dut._log.info("="*70)

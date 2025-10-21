"""
emfi_fsm_test_002.py

CocoTB testbench for emfi-fsm module

Test Case: emfi-fsm-test-002
- Reset with delay_cnt_in=2, firing_cnt_in=2, cooldown_cnt_in=2
- After reset, observe state transitions
- Test passes when module reaches DONE state
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge
from cocotb.types import LogicArray

# State encoding (matches VHDL constants)
RESET_STATE      = 0b000
READY_STATE      = 0b001
DELAY_STATE      = 0b010
FIRING_STATE     = 0b011
COOLING_STATE    = 0b100
DONE_STATE       = 0b101
HARD_FAULT_STATE = 0b110

STATE_NAMES = {
    RESET_STATE:      "RESET",
    READY_STATE:      "READY",
    DELAY_STATE:      "DELAY",
    FIRING_STATE:     "FIRING",
    COOLING_STATE:    "COOLING",
    DONE_STATE:       "DONE",
    HARD_FAULT_STATE: "HARD_FAULT"
}


def get_state_name(state_val):
    """Convert state value to readable name"""
    try:
        state_int = int(state_val)
        return STATE_NAMES.get(state_int, f"UNKNOWN({state_int:03b})")
    except:
        return f"INVALID({state_val})"


@cocotb.test()
async def emfi_fsm_test_002(dut):
    """
    Test case: emfi-fsm-test-002

    Reset with delay_cnt_in=2, firing_cnt_in=2, cooldown_cnt_in=2
    Verify state transitions through all expected states to DONE
    """

    # Create a 10ns period clock (100MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.trig_in.value = 0
    dut.delay_cnt_in.value = 2
    dut.firing_cnt_in.value = 2
    dut.cooldown_cnt_in.value = 2

    # Apply reset
    dut._log.info("=" * 60)
    dut._log.info("Starting emfi-fsm-test-002")
    dut._log.info("Config: delay=2, firing=2, cooldown=2")
    dut._log.info("=" * 60)

    dut.n_reset.value = 0
    await Timer(50, units="ns")  # Hold reset for 50ns
    await RisingEdge(dut.clk)
    dut.n_reset.value = 1

    dut._log.info("Reset released")

    # Track visited states
    visited_states = set()
    # Note: RESET_STATE is transient and transitions immediately, so we expect:
    # READY -> DELAY -> FIRING -> COOLING -> DONE
    expected_sequence = [READY_STATE, DELAY_STATE,
                        FIRING_STATE, COOLING_STATE, DONE_STATE]
    state_sequence = []

    # Wait a clock cycle and check we're in RESET or READY
    await RisingEdge(dut.clk)
    current_state = int(dut.state_out.value)
    state_name = get_state_name(current_state)
    dut._log.info(f"After reset release: state = {state_name}")
    # Capture RESET state if we see it
    if current_state == RESET_STATE:
        visited_states.add(current_state)
        state_sequence.append(current_state)

    # Wait one more cycle to transition from RESET to READY
    await RisingEdge(dut.clk)
    current_state = int(dut.state_out.value)
    state_name = get_state_name(current_state)
    dut._log.info(f"State after 1 cycle: {state_name}")

    # Should be in READY state now, assert trigger
    assert current_state == READY_STATE, f"Expected READY state, got {state_name}"
    dut.trig_in.value = 1
    dut._log.info("Trigger asserted (trig_in = 1)")

    # Monitor state transitions until DONE
    max_cycles = 50  # Safety limit
    cycle_count = 0

    while cycle_count < max_cycles:
        await RisingEdge(dut.clk)
        cycle_count += 1

        current_state = int(dut.state_out.value)
        state_name = get_state_name(current_state)

        # Add to visited states and sequence
        if current_state not in visited_states or current_state != state_sequence[-1] if state_sequence else True:
            visited_states.add(current_state)
            if not state_sequence or state_sequence[-1] != current_state:
                state_sequence.append(current_state)
                dut._log.info(f"Cycle {cycle_count:2d}: State = {state_name}")

        # Check if we've reached DONE state
        if current_state == DONE_STATE:
            dut._log.info("=" * 60)
            dut._log.info("SUCCESS: Reached DONE state!")
            dut._log.info(f"State sequence: {' -> '.join([get_state_name(s) for s in state_sequence])}")
            dut._log.info("=" * 60)
            break

    # Verify we reached DONE state
    assert current_state == DONE_STATE, \
        f"Did not reach DONE state within {max_cycles} cycles. Current state: {state_name}"

    # Verify we visited all expected states
    expected_states_set = set(expected_sequence)
    missing_states = expected_states_set - visited_states

    if missing_states:
        missing_names = [get_state_name(s) for s in missing_states]
        dut._log.error(f"Missing states: {', '.join(missing_names)}")
        assert False, f"Did not visit all expected states. Missing: {missing_names}"

    # Verify DONE state is sticky (stays in DONE for a few cycles)
    dut._log.info("Verifying DONE state is sticky...")
    for i in range(5):
        await RisingEdge(dut.clk)
        current_state = int(dut.state_out.value)
        state_name = get_state_name(current_state)
        assert current_state == DONE_STATE, \
            f"DONE state not sticky! Changed to {state_name} after {i+1} cycles"

    dut._log.info("DONE state verified as sticky")
    dut._log.info("=" * 60)
    dut._log.info("TEST PASSED: emfi-fsm-test-002")
    dut._log.info("=" * 60)

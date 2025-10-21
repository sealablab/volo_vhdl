"""
tpd_med_test_001.py

CocoTB testbench for tpd-med wrapper module

Test Case: tpd-med-test-001
- Tests FSM state transitions (delay=2, firing=2, cooldown=2)
- Tests sticky status register bits
- Tests output level control (trigger_out, intensity_out)
- Verifies outputs are zero outside FIRING state
- Verifies COOLING bit is NOT sticky
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_utils import (
    RESET_STATE, READY_STATE, DELAY_STATE, FIRING_STATE, COOLING_STATE, DONE_STATE,
    get_state_name, decode_status_register, format_status_register, check_bit,
    STATUS_BIT_READY, STATUS_BIT_DELAY, STATUS_BIT_FIRING, STATUS_BIT_COOLING, STATUS_BIT_DONE
)


@cocotb.test()
async def tpd_med_test_001(dut):
    """
    Test case: tpd-med-test-001

    Comprehensive test of tpd-med wrapper:
    1. FSM state transitions
    2. Sticky status register bits
    3. Output level control
    """

    # Test configuration
    DELAY_CYCLES = 2
    FIRING_CYCLES = 2
    COOLDOWN_CYCLES = 2
    TRIG_LEVEL = 0x1234
    INTENS_LEVEL = 0x5678

    # Create a 10ns period clock (100MHz)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.trig_in.value = 0
    dut.delay_cnt_in.value = DELAY_CYCLES
    dut.firing_cnt_in.value = FIRING_CYCLES
    dut.cooldown_cnt_in.value = COOLDOWN_CYCLES
    dut.trig_out_level.value = TRIG_LEVEL
    dut.intens_out_level.value = INTENS_LEVEL

    # Apply reset
    dut._log.info("=" * 70)
    dut._log.info("Starting tpd-med-test-001")
    dut._log.info(f"Config: delay={DELAY_CYCLES}, firing={FIRING_CYCLES}, cooldown={COOLDOWN_CYCLES}")
    dut._log.info(f"Levels: trig=0x{TRIG_LEVEL:04X}, intens=0x{INTENS_LEVEL:04X}")
    dut._log.info("=" * 70)

    dut.n_reset.value = 0
    await Timer(50, unit="ns")  # Hold reset for 50ns
    await RisingEdge(dut.clk)
    dut.n_reset.value = 1

    dut._log.info("Reset released")

    # Wait for FSM to exit RESET and enter READY, then for sticky bit to register
    await RisingEdge(dut.clk)  # FSM transitions from RESET to READY
    await RisingEdge(dut.clk)  # Sticky bit captures READY
    await RisingEdge(dut.clk)  # Give one more cycle for propagation

    # Check initial status register (should have READY bit set)
    status = int(dut.state_reg_out.value)
    dut._log.info(f"Initial status: {format_status_register(status)}")
    assert check_bit(status, STATUS_BIT_READY) == 1, "READY bit should be set after reset"

    # Check outputs are zero before triggering
    trig_out = int(dut.trigger_out.value)
    intens_out = int(dut.intensity_out.value)
    dut._log.info(f"Initial outputs: trigger=0x{trig_out:04X}, intensity=0x{intens_out:04X}")
    assert trig_out == 0, "trigger_out should be 0 before FIRING"
    assert intens_out == 0, "intensity_out should be 0 before FIRING"

    # Assert trigger
    dut.trig_in.value = 1
    dut._log.info("Trigger asserted (trig_in = 1)")

    # Track which sticky bits we've seen set
    seen_ready_sticky = False
    seen_delay_sticky = False
    seen_firing_sticky = False
    seen_done_sticky = False
    seen_cooling_active = False  # COOLING is NOT sticky
    seen_firing_outputs = False

    # Monitor state transitions until DONE
    max_cycles = 50
    cycle_count = 0

    dut._log.info("\nMonitoring sequence...")

    while cycle_count < max_cycles:
        await RisingEdge(dut.clk)
        cycle_count += 1

        # Read current state and outputs
        status = int(dut.state_reg_out.value)
        trig_out = int(dut.trigger_out.value)
        intens_out = int(dut.intensity_out.value)
        status_flags = decode_status_register(status)

        # Log every few cycles
        if cycle_count % 3 == 0 or cycle_count < 5:
            dut._log.info(f"Cycle {cycle_count:2d}: Status={format_status_register(status)}, " +
                         f"Trig=0x{trig_out:04X}, Intens=0x{intens_out:04X}")

        # Track sticky bits getting set
        if status_flags['READY']:
            seen_ready_sticky = True
        if status_flags['DELAY']:
            seen_delay_sticky = True
        if status_flags['FIRING']:
            seen_firing_sticky = True
        if status_flags['DONE']:
            seen_done_sticky = True

        # Track COOLING (non-sticky)
        if status_flags['COOLING']:
            seen_cooling_active = True

        # Check for FIRING outputs
        if trig_out == TRIG_LEVEL and intens_out == INTENS_LEVEL:
            seen_firing_outputs = True
            dut._log.info(f"  -> FIRING outputs detected at cycle {cycle_count}")

        # Check if we've reached DONE state (DONE bit set, COOLING bit clear)
        if status_flags['DONE'] and not status_flags['COOLING']:
            dut._log.info("=" * 70)
            dut._log.info(f"Reached DONE state at cycle {cycle_count}!")
            dut._log.info(f"Final status: {format_status_register(status)}")
            dut._log.info("=" * 70)
            break

    # Verify we reached DONE
    assert status_flags['DONE'], "Did not reach DONE state within timeout"

    # Verify all sticky bits were set
    dut._log.info("\nVerifying sticky bits...")
    assert seen_ready_sticky, "READY sticky bit was never set"
    assert seen_delay_sticky, "DELAY sticky bit was never set"
    assert seen_firing_sticky, "FIRING sticky bit was never set"
    assert seen_done_sticky, "DONE sticky bit was never set"
    dut._log.info("✓ All sticky bits verified")

    # Verify COOLING was seen
    dut._log.info("\nVerifying COOLING behavior...")
    assert seen_cooling_active, "COOLING bit was never set"

    # Verify COOLING bit is NOT sticky (should be 0 now that we're in DONE)
    status = int(dut.state_reg_out.value)
    status_flags = decode_status_register(status)
    assert status_flags['COOLING'] == 0, \
        "COOLING bit should be 0 in DONE state (not sticky)"
    dut._log.info("✓ COOLING is NOT sticky (correctly cleared)")

    # Verify we saw the FIRING outputs
    assert seen_firing_outputs, "Never saw FIRING output levels"
    dut._log.info("✓ FIRING output levels were active")

    # Verify outputs are zero now
    dut._log.info("\nVerifying final outputs...")
    trig_out = int(dut.trigger_out.value)
    intens_out = int(dut.intensity_out.value)
    assert trig_out == 0, f"trigger_out should be 0 after FIRING, got 0x{trig_out:04X}"
    assert intens_out == 0, f"intensity_out should be 0 after FIRING, got 0x{intens_out:04X}"
    dut._log.info("✓ Outputs are zero after sequence")

    # Verify DONE state remains stable
    dut._log.info("\nVerifying DONE state stickiness...")
    for i in range(5):
        await RisingEdge(dut.clk)
        status = int(dut.state_reg_out.value)
        status_flags = decode_status_register(status)
        assert status_flags['DONE'], f"DONE bit should stay set, cycle {i+1}"
        assert status_flags['COOLING'] == 0, f"COOLING should stay 0, cycle {i+1}"
    dut._log.info("✓ DONE state is sticky")

    dut._log.info("=" * 70)
    dut._log.info("TEST PASSED: tpd-med-test-001")
    dut._log.info("\nAll checks passed:")
    dut._log.info("  ✓ State transitions correct")
    dut._log.info("  ✓ Sticky bits (READY, DELAY, FIRING, DONE)")
    dut._log.info("  ✓ COOLING is NOT sticky")
    dut._log.info("  ✓ Output levels during FIRING state")
    dut._log.info("  ✓ Outputs zero outside FIRING state")
    dut._log.info("=" * 70)

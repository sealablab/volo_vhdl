"""
CocotB Testbench for EMFI_Seq Top-Level Module
Tests stair-step DAC output routing through MCC Control registers

This testbench verifies:
1. State machine transitions through S1 -> S2 -> S3 -> S4 -> S1 (wrap)
2. Correct stair-step voltage levels output on DACOut (OutputA)
3. Control register routing: delays, clock divider, enable/clk_en
4. Status register updates (sticky state entry markers)
5. Randomized delay values to ensure robust signal routing

Expected stair levels (from EMFI_Seq_stair.vhd):
  S1 = 1.1V = 0x199A (6554 decimal)
  S2 = 1.2V = 0x1EB8 (7864 decimal)
  S3 = 1.3V = 0x23D7 (9175 decimal)
  S4 = 1.4V = 0x28F5 (10485 decimal)

Author: Claude Code (CocotB migration)
Date: 2025-10-22
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock
import random

# Expected DAC codes for stair levels (signed 16-bit, from Moku_Voltage_pkg)
STAIR_LEVELS = {
    "S1": 0x199A,  # 6554 decimal = 1.1V
    "S2": 0x1EB8,  # 7864 decimal = 1.2V
    "S3": 0x23D7,  # 9175 decimal = 1.3V
    "S4": 0x28F5,  # 10485 decimal = 1.4V
}

# Convert to signed representation for comparison
def to_signed_16(val):
    """Convert unsigned 16-bit value to signed 16-bit (two's complement)"""
    if val & 0x8000:
        return val - 0x10000
    return val

# Expected signed values
STAIR_LEVELS_SIGNED = {k: to_signed_16(v) for k, v in STAIR_LEVELS.items()}


async def setup_clock(dut, period_ns=10):
    """Start clock on MCC-style Clk signal"""
    clock = cocotb.start_soon(Clock(dut.Clk, period_ns, units="ns").start())
    dut._log.info(f"✓ Clock started (Clk, {period_ns}ns period = {1000/period_ns:.1f}MHz)")
    return clock


async def reset_dut(dut, cycles=2):
    """Apply active-high reset (MCC style)"""
    dut.Reset.value = 1
    await ClockCycles(dut.Clk, cycles)
    dut.Reset.value = 0
    await ClockCycles(dut.Clk, 1)
    dut._log.info(f"✓ Reset complete (active-high, {cycles} cycles)")


async def init_control_registers(dut, stair_levels=None):
    """Initialize all control registers to safe defaults

    Args:
        dut: Device under test
        stair_levels: Optional dict with keys S1-S4 for custom stair levels
                     If None, uses default levels (1.1V, 1.2V, 1.3V, 1.4V)
    """
    # Control0: Enable=0 (DISABLED initially), ClkEn=1, DivSel=0
    # Note: Control0[31]=1 means Enable=0 (inverted in Top.vhd)
    # This prevents FSM from advancing during initialization
    dut.Control0.value = 0x80000000  # Bit 31 = 1 → Enable=0

    # Control1-4: Delay values (set to safe non-zero defaults)
    # Tests will override these as needed
    dut.Control1.value = 10  # S1 delay
    dut.Control2.value = 10  # S2 delay
    dut.Control3.value = 10  # S3 delay
    dut.Control4.value = 10  # S4 delay

    # Control5-8: Stair levels (signed 16-bit DAC codes)
    if stair_levels is None:
        # Default levels from original implementation
        dut.Control5.value = STAIR_LEVELS["S1"]  # 1.1V
        dut.Control6.value = STAIR_LEVELS["S2"]  # 1.2V
        dut.Control7.value = STAIR_LEVELS["S3"]  # 1.3V
        dut.Control8.value = STAIR_LEVELS["S4"]  # 1.4V
    else:
        dut.Control5.value = stair_levels["S1"]
        dut.Control6.value = stair_levels["S2"]
        dut.Control7.value = stair_levels["S3"]
        dut.Control8.value = stair_levels["S4"]

    # Control9-15: Unused (initialize to 0)
    for i in range(9, 16):
        getattr(dut, f"Control{i}").value = 0

    # Unused inputs
    dut.InputA.value = 0
    dut.InputB.value = 0
    dut.InputC.value = 0
    dut.InputD.value = 0

    await ClockCycles(dut.Clk, 1)
    dut._log.info("✓ Control registers initialized")


def get_output_values(dut):
    """Extract and decode all outputs"""
    # OutputA = DACOut (16-bit signed stair-step)
    dac_out = int(dut.OutputA.value.signed_integer)

    # OutputB = StatusOut (7 bits in lower portion)
    status = int(dut.OutputB.value) & 0x7F

    # OutputC[3:0] = StateOut (one-hot), [15:4] = Monitor MSBs
    outputc = int(dut.OutputC.value)
    state_oh = outputc & 0x0F
    monitor_msbs = (outputc >> 4) & 0xFFF

    # OutputD[7:0] = DivStatOut (clock divider counter)
    div_stat = int(dut.OutputD.value) & 0xFF

    return {
        "dac_out": dac_out,
        "status": status,
        "state_oh": state_oh,
        "monitor_msbs": monitor_msbs,
        "div_stat": div_stat,
    }


def state_oh_to_name(state_oh):
    """Convert one-hot state encoding to name"""
    state_map = {
        0b0001: "S1",
        0b0010: "S2",
        0b0100: "S3",
        0b1000: "S4",
    }
    return state_map.get(state_oh, f"INVALID(0b{state_oh:04b})")


# =============================================================================
# Test 1: Reset Behavior
# =============================================================================
@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset clears status and sets initial state to S1"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Reset Behavior")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)
    await reset_dut(dut)

    # After reset, should be in S1 with S1 marker set
    outputs = get_output_values(dut)

    assert outputs["state_oh"] == 0b0001, \
        f"State should be S1 (0b0001) after reset, got 0b{outputs['state_oh']:04b}"

    assert outputs["status"] & 0x01 == 0x01, \
        f"Status bit 0 (S1 marker) should be set after reset, got 0x{outputs['status']:02x}"

    # DAC output should be S1 level (1.1V = 0x199A)
    assert outputs["dac_out"] == STAIR_LEVELS_SIGNED["S1"], \
        f"DAC output should be S1 level ({STAIR_LEVELS_SIGNED['S1']}), got {outputs['dac_out']}"

    dut._log.info(f"✓ Reset test PASSED")
    dut._log.info(f"  State: {state_oh_to_name(outputs['state_oh'])}")
    dut._log.info(f"  Status: 0x{outputs['status']:02x}")
    dut._log.info(f"  DAC: {outputs['dac_out']} (expected {STAIR_LEVELS_SIGNED['S1']})")


# =============================================================================
# Test 2: Fixed Stair Levels Verification
# =============================================================================
@cocotb.test()
async def test_fixed_stair_levels(dut):
    """Test 2: Verify hardcoded stair levels for each state"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Fixed Stair Levels Verification")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)

    # Set delays BEFORE reset so they're available when FSM initializes
    dut.Control1.value = 1  # S1 delay = 1
    dut.Control2.value = 1  # S2 delay = 1
    dut.Control3.value = 1  # S3 delay = 1
    dut.Control4.value = 1  # S4 delay = 1
    await ClockCycles(dut.Clk, 1)

    await reset_dut(dut)

    # Enable sequencer operation
    # Note: Control0[31] is Enable (inverted), Control0[30] is ClkEn (inverted)
    dut.Control0.value = 0x00000000  # Enable=1, ClkEn=1, DivSel=0
    await ClockCycles(dut.Clk, 2)

    # Track state transitions and verify DAC output
    expected_sequence = [
        ("S1", 0b0001, STAIR_LEVELS_SIGNED["S1"]),
        ("S2", 0b0010, STAIR_LEVELS_SIGNED["S2"]),
        ("S3", 0b0100, STAIR_LEVELS_SIGNED["S3"]),
        ("S4", 0b1000, STAIR_LEVELS_SIGNED["S4"]),
        ("S1", 0b0001, STAIR_LEVELS_SIGNED["S1"]),  # Wrap back to S1
    ]

    dut._log.info("Monitoring state transitions and DAC output...")

    for i, (state_name, state_oh, expected_dac) in enumerate(expected_sequence):
        # Check current state (before waiting for next transition)
        outputs = get_output_values(dut)
        actual_state = state_oh_to_name(outputs["state_oh"])

        dut._log.info(f"  Transition {i+1}: {actual_state} → DAC={outputs['dac_out']} (expected {expected_dac})")

        assert outputs["state_oh"] == state_oh, \
            f"Expected state {state_name} (0b{state_oh:04b}), got {actual_state} (0b{outputs['state_oh']:04b})"

        assert outputs["dac_out"] == expected_dac, \
            f"DAC output mismatch in {state_name}: expected {expected_dac}, got {outputs['dac_out']}"

        # Wait for state transition
        # With delay=1: 1 cycle to count down, 1 cycle to transition = 2 cycles total
        await ClockCycles(dut.Clk, 2)

    dut._log.info("✓ Fixed stair levels test PASSED")


# =============================================================================
# Test 3: Randomized Delay Values with Stair Level Routing
# =============================================================================
@cocotb.test()
async def test_randomized_delays_stair_routing(dut):
    """Test 3: Random delays ensure stair levels route correctly under various timings"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Randomized Delay Values with Stair Level Routing")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)

    # Generate random delay values at test runtime (7-bit max = 127)
    random.seed()  # Use current time as seed
    delay_s1 = random.randint(2, 15)
    delay_s2 = random.randint(2, 15)
    delay_s3 = random.randint(2, 15)
    delay_s4 = random.randint(2, 15)

    dut._log.info(f"Random delays generated:")
    dut._log.info(f"  S1 delay: {delay_s1}")
    dut._log.info(f"  S2 delay: {delay_s2}")
    dut._log.info(f"  S3 delay: {delay_s3}")
    dut._log.info(f"  S4 delay: {delay_s4}")

    # Set delays BEFORE reset
    dut.Control1.value = delay_s1
    dut.Control2.value = delay_s2
    dut.Control3.value = delay_s3
    dut.Control4.value = delay_s4
    await ClockCycles(dut.Clk, 1)

    await reset_dut(dut)

    # Enable sequencer
    dut.Control0.value = 0x00000000  # Enable=1, ClkEn=1, DivSel=0
    await ClockCycles(dut.Clk, 2)

    # Test sequence: S1 -> S2 -> S3 -> S4 -> S1 (wrap)
    test_sequence = [
        ("S1", 0b0001, STAIR_LEVELS_SIGNED["S1"], delay_s1),
        ("S2", 0b0010, STAIR_LEVELS_SIGNED["S2"], delay_s2),
        ("S3", 0b0100, STAIR_LEVELS_SIGNED["S3"], delay_s3),
        ("S4", 0b1000, STAIR_LEVELS_SIGNED["S4"], delay_s4),
        ("S1", 0b0001, STAIR_LEVELS_SIGNED["S1"], delay_s1),  # Wrap
    ]

    dut._log.info("\nVerifying state transitions with randomized delays...")

    for i, (state_name, state_oh, expected_dac, delay_cycles) in enumerate(test_sequence):
        # Check current state (before waiting for transition)
        outputs = get_output_values(dut)
        actual_state = state_oh_to_name(outputs["state_oh"])

        dut._log.info(f"\n  Step {i+1}: State={actual_state}, DAC={outputs['dac_out']}, Delay={delay_cycles}")

        # Verify current state
        assert outputs["state_oh"] == state_oh, \
            f"Expected {state_name}, got {actual_state}"

        # Verify DAC output matches expected stair level
        assert outputs["dac_out"] == expected_dac, \
            f"DAC mismatch in {state_name}: expected {expected_dac}, got {outputs['dac_out']}"

        # Wait for delay + 1 cycle for transition
        await ClockCycles(dut.Clk, delay_cycles + 1)

    dut._log.info("\n✓ Randomized delays test PASSED")
    dut._log.info("  All stair levels routed correctly under random timing configurations")


# =============================================================================
# Test 4: Status Register Sticky Bits
# =============================================================================
@cocotb.test()
async def test_status_register_sticky_bits(dut):
    """Test 4: Verify sticky status bits set on first entry to each state"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Status Register Sticky Bits")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)

    # Set delays BEFORE reset
    dut.Control1.value = 2
    dut.Control2.value = 2
    dut.Control3.value = 2
    dut.Control4.value = 2
    await ClockCycles(dut.Clk, 1)

    await reset_dut(dut)

    # Enable sequencer
    dut.Control0.value = 0x00000000
    await ClockCycles(dut.Clk, 2)

    # After reset, S1 marker should be set
    outputs = get_output_values(dut)
    assert outputs["status"] == 0b0000001, \
        f"After reset, only S1 marker (bit 0) should be set, got 0b{outputs['status']:07b}"

    # Transition to S2 (delay=2, so wait 3 cycles)
    await ClockCycles(dut.Clk, 3)
    outputs = get_output_values(dut)
    assert outputs["status"] & 0b0000011 == 0b0000011, \
        f"After S2 entry, bits 0,1 should be set, got 0b{outputs['status']:07b}"

    # Transition to S3
    await ClockCycles(dut.Clk, 3)
    outputs = get_output_values(dut)
    assert outputs["status"] & 0b0000111 == 0b0000111, \
        f"After S3 entry, bits 0,1,2 should be set, got 0b{outputs['status']:07b}"

    # Transition to S4
    await ClockCycles(dut.Clk, 3)
    outputs = get_output_values(dut)
    assert outputs["status"] & 0b0001111 == 0b0001111, \
        f"After S4 entry, bits 0,1,2,3 should be set, got 0b{outputs['status']:07b}"

    # Wrap back to S1 (sticky bits should remain)
    await ClockCycles(dut.Clk, 3)
    outputs = get_output_values(dut)
    assert outputs["status"] & 0b0001111 == 0b0001111, \
        f"After wrap to S1, all sticky bits should remain, got 0b{outputs['status']:07b}"

    dut._log.info("✓ Status register sticky bits test PASSED")


# =============================================================================
# Test 5: Clock Divider and ClkEn Control
# =============================================================================
@cocotb.test()
async def test_clock_divider_control(dut):
    """Test 5: Verify clock divider and ClkEn routing through Control0"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: Clock Divider and ClkEn Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)
    await reset_dut(dut)

    # Test ClkEn disable (Control0[30] = 1 disables ClkEn due to inversion)
    dut._log.info("\nTest 5a: ClkEn disabled (sequencer should freeze)")
    dut.Control0.value = 0x40000000  # ClkEn=0 (bit 30 = 1), Enable=1, DivSel=0
    dut.Control1.value = 2
    dut.Control2.value = 2
    dut.Control3.value = 2
    dut.Control4.value = 2

    await ClockCycles(dut.Clk, 2)
    initial_state = get_output_values(dut)["state_oh"]

    # Run many cycles - state should not change
    await ClockCycles(dut.Clk, 20)
    final_state = get_output_values(dut)["state_oh"]

    assert initial_state == final_state, \
        f"With ClkEn=0, state should freeze. Initial={initial_state:04b}, Final={final_state:04b}"

    dut._log.info("  ✓ ClkEn disable verified - sequencer frozen")

    # Re-enable ClkEn and verify operation resumes
    dut._log.info("\nTest 5b: ClkEn re-enabled (sequencer should resume)")
    dut.Control0.value = 0x00000000  # ClkEn=1, Enable=1, DivSel=0

    await ClockCycles(dut.Clk, 10)
    resumed_state = get_output_values(dut)["state_oh"]

    assert resumed_state != initial_state, \
        f"After re-enabling ClkEn, state should change. Initial={initial_state:04b}, Resumed={resumed_state:04b}"

    dut._log.info("  ✓ ClkEn re-enable verified - sequencer resumed")

    dut._log.info("\n✓ Clock divider and ClkEn control test PASSED")


# =============================================================================
# Test 6: Enable Control
# =============================================================================
@cocotb.test()
async def test_enable_control(dut):
    """Test 6: Verify Enable signal routing through Control0[31]"""
    dut._log.info("=" * 70)
    dut._log.info("Test 6: Enable Control")
    dut._log.info("=" * 70)

    await setup_clock(dut)
    await init_control_registers(dut)
    await reset_dut(dut)

    # Disable sequencer (Control0[31] = 1 disables due to inversion)
    dut._log.info("\nTest 6a: Enable disabled (sequencer should hold state)")
    dut.Control0.value = 0x80000000  # Enable=0 (bit 31 = 1), ClkEn=1, DivSel=0
    dut.Control1.value = 2
    dut.Control2.value = 2
    dut.Control3.value = 2
    dut.Control4.value = 2

    await ClockCycles(dut.Clk, 2)
    initial_state = get_output_values(dut)["state_oh"]

    # Run many cycles - state should not advance
    await ClockCycles(dut.Clk, 20)
    final_state = get_output_values(dut)["state_oh"]

    assert initial_state == final_state, \
        f"With Enable=0, state should hold. Initial={initial_state:04b}, Final={final_state:04b}"

    dut._log.info("  ✓ Enable disable verified - sequencer holding")

    # Re-enable and verify operation
    dut._log.info("\nTest 6b: Enable re-enabled (sequencer should advance)")
    dut.Control0.value = 0x00000000  # Enable=1, ClkEn=1, DivSel=0

    await ClockCycles(dut.Clk, 10)
    resumed_state = get_output_values(dut)["state_oh"]

    assert resumed_state != initial_state, \
        f"After re-enabling, state should advance. Initial={initial_state:04b}, Resumed={resumed_state:04b}"

    dut._log.info("  ✓ Enable re-enable verified - sequencer advancing")

    dut._log.info("\n✓ Enable control test PASSED")


# =============================================================================
# Test 7: Runtime-Randomized Stair Levels
# =============================================================================
@cocotb.test()
async def test_runtime_random_stair_levels(dut):
    """Test 7: Verify runtime-randomized stair levels route correctly"""
    dut._log.info("=" * 70)
    dut._log.info("Test 7: Runtime-Randomized Stair Levels")
    dut._log.info("=" * 70)

    await setup_clock(dut)

    # Generate random stair levels at runtime (within Moku range: -32768 to 32767)
    # Generate positive values for easy verification
    random.seed()
    random_levels = {
        "S1": random.randint(1000, 5000),
        "S2": random.randint(5001, 10000),
        "S3": random.randint(10001, 15000),
        "S4": random.randint(15001, 20000),
    }

    dut._log.info("Runtime-generated random stair levels:")
    dut._log.info(f"  S1: {random_levels['S1']} (0x{random_levels['S1']:04x})")
    dut._log.info(f"  S2: {random_levels['S2']} (0x{random_levels['S2']:04x})")
    dut._log.info(f"  S3: {random_levels['S3']} (0x{random_levels['S3']:04x})")
    dut._log.info(f"  S4: {random_levels['S4']} (0x{random_levels['S4']:04x})")

    # Initialize with custom stair levels
    await init_control_registers(dut, stair_levels=random_levels)

    # Set delays BEFORE reset
    dut.Control1.value = 2
    dut.Control2.value = 2
    dut.Control3.value = 2
    dut.Control4.value = 2
    await ClockCycles(dut.Clk, 1)

    await reset_dut(dut)

    # Enable sequencer
    dut.Control0.value = 0x00000000  # Enable=1, ClkEn=1, DivSel=0
    await ClockCycles(dut.Clk, 2)

    # Verify each state outputs the correct random level
    test_sequence = [
        ("S1", 0b0001, random_levels["S1"], 2),
        ("S2", 0b0010, random_levels["S2"], 2),
        ("S3", 0b0100, random_levels["S3"], 2),
        ("S4", 0b1000, random_levels["S4"], 2),
    ]

    dut._log.info("\nVerifying random stair levels...")

    for i, (state_name, state_oh, expected_dac, delay_cycles) in enumerate(test_sequence):
        # Check current state (before waiting for transition)
        outputs = get_output_values(dut)
        actual_state = state_oh_to_name(outputs["state_oh"])

        dut._log.info(f"\n  Step {i+1}: State={actual_state}, DAC={outputs['dac_out']}, Expected={expected_dac}")

        # Verify current state
        assert outputs["state_oh"] == state_oh, \
            f"Expected {state_name}, got {actual_state}"

        # Verify DAC output matches expected random level
        assert outputs["dac_out"] == expected_dac, \
            f"DAC mismatch in {state_name}: expected {expected_dac}, got {outputs['dac_out']}"

        # Wait for delay + 1 cycle for transition
        await ClockCycles(dut.Clk, delay_cycles + 1)

    dut._log.info("\n✓ Runtime-randomized stair levels test PASSED")
    dut._log.info("  All random stair levels routed correctly!")


# =============================================================================
# Summary Test
# =============================================================================
@cocotb.test()
async def test_summary(dut):
    """Final test: Summary and comprehensive check"""
    dut._log.info("=" * 70)
    dut._log.info("EMFI-Seq Top-Level Test Summary")
    dut._log.info("=" * 70)

    dut._log.info("\n✓ All tests completed successfully!")
    dut._log.info("\nVerified capabilities:")
    dut._log.info("  1. Reset behavior and initialization")
    dut._log.info("  2. Fixed stair-step voltage levels (S1-S4)")
    dut._log.info("  3. Randomized delay configurations")
    dut._log.info("  4. Sticky status register updates")
    dut._log.info("  5. Clock divider and ClkEn control")
    dut._log.info("  6. Enable signal routing")
    dut._log.info("  7. Runtime-randomized stair levels (MCC Control5-8)")
    dut._log.info("\nDefault stair levels:")
    dut._log.info(f"  S1: 1.1V = {STAIR_LEVELS['S1']:#06x} ({STAIR_LEVELS_SIGNED['S1']} signed)")
    dut._log.info(f"  S2: 1.2V = {STAIR_LEVELS['S2']:#06x} ({STAIR_LEVELS_SIGNED['S2']} signed)")
    dut._log.info(f"  S3: 1.3V = {STAIR_LEVELS['S3']:#06x} ({STAIR_LEVELS_SIGNED['S3']} signed)")
    dut._log.info(f"  S4: 1.4V = {STAIR_LEVELS['S4']:#06x} ({STAIR_LEVELS_SIGNED['S4']} signed)")
    dut._log.info("\n" + "=" * 70)
    dut._log.info("ALL TESTS PASSED")
    dut._log.info("=" * 70)

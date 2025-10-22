

##JCOTOD: We should add the RESET-MIDRUN test case

``` python
# #############################################################################
# Minimal, teachable cocotb tests for "minimal_sequencer_onehot_ce"
#
# Key ideas demonstrated:
# - Clocks and synchronous reset
# - Driving simple inputs (delays, en, clk_en)
# - Predictable timing: a delay value of N takes (N+1) enabled cycles to advance
# - Checking one-hot state and sticky status bits
#
# How to run (example with GHDL via cocotb's Makefile flow):
#   make SIM=ghdl              # (see Makefile below to set VHDL_SOURCES path)
#
# Notes about DUT behavior:
# - Synchronous reset (active-high) has priority and is NOT gated by clk_en.
# - On entering a state Si, DUT loads delay_cnt <= delay_si.
# - While clk_en='1' and en='1', delay_cnt decrements each cycle.
# - When delay_cnt = 0 on a rising edge, the state advances *on that same edge*.
# - Therefore: time spent in a state (in enabled cycles) is (delay + 1).
# - Sticky status bits (0..3) set on first entry to S1..S4 and never clear (until reset).
# #############################################################################

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, First, Timer
from cocotb.result import TestFailure

# One-hot constants for readability (match the VHDL constants)
S1 = 0b0001
S2 = 0b0010
S3 = 0b0100
S4 = 0b1000

def to_int(vec):
    """Convert std_logic_vector/Unsigned to Python int (handles cocotb BinaryValue)."""
    return int(vec.value)

async def start_clock(dut, period_ns=10):
    """Start a free-running clock on dut.clk."""
    cocotb.start_soon(Clock(dut.clk, period_ns, units="ns").start())

async def apply_sync_reset(dut, cycles=2):
    """
    Apply synchronous reset (active-high) for 'cycles' rising edges.
    IMPORTANT: Reset is NOT gated by clk_en, so no need to set clk_en/en for reset to work.
    """
    dut.rst.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    # Allow one edge to observe post-reset state/outputs settle
    await RisingEdge(dut.clk)

def set_delays(dut, d1, d2, d3, d4):
    """Drive the four 7-bit delay inputs."""
    dut.delay_s1.value = d1
    dut.delay_s2.value = d2
    dut.delay_s3.value = d3
    dut.delay_s4.value = d4

async def advance_exact_enabled_cycles(dut, n):
    """
    Step exactly 'n' rising edges where (clk_en=1 and en=1).
    Assumes those signals are already high.
    """
    for _ in range(n):
        await RisingEdge(dut.clk)

async def expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles, next_state_oh):
    """
    Educational check that mirrors DUT semantics:
      - For 'hold_cycles - 1' enabled edges, the state must remain unchanged.
      - On the 'hold_cycles'-th enabled edge, state must change to 'next_state_oh'.
    Here, 'hold_cycles' == delay + 1 for the *current* state.
    """
    initial_state = to_int(dut.state_oh_out)
    if hold_cycles < 1:
        raise TestFailure("Internal test misuse: hold_cycles must be >= 1")

    # For the first (hold_cycles - 1) edges, state should not change
    for i in range(max(hold_cycles - 1, 0)):
        await RisingEdge(dut.clk)
        assert to_int(dut.state_oh_out) == initial_state, \
            f"State changed too early at enabled step {i+1}: " \
            f"got {to_int(dut.state_oh_out):04b}, expected hold at {initial_state:04b}"

    # On the final (hold_cycles-th) edge, we expect the transition to occur
    await RisingEdge(dut.clk)
    observed = to_int(dut.state_oh_out)
    assert observed == next_state_oh, \
        f"Expected state -> {next_state_oh:04b} after {hold_cycles} enabled cycles, got {observed:04b}"

async def expect_status_bits(dut, s1, s2, s3, s4):
    """
    Assert sticky bits match expectation (bits 0..3 for S1..S4).
    status_out(6..4) are reserved; we only check lower nibble here.
    """
    st = to_int(dut.status_out) & 0x0F
    want = (1 if s1 else 0) \
         | ((1 if s2 else 0) << 1) \
         | ((1 if s3 else 0) << 2) \
         | ((1 if s4 else 0) << 3)
    assert st == want, f"Sticky status mismatch: got 0b{st:04b}, want 0b{want:04b}"

@cocotb.test()
async def test_4321(dut):
    """
    TEST-4321
    Delays: S1=4, S2=3, S3=2, S4=1
    Expectation (enabled cycles per state before advancing): 5, 4, 3, 2
    Also verify sticky bits as we first enter each state.
    """
    # --- bring-up ---
    await start_clock(dut, period_ns=10)
    dut.clk_en.value = 1
    dut.en.value     = 1

    # Program delays
    set_delays(dut, 4, 3, 2, 1)

    # Apply synchronous reset: state=S1, status_out bit0 set, delay_cnt loaded with delay_s1
    await apply_sync_reset(dut)
    assert to_int(dut.state_oh_out) == S1, "Post-reset state must be S1"
    await expect_status_bits(dut, s1=True, s2=False, s3=False, s4=False)

    # S1 (delay=4) -> expect 5 enabled cycles to S2
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=4+1, next_state_oh=S2)
    await expect_status_bits(dut, True, True, False, False)

    # S2 (delay=3) -> expect 4 cycles to S3
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=3+1, next_state_oh=S3)
    await expect_status_bits(dut, True, True, True, False)

    # S3 (delay=2) -> expect 3 cycles to S4
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=2+1, next_state_oh=S4)
    await expect_status_bits(dut, True, True, True, True)

    # S4 (delay=1) -> expect 2 cycles to S1 (wrap)
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=1+1, next_state_oh=S1)
    # Sticky S1 was already set; confirm it stays set and others remain set
    await expect_status_bits(dut, True, True, True, True)

@cocotb.test()
async def test_0240(dut):
    """
    TEST-0240
    Delays: S1=0, S2=2, S3=4, S4=0
    Expectation (enabled cycles per state before advancing): 1, 3, 5, 1
    i.e., delay=0 means "advance on the next enabled clock".
    """
    # --- bring-up ---
    await start_clock(dut, period_ns=10)
    dut.clk_en.value = 1
    dut.en.value     = 1

    # Program delays
    set_delays(dut, 0, 2, 4, 0)

    # Reset and initial checks
    await apply_sync_reset(dut)
    assert to_int(dut.state_oh_out) == S1, "Post-reset state must be S1"
    await expect_status_bits(dut, s1=True, s2=False, s3=False, s4=False)

    # S1 (delay=0) -> expect 1 enabled cycle to S2
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=0+1, next_state_oh=S2)
    await expect_status_bits(dut, True, True, False, False)

    # S2 (delay=2) -> expect 3 cycles to S3
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=2+1, next_state_oh=S3)
    await expect_status_bits(dut, True, True, True, False)

    # S3 (delay=4) -> expect 5 cycles to S4
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=4+1, next_state_oh=S4)
    await expect_status_bits(dut, True, True, True, True)

    # S4 (delay=0) -> expect 1 cycle to S1 (wrap)
    await expect_state_unchanged_for_cycles_then_change_to(dut, hold_cycles=0+1, next_state_oh=S1)
    await expect_status_bits(dut, True, True, True, True)
```
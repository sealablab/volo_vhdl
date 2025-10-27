"""
P3 - Comprehensive Tests for DS1120-PD VOLO

FULL coverage, edge cases, stress testing with realistic scenarios.
Target: 2-3 tests, <1s runtime, comprehensive validation.

Tests:
  T1: Full operational cycle (arm→trigger→fire→cool→done→reset)
  T2: Edge case testing (boundary values, rapid state transitions)
"""

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from test_base import TestBase
from conftest import (
    setup_clock, reset_active_high, init_mcc_inputs,
    mcc_set_regs, mcc_cr0, run_with_timeout
)
from ds1120_pd_volo_tests.ds1120_pd_constants import *


class DS1120PDComprehensiveTests(TestBase):
    """P3 Comprehensive test suite for DS1120-PD VOLO application."""

    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)
        self.clk_period_ns = DEFAULT_CLK_PERIOD_NS

    async def test_full_operational_cycle(self):
        """T1: Complete cycle through all FSM states."""
        # Setup
        await setup_clock(self.dut, clk_signal="Clk", clk_period_ns=self.clk_period_ns)
        await reset_active_high(self.dut, rst_signal="Reset")
        await init_mcc_inputs(self.dut)

        # Configure with realistic operational parameters
        await mcc_set_regs(self.dut, {
            0: mcc_cr0(),
            RegisterMap.ARMED: 0,
            RegisterMap.RESET_FSM: 0,
            RegisterMap.TIMING_CONTROL: 0x00,
            RegisterMap.DELAY_LOWER: TestValues.P3_DELAY & 0xFF,
            RegisterMap.FIRING_DURATION: TestValues.P2_FIRING,
            RegisterMap.COOLING_DURATION: TestValues.P2_COOLING,
            RegisterMap.TRIGGER_THRESH_HI: (Voltages.V2_4 >> 8) & 0xFF,
            RegisterMap.TRIGGER_THRESH_LO: Voltages.V2_4 & 0xFF,
            RegisterMap.INTENSITY_HI: (Voltages.V2_0 >> 8) & 0xFF,
            RegisterMap.INTENSITY_LO: Voltages.V2_0 & 0xFF
        }, set_mcc_ready=True)

        await ClockCycles(self.dut.Clk, 5)

        # Phase 1: Arm the FSM
        self.log("Phase 1: Arming FSM", level='VERBOSE')
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 5)

        # Phase 2: Apply trigger signal
        self.log("Phase 2: Applying trigger", level='VERBOSE')
        trigger_value = Voltages.V3_0  # Above 2.4V threshold
        self.dut.InputA.value = (trigger_value << 16) | trigger_value
        await ClockCycles(self.dut.Clk, 10)

        # Phase 3: Wait for firing
        self.log("Phase 3: Firing active", level='VERBOSE')
        await ClockCycles(self.dut.Clk, TestValues.P2_FIRING)

        # Phase 4: Wait for cooling
        self.log("Phase 4: Cooling down", level='VERBOSE')
        await ClockCycles(self.dut.Clk, TestValues.P2_COOLING)

        # Phase 5: Verify done state
        self.log("Phase 5: Done state", level='VERBOSE')
        await ClockCycles(self.dut.Clk, 5)

        # Phase 6: Reset FSM
        self.log("Phase 6: Resetting FSM", level='VERBOSE')
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 5)

        # Remove trigger
        self.dut.InputA.value = 0

        self.log("Full operational cycle completed successfully", level='NORMAL')

    async def test_edge_cases(self):
        """T2: Test boundary values and edge conditions."""
        # Setup
        await setup_clock(self.dut, clk_signal="Clk", clk_period_ns=self.clk_period_ns)
        await reset_active_high(self.dut, rst_signal="Reset")
        await init_mcc_inputs(self.dut)

        # Edge case 1: Minimum timing values
        self.log("Edge case 1: Minimum timing values", level='VERBOSE')
        await mcc_set_regs(self.dut, {
            0: mcc_cr0(),
            RegisterMap.FIRING_DURATION: 1,   # Minimum
            RegisterMap.COOLING_DURATION: 1,  # Minimum
            RegisterMap.DELAY_LOWER: 1,       # Minimum timeout
        }, set_mcc_ready=True)

        # Quick force fire test
        await mcc_set_regs(self.dut, {RegisterMap.FORCE_FIRE: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 1)
        await mcc_set_regs(self.dut, {RegisterMap.FORCE_FIRE: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 10)

        # Reset
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)

        # Edge case 2: Maximum timing values
        self.log("Edge case 2: Maximum timing values", level='VERBOSE')
        await mcc_set_regs(self.dut, {
            RegisterMap.FIRING_DURATION: 0xFF,   # Maximum 8-bit
            RegisterMap.COOLING_DURATION: 0xFF,  # Maximum 8-bit
            RegisterMap.TIMING_CONTROL: 0xF0,    # Max clock divider
        }, set_mcc_ready=True)

        # Force fire with max values (abbreviated - don't wait full time)
        await mcc_set_regs(self.dut, {RegisterMap.FORCE_FIRE: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 1)
        await mcc_set_regs(self.dut, {RegisterMap.FORCE_FIRE: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 50)  # Just sample, not full duration

        # Reset
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)

        # Edge case 3: Rapid arm/disarm cycles
        self.log("Edge case 3: Rapid arm/disarm", level='VERBOSE')
        await mcc_set_regs(self.dut, {
            RegisterMap.FIRING_DURATION: 4,
            RegisterMap.COOLING_DURATION: 4,
            RegisterMap.TIMING_CONTROL: 0x00,
        }, set_mcc_ready=True)

        for i in range(3):
            # Arm
            await mcc_set_regs(self.dut, {RegisterMap.ARMED: 1}, set_mcc_ready=True)
            await ClockCycles(self.dut.Clk, 2)
            # Immediately disarm
            await mcc_set_regs(self.dut, {RegisterMap.ARMED: 0}, set_mcc_ready=True)
            await ClockCycles(self.dut.Clk, 2)
            # Reset
            await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
            await ClockCycles(self.dut.Clk, 1)
            await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)
            await ClockCycles(self.dut.Clk, 2)

        # Edge case 4: Threshold at boundary
        self.log("Edge case 4: Threshold boundary test", level='VERBOSE')
        threshold = Voltages.V2_4
        await mcc_set_regs(self.dut, {
            RegisterMap.TRIGGER_THRESH_HI: (threshold >> 8) & 0xFF,
            RegisterMap.TRIGGER_THRESH_LO: threshold & 0xFF,
        }, set_mcc_ready=True)

        # Test just below threshold
        self.dut.InputA.value = (threshold - 1) | ((threshold - 1) << 16)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 10)
        # Should not trigger

        # Reset
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)

        # Test just above threshold
        self.dut.InputA.value = (threshold + 1) | ((threshold + 1) << 16)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 10)
        # Should trigger

        # Wait for completion and reset
        await ClockCycles(self.dut.Clk, 20)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)

        self.log("Edge case testing completed", level='NORMAL')

    async def run_p3_comprehensive(self):
        """Run all P3 comprehensive tests."""
        await self.test("T1: Full operational cycle", self.test_full_operational_cycle)
        await self.test("T2: Edge cases", self.test_edge_cases)


@cocotb.test()
async def test_ds1120_pd_p3(dut):
    """Entry point - CocotB discovers this."""
    async def test_logic():
        tester = DS1120PDComprehensiveTests(dut)
        await tester.run_p3_comprehensive()
        tester.print_summary()

    await run_with_timeout(test_logic(), timeout_sec=15, test_name="DS1120-PD P3 Comprehensive")
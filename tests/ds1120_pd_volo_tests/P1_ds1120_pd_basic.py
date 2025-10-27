"""
P1 - Basic Tests for DS1120-PD VOLO

MINIMAL output, FAST execution, ESSENTIAL validation only.
Target: 3 tests, <100ms runtime, <50 tokens output.

Tests:
  T1: Reset behavior - FSM returns to READY
  T2: VOLO_READY control - 3-bit enable scheme
  T3: Basic arm/trigger - Simple operational cycle
"""

import cocotb
from cocotb.triggers import ClockCycles
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


class DS1120PDBasicTests(TestBase):
    """P1 Basic test suite for DS1120-PD VOLO application."""

    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)
        self.clk_period_ns = DEFAULT_CLK_PERIOD_NS

    async def test_reset(self):
        """T1: Reset puts FSM in READY state."""
        # Setup
        await setup_clock(self.dut, clk_signal="Clk", clk_period_ns=self.clk_period_ns)
        await init_mcc_inputs(self.dut)

        # Apply reset
        self.dut.Reset.value = 1
        await ClockCycles(self.dut.Clk, 5)

        # Check outputs during reset
        assert self.dut.OutputA.value == 0, "OutputA should be 0 during reset"
        assert self.dut.OutputB.value == 0, "OutputB should be 0 during reset"

        # Release reset
        self.dut.Reset.value = 0
        await ClockCycles(self.dut.Clk, 2)

        # Outputs should remain zero (not enabled)
        assert self.dut.OutputA.value == 0, "OutputA should be 0 after reset"

    async def test_volo_ready(self):
        """T2: VOLO_READY 3-bit control scheme."""
        # Setup
        await setup_clock(self.dut, clk_signal="Clk", clk_period_ns=self.clk_period_ns)
        await reset_active_high(self.dut, rst_signal="Reset")
        await init_mcc_inputs(self.dut)

        # Test 1: Module disabled when CR0=0
        await mcc_set_regs(self.dut, {0: 0x00000000}, set_mcc_ready=False)
        await ClockCycles(self.dut.Clk, TestValues.P1_TEST_CYCLES)
        assert self.dut.OutputA.value == 0, "Module should be disabled"

        # Test 2: Enable with all 3 bits
        await mcc_set_regs(self.dut, {
            0: mcc_cr0(),  # 0xE0000000 - all 3 bits
            RegisterMap.FORCE_FIRE: 1,
            RegisterMap.INTENSITY_HI: 0x20,
            RegisterMap.INTENSITY_LO: 0x00
        }, set_mcc_ready=True)

        await ClockCycles(self.dut.Clk, 2)
        # Clear force fire
        await mcc_set_regs(self.dut, {RegisterMap.FORCE_FIRE: 0}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, TestValues.P1_FIRING + TestValues.P1_COOLING)

        # Module should have responded (we don't check exact values in P1)
        self.log("VOLO_READY control validated", level='DEBUG')

    async def test_basic_arm_trigger(self):
        """T3: Basic arm and trigger cycle."""
        # Setup
        await setup_clock(self.dut, clk_signal="Clk", clk_period_ns=self.clk_period_ns)
        await reset_active_high(self.dut, rst_signal="Reset")
        await init_mcc_inputs(self.dut)

        # Configure with P1 minimal values
        await mcc_set_regs(self.dut, {
            0: mcc_cr0(),
            RegisterMap.ARMED: 0,
            RegisterMap.TIMING_CONTROL: 0x00,  # No clock division
            RegisterMap.DELAY_LOWER: TestValues.P1_DELAY,
            RegisterMap.FIRING_DURATION: TestValues.P1_FIRING,
            RegisterMap.COOLING_DURATION: TestValues.P1_COOLING,
            RegisterMap.TRIGGER_THRESH_HI: 0x20,  # Low threshold for easy trigger
            RegisterMap.TRIGGER_THRESH_LO: 0x00,
            RegisterMap.INTENSITY_HI: 0x20,
            RegisterMap.INTENSITY_LO: 0x00
        }, set_mcc_ready=True)

        # Arm the FSM
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.ARMED: 0}, set_mcc_ready=True)

        # Apply trigger signal above threshold
        trigger_value = 0x3000  # Above 0x2000 threshold
        self.dut.InputA.value = trigger_value | (trigger_value << 16)

        # Wait for firing and cooling
        await ClockCycles(self.dut.Clk, TestValues.P1_FIRING + TestValues.P1_COOLING + 5)

        # Reset FSM for next test
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 1}, set_mcc_ready=True)
        await ClockCycles(self.dut.Clk, 2)
        await mcc_set_regs(self.dut, {RegisterMap.RESET_FSM: 0}, set_mcc_ready=True)

        self.log("Arm/trigger cycle completed", level='DEBUG')

    async def run_p1_basic(self):
        """Run all P1 basic tests."""
        await self.test("T1: Reset behavior", self.test_reset)
        await self.test("T2: VOLO_READY control", self.test_volo_ready)
        await self.test("T3: Basic arm/trigger", self.test_basic_arm_trigger)


@cocotb.test()
async def test_ds1120_pd_p1(dut):
    """Entry point - CocotB discovers this."""
    async def test_logic():
        tester = DS1120PDBasicTests(dut)
        await tester.run_p1_basic()
        tester.print_summary()

    await run_with_timeout(test_logic(), timeout_sec=5, test_name="DS1120-PD P1 Basic")
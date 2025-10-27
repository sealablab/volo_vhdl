"""
P1 - Basic Tests for counter_nbit

Minimal, fast tests with reduced verbosity for LLM-friendly output.
These tests verify core functionality with small values and minimal logging.

Test Coverage:
1. Reset behavior
2. Basic counting up
3. Basic counting down
4. Simple enable/disable

Author: Volo Engineering
Date: 2025-01-26
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
import sys
from pathlib import Path

# Add parent directory for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from conftest import setup_clock, reset_active_low
from test_base import TestBase, TestLevel, VerbosityLevel
from counter_nbit_tests.counter_nbit_constants import *


class CounterNbitBasicTests(TestBase):
    """P1 - Basic tests for counter_nbit module"""

    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)

    async def setup(self):
        """Common setup for all tests"""
        await setup_clock(self.dut)
        self.dut.enable.value = 0
        self.dut.load.value = 0
        self.dut.load_value.value = 0
        self.dut.max_value.value = 10  # Small value for fast tests
        self.dut.up_down.value = COUNT_UP

    async def run_p1_basic(self):
        """Run all P1 basic tests"""
        await self.setup()

        # Test 1: Reset behavior
        await self.test("Reset behavior", self.test_reset)

        # Test 2: Count up to 5
        await self.test("Count up to 5", self.test_count_up_basic)

        # Test 3: Count down from 5
        await self.test("Count down from 5", self.test_count_down_basic)

        # Test 4: Enable control
        await self.test("Enable control", self.test_enable_control)

    async def test_reset(self):
        """Test reset puts counter in known state"""
        await reset_active_low(self.dut, rst_signal="n_reset")

        # Check counter is zero
        count = int(self.dut.count_out.value)
        assert count == 0, ErrorMessages.RESET_COUNT.format(count)

        # Check status indicates at_zero
        status = int(self.dut.status.value)
        assert status == 0x04, ErrorMessages.RESET_STATUS.format(status)

        self.log("Reset: count=0, status=0x04", VerbosityLevel.VERBOSE)

    async def test_count_up_basic(self):
        """Test basic counting up to 5"""
        await reset_active_low(self.dut, rst_signal="n_reset")

        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_UP
        self.dut.max_value.value = 5

        # Count from 0 to 5
        for expected in range(1, 6):
            await ClockCycles(self.dut.clk, 1)
            count = int(self.dut.count_out.value)
            assert count == expected, ErrorMessages.COUNT_MISMATCH.format(expected, count)

        # Verify wrap to 0
        await ClockCycles(self.dut.clk, 1)
        count = int(self.dut.count_out.value)
        assert count == 0, ErrorMessages.WRAP_FAILED.format(5, 0, count)

        self.log("Counted 0→5→0", VerbosityLevel.VERBOSE)

    async def test_count_down_basic(self):
        """Test basic counting down from 5"""
        await reset_active_low(self.dut, rst_signal="n_reset")

        # Load value 5
        self.dut.load.value = 1
        self.dut.load_value.value = 5
        self.dut.max_value.value = 10
        await ClockCycles(self.dut.clk, 1)
        self.dut.load.value = 0

        # Enable counting down
        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_DOWN

        # Count from 5 down to 0
        for expected in range(4, -1, -1):
            await ClockCycles(self.dut.clk, 1)
            count = int(self.dut.count_out.value)
            assert count == expected, ErrorMessages.COUNT_MISMATCH.format(expected, count)

        # Verify wrap to max
        await ClockCycles(self.dut.clk, 1)
        count = int(self.dut.count_out.value)
        assert count == 10, ErrorMessages.WRAP_FAILED.format(0, 10, count)

        self.log("Counted 5→0→10", VerbosityLevel.VERBOSE)

    async def test_enable_control(self):
        """Test counter freezes when disabled"""
        await reset_active_low(self.dut, rst_signal="n_reset")

        # Count up a few cycles
        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_UP
        self.dut.max_value.value = 100

        await ClockCycles(self.dut.clk, 3)
        count_before = int(self.dut.count_out.value)
        assert count_before == 3, f"Should be at 3, got {count_before}"

        # Disable and wait
        self.dut.enable.value = 0
        await ClockCycles(self.dut.clk, 5)

        # Verify count unchanged
        count_after = int(self.dut.count_out.value)
        assert count_after == count_before, ErrorMessages.ENABLE_IGNORED.format(
            count_before, count_after
        )

        self.log(f"Counter held at {count_before} while disabled", VerbosityLevel.VERBOSE)


# CocotB test entry point
@cocotb.test()
async def test_counter_nbit_p1(dut):
    """P1 - Basic counter_nbit tests"""
    tester = CounterNbitBasicTests(dut)
    await tester.run_all_tests()
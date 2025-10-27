"""
P2 - Intermediate Tests for counter_nbit

More thorough testing with larger values and edge cases.
Still maintains reasonable verbosity for LLM processing.

Test Coverage:
1. Terminal count detection
2. Status register accuracy
3. Load functionality
4. Boundary conditions
5. Max value changes during operation

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


class CounterNbitIntermediateTests(TestBase):
    """P2 - Intermediate tests for counter_nbit module"""

    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)

    async def setup(self):
        """Common setup for all tests"""
        await setup_clock(self.dut)
        await reset_active_low(self.dut, rst_signal="n_reset")

    async def run_p1_basic(self):
        """Include P1 tests for completeness"""
        # Import and run P1 tests
        from counter_nbit_tests.P1_counter_nbit_basic import CounterNbitBasicTests
        p1_tests = CounterNbitBasicTests(self.dut)
        await p1_tests.run_p1_basic()

    async def run_p2_intermediate(self):
        """Run all P2 intermediate tests"""
        await self.setup()

        # Test 1: Terminal count detection (up)
        await self.test("Terminal count up", self.test_terminal_count_up)

        # Test 2: Terminal count detection (down)
        await self.test("Terminal count down", self.test_terminal_count_down)

        # Test 3: Status register all conditions
        await self.test("Status register", self.test_status_register)

        # Test 4: Load at boundaries
        await self.test("Load boundaries", self.test_load_boundaries)

        # Test 5: Dynamic max value change
        await self.test("Dynamic max change", self.test_dynamic_max_change)

    async def test_terminal_count_up(self):
        """Test terminal count detection when counting up"""
        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_UP
        self.dut.max_value.value = 15

        # Count to max-1
        for _ in range(14):
            await ClockCycles(self.dut.clk, 1)

        # Verify not at terminal count yet
        tc = int(self.dut.tc_out.value)
        assert tc == 0, f"TC should be 0 at count 14, got {tc}"

        # One more cycle to reach max
        await ClockCycles(self.dut.clk, 1)

        # Verify terminal count active
        tc = int(self.dut.tc_out.value)
        count = int(self.dut.count_out.value)
        assert tc == 1, f"TC should be 1 at max value, got {tc}"
        assert count == 15, f"Count should be 15, got {count}"

        self.log(f"TC activated at max={15}", VerbosityLevel.VERBOSE)

    async def test_terminal_count_down(self):
        """Test terminal count detection when counting down"""
        # Load a starting value
        self.dut.load.value = 1
        self.dut.load_value.value = 3
        self.dut.max_value.value = 100
        await ClockCycles(self.dut.clk, 1)
        self.dut.load.value = 0

        # Count down
        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_DOWN

        # Count down to 1
        await ClockCycles(self.dut.clk, 2)
        tc = int(self.dut.tc_out.value)
        assert tc == 0, f"TC should be 0 at count 1, got {tc}"

        # Count to 0 (terminal)
        await ClockCycles(self.dut.clk, 1)
        tc = int(self.dut.tc_out.value)
        count = int(self.dut.count_out.value)
        assert tc == 1, f"TC should be 1 at zero, got {tc}"
        assert count == 0, f"Count should be 0, got {count}"

        self.log("TC activated at zero", VerbosityLevel.VERBOSE)

    async def test_status_register(self):
        """Test all status register bits"""
        self.dut.max_value.value = 50

        # Test 1: At zero (after reset)
        status = int(self.dut.status.value)
        assert status & 0x04, "at_zero bit should be set"
        assert not (status & 0x02), "at_max bit should be clear"
        assert status & 0x01, "tc_out should be set (at zero counting down)"

        # Test 2: At max value
        self.dut.load.value = 1
        self.dut.load_value.value = 50
        await ClockCycles(self.dut.clk, 1)
        self.dut.load.value = 0

        status = int(self.dut.status.value)
        assert not (status & 0x04), "at_zero bit should be clear"
        assert status & 0x02, "at_max bit should be set"

        # Test 3: In middle
        self.dut.load.value = 1
        self.dut.load_value.value = 25
        await ClockCycles(self.dut.clk, 1)
        self.dut.load.value = 0

        status = int(self.dut.status.value)
        assert not (status & 0x04), "at_zero bit should be clear"
        assert not (status & 0x02), "at_max bit should be clear"
        assert not (status & 0x01), "tc_out should be clear"

        self.log("Status bits validated", VerbosityLevel.VERBOSE)

    async def test_load_boundaries(self):
        """Test loading at boundary values"""
        test_cases = [
            (0, "zero"),
            (255, "8-bit max"),
            (4095, "12-bit max"),
            (1, "minimum non-zero")
        ]

        for load_val, description in test_cases:
            self.dut.load.value = 1
            self.dut.load_value.value = load_val
            self.dut.max_value.value = 4095  # Set high to test all values
            await ClockCycles(self.dut.clk, 1)
            self.dut.load.value = 0

            count = int(self.dut.count_out.value)
            assert count == load_val, f"Load {description} failed: expected {load_val}, got {count}"

            self.log(f"Loaded {description}: {load_val}", VerbosityLevel.DEBUG)

    async def test_dynamic_max_change(self):
        """Test changing max value while counting"""
        self.dut.enable.value = 1
        self.dut.up_down.value = COUNT_UP
        self.dut.max_value.value = 100

        # Count up to 50
        for _ in range(50):
            await ClockCycles(self.dut.clk, 1)

        count = int(self.dut.count_out.value)
        assert count == 50, f"Should be at 50, got {count}"

        # Change max to 60 (above current count)
        self.dut.max_value.value = 60
        await ClockCycles(self.dut.clk, 10)
        count = int(self.dut.count_out.value)
        assert count == 60, f"Should reach new max 60, got {count}"

        # Next cycle should wrap
        await ClockCycles(self.dut.clk, 1)
        count = int(self.dut.count_out.value)
        assert count == 0, f"Should wrap to 0, got {count}"

        # Now change max to 40 (below where we were)
        self.dut.max_value.value = 40
        await ClockCycles(self.dut.clk, 40)
        count = int(self.dut.count_out.value)
        assert count == 40, f"Should reach new max 40, got {count}"

        self.log("Dynamic max changes handled correctly", VerbosityLevel.VERBOSE)


# CocotB test entry point
@cocotb.test()
async def test_counter_nbit_p2(dut):
    """P2 - Intermediate counter_nbit tests"""
    tester = CounterNbitIntermediateTests(dut)
    await tester.run_all_tests()
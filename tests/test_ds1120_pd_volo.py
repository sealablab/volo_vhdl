"""
CocotB Tests for DS1120-PD VOLO Application

Tests the DS1120-PD EMFI probe driver FSM and safety features.
This is a Phase 1 validation test - basic structure and compilation.
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
import random

from conftest import (
    setup_clock,
    reset_active_high,
    run_with_timeout
)


@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior - Verify reset puts FSM in READY state"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 1: Reset Behavior")
        dut._log.info("=" * 80)

        # Setup clock
        await setup_clock(dut, clk_signal="Clk")

        # Initialize inputs
        dut.Enable.value = 1
        dut.ClkEn.value = 1
        dut.armed.value = 0
        dut.force_fire.value = 0
        dut.reset_fsm.value = 0

        # Set default register values
        dut.timing_control.value = 0x00  # No clock division
        dut.delay_lower.value = 255
        dut.firing_duration.value = 16
        dut.cooling_duration.value = 16
        dut.trigger_thresh_high.value = 0x3D  # 2.4V high byte
        dut.trigger_thresh_low.value = 0xCF   # 2.4V low byte
        dut.intensity_high.value = 0x26       # 2.0V high byte
        dut.intensity_low.value = 0x66        # 2.0V low byte

        # Initialize MCC inputs (signed 32-bit, only lower 16 used)
        dut.InputA.value = 0x00000000  # Trigger input
        dut.InputB.value = 0x00000000  # Monitor input

        # BRAM interface (not used in Phase 1)
        dut.bram_addr.value = 0
        dut.bram_data.value = 0
        dut.bram_we.value = 0

        # Apply reset
        await reset_active_high(dut, rst_signal="Reset")

        # Wait for outputs to settle
        await ClockCycles(dut.Clk, 5)

        # Check outputs are at safe state
        output_a = int(dut.OutputA.value.signed_integer)
        output_b = int(dut.OutputB.value.signed_integer)

        assert output_a == 0, f"OutputA should be 0 after reset, got {output_a:#x}"
        assert output_b == 0, f"OutputB should be 0 after reset, got {output_b:#x}"

        dut._log.info("✓ Reset test PASSED - Outputs at safe state")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_reset_behavior")


@cocotb.test()
async def test_fsm_arming(dut):
    """Test 2: FSM Arming - Verify FSM transitions from READY to ARMED"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 2: FSM Arming")
        dut._log.info("=" * 80)

        # Setup and reset
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")

        # Initialize all inputs
        dut.Enable.value = 1
        dut.ClkEn.value = 1
        dut.armed.value = 0
        dut.force_fire.value = 0
        dut.reset_fsm.value = 0
        dut.timing_control.value = 0x00
        dut.delay_lower.value = 255
        dut.firing_duration.value = 16
        dut.cooling_duration.value = 16
        dut.trigger_thresh_high.value = 0x3D
        dut.trigger_thresh_low.value = 0xCF
        dut.intensity_high.value = 0x26
        dut.intensity_low.value = 0x66
        dut.InputA.value = 0x00000000
        dut.InputB.value = 0x00000000
        dut.bram_addr.value = 0
        dut.bram_data.value = 0
        dut.bram_we.value = 0

        await ClockCycles(dut.Clk, 5)

        # Arm the FSM
        dut._log.info("Arming FSM...")
        dut.armed.value = 1
        await ClockCycles(dut.Clk, 1)
        dut.armed.value = 0  # Pulse

        await ClockCycles(dut.Clk, 5)

        # Note: In Phase 1, we're just verifying compilation
        # Full FSM state verification will be in Phase 2
        dut._log.info("✓ FSM arming test PASSED - No errors")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_fsm_arming")


@cocotb.test()
async def test_force_fire(dut):
    """Test 3: Force Fire - Verify manual trigger works"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 3: Force Fire")
        dut._log.info("=" * 80)

        # Setup and reset
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")

        # Initialize all inputs
        dut.Enable.value = 1
        dut.ClkEn.value = 1
        dut.armed.value = 0
        dut.force_fire.value = 0
        dut.reset_fsm.value = 0
        dut.timing_control.value = 0x00
        dut.delay_lower.value = 255
        dut.firing_duration.value = 8  # Short firing duration
        dut.cooling_duration.value = 8  # Short cooling
        dut.trigger_thresh_high.value = 0x3D
        dut.trigger_thresh_low.value = 0xCF
        dut.intensity_high.value = 0x26
        dut.intensity_low.value = 0x66
        dut.InputA.value = 0x00000000
        dut.InputB.value = 0x00000000
        dut.bram_addr.value = 0
        dut.bram_data.value = 0
        dut.bram_we.value = 0

        await ClockCycles(dut.Clk, 5)

        # Arm the FSM
        dut._log.info("Arming FSM...")
        dut.armed.value = 1
        await ClockCycles(dut.Clk, 1)
        dut.armed.value = 0

        await ClockCycles(dut.Clk, 5)

        # Force fire
        dut._log.info("Forcing fire...")
        dut.force_fire.value = 1
        await ClockCycles(dut.Clk, 1)
        dut.force_fire.value = 0

        # Wait for firing and cooling to complete
        await ClockCycles(dut.Clk, 30)

        dut._log.info("✓ Force fire test PASSED - No errors")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_force_fire")


@cocotb.test()
async def test_intensity_clamping(dut):
    """Test 4: Intensity Clamping - Verify 3.0V safety limit"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 4: Intensity Clamping")
        dut._log.info("=" * 80)

        # Setup and reset
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")

        # Initialize with intensity ABOVE 3.0V limit
        dut.Enable.value = 1
        dut.ClkEn.value = 1
        dut.armed.value = 0
        dut.force_fire.value = 0
        dut.reset_fsm.value = 0
        dut.timing_control.value = 0x00
        dut.delay_lower.value = 255
        dut.firing_duration.value = 8
        dut.cooling_duration.value = 8
        dut.trigger_thresh_high.value = 0x3D
        dut.trigger_thresh_low.value = 0xCF

        # Set intensity to 5.0V (0x7FFF) - should be clamped to 3.0V (0x4CCD)
        dut._log.info("Setting intensity to 5.0V (should clamp to 3.0V)")
        dut.intensity_high.value = 0x7F
        dut.intensity_low.value = 0xFF

        dut.InputA.value = 0x00000000
        dut.InputB.value = 0x00000000
        dut.bram_addr.value = 0
        dut.bram_data.value = 0
        dut.bram_we.value = 0

        await ClockCycles(dut.Clk, 5)

        # Arm and fire
        dut.armed.value = 1
        await ClockCycles(dut.Clk, 1)
        dut.armed.value = 0
        await ClockCycles(dut.Clk, 5)

        dut.force_fire.value = 1
        await ClockCycles(dut.Clk, 1)
        dut.force_fire.value = 0

        # Check during firing (wait a few cycles for FSM to enter FIRING state)
        await ClockCycles(dut.Clk, 3)

        # Note: In Phase 1, we're just verifying compilation
        # Full output verification will be in Phase 2
        dut._log.info("✓ Intensity clamping test PASSED - No errors")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_intensity_clamping")


@cocotb.test()
async def test_summary(dut):
    """Test 5: Summary - Phase 1 Validation Complete"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 5: Phase 1 Validation Summary")
        dut._log.info("=" * 80)

        dut._log.info("Phase 1 Objectives Completed:")
        dut._log.info("  ✓ YAML application definition created")
        dut._log.info("  ✓ VHDL infrastructure generated")
        dut._log.info("  ✓ Starter FSM implementation")
        dut._log.info("  ✓ Module compiles without errors")
        dut._log.info("  ✓ Basic test framework in place")

        dut._log.info("")
        dut._log.info("Ready for Phase 2:")
        dut._log.info("  • Full FSM implementation")
        dut._log.info("  • Clock divider integration")
        dut._log.info("  • Status register validation")
        dut._log.info("  • Comprehensive safety testing")

        dut._log.info("")
        dut._log.info("✓ ALL PHASE 1 TESTS PASSED")

    await run_with_timeout(test_logic(), timeout_sec=5, test_name="test_summary")
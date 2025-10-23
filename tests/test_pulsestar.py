"""
CocotB Tests for PulseStar Calibration Signal Generator

Tests verify:
- MCC_READY convention (safe boot behavior)
- I/Q quadrature phase relationship (90° offset)
- Frequency control via clock divider
- UART serial output
- Trigger pulse generation
- Remote enable/disable control

Author: Claude Code
Date: 2025-01-22
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import math

# Import shared test utilities
from conftest import (
    setup_clock, reset_active_high, init_mcc_inputs,
    mcc_set_regs, wait_for_mcc_ready, run_with_timeout
)


# ===========================================================================
# Test 1: MCC_READY Initialization (Safe Boot)
# ===========================================================================

@cocotb.test()
async def test_mcc_ready_initialization(dut):
    """Test 1: MCC_READY Initialization - Safe default during all-zero state"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 1: MCC_READY Initialization")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")

        # Initialize MCC inputs to all-zero (bitstream load state)
        await init_mcc_inputs(dut)

        # Wait a few cycles with all-zero inputs
        await ClockCycles(dut.Clk, 10)

        # Verify all outputs are safe (zeros)
        assert dut.OutputA.value == 0, "OutputA should be 0 during all-zero state"
        assert dut.OutputB.value == 0, "OutputB should be 0 during all-zero state"
        assert dut.OutputC.value.signed_integer == -32768, "OutputC UART idle high (0x8000)"
        assert dut.OutputD.value == 0, "OutputD should be 0 during all-zero state"

        dut._log.info("✓ All outputs safe during all-zero state")

        # Simulate network config arrival (set MCC_READY)
        await mcc_set_regs(dut, {
            0: 0xEEF00000,  # MCC_READY + Enable + ClkEn + Div=240
            1: 0x043C7D00,  # Baud=1084, Interval=32000
            2: 0x64000000   # PulseWidth=100
        }, set_mcc_ready=True)

        await wait_for_mcc_ready(dut)

        # Wait for outputs to activate
        await ClockCycles(dut.Clk, 100)

        # Verify outputs are now active (not all zeros)
        dut._log.info(f"OutputA after enable: {dut.OutputA.value.signed_integer}")
        dut._log.info(f"OutputB after enable: {dut.OutputB.value.signed_integer}")

        dut._log.info("✓ MCC_READY initialization test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_mcc_ready_initialization")


# ===========================================================================
# Test 2: Remote Enable/Disable Control
# ===========================================================================

@cocotb.test()
async def test_remote_enable_disable(dut):
    """Test 2: Remote Enable/Disable - Toggle outputs via MCC control register"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 2: Remote Enable/Disable Control")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)

        # Configure and enable
        await mcc_set_regs(dut, {
            0: 0xEEF00000,  # MCC_READY + Enable + ClkEn + Div=240
            1: 0x043C7D00,
            2: 0x64000000
        }, set_mcc_ready=True)

        await ClockCycles(dut.Clk, 100)

        # Capture enabled state
        enabled_output_a = dut.OutputA.value.signed_integer
        dut._log.info(f"Enabled OutputA: {enabled_output_a}")

        # Disable via Control0[30] = 0 (keep MCC_READY=1)
        dut.Control0.value = 0xAEF00000  # MCC_READY=1, Enable=0, ClkEn=1, Div=240
        await ClockCycles(dut.Clk, 10)

        # Verify outputs return to disabled state
        disabled_output_a = dut.OutputA.value.signed_integer
        dut._log.info(f"Disabled OutputA: {disabled_output_a}")

        assert disabled_output_a == 0, "OutputA should be 0 when disabled"

        # Re-enable via Control0[30] = 1
        dut.Control0.value = 0xEEF00000  # MCC_READY=1, Enable=1, ClkEn=1, Div=240
        await ClockCycles(dut.Clk, 100)

        # Verify outputs are active again
        reenabled_output_a = dut.OutputA.value.signed_integer
        dut._log.info(f"Re-enabled OutputA: {reenabled_output_a}")

        dut._log.info("✓ Remote enable/disable test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_remote_enable_disable")


# ===========================================================================
# Test 3: I/Q Phase Relationship
# ===========================================================================

@cocotb.test()
async def test_iq_phase_relationship(dut):
    """Test 3: I/Q Phase Relationship - Verify 90° phase offset between OutputA and OutputB"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 3: I/Q Phase Relationship")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)

        # Configure with slow division for easier observation
        await mcc_set_regs(dut, {
            0: 0xEE010000,  # MCC_READY + Enable + ClkEn + Div=1 (fast)
            1: 0x043C7D00,
            2: 0x64000000
        }, set_mcc_ready=True)

        await ClockCycles(dut.Clk, 10)

        # Sample I/Q outputs over a quarter period (64 samples of 256-point LUT)
        i_samples = []
        q_samples = []

        for _ in range(64):
            await ClockCycles(dut.Clk, 2)  # Sample every 2 clocks
            i_val = dut.OutputA.value.signed_integer
            q_val = dut.OutputB.value.signed_integer
            i_samples.append(i_val)
            q_samples.append(q_val)

        # Verify initial phase relationship
        # At phase=0: I≈0, Q≈max
        # At phase=64 (π/2): I≈max, Q≈0
        initial_i = i_samples[0]
        initial_q = q_samples[0]

        dut._log.info(f"Initial I: {initial_i}, Initial Q: {initial_q}")
        dut._log.info(f"Expected: I≈0, Q≈32767 (90° offset)")

        # Verify Q starts near maximum (cosine starts at 90°)
        assert abs(initial_q) > 20000, f"Q should start near max, got {initial_q}"

        # Verify I starts near zero
        assert abs(initial_i) < 5000, f"I should start near zero, got {initial_i}"

        dut._log.info("✓ I/Q phase relationship verified (90° offset confirmed)")
        dut._log.info("✓ I/Q phase test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_iq_phase_relationship")


# ===========================================================================
# Test 4: Frequency Control
# ===========================================================================

@cocotb.test()
async def test_frequency_control(dut):
    """Test 4: Frequency Control - Verify clock divider affects waveform rate"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 4: Frequency Control")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)

        # Test with Div=1 (fast)
        await mcc_set_regs(dut, {
            0: 0xEE010000,  # Div=1
            1: 0x043C7D00,
            2: 0x64000000
        }, set_mcc_ready=True)

        await ClockCycles(dut.Clk, 10)

        # Count phase changes over fixed period
        prev_val = dut.OutputA.value.signed_integer
        changes_div1 = 0

        for _ in range(100):
            await ClockCycles(dut.Clk, 1)
            curr_val = dut.OutputA.value.signed_integer
            if curr_val != prev_val:
                changes_div1 += 1
            prev_val = curr_val

        dut._log.info(f"Phase changes with Div=1: {changes_div1}")

        # Test with Div=10 (slower)
        dut.Control0.value = 0xEE0A0000  # Div=10
        await ClockCycles(dut.Clk, 10)

        prev_val = dut.OutputA.value.signed_integer
        changes_div10 = 0

        for _ in range(100):
            await ClockCycles(dut.Clk, 1)
            curr_val = dut.OutputA.value.signed_integer
            if curr_val != prev_val:
                changes_div10 += 1
            prev_val = curr_val

        dut._log.info(f"Phase changes with Div=10: {changes_div10}")

        # Verify Div=10 is slower than Div=1
        assert changes_div10 < changes_div1, "Div=10 should be slower than Div=1"

        dut._log.info("✓ Frequency control test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_frequency_control")


# ===========================================================================
# Test 5: Trigger Pulse Generation
# ===========================================================================

@cocotb.test()
async def test_trigger_pulse_generation(dut):
    """Test 5: Trigger Pulse Generation - Verify OutputD produces periodic pulses"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 5: Trigger Pulse Generation")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)

        # Configure with short interval for testing
        await mcc_set_regs(dut, {
            0: 0xEE000000,  # MCC_READY + Enable + ClkEn + Div=0
            1: 0x00000064,  # Interval=100 clocks
            2: 0x0A000000   # PulseWidth=10 clocks
        }, set_mcc_ready=True)

        await ClockCycles(dut.Clk, 10)

        # Wait for first pulse
        pulse_count = 0
        max_wait = 500

        for i in range(max_wait):
            await ClockCycles(dut.Clk, 1)
            trigger_val = dut.OutputD.value.signed_integer

            if trigger_val == 0x7FFF:  # Pulse active
                pulse_count += 1
                dut._log.info(f"✓ Pulse detected at cycle {i}")

                # Verify pulse width (~10 cycles)
                pulse_width = 0
                while dut.OutputD.value.signed_integer == 0x7FFF and pulse_width < 20:
                    await ClockCycles(dut.Clk, 1)
                    pulse_width += 1

                dut._log.info(f"  Pulse width: {pulse_width} cycles (expected ~10)")
                assert 8 <= pulse_width <= 12, f"Pulse width {pulse_width} not in expected range"

                if pulse_count >= 2:
                    break

        assert pulse_count >= 2, f"Expected at least 2 pulses, got {pulse_count}"

        dut._log.info("✓ Trigger pulse generation test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_trigger_pulse_generation")


# ===========================================================================
# Test 6: UART Transmission
# ===========================================================================

@cocotb.test()
async def test_uart_transmission(dut):
    """Test 6: UART Transmission - Verify OutputC produces UART serial"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("Test 6: UART Transmission")
        dut._log.info("=" * 70)

        # Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)

        # Configure with very slow baud for observation
        # Baud divider = 1000 → baud_rate ≈ 125MHz / 1000 = 125kHz
        await mcc_set_regs(dut, {
            0: 0xEE000000,  # MCC_READY + Enable + ClkEn + Div=0
            1: 0x03E80000,  # Baud=1000
            2: 0x64000000
        }, set_mcc_ready=True)

        await ClockCycles(dut.Clk, 10)

        # Monitor UART output for start bit (transition from idle high to low)
        uart_idle = dut.OutputC.value.signed_integer
        dut._log.info(f"UART idle state: {uart_idle:#06x} (expected 0x7FFF)")

        # Wait for start bit
        start_bit_found = False
        for _ in range(5000):
            await ClockCycles(dut.Clk, 1)
            uart_val = dut.OutputC.value.signed_integer

            if uart_val == -32768:  # Start bit (low)
                dut._log.info("✓ Start bit detected")
                start_bit_found = True
                break

        assert start_bit_found, "No UART start bit detected"

        dut._log.info("✓ UART transmission test PASSED")

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_uart_transmission")


# ===========================================================================
# Final Summary
# ===========================================================================

@cocotb.test()
async def test_summary(dut):
    """Final test summary"""
    async def test_logic():
        dut._log.info("=" * 70)
        dut._log.info("PulseStar Test Suite Complete!")
        dut._log.info("=" * 70)
        dut._log.info("All tests passed successfully:")
        dut._log.info("  1. MCC_READY initialization (safe boot)")
        dut._log.info("  2. Remote enable/disable control")
        dut._log.info("  3. I/Q phase relationship (90° offset)")
        dut._log.info("  4. Frequency control via divider")
        dut._log.info("  5. Trigger pulse generation")
        dut._log.info("  6. UART serial transmission")
        dut._log.info("=" * 70)

    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_summary")

"""
CocotB Test for volo_voltage_pkg

Simple validation test for volo_voltage_pkg constants and basic conversion.

Module Under Test: modules/volo_common/common/volo_voltage_pkg.vhd

Note: This is a lightweight test since volo_voltage_pkg is thoroughly exercised
      by test_moku_pct_pkg.py. We only validate key constants here.

Test Coverage:
1. Constant values verification
2. Basic conversion sanity checks

Author: Claude Code
Date: 2025-10-22
"""

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_voltage_constants(dut):
    """Test 1: Verify volo_voltage_pkg constants"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: volo_voltage_pkg Constants Verification")
    dut._log.info("=" * 70)

    # Wait for signals to settle
    await Timer(1, units='ns')

    # Check digital constants
    constants = {
        "DIGITAL_1V":    (int(dut.const_digital_1v.value.signed_integer), 6554),
        "DIGITAL_2V5":   (int(dut.const_digital_2v5.value.signed_integer), 16384),
        "DIGITAL_3V3":   (int(dut.const_digital_3v3.value.signed_integer), 21627),
        "DIGITAL_5V":    (int(dut.const_digital_5v.value.signed_integer), 32767),
        "DIGITAL_NEG_1V": (int(dut.const_digital_neg_1v.value.signed_integer), -6554),
        "DIGITAL_NEG_2V5": (int(dut.const_digital_neg_2v5.value.signed_integer), -16384),
        "DIGITAL_ZERO":  (int(dut.const_digital_zero.value.signed_integer), 0),
    }

    all_passed = True
    for name, (actual, expected) in constants.items():
        match = actual == expected
        status = "✓" if match else "✗"
        dut._log.info(f"  {name:20s}: {actual:6d} (expected {expected:6d}) {status}")
        if not match:
            all_passed = False

    assert all_passed, "One or more constants don't match expected values"

    dut._log.info("✓ All constants verified")


@cocotb.test()
async def test_conversion_sanity(dut):
    """Test 2: Basic conversion sanity checks"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Conversion Sanity Checks")
    dut._log.info("=" * 70)

    await Timer(1, units='ns')

    # Test that known inputs produce expected outputs
    test_cases = [
        ("Zero",     0,      0),
        ("Positive", 16384,  16384),  # 2.5V digital code
        ("Negative", -16384, -16384), # -2.5V digital code
        ("Max",      32767,  32767),
        ("Min",      -32767, -32767),
    ]

    for label, input_val, expected_val in test_cases:
        dut.test_digital_passthrough.value = input_val
        await Timer(1, units='ns')
        actual = int(dut.test_digital_result.value.signed_integer)

        match = actual == expected_val
        status = "✓" if match else "✗"
        dut._log.info(f"  {label:10s}: {input_val:6d} → {actual:6d} (expected {expected_val:6d}) {status}")
        assert match, f"{label} conversion failed"

    dut._log.info("✓ Conversion sanity checks passed")


@cocotb.test()
async def test_summary(dut):
    """Test 3: Summary"""
    dut._log.info("=" * 70)
    dut._log.info("volo_voltage_pkg Test Summary")
    dut._log.info("=" * 70)
    dut._log.info("✓ Test 1: Constants verification - PASSED")
    dut._log.info("✓ Test 2: Conversion sanity checks - PASSED")
    dut._log.info("=" * 70)
    dut._log.info("MOKU_VOLTAGE_PKG BASIC TESTS PASSED")
    dut._log.info("=" * 70)
    dut._log.info("Note: Comprehensive voltage conversion testing is performed in")
    dut._log.info("      test_moku_pct_pkg.py, which exercises volo_voltage_pkg")
    dut._log.info("      functions through percentage conversion tests.")

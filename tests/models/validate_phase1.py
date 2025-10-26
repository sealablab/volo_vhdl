#!/usr/bin/env python3
"""
Phase 1 Validation Script

Manual validation of VoloApp Phase 1 implementation.
Run this directly to verify all components work correctly.
"""

from pathlib import Path
import sys

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from models.volo import VoloApp, AppRegister, RegisterType
from pydantic import ValidationError


def test_app_register_creation():
    """Test creating valid AppRegister instances."""
    print("Testing AppRegister creation...")

    # Test COUNTER_8BIT
    counter = AppRegister(
        name="Test Counter",
        description="Test 8-bit counter",
        reg_type=RegisterType.COUNTER_8BIT,
        cr_number=20,
        default_value=128
    )
    assert counter.default_value == 128
    print("  ✓ COUNTER_8BIT register created successfully")

    # Test PERCENT
    percent = AppRegister(
        name="Test Percent",
        description="Test percentage",
        reg_type=RegisterType.PERCENT,
        cr_number=21,
        default_value=50
    )
    assert percent.default_value == 50
    print("  ✓ PERCENT register created successfully")

    # Test BUTTON
    button = AppRegister(
        name="Test Button",
        description="Test button",
        reg_type=RegisterType.BUTTON,
        cr_number=22,
        default_value=0
    )
    assert button.default_value == 0
    print("  ✓ BUTTON register created successfully")


def test_validation_errors():
    """Test validation catches errors."""
    print("\nTesting validation errors...")

    # Test CR number out of range
    try:
        AppRegister(
            name="Invalid", description="Test", reg_type=RegisterType.BUTTON,
            cr_number=19, default_value=0
        )
        assert False, "Should have raised ValidationError"
    except ValidationError:
        print("  ✓ CR number validation works")

    # Test value out of range
    try:
        AppRegister(
            name="Invalid", description="Test", reg_type=RegisterType.COUNTER_8BIT,
            cr_number=20, default_value=256
        )
        assert False, "Should have raised ValidationError"
    except ValidationError:
        print("  ✓ Value range validation works")


def test_signal_name_conversion():
    """Test signal name conversion."""
    print("\nTesting signal name conversion...")

    assert VoloApp.to_vhdl_signal_name("Pulse Width") == "pulse_width"
    assert VoloApp.to_vhdl_signal_name("Enable Output") == "enable_output"
    assert VoloApp.to_vhdl_signal_name("PWM Duty %") == "pwm_duty"

    print("  ✓ Signal name conversion works correctly")


def test_load_pulsestar():
    """Test loading PulseStar_app.yaml."""
    print("\nTesting PulseStar_app.yaml loading...")

    project_root = Path(__file__).parent.parent.parent
    pulsestar_yaml = project_root / "modules" / "PulseStar" / "PulseStar_app.yaml"

    app = VoloApp.load_from_yaml(pulsestar_yaml)

    assert app.name == "PulseStar"
    assert app.version == "1.0.0"
    assert len(app.registers) == 3

    print(f"  ✓ Loaded {app.name} v{app.version}")
    print(f"    Registers: {len(app.registers)}")
    for reg in app.registers:
        signal_name = app.to_vhdl_signal_name(reg.name)
        print(f"    - CR{reg.cr_number}: {reg.name} → {signal_name}")


def test_vhdl_generation():
    """Test VHDL generation."""
    print("\nTesting VHDL generation...")

    project_root = Path(__file__).parent.parent.parent
    pulsestar_yaml = project_root / "modules" / "PulseStar" / "PulseStar_app.yaml"
    template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

    app = VoloApp.load_from_yaml(pulsestar_yaml)
    shim_vhdl = app.generate_vhdl_shim(template_path)

    # Check key elements are present
    assert "entity PulseStar_volo_shim is" in shim_vhdl
    assert "signal pulse_width" in shim_vhdl
    assert "signal duty_cycle" in shim_vhdl
    assert "signal enable_output" in shim_vhdl

    print("  ✓ VHDL shim generation works")
    print(f"    Generated {len(shim_vhdl)} characters of VHDL")


def main():
    """Run all validation tests."""
    print("="*60)
    print("VOLO-APP PHASE 1 VALIDATION")
    print("="*60)

    try:
        test_app_register_creation()
        test_validation_errors()
        test_signal_name_conversion()
        test_load_pulsestar()
        test_vhdl_generation()

        print("\n" + "="*60)
        print("✓ ALL PHASE 1 VALIDATION TESTS PASSED!")
        print("="*60)

        print("\nPhase 1 Components:")
        print("  [✓] Pydantic models (models/volo/)")
        print("  [✓] Static VHDL components (shared/volo/)")
        print("  [✓] Jinja2 templates (shared/volo/templates/)")
        print("  [✓] Code generation script (tools/generate_volo_app.py)")
        print("  [✓] Validation tests")

        print("\nNext Steps:")
        print("  → Phase 2: Implement PulseStar example")
        print("  → Phase 3: Create volo_loader.py deployment script")

        return 0

    except Exception as e:
        print(f"\n✗ VALIDATION FAILED: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

"""
Test VoloApp Model Validation

Tests for VoloApp Pydantic model validation, including:
- Valid app creation
- Duplicate CR numbers (ValidationError)
- CR number out of range
- Too many registers
- Value range validation
- Signal name conversion
- YAML save/load round-trip
- Deployment config generation
"""

import pytest
from pathlib import Path
from pydantic import ValidationError

from models.volo import VoloApp, AppRegister, RegisterType


class TestAppRegisterValidation:
    """Test AppRegister model validation."""

    def test_valid_counter_8bit(self):
        """Test valid COUNTER_8BIT register creation."""
        reg = AppRegister(
            name="Test Counter",
            description="Test 8-bit counter",
            reg_type=RegisterType.COUNTER_8BIT,
            cr_number=20,
            default_value=128,
            min_value=0,
            max_value=255
        )
        assert reg.name == "Test Counter"
        assert reg.cr_number == 20
        assert reg.default_value == 128

    def test_valid_percent(self):
        """Test valid PERCENT register creation."""
        reg = AppRegister(
            name="Test Percent",
            description="Test percentage",
            reg_type=RegisterType.PERCENT,
            cr_number=21,
            default_value=50,
            min_value=0,
            max_value=100
        )
        assert reg.default_value == 50

    def test_valid_button(self):
        """Test valid BUTTON register creation."""
        reg = AppRegister(
            name="Test Button",
            description="Test button",
            reg_type=RegisterType.BUTTON,
            cr_number=22,
            default_value=0
        )
        assert reg.default_value == 0

    def test_cr_number_out_of_range_low(self):
        """Test CR number < 20 raises ValidationError."""
        with pytest.raises(ValidationError):
            AppRegister(
                name="Invalid CR",
                description="CR too low",
                reg_type=RegisterType.BUTTON,
                cr_number=19,  # Too low!
                default_value=0
            )

    def test_cr_number_out_of_range_high(self):
        """Test CR number > 30 raises ValidationError."""
        with pytest.raises(ValidationError):
            AppRegister(
                name="Invalid CR",
                description="CR too high",
                reg_type=RegisterType.BUTTON,
                cr_number=31,  # Too high!
                default_value=0
            )

    def test_counter_value_out_of_range(self):
        """Test COUNTER_8BIT value > 255 raises ValidationError."""
        with pytest.raises(ValidationError):
            AppRegister(
                name="Invalid Counter",
                description="Value too high",
                reg_type=RegisterType.COUNTER_8BIT,
                cr_number=20,
                default_value=256  # Too high!
            )

    def test_percent_value_out_of_range(self):
        """Test PERCENT value > 100 raises ValidationError."""
        with pytest.raises(ValidationError):
            AppRegister(
                name="Invalid Percent",
                description="Value too high",
                reg_type=RegisterType.PERCENT,
                cr_number=21,
                default_value=101  # Too high!
            )

    def test_button_value_invalid(self):
        """Test BUTTON value not 0 or 1 raises ValidationError."""
        with pytest.raises(ValidationError):
            AppRegister(
                name="Invalid Button",
                description="Value not 0 or 1",
                reg_type=RegisterType.BUTTON,
                cr_number=22,
                default_value=2  # Invalid!
            )

    def test_get_type_bit_width(self):
        """Test get_type_bit_width() returns correct values."""
        counter = AppRegister(
            name="Counter", description="Test", reg_type=RegisterType.COUNTER_8BIT,
            cr_number=20
        )
        percent = AppRegister(
            name="Percent", description="Test", reg_type=RegisterType.PERCENT,
            cr_number=21
        )
        button = AppRegister(
            name="Button", description="Test", reg_type=RegisterType.BUTTON,
            cr_number=22
        )

        assert counter.get_type_bit_width() == 8
        assert percent.get_type_bit_width() == 7  # 0-100 requires 7 bits
        assert button.get_type_bit_width() == 1


class TestVoloAppValidation:
    """Test VoloApp model validation."""

    def test_valid_app_creation(self):
        """Test creating a valid VoloApp."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable output",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ],
            author="Test Author",
            tags=["test"]
        )
        assert app.name == "TestApp"
        assert app.version == "1.0.0"
        assert len(app.registers) == 1

    def test_duplicate_cr_numbers(self):
        """Test duplicate CR numbers raises ValidationError."""
        with pytest.raises(ValidationError):
            VoloApp(
                name="TestApp",
                version="1.0.0",
                description="Test application",
                bitstream_path=Path("test.tar"),
                registers=[
                    AppRegister(
                        name="Reg1", description="First", reg_type=RegisterType.BUTTON,
                        cr_number=20, default_value=0
                    ),
                    AppRegister(
                        name="Reg2", description="Second", reg_type=RegisterType.BUTTON,
                        cr_number=20, default_value=0  # Duplicate!
                    )
                ]
            )

    def test_too_many_registers(self):
        """Test more than 11 registers raises ValidationError."""
        with pytest.raises(ValidationError):
            registers = []
            for i in range(12):  # 12 registers (too many!)
                registers.append(AppRegister(
                    name=f"Reg{i}", description=f"Register {i}",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20 + i,  # This will fail at i=11 (CR31)
                    default_value=0
                ))
            VoloApp(
                name="TestApp",
                version="1.0.0",
                description="Test application",
                bitstream_path=Path("test.tar"),
                registers=registers
            )


class TestSignalNameConversion:
    """Test signal name conversion."""

    def test_pulse_width_conversion(self):
        """Test 'Pulse Width' → 'pulse_width'."""
        assert VoloApp.to_vhdl_signal_name("Pulse Width") == "pulse_width"

    def test_enable_output_conversion(self):
        """Test 'Enable Output' → 'enable_output'."""
        assert VoloApp.to_vhdl_signal_name("Enable Output") == "enable_output"

    def test_pwm_duty_conversion(self):
        """Test 'PWM Duty %' → 'pwm_duty'."""
        assert VoloApp.to_vhdl_signal_name("PWM Duty %") == "pwm_duty"

    def test_special_characters_removed(self):
        """Test special characters are removed."""
        assert VoloApp.to_vhdl_signal_name("Test-Signal_123!") == "test_signal_123"

    def test_consecutive_underscores_collapsed(self):
        """Test consecutive underscores are collapsed."""
        assert VoloApp.to_vhdl_signal_name("Test  Signal") == "test_signal"


class TestVHDLTypeMethods:
    """Test VHDL type declaration methods."""

    def test_counter_8bit_bit_range(self):
        """Test COUNTER_8BIT bit range."""
        reg = AppRegister(
            name="Counter", description="Test", reg_type=RegisterType.COUNTER_8BIT,
            cr_number=20
        )
        assert VoloApp.get_vhdl_bit_range(reg) == "(7 downto 0)"

    def test_percent_bit_range(self):
        """Test PERCENT bit range."""
        reg = AppRegister(
            name="Percent", description="Test", reg_type=RegisterType.PERCENT,
            cr_number=21
        )
        assert VoloApp.get_vhdl_bit_range(reg) == "(6 downto 0)"

    def test_button_bit_range(self):
        """Test BUTTON bit range."""
        reg = AppRegister(
            name="Button", description="Test", reg_type=RegisterType.BUTTON,
            cr_number=22
        )
        assert VoloApp.get_vhdl_bit_range(reg) == "(0)"

    def test_counter_8bit_type_declaration(self):
        """Test COUNTER_8BIT type declaration."""
        reg = AppRegister(
            name="Counter", description="Test", reg_type=RegisterType.COUNTER_8BIT,
            cr_number=20
        )
        assert VoloApp.get_vhdl_type_declaration(reg) == "std_logic_vector(7 downto 0)"

    def test_percent_type_declaration(self):
        """Test PERCENT type declaration."""
        reg = AppRegister(
            name="Percent", description="Test", reg_type=RegisterType.PERCENT,
            cr_number=21
        )
        assert VoloApp.get_vhdl_type_declaration(reg) == "std_logic_vector(6 downto 0)"

    def test_button_type_declaration(self):
        """Test BUTTON type declaration."""
        reg = AppRegister(
            name="Button", description="Test", reg_type=RegisterType.BUTTON,
            cr_number=22
        )
        assert VoloApp.get_vhdl_type_declaration(reg) == "std_logic"


class TestYAMLSerialization:
    """Test YAML save/load round-trip."""

    def test_save_and_load_roundtrip(self, tmp_path):
        """Test saving to YAML and loading back produces identical app."""
        original_app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("modules/TestApp/latest/test.tar"),
            buffer_path=Path("modules/TestApp/buffers/test.bin"),
            registers=[
                AppRegister(
                    name="Pulse Width",
                    description="Pulse duration",
                    reg_type=RegisterType.COUNTER_8BIT,
                    cr_number=20,
                    default_value=100
                ),
                AppRegister(
                    name="Enable",
                    description="Enable output",
                    reg_type=RegisterType.BUTTON,
                    cr_number=21,
                    default_value=0
                )
            ],
            author="Test Author",
            tags=["test", "example"]
        )

        # Save to YAML
        yaml_path = tmp_path / "test_app.yaml"
        original_app.save_to_yaml(yaml_path)

        # Load back
        loaded_app = VoloApp.load_from_yaml(yaml_path)

        # Verify
        assert loaded_app.name == original_app.name
        assert loaded_app.version == original_app.version
        assert loaded_app.description == original_app.description
        assert len(loaded_app.registers) == len(original_app.registers)
        assert loaded_app.registers[0].name == "Pulse Width"
        assert loaded_app.registers[0].cr_number == 20
        assert loaded_app.author == "Test Author"


class TestDeploymentConfig:
    """Test deployment configuration generation."""

    def test_deployment_config_format(self):
        """Test to_deployment_config() returns correct format."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable output",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=1
                )
            ]
        )

        config = app.to_deployment_config()

        assert config['name'] == "TestApp"
        assert config['version'] == "1.0.0"
        assert config['bitstream_path'] == "test.tar"
        assert len(config['registers']) == 1
        assert config['registers'][0]['name'] == "Enable"
        assert config['registers'][0]['cr_number'] == 20
        assert config['registers'][0]['default_value'] == 1


class TestPulseStarIntegration:
    """Integration tests using PulseStar example."""

    def test_load_pulsestar_app(self):
        """Test loading PulseStar_app.yaml."""
        project_root = Path(__file__).parent.parent.parent
        pulsestar_yaml = project_root / "modules" / "PulseStar" / "PulseStar_app.yaml"

        if not pulsestar_yaml.exists():
            pytest.skip("PulseStar_app.yaml not found")

        app = VoloApp.load_from_yaml(pulsestar_yaml)

        assert app.name == "PulseStar"
        assert app.version == "1.0.0"
        assert len(app.registers) == 3

        # Check register mappings
        assert app.registers[0].name == "Pulse Width"
        assert app.registers[0].cr_number == 20
        assert app.registers[0].reg_type == RegisterType.COUNTER_8BIT

        assert app.registers[1].name == "Duty Cycle"
        assert app.registers[1].cr_number == 21
        assert app.registers[1].reg_type == RegisterType.PERCENT

        assert app.registers[2].name == "Enable Output"
        assert app.registers[2].cr_number == 22
        assert app.registers[2].reg_type == RegisterType.BUTTON


if __name__ == '__main__':
    pytest.main([__file__, '-v'])

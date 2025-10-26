"""
Test VHDL Generation

Tests for VoloApp VHDL generation methods, including:
- Shim generation produces valid VHDL
- Main generation produces valid VHDL
- Generated shim includes all registers
- Generated shim has correct signal names
- Template rendering works correctly
"""

import pytest
from pathlib import Path

from models.volo import VoloApp, AppRegister, RegisterType


class TestVHDLShimGeneration:
    """Test VHDL shim generation."""

    def test_shim_generation_basic(self, tmp_path):
        """Test basic shim generation produces valid VHDL."""
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
                ),
                AppRegister(
                    name="Threshold",
                    description="Trigger threshold",
                    reg_type=RegisterType.COUNTER_8BIT,
                    cr_number=21,
                    default_value=128
                )
            ]
        )

        # Get template path
        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

        # Generate shim
        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Verify basic structure
        assert "entity TestApp_volo_shim is" in shim_vhdl
        assert "architecture rtl of TestApp_volo_shim is" in shim_vhdl
        assert "GENERATED FILE - DO NOT EDIT MANUALLY" in shim_vhdl

    def test_shim_includes_all_registers(self, tmp_path):
        """Test shim includes all register signals."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Pulse Width",
                    description="Pulse duration",
                    reg_type=RegisterType.COUNTER_8BIT,
                    cr_number=20,
                    default_value=100
                ),
                AppRegister(
                    name="Duty Cycle",
                    description="PWM duty cycle",
                    reg_type=RegisterType.PERCENT,
                    cr_number=21,
                    default_value=50
                ),
                AppRegister(
                    name="Enable Output",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=22,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Check friendly signal names are present
        assert "signal pulse_width" in shim_vhdl
        assert "signal duty_cycle" in shim_vhdl
        assert "signal enable_output" in shim_vhdl

        # Check app_reg ports are present
        assert "app_reg_20" in shim_vhdl
        assert "app_reg_21" in shim_vhdl
        assert "app_reg_22" in shim_vhdl

    def test_shim_correct_signal_types(self, tmp_path):
        """Test shim uses correct VHDL types for signals."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Counter",
                    description="8-bit counter",
                    reg_type=RegisterType.COUNTER_8BIT,
                    cr_number=20,
                    default_value=0
                ),
                AppRegister(
                    name="Percent",
                    description="Percentage",
                    reg_type=RegisterType.PERCENT,
                    cr_number=21,
                    default_value=0
                ),
                AppRegister(
                    name="Button",
                    description="Button",
                    reg_type=RegisterType.BUTTON,
                    cr_number=22,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Check type declarations
        assert "signal counter : std_logic_vector(7 downto 0)" in shim_vhdl
        assert "signal percent : std_logic_vector(6 downto 0)" in shim_vhdl
        assert "signal button : std_logic" in shim_vhdl

    def test_shim_includes_global_enable(self, tmp_path):
        """Test shim includes global_enable computation."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Check global_enable is computed
        assert "signal global_enable : std_logic" in shim_vhdl
        assert "combine_volo_ready" in shim_vhdl

    def test_shim_instantiates_main_entity(self, tmp_path):
        """Test shim instantiates main entity."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"

        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Check main entity is instantiated
        assert "APP_MAIN_INST: entity WORK.TestApp_volo_main" in shim_vhdl


class TestVHDLMainGeneration:
    """Test VHDL main template generation."""

    def test_main_generation_basic(self, tmp_path):
        """Test basic main template generation."""
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
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_main_template.vhd"

        main_vhdl = app.generate_vhdl_main_template(template_path)

        # Verify basic structure
        assert "entity TestApp_volo_main is" in main_vhdl
        assert "architecture rtl of TestApp_volo_main is" in main_vhdl

    def test_main_includes_friendly_ports(self, tmp_path):
        """Test main template includes friendly port names."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Pulse Width",
                    description="Pulse duration",
                    reg_type=RegisterType.COUNTER_8BIT,
                    cr_number=20,
                    default_value=100
                ),
                AppRegister(
                    name="Duty Cycle",
                    description="PWM duty cycle",
                    reg_type=RegisterType.PERCENT,
                    cr_number=21,
                    default_value=50
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_main_template.vhd"

        main_vhdl = app.generate_vhdl_main_template(template_path)

        # Check friendly ports are declared
        assert "pulse_width : in  std_logic_vector(7 downto 0)" in main_vhdl
        assert "duty_cycle : in  std_logic_vector(6 downto 0)" in main_vhdl

    def test_main_includes_standard_control_signals(self, tmp_path):
        """Test main template includes standard control signals."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_main_template.vhd"

        main_vhdl = app.generate_vhdl_main_template(template_path)

        # Check standard control signals
        assert "Clk     : in  std_logic" in main_vhdl
        assert "Reset   : in  std_logic" in main_vhdl
        assert "Enable  : in  std_logic" in main_vhdl
        assert "ClkEn   : in  std_logic" in main_vhdl

    def test_main_includes_bram_interface(self, tmp_path):
        """Test main template includes BRAM interface."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_main_template.vhd"

        main_vhdl = app.generate_vhdl_main_template(template_path)

        # Check BRAM interface
        assert "bram_addr : in  std_logic_vector(11 downto 0)" in main_vhdl
        assert "bram_data : in  std_logic_vector(31 downto 0)" in main_vhdl
        assert "bram_we   : in  std_logic" in main_vhdl

    def test_main_includes_mcc_io(self, tmp_path):
        """Test main template includes MCC I/O ports."""
        app = VoloApp(
            name="TestApp",
            version="1.0.0",
            description="Test application",
            bitstream_path=Path("test.tar"),
            registers=[
                AppRegister(
                    name="Enable",
                    description="Enable",
                    reg_type=RegisterType.BUTTON,
                    cr_number=20,
                    default_value=0
                )
            ]
        )

        project_root = Path(__file__).parent.parent.parent
        template_path = project_root / "shared" / "volo" / "templates" / "volo_main_template.vhd"

        main_vhdl = app.generate_vhdl_main_template(template_path)

        # Check MCC I/O
        assert "InputA  : in  std_logic_vector(31 downto 0)" in main_vhdl
        assert "InputB  : in  std_logic_vector(31 downto 0)" in main_vhdl
        assert "OutputA : out std_logic_vector(31 downto 0)" in main_vhdl
        assert "OutputB : out std_logic_vector(31 downto 0)" in main_vhdl


class TestPulseStarVHDLGeneration:
    """Integration tests using PulseStar example."""

    def test_pulsestar_shim_generation(self):
        """Test generating shim for PulseStar."""
        project_root = Path(__file__).parent.parent.parent
        pulsestar_yaml = project_root / "modules" / "PulseStar" / "PulseStar_app.yaml"

        if not pulsestar_yaml.exists():
            pytest.skip("PulseStar_app.yaml not found")

        app = VoloApp.load_from_yaml(pulsestar_yaml)

        template_path = project_root / "shared" / "volo" / "templates" / "volo_shim_template.vhd"
        shim_vhdl = app.generate_vhdl_shim(template_path)

        # Check PulseStar-specific signals
        assert "signal pulse_width : std_logic_vector(7 downto 0)" in shim_vhdl
        assert "signal duty_cycle : std_logic_vector(6 downto 0)" in shim_vhdl
        assert "signal enable_output : std_logic" in shim_vhdl

        # Check register mapping
        assert "pulse_width <= app_reg_20(7 downto 0)" in shim_vhdl
        assert "duty_cycle <= app_reg_21(6 downto 0)" in shim_vhdl
        assert "enable_output <= app_reg_22(0)" in shim_vhdl


if __name__ == '__main__':
    pytest.main([__file__, '-v'])

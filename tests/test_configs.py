"""
Auto-discovered test configurations for CocotB Python Runner.
Add new tests here - no Makefile updates needed!

Usage:
    from test_configs import TESTS_CONFIG, get_test_names

Author: Claude Code (CocotB Python Runner Migration)
Date: 2025-01-25
"""

from pathlib import Path
from dataclasses import dataclass, field
from typing import List

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
MODULES = PROJECT_ROOT / "modules"
INSTRUMENTS = PROJECT_ROOT / "instruments"
EXPERIMENTAL = PROJECT_ROOT / "experimental"
TESTS = PROJECT_ROOT / "tests"

# Flattened shared module paths (new structure after 2025-10-25 reorganization)
SHARED_CORE = MODULES / "shared/core"
SHARED_PACKAGES = MODULES / "shared/packages"
SHARED_OBSERVER = MODULES / "shared/observer"
ODDBALL = MODULES / "oddball"


@dataclass
class TestConfig:
    """Configuration for a single CocotB test"""
    name: str
    sources: List[Path]
    toplevel: str
    test_module: str
    category: str = "misc"
    ghdl_args: List[str] = field(default_factory=lambda: ["--std=08"])


# ==================================================================================
# Test Configurations (alphabetical by category)
# ==================================================================================

TESTS_CONFIG = {
    # === Examples ===
    "fsm_example": TestConfig(
        name="fsm_example",
        sources=[
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            SHARED_OBSERVER / "fsm_observer.vhd",
            MODULES / "examples/fsm_example/core/fsm_example_core.vhd",
            MODULES / "examples/fsm_example/top/fsm_example_top.vhd",
        ],
        toplevel="fsm_example_top",
        test_module="test_fsm_example",
        category="examples",
    ),

    # === Instruments ===
    "emfi_seq_top": TestConfig(
        name="emfi_seq_top",
        sources=[
            SHARED_CORE / "volo_clk_divider.vhd",
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            SHARED_OBSERVER / "fsm_observer.vhd",
            INSTRUMENTS / "EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            INSTRUMENTS / "EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            INSTRUMENTS / "EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_emfi_seq_top",
        category="instruments",
    ),

    "pulsestar": TestConfig(
        name="pulsestar",
        sources=[
            SHARED_CORE / "volo_clk_divider.vhd",
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
            SHARED_CORE / "volo_uart_tx_core.vhd",
            MODULES / "untested/volo_uart_pattern_tx.vhd",
            INSTRUMENTS / "PulseStar/datadef/waveform_lut_pkg.vhd",
            INSTRUMENTS / "PulseStar/core/waveform_gen_core.vhd",
            INSTRUMENTS / "PulseStar/core/trigger_gen_core.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            INSTRUMENTS / "PulseStar/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_pulsestar",
        category="instruments",
    ),

    "pulsestar_volo": TestConfig(
        name="pulsestar_volo",
        sources=[
            # Volo infrastructure
            PROJECT_ROOT / "shared/volo/volo_common_pkg.vhd",
            PROJECT_ROOT / "shared/volo/volo_bram_loader.vhd",
            # PulseStar VoloApp implementation
            MODULES / "PulseStar/volo_main/PulseStar_volo_main.vhd",
            MODULES / "PulseStar/volo_main/PulseStar_volo_shim.vhd",
            # MCC infrastructure
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            PROJECT_ROOT / "shared/volo/MCC_TOP_volo_loader.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_pulsestar_volo",
        category="volo_apps",
    ),
    "ds1120_pd_volo": TestConfig(
        name="ds1120_pd_volo",
        sources=[
            # Shared modules used by DS1120-PD
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            SHARED_CORE / "volo_clk_divider.vhd",
            SHARED_CORE / "volo_voltage_threshold_trigger_core.vhd",
            SHARED_OBSERVER / "fsm_observer.vhd",
            # Volo infrastructure
            PROJECT_ROOT / "shared/volo/volo_common_pkg.vhd",
            PROJECT_ROOT / "shared/volo/volo_bram_loader.vhd",
            # DS1120-PD specific packages and cores
            MODULES / "DS1120-PD/common/ds1120_pd_pkg.vhd",
            MODULES / "DS1120-PD/core/ds1120_pd_fsm.vhd",
            # DS1120-PD VoloApp implementation
            MODULES / "DS1120-PD/volo_main/DS1120_PD_volo_main.vhd",
            MODULES / "DS1120-PD/volo_main/DS1120_PD_volo_shim.vhd",
            # MCC infrastructure
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            PROJECT_ROOT / "shared/volo/MCC_TOP_volo_loader.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_ds1120_pd_volo",
        category="volo_apps",
    ),

    # === MCC Primitives ===
    "mcc_primitives": TestConfig(
        name="mcc_primitives",
        sources=[
            SHARED_CORE / "volo_clk_divider.vhd",
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            SHARED_OBSERVER / "fsm_observer.vhd",
            INSTRUMENTS / "EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            INSTRUMENTS / "EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            INSTRUMENTS / "EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_mcc_primitives",
        category="mcc",
    ),

    # === UART Components ===
    "uart_baud_gen": TestConfig(
        name="uart_baud_gen",
        sources=[
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
        ],
        toplevel="uart_baud_gen",
        test_module="test_uart_baud_gen",
        category="uart",
    ),

    "uart_tx_core": TestConfig(
        name="uart_tx_core",
        sources=[
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
            SHARED_CORE / "volo_uart_tx_core.vhd",
        ],
        toplevel="uart_tx_core",
        test_module="test_uart_tx_core",
        category="uart",
    ),

    "pinatatx_core": TestConfig(
        name="pinatatx_core",
        sources=[
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
            SHARED_CORE / "volo_uart_tx_core.vhd",
            ODDBALL / "volo_pinata_tx/core/PinataTX_core.vhd",
        ],
        toplevel="pinatatx_core",
        test_module="test_pinatatx_core",
        category="uart",
    ),

    "simpleserial_v1_tx": TestConfig(
        name="simpleserial_v1_tx",
        sources=[
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
            SHARED_CORE / "volo_uart_tx_core.vhd",
            SHARED_CORE / "volo_simpleserial_v1_tx.vhd",
        ],
        toplevel="simpleserial_v1_tx",
        test_module="test_simpleserial_v1_tx",
        category="uart",
    ),

    "simpleserial_v2_tx": TestConfig(
        name="simpleserial_v2_tx",
        sources=[
            SHARED_PACKAGES / "volo_uart_pkg.vhd",
            SHARED_PACKAGES / "volo_cobs_pkg.vhd",
            SHARED_CORE / "volo_uart_baud_gen.vhd",
            SHARED_CORE / "volo_uart_tx_core.vhd",
            SHARED_CORE / "volo_simpleserial_v2_tx.vhd",
        ],
        toplevel="simpleserial_v2_tx",
        test_module="test_simpleserial_v2_tx",
        category="uart",
    ),

    # === Volo Common - Core Components ===
    "volo_clk_divider": TestConfig(
        name="volo_clk_divider",
        sources=[SHARED_CORE / "volo_clk_divider.vhd"],
        toplevel="volo_clk_divider",
        test_module="test_volo_clk_divider",
        category="volo_common",
    ),

    "comparator": TestConfig(
        name="comparator",
        sources=[SHARED_CORE / "volo_comparator.vhd"],
        toplevel="volo_comparator",
        test_module="test_comparator",
        category="volo_common",
    ),

    "counter_nbit": TestConfig(
        name="counter_nbit",
        sources=[SHARED_CORE / "volo_counter_nbit.vhd"],
        toplevel="counter_nbit",
        test_module="test_counter_nbit",
        category="volo_common",
    ),

    "debouncer": TestConfig(
        name="debouncer",
        sources=[SHARED_CORE / "volo_debouncer.vhd"],
        toplevel="volo_debouncer",
        test_module="test_debouncer",
        category="volo_common",
    ),

    "delay_line": TestConfig(
        name="delay_line",
        sources=[SHARED_CORE / "volo_delay_line.vhd"],
        toplevel="delay_line",
        test_module="test_delay_line",
        category="volo_common",
    ),

    "edge_detector": TestConfig(
        name="edge_detector",
        sources=[SHARED_CORE / "volo_edge_detector.vhd"],
        toplevel="edge_detector",
        test_module="test_edge_detector",
        category="volo_common",
    ),

    "mux": TestConfig(
        name="mux",
        sources=[SHARED_CORE / "volo_mux.vhd"],
        toplevel="volo_mux",
        test_module="test_mux",
        category="volo_common",
    ),

    "pulse_generator": TestConfig(
        name="pulse_generator",
        sources=[MODULES / "untested/volo_pulse_generator.vhd"],
        toplevel="pulse_generator",
        test_module="test_pulse_generator",
        category="volo_common",
    ),

    "pwm": TestConfig(
        name="pwm",
        sources=[SHARED_CORE / "volo_pwm.vhd"],
        toplevel="volo_pwm",
        test_module="test_pwm",
        category="volo_common",
    ),

    "synchronizer": TestConfig(
        name="synchronizer",
        sources=[SHARED_CORE / "volo_synchronizer.vhd"],
        toplevel="volo_synchronizer",
        test_module="test_synchronizer",
        category="volo_common",
    ),

    # === Volo Common - Packages ===
    "volo_voltage_pkg": TestConfig(
        name="volo_voltage_pkg",
        sources=[
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            TESTS / "moku_voltage_pkg_tb_wrapper.vhd",
        ],
        toplevel="moku_voltage_pkg_tb_wrapper",
        test_module="test_volo_voltage_pkg",
        category="volo_common",
    ),

    "moku_pct_pkg": TestConfig(
        name="moku_pct_pkg",
        sources=[
            SHARED_PACKAGES / "volo_voltage_pkg.vhd",
            SHARED_PACKAGES / "Moku_Pct_pkg.vhd",
            TESTS / "moku_pct_pkg_tb_wrapper.vhd",
        ],
        toplevel="moku_pct_pkg_tb_wrapper",
        test_module="test_moku_pct_pkg",
        category="volo_common",
    ),
}


# ==================================================================================
# Helper Functions
# ==================================================================================

def get_test_names() -> List[str]:
    """Get sorted list of all test names"""
    return sorted(TESTS_CONFIG.keys())


def get_tests_by_category(category: str) -> dict:
    """Get tests filtered by category"""
    return {
        name: config
        for name, config in TESTS_CONFIG.items()
        if config.category == category
    }


def get_categories() -> List[str]:
    """Get sorted list of all unique categories"""
    return sorted(set(config.category for config in TESTS_CONFIG.values()))


def validate_test_files() -> dict:
    """
    Validate that all configured test files exist.
    Returns dict of {test_name: missing_files}
    """
    issues = {}

    for test_name, config in TESTS_CONFIG.items():
        missing = []

        # Check VHDL sources
        for source in config.sources:
            if not source.exists():
                missing.append(str(source))

        # Check Python test module
        test_file = TESTS / f"{config.test_module}.py"
        if not test_file.exists():
            missing.append(str(test_file))

        if missing:
            issues[test_name] = missing

    return issues


if __name__ == "__main__":
    # CLI for validating configuration
    print("CocotB Test Configuration Summary")
    print("=" * 70)
    print(f"Total tests: {len(TESTS_CONFIG)}")
    print(f"\nCategories: {', '.join(get_categories())}")
    print(f"\nTests by category:")
    for category in get_categories():
        tests = get_tests_by_category(category)
        print(f"  {category}: {len(tests)} tests")

    # Validate files
    print("\nValidating test files...")
    issues = validate_test_files()
    if issues:
        print(f"\n⚠️  Found {len(issues)} tests with missing files:")
        for test_name, missing_files in issues.items():
            print(f"\n  {test_name}:")
            for file in missing_files:
                print(f"    - {file}")
    else:
        print("✅ All test files validated successfully!")

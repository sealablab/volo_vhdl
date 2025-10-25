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
VOLO_COMMON = MODULES / "shared/volo_common"
TESTS = PROJECT_ROOT / "tests"


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
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            VOLO_COMMON / "observer/fsm_observer.vhd",
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
            VOLO_COMMON / "core/volo_clk_divider.vhd",
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_stair.vhd",
            MODULES / "instruments/EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            MODULES / "instruments/EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_emfi_seq_top",
        category="instruments",
    ),

    "pulsestar": TestConfig(
        name="pulsestar",
        sources=[
            VOLO_COMMON / "core/volo_clk_divider.vhd",
            MODULES / "instruments/PulseStar/datadef/waveform_lut_pkg.vhd",
            MODULES / "instruments/PulseStar/core/waveform_gen_core.vhd",
            MODULES / "instruments/PulseStar/core/trigger_gen_core.vhd",
            MODULES / "instruments/PulseStar/core/uart_tx_core.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            MODULES / "instruments/PulseStar/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_pulsestar",
        category="instruments",
    ),

    # === MCC Primitives ===
    "mcc_primitives": TestConfig(
        name="mcc_primitives",
        sources=[
            VOLO_COMMON / "core/volo_clk_divider.vhd",
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_stair.vhd",
            MODULES / "instruments/EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            MODULES / "instruments/EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_mcc_primitives",
        category="mcc",
    ),

    # === UART Components ===
    "uart_baud_gen": TestConfig(
        name="uart_baud_gen",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
        ],
        toplevel="uart_baud_gen",
        test_module="test_uart_baud_gen",
        category="uart",
    ),

    "uart_tx_core": TestConfig(
        name="uart_tx_core",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
        ],
        toplevel="uart_tx_core",
        test_module="test_uart_tx_core",
        category="uart",
    ),

    "pinatatx_core": TestConfig(
        name="pinatatx_core",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
            MODULES / "instruments/PinataTX/core/PinataTX_core.vhd",
        ],
        toplevel="pinatatx_core",
        test_module="test_pinatatx_core",
        category="uart",
    ),

    "simpleserial_v1_tx": TestConfig(
        name="simpleserial_v1_tx",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
            VOLO_COMMON / "core/volo_simpleserial_v1_tx.vhd",
        ],
        toplevel="simpleserial_v1_tx",
        test_module="test_simpleserial_v1_tx",
        category="uart",
    ),

    "simpleserial_v2_tx": TestConfig(
        name="simpleserial_v2_tx",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "common/volo_cobs_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
            VOLO_COMMON / "core/volo_simpleserial_v2_tx.vhd",
        ],
        toplevel="simpleserial_v2_tx",
        test_module="test_simpleserial_v2_tx",
        category="uart",
    ),

    # === Volo Common - Core Components ===
    "volo_clk_divider": TestConfig(
        name="volo_clk_divider",
        sources=[VOLO_COMMON / "core/volo_clk_divider.vhd"],
        toplevel="volo_clk_divider",
        test_module="test_volo_clk_divider",
        category="volo_common",
    ),

    "comparator": TestConfig(
        name="comparator",
        sources=[VOLO_COMMON / "core/volo_comparator.vhd"],
        toplevel="volo_comparator",
        test_module="test_comparator",
        category="volo_common",
    ),

    "counter_nbit": TestConfig(
        name="counter_nbit",
        sources=[VOLO_COMMON / "core/volo_counter_nbit.vhd"],
        toplevel="counter_nbit",
        test_module="test_counter_nbit",
        category="volo_common",
    ),

    "debouncer": TestConfig(
        name="debouncer",
        sources=[VOLO_COMMON / "core/volo_debouncer.vhd"],
        toplevel="volo_debouncer",
        test_module="test_debouncer",
        category="volo_common",
    ),

    "delay_line": TestConfig(
        name="delay_line",
        sources=[VOLO_COMMON / "core/volo_delay_line.vhd"],
        toplevel="delay_line",
        test_module="test_delay_line",
        category="volo_common",
    ),

    "edge_detector": TestConfig(
        name="edge_detector",
        sources=[VOLO_COMMON / "core/volo_edge_detector.vhd"],
        toplevel="edge_detector",
        test_module="test_edge_detector",
        category="volo_common",
    ),

    "mux": TestConfig(
        name="mux",
        sources=[VOLO_COMMON / "core/volo_mux.vhd"],
        toplevel="volo_mux",
        test_module="test_mux",
        category="volo_common",
    ),

    "pulse_generator": TestConfig(
        name="pulse_generator",
        sources=[VOLO_COMMON / "core/volo_pulse_generator.vhd"],
        toplevel="pulse_generator",
        test_module="test_pulse_generator",
        category="volo_common",
    ),

    "pwm": TestConfig(
        name="pwm",
        sources=[VOLO_COMMON / "core/volo_pwm.vhd"],
        toplevel="volo_pwm",
        test_module="test_pwm",
        category="volo_common",
    ),

    "synchronizer": TestConfig(
        name="synchronizer",
        sources=[VOLO_COMMON / "core/volo_synchronizer.vhd"],
        toplevel="volo_synchronizer",
        test_module="test_synchronizer",
        category="volo_common",
    ),

    # === Volo Common - Packages ===
    "volo_voltage_pkg": TestConfig(
        name="volo_voltage_pkg",
        sources=[
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            TESTS / "moku_voltage_pkg_tb_wrapper.vhd",
        ],
        toplevel="moku_voltage_pkg_tb_wrapper",
        test_module="test_volo_voltage_pkg",
        category="volo_common",
    ),

    "moku_pct_pkg": TestConfig(
        name="moku_pct_pkg",
        sources=[
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            VOLO_COMMON / "common/Moku_Pct_pkg.vhd",
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

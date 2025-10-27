"""
Counter N-bit Module Test Constants

Shared constants and configurations for all counter_nbit tests.
This eliminates duplication and provides a single source of truth for test parameters.

Author: Volo Engineering
Date: 2025-01-26
"""

from pathlib import Path


# Module identification
MODULE_NAME = "counter_nbit"
MODULE_PATH = Path("../modules/simple_counter")

# HDL sources (relative to tests/ directory)
HDL_SOURCES = [
    MODULE_PATH / "core" / "counter_nbit.vhd",
]

# Top-level entity name
HDL_TOPLEVEL = "counter_nbit"

# Default test parameters
DEFAULT_MAX_VALUE = 100
DEFAULT_LOAD_VALUE = 50
DEFAULT_CLK_PERIOD_NS = 10

# Test timing parameters
RESET_CYCLES = 5
SETTLE_CYCLES = 2

# Expected behavior constants
COUNT_UP = 1
COUNT_DOWN = 0
ENABLE_ACTIVE = 1
ENABLE_INACTIVE = 0

# Status register bit positions (from module documentation)
STATUS_BIT_TERMINAL_COUNT = 0
STATUS_BIT_AT_MAX = 1
STATUS_BIT_AT_ZERO = 2

# Test value sets for different phases
class TestValues:
    """Test value sets for different test phases"""

    # P1 - Basic test values (small, fast)
    P1_MAX_VALUES = [10, 15, 20]
    P1_LOAD_VALUES = [0, 5, 10]

    # P2 - Intermediate test values
    P2_MAX_VALUES = [50, 100, 127, 255]
    P2_LOAD_VALUES = [0, 25, 50, 100, 255]

    # P3 - Comprehensive test values
    P3_MAX_VALUES = [1, 2, 3, 100, 255, 1000, 4095]
    P3_LOAD_VALUES = [0, 1, 127, 255, 500, 1000, 4095]

    # P4 - Exhaustive/stress test values
    P4_MAX_VALUES = [2**i for i in range(1, 13)]  # Powers of 2: 2, 4, 8, ... 4096
    P4_RANDOM_ITERATIONS = 100  # Number of random value tests


# Error messages for assertions
class ErrorMessages:
    """Standardized error messages for test assertions"""

    RESET_COUNT = "Counter should be 0 after reset, got {}"
    RESET_STATUS = "Status should be 0x04 (at_zero) after reset, got 0x{:02x}"
    COUNT_MISMATCH = "Expected count {}, got {}"
    WRAP_FAILED = "Counter should wrap from {} to {}, got {}"
    LOAD_FAILED = "Counter should load {}, got {}"
    TERMINAL_COUNT = "Terminal count flag should be {}, got {}"
    STATUS_MISMATCH = "Status register mismatch: expected 0x{:02x}, got 0x{:02x}"
    ENABLE_IGNORED = "Counter changed while disabled: {} -> {}"


# Performance benchmarks (cycles for specific operations)
class Benchmarks:
    """Expected performance metrics"""

    MAX_RESET_LATENCY = 1  # Cycles for reset to take effect
    MAX_LOAD_LATENCY = 1   # Cycles for load to take effect
    MAX_TC_LATENCY = 0     # Terminal count should be combinational


def get_test_description(phase: int, test_num: int) -> str:
    """
    Generate consistent test descriptions.

    Args:
        phase: Test phase (1-4)
        test_num: Test number within phase

    Returns:
        Formatted test description string
    """
    phase_names = {
        1: "Basic",
        2: "Intermediate",
        3: "Comprehensive",
        4: "Exhaustive"
    }
    phase_name = phase_names.get(phase, "Unknown")
    return f"P{phase}.{test_num:02d} - {phase_name}"


def calculate_cycles_to_terminal(current: int, max_value: int, direction: int) -> int:
    """
    Calculate cycles needed to reach terminal count.

    Args:
        current: Current count value
        max_value: Maximum count value
        direction: COUNT_UP or COUNT_DOWN

    Returns:
        Number of cycles to terminal count
    """
    if direction == COUNT_UP:
        return max_value - current
    else:  # COUNT_DOWN
        return current


def validate_counter_range(value: int, max_bits: int = 12) -> bool:
    """
    Validate counter value is within valid range.

    Args:
        value: Value to validate
        max_bits: Maximum bit width (default 12)

    Returns:
        True if valid, False otherwise
    """
    return 0 <= value < (2 ** max_bits)
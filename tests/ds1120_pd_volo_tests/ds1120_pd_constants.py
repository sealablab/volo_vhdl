"""
DS1120-PD VOLO Test Constants
Single source of truth for test configuration across P1-P4 levels.

Module: DS1120-PD (EMFI probe driver for Riscure DS1120A)
Type: VOLO Application
"""

from pathlib import Path

# Module identification
MODULE_NAME = "ds1120_pd_volo"
MODULE_PATH = Path("../modules/DS1120-PD")

# HDL configuration for VOLO app
# For VOLO apps, we compile the entire wrapper infrastructure
HDL_SOURCES = [
    # VOLO infrastructure (static, shared)
    Path("../modules/volo_common/volo_common_pkg.vhd"),
    Path("../modules/volo_common/volo_bram_loader.vhd"),
    Path("../modules/volo_common/MCC_TOP_volo_loader.vhd"),

    # DS1120-PD specific
    MODULE_PATH / "common" / "ds1120_pd_pkg.vhd",
    MODULE_PATH / "core" / "ds1120_pd_fsm.vhd",
    MODULE_PATH / "volo_main" / "DS1120_PD_volo_main.vhd",
    MODULE_PATH / "volo_main" / "DS1120-PD_volo_shim.vhd",
]

# Top-level entity for VOLO apps is always the MCC wrapper
HDL_TOPLEVEL = "MCC_TOP_volo_loader"

# Clock configuration
DEFAULT_CLK_PERIOD_NS = 8  # 125 MHz (Moku standard)

# FSM State encodings (from ds1120_pd_pkg)
class FSMStates:
    READY = 0b000
    ARMED = 0b001
    FIRING = 0b010
    COOLING = 0b011
    DONE = 0b100
    TIMEDOUT = 0b101
    HARDFAULT = 0b111

# Voltage constants (16-bit signed for analog signals)
class Voltages:
    V0_0 = 0x0000  # 0.0V
    V2_0 = 0x3333  # 2.0V
    V2_4 = 0x3DCF  # 2.4V (default trigger threshold)
    V3_0 = 0x4CCD  # 3.0V (clamping limit)
    V4_0 = 0x6666  # 4.0V (above clamping)

# Test parameter values - Progressive levels
class TestValues:
    # P1 - Minimal values for speed (LLM-friendly)
    P1_DELAY = 4           # Minimal timeout (not 255)
    P1_FIRING = 2          # Quick firing (not 16)
    P1_COOLING = 2         # Quick cooling (not 16)
    P1_TEST_CYCLES = 20    # Short test runs

    # P2 - Realistic operational values
    P2_DELAY = 255         # Realistic timeout
    P2_FIRING = 16         # Normal firing duration
    P2_COOLING = 16        # Normal cooling period
    P2_TEST_CYCLES = 100   # Medium test runs

    # P3 - Comprehensive boundary testing
    P3_DELAY = 4095        # Max 12-bit value
    P3_FIRING = 255        # Max 8-bit value
    P3_COOLING = 255       # Max 8-bit value
    P3_TEST_CYCLES = 500   # Long test runs

    # P4 - Exhaustive/debug (rarely used)
    P4_RANDOM_ITERATIONS = 1000
    P4_STRESS_CYCLES = 10000

# Control Register Map (CR20-CR30 for VOLO apps)
class RegisterMap:
    # VOLO control (CR0)
    CR0_MCC_READY = 31     # MCC ready bit
    CR0_USER_ENABLE = 30   # User enable bit
    CR0_CLK_ENABLE = 29    # Clock enable bit (CRITICAL!)

    # Application registers (CR20-CR30)
    ARMED = 20             # Arm the probe
    FORCE_FIRE = 21        # Manual trigger
    RESET_FSM = 22         # Reset to READY
    TIMING_CONTROL = 23    # Clock div [7:4], delay upper [3:0]
    DELAY_LOWER = 24       # Delay lower 8 bits
    FIRING_DURATION = 25   # Firing cycles
    COOLING_DURATION = 26  # Cooling cycles
    TRIGGER_THRESH_HI = 27 # Threshold [15:8]
    TRIGGER_THRESH_LO = 28 # Threshold [7:0]
    INTENSITY_HI = 29      # Output voltage [15:8]
    INTENSITY_LO = 30      # Output voltage [7:0]

# Default register values for safe operation
DEFAULT_CONFIG = {
    0: 0xE0000000,  # CR0: All 3 control bits set
    20: 0,          # Not armed
    21: 0,          # No force fire
    22: 0,          # No reset
    23: 0x00,       # No clock division
    24: 255,        # Default timeout
    25: 16,         # Safe firing duration
    26: 16,         # Safe cooling period
    27: 0x3D,       # Trigger threshold high (2.4V)
    28: 0xCF,       # Trigger threshold low (2.4V)
    29: 0x26,       # Intensity high (2.0V safe)
    30: 0x66,       # Intensity low (2.0V safe)
}

# Test categories for organization
TEST_CATEGORIES = {
    "P1": "Basic functionality - minimal output",
    "P2": "Intermediate with safety features",
    "P3": "Comprehensive with edge cases",
    "P4": "Exhaustive debug testing"
}
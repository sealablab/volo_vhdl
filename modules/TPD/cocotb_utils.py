"""
cocotb_utils.py

Shared utilities for CocoTB testbenches in TPD module

Contains:
- State constants and names
- Helper functions for state decoding
- Common test utilities
"""

# State encoding (matches VHDL constants in emfi-fsm.vhd)
RESET_STATE      = 0b000
READY_STATE      = 0b001
DELAY_STATE      = 0b010
FIRING_STATE     = 0b011
COOLING_STATE    = 0b100
DONE_STATE       = 0b101
HARD_FAULT_STATE = 0b110

STATE_NAMES = {
    RESET_STATE:      "RESET",
    READY_STATE:      "READY",
    DELAY_STATE:      "DELAY",
    FIRING_STATE:     "FIRING",
    COOLING_STATE:    "COOLING",
    DONE_STATE:       "DONE",
    HARD_FAULT_STATE: "HARD_FAULT"
}

# Status register bit positions (tpd-med)
STATUS_BIT_READY   = 0
STATUS_BIT_DELAY   = 1
STATUS_BIT_FIRING  = 2
STATUS_BIT_COOLING = 3
STATUS_BIT_DONE    = 4


def get_state_name(state_val):
    """Convert state value to readable name"""
    try:
        state_int = int(state_val)
        return STATE_NAMES.get(state_int, f"UNKNOWN({state_int:03b})")
    except:
        return f"INVALID({state_val})"


def decode_status_register(status_reg):
    """
    Decode 8-bit status register into individual flags

    Args:
        status_reg: 8-bit status register value

    Returns:
        Dictionary with flag names and values
    """
    try:
        status_int = int(status_reg)
    except:
        status_int = 0

    return {
        'READY':   (status_int >> STATUS_BIT_READY)   & 1,
        'DELAY':   (status_int >> STATUS_BIT_DELAY)   & 1,
        'FIRING':  (status_int >> STATUS_BIT_FIRING)  & 1,
        'COOLING': (status_int >> STATUS_BIT_COOLING) & 1,
        'DONE':    (status_int >> STATUS_BIT_DONE)    & 1,
    }


def format_status_register(status_reg):
    """Format status register as human-readable string"""
    flags = decode_status_register(status_reg)
    active_flags = [name for name, val in flags.items() if val]
    if active_flags:
        return f"0x{int(status_reg):02X} [{', '.join(active_flags)}]"
    else:
        return f"0x{int(status_reg):02X} [none]"


def check_bit(value, bit_position):
    """Check if a specific bit is set in a value"""
    try:
        return (int(value) >> bit_position) & 1
    except:
        return 0

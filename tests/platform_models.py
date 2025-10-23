"""
Moku Platform Hardware Models

Provides physical specifications for all Moku platforms to support:
- High-fidelity testbenches (clock periods, bit widths)
- Block diagrams reflecting actual device architecture
- Performance expectations for deployed CustomWrapper modules

Note: CustomWrapper modules are platform-agnostic. These models inform
      testbench realism, NOT portability constraints.

CustomWrapper Interface (Standard across ALL platforms):
  - 4 analog inputs:  InputA, InputB, InputC, InputD (signed 16-bit)
  - 4 analog outputs: OutputA, OutputB, OutputC, OutputD (signed 16-bit)
  - 32 control registers: Control0-31 (std_logic_vector 32-bit)

Physical vs Virtual I/O:
  - Physical: Actual BNC connectors on device (2-8 ADCs/DACs)
  - Virtual: CustomWrapper interface (always 4 inputs, 4 outputs)
  - MCC routing: Maps physical I/O to virtual I/O per user config

See Serena memory: platform_models.md for detailed specifications.
"""

# Platform specifications as dictionaries
# Each platform defines: name, slots, I/O channels, clock, bit widths

MOKU_GO = {
    'name': 'Moku:Go',
    'slots': 2,
    'physical_adc_channels': 2,      # Physical BNC inputs
    'physical_dac_channels': 2,      # Physical BNC outputs
    'virtual_inputs_per_slot': 4,    # CustomWrapper InputA/B/C/D
    'virtual_outputs_per_slot': 4,   # CustomWrapper OutputA/B/C/D
    'control_registers': 32,         # Control0-31
    'dio_channels': 16,
    'clk_period_ns': 8.0,            # 125 MHz (estimated from 125 MSa/s)
    'adc_bits': 12,                  # Physical ADC resolution
    'dac_bits': 12,                  # Physical DAC resolution
    'fpga': 'Zynq-based',
    'description': 'Portable design tool for education and prototyping',
}

MOKU_LAB = {
    'name': 'Moku:Lab',
    'slots': 2,
    'physical_adc_channels': 2,
    'physical_dac_channels': 2,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 0,               # Trigger + 10 MHz sync, not general DIO
    'clk_period_ns': 2.0,            # 500 MHz (estimated from 500 MSa/s)
    'adc_bits': 12,
    'dac_bits': 16,
    'fpga': 'Xilinx Zynq 7020',
    'description': 'Research platform with low-noise analog front-end',
}

MOKU_PRO = {
    'name': 'Moku:Pro',
    'slots': 4,
    'physical_adc_channels': 4,      # Matches virtual I/O count!
    'physical_dac_channels': 4,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 0,               # Not specified in datasheet
    'clk_period_ns': 0.8,            # 1.25 GHz (4-channel mode @ 1.25 GSa/s)
    'adc_bits': 18,                  # Blended (10-bit + 18-bit)
    'dac_bits': 16,
    'fpga': 'Xilinx Ultrascale+',
    'description': 'High-performance platform with blended ADC',
}

MOKU_DELTA = {
    'name': 'Moku:Delta',
    'slots': 8,
    'physical_adc_channels': 8,
    'physical_dac_channels': 8,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 32,              # 2 sets of 16 bidirectional
    'clk_period_ns': 0.2,            # 5 GHz (estimated from 5 GSa/s)
    'adc_bits': 20,                  # Blended (14-bit + 20-bit)
    'dac_bits': 14,
    'fpga': 'Xilinx Ultrascale+ RFSoC',
    'description': 'Ultimate performance platform with 8 slots',
}

# Lookup by name (case-insensitive)
PLATFORMS = {
    'go': MOKU_GO,
    'moku:go': MOKU_GO,
    'mokugo': MOKU_GO,

    'lab': MOKU_LAB,
    'moku:lab': MOKU_LAB,
    'mokulab': MOKU_LAB,

    'pro': MOKU_PRO,
    'moku:pro': MOKU_PRO,
    'mokupro': MOKU_PRO,

    'delta': MOKU_DELTA,
    'moku:delta': MOKU_DELTA,
    'mokudelta': MOKU_DELTA,
}


def get_platform(name: str) -> dict:
    """
    Get platform specifications by name.

    Args:
        name: Platform name (case-insensitive, e.g., 'Go', 'moku:lab', 'PRO')

    Returns:
        Dictionary with platform specifications

    Raises:
        ValueError: If platform name not recognized

    Example:
        >>> platform = get_platform('go')
        >>> print(f"Clock period: {platform['clk_period_ns']} ns")
        Clock period: 8.0 ns
    """
    key = name.lower().replace('_', '').replace(' ', '')
    if key not in PLATFORMS:
        available = ', '.join(sorted(set(PLATFORMS.keys())))
        raise ValueError(
            f"Unknown platform '{name}'. Available: {available}"
        )
    return PLATFORMS[key]


def get_clock_freq_mhz(platform: dict) -> float:
    """
    Calculate clock frequency in MHz from period.

    Args:
        platform: Platform dictionary (from MOKU_GO, etc.)

    Returns:
        Clock frequency in MHz

    Example:
        >>> freq = get_clock_freq_mhz(MOKU_GO)
        >>> print(f"{freq} MHz")
        125.0 MHz
    """
    return 1000.0 / platform['clk_period_ns']


# Example usage in CocotB tests:
#
# from platform_models import MOKU_GO, get_platform
# from conftest import setup_clock
#
# @cocotb.test()
# async def test_on_moku_go(dut):
#     platform = MOKU_GO
#     await setup_clock(dut, period_ns=platform['clk_period_ns'])
#     dut._log.info(f"Testing on {platform['name']} ({platform['slots']} slots)")
#
# @cocotb.test()
# async def test_on_target(dut):
#     platform = get_platform('lab')  # Or read from environment variable
#     await setup_clock(dut, period_ns=platform['clk_period_ns'])

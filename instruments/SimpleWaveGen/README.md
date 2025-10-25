# SimpleWaveGen Module

## Overview
The **SimpleWaveGen** is an educational example module designed to generate three distinct waveform types for troubleshooting and testing other modules/devices. It demonstrates proper configuration parameter validation and error handling patterns following the Volo VHDL project standards.

## Features
- **Three Waveform Types**: Square, Triangle, and Sine waves
- **Safety-Critical Parameter Validation**: Wave selection validation with fault reporting
- **Status Register**: 8-bit status register with enabled status and current wave selection
- **Clock Enable Support**: Frequency control via external clock divider
- **VHDL-2008 Compliance**: Designed for Verilog portability

## Module Structure

### Core Module (`core/SimpleWaveGen_core.vhd`)
- Main waveform generation logic
- Safety-critical parameter validation
- Status register implementation
- 128-point sine lookup table

### Testbench (`tb/core/SimpleWaveGen_core_tb.vhd`)
- Comprehensive test coverage for all waveform types
- Error handling validation
- Reset behavior testing
- Clock enable behavior testing

## Interface

### Inputs
- `clk`: System clock input
- `clk_en`: Clock enable from clock divider (frequency control)
- `rst`: Synchronous reset (active high)
- `en`: Module enable (active high)
- `cfg_safety_wave_select[2:0]`: Wave type selection (Safety-Critical Parameter)
  - `000` = Square wave
  - `001` = Triangle wave  
  - `010` = Sine wave
  - `011-111` = Reserved/Invalid (triggers FAULT_OUT)

### Outputs
- `wave_out[15:0]`: 16-bit signed waveform output
- `fault_out`: Error indicator (high when invalid configuration)
- `stat[7:0]`: 8-bit status register
  - Bit [7]: Enabled status
  - Bits [6:3]: Reserved
  - Bits [2:0]: Current wave selection

### Generics
- `VOUT_MAX`: 16-bit signed maximum (default: 32767)
- `VOUT_MIN`: 16-bit signed minimum (default: -32768)

## Waveform Specifications

### Square Wave
- **Duty Cycle**: 50% (symmetric)
- **Output Range**: VOUT_MIN to VOUT_MAX
- **Reset Value**: 0x0000 (starts low)
- **Behavior**: Toggles between high and low on each clock enable

### Triangle Wave
- **Symmetry**: Symmetric around zero
- **Output Range**: VOUT_MIN to VOUT_MAX
- **Reset Value**: 0x0000 (starts at bottom)
- **Behavior**: Ramps up from reset, then down, then up (sawtooth pattern)

### Sine Wave
- **Lookup Table**: 7-bit (128 points covering 0° to 360°)
- **Output Range**: VOUT_MIN to VOUT_MAX
- **Reset Value**: 0x0000 (starts at zero crossing)
- **Behavior**: Continuous sine wave generation

## Dependencies
- `Moku_Voltage_pkg`: For voltage-related constants and utilities
- `clk_divider`: For frequency control via clock enable

## Compilation and Testing

### Prerequisites
- GHDL with VHDL-2008 support
- Moku_Voltage_pkg package compiled

### Compilation Commands
```bash
# Compile dependencies
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd

# Compile core module
ghdl -a --std=08 modules/SimpleWaveGen/core/SimpleWaveGen_core.vhd

# Compile testbench
ghdl -a --std=08 modules/SimpleWaveGen/tb/core/SimpleWaveGen_core_tb.vhd

# Elaborate testbench
ghdl -e --std=08 SimpleWaveGen_core_tb

# Run simulation
ghdl -r --std=08 SimpleWaveGen_core_tb
```

### Expected Test Results
```
=== SimpleWaveGen Core TestBench Started ===
--- Testing Reset Behavior ---
Test 1: Reset outputs to zero - PASSED
--- Testing Square Wave Generation ---
Test 2: Square wave toggles between high/low - PASSED
Test 3: Square wave status register correct - PASSED
--- Testing Triangle Wave Generation ---
Test 4: Triangle wave increases from reset - PASSED
Test 5: Triangle wave status register correct - PASSED
--- Testing Sine Wave Generation ---
Test 6: Sine wave changes from reset - PASSED
Test 7: Sine wave status register correct - PASSED
--- Testing Invalid Wave Selection ---
Test 8: Invalid selection triggers fault_out - PASSED
--- Testing Enable/Disable Functionality ---
Test 9: Disabled status reflected in status register - PASSED
Test 10: Enabled status reflected in status register - PASSED
--- Testing Clock Enable Behavior ---
Test 11: Output stable when clk_en is low - PASSED
--- Testing Multiple Invalid Selections ---
Test 12: All invalid selections trigger fault_out - PASSED
--- Testing Recovery from Invalid Selection ---
Test 13: Recovery from invalid to valid selection - PASSED
=== Test Results ===
ALL TESTS PASSED
SIMULATION DONE
```

## Safety-Critical Parameter Validation

The module implements proper safety-critical parameter validation as required by the project standards:

- **`cfg_safety_wave_select[2:0]`**: MUST be validated on reset and continuously monitored
- **Validation**: Check for valid values (000, 001, 010) only
- **Error Response**: Set `fault_out` high for invalid selections
- **Status**: Invalid selections are reflected in status register

## Error Handling

- **Invalid Wave Selection**: Sets `fault_out` high, maintains last valid output
- **Status Reporting**: Current configuration state reflected in status register
- **Safe State**: Module enters predictable state on configuration errors

## Implementation Notes

- Uses `std_logic_vector` for state encoding (Verilog compatible)
- Implements synchronous state machine
- Follows VHDL-2008 coding standards
- No VHDL-only features used
- Direct instantiation used in testbench
- Proper reset behavior with all outputs initialized to zero

## Future Enhancements (Not Required)
- Duty cycle configuration for square wave
- Frequency configuration registers
- Phase control for sine wave
- Multiple output channels
- Advanced error reporting

## References
- SimpleWaveGen-reqs.md: Detailed requirements specification
- README-ghdl-testbench-tips.md: GHDL testbench development tips
- Volo VHDL Project Guidelines: Overall project coding standards
# SimpleWaveGen Module Requirements

## Overview
The **SimpleWaveGen** is an educational example module designed to generate three distinct waveform types for troubleshooting and testing other modules/devices. It demonstrates proper configuration parameter validation and error handling patterns.

## Dependencies
- `clk_divider` - For frequency control via clock enable
- `Moku_Voltage_pkg` - For voltage-related constants and utilities

## Module Purpose
- **Primary**: Generate three distinct waveform types for testing/troubleshooting
- **Educational**: Demonstrate proper VHDL-2008 coding practices
- **Simple**: Keep implementation straightforward and maintainable

## Interface Specification

### Clock and Control Inputs
- **`clk`**: System clock input
- **`clk_en`**: Clock enable from clock divider (frequency control)
- **`rst`**: Synchronous reset (active high)
- **`en`**: Module enable (active high)

### Configuration Inputs
- **`cfg_safety_wave_select[2:0]`**: Wave type selection (Safety-Critical Parameter)
  - `000` = Square wave
  - `001` = Triangle wave  
  - `010` = Sine wave
  - `011-111` = Reserved/Invalid (triggers FAULT_OUT)

### Outputs
- **`wave_out[15:0]`**: 16-bit signed waveform output
- **`fault_out`**: Error indicator (high when invalid configuration)
- **`stat[7:0]`**: 8-bit status register
  - Bit [7]: Enabled status
  - Bits [6:3]: Reserved
  - Bits [2:0]: Current wave selection

## Generic Parameters
```vhdl
generic (
    VOUT_MAX : integer := 32767;  -- 16-bit signed maximum
    VOUT_MIN : integer := -32768   -- 16-bit signed minimum
);
```

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

## Configuration Parameter Validation

### Safety-Critical Parameters (Required Validation)
- **`cfg_safety_wave_select[2:0]`**: MUST be validated on reset and continuously monitored
- **Validation**: Check for valid values (000, 001, 010) only
- **Error Response**: Set `fault_out` high for invalid selections
- **Status**: Invalid selections should be reflected in status register

### Configuration Parameters (Developer Discretion)
- **Amplitude scaling**: Optional validation at developer's discretion
- **Timing adjustments**: Can be runtime configurable

## Reset Behavior
- **Synchronous Reset**: All outputs reset on rising edge of `rst`
- **Output Reset Value**: 0x0000 for all wave types
- **Status Reset**: All status bits cleared
- **Fault Reset**: `fault_out` cleared
- **Validation**: Safety-critical parameters validated immediately after reset

## Clock Behavior
- **Frequency Control**: Determined by `clk_en` from external clock divider
- **Synchronous Operation**: All state changes occur on rising edge of `clk`
- **Clock Enable**: Wave generation only occurs when `clk_en` is high

## Error Handling
- **Invalid Wave Selection**: Sets `fault_out` high, maintains last valid output
- **Status Reporting**: Current configuration state reflected in status register
- **Safe State**: Module enters predictable state on configuration errors

## Implementation Requirements

### VHDL-2008 Compliance
- Use `std_logic_vector` for state encoding
- Implement as synchronous state machine
- Follow Verilog portability guidelines
- No VHDL-only features

### Resource Constraints
- **Sine Lookup Table**: 128 × 16-bit ROM (2KB)
- **State Machine**: Simple 3-state design
- **Counters**: Minimal counter logic for wave generation

### Performance Requirements
- **Maximum Frequency**: Determined by external clock divider
- **Latency**: One clock cycle from configuration change to output change
- **Jitter**: Minimal, determined by clock quality

## Testbench Requirements

### Minimal Testbench Scope
- **Basic Functionality**: Verify each wave type generates non-zero output
- **Reset Behavior**: Verify outputs start at 0x0000
- **Wave Characteristics**: 
  - Square: Verify toggles between high/low
  - Triangle: Verify increases from reset (ramps up)
  - Sine: Verify starts at zero and changes
- **Error Handling**: Verify FAULT_OUT behavior for invalid selections
- **Status Register**: Verify status bits reflect current state

### Test Coverage
- All three valid wave selections
- Invalid wave selection handling
- Reset behavior for all outputs
- Enable/disable functionality
- Clock enable behavior

## Integration Guidelines

### Top Module Usage
- **Clock Divider**: Top module should instantiate clock divider and connect `clk_en` to SimpleWaveGen
- **Configuration**: Top module handles configuration register interface
- **Status Monitoring**: Top module can read status and fault outputs

### Direct Instantiation
- Top module must use direct instantiation: `entity WORK.SimpleWaveGen`
- No component declarations allowed in top layer

## Success Criteria
- [ ] Compiles with GHDL VHDL-2008
- [ ] All three wave types generate appropriate outputs
- [ ] Invalid configurations properly trigger FAULT_OUT
- [ ] Status register accurately reflects current state
- [ ] Reset behavior is predictable and safe
- [ ] Testbench passes all validation tests
- [ ] Follows all project coding standards

## Future Enhancements (Not Required)
- Duty cycle configuration for square wave
- Frequency configuration registers
- Phase control for sine wave
- Multiple output channels
- Advanced error reporting

## Notes
- Keep implementation simple and educational
- Focus on demonstrating proper validation patterns
- Use as reference for other modules
- Maintain Verilog portability throughout

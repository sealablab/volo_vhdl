# State Machine Base Template

## Overview

The State Machine Base Template provides a **copy-paste foundation** for all Volo VHDL modules. It implements a robust, safety-critical state machine with automatic status register updates and comprehensive debugging visibility.

**This is designed to be copied directly into your module and customized** - not used as a separate component.

## Features

- **4-bit state encoding** with clear bit patterns
- **Automatic status register updates** with state visibility
- **Safety-critical HARD_FAULT state** with reset-only exit
- **Verilog-portable VHDL-2008** implementation
- **Comprehensive testbench** with full coverage
- **Mermaid documentation** for visual state transitions

## State Encoding

| State | Encoding | Description |
|-------|----------|-------------|
| ST_RESET | 0x0 (0000) | Initialization state |
| ST_READY | 0x1 (0001) | Post-reset validation state |
| ST_IDLE | 0x2 (0010) | Default operational state |
| ST_HARD_FAULT | 0xF (1111) | Safety-critical error state |
| Reserved | 0x3-0xE | Available for module-specific states |

## Status Register Layout

```
[31]    : FAULT bit (from HARD_FAULT state)
[30:28] : Reserved for future fault types
[27:24] : Current state (4-bit state machine output)
[23:16] : Reserved for module-specific status
[15:0]  : Module-specific status bits
```

## Port Interface

### Clock and Reset
- `clk` : System clock
- `rst_n` : Active-low reset

### Control Signals
- `ctrl_enable` : Module enable signal
- `ctrl_start` : Start operation signal

### Configuration
- `cfg_param_valid` : Configuration parameters valid flag

### Status Outputs
- `stat_current_state[3:0]` : Current state (4-bit)
- `stat_fault` : FAULT status (from HARD_FAULT state)
- `stat_ready` : READY status
- `stat_idle` : IDLE status
- `stat_status_reg[31:0]` : Complete status register
- `debug_state_machine[3:0]` : Direct state output for debugging

### Module Integration
- `module_status[15:0]` : Module-specific status input

## Quick Start (Copy-Paste Approach)

1. **Copy the entire `state_machine_base.vhd` file** into your module
2. **Rename the entity** to match your module name
3. **Replace the example parameters** with your actual configuration parameters
4. **Customize the validation logic** for your specific requirements
5. **Add your module logic** in the IDLE state or create additional states

See [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) for detailed examples and customization instructions.

## State Transition Logic

### RESET → READY
- Condition: `ctrl_enable='1' AND cfg_param_valid='1'`
- Purpose: Validate configuration parameters

### READY → IDLE
- Condition: `ctrl_start='1'`
- Purpose: Begin normal operation

### Any State → HARD_FAULT
- Condition: Safety-critical error or invalid parameters
- Purpose: Enter safe state, assert FAULT bit

### HARD_FAULT → RESET
- Condition: `rst_n='0'` (reset signal)
- Purpose: Recover from fault state

## Safety Features

1. **Persistent HARD_FAULT**: Once entered, only reset can exit
2. **Parameter Validation**: Invalid parameters cause HARD_FAULT
3. **State Visibility**: Current state always visible in status register
4. **Fault Indication**: FAULT bit automatically asserted in HARD_FAULT
5. **Reset Recovery**: Guaranteed return to RESET state

## Testing

The template includes a comprehensive testbench that validates:

- State transitions and conditions
- Status register updates
- Module status integration
- HARD_FAULT behavior
- Debug output functionality
- Edge cases and error conditions

### Running Tests

```bash
# Compile the template
ghdl -a --std=08 templates/state_machine_base/state_machine_base.vhd

# Compile the testbench
ghdl -a --std=08 templates/state_machine_base/state_machine_base_tb.vhd

# Elaborate the testbench
ghdl -e --std=08 state_machine_base_tb

# Run the simulation
ghdl -r --std=08 state_machine_base_tb
```

## Integration Guidelines

### For New Modules

1. **Inherit from this template** for consistent state management
2. **Add module-specific states** using encoding 0x3-0xE
3. **Implement parameter validation** in the READY state
4. **Add safety checks** that transition to HARD_FAULT
5. **Use module_status input** to expose internal status

### For System Integration

1. **Monitor stat_fault** for safety-critical systems
2. **Use stat_current_state** for debugging and status
3. **Check stat_status_reg** for complete module status
4. **Implement reset logic** to recover from HARD_FAULT

## Customization

### Adding Module-Specific States

```vhdl
-- Add to state definitions
constant ST_MY_STATE1 : std_logic_vector(3 downto 0) := "0011";  -- 0x3
constant ST_MY_STATE2 : std_logic_vector(3 downto 0) := "0100";  -- 0x4

-- Add to next state logic
when ST_MY_STATE1 =>
    if some_condition then
        next_state <= ST_MY_STATE2;
    end if;
```

### Custom Status Bits

```vhdl
-- Use module_status input to expose internal status
module_status(0) <= my_internal_flag;
module_status(1) <= my_operation_complete;
module_status(15 downto 2) <= my_data_status;
```

## Verilog Compatibility

This template is designed for easy Verilog conversion:

- Uses `std_logic_vector` for all state encoding
- Avoids VHDL-only features
- Implements flat port interfaces
- Uses standard synchronous processes
- Follows VHDL-2008 guidelines

## Future Enhancements

The 4-bit state encoding provides room for future expansion:

- **0x3-0x7**: Reserved for common operational states
- **0x8-0xE**: Reserved for module-specific states
- **0xF**: HARD_FAULT (reserved for safety)

This design ensures backward compatibility while providing room for future enhancements.

## Documentation

- [State Transition Diagram](state_transitions.md) - Visual state machine representation
- [Testbench Results](state_machine_base_tb.vhd) - Comprehensive test coverage
- [Integration Examples](README.md) - Usage patterns and best practices
# Stoplight Top-Level Module

## Overview
The `stoplight_top` module provides the complete stoplight system integration with register-based interface for platform control system integration. It integrates the `stoplight_core` with a clock divider and provides external light outputs.

## Features

### Register Interface
- **32-bit Control Register**: Global enable and clock divider selection
- **32-bit Configuration Register**: Timing parameters (red/yellow delays)
- **32-bit Status Register**: System status and fault information
- **32-bit State Register**: Current state and countdown value

### External Interface
- **Light Outputs**: Direct red/yellow/green light signals
- **Trigger Input**: External trigger to start traffic light cycle
- **Fault Output**: Global fault indication

### Integration
- **Clock Divider**: Integrated clock divider for timing control
- **Direct Instantiation**: Uses VOLO direct instantiation patterns
- **Status Monitoring**: Complete status register readback

## Interface

### System Interface
```vhdl
clk         : in  std_logic;                    -- System clock input
rst         : in  std_logic;                    -- Synchronous reset (active high)
```

### Register Interface
```vhdl
-- Control Register (32-bit)
stoplight_ctrl_wr     : in  std_logic;                    -- Control register write enable
stoplight_ctrl_data   : in  std_logic_vector(31 downto 0); -- Control data
-- Bit 31: Global enable
-- Bits 30-27: Clock divider selection (4 bits)
-- Bits 26-0: Reserved

-- Configuration Register (32-bit)
stoplight_cfg_wr      : in  std_logic;                    -- Configuration register write enable
stoplight_cfg_data    : in  std_logic_vector(31 downto 0); -- Configuration data
-- Bits 31-16: Red delay (16 bits)
-- Bits 15-0: Yellow delay (16 bits)
-- Note: Green delay fixed at 30000 (can be extended)

-- Read Interface
stoplight_status_rd   : out std_logic_vector(31 downto 0); -- Status register
stoplight_state_rd    : out std_logic_vector(31 downto 0); -- State register
```

### External Interface
```vhdl
trig_in     : in  std_logic;                    -- External trigger input
light_red   : out std_logic;                    -- Red light output
light_yellow: out std_logic;                    -- Yellow light output
light_green : out std_logic;                    -- Green light output
fault_out   : out std_logic                     -- Global fault output
```

## Register Layout

### Control Register (stoplight_ctrl_data)
- **Bit 31**: Global enable (1 = enabled, 0 = disabled)
- **Bits 30-27**: Clock divider selection (0-15)
- **Bits 26-0**: Reserved (must be 0)

### Configuration Register (stoplight_cfg_data)
- **Bits 31-16**: Red delay in clock cycles (1-40000)
- **Bits 15-0**: Yellow delay in clock cycles (1-20000)
- **Note**: Green delay is fixed at 30000 cycles

### Status Register (stoplight_status_rd)
- **Bits 31-24**: Core status register (8 bits from stoplight_core)
- **Bits 23-16**: Clock divider status (8 bits)
- **Bits 15-8**: Reserved (0x00)
- **Bits 7-0**: Control status (bit 7 = enable, bits 6-0 = 0)

### State Register (stoplight_state_rd)
- **Bits 31-16**: Countdown value (16 bits, currently 0x0000)
- **Bits 15-3**: Reserved (0x000)
- **Bits 2-0**: Current state (3 bits)
  - 000: RESET_STATE
  - 001: IDLE_STATE
  - 010: RED_STATE
  - 011: YELLOW_STATE
  - 100: GREEN_STATE
  - 101: FAULT_STATE

## Usage

### Basic Operation
1. **Reset**: Assert `rst` to initialize the system
2. **Configure**: Write timing parameters to configuration register
3. **Enable**: Write control register with enable bit set
4. **Trigger**: Assert `trig_in` to start traffic light cycle
5. **Monitor**: Read status and state registers for system state

### Register Access
```vhdl
-- Enable module with clock divider = 0
stoplight_ctrl_data <= x"80000000";
stoplight_ctrl_wr <= '1';
wait for clk_period;
stoplight_ctrl_wr <= '0';

-- Configure timing (red=1000, yellow=500)
stoplight_cfg_data <= x"03E801F4";
stoplight_cfg_wr <= '1';
wait for clk_period;
stoplight_cfg_wr <= '0';

-- Read status
status := stoplight_status_rd;
state := stoplight_state_rd;
```

### Light Outputs
- **light_red**: Active high when in RED state
- **light_yellow**: Active high when in YELLOW state
- **light_green**: Active high when in GREEN state
- **fault_out**: Active high when fault condition detected

## Integration Notes

### Clock Divider
- Uses `clk_divider_core` for timing control
- Clock divider selection via control register bits 30-27
- Clock enable derived from divider status

### Fault Detection
- Module faults: Invalid configuration, core errors
- Clock divider faults: Invalid divider selection
- Global fault output combines all fault sources

### Direct Instantiation
- Follows VOLO standards for direct instantiation
- No intermediate wrapper modules
- Direct entity instantiation of core modules

## Testing

### Testbench
- **stoplight_top_tb.vhd**: Complete top-level testbench
- **4-layer architecture**: Interface, validation, functional, parameter testing
- **Register testing**: Control and configuration register access
- **Integration testing**: Clock divider and core module integration

### Test Coverage
- Register interface read/write operations
- External trigger and light output behavior
- Fault detection and status reporting
- Clock divider integration
- State machine operation through register interface

## Dependencies

- **stoplight_core**: Core traffic light state machine
- **clk_divider_core**: Clock divider for timing control
- **volo_common_pkg**: Status register constants
- **stoplight_constants_pkg**: Custom constants
- **platform_interface_pkg**: Register interface definitions

## File Structure

```
modules/stoplight/top/
├── stoplight_top.vhd          # Main top-level entity
├── README.md                  # This documentation
└── tb/
    └── stoplight_top_tb.vhd   # Top-level testbench
```

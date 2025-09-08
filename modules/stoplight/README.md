# Stoplight Module - VOLO VHDL

A traffic light countdown timer module demonstrating the VOLO VHDL generation workflow with configurable delays for each light state.

## Overview

The stoplight module implements a complete traffic light system with:
- **VOLO State Machine Integration**: Inherits standard RESET→READY→IDLE transitions
- **Custom Traffic Light States**: RED→YELLOW→GREEN→IDLE cycle
- **Configurable Timing**: Independent delays for each light state
- **Status Register**: 8-bit status register with state indicators
- **Input Validation**: Parameter validation with error handling

## Features

### State Machine
- **Base States** (inherited from VOLO):
  - `RESET_STATE` (000): Initial state, configuration validation
  - `READY_STATE` (001): Configuration validated, ready for operation
  - `IDLE_STATE` (010): Waiting for trigger input
  - `FAULT_STATE` (011): Error condition, requires reset

- **Custom States** (stoplight-specific):
  - `RED_STATE` (100): Red light active, countdown from cfg_red_delay
  - `YELLOW_STATE` (101): Yellow light active, countdown from cfg_yellow_delay
  - `GREEN_STATE` (110): Green light active, countdown from cfg_green_delay

### Configuration Parameters
- **cfg_red_delay**: 1-40000 clock cycles (16-bit)
- **cfg_yellow_delay**: 1-20000 clock cycles (16-bit)
- **cfg_green_delay**: 30000-65000 clock cycles (16-bit)

### Status Register (8-bit)
- **Bit 7**: FAULT - Module in error state
- **Bit 6**: ALARM - Set during YELLOW state
- **Bit 5**: BUSY - Reserved for future use
- **Bit 4**: READY - Configuration validated
- **Bit 3**: ENABLED - Module enable status
- **Bit 2**: ACTIVE - Reserved for future use
- **Bit 1**: VALID - Configuration parameters valid
- **Bit 0**: IDLE - Module in idle state

### Custom Status Bits
- **Bit 3**: RED - Red light active
- **Bit 2**: YELLOW - Yellow light active  
- **Bit 1**: GREEN - Green light active

## Interface

### Control Signals
```vhdl
clk         : in  std_logic;                    -- System clock
rst_n       : in  std_logic;                    -- Active low reset
enable      : in  std_logic;                    -- Module enable
clk_en      : in  std_logic;                    -- Clock enable
trig_in     : in  std_logic;                    -- Trigger input (starts cycle)
```

### Configuration
```vhdl
cfg_red_delay    : in  std_logic_vector(15 downto 0);  -- Red duration (clks)
cfg_yellow_delay : in  std_logic_vector(15 downto 0);  -- Yellow duration (clks)
cfg_green_delay  : in  std_logic_vector(15 downto 0);  -- Green duration (clks)
```

### Outputs
```vhdl
stat_status_out : out std_logic_vector(7 downto 0);  -- 8-bit status register
```

## Usage

### Basic Operation
1. **Reset**: Module starts in RESET_STATE, validates configuration
2. **Ready**: Automatic transition to READY_STATE when configuration valid
3. **Idle**: Automatic transition to IDLE_STATE, waiting for trigger
4. **Trigger**: `trig_in` high starts traffic light cycle
5. **Cycle**: RED → YELLOW → GREEN → IDLE (automatic transitions)
6. **Repeat**: Module returns to IDLE, ready for next trigger

### Configuration Validation
- Invalid parameters trigger immediate transition to FAULT_STATE
- Parameters validated only during reset
- No runtime re-validation

## Building and Testing

### Compilation
```bash
# From modules directory
cd /path/to/volo_vhdl/modules
make clean && make

# From stoplight directory  
cd stoplight
make clean && make compile
```

### Testing
```bash
# Run testbench
cd /path/to/volo_vhdl/modules
ghdl -e --std=08 stoplight_core_tb
ghdl -r --std=08 stoplight_core_tb
```

### Test Coverage
- **Layer 1**: Interface testing (status register behavior)
- **Layer 2**: Validation testing (parameter validation)
- **Layer 3**: Functional testing (state transitions)
- **Layer 4**: Generic parameter testing (edge cases)
- **Control**: Enable/disable behavior

## File Structure

```
modules/stoplight/
├── common/
│   └── stoplight_constants_pkg.vhd    # Constants and validation functions
├── core/
│   └── stoplight_core.vhd             # Main entity with state machine
├── tb/
│   └── core/
│       └── stoplight_core_tb.vhd      # 4-layer testbench
├── Makefile                           # Build configuration
└── README.md                          # This file
```

## Dependencies

- **volo_common_pkg**: Status register constants and utility functions
- **VOLO Base Module Pattern**: Standard state machine transitions

## Changelog

### 2025-09-08
- **Initial Release**: Complete stoplight module implementation
- **VOLO Integration**: Proper state machine pattern inheritance
- **Status Register**: 8-bit status register with custom traffic light bits
- **Configuration Validation**: Parameter validation with error handling
- **Testbench**: 4-layer testbench architecture with comprehensive coverage
- **Build System**: Makefile integration with dependency management
- **Documentation**: Complete README with usage examples and interface specification

# SimpleWaveGen Top-Level Module

## Overview
The **SimpleWaveGen_top** module provides a register-based interface for the SimpleWaveGen waveform generator. It integrates the SimpleWaveGen core with a clock divider and exposes a comprehensive register interface for host control and monitoring.

## Features
- **Register-Based Interface**: 32-bit registers for control, configuration, status, and output
- **Safety-Critical Parameter Validation**: Wave selection validation with fault reporting
- **Amplitude Scaling**: Runtime configurable amplitude scaling (0x0000-0xFFFF)
- **Clock Divider Integration**: Configurable frequency control (division ratios 1-16)
- **Fault Aggregation**: Comprehensive fault monitoring and reporting
- **VHDL-2008 Compliance**: Designed for Verilog portability

## Interface

### System Interface
- `clk`: System clock input
- `rst`: Synchronous reset (active high)

### Register Write Interface
- `ctrl0_wr`, `ctrl0_data`: Control0 register (global enable, clock divider selection)
- `ctrl1_wr`, `ctrl1_data`: Control1 register (reserved for future use)
- `config0_wr`, `config0_data`: Config0 register (wave selection - safety critical)
- `config1_wr`, `config1_data`: Config1 register (amplitude scaling)

### Register Read Interface
- `status0_rd`: Status0 register (enabled status, wave selection)
- `status1_rd`: Status1 register (global fault status)
- `output0_rd`: Output0 register (current waveform output)

### External Interface
- `wave_out`: Direct 16-bit signed waveform output
- `fault_out`: Global fault output

## Register Map

### Control0 Register (Write-Only)
| Bit Range | Field Name | Type | Default | Description |
|-----------|-------------|------|---------|-------------|
| [31] | `ctrl_global_enable` | Control | 0 | Global module enable (1=enable, 0=disable) |
| [30:24] | Reserved | - | 0 | Reserved for future use |
| [23:20] | `cfg_clk_div_sel` | Config | 0 | Clock divider selection (0-15, 0=no division) |
| [19:0] | Reserved | - | 0 | Reserved for future use |

### Config0 Register (Write-Only) - **SAFETY CRITICAL**
| Bit Range | Field Name | Type | Default | Safety Critical | Description |
|-----------|-------------|------|---------|-----------------|-------------|
| [31:3] | Reserved | - | 0 | No | Reserved for future use |
| [2:0] | `cfg_safety_wave_select` | Config | 0 | **YES** | Wave type selection (000=square, 001=triangle, 010=sine, 011-111=invalid) |

### Config1 Register (Write-Only)
| Bit Range | Field Name | Type | Default | Safety Critical | Description |
|-----------|-------------|------|---------|-----------------|-------------|
| [31:16] | Reserved | - | 0 | No | Reserved for future use |
| [15:0] | `cfg_amplitude_scale` | Config | 0x8000 | No | Amplitude scaling factor (0x0000-0xFFFF, 0x8000=unity) |

### Status0 Register (Read-Only)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:8] | Reserved | - | Reserved for future use |
| [7] | `stat_enabled` | Status | Module enabled status (1=enabled, 0=disabled) |
| [6:3] | Reserved | - | Reserved for future use |
| [2:0] | `stat_wave_select` | Status | Current wave selection (mirrors config) |

### Status1 Register (Read-Only)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:1] | Reserved | - | Reserved for future use |
| [0] | `stat_global_fault` | Status | **Aggregated fault status** (1=fault detected, 0=normal) |

### Output0 Register (Read-Only)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:16] | Reserved | - | Reserved for future use |
| [15:0] | `wave_out` | Output | Current 16-bit signed waveform output (-32768 to +32767) |

## Safety-Critical Parameter Validation

### Wave Selection Validation
- **Parameter**: `cfg_safety_wave_select[2:0]`
- **Valid Values**: 000 (square), 001 (triangle), 010 (sine)
- **Invalid Values**: 011-111 (triggers fault_out)
- **Validation**: Continuous monitoring with immediate fault response
- **Recovery**: Write valid value to clear fault condition

## Amplitude Scaling

### Scaling Function
- **Formula**: `scaled_output = (wave_out * amplitude_scale) / 32768`
- **Unity Scaling**: `amplitude_scale = 0x8000` (no change)
- **Half Amplitude**: `amplitude_scale = 0x4000`
- **Maximum Amplitude**: `amplitude_scale = 0xFFFF`

## Clock Divider Integration

### Division Ratios
- **0**: No division (clk_en always high)
- **1**: Divide by 2
- **2**: Divide by 3
- **...**
- **15**: Divide by 16

### Frequency Control
- Clock divider provides `clk_en` to SimpleWaveGen core
- Waveform generation only occurs when `clk_en` is high
- Frequency = system_clock / (div_sel + 1)

## Fault Aggregation

### Fault Sources
1. **SimpleWaveGen_core.fault_out**: Invalid wave selection
2. **clk_divider.fault_out**: Invalid clock divider configuration (if applicable)

### Aggregation Logic
- **Global Fault**: OR of all sub-module fault outputs
- **Status Register**: `stat_global_fault` reflects aggregated fault state
- **Reset Behavior**: Cleared on system reset
- **Fault Persistence**: Fault remains until configuration is corrected

## Dependencies

### Required Modules
- `SimpleWaveGen_core`: Main waveform generation logic
- `clk_divider_core`: Clock divider for frequency control
- `Moku_Voltage_pkg`: Voltage-related constants and utilities
- `platform_interface_pkg`: Register interface utilities and constants

### Compilation Order
1. `Moku_Voltage_pkg.vhd`
2. `platform_interface_pkg.vhd`
3. `clk_divider_core.vhd`
4. `SimpleWaveGen_core.vhd`
5. `SimpleWaveGen_top.vhd`

## Compilation and Testing

### Prerequisites
- GHDL with VHDL-2008 support
- All dependency modules compiled

### Compilation Commands
```bash
# Compile dependencies
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd
ghdl -a --std=08 modules/SimpleWaveGen/common/platform_interface_pkg.vhd
ghdl -a --std=08 modules/clk_divider/core/clk_divider_core.vhd
ghdl -a --std=08 modules/SimpleWaveGen/core/SimpleWaveGen_core.vhd

# Compile top module
ghdl -a --std=08 modules/SimpleWaveGen/top/SimpleWaveGen_top.vhd

# Compile testbench
ghdl -a --std=08 modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd

# Elaborate testbench
ghdl -e --std=08 SimpleWaveGen_top_tb

# Run simulation
ghdl -r --std=08 SimpleWaveGen_top_tb
```

### Expected Test Results
```
=== SimpleWaveGen Top-Level TestBench Started ===
--- Testing Register Access ---
Test 1: Control0 register write/read - PASSED
Test 2: Config0 register write/read - PASSED
Test 3: Config1 register write/read - PASSED
--- Testing Safety-Critical Parameter Validation ---
Test 4: Valid wave selections - PASSED
Test 5: Invalid wave selections trigger fault - PASSED
Test 6: Fault recovery - PASSED
--- Testing Amplitude Scaling ---
Test 7: Unity scaling - PASSED
Test 8: Half amplitude scaling - PASSED
Test 9: Maximum amplitude scaling - PASSED
--- Testing Clock Divider Integration ---
Test 10: Clock divider configuration - PASSED
Test 11: Frequency division verification - PASSED
--- Testing Fault Aggregation ---
Test 12: Core fault aggregation - PASSED
Test 13: Global fault status - PASSED
--- Testing Reset and Initialization ---
Test 14: Reset behavior - PASSED
Test 15: Initialization sequence - PASSED
--- Testing End-to-End Functionality ---
Test 16: Square wave generation - PASSED
Test 17: Triangle wave generation - PASSED
Test 18: Sine wave generation - PASSED
=== Test Results ===
ALL TESTS PASSED
SIMULATION DONE
```

## Implementation Notes

### Design Decisions
1. **Register Interface**: 32-bit registers with explicit write enables for each register
2. **Fault Aggregation**: Simple OR logic for all fault sources
3. **Amplitude Scaling**: Applied to core waveform output before register exposure
4. **Clock Divider**: Direct integration with fault output aggregation
5. **Safety Validation**: Continuous monitoring with immediate fault response

### VHDL-2008 Compliance
- Uses `std_logic` and `std_logic_vector` types only
- Implements synchronous processes with `rising_edge(clk)`
- Uses explicit bit widths for all vectors
- No VHDL-only features (records, enums, etc.)
- Direct instantiation for all sub-modules

### Signal Naming Conventions
- Control signals: `ctrl_*` prefix
- Configuration signals: `cfg_*` prefix
- Safety-critical parameters: `cfg_safety_*` prefix
- Status signals: `stat_*` prefix

## Future Enhancements (Not Required)
- Phase control for sine wave
- Duty cycle configuration for square wave
- Multiple output channels
- Advanced error reporting with fault codes
- DMA transfer interface for high-speed output
- Real-time frequency adjustment

## References
- SimpleWaveGen-top-regs-r2.md: Detailed register interface specification
- SimpleWaveGen-reqs.md: Core module requirements
- platform_interface_pkg.vhd: Register interface utilities and constants
- Volo VHDL Project Guidelines: Overall project coding standards
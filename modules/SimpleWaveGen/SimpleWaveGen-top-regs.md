# SimpleWaveGen Top-Level Register Interface Specification

## Module Overview
- **Module Name**: SimpleWaveGen
- **Purpose**: Waveform generator with configurable wave types and frequency control
- **Top Interface Type**: Register-based control system with fault aggregation

## Register Interface Requirements

### 1. Control Registers (Write-Only from Host)

#### Control0 Register (32-bit)
| Bit Range | Field Name | Type | Default | Description |
|-----------|-------------|------|---------|-------------|
| [31] | `ctrl_global_enable` | Control | 0 | Global module enable (1=enable, 0=disable) |
| [30:24] | Reserved | - | 0 | Reserved for future use |
| [23:20] | `cfg_clk_div_sel` | Config | 0 | Clock divider selection (0-15, 0=no division) |
| [19:16] | Reserved | - | 0 | Reserved for future use |
| [15:0] | Reserved | - | 0 | Reserved for future use |

#### Control1 Register (32-bit)
| Bit Range | Field Name | Type | Default | Description |
|-----------|-------------|------|---------|-------------|
| [31:16] | Reserved | - | 0 | Reserved for future use |
| [15:0] | Reserved | - | 0 | Reserved for future use |

### 2. Configuration Registers (Write-Only from Host)

#### Config0 Register (32-bit)
| Bit Range | Field Name | Type | Default | Safety Critical | Description |
|-----------|-------------|------|---------|-----------------|-------------|
| [31:3] | Reserved | - | 0 | No | Reserved for future use |
| [2:0] | `cfg_safety_wave_select` | Config | 0 | **YES** | Wave type selection (000=square, 001=triangle, 010=sine, 011-111=invalid) |

### 3. Status Registers (Read-Only by Host)

#### Status0 Register (32-bit)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:8] | Reserved | - | Reserved for future use |
| [7] | `stat_enabled` | Status | Module enabled status (1=enabled, 0=disabled) |
| [6:3] | Reserved | - | Reserved for future use |
| [2:0] | `stat_wave_select` | Status | Current wave selection (mirrors config) |

#### Status1 Register (32-bit)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:1] | Reserved | - | Reserved for future use |
| [0] | `stat_global_fault` | Status | **Aggregated fault status** (1=fault detected, 0=normal) |

## Safety-Critical Parameter Analysis

### Required Validation
- **`cfg_safety_wave_select[2:0]`**: MUST be validated on reset and continuously monitored
  - **Valid Values**: 000, 001, 010 only
  - **Invalid Response**: Set fault_out high, maintain last valid configuration
  - **Status Reflection**: Invalid selections reflected in status register

### Non-Safety-Critical Parameters
- **`cfg_clk_div_sel[3:0]`**: Clock divider selection (developer discretion validation)
  - **Valid Range**: 0-15 (4-bit field)
  - **Default**: 0 (no division)
  - **Error Response**: Clamp to valid range if needed

## Fault Aggregation Rules

### Sub-Module Fault Sources
1. **SimpleWaveGen_core.fault_out** → Invalid wave selection
2. **clk_divider.fault_out** → Invalid clock divider configuration (if applicable)

### Aggregation Logic
- **Global Fault**: OR of all sub-module fault outputs
- **Status Register**: `stat_global_fault` reflects aggregated fault state
- **Reset Behavior**: Cleared on system reset

## Implementation Guidelines

### Top Module Responsibilities
- **Register Interface**: Handle all host register read/write operations
- **Fault Aggregation**: OR together all sub-module fault outputs
- **Clock Management**: Instantiate and configure clock divider
- **Status Reporting**: Maintain current configuration state in status registers

### Direct Instantiation Requirements
- **SimpleWaveGen_core**: `entity WORK.SimpleWaveGen_core`
- **clk_divider**: `entity WORK.clk_divider_core`
- **No component declarations allowed**

### Register Access Patterns
- **Write Access**: Configuration changes take effect on next clock cycle
- **Read Access**: Status registers reflect current state (no buffering)
- **Reset**: All registers return to default values

## Testbench Requirements

### Top-Level Testbench
- **Location**: `modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`
- **Direct Instantiation**: Required for all module instantiations
- **Test Coverage**: Register access, fault aggregation, configuration validation

### Test Scenarios
1. **Basic Functionality**: Verify each wave type generates appropriate output
2. **Register Access**: Test write/read of all control and configuration registers
3. **Fault Handling**: Test invalid configurations trigger fault outputs
4. **Fault Aggregation**: Verify global fault status reflects sub-module faults
5. **Reset Behavior**: Verify all registers return to defaults

## Automation Notes

### Code Generation Targets
- **Register Interface**: VHDL entity with proper port mapping
- **Fault Aggregation**: Automatic OR logic for all fault outputs
- **Status Registers**: Automatic reflection of current configuration state
- **Validation Logic**: Automatic bounds checking for safety-critical parameters

### Required Metadata
- **Field Types**: Control, Config, Status (with Safety Critical flag)
- **Bit Ranges**: Explicit start/end bit positions
- **Default Values**: Initial values for all fields
- **Validation Rules**: Bounds and safety requirements

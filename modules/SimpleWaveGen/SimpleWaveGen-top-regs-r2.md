# SimpleWaveGen Top-Level Register Interface Specification (Revision 2)

## Module Overview
- **Module Name**: SimpleWaveGen
- **Purpose**: Waveform generator with configurable wave types, frequency control, and amplitude scaling
- **Top Interface Type**: Register-based control system with fault aggregation
- **Revision**: 2 (Enhanced with output interface, amplitude control, and detailed specifications)

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

#### Config1 Register (32-bit)
| Bit Range | Field Name | Type | Default | Safety Critical | Description |
|-----------|-------------|------|---------|-----------------|-------------|
| [31:16] | Reserved | - | 0 | No | Reserved for future use |
| [15:0] | `cfg_amplitude_scale` | Config | 0x8000 | No | Amplitude scaling factor (0x0000-0xFFFF, 0x8000=unity) |

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

### 4. Output Registers (Read-Only by Host)

#### Output0 Register (32-bit)
| Bit Range | Field Name | Type | Description |
|-----------|-------------|------|-------------|
| [31:16] | Reserved | - | Reserved for future use |
| [15:0] | `wave_out` | Output | Current 16-bit signed waveform output (-32768 to +32767) |

## Safety-Critical Parameter Analysis

### Required Validation
- **`cfg_safety_wave_select[2:0]`**: MUST be validated on reset and continuously monitored
  - **Valid Values**: 000, 001, 010 only
  - **Invalid Response**: Set fault_out high, maintain last valid configuration
  - **Status Reflection**: Invalid selections reflected in status register
  - **Recovery**: Write valid value to clear fault condition

### Non-Safety-Critical Parameters
- **`cfg_clk_div_sel[3:0]`**: Clock divider selection (developer discretion validation)
  - **Valid Range**: 0-15 (4-bit field)
  - **Default**: 0 (no division)
  - **Error Response**: Clamp to valid range if needed
- **`cfg_amplitude_scale[15:0]`**: Amplitude scaling factor (developer discretion validation)
  - **Valid Range**: 0x0000-0xFFFF (16-bit field)
  - **Default**: 0x8000 (unity scaling)
  - **Error Response**: Clamp to valid range if needed

## Fault Aggregation Rules

### Sub-Module Fault Sources
1. **SimpleWaveGen_core.fault_out** → Invalid wave selection
2. **clk_divider.fault_out** → Invalid clock divider configuration (if applicable)

### Aggregation Logic
- **Global Fault**: OR of all sub-module fault outputs
- **Status Register**: `stat_global_fault` reflects aggregated fault state
- **Reset Behavior**: Cleared on system reset
- **Fault Persistence**: Fault remains until configuration is corrected

## Register Access Timing and Initialization

### Register Access Timing
- **Write Latency**: Configuration changes take effect on next rising clock edge
- **Read Latency**: Status and output registers reflect current state immediately (no buffering)
- **Reset Latency**: All registers return to defaults within 1 clock cycle

### Initialization Sequence
1. **Power-On Reset**: All registers set to default values
2. **Safety Validation**: Safety-critical parameters validated immediately after reset
3. **Fault Clearing**: All fault outputs cleared on successful validation
4. **Ready State**: Module ready for operation when no faults present

### Clock Domain Requirements
- **Register Interface**: Synchronous to system clock
- **Waveform Generation**: Synchronous to system clock with clk_en gating
- **No Clock Domain Crossing**: All interfaces use same clock domain

## Implementation Guidelines

### Top Module Responsibilities
- **Register Interface**: Handle all host register read/write operations
- **Fault Aggregation**: OR together all sub-module fault outputs
- **Clock Management**: Instantiate and configure clock divider
- **Status Reporting**: Maintain current configuration state in status registers
- **Output Management**: Provide current waveform output through output register

### Direct Instantiation Requirements
- **SimpleWaveGen_core**: `entity WORK.SimpleWaveGen_core`
- **clk_divider**: `entity WORK.clk_divider_core`
- **No component declarations allowed**

### Clock Divider Integration
- **Configuration**: `cfg_clk_div_sel` directly controls clock divider selection
- **Clock Enable**: Clock divider provides `clk_en` to SimpleWaveGen_core
- **Fault Handling**: Clock divider fault output aggregated into global fault status
- **Frequency Range**: Clock divider supports division ratios 1-16 (0=no division)

## Testbench Requirements

### Top-Level Testbench
- **Location**: `modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`
- **Direct Instantiation**: Required for all module instantiations
- **Test Coverage**: Register access, fault aggregation, configuration validation, output verification

### Detailed Test Scenarios

#### 1. Register Access Tests
- **Control0 Register**:
  - Write `ctrl_global_enable=1`, verify `stat_enabled=1` on next clock
  - Write `cfg_clk_div_sel=0x5`, verify clock divider configuration
  - Write `cfg_clk_div_sel=0x10` (invalid), verify clamping to 0xF
- **Config0 Register**:
  - Write `cfg_safety_wave_select=000`, verify `stat_wave_select=000` and no fault
  - Write `cfg_safety_wave_select=001`, verify `stat_wave_select=001` and no fault
  - Write `cfg_safety_wave_select=010`, verify `stat_wave_select=010` and no fault
  - Write `cfg_safety_wave_select=011`, verify fault assertion and status reflection
  - Write `cfg_safety_wave_select=111`, verify fault assertion and status reflection
- **Config1 Register**:
  - Write `cfg_amplitude_scale=0x8000`, verify unity scaling
  - Write `cfg_amplitude_scale=0x4000`, verify half amplitude scaling
  - Write `cfg_amplitude_scale=0xFFFF`, verify maximum amplitude scaling

#### 2. Fault Aggregation Tests
- **Single Fault Sources**:
  - Force `SimpleWaveGen_core.fault_out=1`, verify `stat_global_fault=1`
  - Force `clk_divider.fault_out=1`, verify `stat_global_fault=1`
- **Multiple Fault Sources**:
  - Force both fault sources high, verify `stat_global_fault=1`
  - Clear one fault source, verify `stat_global_fault` remains high until all cleared
- **Fault Recovery**:
  - Set invalid wave selection, verify fault assertion
  - Write valid wave selection, verify fault clearing

#### 3. Output Validation Tests
- **Waveform Output Verification**:
  - Configure square wave, verify `wave_out` toggles between high/low values
  - Configure triangle wave, verify `wave_out` shows ramping behavior
  - Configure sine wave, verify `wave_out` shows sinusoidal behavior
- **Amplitude Scaling Verification**:
  - Set `cfg_amplitude_scale=0x4000`, verify output amplitude is half of full scale
  - Set `cfg_amplitude_scale=0x8000`, verify output amplitude is full scale
- **Output Range Compliance**:
  - Verify all waveform outputs stay within -32768 to +32767 range
  - Verify output changes appropriately with clock enable

#### 4. Reset and Initialization Tests
- **Reset Behavior**:
  - Apply reset, verify all registers return to default values
  - Verify `stat_global_fault=0` after reset
  - Verify `wave_out=0x0000` after reset
- **Initialization Sequence**:
  - Release reset, verify safety-critical parameter validation
  - Verify module enters ready state with no faults
  - Verify default configuration is active

#### 5. Integration Tests
- **Clock Divider Integration**:
  - Set `cfg_clk_div_sel=2`, verify clock enable frequency is system_clock/4
  - Verify waveform output frequency matches expected divided frequency
- **End-to-End Functionality**:
  - Configure valid wave type and amplitude
  - Enable module, verify appropriate waveform output
  - Change configuration, verify output updates on next clock cycle

### Test Success Criteria
- **ALL TESTS PASSED**: All test scenarios complete successfully
- **TEST FAILED**: Any test scenario fails validation
- **SIMULATION DONE**: Always printed at test completion
- **Individual Test Results**: Each test reports pass/fail status

## Automation Notes

### Code Generation Targets
- **Register Interface**: VHDL entity with proper port mapping
- **Fault Aggregation**: Automatic OR logic for all fault outputs
- **Status Registers**: Automatic reflection of current configuration state
- **Validation Logic**: Automatic bounds checking for safety-critical parameters
- **Output Interface**: Automatic waveform output register implementation

### Required Metadata
- **Field Types**: Control, Config, Status, Output (with Safety Critical flag)
- **Bit Ranges**: Explicit start/end bit positions
- **Default Values**: Initial values for all fields
- **Validation Rules**: Bounds and safety requirements
- **Timing Requirements**: Register access timing specifications
- **Fault Sources**: Complete list of fault inputs for aggregation

### Automation Readiness Checklist
- [x] All register fields explicitly defined with bit positions
- [x] Field types clearly classified (Control, Config, Status, Output)
- [x] Default values specified for all fields
- [x] Validation rules defined for all parameters
- [x] Safety-critical parameters clearly identified
- [x] Fault aggregation logic specified
- [x] Register access timing defined
- [x] Test requirements detailed with specific validation criteria
- [x] Direct instantiation requirements specified
- [x] Clock domain requirements clarified

## MCC Compatibility

### Interface Compatibility
- **Register Structure**: Flat 32-bit registers compatible with standard bus interfaces
- **Read/Write Semantics**: Clear separation of control, config, status, and output registers
- **Fault Handling**: Standard fault aggregation approach for system integration
- **Clock Domain**: Single clock domain simplifies integration

### Platform Integration
- **CustomWrapper Integration**: Register interface designed for Moku CustomWrapper approach
- **Fault Monitoring**: Global fault status enables system-level fault handling
- **Status Monitoring**: Real-time status and output registers for system monitoring
- **Configuration Management**: Standard configuration register approach

## Success Criteria

### Implementation Requirements
- [ ] Compiles with GHDL VHDL-2008
- [ ] All register interfaces function correctly
- [ ] Fault aggregation works for all fault sources
- [ ] Safety-critical parameter validation functions properly
- [ ] Output register provides current waveform data
- [ ] Clock divider integration works correctly
- [ ] All test scenarios pass validation
- [ ] Follows all project coding standards

### Verification Requirements
- [ ] All test scenarios execute successfully
- [ ] Register access timing meets specifications
- [ ] Fault handling works for all error conditions
- [ ] Output waveforms meet specifications
- [ ] Reset and initialization sequence works correctly
- [ ] Integration with clock divider functions properly

## Future Enhancements (Not Required)
- Phase control for sine wave
- Duty cycle configuration for square wave
- Multiple output channels
- Advanced error reporting with fault codes
- DMA transfer interface for high-speed output
- Real-time frequency adjustment
# ProbeHero9 Interface Requirements - Version 1

## 📋 Source Attribution
**COPIED FROM**: `ai-workflow/examples/ProbeHero7/PH7-interface-reqs-r2.md`  
**DATE**: 2025-01-27  
**PURPOSE**: Base interface requirements for ProbeHero9 development  
**NOTE**: This file will be adapted and enhanced for ProbeHero9-specific requirements

---

## 🎯 Module Overview
**ProbeHero9 is a VHDL module designed to drive various SCA and FI probes with enhanced capabilities beyond ProbeHero7. Conceptually it is similar to a simple signal generator with improved safety, reliability, and integration features. It is intended to drive two analog outputs in response to a simple `trigger_in` signal.  

Characteristics about the specific probe's are stored in `Global_Probe_Table` and are encapsulated in the `Probe_Config_pkg_PH9.vhd` (enhanced version)

The module will utilize the `PercentLut_pkg_PH9.vhd` file to interface with a probe-specific intensity look-up table. 

The module also utilizes the `Moku_Voltage_pkg_PH9.vhd` file for manipulating voltages in a platform specific and safe manner.

### Units Convention
All parameters include units for clarity and future metadata:
- **Physical Units**: `clks` (clock cycles), `volts` (voltage)
- **Logical Units**: `index` (table indices), `bits` (status register)
- **Signal Units**: `signal` (control and clock signals)

### ProbeHero9 Enhancements
**Key improvements over ProbeHero7:**
- **Enhanced Error Handling**: Improved validation and recovery mechanisms
- **Better Integration**: Enhanced platform integration and status reporting
- **Extended Safety**: Additional safety checks and fault detection
- **Improved Reliability**: Better state management and error recovery
- **Enhanced Packages**: Uses enhanced datadef packages with better validation

<!-- 
  TIP: Keep this concise but descriptive. Think about what someone would need to know 
  to understand if this module is relevant to their needs.
-->

## 🔗 Dependencies

### Core Dependencies
<!-- 
  TIP: These are the packages/modules your module absolutely needs to function.
  Start with the most fundamental ones.
-->
- **Note**: All dependencies are enhanced VOLO datadef packages (copied from ProbeHero8)
-  **Probe_Config_pkg_PH9.vhd** - Enhanced probe configuration data types and constants - **Units**: package (VHDL package)
-  **Global_Probe_Table_pkg_PH9.vhd** - Enhanced global probe definitions and validation - **Units**: package (VHDL package)
-  **Moku_Voltage_pkg_PH9.vhd** - Enhanced voltage conversion utilities for MCC platform - **Units**: package (VHDL package)
-  **PercentLut_pkg_PH9.vhd** - Enhanced percentage-based lookup table utilities - **Units**: package (VHDL package)

## 🎛️ Control Interface

### Standard Control Signals
<!-- 
  TIP: Most VOLO modules use these standard control signals.
  Remove any that don't apply to your module.
-->
- **Implementation**: Follows standard VOLO control signal patterns
-  **reset** - Active low reset signal (n_reset or reset_n) - **Units**: signal (control signal)
-  **enable** - Module enable/disable control - **Units**: signal (control signal)
-  **clk** - Primary clock input - **Units**: signal (clock signal)
-  **clk_en** - Clock enable signal - **Units**: signal (control signal)

### Custom Control Signals
<!-- 
  TIP: Add any module-specific control signals here.
  Use descriptive names with ctrl_ prefix for clarity.
-->
-  **trig_in** - Trigger input signal (rising edge triggers firing sequence) - **Units**: signal (trigger input)

## ⚙️ Configuration Interface

### Configuration Parameters
<!-- 
  TIP: These are the parameters that configure how your module operates.
  Use cfg_ prefix for configuration signals.
  Be specific about types, ranges, and validation requirements.
-->

#### probe_selector_index_in
- **Type**: std_logic_vector
- **Width**: 2 bits
- **Units**: index (table selector)
- **Purpose**: Selects which probe configuration to use from the global probe table
- **Validation**: Must be valid index into Global_Probe_Table (use their validation functions)
- **Default**: 0 (first probe in table)

#### intensity_index_in
- **Type**: std_logic_vector
- **Width**: 7 bits
- **Units**: index (LUT table index)
- **Purpose**: Index into PercentLut for intensity scaling (0-127 range)
- **Validation**: Must be valid PercentLut index (use PercentLut validation functions)
- **Default**: 5 (5% intensity)

#### fire_duration_in
- **Type**: unsigned
- **Width**: 16 bits
- **Units**: clks (clock cycles)
- **Purpose**: How long to keep intensity_out and trigger_out high when firing
- **Validation**: Will be clamped to probe config min/max limits, sets ALARM if clamped
- **Default**: 0 (no duration)

#### cooldown_duration_in
- **Type**: unsigned
- **Width**: 16 bits
- **Units**: clks (clock cycles)
- **Purpose**: How long to stay in COOLING state after firing completes
- **Validation**:Will be clamped to probe config min/max limits, sets ALARM if clamped
- **Default**: 1000 (configurable cooling period)

<!-- 
  TIP: Copy the above block for each configuration parameter.
  Consider grouping related parameters together.
-->

## 📤 Output Interface

### Primary Outputs
<!-- 
  TIP: These are the main outputs your module produces.
  Be specific about types, timing, and any constraints.
-->

#### trigger_out
- **Type**: signed
- **Width**: 16 bits
- **Units**: volts (voltage output)
- **Purpose**: Voltage value to drive the probe's trigger input
- **Timing**: Valid when module is firing (FIRING state)
- **Constraints**: Should be equal to  probe_config.probe_trigger_voltage while firing - zero otherwise

#### intensity_out
- **Type**: signed
- **Width**: 16 bits
- **Units**: volts (voltage output)
- **Purpose**: Voltage value to drive the probe's intensity input
- **Timing**: Valid when module is firing (FIRING state)
- **Constraints**: Clamped to probe_intensity_min/max, sets ALARM if clamped

### Status Output register
<!-- 
  TIP: Most VOLO modules include a status register.
  Define the bit meanings clearly.
-->

#### probe_status_out
- **Width**: 8-bit (standard VOLO convention)
- **Units**: bits (status register)
- **Implementation**: Follows standard VOLO status register patterns
- **Bit Definitions**:
  - **Bit 7**: FAULT - Fault condition (standard VOLO convention)
  - **Bit 6**: ALARM - Alarm/warning condition (set on validation failures)
  - **Bit 5**: RESERVED - Reserved for future use
  - **Bit 4**: RESERVED - Reserved for future use
  - **Bit 3**: COOL - Cooling status (probe is cooling down)
  - **Bit 2**: FIRED - Fired status (sticky bit, cleared on reset or new fire command)
  - **Bit 1**: FIRING - Currently firing (active during firing sequence)
  - **Bit 0**: ARMED - Module enabled (reflects enable status)

## ✅ Validation Requirements

### Input Validation
<!-- 
  TIP: List all validation rules for inputs.
  Be specific about what constitutes valid vs invalid.
  Consider edge cases and boundary conditions.
-->
- **probe_selector_index_in**: Must be valid Global_Probe_Table index (use their validation functions)
- **intensity_index_in**: Must be valid PercentLut index  (use PercentLut validation functions)
- **fire_duration_in**: Will be clamped to probe config limits, sets ALARM if clamping occurs
- **cooldown_duration_in**: Will be clamped to probe config limits, sets ALARM if clamping occurs
- **trig_in**: Rising edge detection only when module is enabled

### Output Validation
<!-- 
  TIP: List any constraints on outputs.
  Consider safety limits, timing requirements, etc.
-->
- **trigger_out**: Never exceed probe_config.probe_trigger_voltage
- **intensity_out**: Clamped to probe_intensity_min/max, sets ALARM if clamping needed

### Error Handling
<!-- 
  TIP: How should the module behave when validation fails?
  Consider status register updates, safe states, etc.
-->
- **Invalid input**: Set appropriate status bits, enter safe state
- **Output constraint violation**: Clamp outputs to valid range, set ALARM bit
- **Invalid trigger**: Ignore trig_in when not ARMED or when in COOLING state

## 🔄 State Machine Requirements

### Default States
<!-- 
  TIP: If your module has states, define them here.
  Use std_logic_vector encoding for Verilog compatibility.
  Consider using constants for state names.
-->
- **IDLE_STATE**: Waiting for trigger, outputs at safe levels, module disabled
- **ARMED_STATE**: Module enabled, waiting for trigger, outputs at safe levels
- **FIRING_STATE**: Actively driving outputs with configured values
- **COOLING_STATE**: Probe is cooling down after firing
- **HARDFAULT_STATE**: Fatal error detected. Driver halts until reset.

### State Transitions
<!-- 
  TIP: Define what triggers state changes.
  Be specific about conditions and timing.
-->
- **IDLE → ARMED**: enable signal goes high
- **ARMED → FIRING**: trig_in rising edge detected. 
- **FIRING → COOLING**: Fire duration timer expired
- **COOLING → IDLE**: Cooling period completed
- **Any → HARDFAULT_STATE**: Validation failure or fault condition

### State Machine Behavior
- **Output Timing**: Outputs change immediately when entering FIRING state, held constant during fire duration
- **Safe Outputs**: All outputs at safe levels (typically 0) except during FIRING state
- **Status Updates**: Status register updated on every state transition
- **Sticky Bits**: FIRED bit set when entering FIRING state, cleared on reset or new fire command
- **Implementation**: Status register follows standard VOLO patterns (synchronous updates, proper bit behavior)

## 📝 Implementation Notes

### Design Philosophy
<!-- 
  TIP: Document any design decisions or constraints.
  This helps future developers understand the reasoning.
-->
- Interface-first approach - define contract before implementation
- Safety first - always clamp outputs to valid ranges
- Status-driven design - clear visibility into module state
- Simple state machine - avoid complex logic in favor of clarity
- Edge-triggered firing - rising edge of trig_in initiates firing sequence

### Expected Outputs
<!-- 
  TIP: What should this requirements document enable?
  Be specific about deliverables.
-->
This interface definition should enable generation of:
- [ ] Core entity block with enhanced error handling
- [ ] Core testbench to validate inputs and error conditions
- [ ] Common/ module_constants_pkg.vhd with ProbeHero9-specific constants
- [ ] Enhanced state machine with improved error recovery
- [ ] Comprehensive test coverage for all error conditions

### Next Phase
<!-- 
  TIP: What comes after interface definition?
  This helps maintain workflow continuity.
-->
- [ ] Analyze ProbeHero8 implementation for enhancement opportunities
- [ ] Define specific ProbeHero9 enhancements and improvements
- [ ] Core VHDL entity block with enhanced features
- [ ] Internal logic design (enhanced state machine implementation)
- [ ] Detailed implementation (timing, edge cases, error handling)
- [ ] Comprehensive testbench development (validation testing, error scenarios)

## 🔍 Questions for Clarification

<!-- 
  TIP: List any questions that need answers before proceeding.
  This helps identify missing requirements early.
-->
- **RESOLVED**: What should happen if probe_selector_index_in is invalid? 
  - **Answer**: Enter HARDFAULT_STATE and halt operation until reset


## 📚 See Also

<!-- 
  TIP: Link to related documents, standards, or examples.
  This helps maintain documentation consistency.
-->
- **Source Requirements**: `ai-workflow/examples/ProbeHero7/PH7-interface-reqs-r2.md`
- **Enhanced Packages**: `modules/probe_hero9/datadef/` (ProbeHero8 enhanced versions)
- **ProbeHero8 Implementation**: `modules/probe_hero8/` (reference implementation)
- **VOLO Standards**: `ai-workflow/ng/` (development guidelines)
- **ProbeHero9 Development**: `modules/probe_hero9/development/` (development process)

<!-- End of requirements refined from PH7-interface-reqs.md -->
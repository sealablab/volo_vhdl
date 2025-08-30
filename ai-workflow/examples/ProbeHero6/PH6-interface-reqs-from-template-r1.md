# ProbeHero6 Interface Requirements

## 🎯 Module Overview
**ProbeHero6 is a VHDL module designed to drive various SCA and FI probes. Conceptually it's similar to a simple signal generator that can fire probes with configurable intensity and duration.**

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
- [x] **Probe_Config_pkg.vhd** - Probe configuration data types and constants
- [x] **Global_Probe_Table_pkg.vhd** - Global probe definitions and validation
- [x] **Moku_Voltage_pkg.vhd** - Voltage conversion utilities for MCC platform
- [x] **PercentLut_pkg.vhd** - Percentage-based lookup table utilities
- [x] **clk_divider_core.vhd** - Clock division functionality for timing control

## 🎛️ Control Interface

### Standard Control Signals
<!-- 
  TIP: Most VOLO modules use these standard control signals.
  Remove any that don't apply to your module.
-->
- [x] **n_reset** - Active low reset signal
- [x] **enable** - Module enable/disable control (sets ARMED status)
- [x] **clk** - Primary clock input
- [x] **clk_en** - Clock enable signal

### Custom Control Signals
<!-- 
  TIP: Add any module-specific control signals here.
  Use descriptive names with ctrl_ prefix for clarity.
-->
- [x] **trig_in** - Trigger input signal (rising edge triggers firing sequence)

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
- **Purpose**: Selects which probe configuration to use from the global probe table
- **Validation**: Must be valid index into Global_Probe_Table (use their validation functions)
- **Default**: 0 (first probe in table)

#### intensity_index_in
- **Type**: std_logic_vector
- **Width**: 7 bits
- **Purpose**: Index into PercentLut for intensity scaling (0-127 range)
- **Validation**: Must be valid PercentLut index (use PercentLut validation functions)
- **Default**: 0 (0% intensity)

#### duration_in
- **Type**: unsigned
- **Width**: 16 bits
- **Purpose**: How long to keep intensity_out and trigger_out high when firing
- **Validation**: Will be clamped to probe config min/max limits, sets ALARM if clamped
- **Default**: 0 (no duration)

#### cooling_duration_in
- **Type**: unsigned
- **Width**: 16 bits
- **Purpose**: How long to stay in COOLING state after firing completes
- **Validation**: Must be > 0, clamped to reasonable maximum (e.g., 65535)
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
- **Purpose**: Voltage value to drive the probe's trigger input
- **Timing**: Valid when module is firing (FIRING state)
- **Constraints**: Never exceed probe_config.probe_trigger_voltage

#### intensity_out
- **Type**: signed
- **Width**: 16 bits
- **Purpose**: Voltage value to drive the probe's intensity input
- **Timing**: Valid when module is firing (FIRING state)
- **Constraints**: Clamped to probe_intensity_min/max, sets ALARM if clamped

### Status Outputs
<!-- 
  TIP: Most VOLO modules include a status register.
  Define the bit meanings clearly.
-->

#### probe_status_out
- **Width**: 8-bit (standard convention)
- **Bit Definitions**:
  - **Bit 7**: FAULT - Fault condition (standard convention)
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
- **intensity_index_in**: Must be valid PercentLut index 0-127 (use PercentLut validation functions)
- **duration_in**: Will be clamped to probe config limits, sets ALARM if clamping occurs
- **cooling_duration_in**: Must be > 0, clamped to maximum 65535, sets ALARM if clamped
- **trig_in**: Rising edge detection only when module is ARMED and not in COOLING state

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

### States
<!-- 
  TIP: If your module has states, define them here.
  Use std_logic_vector encoding for Verilog compatibility.
  Consider using constants for state names.
-->
- **IDLE_STATE**: Waiting for trigger, outputs at safe levels, module disabled
- **ARMED_STATE**: Module enabled, waiting for trigger, outputs at safe levels
- **FIRING_STATE**: Actively driving outputs with configured values
- **COOLING_STATE**: Probe is cooling down after firing
- **ERROR_STATE**: Error condition, outputs safe, status bits set

### State Transitions
<!-- 
  TIP: Define what triggers state changes.
  Be specific about conditions and timing.
-->
- **IDLE → ARMED**: enable signal goes high
- **ARMED → IDLE**: enable signal goes low
- **ARMED → FIRING**: trig_in rising edge detected and module ARMED
- **FIRING → COOLING**: Duration timer expired
- **COOLING → ARMED**: Cooling period completed and module still enabled
- **COOLING → IDLE**: Cooling period completed and module disabled
- **Any → ERROR**: Validation failure or fault condition

### State Machine Behavior
- **Output Timing**: Outputs change immediately when entering FIRING state, held constant during firing duration
- **Safe Outputs**: All outputs at safe levels (typically 0) except during FIRING state
- **Status Updates**: Status register updated on every state transition
- **Sticky Bits**: FIRED bit set when entering FIRING state, cleared on reset or new fire command

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

### Clock Divider Usage
- **Purpose**: Used for timing control of firing duration and cooling period
- **Implementation**: Create configurable clock enables for duration and cooling timers
- **Integration**: Use clk_divider_core to generate appropriate timing signals

### Expected Outputs
<!-- 
  TIP: What should this requirements document enable?
  Be specific about deliverables.
-->
This interface definition should enable generation of:
- [x] Basic probe_driver_core entity block
- [x] Basic testbench structure
- [x] Port validation logic
- [x] Status register implementation
- [x] State machine implementation with proper timing

### Next Phase
<!-- 
  TIP: What comes after interface definition?
  This helps maintain workflow continuity.
-->
- [x] Functional requirements specification (how the firing sequence works)
- [ ] Internal logic design (state machine implementation)
- [ ] Detailed implementation (timing, edge cases)
- [ ] Testbench development (validation testing)

## 🔍 Questions for Clarification

<!-- 
  TIP: List any questions that need answers before proceeding.
  This helps identify missing requirements early.
-->
- [x] What should happen if probe_selector_index_in is invalid? Enter error state?
- [x] How long should the COOLING state last? Is this probe-specific? → Added cooling_duration_in parameter
- [x] Should there be a maximum firing frequency limit? → Handled by cooling state
- [x] What triggers the FIRED sticky bit to clear? Manual reset or automatic? → Cleared on reset or new fire command
- [x] What is the trigger mechanism? → trig_in rising edge when ARMED
- [x] How does the ARMED state work? → Set when enable is high

## 📚 See Also

<!-- 
  TIP: Link to related documents, standards, or examples.
  This helps maintain documentation consistency.
-->
- [[VOLO-codes-workflow|VOLO-codes-workflow]]
- [[ProbeHero6-functional-reqs|ProbeHero6 Functional Requirements]]
- [[Probe_Config_pkg|Probe Configuration Package]]
- [[Global_Probe_Table_pkg|Global Probe Table Package]]

<!-- End of requirements refined from PH6-interface-reqs-from-template.md -->
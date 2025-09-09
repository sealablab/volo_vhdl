# ProbeHero10 Interface Requirements

## 🎯 Module Overview
**ProbeHero10 is a voltage-controlled probe firing system that manages probe selection, intensity control, and firing sequences with comprehensive safety validation and status reporting.**

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
- [x] **volo_common_pkg.vhd** - Standard state machine states and global constants
- [x] **Probe_Config_pkg_PH10.vhd** - Probe configuration data types and constants
- [x] **Global_Probe_Table_pkg_PH10.vhd** - Global probe definitions and validation
- [x] **Moku_Voltage_pkg_PH10.vhd** - Voltage conversion utilities for MCC platform
- [x] **PercentLut_pkg_PH10.vhd** - Percentage-based lookup table utilities

### Optional Dependencies
<!-- 
  TIP: These are packages/modules that enhance functionality but aren't required.
  Remove this section if not needed.
-->
- None required for basic functionality

## 🎛️ Control Interface

### Standard Control Signals
<!-- 
  TIP: Most VOLO modules use these standard control signals.
  Remove any that don't apply to your module.
-->
- [x] **reset_n** - Active low reset signal (Units: signal)
- [x] **enable** - Module enable/disable control (Units: signal)
- [x] **clk** - Primary clock input (Units: signal)
- [x] **clk_en** - Clock enable signal (Units: signal)

### Custom Control Signals
<!-- 
  TIP: Add any module-specific control signals here.
  Use descriptive names with ctrl_ prefix for clarity.
-->
- [x] **trig_in** - Trigger input signal for probe firing (Units: signal)

## ⚙️ Configuration Interface

### Configuration Parameters
<!-- 
  TIP: These are the parameters that configure how your module operates.
  Use cfg_ prefix for configuration signals.
  Be specific about types, ranges, and validation requirements.
-->

#### probe_selector_index_in
- **Type**: std_logic_vector
- **Width**: 2 bits (PROBE_SELECTOR_WIDTH)
- **Purpose**: Selects which probe configuration to use from the global probe table
- **Validation**: Must be within valid probe table range (0-3)
- **Default**: "00" (first probe)
- **Units**: index

#### intensity_index_in
- **Type**: std_logic_vector
- **Width**: 7 bits (INTENSITY_INDEX_WIDTH)
- **Purpose**: Controls probe firing intensity via percentage lookup table
- **Validation**: Must be within valid intensity range (0-100)
- **Default**: "0000101" (5% intensity)
- **Units**: index

#### fire_duration_in
- **Type**: unsigned
- **Width**: 16 bits (DURATION_WIDTH)
- **Purpose**: Duration of probe firing in clock cycles
- **Validation**: Must be within probe-specific min/max limits
- **Default**: 0 (no duration)
- **Units**: clks

#### cooldown_duration_in
- **Type**: unsigned
- **Width**: 16 bits (DURATION_WIDTH)
- **Purpose**: Cooldown period between firings in clock cycles
- **Validation**: Must be within probe-specific min/max limits
- **Default**: 1000 (1000 cycles)
- **Units**: clks

## 📤 Output Interface

### Primary Outputs
<!-- 
  TIP: These are the main outputs your module produces.
  Be specific about types, timing, and any constraints.
-->

#### trigger_out
- **Type**: signed
- **Width**: 16 bits (VOLTAGE_OUTPUT_WIDTH)
- **Purpose**: Trigger voltage output for probe firing
- **Timing**: Active when in IDLE state and user logic determines firing
- **Constraints**: Must use GLOBAL_VOLTAGE_ZERO when not active
- **Units**: volts

#### intensity_out
- **Type**: signed
- **Width**: 16 bits (VOLTAGE_OUTPUT_WIDTH)
- **Purpose**: Intensity voltage output for probe firing
- **Timing**: Active when in IDLE state and user logic determines firing
- **Constraints**: Must use GLOBAL_VOLTAGE_ZERO when not active
- **Units**: volts

### Status Outputs
<!-- 
  TIP: Most VOLO modules include a status register.
  Define the bit meanings clearly.
-->

#### probe_status_out
- **Width**: 8 bits (STATUS_REGISTER_WIDTH)
- **Bit Definitions**:
  - **Bit 7**: FAULT - Fault condition (standard convention)
  - **Bit 6**: ALARM - Alarm/warning condition (validation failure)
  - **Bit 5**: RESERVED - Reserved for future use
  - **Bit 4**: READY - Ready state (parameters validated)
  - **Bit 3**: RESERVED - Reserved for future use
  - **Bit 2**: RESERVED - Reserved for future use
  - **Bit 1**: RESERVED - Reserved for future use
  - **Bit 0**: IDLE - Idle state (user implementation active)

## ✅ Validation Requirements

### Input Validation
<!-- 
  TIP: List all validation rules for inputs.
  Be specific about what constitutes valid vs invalid.
  Consider edge cases and boundary conditions.
-->
- **probe_selector_index_in**: Must be within valid probe table range (0-3), checked via is_valid_probe_selector()
- **intensity_index_in**: Must be within valid intensity range (0-100), checked via is_valid_intensity_index()
- **fire_duration_in**: Must be within probe-specific min/max limits, checked via is_valid_duration()
- **cooldown_duration_in**: Must be within probe-specific min/max limits, checked via is_valid_duration()

### Output Validation
<!-- 
  TIP: List any constraints on outputs.
  Consider safety limits, timing requirements, etc.
-->
- **trigger_out**: Must use GLOBAL_VOLTAGE_ZERO when not active, user controls when active
- **intensity_out**: Must use GLOBAL_VOLTAGE_ZERO when not active, user controls when active
- **probe_status_out**: Must follow standard status register format with proper bit assignments

### Error Handling
<!-- 
  TIP: How should the module behave when validation fails?
  Consider status register updates, safe states, etc.
-->
- **Invalid input**: Transition to STATE_FAULT, set ALARM bit, maintain safe output state
- **Output constraint violation**: Not applicable - outputs use global constants for safety

## 🔄 Core State Machine Requirements

### Required Core States (from volo_common_pkg)
<!-- 
  TIP: All VOLO modules must implement this standard state machine.
  These states are defined in volo_common_pkg and provide consistent behavior.
-->
- **STATE_RESET**: Parameter validation and initialization
- **STATE_READY**: Parameters validated, configuration loaded, ready for operation
- **STATE_IDLE**: User implementation pickup point (where your specific logic begins)
- **STATE_FAULT**: Validation failure state (only reset can exit)

### Core State Transitions
<!-- 
  TIP: These transitions are handled automatically by the core.
  You only need to define what triggers the READY → IDLE transition.
-->
- **RESET → READY**: All input parameters validate successfully (automatic)
- **READY → IDLE**: [Your trigger condition - e.g., enable signal, start command]
- **Any → FAULT**: Any parameter validation failure (automatic)
- **FAULT → RESET**: Reset signal assertion only (automatic)

### User Implementation Points
<!-- 
  TIP: Define what happens in the IDLE state and beyond.
  This is where your module-specific logic begins.
-->
- **IDLE State Logic**: User controls probe firing sequence, timing, and output activation
- **Output Control**: User determines when trigger_out and intensity_out are active based on firing logic
- **Timer Management**: User handles fire duration and cooldown timing control
- **Custom States**: User can add states for FIRING, COOLING, etc. beyond IDLE

### Output Behavior Requirements
<!-- 
  TIP: Define when outputs should be active vs. safe state.
  Core uses GLOBAL_VOLTAGE_ZERO for safe state.
-->
- **Default State**: All outputs use GLOBAL_VOLTAGE_ZERO when not active
- **Active Conditions**: trigger_out and intensity_out active when user logic determines firing should occur
- **User Control**: User logic in IDLE state controls when outputs are driven vs. safe state

## 📝 Implementation Notes

### Design Philosophy
<!-- 
  TIP: Document any design decisions or constraints.
  This helps future developers understand the reasoning.
-->
- Core provides infrastructure (validation, state management, safe outputs)
- User provides functionality (firing logic, timing control, output activation)
- Clear separation of concerns between core and user implementation
- Safety-first approach with global constants for safe states

### Expected Outputs
<!-- 
  TIP: What should this requirements document enable?
  Be specific about deliverables.
-->
This interface definition should enable generation of:
- [x] Basic probe_hero10_core entity block with core state machine
- [x] Basic testbench structure for core functionality
- [x] Port validation logic for all inputs
- [x] Status register implementation with standard bits
- [x] User implementation pickup point at IDLE state

### Next Phase
<!-- 
  TIP: What comes after interface definition?
  This helps maintain workflow continuity.
-->
- [x] Core state machine implementation (RESET → READY → IDLE → FAULT)
- [ ] User-specific firing logic implementation in IDLE state
- [ ] Timer management for fire/cooldown durations
- [ ] Custom state machine for firing sequences
- [ ] Comprehensive testbench development

## 🔍 Questions for Clarification

<!-- 
  TIP: List any questions that need answers before proceeding.
  This helps identify missing requirements early.
-->
- [x] All requirements are clear and complete
- [x] Core state machine behavior is well-defined
- [x] User implementation points are clearly specified
- [x] Validation rules are comprehensive

## 📚 See Also

<!-- 
  TIP: Link to related documents, standards, or examples.
  This helps maintain documentation consistency.
-->
- **@ai-workflow/ng/README-CORE-STATE-MACHINE-STANDARD-ng.md** - Core state machine standard
- **@modules/probe_hero9/core/probe_hero9_core.vhd** - Reference implementation
- **@modules/volo_common/common/volo_common_pkg.vhd** - Standard constants and states
- **@ai-workflow/templates/state_machine_base/core_state_machine_template.vhd** - Implementation template

---

<!-- 
  TIP: This template is designed to be:
  1. Easy for humans to fill out
  2. Structured for AI agents to parse
  3. Comprehensive enough for implementation
  4. Flexible enough for different module types
  
  Feel free to modify sections based on your specific needs.
  Remove sections that don't apply to your module.
-->

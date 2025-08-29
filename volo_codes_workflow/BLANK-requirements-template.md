# [MODULE_NAME] Interface Requirements

## 🎯 Module Overview
**Brief description of what this module does and its purpose in the system.**

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
- [ ] **Probe_Config_pkg.vhd** - Probe configuration data types and constants
- [ ] **Global_Probe_Table_pkg.vhd** - Global probe definitions and validation
- [ ] **Moku_Voltage_pkg.vhd** - Voltage conversion utilities for MCC platform
- [ ] **PercentLut_pkg.vhd** - Percentage-based lookup table utilities
- [ ] **clk_divider_core.vhd** - Clock division functionality

### Optional Dependencies
<!-- 
  TIP: These are packages/modules that enhance functionality but aren't required.
  Remove this section if not needed.
-->
- [ ] **Additional package** - What it provides

## 🎛️ Control Interface

### Standard Control Signals
<!-- 
  TIP: Most VOLO modules use these standard control signals.
  Remove any that don't apply to your module.
-->
- [ ] **n_reset** - Active low reset signal
- [ ] **enable** - Module enable/disable control
- [ ] **clk** - Primary clock input
- [ ] **clk_en** - Clock enable signal

### Custom Control Signals
<!-- 
  TIP: Add any module-specific control signals here.
  Use descriptive names with ctrl_ prefix for clarity.
-->
- [ ] **ctrl_signal_name** - Description of what this control does

## ⚙️ Configuration Interface

### Configuration Parameters
<!-- 
  TIP: These are the parameters that configure how your module operates.
  Use cfg_ prefix for configuration signals.
  Be specific about types, ranges, and validation requirements.
-->

#### parameter_name
- **Type**: [std_logic_vector/unsigned/signed/natural/integer]
- **Width**: [bit width if applicable]
- **Purpose**: [What this parameter controls]
- **Validation**: [How to validate this input]
- **Default**: [Default value if applicable]

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

#### output_name
- **Type**: [std_logic_vector/unsigned/signed]
- **Width**: [bit width]
- **Purpose**: [What this output represents]
- **Timing**: [When this output is valid/updated]
- **Constraints**: [Any limits or validation rules]

### Status Outputs
<!-- 
  TIP: Most VOLO modules include a status register.
  Define the bit meanings clearly.
-->

#### status_register_name
- **Width**: [8-bit recommended for consistency]
- **Bit Definitions**:
  - **Bit 7**: FAULT - Fault condition (standard convention)
  - **Bit 6**: ALARM - Alarm/warning condition
  - **Bit 5**: RESERVED - Reserved for future use
  - **Bit 4**: RESERVED - Reserved for future use
  - **Bit 3**: STATUS_3 - Description of this status bit
  - **Bit 2**: STATUS_2 - Description of this status bit
  - **Bit 1**: STATUS_1 - Description of this status bit
  - **Bit 0**: STATUS_0 - Description of this status bit

## ✅ Validation Requirements

### Input Validation
<!-- 
  TIP: List all validation rules for inputs.
  Be specific about what constitutes valid vs invalid.
  Consider edge cases and boundary conditions.
-->
- **parameter_name**: [Validation rule description]
- **parameter_name**: [Validation rule description]

### Output Validation
<!-- 
  TIP: List any constraints on outputs.
  Consider safety limits, timing requirements, etc.
-->
- **output_name**: [Validation rule description]
- **output_name**: [Validation rule description]

### Error Handling
<!-- 
  TIP: How should the module behave when validation fails?
  Consider status register updates, safe states, etc.
-->
- **Invalid input**: [What happens when input validation fails]
- **Output constraint violation**: [What happens when output constraints can't be met]

## 🔄 State Machine Requirements

### States
<!-- 
  TIP: If your module has states, define them here.
  Use std_logic_vector encoding for Verilog compatibility.
  Consider using constants for state names.
-->
- **IDLE_STATE**: [Description of idle behavior]
- **ACTIVE_STATE**: [Description of active behavior]
- **ERROR_STATE**: [Description of error handling]

### State Transitions
<!-- 
  TIP: Define what triggers state changes.
  Be specific about conditions and timing.
-->
- **IDLE → ACTIVE**: [Trigger condition]
- **ACTIVE → IDLE**: [Trigger condition]
- **Any → ERROR**: [Error conditions]

## 📝 Implementation Notes

### Design Philosophy
<!-- 
  TIP: Document any design decisions or constraints.
  This helps future developers understand the reasoning.
-->
- [Design principle or constraint]

### Expected Outputs
<!-- 
  TIP: What should this requirements document enable?
  Be specific about deliverables.
-->
This interface definition should enable generation of:
- [ ] Basic [module_name]_core entity block
- [ ] Basic testbench structure
- [ ] Port validation logic
- [ ] Status register implementation

### Next Phase
<!-- 
  TIP: What comes after interface definition?
  This helps maintain workflow continuity.
-->
- [ ] Functional requirements specification
- [ ] Internal logic design
- [ ] Detailed implementation
- [ ] Testbench development

## 🔍 Questions for Clarification

<!-- 
  TIP: List any questions that need answers before proceeding.
  This helps identify missing requirements early.
-->
- [ ] Question about requirement or constraint
- [ ] Question about interface behavior
- [ ] Question about validation rules

## 📚 See Also

<!-- 
  TIP: Link to related documents, standards, or examples.
  This helps maintain documentation consistency.
-->
- [[VOLO-codes-workflow|VOLO-codes-workflow]]
- [Related module or package documentation]
- [Relevant standards or specifications]

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

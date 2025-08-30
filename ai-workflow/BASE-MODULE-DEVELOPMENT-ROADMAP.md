# Base Module Development Roadmap

## 🎯 **Project Overview**
**Base Module** is the invisible foundation template that provides guaranteed minimal functionality for all VOLO VHDL modules. It serves as the starting point for generating specific modules (like the stoplight) without users ever seeing the underlying template.

## 🚀 **Why Base Module Now?**

### **Foundation Requirements:**
✅ **Guaranteed minimal functionality** - compiles and simulates from day one  
✅ **Standard VOLO patterns** - state machine, status register, validation  
✅ **Invisible to users** - they start from interface requirements, not templates  
✅ **Builds into anything** - stoplight, ProbeHero, or any future module  

### **Learning Objectives:**
- **Validate the template approach** - prove invisible foundation works
- **Test enhanced package integration** - ensure packages work with base template
- **Create generation workflow** - interface requirements → working module
- **Establish development patterns** - consistent foundation for all modules

## 📋 **Implementation Roadmap**

### **Phase 1: Base Module Core Development**
**Goal:** Create the invisible foundation with guaranteed minimal functionality

#### **1.1 Base Entity Structure**
- [ ] Create `ai-workflow/templates/base/base_core.vhd`
- [ ] Implement generic interface:
  - Standard control signals (clk, rst_n, enable, clk_en)
  - Generic configuration input (cfg_param_in)
  - Generic output (data_out)
  - Standard status register (stat_status_out)
- [ ] Use generic state machine template
- [ ] Implement proper port validation and error handling

#### **1.2 Generic State Machine Implementation**
- [ ] **4 Generic States** (can be renamed to anything):
  - **RESET_STATE** - Module reset, safe outputs
  - **READY_STATE** - Module ready, waiting for enable
  - **IDLE_STATE** - Module enabled, waiting for operation
  - **HARD_FAULT_STATE** - Non-recoverable error state
- [ ] **State Encoding**: `std_logic_vector(1 downto 0)` for Verilog compatibility
- [ ] **State Transitions**: Simple, predictable flow
- [ ] **Timer Logic**: Generic countdown mechanism for state transitions

#### **1.3 Status Register Design**
- [ ] **8-bit Status Register** following VOLO convention
- [ ] **Auto-exposed State Bits**:
  - Bit 3: HARD_FAULT active
  - Bit 2: IDLE active  
  - Bit 1: READY active
  - Bit 0: RESET active (ARMED)
- [ ] **Reserved Bits** (4-7) for future expansion
- [ ] **Real-time Updates** on every state change

#### **1.4 Alarm Status Bit Implementation**
- [ ] **Contrived Alarm Reason**: Timer-based warning system
- [ ] **Alarm Logic**: Set ALARM bit when countdown ≤ threshold
- [ ] **Recoverable Warning**: Module continues operation, just warns
- [ ] **Status Register Integration**: ALARM bit in status register

#### **1.5 Generic Parameter Validation**
- [ ] **Input Validation Framework**: Generic validation patterns
- [ ] **Parameter Clamping**: Safe defaults when validation fails
- [ ] **Error Reporting**: Status register updates for validation failures
- [ ] **Safe Operation**: Module enters safe state on validation failure

### **Phase 2: Base Module Testbench Development**
**Goal:** Validate base functionality with comprehensive testing

#### **2.1 Testbench Structure**
- [ ] Create `ai-workflow/templates/base/base_core_tb.vhd`
- [ ] Follow layer-organized testbench structure
- [ ] Use direct instantiation for consistency
- [ ] Implement comprehensive test coverage

#### **2.2 Reset Stub Testing**
- [ ] **Reset Behavior Tests**:
  - Active low reset functionality
  - State machine reset to RESET_STATE
  - Output reset to safe values
  - Status register reset
- [ ] **Reset Recovery Tests**:
  - Normal operation after reset
  - State transitions after reset
  - Status register updates after reset

#### **2.3 Input Parameter Validation Testing**
- [ ] **Valid Parameter Tests**:
  - Normal parameter ranges
  - State transitions with valid parameters
  - Status register updates
- [ ] **Invalid Parameter Tests**:
  - Parameter clamping behavior
  - ALARM bit setting
  - Safe state operation
  - Error recovery

#### **2.4 State Machine Testing**
- [ ] **State Transition Tests**:
  - RESET → READY → IDLE flow
  - HARD_FAULT entry conditions
  - State machine timing
  - Status register state bits
- [ ] **Timer Logic Tests**:
  - Countdown functionality
  - State transition timing
  - ALARM generation timing

#### **2.5 GHDL Validation**
- [ ] Compile with `ghdl --std=08`
- [ ] Run all tests to completion
- [ ] Verify deterministic results
- [ ] Ensure proper error reporting

### **Phase 3: Enhanced Package Integration**
**Goal:** Ensure base module works seamlessly with enhanced packages

#### **3.1 Package Import Testing**
- [ ] Test base module with enhanced packages
- [ ] Validate package integration
- [ ] Test enhanced validation functions
- [ ] Verify error handling patterns

#### **3.2 Validation Function Testing**
- [ ] Test enhanced package validation
- [ ] Verify error reporting integration
- [ ] Test safe default handling
- [ ] Validate status register updates

### **Phase 4: Generation Workflow Validation**
**Goal:** Prove the invisible foundation approach works

#### **4.1 Template Validation**
- [ ] Verify base template compiles and simulates
- [ ] Test all state machine functionality
- [ ] Validate status register behavior
- [ ] Confirm parameter validation works

#### **4.2 Generation Readiness**
- [ ] Base template ready for customization
- [ ] Generation workflow defined
- [ ] Interface requirements template ready
- [ ] Stoplight generation plan ready

## 🔧 **Technical Requirements**

### **VHDL-2008 with Verilog Portability**
- [ ] Use `std_logic` and `std_logic_vector` types
- [ ] Implement FSMs with `std_logic_vector` state encoding
- [ ] Use constants for state labels (no enums)
- [ ] Avoid VHDL-only features

### **Generic Foundation Design**
- [ ] **No functional assumptions** - completely generic
- [ ] **Standard patterns** - state machine, status register, validation
- [ ] **Extensible structure** - easy to customize for specific needs
- [ ] **Proven foundation** - guaranteed to work

### **Enhanced Package Integration**
- [ ] Import subset of enhanced packages
- [ ] Use enhanced validation functions
- [ ] Implement proper error handling patterns
- [ ] Leverage improved utility functions

## 📁 **File Structure**
```
ai-workflow/templates/base/
├── base_core.vhd              # Main entity and architecture
├── base_core_tb.vhd           # Comprehensive testbench
├── base_common_pkg.vhd         # Common constants and types
└── README.md                   # Template documentation
```

## 🎯 **Success Criteria**

### **Functional Requirements**
- [ ] All state transitions work correctly
- [ ] Status register updates properly
- [ ] ALARM bit functions as designed
- [ ] Parameter validation works correctly
- [ ] Reset functionality is robust

### **Technical Requirements**
- [ ] Compiles with GHDL without errors
- [ ] All tests pass consistently
- [ ] Enhanced packages integrate properly
- [ ] Verilog portability maintained
- [ ] Generic foundation is truly generic

### **Generation Readiness**
- [ ] Base template can be customized for any module
- [ ] Generation workflow is defined and tested
- [ ] Interface requirements can generate working modules
- [ ] Stoplight generation is ready to proceed

## 🚨 **Risk Mitigation**

### **Potential Challenges**
1. **Generic vs Specific Balance** - Template must be generic enough but functional enough
2. **Enhanced Package Integration** - Ensuring packages work with base template
3. **State Machine Complexity** - Keeping it simple but functional
4. **Generation Workflow** - Proving the invisible foundation approach works

### **Mitigation Strategies**
1. **Incremental Development** - Build and test each component thoroughly
2. **Comprehensive Testing** - Test all functionality before proceeding
3. **Package Testing** - Validate enhanced package integration early
4. **Documentation** - Document any deviations or discoveries

## 📅 **Timeline Estimate**

### **Day 1: Base Core Development**
- Morning: Entity structure and state machine
- Afternoon: Status register and alarm logic

### **Day 2: Base Testing**
- Morning: Testbench development
- Afternoon: Test execution and debugging

### **Day 3: Package Integration**
- Morning: Enhanced package integration
- Afternoon: Integration testing

### **Day 4: Generation Validation**
- Morning: Template validation
- Afternoon: Generation workflow preparation

## 🔍 **Next Phase Preparation**

### **Stoplight Generation Plan**
- [ ] Interface requirements document template
- [ ] Generation workflow definition
- [ ] Customization process documentation
- [ ] Testing and validation plan

### **Future Module Generation**
- [ ] Base template proven and documented
- [ ] Generation workflow established
- [ ] Interface requirements template ready
- [ ] Enhanced package integration validated

## 💡 **Key Benefits of This Approach**

- **Invisible foundation** - users never see the template complexity
- **Guaranteed functionality** - base template always works
- **Consistent patterns** - all modules follow same foundation
- **Rapid development** - interface requirements → working module
- **Quality assurance** - proven foundation reduces errors

---

**Ready to build the invisible foundation for VOLO VHDL development! 🚀**

*This roadmap creates the base module that will serve as the invisible foundation for generating all future modules, starting with the stoplight example.*

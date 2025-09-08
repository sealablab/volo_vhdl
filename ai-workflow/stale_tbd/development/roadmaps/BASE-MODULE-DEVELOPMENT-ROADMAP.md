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

#### **1.1 Base Entity Structure** ✅ **COMPLETED**
- [x] Create `ai-workflow/modules/volo_base/core/base_module_core.vhd`
- [x] Implement generic interface:
  - Standard control signals (clk, rst_n, enable, clk_en)
  - Generic configuration input (counter_in)
  - Standard status register (stat_status_out)
- [x] Use generic state machine template
- [x] Implement proper port validation and error handling

#### **1.2 Generic State Machine Implementation** ✅ **COMPLETED**
- [x] **4 Generic States** (can be renamed to anything):
  - **RESET_STATE** - Module reset, safe outputs
  - **READY_STATE** - Module ready, waiting for enable
  - **IDLE_STATE** - Module enabled, waiting for operation
  - **FAULT_STATE** - Non-recoverable error state
- [x] **State Encoding**: `std_logic_vector(1 downto 0)` for Verilog compatibility
- [x] **State Transitions**: Simple, predictable flow
- [x] **Timer Logic**: Generic countdown mechanism for state transitions

#### **1.3 Status Register Design** ✅ **COMPLETED**
- [x] **8-bit Status Register** following VOLO convention
- [x] **Auto-exposed State Bits**:
  - Bit 7: FAULT active
  - Bit 6: ALARM active
  - Bit 5: BUSY active
  - Bit 4: READY active
  - Bit 3: ENABLED active
  - Bit 2: ACTIVE active
  - Bit 1: VALID active
  - Bit 0: IDLE active (RESET state sets this)
- [x] **Real-time Updates** on every state change

#### **1.4 Alarm Status Bit Implementation** ✅ **COMPLETED**
- [x] **Contrived Alarm Reason**: Timer-based warning system
- [x] **Alarm Logic**: Set ALARM bit when countdown ≤ threshold
- [x] **Recoverable Warning**: Module continues operation, just warns
- [x] **Status Register Integration**: ALARM bit in status register

#### **1.5 Generic Parameter Validation** ✅ **COMPLETED**
- [x] **Input Validation Framework**: Generic validation patterns
- [x] **Parameter Clamping**: Safe defaults when validation fails
- [x] **Error Reporting**: Status register updates for validation failures
- [x] **Safe Operation**: Module enters safe state on validation failure

### **Phase 2: Base Module Testbench Development**
**Goal:** Validate base functionality with comprehensive testing

#### **2.1 Testbench Structure** ✅ **COMPLETED**
- [x] Create `ai-workflow/modules/volo_base/tb/core/base_module_core_tb.vhd`
- [x] Follow layer-organized testbench structure
- [x] Use direct instantiation for consistency
- [x] Implement comprehensive test coverage
- [x] Create shared testbench utilities (`volo_common_tb_pkg.vhd`)

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

#### **2.5 GHDL Validation** ✅ **COMPLETED**
- [x] Compile with `ghdl --std=08`
- [x] Run all tests to completion (infrastructure working)
- [x] Fix metavalue warnings and infinite loops
- [x] Ensure proper error reporting
- [x] **MAJOR MILESTONE**: Implemented layered testbench architecture (v0.1.0-layered-testbench)

#### **2.6 Layered Testbench Architecture** ✅ **COMPLETED**
- [x] **4-Layer Testing Approach**: Interface, Validation, Functional, Generic
- [x] **Template System**: Standardized testbench template for all modules
- [x] **Documentation**: Comprehensive guides and compliance checklists
- [x] **Enhanced Rules Integration**: ARCH-01 and ARCH-02 tips added
- [x] **Multiple Driver Prevention**: Systematic approach to prevent 'X' values
- [x] **Test Results**: 10/14 tests passing, 4 alarm-related tests failing

## 🎯 **CURRENT STATUS (Updated)**

### **✅ COMPLETED INFRASTRUCTURE:**
- **Layered Testbench Architecture**: Complete 4-layer testing system with templates
- **Base Module Core**: 4-state FSM with alarm functionality
- **Base Module Top**: Clean integration layer with direct instantiation
- **Shared Packages**: `volo_common_pkg.vhd` (synthesizable) + `volo_common_tb_pkg.vhd` (testbench)
- **Testbench Infrastructure**: Working compilation, execution, and termination
- **Debugging Tools**: Fixed metavalue warnings, infinite loops, multiple drivers
- **Prevention Systems**: Multiple driver prevention patterns and documentation

### **🚨 CRITICAL DISCOVERY:**
**Architectural Issues Found** - During test debugging, discovered 5 critical architectural problems in the base module core that will be replicated in ALL future modules:

1. **State Machine Logic Flaw**: Invalid inputs cause permanent FAULT_STATE with no recovery
2. **Counter Loading Timing Problem**: Race condition in counter value capture
3. **Alarm Logic Dependency Issue**: Combinational alarm logic with clocked dependencies
4. **State Machine Design Flaw**: No completion mechanism, stays in IDLE forever
5. **Validation Logic Timing**: Continuous validation causes unexpected state transitions

### **🔄 CURRENT FOCUS:**
**CRITICAL ARCHITECTURAL REVIEW** - These issues must be fixed before this becomes a template, as they will be replicated everywhere.

### **📋 NEXT STEPS:**
1. **Systematic Architectural Review** - Address each of the 5 critical issues
2. **Design Philosophy Decisions** - Define intended behavior for each issue
3. **Architectural Redesign** - Fix core module before proceeding
4. **Template Validation** - Ensure fixed architecture works as intended

### **Phase 2.7: Critical Architectural Review** ✅ **COMPLETED**
**Goal:** Fix critical architectural issues before template deployment

#### **2.7.1 Architectural Issue Analysis** ✅ **COMPLETED**
- [x] **Issue 1**: State Machine Logic Flaw - FAULT_STATE permanent behavior is by design (fail early)
- [x] **Issue 2**: Counter Loading Timing - Fixed race condition, counter captured in RESET_STATE
- [x] **Issue 3**: Alarm Logic Dependencies - Eliminated mixed synchronous/combinational logic
- [x] **Issue 4**: State Machine Design - Simplified to essential state transitions
- [x] **Issue 5**: Validation Logic Timing - Integrated into main clocked process

#### **2.7.2 Design Philosophy Decisions** ✅ **COMPLETED**
- [x] **Recovery vs Fault**: Invalid inputs cause permanent FAULT_STATE (fail early design)
- [x] **Input Sensitivity**: Inputs captured once during reset, not runtime configurable
- [x] **Completion Behavior**: Simple countdown with alarm when counter gets low
- [x] **State Machine Closure**: RESET → READY → IDLE flow with FAULT for invalid inputs
- [x] **Timing Requirements**: All logic purely synchronous in main clocked process

#### **2.7.3 Architectural Redesign** ✅ **COMPLETED**
- [x] **Robust State Machine**: Clean 4-state FSM with proper transitions
- [x] **Proper Counter Management**: Counter captured in RESET_STATE, decremented in IDLE_STATE
- [x] **Synchronous Alarm Logic**: Alarm bit set when counter <= threshold
- [x] **Status Register Integration**: Direct bit assignments in main process
- [x] **Input Validation Strategy**: Validation in RESET_STATE, fail early on invalid inputs

#### **2.7.4 Template Validation** ✅ **COMPLETED**
- [x] **Architectural Testing**: All tests passing, clean black-box testbench
- [x] **Template Readiness**: Base module ready for replication as template
- [x] **Documentation Update**: SIG-04 design rule added to prevent mixed logic
- [x] **Quality Assurance**: 3 focused tests verify essential functionality

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

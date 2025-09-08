# ProbeHero8 Implementation Plan

## 🚨 **GIT WORKFLOW - READ BEFORE STARTING!**

### **Initial Setup (Do This First!)**
```bash
# 1. Sync with main branch
git checkout main
git pull origin main

# 2. Create feature branch for ProbeHero8 development
git checkout -b feature/probehero8-implementation

# 3. Verify you're on the feature branch
git branch
# Should show: * feature/probehero8-implementation
```

### **Daily Workflow**
```bash
# Start of day: Sync feature branch with main
git checkout main
git pull origin main
git checkout feature/probehero8-implementation
git merge main

# End of day: Commit progress
git add .
git commit -m "ProbeHero8: [describe what was accomplished]"
git push origin feature/probehero8-implementation
```

### **When Ready to Merge**
```bash
# Create pull request from feature branch to main
# After approval and merge, clean up:
git checkout main
git pull origin main
git branch -d feature/probehero8-implementation
git push origin --delete feature/probehero8-implementation
```

---

## 🎯 **Project Overview**
**ProbeHero8** is the enhanced version of ProbeHero7, leveraging all the enhanced datadef packages, state machine templates, and validation infrastructure we've built. This will serve as a comprehensive test of our enhanced development workflow.

## 🚀 **Why ProbeHero8 Now?**

### **Infrastructure Ready:**
✅ **Enhanced datadef packages** - All packages now have proper validation, error handling, and enhanced functionality  
✅ **State machine templates** - Clean, Verilog-portable FSM base with proper status register handling  
✅ **Reset and validation infrastructure** - Comprehensive parameter validation and error handling patterns  
✅ **Testbench framework** - Organized by layer with proper GHDL compatibility  

### **Learning Objectives:**
- **Validate the entire workflow** from datadef → core → top → testbench
- **Real-world testing** of enhanced packages and templates
- **End-to-end validation** of our development process
- **Immediate feedback** on what works and what needs refinement

## 📋 **Implementation Roadmap**

### **Phase 1: Core Entity Development**
**Goal:** Create the main ProbeHero8 core using enhanced packages

#### **1.1 Core Entity Structure**
- [ ] Create `modules/probe_driver_en/core/probe_hero8_core.vhd`
- [ ] Implement interface using enhanced packages:
  - `Probe_Config_pkg_en` for probe configuration
  - `Global_Probe_Table_pkg_en` for probe selection
  - `Moku_Voltage_pkg_en` for voltage handling
  - `PercentLut_pkg_en` for intensity scaling
- [ ] Use state machine template as base
- [ ] Implement proper port validation and error handling

#### **1.2 State Machine Implementation**
- [ ] Use `state_machine_base.vhd` template
- [ ] Implement states: IDLE, ARMED, FIRING, COOLING, HARDFAULT
- [ ] Add probe-specific logic for firing sequence
- [ ] Implement proper status register updates

#### **1.3 Validation Logic**
- [ ] Use enhanced package validation functions
- [ ] Implement parameter clamping with ALARM signaling
- [ ] Add safety checks for probe configuration
- [ ] Handle invalid inputs gracefully

### **Phase 2: Core Testbench Development**
**Goal:** Validate core functionality with comprehensive testing

#### **2.1 Testbench Structure**
- [ ] Create `modules/probe_driver_en/tb/core/probe_hero8_core_tb.vhd`
- [ ] Follow layer-organized testbench structure
- [ ] Use direct instantiation for consistency
- [ ] Implement comprehensive test coverage

#### **2.2 Test Scenarios**
- [ ] **Basic functionality tests:**
  - Reset behavior
  - Enable/disable functionality
  - State transitions
- [ ] **Parameter validation tests:**
  - Valid probe selection
  - Invalid probe selection (should trigger HARDFAULT)
  - Parameter clamping behavior
  - ALARM bit setting
- [ ] **Firing sequence tests:**
  - Trigger detection
  - Duration timing
  - Output voltage validation
  - Cooling period behavior
- [ ] **Error condition tests:**
  - Invalid configurations
  - Boundary conditions
  - Fault recovery

#### **2.3 GHDL Validation**
- [ ] Compile with `ghdl --std=08`
- [ ] Run all tests to completion
- [ ] Verify deterministic results
- [ ] Ensure proper error reporting

### **Phase 3: Top-Level Integration**
**Goal:** Create top-level module with direct instantiation

#### **3.1 Top Module Creation**
- [ ] Create `modules/probe_driver_en/top/probe_hero8_top.vhd`
- [ ] **MUST use direct instantiation** for all internal connections
- [ ] Integrate core module with proper interface
- [ ] Add external interface for platform control system
- [ ] Expose control, configuration, and status registers

#### **3.2 Top-Level Testbench**
- [ ] Create `modules/probe_driver_en/tb/top/probe_hero8_top_tb.vhd`
- [ ] **MUST use direct instantiation** for all module connections
- [ ] Test full system integration
- [ ] Validate register interface
- [ ] Test end-to-end functionality

### **Phase 4: System Validation**
**Goal:** Ensure everything works together seamlessly

#### **4.1 Integration Testing**
- [ ] Test all enhanced packages working together
- [ ] Validate error handling across the system
- [ ] Test parameter validation end-to-end
- [ ] Verify status register behavior

#### **4.2 Performance Validation**
- [ ] Test timing requirements
- [ ] Validate state machine performance
- [ ] Test error recovery mechanisms
- [ ] Verify resource utilization

## 🔧 **Technical Requirements**

### **VHDL-2008 with Verilog Portability**
- [ ] Use `std_logic` and `std_logic_vector` types
- [ ] Implement FSMs with `std_logic_vector` state encoding
- [ ] Use constants for state labels (no enums)
- [ ] Avoid VHDL-only features

### **Direct Instantiation Requirements**
- [ ] **Top layer files MUST use direct instantiation**
- [ ] **Top layer testbenches MUST use direct instantiation**
- [ ] Use `entity WORK.module_name` pattern
- [ ] No component declarations in top layer

### **Enhanced Package Integration**
- [ ] Use validation functions from enhanced packages
- [ ] Implement proper error handling patterns
- [ ] Use enhanced type safety features
- [ ] Leverage improved utility functions

## 📁 **File Structure**
```
modules/probe_driver_en/
├── core/
│   └── probe_hero8_core.vhd          # Main implementation
├── top/
│   └── probe_hero8_top.vhd           # Top-level integration
└── tb/
    ├── core/
    │   └── probe_hero8_core_tb.vhd   # Core testing
    └── top/
        └── probe_hero8_top_tb.vhd    # Top-level testing
```

## 🎯 **Success Criteria**

### **Functional Requirements**
- [ ] All state transitions work correctly
- [ ] Parameter validation functions properly
- [ ] Error handling works as expected
- [ ] Status register updates correctly
- [ ] Output voltages are properly controlled

### **Technical Requirements**
- [ ] Compiles with GHDL without errors
- [ ] All tests pass consistently
- [ ] Direct instantiation used in top layer
- [ ] Enhanced packages integrated properly
- [ ] Verilog portability maintained

### **Quality Requirements**
- [ ] Comprehensive test coverage
- [ ] Clear error reporting
- [ ] Consistent coding style
- [ ] Proper documentation
- [ ] Follows VOLO coding standards

## 🚨 **Risk Mitigation**

### **Potential Challenges**
1. **Package Integration Issues** - Enhanced packages may have unexpected interactions
2. **State Machine Complexity** - Probe-specific logic may complicate the template
3. **Validation Edge Cases** - Complex parameter validation may reveal gaps
4. **Timing Requirements** - Real-time constraints may need refinement

### **Mitigation Strategies**
1. **Incremental Development** - Build and test in small increments
2. **Comprehensive Testing** - Test each component thoroughly before integration
3. **Error Handling First** - Implement robust error handling early
4. **Documentation** - Document any deviations or discoveries

## 📅 **Timeline Estimate**

### **Day 1: Core Development**
- Morning: Core entity structure and state machine
- Afternoon: Validation logic and basic functionality

### **Day 2: Core Testing**
- Morning: Core testbench development
- Afternoon: Test execution and debugging

### **Day 3: Top-Level Integration**
- Morning: Top module creation
- Afternoon: Top-level testbench

### **Day 4: System Validation**
- Morning: Integration testing
- Afternoon: Performance validation and refinement

## 🔍 **Questions for Tomorrow**

1. **Priority Order:** Should we start with core entity or test the enhanced packages together first?
2. **State Machine Complexity:** How complex should the probe-specific logic be in the first iteration?
3. **Error Handling:** What level of error detail should we provide in the status register?
4. **Testing Strategy:** Should we use automated test vectors or manual test scenarios?

## 💡 **Key Benefits of This Approach**

- **Immediate validation** of our enhanced infrastructure
- **Real-world testing** of packages and templates
- **Complete workflow validation** from concept to implementation
- **Foundation building** for future modules
- **Learning opportunity** to refine our development process

---

**Ready to build the future of VOLO VHDL development! 🚀**

*This plan captures our discussion and provides a clear roadmap for implementing ProbeHero8 using all the enhanced infrastructure we've built.*

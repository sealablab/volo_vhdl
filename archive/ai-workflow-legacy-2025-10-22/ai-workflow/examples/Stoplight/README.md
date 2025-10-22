# Stoplight Module Example

## 🎯 **Purpose**
This is a **validation example** that demonstrates the VOLO VHDL generation workflow:
**Requirements Document → AI Generation → Working Module**

## 📋 **Development Phases**

### **Phase 1: Requirements Document** ✅ **READY**
- [ ] Create `stoplight-interface-requirements.md`
- [ ] Define traffic light functionality and interface
- [ ] Specify state machine behavior and transitions

### **Phase 2: AI Generation** 🔄 **NEXT**
- [ ] Use AI to generate `stoplight_core.vhd` from requirements + base module
- [ ] Customize base module for traffic light functionality
- [ ] Validate generated code compiles and follows VOLO standards

### **Phase 3: Testing** 📋 **PLANNED**
- [ ] Create comprehensive testbench
- [ ] Test traffic light state transitions
- [ ] Validate countdown functionality
- [ ] Test enhanced package integration

### **Phase 4: Validation** 📋 **PLANNED**
- [ ] Prove the generation workflow works
- [ ] Document successful approach
- [ ] Prepare for future module generation

## 🔧 **Technical Details**

### **Base Module Foundation**
- **Source**: `ai-workflow/modules/volo_base/core/base_module_core.vhd`
- **Customization**: States, logic, outputs, status register
- **Integration**: Enhanced packages (`volo_common_pkg`, etc.)

### **Expected States**
- **Base Module**: RESET → READY → IDLE → FAULT
- **Stoplight**: RED → YELLOW → GREEN → FAULT
- **Note**: Internal states only - external interface hides implementation

### **Key Features**
- **Traffic Light Control**: RED/YELLOW/GREEN output signals
- **Countdown Timer**: Configurable delays for each state
- **Status Monitoring**: Current state and progress
- **Configuration**: Delay parameters for each light state

## 📁 **File Structure**
```
ai-workflow/examples/Stoplight/
├── README.md                              # This file
├── stoplight-interface-requirements.md    # Requirements document
├── stoplight_core.vhd                     # Generated core module
├── stoplight_top.vhd                      # Top-level integration (if needed)
└── tb/
    ├── core/
    │   └── stoplight_core_tb.vhd         # Core module testbench
    └── top/
        └── stoplight_top_tb.vhd          # Top-level testbench (if needed)
```

## 🎯 **Success Criteria**
- [ ] Requirements document is clear and AI-friendly
- [ ] Generated module compiles without errors
- [ ] Traffic light functionality works as specified
- [ ] Testbench validates all functionality
- [ ] Generation workflow is proven and documented

## 🔗 **Related Files**
- **Roadmap**: `ai-workflow/STOPLIGHT-MODULE-ROADMAP.md`
- **Base Module**: `ai-workflow/modules/volo_base/core/base_module_core.vhd`
- **Enhanced Packages**: `ai-workflow/modules/volo_common/volo_common_pkg.vhd`
- **Agent Guidelines**: `AGENTS.md`

---

**Ready to prove the generation workflow works! 🚦🚀**

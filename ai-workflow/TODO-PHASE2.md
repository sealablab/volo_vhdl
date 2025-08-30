# 🚀 **TODO: Phase 2 - Code Generation**

**What to Build Tomorrow:**
- 🔄 **Phase 2**: Code generation prompts that take refined requirements and generate complete VHDL

## 🚀 **Starting Points for Tomorrow:**

### **1. Review What We Have**
- **Current Prompt**: `ai-workflow/prompts/interface-refinement/PROMPT-02--interface refinement.md`
- **Example Requirements**: `ai-workflow/examples/ProbeHero7/PH7-interface-reqs-r2.md`
- **Generated Output**: Constants package, core entity, basic testbench

### **2. Design Phase 2 Prompt**
- **Input**: Refined requirements from Phase 1
- **Output**: Complete VHDL implementation (entity + architecture + processes)
- **Focus**: Generate working, standards-compliant VHDL code

### **3. Key Features to Include**
- **Complete Module Generation**: Full entity and architecture
- **Process Implementation**: Clocked processes, state machines, counters
- **Status Register Logic**: Implement status bits as specified
- **Error Handling**: Fault detection and status updates
- **Constants Integration**: Use constants from Phase 1 output

### **4. Test with ProbeHero7**
- Use the refined requirements we created today
- Generate complete VHDL implementation
- Validate against VOLO coding standards

## 🎨 **Prompt Structure Ideas:**

```
# Phase 2: VHDL Code Generation Prompt

**Purpose**: Generate complete VHDL implementations from refined requirements
**Input**: Phase 1 output (constants package + refined requirements)
**Output**: Complete entity, architecture, and processes

**Key Sections**:
1. Requirements Analysis
2. Architecture Design
3. Process Generation
4. Status Register Implementation
5. Error Handling Logic
6. Quality Validation
```

## 🔗 **Files to Reference:**
- **@ai-workflow/README.md** - Main workflow guide
- **@ai-workflow/examples/ProbeHero7/** - Complete workflow example
- **@ai-workflow/prompts/interface-refinement/** - Phase 1 prompt for reference
- **@rules.mdc** - VOLO coding standards

## 💡 **Remember:**
- **Build on Phase 1**: Use the interface refinement output as input
- **Maintain Standards**: All generated code must follow VOLO rules
- **Test Everything**: Validate generated code with GHDL
- **Document Process**: Update the workflow documentation

---


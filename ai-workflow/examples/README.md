# Example Workflows for VOLO VHDL Development

This directory contains complete examples of the AI workflow in action, showing how to go from initial requirements to generated VHDL code.

## 🎯 **Available Examples**

### **ProbeHero6 Example**
Located in `ProbeHero6/`

**Purpose**: Complete workflow demonstration for a probe driver module
**Use Case**: Reference for similar probe-related modules
**Key Features**:
- Initial requirements document
- AI-refined requirements
- Generated VHDL code
- Workflow evolution tracking

### **ProbeHero7 Example**
Located in `ProbeHero7/`

**Purpose**: Enhanced workflow with units convention
**Use Case**: Reference for modern requirements format
**Key Features**:
- Units-enhanced requirements
- Interactive refinement process
- Complete workflow documentation
- Best practices demonstration

## 🚀 **How to Use Examples**

### **1. Study the Workflow**
- Review the initial requirements
- See how AI identified and resolved issues
- Understand the refinement process
- Learn from the final output

### **2. Copy as Starting Points**
```bash
# Copy an example for your new module
cp -r ai-workflow/examples/ProbeHero7 \
   modules/your_new_module/

# Customize for your specific needs
# Use the AI workflow to refine and generate code
```

### **3. Learn Best Practices**
- **Requirements Structure**: See how to organize requirements
- **AI Interaction**: Learn effective prompt usage
- **Issue Resolution**: Understand common problems and solutions
- **Code Generation**: See the quality of AI-generated VHDL

### **4. Adapt to Your Needs**
- Modify requirements for your module type
- Adjust the workflow for your team's preferences
- Extend with additional requirements
- Customize the AI prompts as needed

## 📋 **Example Structure**

Each example contains:

### **Requirements Evolution**
- **Initial**: `[module]-interface-reqs.md`
- **Refined**: `[module]-interface-reqs-r1.md`, `-r2.md`, etc.
- **Final**: Complete, AI-approved requirements

### **Generated Code**
- **Constants Package**: `common/[module]_constants_pkg.vhd`
- **Core Entity**: `core/[module]_core.vhd`
- **Testbench**: `tb/core/[module]_core_tb.vhd`

### **Workflow Documentation**
- **Process Logs**: `-log-r1.md`, etc.
- **Issue Tracking**: Documented problems and solutions
- **Decision History**: Key choices and rationale

## 🎨 **Learning from Examples**

### **Requirements Writing**
- **Clarity**: See how to write clear, unambiguous requirements
- **Completeness**: Understand what details are essential
- **Structure**: Learn the optimal organization
- **Units**: See how to specify units for all parameters

### **AI Interaction**
- **Question Handling**: Learn how to respond to AI questions
- **Issue Resolution**: See how to address identified problems
- **Iteration**: Understand the refinement process
- **Validation**: Learn how to verify AI output

### **Code Quality**
- **Standards Compliance**: See VOLO coding standards in action
- **Verilog Portability**: Understand VHDL-2008 requirements
- **Naming Conventions**: Learn proper signal prefixes
- **Testbench Structure**: See proper testing approaches

## 📚 **Best Practices Demonstrated**

### **1. Start Simple**
- Begin with basic requirements
- Let AI guide you to completeness
- Iterate based on feedback
- Build complexity gradually

### **2. Use Templates**
- Start with standardized formats
- Maintain consistency across modules
- Include all required sections
- Follow established patterns

### **3. Iterate Effectively**
- Address AI feedback promptly
- Refine requirements systematically
- Track changes and decisions
- Learn from each iteration

### **4. Validate Output**
- Check generated code quality
- Verify standards compliance
- Test basic functionality
- Document any issues

## 🔧 **Customizing Examples**

### **Module-Specific Adaptations**
- **Interface Modules**: Focus on signal definitions
- **Processing Modules**: Emphasize algorithms and timing
- **Control Modules**: Highlight state machines and logic
- **Memory Modules**: Detail storage and access patterns

### **Team Preferences**
- **Documentation Style**: Adjust comment and format preferences
- **Naming Conventions**: Modify for team standards
- **Testing Approach**: Customize testbench strategies
- **Validation Methods**: Adapt error handling approaches

## 🤝 **Contributing Examples**

To add new examples:
1. **Complete a Workflow**: Use the AI workflow for a new module
2. **Document the Process**: Track requirements evolution
3. **Organize Files**: Structure according to established patterns
4. **Add Documentation**: Include README and process notes
5. **Share**: Contribute back to the workflow

## 📖 **Example Walkthrough**

### **ProbeHero7 Complete Workflow**
1. **Initial Requirements**: Basic module specification
2. **AI Analysis**: Identified missing units and unclear dependencies
3. **Interactive Refinement**: AI guided through issue resolution
4. **Requirements Update**: Added units and clarified parameters
5. **Code Generation**: Generated constants, entity, and testbench
6. **Quality Validation**: Ensured standards compliance

---

**These examples demonstrate the power of AI-assisted VHDL development - study them to accelerate your own workflow!** 🚀

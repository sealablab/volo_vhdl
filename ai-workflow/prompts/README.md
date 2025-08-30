# AI Prompts for VOLO VHDL Development

This directory contains AI prompts designed for different phases of VHDL module development. Each prompt is engineered to work with the VOLO project's coding standards and workflow.

## 🎯 **Available Prompts**

### **Interface Refinement Prompts**
Located in `interface-refinement/`

**Purpose**: Define and refine module interfaces before implementation
**Input**: Requirements document with module specifications
**Output**: Constants package, core entity, and basic testbench
**Use Case**: Initial module design and interface iteration

**Key Features**:
- Interactive requirements refinement
- Automatic issue detection and resolution
- Standards-compliant VHDL generation
- Support for both interactive and strict modes

### **Code Generation Prompts** (Future)
Located in `code-generation/`

**Purpose**: Generate complete module implementations
**Input**: Refined interface requirements
**Output**: Full module architecture and processes
**Use Case**: Complete module development

### **Validation Prompts** (Future)
Located in `validation/`

**Purpose**: Validate and test generated code
**Input**: Generated VHDL modules
**Output**: Test results and compliance reports
**Use Case**: Quality assurance and testing

## 🚀 **How to Use Prompts**

### **1. Choose Your Prompt**
Select the prompt that matches your current development phase:
- **Interface Definition**: Use interface refinement prompts
- **Implementation**: Use code generation prompts (when available)
- **Testing**: Use validation prompts (when available)

### **2. Prepare Your Input**
- **Requirements Document**: For interface refinement
- **Interface Specification**: For code generation
- **Generated Code**: For validation

### **3. Run the Prompt**
- Copy the prompt text
- Paste into your AI assistant (Cursor, ChatGPT, etc.)
- Provide your input document
- Follow the AI's guidance

### **4. Iterate and Refine**
- Address any issues the AI identifies
- Refine requirements based on AI feedback
- Regenerate code as needed
- Validate results

## 🔧 **Prompt Modes**

### **Interactive Mode (Default)**
- AI asks clarifying questions
- Guides you through issue resolution
- Creates refined requirements files
- Best for development and learning

### **Strict Mode (`--strict`)**
- AI stops on any issues
- Creates revision files with problem lists
- No code generation until issues resolved
- Best for automated/CI scenarios

## 📋 **Input Requirements**

### **For Interface Refinement**
- Module overview and purpose
- Dependencies and requirements
- Control and configuration signals
- Status register specifications
- State machine behavior

### **For Code Generation** (Future)
- Complete interface specification
- Detailed functional requirements
- Performance constraints
- Testing requirements

### **For Validation** (Future)
- Generated VHDL code
- Testbench files
- Performance specifications
- Compliance requirements

## 🎨 **Customization**

Each prompt can be customized for:
- **Specific module types** (FSMs, counters, interfaces)
- **Special requirements** (high-speed, low-power, etc.)
- **Team preferences** (naming conventions, coding style)
- **Project standards** (documentation, testing requirements)

## 📚 **Best Practices**

1. **Start with Interface Refinement**: Define clear interfaces before implementation
2. **Use Templates**: Start with provided templates for consistency
3. **Iterate**: Refine requirements based on AI feedback
4. **Validate**: Always test generated code
5. **Document**: Keep track of decisions and changes
6. **Share**: Contribute improvements back to the workflow

## 📖 **Essential Reading**

Before using AI prompts, review these key documents:
- **@ai-workflow/README-RESET.md** - Control signal behavior and priorities
- **@ai-workflow/README-direct-instantiation.md** - Direct instantiation patterns
- **@ai-workflow/README-ghdl-testbench-tips.md** - Testbench best practices

## 🤝 **Getting Help**

If you encounter issues with prompts:
1. Check the examples in `../examples/`
2. Review the main workflow documentation
3. Test with simple requirements first
4. Provide feedback for prompt improvements

---

**These prompts represent the cutting edge of AI-assisted VHDL development - use them to accelerate your hardware design workflow!** 🚀

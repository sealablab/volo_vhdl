# Input Templates for VOLO VHDL Development

This directory contains standardized templates for creating requirements documents and specifications that work seamlessly with the AI workflow prompts.

## 🎯 **Available Templates**

### **Requirements Templates**
Located in `requirements/`

**Purpose**: Define module interfaces and requirements
**Use Case**: Initial module specification and AI prompt input
**Output**: Structured requirements document ready for AI processing

**Key Features**:
- Standardized sections and formatting
- Pre-filled common dependencies
- Clear structure for AI parsing
- Human-friendly with helpful comments

### **Specification Templates** (Future)
Located in `specifications/`

**Purpose**: Detailed technical specifications
**Use Case**: Complete module design documentation
**Output**: Comprehensive technical specification

## 🚀 **How to Use Templates**

### **1. Choose Your Template**
- **New Module**: Start with `BLANK-requirements-template.md`
- **Existing Module**: Copy and modify an existing requirements file
- **Special Purpose**: Use specialized templates as they become available

### **2. Copy and Customize**
```bash
# Copy the blank template
cp ai-workflow/templates/requirements/BLANK-requirements-template.md \
   modules/your_module/your_module-requirements.md

# Edit with your module details
# Follow the template structure and comments
```

### **3. Fill in the Details**
- **Module Overview**: Describe purpose and functionality
- **Dependencies**: List required packages and modules
- **Interface**: Define all inputs, outputs, and parameters
- **Behavior**: Specify state machines and timing
- **Validation**: Define error conditions and limits

### **4. Use with AI Prompts**
- Copy your completed requirements
- Paste into the appropriate AI prompt
- Follow the AI's guidance for refinement
- Generate VHDL code automatically

## 📋 **Template Structure**

### **Standard Requirements Template Sections**
1. **Module Overview** - Purpose and functionality
2. **Dependencies** - Required packages and modules
3. **Control Inputs** - Clock, reset, enable signals
4. **Configuration Inputs** - Parameters and settings
5. **Data Inputs** - Data and control signals
6. **Expected Outputs** - Results and status
7. **Status Register** - Status and monitoring bits
8. **Validation Rules** - Parameter limits and error conditions
9. **State Machine** - Behavior and transitions
10. **Implementation Notes** - Special requirements and constraints

### **Template Features**
- **Checkboxes** for completion tracking
- **HTML Comments** for human guidance (ignored by AI)
- **Emojis** for visual organization
- **Pre-filled sections** for common requirements
- **Units fields** for all parameters

## 🎨 **Customization Guidelines**

### **Keep Templates Minimal**
- Focus on structure, not content
- Use clear, consistent formatting
- Include helpful comments and examples
- Avoid over-specification

### **Ensure AI Compatibility**
- Use consistent section headers
- Follow naming conventions
- Include all required fields
- Provide clear examples

### **Maintain Human Readability**
- Use descriptive section names
- Include helpful guidance
- Provide examples where helpful
- Keep formatting clean and organized

## 📚 **Best Practices**

1. **Start with Templates**: Always begin with a template for consistency
2. **Follow Structure**: Maintain the template organization
3. **Be Specific**: Provide clear, unambiguous requirements
4. **Include Units**: Always specify units for parameters
5. **Validate Early**: Use AI prompts to catch issues early
6. **Iterate**: Refine requirements based on AI feedback
7. **Document Decisions**: Keep track of design choices

## 🔧 **Template Maintenance**

### **When to Update Templates**
- New common requirements identified
- AI parsing improvements needed
- Team feedback suggests changes
- New project standards adopted

### **How to Update Templates**
1. Identify the need for change
2. Update the template file
3. Test with AI prompts
4. Update documentation
5. Notify team members

## 🤝 **Getting Help**

If you need help with templates:
1. Check the examples in `../examples/`
2. Review existing requirements files
3. Test with AI prompts
4. Provide feedback for improvements

---

**These templates provide the foundation for consistent, AI-friendly requirements documentation - the first step toward automated VHDL development!** 🚀

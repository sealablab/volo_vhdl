# AI Development Workflow for VOLO VHDL

This directory contains the AI-powered development workflow tools for the VOLO VHDL project. These tools enable rapid, consistent, and standards-compliant VHDL module development through AI assistance.

## 🎯 **Purpose**

The AI workflow environment provides:
- **Standardized prompts** for different development phases
- **Input templates** for requirements and specifications
- **Complete examples** showing the workflow in action
- **Consistent quality** through AI-guided development

## 🏗️ **Directory Structure**

```
ai-workflow/
├── prompts/                    # AI prompts for different phases
│   ├── interface-refinement/   # Interface definition prompts
│   ├── code-generation/        # Code generation prompts  
│   ├── validation/            # Testing/validation prompts
│   └── README.md              # Prompt usage guide
├── templates/                  # Input form templates
│   ├── requirements/           # Requirements document templates
│   ├── specifications/         # Technical spec templates
│   └── README.md              # Template usage guide
├── examples/                   # Example inputs/outputs
│   ├── ProbeHero6/            # Complete example workflow
│   ├── ProbeHero7/            # Another complete example
│   └── README.md              # Examples guide
└── README.md                   # This file
```

## 🚀 **Quick Start**

1. **Choose your development phase:**
   - **Interface Definition**: Use prompts in `prompts/interface-refinement/`
   - **Code Generation**: Use prompts in `prompts/code-generation/`
   - **Validation**: Use prompts in `prompts/validation/`

2. **Start with a template:**
   - Copy from `templates/requirements/` for new modules
   - Use examples in `examples/` as reference

3. **Run the AI prompt:**
   - Follow the prompt instructions
   - Iterate on requirements as needed
   - Generate VHDL code following VOLO standards

## 🔄 **Workflow Phases**

### **Phase 1: Interface Definition**
- Define module dependencies and interfaces
- Use `PROMPT-02--interface refinement.md`
- Creates constants package, core entity, and basic testbench

### **Phase 2: Code Generation** (Future)
- Implement full module functionality
- Generate complete architectures and processes
- Create comprehensive testbenches

### **Phase 3: Validation** (Future)
- Automated testing and validation
- Standards compliance checking
- Performance and timing analysis

## 📋 **Standards Compliance**

All AI-generated code follows:
- **VHDL-2008** with Verilog portability
- **VOLO coding standards** from `@rules.mdc`
- **Project naming conventions** (`ctrl_*`, `cfg_*`, `stat_*`)
- **Direct instantiation** requirements for top layer

## 🎨 **Customization**

The workflow is designed to be:
- **Flexible**: Adapt to different module types
- **Extensible**: Easy to add new prompt types
- **Consistent**: Maintains quality across all modules
- **Human-friendly**: Guides users through complex decisions

## 📚 **Documentation**

- **@AGENTS.md** - Core VHDL coding standards
- **@rules.mdc** - Repository-specific rules
- **@ai-workflow/README-direct-instantiation.md** - Direct instantiation patterns
- **@ai-workflow/README-ghdl-testbench-tips.md** - Testbench best practices

## 🤝 **Contributing**

To improve the AI workflow:
1. Test prompts with real modules
2. Identify areas for improvement
3. Update prompts based on feedback
4. Add new prompt types as needed
5. Maintain examples and templates

---

**This AI workflow represents the first engineered prompt system for VHDL development - a significant milestone in automated hardware design!** 🎉

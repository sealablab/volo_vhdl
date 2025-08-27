# Volo VHDL Project

Johnny's evolving AI VHDL generation workflow designed for **VHDL-2008 with Verilog portability**.

## Project Structure

```
volo_vhdl/
├─ .cursor/rules              # Project rules for AI agents
├─ AGENTS.md                  # Comprehensive agent guidelines
├─ modules/                   # VHDL modules with standardized structure
│  ├─ README.md              # Module structure documentation
│  └─ [module_name]/
│      ├─ datadef/           # Data structure definitions (Tier 2 rules)
│      ├─ common/            # RTL utility packages (Tier 1 rules)
│      ├─ core/              # Main algorithmic/logic implementation (Tier 1 rules)
│      ├─ top/               # Top-level integration (Tier 1 rules, optional)
│      └─ tb/                # Testbenches (Tier 3 rules)
├─ templates/                 # Reusable VHDL templates
│  └─ README.md              # Template guidelines
└─ docs/                      # Additional documentation
    ├─ STYLE.md              # Coding style guidelines
    ├─ REGISTERS.md          # ctrl_/cfg_/stat_ rules + reset semantics
    └─ WORKFLOW.md           # How to use templates with Cursor
```

## Quick Start

1. **Read the Rules**: Start with `.cursor/rules` and `AGENTS.md`
2. **Follow the Structure**: Use the standardized module layout in `modules/`
3. **Use Templates**: Leverage pre-built templates in `templates/`
4. **Maintain Standards**: Follow VHDL-2008 with Verilog portability guidelines

## Key Features

- **Verilog Portable**: All VHDL code designed for easy conversion
- **Tiered Rule System**: Three-tier approach balancing portability with practicality
- **Standardized Architecture**: Consistent module structure across the project
- **AI Agent Ready**: Comprehensive guidelines for AI-assisted development
- **Template Driven**: Reusable templates following project standards

## Tiered Rule System

The project uses a **three-tier rule system** to balance Verilog portability requirements with practical VHDL development needs:

- **Tier 1 (Strict RTL)**: `common/`, `core/`, `top/` - Strict Verilog portability rules
- **Tier 2 (Data Definitions)**: `datadef/` - Relaxed rules for LUTs and data structures  
- **Tier 3 (Testbenches)**: `tb/` - Full VHDL-2008 features allowed

This approach ensures synthesizable RTL maintains full Verilog compatibility while allowing appropriate flexibility for data definitions and verification code. See `.cursor/rules.mdc` for complete details.

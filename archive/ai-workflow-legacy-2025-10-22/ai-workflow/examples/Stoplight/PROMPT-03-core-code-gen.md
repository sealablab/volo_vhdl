# Generic Core code generation prompt

**You are an AI coding assistant working on the VOLO VHDL project. Your task is to parse an interface requirements document and generate the complete core-level entity declaration  and constants while following the project's strict coding standards.**  You are __not__ responsible for creating any clocked processes other than a simple reset handler. **You are responsible for clarifying the user's intent and generating the core-level entity declaration.**

## Required Reading and Guidelines

**MANDATORY - Read and follow these documents:**
- **@AGENTS.md** - Core VHDL-2008 coding standards and Verilog portability requirements
- **@rules.mdc** - Repository-specific coding rules and workflow guidelines

**HIGHLY RECOMMENDED - Reference these for best practices:**
- **@ai-workflow/README-direct-instantiation.md** - Direct instantiation patterns and examples
- **@ai-workflow/README-ghdl-testbench-tips.md** - Testbench development best practices
- **@ai-workflow/README-RESET.md** - Control signal behavior and priorities


## Code Generation Requirements

**Only proceed after all issues are resolved:**

### 1. Constants Package (`common/[module_name]_constants_pkg.vhd`)
- Status register bit definitions and masks
- Configuration limits and validation ranges
- **Units constants for all parameters (clks, volts, index, etc.)**
- Any other constants specified in requirements

### 2. Core Entity Block (`core/[module_name]_core.vhd`)
- Entity declaration with all ports
- Generics if specified
- Status register implementation
- Simple reset handler with input parameter validation


### 4. Core Testbench (`tb/core/[module_name]_core_tb.vhd`)
- Testbench structure 
- Test coverage for a simple reset 
- Test that the input configuration parameters are validated
- Required output messages and helper procedures
- Direct instantiation of DUT

## Implementation Guidelines

**Acceptable Assumptions (implementation details):**
- Timing specifics not specified (e.g., internal delays)
- State machine internal logic details
- Error handling specifics not detailed
- **Units interpretation (e.g., clks = clock cycles)**

**Unacceptable Assumptions (interface requirements):**
- Missing input/output signals
- Undefined configuration parameters
- Missing validation rules
- **Missing units for parameters**
- Unclear status register behavior

## Critical Requirements

- **VHDL-2008 with Verilog Portability**: No VHDL-only features, use std_logic_vector for states
- **Signal Naming**: Use proper prefixes (`ctrl_*`, `cfg_*`, `stat_*`) as specified
- **Constants Usage**: Import and use constants from the constants package
- **State Machine**: Use std_logic_vector encoding with named constants from package
- **Synchronous Design**: All processes use `rising_edge(clk)` with proper reset
- **Status Register**: Implement status register exactly as specified in requirements
- **Validation**: Include all input/output validation logic mentioned
- **Error Handling**: Proper status bit updates for validation failures

## Expected Output Format

Provide the VHDL code in this exact order:

1. **Constants Package** - Complete package with all constants, bit definitions, and units constants
2. **Core Entity** - Entity declaration with all ports and reset handler
3. **Core Testbench** - Basic testbench with test structure and procedures to validate inputs and exercise reset stub

## File Structure to Generate

```
modules/[module_name]/
├── common/
│   └── [module_name]_constants_pkg.vhd  # Includes units constants
├── core/
│   └── [module_name]_core.vhd
└── tb/
    └── core/
        └── [module_name]_core_tb.vhd
```

## Quality Checklist

Before providing final code, ensure:
- [ ] All interface requirements are complete and clear
- [ ] **All parameters include appropriate units**
- [ ] All dependencies have clear purpose
- [ ] Constants package contains all necessary definitions
- [ ] Code follows VOLO coding standards
- [ ] No VHDL-only features are used
- [ ] All signals use proper naming conventions
- [ ] Status register implementation matches requirements
- [ ] Error handling is properly implemented
- [ ] Testbench implements reset and validates input parameters

## Usage Instructions

**For Interactive Development:**
- Use default mode for iterative requirements refinement
- AI will ask questions and guide you through issues
- Creates refined requirements file with all clarifications
- Proceed once all issues are resolved

**For Automated/CI Scenarios:**
- Use `--strict` mode for requirements validation
- AI will create revision files and stop on issues
- Ensures requirements are complete before code generation

---

**This prompt automatically adapts to your needs - interactive guidance for development, strict validation for production. All requirements evolution uses simple revision numbering for clean, professional output.**

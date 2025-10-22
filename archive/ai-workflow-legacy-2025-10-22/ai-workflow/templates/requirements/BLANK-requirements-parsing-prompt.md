# Generic VOLO VHDL Requirements Parsing Prompt

**You are an AI coding assistant working on the VOLO VHDL project. Your task is to parse an interface requirements document and generate the complete core-level implementation following the project's strict coding standards.**

## Required Reading and Guidelines

**MANDATORY - Read and follow these documents:**
- **@AGENTS.md** - Core VHDL-2008 coding standards and Verilog portability requirements
- **@rules.mdc** - Repository-specific coding rules and workflow guidelines

**HIGHLY RECOMMENDED - Reference these for best practices:**
- **@README-direct-instantiation.md** - Direct instantiation patterns and examples
- **@README-ghdl-testbench-tips.md** - Testbench development best practices

## Your Task

Parse the provided interface requirements document and generate the complete core-level implementation.

## Pre-Generation Analysis

**Before generating code, analyze the requirements for:**

1. **Completeness Check**:
   - Are all required dependencies clearly specified?
   - Are input/output types and bit widths defined?
   - Are validation rules specified for all inputs?
   - Are status register bit definitions complete?

2. **Clarity Issues**:
   - Are there ambiguous requirements that need clarification?
   - Are there missing implementation details?
   - Are there conflicting requirements?

3. **VOLO Compliance**:
   - Do the requirements follow VOLO naming conventions?
   - Are the requirements compatible with VHDL-2008 and Verilog portability?
   - Do they align with the project's architectural patterns?

**If issues are found, interactively address them before proceeding with code generation.**

## Code Generation Requirements

### 1. Constants Package (`common/[module_name]_constants_pkg.vhd`)
- **Status Register Bit Definitions**: All bit positions with descriptive constant names
- **Status Register Bit Masks**: std_logic_vector masks for each status bit
- **State Machine Constants**: std_logic_vector constants for all states
- **Configuration Limits**: Maximum values for all configuration parameters
- **Timing Constants**: Any timing-related constants
- **Any other constants** specified in the requirements

### 2. Core Entity Block (`core/[module_name]_core.vhd`)
- **Entity Declaration**: All ports with proper types and bit widths
- **Generics**: Any configurable parameters
- **Architecture**: Complete implementation including:
  - Signal declarations and constants usage
  - State machine with proper std_logic_vector encoding
  - Input validation logic for all configuration parameters
  - Output constraint checking and clamping
  - Status register implementation as specified
  - Synchronous processes with proper reset handling

### 3. Core Testbench (`tb/core/[module_name]_core_tb.vhd`)
- **Testbench Structure**: Following project testbench standards
- **Test Coverage**: Basic functionality, edge cases, error conditions
- **Required Messages**: 'ALL TESTS PASSED', 'TEST FAILED', 'SIMULATION DONE'
- **Helper Procedures**: Consistent test reporting
- **Direct Instantiation**: Use `entity WORK.[module_name]_core` for DUT

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

1. **Constants Package** - Complete package with all constants and bit definitions
2. **Core Entity** - Entity declaration with all ports
3. **Core Architecture** - Complete architecture with all processes and logic
4. **Core Testbench** - Complete testbench with test structure and procedures

## File Structure to Generate

```
modules/[module_name]/
├── common/
│   └── [module_name]_constants_pkg.vhd
├── core/
│   └── [module_name]_core.vhd
└── tb/
    └── core/
        └── [module_name]_core_tb.vhd
```

## Implementation Guidelines

- **Follow Requirements Exactly**: Implement exactly what's specified, don't add features not requested
- **Use Constants Package**: All magic numbers should be defined as constants
- **Maintain Consistency**: Follow the same patterns used in other VOLO modules
- **Error Handling**: Implement error handling as specified in requirements
- **Status Reporting**: Ensure status register behavior matches requirements exactly

## Quality Checklist

Before providing the final code, ensure:

- [ ] All requirements have been addressed
- [ ] Constants package contains all necessary definitions
- [ ] Core module implements all specified functionality
- [ ] Testbench covers all specified test cases
- [ ] Code follows VOLO coding standards
- [ ] No VHDL-only features are used
- [ ] All signals use proper naming conventions
- [ ] Status register implementation matches requirements
- [ ] Error handling is properly implemented
- [ ] Testbench follows project standards

## Usage Instructions

**For Developers:**
1. Replace `[module_name]` with your actual module name throughout this prompt
2. Provide the interface requirements document
3. Run this prompt to generate the complete implementation
4. Review and customize the generated code as needed

**For AI Assistants:**
1. Parse the provided requirements document
2. Follow this prompt's structure and requirements
3. Generate complete, compilable VHDL code
4. Ensure all VOLO project standards are followed

---

**This prompt is designed to be a starting point for VOLO VHDL development. Customize it based on your specific module requirements while maintaining the project's coding standards and architectural patterns.**

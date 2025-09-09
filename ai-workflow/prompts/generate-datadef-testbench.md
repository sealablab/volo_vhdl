# Generate Datadef Testbench - Generic Prompt

## Overview
This prompt generates a comprehensive testbench for any VHDL datadef package following the VOLO VHDL datadef testbench architecture. The generated testbench will include all 4 layers of testing and comply with VOLO standards.

## Usage
Provide the target package file as input, and this prompt will generate a complete testbench following the datadef testing standards.

## Prompt Template

```
# Generate Datadef Testbench for [PACKAGE_NAME]

I need you to generate a comprehensive testbench for the VHDL datadef package `[PACKAGE_NAME]` following the VOLO VHDL datadef testbench architecture.

## Requirements

### Package Analysis
1. **Read the package file**: `[PACKAGE_PATH]`
2. **Identify all public functions**: List all functions with their signatures
3. **Identify all public types**: List all record types, array types, and custom types
4. **Identify all public constants**: List all constants and their values
5. **Identify package dependencies**: List any `use work.package_name.ALL;` statements

### Testbench Generation
Generate a complete testbench following the 4-layer datadef architecture:

#### Layer 1: Interface Testing (Function Signatures)
- Test function parameter validation
- Test return value types and ranges
- Test package initialization
- Test type definitions

#### Layer 2: Validation Testing (Error Handling)
- Test invalid input handling
- Test boundary conditions
- Test error conditions
- Test range checking and clamping

#### Layer 3: Functional Testing (Core Behavior)
- Test core functionality of each function
- Test mathematical correctness
- Test function integration
- Test precision requirements

#### Layer 4: Configuration Testing (Constants and Types)
- Test constant values
- Test type definitions
- Test configuration variations
- Test default values

#### Package Integration Testing
- Test cross-package function calls
- Test package dependencies
- Test package initialization

### Testbench Structure
Use the following structure:

```vhdl
-- [PACKAGE_NAME] Package Testbench
-- Generated following VOLO VHDL datadef testbench architecture
-- Tests all functions, types, and constants in the package

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities
use WORK.[PACKAGE_NAME]_pkg.ALL;   -- Package under test

entity [PACKAGE_NAME]_pkg_tb is
end entity [PACKAGE_NAME]_pkg_tb;

architecture test of [PACKAGE_NAME]_pkg_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
        -- Test variables (customize based on package contents)
        -- [GENERATE_VARIABLES_BASED_ON_PACKAGE]
        
    begin
        -- Test initialization
        write(l, string'("=== [PACKAGE_NAME] Package TestBench Started ==="));
        writeline(output, l);
        
        -- [GENERATE_LAYER_1_TESTS]
        -- [GENERATE_LAYER_2_TESTS]
        -- [GENERATE_LAYER_3_TESTS]
        -- [GENERATE_LAYER_4_TESTS]
        -- [GENERATE_INTEGRATION_TESTS]
        
        -- Final results
        print_test_completion(all_tests_passed);
        
        wait for 100 ns;
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;
```

### Test Generation Guidelines

#### For Each Function:
1. **Interface Tests**: Test with valid inputs, verify return types
2. **Validation Tests**: Test with invalid inputs, boundary conditions
3. **Functional Tests**: Test mathematical correctness, precision
4. **Integration Tests**: Test function composition and chaining

#### For Each Type:
1. **Type Definition Tests**: Test type bounds, field access
2. **Initialization Tests**: Test default values, record field access
3. **Conversion Tests**: Test type conversion functions

#### For Each Constant:
1. **Value Tests**: Test constant values are correct
2. **Relationship Tests**: Test relationships between constants
3. **Usage Tests**: Test constants are used correctly in functions

### Mathematical Precision
- Use tolerance-based comparisons for real types: `abs(actual - expected) < tolerance`
- Use exact equality for integer types: `actual = expected`
- Test edge cases around zero and boundary values
- Test precision requirements for the specific domain

### Error Handling
- Test invalid parameter handling
- Test boundary condition behavior
- Test clamping and range checking functions
- Test error condition responses

### Package Dependencies
- Test cross-package function calls
- Test dependency resolution
- Test package initialization order

### Output Requirements
- Use `report_test()` procedure for each test
- Include clear test descriptions
- Use layer headers in output
- End with `print_test_completion()`

### File Naming
- Testbench file: `[PACKAGE_NAME]_pkg_tb.vhd`
- Entity name: `[PACKAGE_NAME]_pkg_tb`
- Architecture name: `test`

## Example Usage

### Input:
```
Package: Moku_Voltage_pkg_PH9
Path: modules/probe_hero9/datadef/Moku_Voltage_pkg_PH9.vhd
```

### Expected Output:
- Complete testbench file following VOLO standards
- All 4 layers of testing implemented
- Comprehensive coverage of package contents
- Proper error handling and precision testing
- Clear, maintainable code structure

## Quality Assurance
- Follow VOLO VHDL coding standards
- Use consistent naming conventions
- Include comprehensive comments
- Ensure all tests are meaningful and useful
- Verify mathematical correctness
- Test edge cases and error conditions

## Notes
- This is a datadef package testbench, not a module testbench
- Focus on function testing, not status register testing
- No clock, reset, or control signals needed
- Pure functional testing of package contents
- Serve as living documentation of package capabilities

Generate the complete testbench file following these requirements.
```

## Usage Instructions

1. **Copy the prompt template above**
2. **Replace placeholders**:
   - `[PACKAGE_NAME]` with the actual package name
   - `[PACKAGE_PATH]` with the full path to the package file
3. **Provide the prompt to an AI assistant**
4. **Review and customize** the generated testbench as needed

## Example Commands

### For Moku_Voltage_pkg_PH9:
```bash
# Use the prompt with:
Package: Moku_Voltage_pkg_PH9
Path: modules/probe_hero9/datadef/Moku_Voltage_pkg_PH9.vhd
```

### For Probe_Config_pkg_PH9:
```bash
# Use the prompt with:
Package: Probe_Config_pkg_PH9
Path: modules/probe_hero9/datadef/Probe_Config_pkg_PH9.vhd
```

## Quality Checklist

Before using the generated testbench, verify:

- [ ] All package functions are tested
- [ ] All package types are tested
- [ ] All package constants are tested
- [ ] All 4 layers are implemented
- [ ] Mathematical precision is appropriate
- [ ] Error handling is comprehensive
- [ ] Package dependencies are tested
- [ ] Code follows VOLO standards
- [ ] Comments are clear and helpful
- [ ] Test descriptions are meaningful

## Integration

The generated testbench will:
- Compile with GHDL using `--std=08`
- Integrate with the VOLO build system
- Follow the datadef testbench architecture
- Serve as living documentation
- Provide comprehensive package validation

---

**This prompt ensures consistent, high-quality testbench generation for all VOLO VHDL datadef packages.**

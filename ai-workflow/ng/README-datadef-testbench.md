# Datadef Package Testbench Architecture - VOLO VHDL Standard

## Overview
Datadef package testbenches are fundamentally different from module testbenches and require a specialized testing approach. This document defines the **mandatory testing architecture** for all VOLO VHDL datadef packages.

## Core Philosophy
**Test WHAT the package provides, not HOW it implements it.**

This principle ensures that:
- Tests focus on package interface and functionality
- Tests validate mathematical correctness and behavior
- Tests serve as living documentation of package capabilities
- Tests remain valid when internal implementation changes

## Why Datadef Testbenches Are Different

### **No Module Interface**
- No status registers, control signals, or external ports
- No state machines or sequential behavior
- No clock or reset signals
- Pure functional testing of package contents

### **Function-Centric Testing**
- Test individual functions and procedures
- Test type definitions and constants
- Test mathematical correctness
- Test error handling and edge cases

### **Package Dependencies**
- Test cross-package function calls
- Test package initialization and constants
- Test dependency resolution

## The 4-Layer Datadef Architecture

### **Layer 1: Interface Testing (Function Signatures)**
**Purpose**: Test function interfaces and basic behavior

**What to Test**:
- Function parameter validation
- Return value types and ranges
- Function behavior with valid inputs
- Type definitions and constants
- Package initialization

**What NOT to Test**:
- Internal implementation details
- Specific algorithm choices
- Performance characteristics

**Example**:
```vhdl
-- ✅ GOOD: Test function interface
test_passed := (voltage_to_digital(1.0) = x"1999");

-- ❌ BAD: Test implementation details
test_passed := (internal_calculation_step = expected_value);
```

### **Layer 2: Validation Testing (Error Handling)**
**Purpose**: Test parameter validation and error handling

**What to Test**:
- Invalid parameter handling
- Boundary conditions and edge cases
- Error conditions and exception handling
- Range checking and clamping
- Type validation

**Key Patterns**:
- Test invalid inputs trigger appropriate behavior
- Test valid inputs produce correct results
- Test validation edge cases

**Example**:
```vhdl
-- Test invalid input handling
test_passed := (clamp_voltage(10.0, 0.0, 5.0) = 5.0);

-- Test boundary conditions
test_passed := (is_voltage_in_range(5.0, 0.0, 5.0) = true);
```

### **Layer 3: Functional Testing (Core Behavior)**
**Purpose**: Test core functionality and mathematical correctness

**What to Test**:
- Main functional behavior of each function
- Mathematical correctness and precision
- Function integration and composition
- Performance characteristics
- Functional edge cases

**Key Patterns**:
- Test core functionality produces correct results
- Test mathematical operations are accurate
- Test function composition works correctly

**Example**:
```vhdl
-- Test core functionality
test_passed := (add_voltages(1.0, 2.0) = 3.0);

-- Test function composition
test_passed := (voltage_to_digital(add_voltages(1.0, 2.0)) = x"4CCC");
```

### **Layer 4: Configuration Testing (Constants and Types)**
**Purpose**: Test different configurations and constant values

**What to Test**:
- Different constant values and configurations
- Type variations and edge cases
- Configuration validation
- Package constant behavior

**Key Patterns**:
- Test edge cases around constant values
- Test different type configurations
- Test constant validation limits

**Example**:
```vhdl
-- Test constant behavior
test_passed := (VOLTAGE_DATA_WIDTH = 16);

-- Test type edge cases
test_passed := (t_probe_config'left = 1);
```

## Implementation Guidelines

### **Test Structure**
```vhdl
-- ============================================================================
-- LAYER 1: INTERFACE TESTING (Function Signatures)
-- ============================================================================
write(l, string'("--- Layer 1: Interface Testing (Function Signatures) ---"));
writeline(output, l);

-- Test 1: Function parameter validation
-- Test 2: Return value types and ranges
-- Test 3: Package initialization

-- ============================================================================
-- LAYER 2: VALIDATION TESTING (Error Handling)
-- ============================================================================
write(l, string'("--- Layer 2: Validation Testing (Error Handling) ---"));
writeline(output, l);

-- Test 4: Invalid input handling
-- Test 5: Boundary conditions
-- Test 6: Error conditions

-- ============================================================================
-- LAYER 3: FUNCTIONAL TESTING (Core Behavior)
-- ============================================================================
write(l, string'("--- Layer 3: Functional Testing (Core Behavior) ---"));
writeline(output, l);

-- Test 7: Core functionality
-- Test 8: Mathematical correctness
-- Test 9: Function integration

-- ============================================================================
-- LAYER 4: CONFIGURATION TESTING (Constants and Types)
-- ============================================================================
write(l, string'("--- Layer 4: Configuration Testing (Constants and Types) ---"));
writeline(output, l);

-- Test 10: Constant values
-- Test 11: Type definitions
-- Test 12: Configuration variations

-- ============================================================================
-- PACKAGE INTEGRATION TESTING
-- ============================================================================
write(l, string'("--- Package Integration Testing ---"));
writeline(output, l);

-- Test 13: Cross-package function calls
-- Test 14: Package dependencies
-- Test 15: Package initialization
```

### **Test Naming Convention**
- **Layer 1**: "Function parameter validation", "Return value types", "Package initialization"
- **Layer 2**: "Invalid input handling", "Boundary conditions", "Error conditions"
- **Layer 3**: "Core functionality", "Mathematical correctness", "Function integration"
- **Layer 4**: "Constant values", "Type definitions", "Configuration variations"
- **Integration**: "Cross-package function calls", "Package dependencies", "Package initialization"

### **Test Validation Patterns**
```vhdl
-- Interface Testing: Test function signatures
test_passed := (function_name(valid_input) = expected_output);

-- Validation Testing: Test error handling
test_passed := (function_name(invalid_input) = expected_error_result);

-- Functional Testing: Test core behavior
test_passed := (function_name(input) = mathematically_correct_result);

-- Configuration Testing: Test constants and types
test_passed := (CONSTANT_NAME = expected_value);
```

## Datadef-Specific Testing Patterns

### **Mathematical Precision Testing**
```vhdl
-- Test with tolerance for floating-point operations
test_passed := (abs(actual_result - expected_result) < tolerance);

-- Test exact equality for integer operations
test_passed := (actual_result = expected_result);
```

### **Type Definition Testing**
```vhdl
-- Test record type initialization
test_passed := (DEFAULT_RECORD.field_name = expected_value);

-- Test array type bounds
test_passed := (array_type'left = expected_left and array_type'right = expected_right);
```

### **Constant Validation Testing**
```vhdl
-- Test constant values
test_passed := (CONSTANT_NAME = expected_value);

-- Test constant relationships
test_passed := (CONSTANT_A + CONSTANT_B = CONSTANT_C);
```

### **Function Composition Testing**
```vhdl
-- Test function chaining
test_passed := (function_b(function_a(input)) = expected_result);

-- Test inverse operations
test_passed := (function_inverse(function_forward(input)) = input);
```

## Package Testbench Template

### **Basic Structure**
```vhdl
-- Datadef Package Testbench Template
-- Standard template for all VOLO VHDL datadef package testbenches
-- Follows the 4-layer testing architecture for comprehensive coverage

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities
use WORK.<package_name>_pkg.ALL;   -- Package under test

entity <package_name>_pkg_tb is
end entity <package_name>_pkg_tb;

architecture test of <package_name>_pkg_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
        -- Test variables (customize for your package)
        variable test_voltage : real;
        variable test_digital : signed(15 downto 0);
        variable test_result : real;
        variable test_bool : boolean;
        
    begin
        -- Test initialization
        write(l, string'("=== <Package Name> Package TestBench Started ==="));
        writeline(output, l);
        
        -- Implement 4-layer testing here
        -- (See detailed structure above)
        
        -- Final results
        print_test_completion(all_tests_passed);
        
        wait for 100 ns;
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;
```

## Compliance Requirements

### **Mandatory Elements**
- [ ] All 4 layers implemented
- [ ] Clear layer separation in comments
- [ ] Interface testing (function signatures)
- [ ] Validation testing (error handling)
- [ ] Functional testing (core behavior)
- [ ] Configuration testing (constants and types)
- [ ] Package integration testing

### **Quality Standards**
- [ ] Tests focus on package interface
- [ ] Mathematical correctness validation
- [ ] Comprehensive error handling coverage
- [ ] Edge case testing
- [ ] Clear test naming and organization

### **Output Requirements**
- [ ] Layer headers in test output
- [ ] Clear test descriptions
- [ ] Proper use of `report_test()` procedure
- [ ] Final test completion with `print_test_completion()`

## Common Pitfalls

### **❌ Implementation-Dependent Testing**
```vhdl
-- BAD: Testing internal implementation
test_passed := (internal_variable = expected_value);
```

### **❌ Mixed Layer Concerns**
```vhdl
-- BAD: Mixing interface and functional testing
test_passed := (function_name(input) = result and internal_state = expected);
```

### **❌ Missing Layer Coverage**
```vhdl
-- BAD: Only testing functional behavior
-- Missing interface, validation, and configuration testing
```

### **✅ Correct Datadef Testing**
```vhdl
-- GOOD: Clear layer separation
-- Layer 1: Interface testing
test_passed := (function_name(valid_input) = expected_output);

-- Layer 2: Validation testing  
test_passed := (function_name(invalid_input) = expected_error_result);

-- Layer 3: Functional testing
test_passed := (function_name(input) = mathematically_correct_result);

-- Layer 4: Configuration testing
test_passed := (CONSTANT_NAME = expected_value);
```

## Integration with VOLO Workflow

### **Template Integration**
- Use datadef testbench template for all package testbenches
- Follow template structure and patterns
- Customize only package-specific elements

### **Documentation Integration**
- Reference this document in all datadef testbench development
- Use as checklist for testbench compliance
- Update with new patterns and best practices

### **Quality Assurance**
- All datadef testbenches must pass layered architecture compliance
- Code reviews must verify layer separation
- Continuous integration must validate test structure

## Special Considerations

### **Floating-Point Testing**
- Use tolerance-based comparisons for real types
- Test edge cases around zero and infinity
- Validate precision requirements

### **Type Definition Testing**
- Test record field initialization
- Test array bounds and indexing
- Test type conversion functions

### **Package Dependencies**
- Test cross-package function calls
- Test dependency resolution order
- Test package initialization

### **Constant Testing**
- Test constant values and relationships
- Test constant usage in functions
- Test configuration variations

---

**This datadef testbench architecture ensures that all VOLO VHDL packages are tested comprehensively, maintainably, and in a way that serves as living documentation of package capabilities.**

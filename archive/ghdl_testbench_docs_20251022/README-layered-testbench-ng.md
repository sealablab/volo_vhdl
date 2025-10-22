# Layered Testbench Architecture - VOLO VHDL Standard

## Overview
The Layered Testbench Architecture is the **mandatory testing approach** for all VOLO VHDL modules. It ensures comprehensive, maintainable, and implementation-independent testing.

## Core Philosophy
**Test WHAT the module does, not HOW it does it.**

This principle ensures that:
- Tests remain valid when internal implementation changes
- Tests focus on external observable behavior
- Tests are maintainable and understandable
- Tests serve as living documentation of module behavior

## The 4-Layer Architecture

### **Layer 1: Interface Testing (Status Register)**
**Purpose**: Test external behavior only - no assumptions about internal state machine

**What to Test**:
- Status register bit behavior for given inputs
- External interface compliance
- Signal timing and edge behavior
- Output signal validity

**What NOT to Test**:
- Internal state machine transitions
- Implementation-specific logic
- Internal signal values

**Example**:
```vhdl
-- ✅ GOOD: Test external behavior
test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');

-- ❌ BAD: Test implementation details
test_passed := (current_state = READY_STATE);
```

### **Layer 2: Validation Testing**
**Purpose**: Test parameter validation and error handling

**What to Test**:
- Invalid parameter handling
- Validation failure responses
- Error status bit setting
- Safe state behavior on validation failure

**Key Patterns**:
- Test invalid inputs trigger appropriate status bits
- Test valid inputs allow normal operation
- Test validation edge cases

**Example**:
```vhdl
-- Test invalid input triggers validation failure
counter_in <= x"0000"; -- Invalid (below minimum)
wait until rising_edge(clk);
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' or 
               stat_status_out(STATUS_ALARM_BIT) = '1');
```

### **Layer 3: Functional Testing**
**Purpose**: Test core functionality and behavior

**What to Test**:
- Main functional behavior
- Specific feature operation
- Performance characteristics
- Functional edge cases

**Key Patterns**:
- Test core functionality completes without errors
- Test specific behaviors (alarms, thresholds, etc.)
- Test functional edge cases

**Example**:
```vhdl
-- Test core functionality
counter_in <= x"0003";
wait until rising_edge(clk);
-- Wait for countdown to complete
wait until rising_edge(clk);
wait until rising_edge(clk);
wait until rising_edge(clk);
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0');
```

### **Layer 4: Generic Parameter Testing**
**Purpose**: Test different generic values and parameter variations

**What to Test**:
- Different generic parameter values
- Generic validation limits
- Parameter edge cases
- Configuration variations

**Key Patterns**:
- Test edge cases around generic values
- Test different generic configurations
- Test generic validation limits

**Example**:
```vhdl
-- Test alarm threshold edge cases
counter_in <= x"0001"; -- Below threshold
wait until rising_edge(clk);
test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
```

## Implementation Guidelines

### **Test Structure**
```vhdl
-- ============================================================================
-- LAYER 1: INTERFACE TESTING (Status Register)
-- ============================================================================
write(l, string'("--- Layer 1: Interface Testing (Status Register) ---"));
writeline(output, l);

-- Test 1: Reset behavior - module should be in safe state
-- Test 2: Enable behavior - module should show enabled status

-- ============================================================================
-- LAYER 2: VALIDATION TESTING
-- ============================================================================
write(l, string'("--- Layer 2: Validation Testing ---"));
writeline(output, l);

-- Test 3: Invalid input - validation failure
-- Test 4: Valid input - normal operation

-- ============================================================================
-- LAYER 3: FUNCTIONAL TESTING
-- ============================================================================
write(l, string'("--- Layer 3: Functional Testing ---"));
writeline(output, l);

-- Test 5: Core functionality - no faults
-- Test 6: Specific functional behavior

-- ============================================================================
-- LAYER 4: GENERIC PARAMETER TESTING
-- ============================================================================
write(l, string'("--- Layer 4: Generic Parameter Testing ---"));
writeline(output, l);

-- Test 7: Generic parameter edge cases

-- ============================================================================
-- CONTROL SIGNAL TESTING
-- ============================================================================
write(l, string'("--- Control Signal Testing ---"));
writeline(output, l);

-- Test 8: Module disable - safe state
-- Test 9: Module re-enable - normal operation
```

### **Test Naming Convention**
- **Layer 1**: "Reset behavior - safe state", "Enable behavior - enabled status"
- **Layer 2**: "Invalid input - validation failure", "Valid input - normal operation"
- **Layer 3**: "Core functionality - no faults", "Specific functional behavior"
- **Layer 4**: "Generic parameter edge case", "Configuration variation"
- **Control**: "Module disable - safe state", "Module re-enable - normal operation"

### **Test Validation Patterns**
```vhdl
-- Interface Testing: Test status register bits
test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');

-- Validation Testing: Test error handling
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' or 
               stat_status_out(STATUS_ALARM_BIT) = '1');

-- Functional Testing: Test core behavior
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0');

-- Generic Testing: Test parameter variations
test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
```

## Benefits of Layered Architecture

### **Maintainability**
- Tests remain valid when implementation changes
- Clear separation of concerns
- Easy to understand and modify

### **Comprehensive Coverage**
- Interface behavior (Layer 1)
- Error handling (Layer 2)
- Core functionality (Layer 3)
- Parameter variations (Layer 4)

### **Documentation Value**
- Tests serve as living documentation
- Clear behavior specification
- Usage examples for module interface

### **Debugging Efficiency**
- Clear test organization
- Easy to identify failure categories
- Systematic debugging approach

## Compliance Requirements

### **Mandatory Elements**
- [ ] All 4 layers implemented
- [ ] Clear layer separation in comments
- [ ] Interface testing (no implementation assumptions)
- [ ] Validation testing (error handling)
- [ ] Functional testing (core behavior)
- [ ] Generic parameter testing (edge cases)
- [ ] Control signal testing (enable/disable)

### **Quality Standards**
- [ ] Tests focus on external behavior
- [ ] No assumptions about internal state machine
- [ ] Comprehensive error handling coverage
- [ ] Edge case testing
- [ ] Clear test naming and organization

### **Output Requirements**
- [ ] Layer headers in test output
- [ ] Clear test descriptions
- [ ] Proper use of `report_test()` procedure
- [ ] Final test completion with `print_test_completion()`

## Template Usage

### **Starting a New Testbench**
1. Copy `layered_testbench_template.vhd`
2. Replace `<module_name>` with your module name
3. Add module-specific signals and port mappings
4. Implement tests for each layer
5. Follow naming conventions and patterns

### **Customization Guidelines**
- **Layer 1**: Always test reset and enable behavior
- **Layer 2**: Always test validation failure and success
- **Layer 3**: Always test core functionality
- **Layer 4**: Always test generic parameter edge cases
- **Control**: Always test enable/disable behavior

## Common Pitfalls

### **❌ Implementation-Dependent Testing**
```vhdl
-- BAD: Testing internal state
test_passed := (current_state = READY_STATE);
```

### **❌ Mixed Layer Concerns**
```vhdl
-- BAD: Mixing interface and functional testing
test_passed := (stat_status_out(STATUS_READY_BIT) = '1' and 
               counter_register = 5);
```

### **❌ Missing Layer Coverage**
```vhdl
-- BAD: Only testing functional behavior
-- Missing interface, validation, and generic testing
```

### **✅ Correct Layered Testing**
```vhdl
-- GOOD: Clear layer separation
-- Layer 1: Interface testing
test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');

-- Layer 2: Validation testing  
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1');

-- Layer 3: Functional testing
test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0');

-- Layer 4: Generic testing
test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
```

## Integration with VOLO Workflow

### **Template Integration**
- Use `layered_testbench_template.vhd` for all new testbenches
- Follow template structure and patterns
- Customize only module-specific elements

### **Documentation Integration**
- Reference this document in all testbench development
- Use as checklist for testbench compliance
- Update with new patterns and best practices

### **Quality Assurance**
- All testbenches must pass layered architecture compliance
- Code reviews must verify layer separation
- Continuous integration must validate test structure

---

**This layered testbench architecture ensures that all VOLO VHDL modules are tested comprehensively, maintainably, and in a way that serves as living documentation of module behavior.**
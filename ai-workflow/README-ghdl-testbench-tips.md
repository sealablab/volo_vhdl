# GHDL Testbench Development Tips and Best Practices

## Overview
This document provides practical tips and solutions for common issues encountered when developing VHDL testbenches with GHDL, based on real-world experience from the Volo VHDL project.

## Common Compilation Issues and Solutions

### 1. Procedure Parameter Passing Issues

**Problem**: `error: variable parameter must be a variable`
```vhdl
procedure report_test(test_name : string; passed : boolean; test_num : inout natural);
-- Called with signal instead of variable
report_test("Test name", test_passed, test_number); -- test_number is a signal
```

**Solution**: Use local variables in processes, not signals for procedure parameters
```vhdl
process
    variable local_test_number : natural := 0;  -- Use variable, not signal
begin
    report_test("Test name", test_passed, local_test_number);
end process;
```

**Alternative**: Avoid procedures entirely and use direct test reporting
```vhdl
test_number := test_number + 1;
if test_passed then
    write(l, string'("Test " & integer'image(test_number) & ": Test name - PASSED"));
else
    write(l, string'("Test " & integer'image(test_number) & ": Test name - FAILED"));
end if;
writeline(output, l);
```

### 2. Signal vs Variable Confusion

**Problem**: Mixing signals and variables inappropriately
- Signals: Used for inter-process communication, updated on clock edges
- Variables: Used for local computation within processes, updated immediately

**Best Practice**: 
- Use variables for test counters and local computations
- Use signals only for DUT connections and inter-process communication
- Initialize variables at declaration: `variable test_num : natural := 0;`

### 3. String Concatenation and Bit Width Issues

**Problem**: `error: string length does not match that of anonymous integer subtype`
```vhdl
status_reg(6 downto 3) <= "000";  -- Wrong: 3 bits assigned to 4-bit slice
```

**Solution**: Match exact bit widths
```vhdl
status_reg(6 downto 3) <= "0000";  -- Correct: 4 bits assigned to 4-bit slice
```

**Alternative**: Use individual bit assignments
```vhdl
status_reg(7) <= enabled_reg;
status_reg(6 downto 3) <= "0000";
status_reg(2 downto 0) <= wave_select_reg;
```

### 4. Array Bounds and Index Overflow

**Problem**: `bound check failure` when accessing arrays
```vhdl
sine_phase <= sine_phase + 1;  -- Can overflow beyond array bounds
sine_output <= sine_lut(to_integer(sine_phase));  -- Index out of bounds
```

**Solution**: Add bounds checking
```vhdl
if sine_phase >= 127 then
    sine_phase <= (others => '0');
else
    sine_phase <= sine_phase + 1;
end if;
sine_output <= sine_lut(to_integer(sine_phase));
```

### 5. Compilation Order Dependencies

**Problem**: `error: architecture "test" of "entity" is obsoleted by entity "other_entity"`
- Occurs when recompiling entities that other files depend on

**Solution**: Always recompile in dependency order
```bash
# 1. Compile dependencies first
ghdl -a --std=08 modules/dependency/package.vhd

# 2. Compile entities
ghdl -a --std=08 modules/module/core/entity.vhd

# 3. Compile testbenches
ghdl -a --std=08 modules/module/tb/core/entity_tb.vhd

# 4. Elaborate
ghdl -e --std=08 entity_tb

# 5. Run
ghdl -r --std=08 entity_tb
```

## Testbench Design Best Practices

### 1. Test Structure and Organization

**Recommended Structure**:
```vhdl
library STD.ENV.all;  -- For stop() function

test_process : process
    variable l : line;
    variable test_passed : boolean;
    variable test_number : natural := 0;
begin
    -- Test initialization
    write(l, string'("=== TestBench Started ==="));
    writeline(output, l);
    
    -- Individual tests with clear reporting
    test_passed := (actual_result = expected_result);
    test_number := test_number + 1;
    if test_passed then
        write(l, string'("Test " & integer'image(test_number) & ": Description - PASSED"));
    else
        write(l, string'("Test " & integer'image(test_number) & ": Description - FAILED"));
    end if;
    writeline(output, l);
    
    -- Final results
    if all_tests_passed then
        write(l, string'("ALL TESTS PASSED"));
    else
        write(l, string'("TEST FAILED"));
    end if;
    writeline(output, l);
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    
    stop(0); -- Clean termination (recommended)
    -- Alternative: assert false report "Simulation completed" severity failure;
end process;
```

### 2. Clock and Timing Management

**Clock Generation**:
```vhdl
clk_process : process
begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
end process;
```

**Clock Enable Simulation**:
```vhdl
clk_en_process : process
begin
    clk_en <= '0';
    wait for CLK_PERIOD * 3;  -- Low period
    clk_en <= '1';
    wait for CLK_PERIOD;      -- High period
end process;
```

### 3. Reset and Initialization

**Proper Reset Testing**:
```vhdl
-- Apply reset
rst <= '1';
wait for CLK_PERIOD * 2;  -- Ensure reset is held long enough
rst <= '0';
wait for CLK_PERIOD;      -- Wait for reset to propagate

-- Test reset behavior
test_passed := (output = expected_reset_value) and (status = expected_status);
```

### 4. State Machine and Output Testing

**Testing State Changes**:
```vhdl
-- Wait for clock enable
wait until clk_en = '1';
prev_output := current_output;
wait for CLK_PERIOD;
wait until clk_en = '1';
wait for CLK_PERIOD;

-- Check for expected change
test_passed := (current_output /= prev_output) and (current_output = expected_value);
```

## Common Runtime Issues and Solutions

### 1. Infinite Simulation Loops

**Problem**: Testbench runs indefinitely without completing

**Root Cause**: The `wait;` statement at the end of test processes can cause GHDL to hang indefinitely in some cases.

**Solution 1 (Recommended)**: Use `std.env.stop()` for clean termination
```vhdl
library STD.ENV.all;  -- Add this to library declarations

test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    stop(0); -- Clean termination with exit code 0
end process;
```

**Solution 2 (Alternative)**: Use `assert false` to force termination
```vhdl
test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    assert false report "Simulation completed" severity failure;
end process;
```

**Solution 3 (Backup)**: Add a timeout process as safety mechanism
```vhdl
-- Safety timeout process (use only if needed)
timeout_process : process
    variable l : line;
begin
    wait for 10 ms;  -- Maximum simulation time
    write(l, string'("ERROR: Simulation timeout - forcing termination"));
    writeline(output, l);
    stop(1);  -- Exit with error code
end process;
```

**Note**: The timeout approach with while loops and clock counting is overly complex for most testbenches. Use `stop()` or `assert false` instead. Only add timeout processes if you have specific timing requirements or are debugging complex clock enable scenarios.

**When to Avoid Complex Timeout Logic**:
- Simple testbenches with deterministic test sequences
- Tests that don't depend on external clock enable signals
- Most educational and verification testbenches
- When you can control the test flow with fixed wait times

**When Complex Timeout Might Be Needed**:
- Testing modules with complex clock enable dependencies
- Debugging timing-sensitive issues
- Integration tests with multiple clock domains
- When external signals might not behave as expected

### 2. Metavalue Warnings

**Problem**: `NUMERIC_STD.">": metavalue detected, returning FALSE`
- Occurs when comparing signals with 'U' (uninitialized) values

**Solution**: Ensure all signals are properly initialized
```vhdl
-- Initialize all signals
signal test_signal : std_logic_vector(15 downto 0) := (others => '0');
signal test_enable : std_logic := '0';

-- Or reset before testing
rst <= '1';
wait for CLK_PERIOD;
rst <= '0';
wait for CLK_PERIOD;
```

### 3. Timing and Synchronization Issues

**Problem**: Tests fail due to timing mismatches

**Solution**: Use proper wait conditions
```vhdl
-- Wait for specific conditions
wait until clk_en = '1';
wait for CLK_PERIOD;

-- Or wait for multiple clock cycles
wait for CLK_PERIOD * 5;
```

## Debugging Techniques

### 1. Signal Monitoring

**Add debug output to track signal values**:
```vhdl
-- Debug output
write(l, string'("Debug: wave_out = " & to_hstring(wave_out)));
write(l, string'("Debug: fault_out = " & std_logic'image(fault_out)));
write(l, string'("Debug: stat = " & to_hstring(stat)));
writeline(output, l);
```

### 2. Step-by-Step Testing

**Break complex tests into smaller steps**:
```vhdl
-- Test 1: Basic functionality
-- Test 2: Edge cases
-- Test 3: Error conditions
-- Test 4: Integration
```

### 3. Expected vs Actual Comparison

**Always compare expected vs actual values**:
```vhdl
test_passed := (actual_value = expected_value);
if not test_passed then
    write(l, string'("Expected: " & to_hstring(expected_value)));
    write(l, string'("Actual: " & to_hstring(actual_value)));
    writeline(output, l);
end if;
```

## GHDL-Specific Considerations

### 1. VHDL Standard Compliance

**Always use `--std=08` flag**:
```bash
ghdl -a --std=08 file.vhd
ghdl -e --std=08 entity_name
ghdl -r --std=08 entity_name
```

### 2. Direct Instantiation

**Use direct instantiation in testbenches**:
```vhdl
-- Recommended
DUT: entity WORK.entity_name
    port map (
        clk => clk,
        rst => rst,
        -- ... other ports
    );

-- Avoid component declarations in testbenches
```

### 3. File Organization

**Follow project directory structure**:
```
modules/module_name/
├── core/           # RTL entities
├── tb/core/        # Core testbenches
├── tb/top/         # Top-level testbenches
└── tb/datadef/     # Package testbenches
```

## Summary Checklist

Before submitting a testbench, ensure:

- [ ] All signals are properly initialized
- [ ] Test process ends with `stop(0)` or `assert false` (not `wait;`)
- [ ] Uses variables for local computations, signals for DUT connections
- [ ] Proper reset testing with adequate timing
- [ ] Clear test reporting with PASSED/FAILED messages
- [ ] Final "ALL TESTS PASSED" or "TEST FAILED" message
- [ ] "SIMULATION DONE" message
- [ ] Compiles with `ghdl --std=08` without errors
- [ ] Runs to completion without infinite loops
- [ ] Tests all required functionality and edge cases
- [ ] Uses direct instantiation for DUT
- [ ] Follows project coding standards

## Quick Reference Commands

```bash
# Compile in order
ghdl -a --std=08 dependency.vhd
ghdl -a --std=08 entity.vhd
ghdl -a --std=08 entity_tb.vhd

# Elaborate and run
ghdl -e --std=08 entity_tb
ghdl -r --std=08 entity_tb

# Clean up artifacts
rm -f work-obj*.cf *_tb *.o *.exe
```

This guide should help avoid common pitfalls and ensure robust, maintainable testbenches that work reliably with GHDL.
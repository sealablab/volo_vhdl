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

### 6. Successful Compilation Patterns (From State Machine Base)

**What Worked Well**: The state machine base compiled successfully with minimal issues. Key patterns:

#### **Clean Entity/Architecture Structure**
```vhdl
-- Simple, clear entity declaration
entity state_machine_base is
    generic (
        MODULE_NAME : string := "state_machine_base";
        STATUS_REG_WIDTH : integer := 32;
        MODULE_STATUS_BITS : integer := 16
    );
    port (
        -- Clear, well-documented ports
        clk : in std_logic;
        rst_n : in std_logic;
        -- ... other ports
    );
end entity state_machine_base;
```

#### **Process Organization**
```vhdl
-- Separate processes for different concerns
-- 1. Parameter validation (combinational)
parameter_validation : process(cfg_param1, cfg_param2, cfg_param3)
begin
    -- Simple validation logic
end process;

-- 2. State machine (clocked)
state_machine_proc : process(clk, rst_n)
begin
    if rst_n = '0' then
        current_state <= ST_RESET;
    elsif rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;

-- 3. Status register (clocked)
status_reg_proc : process(clk, rst_n)
begin
    if rst_n = '0' then
        status_reg <= (others => '0');
    elsif rising_edge(clk) then
        -- Update status register
    end if;
end process;
```

#### **Avoid These Patterns (Caused Compilation Errors)**
```vhdl
-- ❌ Complex aggregates with non-static choices
status_reg <= (31 => fault_bit, 30 downto 28 => (others => '0'), ...);

-- ❌ Mixing signal and variable types in procedures
procedure report_test(test_name : string; passed : boolean; test_num : inout natural);
-- Called with signal instead of variable

-- ❌ Incorrect bit width assignments
status_reg(6 downto 3) <= "000";  -- 3 bits to 4-bit slice
```

#### **Use These Patterns Instead**
```vhdl
-- ✅ Simple process assignments
status_reg(31) <= fault_bit;
status_reg(30 downto 28) <= (others => '0');
status_reg(27 downto 24) <= current_state;

-- ✅ Use variables for local computations
variable test_number : natural := 0;
report_test("Test name", test_passed, test_number);

-- ✅ Match exact bit widths
status_reg(6 downto 3) <= "0000";  -- 4 bits to 4-bit slice
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

## Recent Success Patterns (State Machine Base Implementation)

### What Made This Implementation Successful

The state machine base template was implemented with minimal compilation issues. Here are the key patterns that worked well:

#### 1. **Proper Signal Initialization**
```vhdl
-- Initialize all signals with explicit values
signal current_state : std_logic_vector(3 downto 0) := ST_RESET;
signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
signal cfg_param_valid : std_logic;  -- No initialization needed for combinational signals
```

#### 2. **Clean Process Structure**
```vhdl
-- Separate processes for different concerns
state_machine_proc : process(clk, rst_n)  -- Clocked process
parameter_validation : process(cfg_param1, cfg_param2, cfg_param3)  -- Combinational process
status_reg_proc : process(clk, rst_n)  -- Clocked process
```

#### 3. **Proper Clock Edge Handling in Testbenches**
```vhdl
-- Wait for clock edges before checking status register updates
wait_clk(1);  -- Wait for status register to update
check_status_bit(31, '0', "FAULT bit reset to 0");
```

#### 4. **Clear State Encoding**
```vhdl
-- Use clear, documented state encodings
constant ST_RESET      : std_logic_vector(3 downto 0) := "0000";  -- 0x0
constant ST_READY      : std_logic_vector(3 downto 0) := "0001";  -- 0x1
constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
```

#### 5. **Avoid Complex Aggregates**
```vhdl
-- Instead of complex aggregates (which caused compilation errors):
-- status_reg <= (31 => fault_bit, 30 downto 28 => (others => '0'), ...);

-- Use simple process assignments:
status_reg(31) <= fault_bit;
status_reg(30 downto 28) <= (others => '0');
status_reg(27 downto 24) <= current_state;
```

#### 6. **Testbench Timing Patterns**
```vhdl
-- Pattern that worked well for state machine testing:
-- 1. Apply reset
-- 2. Wait for clock edge
-- 3. Check initial state
-- 4. Apply inputs
-- 5. Wait for clock edge
-- 6. Check results
-- 7. Repeat for next test
```

### Key Success Factors

1. **Explicit Initialization**: All signals properly initialized
2. **Process Separation**: Different concerns in different processes
3. **Clock-Aware Testing**: Testbenches account for clock delays
4. **Simple Constructs**: Avoid complex VHDL features that cause compilation issues
5. **Clear Documentation**: Well-commented code with clear intent
6. **Incremental Testing**: Test one feature at a time

### What We've Learned

- **VHDL-2008 + Verilog portability** is achievable with careful design
- **Simple, explicit code** compiles more reliably than clever constructs
- **Clock delays in testbenches** are crucial for proper testing
- **Process separation** makes code more maintainable and debuggable
- **Clear state encodings** make debugging much easier

## New Tips from ProbeHero8 Implementation

### 7. Case Statement Constants Issue

**Problem**: `error: choice must be locally static expression`
```vhdl
-- ❌ This causes compilation errors
case ctrl_reg_addr is
    when CTRL_ENABLE_ADDR =>  -- Constant not locally static
        ctrl_enable_internal <= ctrl_reg_data_in(0);
    when others =>
        null;
end case;
```

**Solution**: Use literal values instead of constants in case statements
```vhdl
-- ✅ This compiles correctly
case ctrl_reg_addr is
    when x"00" =>  -- CTRL_ENABLE_ADDR
        ctrl_enable_internal <= ctrl_reg_data_in(0);
    when x"01" =>  -- CTRL_ARM_ADDR
        ctrl_arm_internal <= ctrl_reg_data_in(0);
    when others =>
        null;
end case;
```

**Why**: GHDL requires locally static expressions in case choices. Constants defined in the architecture are not considered locally static.

### 8. Procedure Declaration Location

**Problem**: `error: unexpected token 'procedure' in a concurrent statement list`
```vhdl
-- ❌ Procedures declared in architecture body
architecture test of entity_tb is
begin
    procedure report_test(...) is  -- Error: not allowed here
    begin
        -- procedure body
    end procedure;
    
    test_process : process
    begin
        -- test code
    end process;
end architecture;
```

**Solution**: Declare procedures within processes
```vhdl
-- ✅ Procedures declared within process
architecture test of entity_tb is
begin
    test_process : process
        -- Test Helper Procedures (declared within process)
        procedure report_test(...) is
        begin
            -- procedure body
        end procedure;
        
    begin
        -- test code using procedures
    end process;
end architecture;
```

### 9. Variable vs Signal for Procedure Parameters

**Problem**: `error: variable parameter must be a variable`
```vhdl
-- ❌ Using signal for inout parameter
signal test_number : natural := 0;
procedure report_test(test_name : string; test_num : inout natural);
-- Called with signal
report_test("Test name", test_number);  -- Error: test_number is signal
```

**Solution**: Use variables for procedure parameters
```vhdl
-- ✅ Using variable for inout parameter
test_process : process
    variable test_number : natural := 0;  -- Use variable, not signal
    
    procedure report_test(test_name : string; test_num : inout natural) is
    begin
        -- procedure body
    end procedure;
    
begin
    report_test("Test name", test_number);  -- Correct: test_number is variable
end process;
```

### 10. Testbench Termination Best Practices

**Problem**: Testbench runs indefinitely with `wait;` statement
```vhdl
-- ❌ Can cause infinite loops
test_process : process
begin
    -- ... tests ...
    wait; -- End simulation - can hang indefinitely
end process;
```

**Solution**: Use proper termination methods
```vhdl
-- ✅ Clean termination
library STD.ENV.ALL;  -- Add this to library declarations

test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    
    stop(0); -- Clean termination with exit code 0
end process;
```

**Alternative**: Use assert false for termination
```vhdl
-- ✅ Alternative termination method
test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    
    assert false report "Simulation completed" severity failure;
end process;
```

### 11. Complex Module Integration Patterns

**What Worked Well in ProbeHero8**: The implementation successfully compiled and ran with these patterns:

#### **Direct Instantiation in Top Layer**
```vhdl
-- ✅ Required for top layer files
U1: entity WORK.probe_hero8_core
    generic map (
        MODULE_NAME => "probe_hero8_core",
        STATUS_REG_WIDTH => 32,
        MODULE_STATUS_BITS => 16
    )
    port map (
        clk => clk,
        rst_n => rst_n,
        -- ... other ports
    );
```

#### **Package-Based Configuration**
```vhdl
-- ✅ Use packages for complex data structures
library WORK;
use WORK.probe_config_pkg.ALL;
use WORK.probe_status_pkg.ALL;

-- Configuration record assembly
probe_config <= (
    probe_selection    => cfg_safety_probe_selection,
    firing_voltage     => cfg_safety_firing_voltage,
    firing_duration    => cfg_safety_firing_duration,
    cooling_duration   => cfg_safety_cooling_duration,
    enable_auto_arm    => cfg_safety_enable_auto_arm,
    enable_safety_mode => cfg_safety_enable_safety_mode
);
```

#### **State Machine with Safety Features**
```vhdl
-- ✅ Clear state encoding with safety validation
constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
constant ST_ARMED      : std_logic_vector(3 downto 0) := "0011";  -- 0x3
constant ST_FIRING     : std_logic_vector(3 downto 0) := "0100";  -- 0x4
constant ST_COOLING    : std_logic_vector(3 downto 0) := "0101";  -- 0x5
constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF

-- Parameter validation process
parameter_validation : process(probe_config)
begin
    if is_valid_probe_config(probe_config) then
        cfg_params_valid <= '1';
    else
        cfg_params_valid <= '0';
    end if;
end process;
```

### 12. Compilation Order for Complex Modules

**Successful Compilation Sequence**:
```bash
# 1. Compile packages first (dependency order)
ghdl -a --std=08 modules/probe_hero8/datadef/*.vhd

# 2. Compile core entities
ghdl -a --std=08 modules/probe_hero8/core/*.vhd

# 3. Compile top entities
ghdl -a --std=08 modules/probe_hero8/top/*.vhd

# 4. Compile testbenches
ghdl -a --std=08 modules/probe_hero8/tb/core/*.vhd
ghdl -a --std=08 modules/probe_hero8/tb/top/*.vhd

# 5. Elaborate and run
ghdl -e --std=08 probe_hero8_core_tb
ghdl -r --std=08 probe_hero8_core_tb
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
- [ ] **NEW**: Case statements use literal values, not constants
- [ ] **NEW**: Procedures declared within processes, not in architecture body
- [ ] **NEW**: Procedure parameters use variables, not signals
- [ ] **NEW**: Includes `library STD.ENV.ALL;` for proper termination

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
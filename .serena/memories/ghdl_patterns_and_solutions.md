# GHDL Patterns and Solutions - Comprehensive Reference

This memory consolidates all GHDL compilation patterns, testbench best practices, and design patterns discovered during the Volo VHDL project development.

**Sources Integrated:**
- `ai-workflow/README-ghdl-testbench-tips.md` (560 lines, comprehensive testbench patterns)
- `ai-workflow/README-direct-instantiation.md` (297 lines, direct instantiation guide)
- Real-world errors from EMFI-Seq voltage package development (2025-01-21)

**Last Updated:** 2025-01-21

---

## Table of Contents
1. [Compilation Settings](#compilation-settings)
2. [Common Compilation Errors](#common-compilation-errors)
3. [Direct Instantiation Patterns](#direct-instantiation-patterns)
4. [Testbench Design Patterns](#testbench-design-patterns)
5. [Debugging Techniques](#debugging-techniques)
6. [Success Patterns](#success-patterns)

---

## Compilation Settings

### Standard GHDL Invocation
Always use VHDL-2008 standard for this project:
```bash
ghdl -a --std=08 --work=work <file.vhd>  # Analyze (compile)
ghdl -e --std=08 --work=work <entity>    # Elaborate
ghdl -r --std=08 --work=work <entity>    # Run
```

### Relaxed Mode (Avoid Unless Necessary)
```bash
ghdl -a --std=08 -frelaxed <file.vhd>  # Turns some errors into warnings
```
**Note**: Always fix the code properly instead of using `-frelaxed`.

### Compilation Order
Always compile in dependency order:
```bash
# 1. Packages (declarations and bodies)
ghdl -a --std=08 datadef/Moku_Voltage_pkg_en.vhd

# 2. Core entities
ghdl -a --std=08 core/EMFI_Seq_stair.vhd

# 3. Top-level modules
ghdl -a --std=08 top/EMFI_Seq.vhd

# 4. Testbenches
ghdl -a --std=08 tb/core/tb_EMFI_Seq_stair.vhd

# 5. Elaborate and run
ghdl -e --std=08 tb_EMFI_Seq_stair
ghdl -r --std=08 tb_EMFI_Seq_stair
```

---

## Common Compilation Errors

### Error 1: Variable Name Shadowing (Warning)

**GHDL Message:**
```
warning: declaration of "offset_voltage" hides function "offset_voltage" [-Whide]
    variable offset_voltage : real;
             ^
```

**Problem:** Local variable has the same name as the enclosing function/procedure.

**Code That Triggers It:**
```vhdl
function offset_voltage(voltage : real; offset : real) return real is
    variable offset_voltage : real;  -- ⚠️ Shadows function name
begin
    offset_voltage := voltage + offset;
    return clamp_voltage_safe(offset_voltage);
end function;
```

**Solution:** Use a different, descriptive variable name:
```vhdl
function offset_voltage(voltage : real; offset : real) return real is
    variable result_voltage : real;  -- ✅ Clear and unambiguous
begin
    result_voltage := voltage + offset;
    return clamp_voltage_safe(result_voltage);
end function;
```

**Lesson:** While legal VHDL, shadowing is confusing. Use descriptive names like `result_*`, `temp_*`, or `local_*`.

**Discovered:** EMFI-Seq voltage package development, 2025-01-21

---

### Error 2: Shared Variables Must Be Protected Types (VHDL-2008)

**GHDL Message:**
```
error: type of a shared variable must be a protected type
    shared variable test_count : natural := 0;
                    ^
note: (you can use -frelaxed to turn this error into a warning)
```

**Problem:** VHDL-2008 requires shared variables to be protected types to prevent race conditions.

**Code That Triggers It:**
```vhdl
-- At architecture level (outside process)
shared variable test_count : natural := 0;
shared variable pass_count : natural := 0;

-- Helper procedure trying to access them
procedure check_test(...) is
begin
    test_count := test_count + 1;  -- Compile error in VHDL-2008
    ...
end procedure;
```

**Solution A: Use Local Variables in Process (Preferred for Single-Process Testbenches)**
```vhdl
test_process : process
    -- Move variables inside the process
    variable test_count : natural := 0;
    variable pass_count : natural := 0;
    variable fail_count : natural := 0;

    -- Helper procedures must also be inside the process
    procedure check_test(
        test_name : string;
        condition : boolean
    ) is
    begin
        test_count := test_count + 1;
        if condition then
            pass_count := pass_count + 1;
            report "PASS: " & test_name severity note;
        else
            fail_count := fail_count + 1;
            report "FAIL: " & test_name severity error;
        end if;
    end procedure;
begin
    -- Test code here
    check_test("My test", some_signal = expected_value);
    ...
end process;
```

**Solution B: Use Signals Instead (For Multi-Process Testbenches)**
```vhdl
-- At architecture level
signal test_count : natural := 0;
signal pass_count : natural := 0;

-- Helper procedure with signal parameters
procedure check_test(
    signal test_cnt : inout natural;
    signal pass_cnt : inout natural;
    signal fail_cnt : inout natural;
    test_name : string;
    condition : boolean
) is
begin
    test_cnt <= test_cnt + 1;
    if condition then
        pass_cnt <= pass_cnt + 1;
        ...
    end if;
    wait for 0 ns;  -- Allow signal updates
end procedure;
```

**Solution C: Define Protected Type (Advanced, Rarely Needed)**
```vhdl
-- Define protected type (usually in a package)
type test_counter_type is protected
    procedure increment;
    impure function get_count return natural;
end protected;

type test_counter_type is protected body
    variable count : natural := 0;
    
    procedure increment is
    begin
        count := count + 1;
    end procedure;
    
    impure function get_count return natural is
    begin
        return count;
    end function;
end protected body;

-- Usage
shared variable test_counter : test_counter_type;
```

**Recommendation:**
- **Single-process testbenches**: Use Solution A (local variables)
- **Multi-process testbenches**: Use Solution B (signals)
- **Complex synchronization needs**: Use Solution C (protected types)

**Why This Changed:** VHDL-93 allowed unprotected shared variables, but this was error-prone. VHDL-2008 enforces thread-safe access patterns.

**Discovered:** EMFI-Seq voltage package testbench, 2025-01-21

---

### Error 3: Procedure Parameter Passing Issues

**GHDL Message:**
```
error: variable parameter must be a variable
```

**Problem:** Passing a signal to a procedure that expects a variable parameter.

**Code That Triggers It:**
```vhdl
procedure report_test(test_name : string; passed : boolean; test_num : inout natural);
-- Called with signal instead of variable
report_test("Test name", test_passed, test_number); -- test_number is a signal
```

**Solution:** Use local variables in processes, not signals for procedure parameters:
```vhdl
process
    variable local_test_number : natural := 0;  -- Use variable, not signal
begin
    report_test("Test name", test_passed, local_test_number);
end process;
```

**Alternative:** Avoid procedures entirely and use direct test reporting:
```vhdl
test_number := test_number + 1;
if test_passed then
    report "Test " & integer'image(test_number) & ": Test name - PASSED" severity note;
else
    report "Test " & integer'image(test_number) & ": Test name - FAILED" severity error;
end if;
```

---

### Error 4: String Length Mismatch / Bit Width Issues

**GHDL Message:**
```
error: string length does not match that of anonymous integer subtype
```

**Problem:** Bit width mismatch in assignment.

**Code That Triggers It:**
```vhdl
status_reg(6 downto 3) <= "000";  -- Wrong: 3 bits assigned to 4-bit slice
```

**Solution:** Match exact bit widths:
```vhdl
status_reg(6 downto 3) <= "0000";  -- Correct: 4 bits assigned to 4-bit slice
```

**Alternative:** Use individual bit assignments:
```vhdl
status_reg(7) <= enabled_reg;
status_reg(6 downto 3) <= "0000";
status_reg(2 downto 0) <= wave_select_reg;
```

---

### Error 5: Array Bounds and Index Overflow

**GHDL Message:**
```
bound check failure
```

**Problem:** Accessing arrays with out-of-bounds indices.

**Code That Triggers It:**
```vhdl
sine_phase <= sine_phase + 1;  -- Can overflow beyond array bounds
sine_output <= sine_lut(to_integer(sine_phase));  -- Index out of bounds
```

**Solution:** Add bounds checking:
```vhdl
if sine_phase >= 127 then
    sine_phase <= (others => '0');
else
    sine_phase <= sine_phase + 1;
end if;
sine_output <= sine_lut(to_integer(sine_phase));
```

---

### Error 6: Compilation Order Dependencies

**GHDL Message:**
```
error: architecture "test" of "entity" is obsoleted by entity "other_entity"
```

**Problem:** Recompiling entities that other files depend on without recompiling dependents.

**Solution:** Always recompile in dependency order (see [Compilation Order](#compilation-order) above).

---

### Error 7: Metavalue Warnings

**GHDL Message:**
```
NUMERIC_STD.">": metavalue detected, returning FALSE
```

**Problem:** Comparing signals with 'U' (uninitialized) values.

**Solution:** Ensure all signals are properly initialized:
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

---

## Direct Instantiation Patterns

### What is Direct Instantiation?

Direct instantiation uses the `entity` keyword to directly reference and instantiate an entity, eliminating the need for component declarations.

### Basic Syntax

```vhdl
instance_label: entity library_name.entity_name
    port map (
        port_name => signal_name,
        -- ... more ports
    );
```

### Traditional vs Direct Instantiation

**Traditional Component-Based Approach:**
```vhdl
-- Component declaration required
component DCSequencer is
    port (
        Clk : in std_logic;
        Reset : in std_logic;
        DataIn : in std_logic_vector(31 downto 0);
        HIThreshold : in signed(15 downto 0);
        LOThreshold : in signed(15 downto 0);
        DataOutA : out std_logic_vector(31 downto 0);
        DataOutB : out std_logic_vector(31 downto 0)
    );
end component;

-- Then instantiation
DC_SEQUENCER: DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset,
        DataIn => InputA,
        HIThreshold => signed(Control0(31 downto 16)),
        LOThreshold => signed(Control0(15 downto 0)),
        DataOutA => DataOutA,
        DataOutB => DataOutB
    );
```

**Direct Instantiation Approach (Recommended):**
```vhdl
-- No component declaration needed!
DC_SEQUENCER: entity WORK.DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset,
        DataIn => InputA,
        HIThreshold => signed(Control0(31 downto 16)),
        LOThreshold => signed(Control0(15 downto 0)),
        DataOutA => DataOutA,
        DataOutB => DataOutB
    );
```

### Advantages of Direct Instantiation

1. **Reduced Code Verbosity** - Eliminates component declarations
2. **Better Error Detection** - Port mismatches caught at analysis time
3. **Library Flexibility** - Can specify any library explicitly
4. **Compilation Order Benefits** - Automatic dependency resolution

### When to Use Direct Instantiation

**Use Direct Instantiation When:**
- ✅ You have direct access to the entity source
- ✅ The entity is part of your current project
- ✅ You want to minimize code duplication
- ✅ You're working in a modern VHDL environment (VHDL-93+)
- ✅ **MANDATORY for Volo VHDL project top-level files**

**Use Traditional Components When:**
- ⚠️ You need to hide implementation details (black-box approach)
- ⚠️ You're creating reusable IP cores
- ⚠️ You need to support multiple implementations of the same interface
- ⚠️ You're working with legacy VHDL-87 code

### Advanced Direct Instantiation Patterns

**1. Generic Parameter Passing:**
```vhdl
U1: entity WORK.Counter
    generic map (
        WIDTH => 32,
        MAX_VALUE => 1000
    )
    port map (
        clk => clk,
        rst => rst,
        count => counter_out
    );
```

**2. Multiple Instances with Different Configurations:**
```vhdl
-- 8-bit counter
U1: entity WORK.Counter
    generic map (WIDTH => 8)
    port map (clk => clk, rst => rst, count => count8);

-- 16-bit counter  
U2: entity WORK.Counter
    generic map (WIDTH => 16)
    port map (clk => clk, rst => rst, count => count16);
```

**3. Conditional Instantiation with Generate:**
```vhdl
gen_counters: for i in 0 to 3 generate
    U: entity WORK.Counter
        generic map (WIDTH => 8)
        port map (
            clk => clk,
            rst => rst,
            count => counter_array(i)
        );
end generate;
```

### Port Mapping Styles

**Named Association (Recommended):**
```vhdl
U1: entity WORK.DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset,
        DataIn => InputA
    );
```

**Positional Association (Avoid):**
```vhdl
U1: entity WORK.DCSequencer
    port map (Clk, Reset, InputA, HIThreshold, LOThreshold, DataOutA, DataOutB);
```

### Common Pitfalls and Solutions

**1. Missing Library References:**
```vhdl
-- ❌ Wrong - entity not found
U1: entity DCSequencer port map (...);

-- ✅ Correct - specify library
U1: entity WORK.DCSequencer port map (...);
```

**2. Port Type Mismatches:**
```vhdl
-- ❌ Wrong - type mismatch
HIThreshold => Control0(31 downto 16),  -- std_logic_vector vs signed

-- ✅ Correct - use type conversion
HIThreshold => signed(Control0(31 downto 16)),
```

**3. Missing Ports:**
```vhdl
-- ❌ Wrong - missing required ports
U1: entity WORK.DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset
        -- Missing DataIn, HIThreshold, LOThreshold, DataOutA, DataOutB
    );

-- ✅ Correct - all ports mapped
U1: entity WORK.DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset,
        DataIn => InputA,
        HIThreshold => signed(Control0(31 downto 16)),
        LOThreshold => signed(Control0(15 downto 0)),
        DataOutA => DataOutA,
        DataOutB => DataOutB
    );
```

### Best Practices for Direct Instantiation

1. **Always use named association** for clarity and maintainability
2. **Include all required ports** in the port map
3. **Use explicit type conversions** when needed (e.g., `signed()`, `unsigned()`)
4. **Verify library paths** are correct (usually `WORK` for current project)
5. **Check compilation order** - entities must be compiled before architectures that use them

---

## Testbench Design Patterns

### Recommended Testbench Structure

**Complete Template:**
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;  -- For stop() function

entity tb_my_module is
end entity tb_my_module;

architecture sim of tb_my_module is
    -- Clock and timing
    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    
    -- DUT signals
    signal data_in : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out : std_logic_vector(15 downto 0);
    signal enable : std_logic := '0';
    
    -- Helper function for real comparisons
    constant TOLERANCE : real := 0.01;
    function real_equal(a, b : real; tol : real := TOLERANCE) return boolean is
    begin
        return abs(a - b) < tol;
    end function;

begin

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- DUT instantiation (using direct instantiation)
    DUT: entity WORK.my_module
        port map (
            clk => clk,
            rst => rst,
            data_in => data_in,
            data_out => data_out,
            enable => enable
        );

    -- Test process
    test_process: process
        variable test_count : natural := 0;
        variable pass_count : natural := 0;
        variable fail_count : natural := 0;

        -- Helper procedure for test reporting
        procedure check_test(
            test_name : string;
            condition : boolean
        ) is
        begin
            test_count := test_count + 1;
            if condition then
                pass_count := pass_count + 1;
                report "PASS: " & test_name severity note;
            else
                fail_count := fail_count + 1;
                report "FAIL: " & test_name severity error;
            end if;
        end procedure;
    begin
        report "========================================" severity note;
        report "Starting my_module tests" severity note;
        report "========================================" severity note;
        
        -- Apply reset
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test 1: Initial state
        check_test("Reset state", data_out = x"0000");
        
        -- Test 2: Enable module
        enable <= '1';
        data_in <= x"1234";
        wait for CLK_PERIOD;
        check_test("Data propagation", data_out = x"1234");
        
        -- ... more tests ...
        
        -- Report summary
        report "========================================" severity note;
        report "Test Summary:" severity note;
        report "  Total tests: " & integer'image(test_count) severity note;
        report "  Passed:      " & integer'image(pass_count) severity note;
        report "  Failed:      " & integer'image(fail_count) severity note;
        report "========================================" severity note;
        
        if fail_count = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TEST FAILED" severity error;
        end if;
        
        report "SIMULATION DONE" severity note;
        std.env.stop(0);
    end process;

end architecture sim;
```

### Signal vs Variable Best Practices

**Use Signals For:**
- DUT port connections
- Inter-process communication
- Clock and reset signals

**Use Variables For:**
- Test counters and local computations (inside processes)
- Temporary calculations
- Loop counters

**Initialization:**
```vhdl
-- Signals: Initialize at declaration
signal test_signal : std_logic_vector(15 downto 0) := (others => '0');

-- Variables: Initialize inside process
variable test_count : natural := 0;
```

### Testbench Termination Patterns

**Method 1: Clean Stop (Recommended):**
```vhdl
library STD.ENV.all;  -- Add to library declarations

test_process : process
begin
    -- ... tests ...
    
    report "SIMULATION DONE" severity note;
    std.env.stop(0);  -- Clean termination with exit code 0
end process;
```

**Method 2: Assertion Failure (Alternative):**
```vhdl
test_process : process
begin
    -- ... tests ...
    
    report "SIMULATION DONE" severity note;
    assert false report "Simulation completed" severity failure;
end process;
```

**Method 3: Timeout Process (Safety Mechanism):**
```vhdl
-- Use only if needed for debugging
timeout_process : process
begin
    wait for 10 ms;  -- Maximum simulation time
    report "ERROR: Simulation timeout - forcing termination" severity error;
    std.env.stop(1);  -- Exit with error code
end process;
```

**When to Avoid Complex Timeout Logic:**
- Simple testbenches with deterministic test sequences
- Tests that don't depend on external clock enable signals
- Most educational and verification testbenches

### Clock and Timing Management

**Clock Generation:**
```vhdl
constant CLK_PERIOD : time := 10 ns;

clk_process : process
begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
end process;
```

**Clock Enable Simulation:**
```vhdl
clk_en_process : process
begin
    clk_en <= '0';
    wait for CLK_PERIOD * 3;  -- Low period
    clk_en <= '1';
    wait for CLK_PERIOD;      -- High period
end process;
```

**Waiting for Specific Conditions:**
```vhdl
-- Wait for clock enable
wait until clk_en = '1';
wait for CLK_PERIOD;

-- Wait for multiple clock cycles
wait for CLK_PERIOD * 5;

-- Wait for rising edge
wait until rising_edge(clk);
```

### Reset Testing Pattern

**Proper Reset Sequence:**
```vhdl
-- Apply reset
rst <= '1';
wait for CLK_PERIOD * 2;  -- Ensure reset is held long enough
rst <= '0';
wait for CLK_PERIOD;      -- Wait for reset to propagate

-- Test reset behavior
check_test("Reset state", output = expected_reset_value);
```

### Process Organization Best Practices

**Separate Processes for Different Concerns:**
```vhdl
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

---

## Debugging Techniques

### 1. Signal Monitoring

**Add debug output to track signal values:**
```vhdl
-- Debug output with formatting
report "Debug: wave_out = " & to_hstring(wave_out) severity note;
report "Debug: fault_out = " & std_logic'image(fault_out) severity note;
report "Debug: stat = " & to_hstring(stat) severity note;
report "Debug: voltage = " & real'image(voltage_value) severity note;
```

### 2. Expected vs Actual Comparison

**Always compare expected vs actual values:**
```vhdl
check_test("Test name", actual_value = expected_value);

-- For better debugging, show both values on failure
if not (actual_value = expected_value) then
    report "Expected: " & to_hstring(expected_value) severity error;
    report "Actual:   " & to_hstring(actual_value) severity error;
end if;
```

### 3. Step-by-Step Testing

**Break complex tests into smaller steps:**
```vhdl
-- Test 1: Reset behavior
-- Test 2: Basic functionality  
-- Test 3: Edge cases
-- Test 4: Error conditions
-- Test 5: Integration
```

### 4. Real Number Comparison with Tolerance

**Helper function for real comparisons:**
```vhdl
constant TOLERANCE : real := 0.01;  -- 1% or absolute value

function real_equal(a, b : real; tol : real := TOLERANCE) return boolean is
begin
    return abs(a - b) < tol;
end function;

-- Usage in tests
check_test("Voltage test", real_equal(actual_voltage, 1.2, 0.01));
```

---

## Success Patterns

### Patterns That Work Well

#### 1. Proper Signal Initialization
```vhdl
-- Initialize all signals with explicit values
signal current_state : std_logic_vector(3 downto 0) := ST_RESET;
signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
signal cfg_param_valid : std_logic;  -- No initialization needed for combinational signals
```

#### 2. Clean Entity/Architecture Structure
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

#### 3. Clear State Encoding
```vhdl
-- Use clear, documented state encodings
constant ST_RESET      : std_logic_vector(3 downto 0) := "0000";  -- 0x0
constant ST_READY      : std_logic_vector(3 downto 0) := "0001";  -- 0x1
constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
```

#### 4. Avoid Complex Aggregates
```vhdl
-- ❌ Complex aggregates (can cause compilation errors):
status_reg <= (31 => fault_bit, 30 downto 28 => (others => '0'), ...);

-- ✅ Use simple process assignments:
status_reg(31) <= fault_bit;
status_reg(30 downto 28) <= (others => '0');
status_reg(27 downto 24) <= current_state;
```

#### 5. Testbench Timing Pattern That Works
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

1. **Explicit Initialization** - All signals properly initialized
2. **Process Separation** - Different concerns in different processes
3. **Clock-Aware Testing** - Testbenches account for clock delays
4. **Simple Constructs** - Avoid complex VHDL features that cause compilation issues
5. **Clear Documentation** - Well-commented code with clear intent
6. **Incremental Testing** - Test one feature at a time

---

## Testbench Checklist

Before submitting a testbench, ensure:

- [ ] All signals are properly initialized
- [ ] Test process ends with `std.env.stop(0)` or `assert false` (not `wait;`)
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

---

## Quick Reference Commands

```bash
# Clean compilation
ghdl -a --std=08 dependency.vhd
ghdl -a --std=08 entity.vhd
ghdl -a --std=08 entity_tb.vhd

# Elaborate and run
ghdl -e --std=08 entity_tb
ghdl -r --std=08 entity_tb

# Clean up artifacts
rm -f work-obj*.cf *_tb *.o *.exe
```

---

## Known GHDL Limitations

### Real Number Arithmetic Precision
- Real number arithmetic in constants may have floating-point precision issues
- Example: `voltage_to_digital(1.2)` might be off by ±1 LSB
- **Solution**: Accept tolerance in testbenches, or use integer math where possible

### Version-Specific Notes
- **GHDL 1.0+** (VHDL-2008):
  - Strict enforcement of protected types for shared variables
  - Better support for `std.env.stop()`
  - Improved real number handling in synthesis contexts

---

## Related Documentation

- See `coding_standards` memory for general VHDL style guidelines
- See `ai_workflow_and_system_info` for build system integration
- See `design_patterns` memory for architectural patterns

**Original Source Files:**
- `ai-workflow/README-ghdl-testbench-tips.md` (comprehensive testbench patterns)
- `ai-workflow/README-direct-instantiation.md` (direct instantiation guide)

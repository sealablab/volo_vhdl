# GHDL Patterns and Solutions - Comprehensive Reference

This memory consolidates all GHDL compilation patterns, testbench best practices, and design patterns discovered during the Volo VHDL project development.

**Sources Integrated:**
- Real-world errors from EMFI-Seq voltage package development (2025-01-21)
- Moku_Pct_pkg CocotB migration patterns (2025-10-22)
- Legacy GHDL testbench patterns (archived 2025-01-22, 2025-10-22)

**Last Updated:** 2025-10-22

**Note**: GHDL testbenches are deprecated. Use CocotB framework in `tests/` directory for all new tests. See `cocotb_testing_guide.md` memory for current testing standards.

---

## Table of Contents
1. [Compilation Settings](#compilation-settings)
2. [Common Compilation Errors](#common-compilation-errors)
3. [Direct Instantiation Patterns](#direct-instantiation-patterns)
4. [Legacy Testbench Patterns](#legacy-testbench-patterns) (Deprecated - Use CocotB)
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
ghdl -a --std=08 datadef/Moku_Voltage_pkg.vhd

# 2. Core entities
ghdl -a --std=08 core/EMFI_Seq_stair.vhd

# 3. Top-level modules
ghdl -a --std=08 top/EMFI_Seq.vhd

# 4. Testbenches (use CocotB instead for new tests)
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

### Error 2: String Length Mismatch / Bit Width Issues

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

### Error 3: Array Bounds and Index Overflow

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

### Error 4: Compilation Order Dependencies

**GHDL Message:**
```
error: architecture "test" of "entity" is obsoleted by entity "other_entity"
```

**Problem:** Recompiling entities that other files depend on without recompiling dependents.

**Solution:** Always recompile in dependency order (see [Compilation Order](#compilation-order) above).

---

### Error 5: Metavalue Warnings

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

## Legacy Testbench Patterns (Deprecated - Use CocotB)

⚠️ **IMPORTANT**: GHDL testbenches are deprecated. Use CocotB framework in `tests/` directory for all new tests.

See `cocotb_testing_guide.md` memory for current testing standards.

**Legacy GHDL testbenches archived to:**
- `archive/ghdl_testbenches/2025-01-22/` (original archival)
- `archive/ghdl_testbenches/2025-01-22/ARCHIVE_UPDATE_2025-10-22.md` (additional cleanup)

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
-- For better debugging, show both values on failure
if not (actual_value = expected_value) then
    report "Expected: " & to_hstring(expected_value) severity error;
    report "Actual:   " & to_hstring(actual_value) severity error;
end if;
```

### 3. Real Number Comparison with Tolerance

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

### Key Success Factors

1. **Explicit Initialization** - All signals properly initialized
2. **Process Separation** - Different concerns in different processes
3. **Clock-Aware Testing** - Testbenches account for clock delays
4. **Simple Constructs** - Avoid complex VHDL features that cause compilation issues
5. **Clear Documentation** - Well-commented code with clear intent
6. **Incremental Testing** - Test one feature at a time

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

## Migration to CocotB

For CocotB testing patterns, see:
- **`cocotb_testing_guide.md`** - CocotB testing framework (current standard)
- **`tests/README.md`** - CocotB testing guide in project
- **`tests/conftest.py`** - Shared CocotB test utilities
- **Examples**: `tests/test_clk_divider_core.py`, `tests/test_moku_pct_pkg.py`

---

## Related Documentation

- See `coding_standards` memory for general VHDL style guidelines
- See `cocotb_testing_guide` memory for current testing framework
- See `design_patterns` memory for architectural patterns

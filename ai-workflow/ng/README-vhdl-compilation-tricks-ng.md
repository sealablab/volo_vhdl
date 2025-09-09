# VHDL Compilation Tricks for GHDL

## Overview
This document provides core VHDL generation tricks and patterns that make GHDL compilation easier and more reliable. These are fundamental techniques for writing VHDL that compiles cleanly with GHDL.

## Package Design Patterns

### 1. Function Overloading with Type Safety

**Problem**: Function overloading can cause ambiguous calls
```vhdl
-- This can be ambiguous:
function convert(value : signed(15 downto 0)) return real;
function convert(value : std_logic_vector(15 downto 0)) return real;
```

**Solution**: Use descriptive function names instead of overloading
```vhdl
-- Better approach:
function signed_to_voltage(digital : signed(15 downto 0)) return real;
function vector_to_voltage(digital : std_logic_vector(15 downto 0)) return real;
```

**Alternative**: Use different parameter types for overloading
```vhdl
-- Safe overloading with different parameter types:
function voltage_to_digital(voltage : real) return signed;
function voltage_to_digital_vector(voltage : real) return std_logic_vector;
```

### 2. Package Function Declaration Patterns

**Problem**: Complex return types cause compilation issues
```vhdl
-- This fails:
function get_config return t_probe_config(probe_trigger_voltage : real; probe_intensity_min : real);
```

**Solution**: Use simple return types and separate access functions
```vhdl
-- Better approach:
function get_trigger_voltage(probe_id : natural) return real;
function get_intensity_min(probe_id : natural) return real;
function get_intensity_max(probe_id : natural) return real;

-- Or use records with simple field access:
function get_probe_config(probe_id : natural) return t_probe_config;
-- Where t_probe_config is a simple record type
```

### 3. Constant Definition Patterns

**Problem**: Complex constant expressions cause compilation issues
```vhdl
-- This can fail:
constant COMPLEX_CONSTANT : std_logic_vector(15 downto 0) := 
    std_logic_vector(to_signed(integer(real_value * 65536.0 / 10.0), 16));
```

**Solution**: Break complex constants into simpler parts
```vhdl
-- Better approach:
constant SCALE_FACTOR : real := 65536.0 / 10.0;
constant SCALED_VALUE : integer := integer(real_value * SCALE_FACTOR);
constant COMPLEX_CONSTANT : std_logic_vector(15 downto 0) := 
    std_logic_vector(to_signed(SCALED_VALUE, 16));
```

### 4. Type Definition Patterns

**Problem**: Constrained array types in function returns cause issues
```vhdl
-- This fails:
function get_data return std_logic_vector(0 to 255);
```

**Solution**: Use unconstrained array types
```vhdl
-- Better approach:
type data_array is array (natural range <>) of std_logic_vector(15 downto 0);

function get_data return data_array;
-- Implementation constrains the array as needed
```

## Entity and Architecture Patterns

### 5. Port Declaration Patterns

**Problem**: Complex port types cause compilation issues
```vhdl
-- This can fail:
port (
    config : t_complex_config;  -- Complex record type
    data : t_data_array(0 to 15)  -- Constrained array
);
```

**Solution**: Use flat port structures
```vhdl
-- Better approach:
port (
    -- Configuration signals (flattened)
    cfg_trigger_voltage : in std_logic_vector(15 downto 0);
    cfg_intensity_min   : in std_logic_vector(15 downto 0);
    cfg_intensity_max   : in std_logic_vector(15 downto 0);
    
    -- Data signals (flattened)
    data_in_0  : in std_logic_vector(15 downto 0);
    data_in_1  : in std_logic_vector(15 downto 0);
    -- ... etc
);
```

### 6. Generic Declaration Patterns

**Problem**: Complex generic expressions cause compilation issues
```vhdl
-- This can fail:
generic (
    DATA_WIDTH : natural := integer(real(CLK_FREQ) * 0.001);
);
```

**Solution**: Use simple generic values
```vhdl
-- Better approach:
generic (
    CLK_FREQ_MHZ : natural := 100;  -- Clock frequency in MHz
    DATA_WIDTH   : natural := 16;   -- Data width in bits
);
-- Calculate derived values inside the architecture
```

### 7. Signal Declaration Patterns

**Problem**: Complex signal initializations cause compilation issues
```vhdl
-- This can fail:
signal complex_signal : std_logic_vector(15 downto 0) := 
    std_logic_vector(to_signed(integer(real_value * scale), 16));
```

**Solution**: Use simple initializations
```vhdl
-- Better approach:
signal complex_signal : std_logic_vector(15 downto 0) := (others => '0');
-- Initialize with calculated values in a process
```

## Process and Logic Patterns

### 8. Process Declaration Patterns

**Problem**: Complex process sensitivity lists cause compilation issues
```vhdl
-- This can be problematic:
process(clk, rst, complex_signal, another_complex_signal)
```

**Solution**: Use simple sensitivity lists
```vhdl
-- Better approach:
process(clk, rst_n)  -- Only clock and reset
begin
    if rst_n = '0' then
        -- Reset logic
    elsif rising_edge(clk) then
        -- Synchronous logic
    end if;
end process;
```

### 9. Case Statement Patterns

**Problem**: Case statements with complex expressions cause compilation issues
```vhdl
-- This can fail:
case complex_expression is
    when some_complex_value => 
        -- logic
end case;
```

**Solution**: Use if-elsif for complex expressions
```vhdl
-- Better approach:
if complex_expression = some_complex_value then
    -- logic
elsif complex_expression = another_complex_value then
    -- logic
else
    -- default logic
end if;
```

### 10. Loop Patterns

**Problem**: Complex loop bounds cause compilation issues
```vhdl
-- This can fail:
for i in 0 to complex_calculation loop
```

**Solution**: Use simple loop bounds
```vhdl
-- Better approach:
constant MAX_ITERATIONS : natural := 100;
for i in 0 to MAX_ITERATIONS-1 loop
    if i < actual_limit then
        -- loop logic
    end if;
end loop;
```

## Package Body Patterns

### 11. Function Implementation Patterns

**Problem**: Complex function implementations cause compilation issues
```vhdl
-- This can fail:
function complex_function(param : complex_type) return complex_type is
    variable result : complex_type;
begin
    result.field1 := complex_calculation(param.field1);
    result.field2 := another_complex_calculation(param.field2);
    return result;
end function;
```

**Solution**: Break complex functions into simpler parts
```vhdl
-- Better approach:
function simple_calculation_1(value : real) return real is
begin
    return value * 2.0;
end function;

function simple_calculation_2(value : real) return real is
begin
    return value + 1.0;
end function;

function complex_function(param : complex_type) return complex_type is
    variable result : complex_type;
begin
    result.field1 := simple_calculation_1(param.field1);
    result.field2 := simple_calculation_2(param.field2);
    return result;
end function;
```

### 12. Variable Declaration Patterns

**Problem**: Complex variable initializations cause compilation issues
```vhdl
-- This can fail:
variable complex_var : complex_type := 
    (field1 => complex_calculation, field2 => another_calculation);
```

**Solution**: Initialize variables in steps
```vhdl
-- Better approach:
variable complex_var : complex_type;
begin
    complex_var.field1 := simple_calculation_1;
    complex_var.field2 := simple_calculation_2;
    -- Use complex_var
end;
```

## Testbench Patterns

### 13. Testbench Structure Patterns

**Problem**: Complex testbench structures cause compilation issues
```vhdl
-- This can be problematic:
architecture complex of testbench is
    -- Many complex signals and variables
    -- Complex processes
    -- Complex procedures
begin
    -- Complex concurrent statements
end architecture;
```

**Solution**: Use simple, modular testbench structure
```vhdl
-- Better approach:
architecture simple of testbench is
    -- Simple signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal test_complete : boolean := false;
    
    -- Simple procedures (if needed)
    procedure simple_test(test_name : string; passed : boolean) is
        variable l : line;
    begin
        -- Simple test reporting
    end procedure;
begin
    -- Simple clock generation
    clk <= not clk after 5 ns when not test_complete;
    
    -- Simple test process
    test_process : process
        variable test_passed : boolean;
    begin
        -- Simple tests
        test_passed := (actual = expected);
        simple_test("Test name", test_passed);
        
        test_complete <= true;
        wait;
    end process;
end architecture;
```

### 14. Test Data Generation Patterns

**Problem**: Complex test data generation causes compilation issues
```vhdl
-- This can fail:
variable test_data : complex_array := generate_complex_test_data(complex_params);
```

**Solution**: Generate test data in simple steps
```vhdl
-- Better approach:
variable test_data : simple_array;
begin
    -- Generate simple test data
    for i in 0 to 10 loop
        test_data(i) := simple_calculation(i);
    end loop;
    
    -- Use test_data
end;
```

## Compilation Order Patterns

### 15. Dependency Management Patterns

**Problem**: Complex dependency chains cause compilation issues
```vhdl
-- Package A depends on Package B
-- Package B depends on Package C
-- Package C depends on Package A (circular dependency)
```

**Solution**: Design packages with clear dependency hierarchy
```vhdl
-- Better approach:
-- Level 1: Basic types and constants (no dependencies)
package basic_types_pkg is
    -- Basic types only
end package;

-- Level 2: Simple functions (depends only on Level 1)
package simple_functions_pkg is
    use work.basic_types_pkg.all;
    -- Simple functions only
end package;

-- Level 3: Complex functions (depends on Level 1 and 2)
package complex_functions_pkg is
    use work.basic_types_pkg.all;
    use work.simple_functions_pkg.all;
    -- Complex functions
end package;
```

### 16. Package Import Patterns

**Problem**: Circular imports cause compilation issues
```vhdl
-- Package A imports Package B
-- Package B imports Package A
```

**Solution**: Use unidirectional imports
```vhdl
-- Better approach:
-- Package A (base package)
package base_pkg is
    -- Basic definitions
end package;

-- Package B (extends Package A)
package extended_pkg is
    use work.base_pkg.all;
    -- Extended definitions
end package;

-- Package C (uses both)
package user_pkg is
    use work.base_pkg.all;
    use work.extended_pkg.all;
    -- User definitions
end package;
```

## Error Prevention Patterns

### 17. Type Safety Patterns

**Problem**: Type mismatches cause compilation issues
```vhdl
-- This can fail:
signal data : std_logic_vector(15 downto 0);
data <= some_signed_value;  -- Type mismatch
```

**Solution**: Use explicit type conversions
```vhdl
-- Better approach:
signal data : std_logic_vector(15 downto 0);
data <= std_logic_vector(some_signed_value);
```

### 18. Range Safety Patterns

**Problem**: Range violations cause compilation issues
```vhdl
-- This can fail:
signal data : std_logic_vector(7 downto 0);
data(15 downto 8) <= some_value;  -- Range violation
```

**Solution**: Use appropriate signal sizes
```vhdl
-- Better approach:
signal data : std_logic_vector(15 downto 0);
data(15 downto 8) <= some_value;  -- Correct range
```

### 19. Initialization Safety Patterns

**Problem**: Uninitialized signals cause runtime issues
```vhdl
-- This can cause issues:
signal data : std_logic_vector(15 downto 0);  -- Uninitialized
```

**Solution**: Always initialize signals
```vhdl
-- Better approach:
signal data : std_logic_vector(15 downto 0) := (others => '0');
```

## Summary

These patterns help ensure that VHDL code compiles cleanly with GHDL:

1. **Use simple types** - Avoid complex nested types in function returns
2. **Break complex expressions** - Split complex calculations into simple steps
3. **Use flat structures** - Prefer flat port structures over complex records
4. **Initialize everything** - Always initialize signals and variables
5. **Use explicit conversions** - Don't rely on implicit type conversions
6. **Design clear dependencies** - Avoid circular package dependencies
7. **Use simple loops and conditions** - Avoid complex expressions in control structures
8. **Test incrementally** - Compile and test each component separately
9. **Use descriptive names** - Avoid function overloading when possible
10. **Follow compilation order** - Compile dependencies before dependents

By following these patterns, VHDL code will be more likely to compile successfully with GHDL and be easier to debug and maintain.
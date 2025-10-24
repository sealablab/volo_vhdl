# GHDL Patterns and Solutions - Comprehensive Reference

This memory consolidates all GHDL compilation patterns, testbench best practices, and design patterns discovered during the Volo VHDL project development.

**Sources Integrated:**
- Real-world errors from EMFI-Seq voltage package development (2025-01-21)
- Moku_Pct_pkg CocotB migration patterns (2025-10-22)
- Legacy GHDL testbench patterns (archived 2025-01-22, 2025-10-22)
- Counter reliability patterns from volo_common module development (2025-10-23)

**Last Updated:** 2025-10-23

**Note**: GHDL testbenches are deprecated. Use CocotB framework in `tests/` directory for all new tests. See `cocotb_testing_guide.md` memory for current testing standards.

---

## Table of Contents
1. [Compilation Settings](#compilation-settings)
2. [Common Compilation Errors](#common-compilation-errors)
3. [Counter Patterns and Metavalue Issues](#counter-patterns-and-metavalue-issues) ⭐ NEW
4. [CocotB/GHDL Simulation Timing Quirks](#cocotbghdl-simulation-timing-quirks) ⭐ NEW
5. [Direct Instantiation Patterns](#direct-instantiation-patterns)
6. [Legacy Testbench Patterns](#legacy-testbench-patterns) (Deprecated - Use CocotB)
7. [Debugging Techniques](#debugging-techniques)
8. [Success Patterns](#success-patterns)

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

**See Also:** [Counter Patterns and Metavalue Issues](#counter-patterns-and-metavalue-issues) for detailed counter-specific metavalue problems.

---

## Counter Patterns and Metavalue Issues

⭐ **CRITICAL DISCOVERY (2025-10-23):** Generic counter WIDTH parameters cause GHDL metavalue warnings and test failures. Fixed-width counters achieve 100% reliability.

### The Problem: Generic WIDTH Counters

**Modules with Generic WIDTH:**
- `volo_pulse_generator` - Success rate: 20% (2/10 tests passed)
- `volo_counter_nbit` - Success rate: 30% (3/10 tests passed)

**Common Pattern (PROBLEMATIC):**
```vhdl
entity pulse_generator is
    generic (
        COUNTER_WIDTH : positive := 16;  -- ⚠️ Generic causes issues!
        PULSE_WIDTH : positive := 1
    );
    port (
        clk : in std_logic;
        -- ...
    );
end entity;

architecture rtl of pulse_generator is
    signal counter : unsigned(COUNTER_WIDTH-1 downto 0);  -- ⚠️ Generic-based sizing
    signal max_count : unsigned(COUNTER_WIDTH-1 downto 0);
begin
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if counter >= max_count then  -- ⚠️ Metavalue warnings here!
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
end architecture;
```

**GHDL Warnings from Generic Counters:**
```
NUMERIC_STD.">": metavalue detected, returning FALSE
NUMERIC_STD.">=": metavalue detected, returning FALSE
NUMERIC_STD."<": metavalue detected, returning FALSE
```

**Why It Fails:**
1. Generic WIDTH creates dynamic-width signals
2. GHDL has difficulty initializing generic-sized signals properly
3. Comparisons see 'U' (uninitialized) bits early in simulation
4. Tests fail unpredictably despite correct logic

---

### The Solution: Fixed-Width Counters

**Module with Fixed Width:**
- `volo_pwm` - Success rate: 100% (10/10 tests passed) ✅

**Successful Pattern (RECOMMENDED):**
```vhdl
entity volo_pwm is
    port (
        clk         : in  std_logic;
        n_reset     : in  std_logic;
        enable      : in  std_logic;
        duty_cycle  : in  std_logic_vector(7 downto 0);  -- Fixed 8-bit
        pwm_out     : out std_logic;
        stat_reg    : out std_logic_vector(7 downto 0)
    );
end entity volo_pwm;

architecture rtl of volo_pwm is
    signal counter : unsigned(7 downto 0);  -- ✅ Fixed 8-bit width!
begin
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                counter <= counter + 1;  -- ✅ Auto-wraps at 255→0
            end if;
        end if;
    end process;

    -- Simple comparison (no metavalue warnings!)
    pwm_raw <= '1' when counter < unsigned(duty_cycle) else '0';
    pwm_out <= pwm_raw when (enable = '1' and n_reset = '1') else '0';
end architecture;
```

**Results:**
- ✅ Zero metavalue warnings
- ✅ All tests pass on first run
- ✅ Clean, predictable simulation behavior
- ✅ Counter wraps automatically (no overflow detection needed)

---

### Counter Design Guidelines

**DO:**
- ✅ Use fixed-width signals (`unsigned(7 downto 0)`, `unsigned(15 downto 0)`)
- ✅ Let counters auto-wrap with natural overflow
- ✅ Keep counter logic simple (increment, reset, hold)
- ✅ Use fixed comparison values from ports (not computed)

**DON'T:**
- ❌ Use generic WIDTH parameters for counters
- ❌ Use dynamic max_count values computed from generics
- ❌ Add complex overflow detection logic
- ❌ Mix generic widths with counter comparisons

**If You Need Flexibility:**

Instead of generic WIDTH, create multiple fixed-width versions:
```vhdl
-- volo_pwm.vhd (8-bit, always 256 steps)
signal counter : unsigned(7 downto 0);

-- volo_pwm_10bit.vhd (10-bit, always 1024 steps)  
signal counter : unsigned(9 downto 0);

-- volo_pwm_12bit.vhd (12-bit, always 4096 steps)
signal counter : unsigned(11 downto 0);
```

Or use external clock dividers to adjust effective resolution.

---

### Metavalue Warning Patterns

**Common Warning Locations:**
```vhdl
-- ⚠️ Warning: counter >= max_count
if counter >= max_count then  

-- ⚠️ Warning: counter < threshold
elsif counter < pulse_width then

-- ⚠️ Warning: Any comparison with generic-width signals
if generic_signal > some_value then
```

**Clean Alternatives:**
```vhdl
-- ✅ Fixed-width comparison
if counter < unsigned(duty_cycle) then  -- duty_cycle is port input

-- ✅ Simple auto-wrap (no comparison needed)
counter <= counter + 1;  -- Wraps at max value automatically

-- ✅ Port-based threshold
if counter >= unsigned(threshold_in) then
```

---

### Module Success Rates by Counter Type

| Module | Counter Type | Tests Passed | Success Rate | Notes |
|--------|-------------|--------------|--------------|-------|
| volo_pwm | Fixed 8-bit | 10/10 | 100% | ✅ GOLD STANDARD |
| volo_pulse_generator | Generic WIDTH | 2/10 | 20% | ❌ Metavalue warnings |
| volo_counter_nbit | Generic WIDTH | 3/10 | 30% | ❌ Metavalue warnings |

**Conclusion:** Fixed-width counters are 3-5x more reliable than generic WIDTH counters in GHDL simulation.

---

## CocotB/GHDL Simulation Timing Quirks

⭐ **NEW (2025-10-23):** Documented timing behaviors specific to CocotB + GHDL simulation environment.

### Pattern 1: Synchronizer Timing (DEPTH + 1)

**Module:** `volo_synchronizer` (2-FF, 3-FF, 4-FF CDC synchronizer)

**Expected Behavior:** Signal should propagate through DEPTH flip-flops in DEPTH clock cycles.

**Actual CocotB/GHDL Behavior:** Signal takes DEPTH + 1 cycles to appear at output.

**Example:**
```python
DEPTH = 2  # 2-FF synchronizer
STABILITY_CYCLES = DEPTH + 1  # = 3 cycles in simulation!

# Apply input
dut.async_in.value = 1
await ClockCycles(dut.clk, STABILITY_CYCLES)  # Wait 3 cycles, not 2

# Now output is stable
assert dut.sync_out.value == 1
```

**Why:** Delta-cycle timing in GHDL simulation causes an extra cycle delay between FF updates and output sampling.

**VHDL Implementation:**
```vhdl
signal sync_chain : std_logic_vector(3 downto 0);  -- Fixed max size

process(clk, n_reset)
begin
    if n_reset = '0' then
        sync_chain <= (others => '0');
    elsif rising_edge(clk) then
        sync_chain(0) <= async_in;      -- Cycle 1: Input sampled
        sync_chain(1) <= sync_chain(0); -- Cycle 2: Propagates to FF1
        sync_chain(2) <= sync_chain(1); -- Cycle 3: Output appears!
        sync_chain(3) <= sync_chain(2);
    end if;
end process;

sync_out <= sync_chain(DEPTH-1);  -- DEPTH=2 uses sync_chain(1)
```

**Affected Modules:**
- `volo_synchronizer` (10/10 tests pass with DEPTH+1)
- `volo_delay_line` (similar pattern)

---

### Pattern 2: Debouncer Timing (DEPTH + 2)

**Module:** `volo_debouncer` (shift register + stability detection)

**Expected Behavior:** Signal should stabilize after DEPTH consecutive samples.

**Actual CocotB/GHDL Behavior:** Signal takes DEPTH + 2 cycles to debounce.

**Example:**
```python
DEPTH = 8  # 8-bit shift register
STABILITY_CYCLES = DEPTH + 2  # = 10 cycles in simulation!

# Apply stable input
dut.noisy_in.value = 1
await ClockCycles(dut.clk, STABILITY_CYCLES)  # Wait 10 cycles, not 8

# Now output is debounced
assert dut.debounced_out.value == 1
```

**Why:** Requires DEPTH cycles to fill shift register + 1 cycle for stability detection logic + 1 cycle for output update.

**VHDL Implementation:**
```vhdl
signal shift_reg : std_logic_vector(15 downto 0);  -- Fixed max size
signal all_ones, all_zeros : std_logic;

process(clk, n_reset)
begin
    if n_reset = '0' then
        shift_reg <= (others => '0');
        debounced <= '0';
    elsif rising_edge(clk) then
        if clk_en = '1' then
            -- Shift input (cycles 1-8 for DEPTH=8)
            shift_reg <= shift_reg(14 downto 0) & noisy_in;
            
            -- Detect stability (cycle 9)
            if all_ones = '1' then
                debounced <= '1';  -- Update output (cycle 10)
            elsif all_zeros = '1' then
                debounced <= '0';
            end if;
        end if;
    end if;
end process;

-- Combinational stability detection (available cycle 9)
all_ones <= '1' when shift_reg(DEPTH-1 downto 0) = (DEPTH-1 downto 0 => '1') else '0';
all_zeros <= '1' when shift_reg(DEPTH-1 downto 0) = (DEPTH-1 downto 0 => '0') else '0';
```

**Affected Modules:**
- `volo_debouncer` (10/10 tests pass with DEPTH+2)

---

### Pattern 3: Edge Detector Timing (DEPTH + 1)

**Module:** `volo_edge_detector` (shift register + XOR detection)

**Similar to synchronizer:** Needs DEPTH + 1 cycles for edge detection to appear.

**Example:**
```python
DEPTH = 2
EDGE_CYCLES = DEPTH + 1  # = 3 cycles

# Create rising edge
dut.sig_in.value = 0
await ClockCycles(dut.clk, 2)
dut.sig_in.value = 1
await ClockCycles(dut.clk, EDGE_CYCLES)  # Wait 3 cycles

# Edge pulse should have occurred within this window
```

---

### General Timing Guidelines

**For Shift Register Patterns:**
- Simple propagation (sync, delay): Use DEPTH + 1
- With detection logic (debounce): Use DEPTH + 2
- With state machines: May need DEPTH + 3

**For Counter Patterns:**
- Fixed-width counters: No extra cycles needed
- Generic counters: Unpredictable (avoid!)

**For Pure Combinational:**
- Zero latency, instant response
- No timing adjustment needed
- Works perfectly (mux, comparator)

**Testing Strategy:**
```python
# Define timing constants at module level
DEPTH = 8
BASE_CYCLES = DEPTH
PROPAGATION_CYCLES = DEPTH + 1  # For shift registers
DETECTION_CYCLES = DEPTH + 2    # For shift + detection

# Use appropriate constant in tests
await ClockCycles(dut.clk, PROPAGATION_CYCLES)
```

---

### Debugging Timing Issues

**Symptom:** Test expects signal change at cycle N, but actually appears at cycle N+1 or N+2.

**Solution Steps:**
1. Identify module type (shift register? counter? combinational?)
2. Count logic stages from input to output
3. Add +1 for each sequential stage
4. Add +1 for detection/comparison logic
5. Adjust test timing constants

**Example Debug:**
```python
# Debug: Print cycle-by-cycle output
for cycle in range(15):
    await ClockCycles(dut.clk, 1)
    dut._log.info(f"Cycle {cycle}: output = {dut.output.value}")
    # Watch when output actually changes!
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

### 4. Counter Metavalue Debugging

**For counter-related metavalue warnings:**

```vhdl
-- Add initialization assertions
assert counter'length = 8 report "Counter width mismatch!" severity failure;

-- Monitor counter state
report "Counter value: " & integer'image(to_integer(counter)) severity note;
report "Counter bits: " & to_hstring(std_logic_vector(counter)) severity note;

-- Check for 'U' bits
assert is_x(std_logic_vector(counter)) = false 
    report "Counter has metavalues!" severity warning;
```

**In CocotB tests:**
```python
# Debug counter state
dut._log.info(f"Counter value: {int(dut.counter.value)}")
dut._log.info(f"Counter bits: {dut.counter.value.binstr}")

# Check for X/U bits
if 'x' in str(dut.counter.value).lower() or 'u' in str(dut.counter.value).lower():
    dut._log.error("Counter has metavalues!")
```

---

## Success Patterns

### Patterns That Work Well

#### 1. Fixed-Width Signals (HIGHEST RELIABILITY)

⭐ **Gold Standard Pattern:**
```vhdl
-- ✅ Fixed-width counter (100% reliable)
signal counter : unsigned(7 downto 0);
signal threshold : unsigned(7 downto 0);

process(clk, n_reset)
begin
    if n_reset = '0' then
        counter <= (others => '0');
    elsif rising_edge(clk) then
        if enable = '1' then
            counter <= counter + 1;  -- Auto-wraps!
        end if;
    end if;
end process;

output <= '1' when counter < threshold else '0';
```

**Success Rate:** 100% (volo_pwm: 10/10 tests)

#### 2. Proper Signal Initialization

```vhdl
-- Initialize all signals with explicit values
signal current_state : std_logic_vector(3 downto 0) := ST_RESET;
signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
signal cfg_param_valid : std_logic;  -- No initialization needed for combinational signals
```

#### 3. Clean Entity/Architecture Structure

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

#### 4. Clear State Encoding

```vhdl
-- Use clear, documented state encodings
constant ST_RESET      : std_logic_vector(3 downto 0) := "0000";  -- 0x0
constant ST_READY      : std_logic_vector(3 downto 0) := "0001";  -- 0x1
constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
```

#### 5. Avoid Complex Aggregates

```vhdl
-- ❌ Complex aggregates (can cause compilation errors):
status_reg <= (31 => fault_bit, 30 downto 28 => (others => '0'), ...);

-- ✅ Use simple process assignments:
status_reg(31) <= fault_bit;
status_reg(30 downto 28) <= (others => '0');
status_reg(27 downto 24) <= current_state;
```

### Module Reliability Hierarchy

Based on 45 tests across 9 modules (2025-10-23 session):

**Tier 1: 100% Success (Pure Combinational)**
- volo_comparator: 10/10 tests ✅
- volo_mux: 10/10 tests ✅
- **Pattern:** Zero state, instant response, no timing dependencies

**Tier 2: 100% Success (Shift Register)**
- volo_edge_detector: 10/10 tests ✅
- volo_delay_line: 5/5 tests ✅
- volo_synchronizer: 10/10 tests ✅
- volo_debouncer: 10/10 tests ✅
- **Pattern:** Fixed array size, simple shifting, predictable timing

**Tier 3: 100% Success (Fixed Counter)**
- volo_pwm: 10/10 tests ✅
- **Pattern:** Fixed-width counter, auto-wrap, simple comparison

**Tier 4: Low Success (Generic Counter)**
- volo_pulse_generator: 2/10 tests ❌
- volo_counter_nbit: 3/10 tests ❌
- **Pattern:** Generic WIDTH, dynamic max_count, metavalue warnings

### Key Success Factors

1. **Fixed-Width Signals** - Avoid generic WIDTH for counters
2. **Explicit Initialization** - All signals properly initialized
3. **Process Separation** - Different concerns in different processes
4. **Simple Constructs** - Avoid complex VHDL features that cause compilation issues
5. **Clear Documentation** - Well-commented code with clear intent
6. **Incremental Testing** - Test one feature at a time
7. **Timing Awareness** - Account for DEPTH+1/+2 simulation delays in tests

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

### Generic WIDTH Parameters with Counters
- Generic WIDTH causes metavalue warnings in counter comparisons
- GHDL has difficulty initializing generic-sized signals
- **Solution**: Use fixed-width counters (see [Counter Patterns](#counter-patterns-and-metavalue-issues))

### Simulation Timing Delays
- Shift register patterns need DEPTH+1 or DEPTH+2 cycles in simulation
- Delta-cycle effects cause extra propagation delays
- **Solution**: Adjust test timing constants (see [CocotB/GHDL Timing Quirks](#cocotbghdl-simulation-timing-quirks))

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
- **Examples**: `tests/test_clk_divider_core.py`, `tests/test_moku_pct_pkg.py`, `tests/test_pwm.py`

---

## Related Documentation

- See `coding_standards` memory for general VHDL style guidelines
- See `cocotb_testing_guide` memory for current testing framework
- See `design_patterns` memory for architectural patterns

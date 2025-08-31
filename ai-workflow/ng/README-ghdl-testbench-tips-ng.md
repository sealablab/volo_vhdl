# GHDL Testbench Development Tips and Best Practices (Structured)

> Dual‑purpose format: concise, machine‑friendly rules in the open text; deeper human notes and long examples inside HTML comments.

## Usage for Agents
- Ignore HTML comments (`<!-- … -->`).
- Consume only headings, **Problem/Cause/Solution**, **Pattern** snippets, and **Tags**.
- Prefer **Pattern** snippets as canonical forms when generating code.

## Quick Index (maintained by humans)
| Error/Clue (optional) | Category | Tip ID | Title |
|------------------------|----------|--------|-------|
| `variable parameter must be a variable` | VS | VS-01 | Procedure parameters must be variables |
| `variable parameter must be a variable` | VS | VS-03 | Procedure parameter issues and alternatives |
| `string length does not match` | DT | DT-01 | String/width alignment |
| `string length does not match` | DT | DT-04 | String concatenation and bit width issues |
| `writeline` usage unclear | LOG | LOG-02 | TextIO write/writeline patterns |
| unclear test organization | LOG | LOG-04 | Test structure and organization |
| `--std=08` required | GHDL | GHDL-01 | Use VHDL‑2008 consistently |
| `architecture is obsoleted` | GHDL | GHDL-04 | Compilation order dependencies |
| flaky tests | TB | TB-05 | Clock and timing management |
| incomplete reset testing | TB | TB-06 | Reset and initialization testing |
| incomplete state testing | TB | TB-07 | State machine and output testing |
| infinite simulation loops | TB | TB-08 | Infinite simulation loops and termination |
| (add more rows as new tips are added) |  |  |  |

---

## 1) Variables & Signals (VS)

### VS-01: Procedure parameters must be **variables**
**Problem**: GHDL error `variable parameter must be a variable` when calling procedures from a process.  
**Cause**: Passing a **signal** to a procedure formal defined as a **variable** (common with counters/indices).  
**Solution**: Use a local **variable** in the process; pass that variable to the procedure.  
**Pattern**:
```vhdl
process
  variable test_num : natural := 0;
begin
  test_num := test_num + 1;
  report_test("sanity", passed => (a = b), test_id => test_num);
  wait;
end process;
```
**Tags**: #variables #signals #ghdl-error #procedures
<!--
Human note: Avoid using signals for intra-process counters. Variables update immediately; signals update after delta delay.
If you must interact with DUT signals, copy to locals, compute, then assign back once per cycle.
-->

### VS-02: When to use **variables** vs **signals**
**Problem**: Confusion on where to use variables vs signals in TBs.  
**Cause**: Misunderstanding delta cycles and process semantics.  
**Solution**: Use **variables** for local computation/counters; use **signals** for DUT I/O and cross-process communication.  
**Pattern**:
```vhdl
clk <= not clk after 16 ns;  -- signal used across processes
process
  variable cnt : natural := 0; -- local, instant updates
begin
  wait until rising_edge(clk);
  cnt := cnt + 1;
end process;
```
**Tags**: #variables #signals #delta-cycles #tb-architecture
<!-- Longer examples: show a failing version that uses signals as counters and passes them into procedures, then the fixed variant. -->

---

## 2) Data Types & Widths (DT)

### DT-01: String/width alignment for reports and slices
**Problem**: Mismatched string or vector widths causing compile errors or confusing output.  
**Cause**: Implicit size assumptions (e.g., assigning 4 bits into a 3‑bit slice or vice‑versa).  
**Solution**: Always match exact widths; use explicit slices and `to_string(...)` helpers.  
**Pattern**:
```vhdl
status_reg(6 downto 3) <= "0000";  -- exact 4 bits
-- OK: status_reg(2) <= '1';       -- exact single bit
-- Use to_string(unsigned(...)) for numeric logging
```
**Tags**: #widths #slices #string-format

### DT-02: Conversions between `std_logic_vector` and numeric types
**Problem**: Arithmetic or comparisons fail on `std_logic_vector`.  
**Cause**: Missing conversion to `unsigned`/`signed`.  
**Solution**: Convert for math; convert back for ports/logging.  
**Pattern**:
```vhdl
signal a,b : std_logic_vector(15 downto 0);
...
assert unsigned(a) + 1 = unsigned(b) report "off by one" severity error;
```
**Tags**: #type-conversion #unsigned #signed

### DT-03: Safe concatenation patterns
**Problem**: Concatenations silently change widths or sign.  
**Cause**: Mixed types or implicit growth.  
**Solution**: Normalize types and widths before concatenation.  
**Pattern**:
```vhdl
signal s : std_logic_vector(7 downto 0);
...
s <= "0" & s(7 downto 1);  -- explicit width maintenance
```
**Tags**: #concatenation #widths

---

## 3) Simulation Output & Logging (LOG)

### LOG-01: Prefer `assert` for pass/fail, `report` for commentary
**Problem**: Noisy or ambiguous test output.  
**Cause**: Using `report` for failures or mixing responsibilities.  
**Solution**: Use `assert` with `severity error` for failures and distinct magic strings for automation.  
**Pattern**:
```vhdl
assert (a = b)
  report "MISMATCH: a!=b"
  severity error;

report "ALL_TESTS_PASSED" severity note; -- machine-friendly sentinel
```
**Tags**: #assert #report #automation #magic-strings
<!-- Human note: consider a small wrapper proc: report_test(name, passed, id) that emits both human text and machine sentinel. -->

### LOG-02: `textio` / `writeline` canonical usage
**Problem**: Confusion printing composite values and newlines.  
**Cause**: Misuse of `write` vs `writeline`.  
**Solution**: Build a line with `write(...)` calls, then commit with `writeline(...)`.  
**Pattern**:
```vhdl
use std.textio.all;
use ieee.std_logic_textio.all;

file L : text open write_mode is "tb.log";
variable ln : line;

write(ln, string'("t=")); write(ln, now);
write(ln, string'(" a=")); write(ln, to_hstring(a));
writeline(L, ln);
```
**Tags**: #textio #writeline #formatting

### LOG-03: Human vs machine output
**Problem**: Output is readable but hard to parse (or vice versa).  
**Cause**: Single-channel logging.  
**Solution**: Emit both: (1) human message; (2) machine sentinel.  
**Pattern**:
```vhdl
report "Reset sequence complete" severity note;
report "TB_SENTINEL:RESET_OK" severity note;
```
**Tags**: #logging #sentinels #automation

---

## 4) GHDL / Toolchain Quirks (GHDL)

### GHDL-01: Use VHDL‑2008 consistently
**Problem**: Constructs fail without `--std=08`.  
**Cause**: Default standard may be older.  
**Solution**: Compile/elaborate with `--std=08`.  
**Pattern**:
```sh
ghdl -a --std=08 src1.vhd
ghdl -e --std=08 my_tb
ghdl -r --std=08 my_tb --wave=wave.ghw
```
**Tags**: #ghdl #vhdl2008

### GHDL-02: Compile order matters
**Problem**: Missing unit errors.  
**Cause**: Packages/entities not analyzed before use.  
**Solution**: Analyze packages → entities → testbenches, then elaborate and run.  
**Pattern**:
```sh
ghdl -a --std=08 my_pkg.vhd
ghdl -a --std=08 dut.vhd
ghdl -a --std=08 tb_dut.vhd
ghdl -e --std=08 tb_dut
ghdl -r --std=08 tb_dut
```
**Tags**: #compile-order #packages #entities #tb

### GHDL-03: Wave dumping and reproducibility
**Problem**: Missing waveforms or non-deterministic outputs.  
**Cause**: Not enabling dumps or relying on uninitialized drivers.  
**Solution**: Always pass `--wave` (or `--vcd`) and initialize drivers.  
**Pattern**:
```sh
ghdl -r --std=08 tb_dut --wave=wave.ghw
```
```vhdl
signal clk : std_logic := '0';  -- initialize
```
**Tags**: #ghw #vcd #initialization

---

## 5) Testbench Patterns (TB)

### TB-01: Clock and reset processes
**Problem**: Flaky tests due to ad-hoc clocks/resets.  
**Cause**: Inconsistent driver structure.  
**Solution**: Canonical clock/reset generators.  
**Pattern**:
```vhdl
signal clk   : std_logic := '0';
signal rst_n : std_logic := '0';

clk <= not clk after 16 ns;

process begin
  rst_n <= '0'; wait for 200 ns;
  rst_n <= '1'; wait;
end process;
```
**Tags**: #clock #reset

### TB-02: Deterministic stimulus
**Problem**: Non-reproducible failures.  
**Cause**: Random stimulus without seed control or timing discipline.  
**Solution**: Seeded RNG or fixed vectors; align to clock edges.  
**Pattern**:
```vhdl
wait until rising_edge(clk);
stim <= next_stimulus;  -- deterministic sequence
```
**Tags**: #determinism #stimulus

### TB-03: Single-writer discipline for signals
**Problem**: 'U'/'X' due to multiple drivers.  
**Cause**: Assigning the same signal from multiple processes.  
**Solution**: One writer per signal; use variables for local calc.  
**Pattern**:
```vhdl
-- OK: only one process assigns 'stim'
process begin
  wait until rising_edge(clk);
  stim <= func(stim);
end process;
```
**Tags**: #drivers #resolution #discipline

### TB-04: Boundary and fault injection checks
**Problem**: Edge cases missed.  
**Cause**: Only testing “happy path.”  
**Solution**: Include parameter extremes, invalid codes, timing edges.  
**Pattern**:
```vhdl
assert probe_sel /= "1111" report "invalid code must fault" severity error;
```
**Tags**: #edge-cases #fault-injection

---
## Appendix: Agent-Contributed Tips
Agents may append new candidate tips **below the following line**.  
Do not modify the main body above.
Use the template below 'PROC-XX'

### Candidate: PROC-XX
**Problem**: …  
**Cause**: …  
**Solution**: …  
**Pattern**:
```vhdl
-- example
```
**Tags**: #candidate #unreviewed

------- New Tips here-------

### VS-03: Procedure parameter issues and alternatives
**Problem**: `error: variable parameter must be a variable` when calling procedures from processes.  
**Cause**: Passing signals to procedure formals defined as variables, or using procedures unnecessarily.  
**Solution**: Use local variables for procedure parameters, or avoid procedures entirely with direct test reporting.  
**Pattern**:
```vhdl
-- Option 1: Use local variables
process
    variable local_test_number : natural := 0;
begin
    report_test("Test name", test_passed, local_test_number);
end process;

-- Option 2: Avoid procedures entirely (recommended)
process
    variable test_number : natural := 0;
begin
    test_number := test_number + 1;
    if test_passed then
        write(l, string'("Test " & integer'image(test_number) & ": Test name - PASSED"));
    else
        write(l, string'("Test " & integer'image(test_number) & ": Test name - FAILED"));
    end if;
    writeline(output, l);
end process;
```
**Tags**: #variables #procedures #ghdl-error #test-reporting
<!-- See README-ghdl-testbench-tips.md for detailed examples and alternatives -->

### DT-04: String concatenation and bit width issues
**Problem**: `error: string length does not match` or bit width mismatches.  
**Cause**: Implicit size assumptions or incorrect bit slice assignments.  
**Solution**: Match exact widths and use explicit bit assignments.  
**Pattern**:
```vhdl
-- Correct bit width matching
status_reg(6 downto 3) <= "0000";  -- 4 bits assigned to 4-bit slice
status_reg(7) <= enabled_reg;       -- single bit assignment
status_reg(2 downto 0) <= wave_select_reg;  -- 3 bits assigned to 3-bit slice

-- Alternative: individual bit assignments
status_reg(7) <= enabled_reg;
status_reg(6 downto 3) <= "0000";
status_reg(2 downto 0) <= wave_select_reg;
```
**Tags**: #widths #slices #bit-assignment #string-format

### LOG-04: Test structure and organization
**Problem**: Unclear test organization and inconsistent reporting.  
**Cause**: Ad-hoc test structure without clear patterns.  
**Solution**: Use structured test process with clear reporting and proper termination.  
**Pattern**:
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
end process;
```
**Tags**: #test-structure #reporting #termination #organization

### GHDL-04: Compilation order dependencies
**Problem**: `error: architecture "test" of "entity" is obsoleted by entity "other_entity"`.  
**Cause**: Recompiling entities that other files depend on without proper order.  
**Solution**: Always recompile in dependency order: packages → entities → testbenches.  
**Pattern**:
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
**Tags**: #compile-order #dependencies #packages #entities #tb

### TB-05: Clock and timing management
**Problem**: Flaky tests due to inconsistent clock generation and timing.  
**Cause**: Ad-hoc clock generation without proper timing discipline.  
**Solution**: Use canonical clock generation and proper timing management.  
**Pattern**:
```vhdl
-- Clock generation
clk_process : process
begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
end process;

-- Clock enable simulation
clk_en_process : process
begin
    clk_en <= '0';
    wait for CLK_PERIOD * 3;  -- Low period
    clk_en <= '1';
    wait for CLK_PERIOD;      -- High period
end process;

-- Proper timing in tests
wait until rising_edge(clk);
stim <= next_stimulus;  -- deterministic sequence
wait for CLK_PERIOD;
```
**Tags**: #clock #timing #clock-enable #determinism

### TB-06: Reset and initialization testing
**Problem**: Incomplete reset testing and initialization issues.  
**Cause**: Insufficient reset timing or missing initialization checks.  
**Solution**: Use proper reset timing and comprehensive initialization testing.  
**Pattern**:
```vhdl
-- Apply reset
rst <= '1';
wait for CLK_PERIOD * 2;  -- Ensure reset is held long enough
rst <= '0';
wait for CLK_PERIOD;      -- Wait for reset to propagate

-- Test reset behavior
test_passed := (output = expected_reset_value) and (status = expected_status);

-- Initialize all signals
signal test_signal : std_logic_vector(15 downto 0) := (others => '0');
signal test_enable : std_logic := '0';
```
**Tags**: #reset #initialization #timing #testing

### TB-07: State machine and output testing
**Problem**: Incomplete state machine testing and output verification.  
**Cause**: Missing state change verification and output comparison.  
**Solution**: Test state changes and compare expected vs actual outputs.  
**Pattern**:
```vhdl
-- Wait for clock enable
wait until clk_en = '1';
prev_output := current_output;
wait for CLK_PERIOD;
wait until clk_en = '1';
wait for CLK_PERIOD;

-- Check for expected change
test_passed := (current_output /= prev_output) and (current_output = expected_value);

-- Expected vs actual comparison
test_passed := (actual_value = expected_value);
if not test_passed then
    write(l, string'("Expected: " & to_hstring(expected_value)));
    write(l, string'("Actual: " & to_hstring(actual_value)));
    writeline(output, l);
end if;
```
**Tags**: #state-machine #output-testing #comparison #verification

### TB-08: Infinite simulation loops and termination
**Problem**: Testbench runs indefinitely without completing.  
**Cause**: Using `wait;` statement or missing proper termination.  
**Solution**: Use `std.env.stop()` for clean termination or `assert false` as alternative.  
**Pattern**:
```vhdl
library STD.ENV.all;  -- Add this to library declarations

test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    stop(0); -- Clean termination with exit code 0
end process;

-- Alternative: Use assert false
test_process : process
begin
    -- ... tests ...
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    assert false report "Simulation completed" severity failure;
end process;
```
**Tags**: #termination #simulation-loops #stop #assert-false
<!-- See README-ghdl-testbench-tips.md for detailed examples and when to use each approach -->

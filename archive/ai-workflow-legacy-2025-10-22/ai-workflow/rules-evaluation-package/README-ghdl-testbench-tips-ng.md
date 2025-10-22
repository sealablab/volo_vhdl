# GHDL Testbench Development Tips and Best Practices (Structured, -ng)

> Dual‑purpose format: concise, machine‑friendly rules in the open text; deeper human notes and long examples inside HTML comments.

## Usage for Agents
- Ignore HTML comments (`<!-- … -->`).
- Consume only headings, **Problem/Cause/Solution**, **Pattern** snippets, and **Tags**.
- Prefer **Pattern** snippets as canonical forms when generating code.
- ⚠️ Do not edit or reorganize the main body of this file.
- If you believe you have discovered a **new tip**, append it to the footer section marked
  `------- New Tips here-------` instead of altering the main text.

## Quick Index (maintained by humans)
| Error/Clue (optional) | Category | Tip ID | Title |
|------------------------|----------|--------|-------|
| variable parameter must be a variable | VS | VS-01 | Procedure parameters must be variables |
| string length does not match         | DT | DT-01 | String/width alignment |
| use/writeline/TextIO confusion       | LOG | LOG-02 | TextIO write/writeline patterns |
| needs --std=08                       | GHDL | GHDL-01 | Use VHDL‑2008 consistently |
| clock discipline/CE usage            | TB | TB-05 | Clock & timing management |
| reset held long enough               | TB | TB-06 | Reset & initialization testing |

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
clk <= not clk after 16 ns;  -- signal shared across processes
process
  variable cnt : natural := 0; -- local, instant updates
begin
  wait until rising_edge(clk);
  cnt := cnt + 1;
end process;
```
**Tags**: #variables #signals #delta-cycles #tb-architecture

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
<!-- Consider a wrapper proc: report_test(name, passed, id) that emits both human text and machine sentinel. -->

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

### TB-05: Clock & timing management
**Problem**: Flaky tests from inconsistent timing and CE discipline.  
**Cause**: Free-running stimuli or implicit delays relative to clock.  
**Solution**: Drive enable/updates **synchronously**, prefer clock-enables over `wait for` when checking logic.  
**Pattern**:
```vhdl
wait until rising_edge(clk);
if ce = '1' then
  drive_inputs;
end if;
```
**Tags**: #clock #timing #clock-enable #determinism
<!-- Human note: when possible, sample DUT outputs only on edges; avoid mid-cycle sampling that depends on delta timing. -->

### TB-06: Reset & initialization testing
**Problem**: DUT passes nominal tests but fails power-up/first-cycle.  
**Cause**: Reset not held long enough; uninitialized regs/ROMs; missing deassertion sequencing.  
**Solution**: Create a dedicated reset/boot test that verifies post-reset defaults and first valid transaction.  
**Pattern**:
```vhdl
rst <= '1'; wait for 10*CLK_PERIOD;
rst <= '0'; wait until rising_edge(clk);
assert outputs = DEFAULTS report "post-reset defaults wrong" severity error;
```
**Tags**: #reset #initialization #timing

---

## Appendix: Agent-Contributed Tips
Agents may append new candidate tips **below this line**.  
Do not modify the main body above.

------- New Tips here-------

### Candidate: VS-03: Variable name hiding in nested scopes
**Problem**: GHDL warning about variable name hiding when declaring variables with same name in nested scopes.  
**Cause**: Declaring variables with identical names in procedure and containing process.  
**Solution**: Use unique variable names in nested scopes or accept the warning if intentional.  
**Pattern**:
```vhdl
process
  variable l: line;  -- Main process variable
  procedure report_test(name: string) is
    variable l: line;  -- WARNING: hides outer 'l'
  begin
    write(l, name);
    writeline(output, l);
  end procedure;
begin
  -- Use different names to avoid hiding
  report_test("test");
end process;
```
**Tags**: #candidate #unreviewed #variables #scope #ghdl-warning

### Candidate: GHDL-04: Metavalue warnings in NUMERIC_STD operations
**Problem**: GHDL warnings about metavalues detected in NUMERIC_STD operations during simulation.  
**Cause**: Uninitialized signals or undefined values being used in arithmetic/comparison operations.  
**Solution**: Initialize all signals properly and ensure all inputs are defined before use.  
**Pattern**:
```vhdl
-- Initialize signals to avoid metavalues
signal counter : unsigned(15 downto 0) := (others => '0');
signal data_in : std_logic_vector(7 downto 0) := (others => '0');

-- Check for valid values before arithmetic
if data_in /= "UUUUUUUU" then
  result <= unsigned(data_in) + 1;
end if;
```
**Tags**: #candidate #unreviewed #metavalues #initialization #numeric-std

### Candidate: TB-07: Comprehensive test vector design
**Problem**: Ad-hoc test cases lead to incomplete coverage and inconsistent results.  
**Cause**: Lack of systematic approach to test case generation and validation.  
**Solution**: Use structured test vectors with expected results for systematic testing.  
**Pattern**:
```vhdl
-- Define test vector record type
type test_vector_t is record
    input1    : std_logic_vector(7 downto 0);
    input2    : std_logic_vector(7 downto 0);
    expected  : boolean;
end record;

-- Create test vector array
constant test_vectors : test_vector_array_t := (
    ("00000001", "00000001", true),   -- Valid case 1
    ("00000000", "00000001", false),  -- Invalid case 1
    ("11111111", "00000001", true)    -- Valid case 2
);

-- Use in test loop
for i in test_vectors'range loop
    apply_stimulus(test_vectors(i).input1, test_vectors(i).input2);
    check_result(test_vectors(i).expected);
end loop;
```
**Tags**: #candidate #unreviewed #test-vectors #systematic-testing #coverage

### Candidate: TB-08: System integration testing with operational mode validation
**Problem**: Top-level testbenches only test basic functionality, missing system-level integration validation.  
**Cause**: Lack of comprehensive system state testing and operational mode validation.  
**Solution**: Test system-level integration with operational mode validation and comprehensive system state checking.  
**Pattern**:
```vhdl
-- System integration test with operational mode validation
type system_test_vector_t is record
    input_config : std_logic_vector(7 downto 0);
    expected_ready : boolean;
    expected_mode  : std_logic_vector(1 downto 0);
end record;

-- Test system integration
for i in system_test_vectors'range loop
    apply_system_stimulus(system_test_vectors(i).input_config);
    
    -- Validate system state
    check_system_ready(system_test_vectors(i).expected_ready);
    check_operational_mode(system_test_vectors(i).expected_mode);
    check_system_integration();
end loop;
```
**Tags**: #candidate #unreviewed #system-integration #operational-modes #top-level-testing

# Synthesizable VHDL Tips and Best Practices (Structured)

> Dual-purpose format: concise, machine-friendly rules in the open text; deeper human notes and long examples inside HTML comments.

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
| latch inferred         | PROC     | PROC-01 | Avoid unintended latches |
| port mismatch at elaboration | PROC | PROC-02 | Direct instantiation patterns |
| signal priority confusion | PROC | PROC-03 | Reset/enable signal hierarchy |
| multiple drivers error | SIG      | SIG-01  | Single-writer for signals |
| port type mismatch     | SIG      | SIG-02  | Port mapping best practices |
| unclear signal behavior | SIG | SIG-03 | Signal priority and truth table patterns |
| timing violation       | TIM      | TIM-01  | Constrain critical paths |
| missing unit errors    | STD      | STD-02  | Library management and compilation order |
| generic not configured | STD | STD-03 | Generic parameter passing patterns |
| …                      | …        | …       | … |

---

## 1) Processes & State Machines (PROC)

### PROC-01: Avoid unintended latches
**Problem**: Latches inferred unexpectedly.  
**Cause**: Incomplete process sensitivity list or missing default assignments.  
**Solution**: Ensure all branches assign outputs, and use clocked processes for storage.  
**Pattern**:
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    q <= d;
  end if;
end process;
```
**Tags**: #process #fsm #latch

---

## 2) Signals & Assignments (SIG)

### SIG-01: Single-writer for signals
**Problem**: Multiple drivers create 'X' or 'U'.  
**Cause**: Same signal assigned from different processes.  
**Solution**: Follow single-writer rule; resolve externally if needed.  
**Pattern**:
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    out_sig <= next_val;
  end if;
end process;
```
**Tags**: #signals #drivers #discipline

---

## 3) Timing & Clocks (TIM)

### TIM-01: Constrain critical paths
**Problem**: Timing violations in synthesis.  
**Cause**: Long combinatorial logic between flops.  
**Solution**: Add pipeline registers; use proper clock constraints.  
**Pattern**:
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    stage1 <= a + b;
    stage2 <= stage1 + c;
  end if;
end process;
```
**Tags**: #timing #pipeline #constraints

---

## 4) Resources & Structures (RES)

### RES-01: BRAM inference patterns
**Problem**: Memory inferred as registers instead of BRAM.  
**Cause**: Incorrect coding style.  
**Solution**: Use array + clocked process style.  
**Pattern**:
```vhdl
type ram_t is array(0 to 255) of std_logic_vector(7 downto 0);
signal ram : ram_t;
...
process(clk)
begin
  if rising_edge(clk) then
    if we = '1' then
      ram(addr) <= din;
    end if;
    dout <= ram(addr);
  end if;
end process;
```
**Tags**: #bram #inference

---

## 5) Portability & Standards (STD)

### STD-01: Use portable subset for Verilog
**Problem**: Non-portable constructs.  
**Cause**: Using VHDL features without Verilog analogues.  
**Solution**: Stick to basic types, avoid records, keep FSM encoding explicit.  
**Pattern**:
```vhdl
-- Portable FSM
type state_t is (IDLE, RUN, DONE);
signal state : state_t := IDLE;

process(clk)
begin
  if rising_edge(clk) then
    case state is
      when IDLE => state <= RUN;
      when RUN  => state <= DONE;
      when DONE => state <= IDLE;
    end case;
  end if;
end process;
```
**Tags**: #portability #verilog #fsm

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

### PROC-02: Direct instantiation patterns
**Problem**: Port mismatches caught at elaboration time, not analysis time.  
**Cause**: Using traditional component declarations instead of direct instantiation.  
**Solution**: Use direct instantiation with proper library references and named association.  
**Pattern**:
```vhdl
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
**Tags**: #direct-instantiation #port-mapping #library-management
<!-- See README-direct-instantiation.md for detailed examples and advanced patterns -->

### PROC-03: Reset/enable signal hierarchy
**Problem**: Confusion about signal priority and behavior.  
**Cause**: Unclear hierarchy between reset, clock enable, and functional enable.  
**Solution**: Follow strict priority: Reset > clk_en > enable.  
**Pattern**:
```vhdl
process(clk, rst_n)
begin
    if rst_n = '0' then
        -- Reset dominates
        state <= IDLE;
    elsif rising_edge(clk) then
        if clk_en = '1' then
            if enable = '1' then
                -- Normal operation
                state <= next_state;
            end if;
            -- clk_en='0' holds state
        end if;
    end if;
end process;
```
**Tags**: #reset #clock-enable #signal-hierarchy
<!-- See README-RESET.md for complete truth table and behavior details -->

### SIG-02: Port mapping best practices
**Problem**: Port type mismatches and missing connections.  
**Cause**: Incorrect port mapping syntax or missing type conversions.  
**Solution**: Use named association with explicit type conversions.  
**Pattern**:
```vhdl
-- Named association (recommended)
U1: entity WORK.DCSequencer
    port map (
        Clk => Clk,
        Reset => Reset,
        DataIn => InputA,
        HIThreshold => signed(Control0(31 downto 16)),  -- explicit conversion
        LOThreshold => signed(Control0(15 downto 0)),   -- explicit conversion
        DataOutA => DataOutA,
        DataOutB => DataOutB
    );
```
**Tags**: #port-mapping #type-conversion #named-association

### SIG-03: Signal priority and truth table patterns
**Problem**: Unclear signal behavior in complex enable/reset scenarios.  
**Cause**: Missing clear priority hierarchy and truth table documentation.  
**Solution**: Document signal priority and use consistent truth table patterns.  
**Pattern**:
```vhdl
-- Signal priority: Reset > clk_en > enable
-- Truth table:
-- Reset | clk_en | enable | Behavior
--   1   |   X    |   X    | Reset dominates → safe defaults
--   0   |   0    |   X    | Clock frozen → hold state, no updates
--   0   |   1    |   0    | Idle/hold → state stable, outputs parked
--   0   |   1    |   1    | Normal operation → advance state, process data

process(clk, rst_n)
begin
    if rst_n = '0' then
        -- Reset dominates
        output <= (others => '0');
        state <= IDLE;
    elsif rising_edge(clk) then
        if clk_en = '1' then
            if enable = '1' then
                -- Normal operation
                output <= next_output;
                state <= next_state;
            end if;
            -- clk_en='0' holds state
        end if;
    end if;
end process;
```
**Tags**: #signal-hierarchy #truth-table #reset-priority

### STD-02: Library management and compilation order
**Problem**: Missing unit errors and compilation failures.  
**Cause**: Incorrect library references or wrong compilation order.  
**Solution**: Use proper library references and compile in dependency order.  
**Pattern**:
```vhdl
-- Always specify library for direct instantiation
U1: entity WORK.DCSequencer port map (...);  -- WORK library
U2: entity IEEE.STD_LOGIC_ARITH.ALL;         -- IEEE library
U3: entity my_lib.my_entity port map (...);  -- Custom library
```
```bash
# Compilation order: dependencies first
ghdl -a --std=08 dependency.vhd
ghdl -a --std=08 entity.vhd
ghdl -a --std=08 top.vhd
ghdl -e --std=08 top
```
**Tags**: #library-management #compilation-order #dependencies

### STD-03: Generic parameter passing patterns
**Problem**: Generic parameters not properly configured for different instances.  
**Cause**: Missing or incorrect generic map usage.  
**Solution**: Use explicit generic map with named association.  
**Pattern**:
```vhdl
-- Single instance with generics
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

-- Multiple instances with different configurations
U1: entity WORK.Counter
    generic map (WIDTH => 8)
    port map (clk => clk, rst => rst, count => count8);

U2: entity WORK.Counter
    generic map (WIDTH => 16)
    port map (clk => clk, rst => rst, count => count16);
```
**Tags**: #generics #parameter-passing #configuration


# Synthesizable VHDL Tips and Best Practices (Structured, -ng)

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
| multiple drivers error | SIG      | SIG-01  | Single-writer for signals |
| positional map mismatch| SIG      | SIG-02  | Prefer named association & explicit conversions |
| priority confusion     | SIG      | SIG-03  | Define signal priority & truth table |
| timing violation       | TIM      | TIM-01  | Constrain critical paths |

---

## 1) Processes & State Machines (PROC)

### PROC-01: Avoid unintended latches
**Problem**: Latches inferred unexpectedly.  
**Cause**: Incomplete process branches or missing default assignments.  
**Solution**: Ensure all branches assign outputs; use clocked processes for storage.  
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

### SIG-02: Prefer **named association** & explicit conversions
**Problem**: Port type mismatches and accidental mis-wiring with positional maps.  
**Cause**: Positional association hides intent; implicit conversions not applied.  
**Solution**: Use **named** port maps and explicit `std_logic_vector`/`unsigned` conversions.  
**Pattern**:
```vhdl
u_core: entity work.core
  port map (
    clk   => clk,
    rst   => rst,
    a_in  => std_logic_vector(a_u),
    b_in  => std_logic_vector(b_u),
    y_out => y
  );
```
**Tags**: #port-mapping #type-conversion #named-association

### SIG-03: Define **signal priority** & truth table
**Problem**: Unclear behavior when `reset`, `clock_enable`, and `enable` interact.  
**Cause**: Priority not documented; inconsistent implementation across modules.  
**Solution**: Adopt and document a **priority hierarchy** (e.g., `reset > clock_enable > enable`) and a truth table.  
**Pattern**:
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      y <= (others => '0');     -- highest priority
    elsif ce = '1' then
      if en = '1' then
        y <= next_y;
      end if;
    end if;
  end if;
end process;
```
**Tags**: #signal-priority #truth-table #documentation
<!-- Human note: mirror this priority in your module README and TBs; include an explicit truth-table for reviewers. -->

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
**Solution**: Stick to basic types; keep FSM encoding explicit.  
**Pattern**:
```vhdl
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
Agents may append new candidate tips **below this line**.  
Do not modify the main body above.

------- New Tips here-------

### Candidate: TIM-02: Pipeline registers for complex calculations
**Problem**: Long combinatorial paths causing timing violations in complex calculations.  
**Cause**: Multi-stage arithmetic or logic operations in single clock cycle.  
**Solution**: Break complex calculations into pipeline stages with intermediate registers.  
**Pattern**:
```vhdl
-- Pipeline complex calculation across multiple clock cycles
process(clk)
begin
  if rising_edge(clk) then
    -- Stage 1: Input processing
    stage1 <= unsigned(input_data);
    -- Stage 2: Arithmetic operation
    stage2 <= to_signed(to_integer(stage1) * 16, 16);
    -- Stage 3: Output with clamping
    if stage2 > MAX_VALUE then
      output <= MAX_VALUE;
    else
      output <= stage2;
    end if;
  end if;
end process;
```
**Tags**: #candidate #unreviewed #pipeline #timing #critical-paths

### Candidate: SIG-04: Comprehensive status reporting in top-level modules
**Problem**: Limited visibility into system state and operational status in top-level modules.  
**Cause**: Only basic status register provided, missing system-level status information.  
**Solution**: Add comprehensive status outputs including system_ready, config_valid, and operational_mode.  
**Pattern**:
```vhdl
-- Top-level module with comprehensive status reporting
entity top_module is
  port (
    -- Standard outputs
    data_out : out std_logic_vector(7 downto 0);
    status_reg : out std_logic_vector(7 downto 0);
    
    -- Additional status outputs
    stat_system_ready : out std_logic;
    stat_config_valid : out std_logic;
    stat_operational_mode : out std_logic_vector(1 downto 0)
  );
end entity;

-- Status generation
system_ready <= all_config_valid and (not fault_condition);
stat_system_ready <= system_ready;
stat_config_valid <= all_config_valid;
stat_operational_mode <= operational_mode;
```
**Tags**: #candidate #unreviewed #status-reporting #top-level #system-integration

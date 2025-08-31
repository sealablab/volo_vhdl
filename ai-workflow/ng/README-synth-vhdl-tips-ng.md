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

### SIG-04: Prohibit mixed synchronous/combinational logic
**Problem**: Mixed synchronous/combinational logic creates timing dependencies and race conditions.  
**Cause**: Combinational processes that depend on clocked signals, or clocked processes that depend on combinational signals.  
**Solution**: Keep logic purely synchronous OR purely combinational. Never mix clocked and combinational dependencies.  

**Context**: This rule was discovered during base module architectural review when alarm logic failed tests. The original implementation had a combinational status register process that depended on `counter_register` (a clocked signal), creating a race condition where the status register would update based on stale counter values.

**Real Example from Base Module**:
```vhdl
-- ❌ ORIGINAL BROKEN CODE: Mixed logic causing test failures
signal counter_register : unsigned(15 downto 0);  -- Clocked signal
signal alarm_active : std_logic;  -- Intermediate signal

-- Clocked process updates counter
process(clk, rst_n)
begin
    if rst_n = '0' then
        counter_register <= (others => '0');
    elsif rising_edge(clk) then
        if clk_en = '1' then
            counter_register <= counter_register - 1;  -- Clocked update
        end if;
    end if;
end process;

-- Combinational process depends on clocked signal - RACE CONDITION!
alarm_active <= '1' when counter_register <= threshold else '0';

-- Another combinational process depends on the intermediate signal
status_update: process(current_state, alarm_active)  -- Still mixed!
begin
    status_reg(ALARM_BIT) <= alarm_active;
end process;
```

**Pattern**:
```vhdl
-- ✅ CORRECT: Purely synchronous status register
process(clk, rst_n)
begin
    if rst_n = '0' then
        status_reg <= (others => '0');
        counter_register <= (others => '0');
    elsif rising_edge(clk) then
        if clk_en = '1' then
            -- All logic in one synchronous process
            if counter_register > 0 then
                counter_register <= counter_register - 1;
            end if;
            
            -- Status register updated synchronously with counter
            status_reg <= create_status_reg(
                fault => '1' when current_state = FAULT_STATE else '0',
                alarm => '1' when counter_register <= threshold else '0',
                -- ... other bits
            );
        end if;
    end if;
end process;

-- ❌ FORBIDDEN: Mixed logic - combinational process depending on clocked signals
process(current_state, counter_register)  -- counter_register is clocked!
begin
    alarm_active <= '1' when counter_register <= threshold else '0';
end process;

-- ❌ FORBIDDEN: Intermediate signals between clocked and combinational
signal intermediate_signal : std_logic;  -- Avoid this pattern
```

**Detection Methods**:
- Look for combinational processes in sensitivity list that include clocked signals
- Look for intermediate signals that are assigned in clocked processes but used in combinational processes
- Check for status registers or output logic that depends on internal state signals

**Test Symptoms**:
- Tests pass intermittently (timing-dependent)
- Status bits not updating as expected
- Alarm/warning logic not triggering correctly
- Debug output shows correct internal state but wrong outputs

**Verification**:
- All combinational processes should only depend on inputs and other combinational signals
- All clocked processes should contain all logic that depends on internal state
- Status registers should be updated synchronously in the main clocked process

**Tags**: #mixed-logic #timing #race-condition #synchronous #combinational #base-module #architectural-review

### SIG-05: Prefer direct bit assignments over complex functions
**Problem**: Complex status register functions create unnecessary complexity and potential timing issues.  
**Cause**: Functions like `create_status_reg()` were created to accommodate separate processes, but add complexity when integrated into main clocked process.  
**Solution**: Use direct bit assignments for status registers in clocked processes.  
**Pattern**:
```vhdl
-- ✅ CORRECT: Direct bit assignments in clocked process
process(clk, rst_n)
begin
    if rst_n = '0' then
        status_reg <= (others => '0');
    elsif rising_edge(clk) then
        if clk_en = '1' then
            -- Clear all bits first
            status_reg(STATUS_FAULT_BIT) <= '0';
            status_reg(STATUS_ALARM_BIT) <= '0';
            status_reg(STATUS_BUSY_BIT) <= '0';
            status_reg(STATUS_READY_BIT) <= '0';
            status_reg(STATUS_ACTIVE_BIT) <= '0';
            status_reg(STATUS_IDLE_BIT) <= '0';
            status_reg(STATUS_VALID_BIT) <= '0';
            status_reg(STATUS_ENABLED_BIT) <= '0';
            
            -- Set appropriate bits based on state
            if current_state = IDLE_STATE then
                status_reg(STATUS_ACTIVE_BIT) <= '1';
                status_reg(STATUS_IDLE_BIT) <= '1';
                status_reg(STATUS_VALID_BIT) <= '1';
                status_reg(STATUS_ENABLED_BIT) <= enable;
                if counter_register <= ALARM_THRESHOLD then
                    status_reg(STATUS_ALARM_BIT) <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

-- ❌ AVOID: Complex function calls in clocked processes
status_reg <= create_status_reg('0', '1', '0', '0', enable, '1', '1', '1');
```
**Tags**: #status-register #direct-assignment #simplicity #clocked-process

### TB-07: Focus testbenches on essential functionality
**Problem**: Testbenches become overly complex with too many edge cases and internal state peeking.  
**Cause**: Trying to test every possible scenario and debug internal implementation details.  
**Solution**: Focus on essential functionality through public interface, use black-box testing.  
**Pattern**:
```vhdl
-- ✅ CORRECT: Focused testbench with essential tests
test_process : process
begin
    -- Test 1: Invalid input should cause FAULT state
    counter_in <= x"0000"; -- Invalid input
    rst_n <= '0'; wait until rising_edge(clk);
    rst_n <= '1'; wait until rising_edge(clk);
    test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1');
    
    -- Test 2: Valid input should allow normal state transitions
    counter_in <= x"0005"; -- Valid input
    rst_n <= '0'; wait until rising_edge(clk);
    rst_n <= '1'; wait until rising_edge(clk);
    wait until rising_edge(clk); -- Transition to READY
    wait until rising_edge(clk); -- Transition to IDLE
    test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1');
    
    -- Test 3: Alarm functionality should work
    wait until rising_edge(clk); -- Count down
    wait until rising_edge(clk); -- Count down
    wait until rising_edge(clk); -- Count down (alarm should trigger)
    test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
    
    wait;
end process;

-- ❌ AVOID: Complex testbenches with internal state peeking
signal debug_current_state : std_logic_vector(1 downto 0);
-- ... 14 different tests with debug output
```
**Tags**: #testbench #black-box #essential-functionality #public-interface

### Candidate: PROC-02: Function declarations in architectures
**Problem**: GHDL error when declaring functions directly in architecture body.  
**Cause**: Functions must be declared in packages or within processes, not as standalone declarations in architecture.  
**Solution**: Move function logic into processes or create separate packages for reusable functions.  
**Pattern**:
```vhdl
-- WRONG: Function in architecture body
architecture behavioral of entity is
  function my_func(x: std_logic_vector) return std_logic_vector is
  begin
    return x;
  end function;
begin
  -- ...
end architecture;

-- CORRECT: Function logic in process
architecture behavioral of entity is
begin
  process(input)
    variable result: std_logic_vector(7 downto 0);
  begin
    -- Function logic here
    result := input + 1;
    output <= result;
  end process;
end architecture;
```
**Tags**: #candidate #unreviewed #functions #architecture #ghdl-error

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

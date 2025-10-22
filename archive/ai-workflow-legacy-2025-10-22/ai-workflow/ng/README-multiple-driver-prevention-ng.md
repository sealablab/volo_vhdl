# Multiple Driver Prevention - VOLO VHDL Standard

## Overview
Multiple driver conflicts are a common VHDL design error that results in 'X' (unknown) values and simulation failures. This document establishes systematic patterns to prevent multiple driver issues in VOLO VHDL modules.

## Root Cause Analysis

### **What Causes Multiple Drivers?**
A signal is driven by **multiple processes** or **multiple assignments** within the same process, violating VHDL's fundamental rule that each signal can have only **one driver**.

### **Common Scenarios:**
1. **Reset + Combinational Logic**: Signal driven by both reset logic and combinational process
2. **Multiple Clocked Processes**: Same signal assigned in different clocked processes  
3. **Process + Concurrent Assignment**: Signal assigned in process and concurrent statement
4. **Nested Process Conflicts**: Signal driven by parent and child processes

## Prevention Patterns

### **Pattern 1: Single Driver Per Signal Rule**
**Problem**: Signal driven by multiple processes
**Solution**: Ensure each signal has exactly one driver
**Pattern**:
```vhdl
-- ✅ GOOD: Single driver pattern
signal status_reg : std_logic_vector(7 downto 0) := (others => '0');

-- Clocked process handles state machine
main_process: process(clk, rst_n)
begin
    if rst_n = '0' then
        current_state <= RESET_STATE;
        -- status_reg NOT assigned here
    elsif rising_edge(clk) then
        -- State machine logic only
        current_state <= next_state;
    end if;
end process;

-- Combinational process handles status register
status_update: process(current_state, enable, valid)
begin
    status_reg <= create_status_from_state(current_state, enable, valid);
end process;
```

### **Pattern 2: Reset-Only Clocked Process**
**Problem**: Mixing reset logic with combinational logic
**Solution**: Separate reset handling from combinational logic
**Pattern**:
```vhdl
-- ✅ GOOD: Reset-only clocked process
main_process: process(clk, rst_n)
begin
    if rst_n = '0' then
        -- Only reset state machine signals
        current_state <= RESET_STATE;
        counter_reg <= (others => '0');
        -- DO NOT reset status_reg here
    elsif rising_edge(clk) then
        -- Only state machine transitions
        current_state <= next_state;
        counter_reg <= next_counter;
    end if;
end process;

-- Separate combinational process for status
status_process: process(current_state, enable, valid)
begin
    status_reg <= compute_status(current_state, enable, valid);
end process;
```

### **Pattern 3: Status Register Architecture**
**Problem**: Status register driven by multiple sources
**Solution**: Dedicated status computation process
**Pattern**:
```vhdl
-- ✅ GOOD: Dedicated status architecture
architecture behavioral of module_core is
    -- State machine signals (clocked)
    signal current_state : std_logic_vector(1 downto 0) := RESET_STATE;
    signal counter_reg   : unsigned(15 downto 0) := (others => '0');
    
    -- Status signals (combinational)
    signal status_reg    : std_logic_vector(7 downto 0) := (others => '0');
    
begin
    -- Clocked process: State machine only
    state_machine: process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= RESET_STATE;
            counter_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- State transitions only
            current_state <= next_state;
            counter_reg <= next_counter;
        end if;
    end process;
    
    -- Combinational process: Status computation only
    status_compute: process(current_state, enable, valid, counter_reg)
    begin
        status_reg <= create_status_reg(current_state, enable, valid, counter_reg);
    end process;
    
    -- Output assignment
    stat_status_out <= status_reg;
end architecture;
```

### **Pattern 4: Signal Initialization Strategy**
**Problem**: Uninitialized signals causing 'X' values
**Solution**: Proper signal initialization and single driver
**Pattern**:
```vhdl
-- ✅ GOOD: Proper initialization
architecture behavioral of module_core is
    -- Initialize all signals with safe defaults
    signal current_state : std_logic_vector(1 downto 0) := RESET_STATE;
    signal status_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal counter_reg   : unsigned(15 downto 0) := (others => '0');
    
begin
    -- Single driver per signal
    state_process: process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= RESET_STATE;  -- Only state machine
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    status_process: process(current_state, enable)
    begin
        status_reg <= compute_status(current_state, enable);  -- Only status
    end process;
end architecture;
```

## Design Rules

### **Rule 1: One Driver Per Signal**
- Each signal must have exactly **one driver**
- Never assign the same signal in multiple processes
- Use separate signals for different purposes

### **Rule 2: Separate Concerns**
- **State machine signals**: Driven by clocked processes only
- **Status signals**: Driven by combinational processes only
- **Output signals**: Simple assignments from internal signals

### **Rule 3: Reset Strategy**
- **Reset only state machine signals** in clocked processes
- **Do not reset status registers** in clocked processes
- **Let combinational logic handle status** based on current state

### **Rule 4: Signal Naming Convention**
- **State signals**: `current_state`, `next_state`, `counter_reg`
- **Status signals**: `status_reg`, `alarm_active`, `valid_flags`
- **Output signals**: `stat_*_out`, `data_*_out`

## Validation Checklist

### **Pre-Implementation**
- [ ] **Signal Analysis**: List all signals and their drivers
- [ ] **Driver Count**: Verify each signal has exactly one driver
- [ ] **Process Separation**: Separate state machine from status logic
- [ ] **Reset Strategy**: Plan reset behavior for each signal

### **Implementation**
- [ ] **Single Driver**: Each signal assigned in only one process
- [ ] **Process Purpose**: Each process has single, clear purpose
- [ ] **Signal Initialization**: All signals properly initialized
- [ ] **No Cross-Drivers**: No signal driven by multiple processes

### **Post-Implementation**
- [ ] **Compilation Check**: No multiple driver warnings
- [ ] **Simulation Check**: No 'X' values in status registers
- [ ] **Test Validation**: All tests pass without metavalue issues
- [ ] **Code Review**: Peer review for driver conflicts

## Common Anti-Patterns

### **❌ Anti-Pattern 1: Reset + Status in Same Process**
```vhdl
-- BAD: Multiple drivers for status_reg
main_process: process(clk, rst_n)
begin
    if rst_n = '0' then
        current_state <= RESET_STATE;
        status_reg <= (others => '0');  -- Driver 1
    elsif rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;

status_process: process(current_state)
begin
    status_reg <= compute_status(current_state);  -- Driver 2 - CONFLICT!
end process;
```

### **❌ Anti-Pattern 2: Multiple Clocked Processes**
```vhdl
-- BAD: Same signal in multiple clocked processes
process1: process(clk, rst_n)
begin
    if rst_n = '0' then
        status_reg <= (others => '0');  -- Driver 1
    elsif rising_edge(clk) then
        -- logic
    end if;
end process;

process2: process(clk, rst_n)
begin
    if rst_n = '0' then
        -- other logic
    elsif rising_edge(clk) then
        status_reg <= new_status;  -- Driver 2 - CONFLICT!
    end if;
end process;
```

### **❌ Anti-Pattern 3: Process + Concurrent Assignment**
```vhdl
-- BAD: Signal driven by process and concurrent assignment
status_process: process(current_state)
begin
    status_reg <= compute_status(current_state);  -- Driver 1
end process;

-- Concurrent assignment
status_reg <= (others => '0') when rst_n = '0' else status_reg;  -- Driver 2 - CONFLICT!
```

## Testing for Multiple Drivers

### **Compilation Warnings**
```bash
# Look for these GHDL warnings:
# warning: multiple drivers for signal "status_reg"
# warning: signal "status_reg" has multiple drivers
```

### **Simulation Metavalues**
```vhdl
-- Test for 'X' values in status registers
assert stat_status_out /= "XXXXXXXX" 
    report "Multiple driver detected: status register has 'X' values" 
    severity error;
```

### **Debug Output**
```vhdl
-- Add debug output to detect metavalues
write(l, string'("DEBUG: Status = " & to_string(stat_status_out)));
writeline(output, l);
-- Look for 'X' characters in output
```

## Integration with VOLO Workflow

### **Template Integration**
- All VOLO templates must follow single driver patterns
- Status register architecture must be separated from state machine
- Reset strategy must be clearly defined

### **Code Review Process**
- Reviewers must check for multiple driver conflicts
- Automated tools should detect driver conflicts
- Testbenches must validate no 'X' values

### **Documentation Requirements**
- Signal driver analysis must be documented
- Process purposes must be clearly stated
- Reset behavior must be explicitly defined

---

**This systematic approach ensures that multiple driver conflicts are prevented at the design level, resulting in reliable, maintainable VHDL code.**
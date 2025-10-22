# VOLO VHDL Standard State Machine Pattern

## Overview
All VOLO VHDL modules inherit a standard base state machine pattern that provides consistent behavior across the framework. This document defines the mandatory state transitions and patterns that agents must follow.

## Standard VOLO State Transitions

### **Base Module States (Mandatory)**
Every VOLO module inherits these three states as the foundation:

```vhdl
-- Standard VOLO Base Module States (inherited by all modules)
constant RESET_STATE     : std_logic_vector(2 downto 0) := "000";
constant READY_STATE     : std_logic_vector(2 downto 0) := "001";
constant IDLE_STATE      : std_logic_vector(2 downto 0) := "010";
constant FAULT_STATE     : std_logic_vector(2 downto 0) := "011";
```

### **State Transition Flow**
```
RESET_STATE → READY_STATE → IDLE_STATE
     ↓              ↓           ↓
FAULT_STATE ← FAULT_STATE ← FAULT_STATE
```

### **State Behavior Definitions**

#### **RESET_STATE (000)**
- **Purpose**: Initial state during reset and configuration validation
- **Behavior**: 
  - All outputs in safe state
  - Capture and validate configuration parameters
  - Set status register to indicate reset state
- **Transitions**:
  - Valid configuration → READY_STATE
  - Invalid configuration → FAULT_STATE
  - Reset active → RESET_STATE

#### **READY_STATE (001)**
- **Purpose**: Configuration validated, ready for operation
- **Behavior**:
  - All outputs in safe state
  - Configuration parameters locked in
  - Status register indicates ready state
- **Transitions**:
  - Automatic → IDLE_STATE (inviolate transition)
  - Invalid configuration → FAULT_STATE

#### **IDLE_STATE (010)**
- **Purpose**: Module ready for user interaction/operation
- **Behavior**:
  - All outputs in safe state
  - Waiting for user input/trigger
  - Status register indicates idle state
- **Transitions**:
  - User trigger → Custom states (module-specific)
  - Invalid configuration → FAULT_STATE
  - Module disable → RESET_STATE

#### **FAULT_STATE (011)**
- **Purpose**: Error condition, requires reset
- **Behavior**:
  - All outputs in safe state
  - Error status indicated
  - No automatic recovery
- **Transitions**:
  - Reset only → RESET_STATE

## Module-Specific State Extension

### **Custom State Encoding**
Modules may add custom states beyond the base pattern:

```vhdl
-- Standard VOLO Base Module States (inherited)
constant RESET_STATE     : std_logic_vector(2 downto 0) := "000";
constant READY_STATE     : std_logic_vector(2 downto 0) := "001";
constant IDLE_STATE      : std_logic_vector(2 downto 0) := "010";
constant FAULT_STATE     : std_logic_vector(2 downto 0) := "011";

-- Module-specific states (extending base module)
constant CUSTOM_STATE_1  : std_logic_vector(2 downto 0) := "100";
constant CUSTOM_STATE_2  : std_logic_vector(2 downto 0) := "101";
constant CUSTOM_STATE_3  : std_logic_vector(2 downto 0) := "110";
-- Note: "111" reserved for future use
```

### **Custom State Transitions**
Custom states must follow these rules:
- **Entry**: Only from IDLE_STATE (via user trigger)
- **Exit**: Return to IDLE_STATE or go to FAULT_STATE
- **No direct transitions** between custom states and base states (except IDLE)

## Implementation Patterns

### **State Machine Process Structure**
```vhdl
main_process: process(clk, rst_n)
begin
    -- Highest priority: Reset
    if rst_n = '0' then
        current_state <= RESET_STATE;
        -- Initialize all registers
        
    elsif rising_edge(clk) then
        -- Second priority: Clock enable
        if clk_en = '1' then
            -- Third priority: Module enable
            if enable = '1' then
                -- State machine logic
                case current_state is
                    when RESET_STATE =>
                        -- Capture and validate configuration
                        -- Transition based on validation
                        
                    when READY_STATE =>
                        -- Automatic transition to IDLE
                        current_state <= IDLE_STATE;
                        
                    when IDLE_STATE =>
                        -- Wait for user trigger
                        -- Transition to custom states
                        
                    when CUSTOM_STATE_1 =>
                        -- Module-specific behavior
                        -- Return to IDLE when complete
                        
                    when FAULT_STATE =>
                        -- Stay in fault until reset
                        current_state <= FAULT_STATE;
                        
                    when others =>
                        current_state <= FAULT_STATE;
                end case;
                
            else
                -- Module disabled - return to RESET
                current_state <= RESET_STATE;
            end if;
        end if;
    end if;
end process main_process;
```

### **Status Register Updates**
Each state must update the status register appropriately:

```vhdl
-- RESET_STATE
status_reg <= (others => '0');
status_reg(STATUS_IDLE_BIT) <= '1';
status_reg(STATUS_VALID_BIT) <= config_valid;

-- READY_STATE
status_reg <= (others => '0');
status_reg(STATUS_READY_BIT) <= '1';
status_reg(STATUS_VALID_BIT) <= '1';

-- IDLE_STATE
status_reg <= (others => '0');
status_reg(STATUS_IDLE_BIT) <= '1';
status_reg(STATUS_VALID_BIT) <= '1';

-- FAULT_STATE
status_reg <= (others => '0');
status_reg(STATUS_FAULT_BIT) <= '1';
```

## Agent Guidelines

### **When Creating New Modules**
1. **Always inherit** the base state pattern (RESET→READY→IDLE)
2. **Add custom states** only after IDLE_STATE
3. **Use 3-bit encoding** for state vectors to allow for custom states
4. **Follow the transition rules** (no direct custom→base transitions)
5. **Update status register** in each state

### **When Analyzing Requirements**
1. **Assume base states exist** - don't ask about RESET/READY/IDLE
2. **Focus on custom states** - what happens after IDLE?
3. **Check transition logic** - how does user input trigger custom states?
4. **Verify return path** - how do custom states return to IDLE?

### **When Generating Code**
1. **Include base state constants** in constants package
2. **Implement base state logic** in main process
3. **Add custom state logic** after base states
4. **Follow priority hierarchy** (reset > enable > clk_en > normal operation)

## Common Patterns

### **Simple Trigger-Based Modules**
- IDLE → (trigger) → CUSTOM_STATE → IDLE
- Example: Stoplight, Timer, Counter

### **Multi-Step Modules**
- IDLE → (trigger) → CUSTOM_STATE_1 → CUSTOM_STATE_2 → CUSTOM_STATE_3 → IDLE
- Example: State machines with multiple phases

### **Continuous Operation Modules**
- IDLE → (trigger) → CUSTOM_STATE → (complete) → IDLE
- Example: Data processing, calculations

## Benefits

### **Consistency**
- All modules behave the same way during reset/configuration
- Predictable state transitions across the framework
- Standardized error handling

### **Maintainability**
- Clear separation between base and custom logic
- Easy to understand and debug
- Consistent testing patterns

### **Integration**
- Modules can be easily integrated into larger systems
- Standard interface for control and status
- Predictable behavior for system-level control

---

**This pattern ensures that all VOLO VHDL modules provide consistent, reliable behavior while allowing for module-specific functionality. Agents must follow this pattern when creating or analyzing VOLO modules.**

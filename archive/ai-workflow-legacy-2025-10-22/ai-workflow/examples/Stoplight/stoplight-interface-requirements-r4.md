# Stoplight Module Interface Requirements (Refined)

## 🎯 **Module Purpose**
Traffic light countdown timer with configurable delays for each light state. This module demonstrates the VOLO VHDL generation workflow by customizing the base module for traffic light functionality.

## Example usage:
The `stoplight-core` module will validate all input parameters on input, and
- Inherit standard VOLO base module transitions: RESET → READY → IDLE
- Once `trig_in` goes high while in IDLE state, move to `RED_STATE`
- After `cfg_red_delay` clock ticks, enter `YELLOW_STATE` for `cfg_yellow_delay` clock cycles
- After `cfg_yellow_delay` clock ticks, enter `GREEN_STATE` for `cfg_green_delay` clock cycles
- After `cfg_green_delay` clock cycles, return to IDLE state
- `trig_in` is ignored unless the module is in IDLE state

### **VOLO VHDL module dependencies**
- **volo_common_pkg**: Use for parameter validation functions
- **Base Module Pattern**: Inherit standard RESET→READY→IDLE transitions
- **Status Register**: Follow VOLO 8-bit status register convention
- **Error Handling**: Use enhanced package error handling patterns

## 🔧 **Interface Specification**

### **Control Signals** (Standard VOLO)
```vhdl
-- Clock and Reset
clk         : in  std_logic;                    -- System clock
rst_n       : in  std_logic;                    -- Active low reset
-- Control
enable      : in  std_logic;                    -- Module enable
clk_en      : in  std_logic;                    -- Clock enable

-- User specified
trig_in     : in  std_logic;                    -- Trigger in, starts the timers
```

### **Configuration Parameters**
```vhdl
-- Traffic Light Timing Configuration
cfg_red_delay    : in  std_logic_vector(15 downto 0);  -- Red duration (clks)
cfg_yellow_delay : in  std_logic_vector(15 downto 0);  -- Yellow duration (clks)  
cfg_green_delay  : in  std_logic_vector(15 downto 0);  -- Green duration (clks)
```

### **Output Signals**
```vhdl
-- Countdown Display
-- Note: `count_out` intended for future use
-- count_out   : out std_logic_vector(15 downto 0); -- Current countdown value

-- Status Register
-- Note: We will use three bits of the default / built-in status register to indicate the RED/YELLOW/GREEN
stat_status_out : out std_logic_vector(7 downto 0); -- 8-bit status register (bits)
-- Bit 7: FAULT active (module in error state)
-- Bit 6: ALARM
-- Bit 5: Enabled
-- Bit 4: VALID (configuration parameters are valid)
-- Bit 3: RED-Stat
-- Bit 2: YELLOW-Stat
-- Bit 1: GREEN-Stat
-- Bit 0: IDLE
```

## 🚦 **State Machine Behavior**

### **State Definitions** (Inheriting VOLO Base Module)
```vhdl
-- Standard VOLO Base Module States (inherited)
constant RESET_STATE     : std_logic_vector(2 downto 0) := "000";
constant READY_STATE     : std_logic_vector(2 downto 0) := "001";
constant IDLE_STATE      : std_logic_vector(2 downto 0) := "010";
constant FAULT_STATE     : std_logic_vector(2 downto 0) := "011";

-- Stoplight-specific states (extending base module)
constant RED_STATE       : std_logic_vector(2 downto 0) := "100";
constant YELLOW_STATE    : std_logic_vector(2 downto 0) := "101";
constant GREEN_STATE     : std_logic_vector(2 downto 0) := "110";
```

### **State Transitions** (Inheriting + Custom)
1. **RESET_STATE** → **READY_STATE** (on reset release and valid configuration) [VOLO Standard]
2. **READY_STATE** → **IDLE_STATE** (automatic transition) [VOLO Standard]
3. **RESET_STATE** → **FAULT_STATE** (on invalid configuration) [VOLO Standard]
4. **IDLE_STATE** → **RED_STATE** (on `trig_in` high) [Stoplight Custom]
5. **RED_STATE** → **YELLOW_STATE** (after red_delay countdown) [Stoplight Custom]
6. **YELLOW_STATE** → **GREEN_STATE** (after yellow_delay countdown) [Stoplight Custom]
7. **GREEN_STATE** → **IDLE_STATE** (after green_delay countdown) [Stoplight Custom]
8. **Any State** → **FAULT_STATE** (on invalid configuration) [VOLO Standard]

### **State Behavior**
- **RESET_STATE**: All lights OFF, waiting for valid configuration [VOLO Standard]
- **READY_STATE**: All lights OFF, configuration validated [VOLO Standard]
- **IDLE_STATE**: All lights OFF, waiting for trig_in [VOLO Standard + Stoplight]
- **RED_STATE**: Red light ON, countdown from cfg_red_delay [Stoplight Custom]
- **YELLOW_STATE**: Yellow light ON, countdown from cfg_yellow_delay [Stoplight Custom]
- **GREEN_STATE**: Green light ON, countdown from cfg_green_delay [Stoplight Custom]
- **FAULT_STATE**: All lights OFF, countdown = 0, error status [VOLO Standard]

## ⏱️ **Timer Logic**

### **Countdown Behavior**
- **Initialization**: Counter loaded with configured delay on state entry
- **Decrement**: Counter decrements on each clock cycle (when clk_en = '1')
- **State Change**: When counter reaches 0, transition to next state
- **Display**: count_out shows current counter value

### **Timer Configuration**
- **Minimum Delay**: 1 clock cycle (prevents zero-delay states)
- **Maximum Delay**: 65535 clock cycles (16-bit counter)
- **Invalid Delay**: 0 or > 65535 → FAULT_STATE

## 📊 **Status Register**

### **8-bit Status Register** (Standard VOLO)
```vhdl
-- Bit 7: FAULT active (module in error state)
-- Bit 6: ALARM
-- Bit 5: Enabled
-- Bit 4: VALID (configuration parameters are valid)
-- Bit 3: RED-Stat
-- Bit 2: YELLOW-Stat
-- Bit 1: GREEN-Stat
-- Bit 0: IDLE
```

### **Status Bit Logic**
- **FAULT**: Set when in FAULT_STATE or invalid configuration
- **ALARM**: Set when in YELLOW state
- **ENABLED**: Set when enable = '1'
- **VALID**: Set when configuration parameters are valid
- **RED-Stat**: Set when in RED_STATE
- **YELLOW-Stat**: Set when in YELLOW_STATE
- **GREEN-Stat**: Set when in GREEN_STATE
- **IDLE**: Set when in IDLE_STATE

## 🔧 **Configuration Validation**

### **Parameter Validation**
- **cfg_red_delay**: 1-40000 inclusive (clks), otherwise FAULT
- **cfg_yellow_delay**: 1-20000 inclusive (clks), otherwise FAULT
- **cfg_green_delay**: 30000-65000 inclusive (clks), otherwise FAULT
- **Invalid Parameters**: Cause immediate transition to FAULT_STATE

### **Validation Timing**
- **Reset Time**: Parameters validated when rst_n goes high
- **Runtime**: Parameters not re-validated during operation
- **Error Response**: Invalid parameters trigger FAULT_STATE

## 🎯 **Customization Requirements**

## 📋 **Test Requirements**

### **Basic Functionality Tests**
- [ ] Reset behavior and safe state
- [ ] State transitions (IDLE→RED→YELLOW→GREEN→IDLE)
- [ ] Timer countdown functionality
- [ ] Output signal generation

### **Configuration Tests**
- [ ] Valid delay parameter handling
- [ ] Invalid parameter validation and clamping
- [ ] Parameter update during operation

### **Status Register Tests**
- [ ] State bit updates
- [ ] Progress monitoring
- [ ] Error condition reporting

## 🔗 **Related Files**
- **Base Module**: `ai-workflow/modules/volo_base/core/base_module_core.vhd`
- **Enhanced Packages**: `ai-workflow/modules/volo_common/volo_common_pkg.vhd`
- **Roadmap**: `ai-workflow/STOPLIGHT-MODULE-ROADMAP.md`
- **Agent Guidelines**: `AGENTS.md`

---

**Ready for AI generation! 🚦🚀**

<!-- End of requirements refined from stoplight-interface-requirements-r3.md -->

# Stoplight Module Interface Requirements

## 🎯 **Module Purpose**
Traffic light countdown timer with configurable delays for each light state. This module demonstrates the VOLO VHDL generation workflow by customizing the base module for traffic light functionality.

## 🔧 **Interface Specification**

### **Control Signals** (Standard VOLO)
```vhdl
-- Clock and Reset
clk         : in  std_logic;                    -- System clock
rst_n       : in  std_logic;                    -- Active low reset

-- Control
enable      : in  std_logic;                    -- Module enable
clk_en      : in  std_logic;                    -- Clock enable
```

### **Configuration Parameters**
```vhdl
-- Traffic Light Timing Configuration
cfg_red_delay    : in  std_logic_vector(15 downto 0);  -- Red light duration (clocks)
cfg_yellow_delay : in  std_logic_vector(15 downto 0);  -- Yellow light duration (clocks)  
cfg_green_delay  : in  std_logic_vector(15 downto 0);  -- Green light duration (clocks)
```

### **Output Signals**
```vhdl
-- Traffic Light Control
light_out   : out std_logic_vector(2 downto 0);  -- Traffic light state
-- Bit 2: RED light (active high)
-- Bit 1: YELLOW light (active high)  
-- Bit 0: GREEN light (active high)

-- Countdown Display
count_out   : out std_logic_vector(15 downto 0); -- Current countdown value

-- Status Register
stat_status_out : out std_logic_vector(7 downto 0); -- 8-bit status register
```

## 🚦 **State Machine Behavior**

### **State Definitions**
```vhdl
-- Internal States (not exposed externally)
constant RED_STATE    : std_logic_vector(1 downto 0) := "00";
constant YELLOW_STATE : std_logic_vector(1 downto 0) := "01";
constant GREEN_STATE  : std_logic_vector(1 downto 0) := "10";
constant FAULT_STATE  : std_logic_vector(1 downto 0) := "11";
```

### **State Transitions**
1. **RESET_STATE** → **RED_STATE** (on reset release)
2. **RED_STATE** → **YELLOW_STATE** (after red_delay countdown)
3. **YELLOW_STATE** → **GREEN_STATE** (after yellow_delay countdown)
4. **GREEN_STATE** → **RED_STATE** (after green_delay countdown)
5. **Any State** → **FAULT_STATE** (on invalid configuration)

### **State Behavior**
- **RED_STATE**: Red light ON, countdown from cfg_red_delay
- **YELLOW_STATE**: Yellow light ON, countdown from cfg_yellow_delay  
- **GREEN_STATE**: Green light ON, countdown from cfg_green_delay
- **FAULT_STATE**: All lights OFF, countdown = 0, error status

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
-- Bit 6: ALARM active (countdown ≤ 5, warning condition)
-- Bit 5: BUSY active (module actively counting down)
-- Bit 4: READY active (module ready for operation)
-- Bit 3: ENABLED active (module enabled)
-- Bit 2: ACTIVE active (module in active state)
-- Bit 1: VALID active (configuration is valid)
-- Bit 0: IDLE active (module in idle state)
```

### **Status Bit Logic**
- **FAULT**: Set when in FAULT_STATE or invalid configuration
- **ALARM**: Set when countdown ≤ 5 (warning condition)
- **BUSY**: Set when actively counting down (not in FAULT_STATE)
- **READY**: Set when module is ready for operation
- **ENABLED**: Set when enable = '1'
- **ACTIVE**: Set when in RED/YELLOW/GREEN states
- **VALID**: Set when configuration parameters are valid
- **IDLE**: Set when in RESET_STATE

## 🔧 **Configuration Validation**

### **Parameter Validation**
- **cfg_red_delay**: Must be 1-65535, clamped to 1 if invalid
- **cfg_yellow_delay**: Must be 1-65535, clamped to 1 if invalid
- **cfg_green_delay**: Must be 1-65535, clamped to 1 if invalid
- **Invalid Parameters**: Cause immediate transition to FAULT_STATE

### **Validation Timing**
- **Reset Time**: Parameters validated when rst_n goes high
- **Runtime**: Parameters not re-validated during operation
- **Error Response**: Invalid parameters trigger FAULT_STATE

## 🎯 **Customization Requirements**

### **Base Module Customization**
- **State Machine**: Replace generic states with traffic light states
- **Timer Logic**: Replace generic counter with traffic light countdown
- **Output Logic**: Replace generic outputs with traffic light outputs
- **Status Register**: Customize status bits for traffic light monitoring

### **Enhanced Package Integration**
- **volo_common_pkg**: Use for parameter validation functions
- **Status Register**: Follow VOLO 8-bit status register convention
- **Error Handling**: Use enhanced package error handling patterns

## 📋 **Test Requirements**

### **Basic Functionality Tests**
- [ ] Reset behavior and safe state
- [ ] State transitions (RED→YELLOW→GREEN→RED)
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

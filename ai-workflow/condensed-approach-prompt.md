# Condensed Approach Implementation Prompt

## 🚀 Your Mission: Implement ProbeHero8 Fast & Right

You are implementing **ProbeHero8** using the condensed approach. This is about **speed + quality** - move fast, implement correctly, test thoroughly.

## 📋 What You're Building

**ProbeHero8** is an enhanced probe driver with:
- **FSM States**: IDLE → ARMED → FIRING → COOLING → HARDFAULT
- **Safety Features**: Parameter validation, ALARM signaling, fault detection
- **Enhanced Packages**: Validation functions, error handling, status registers
- **Verilog Portability**: VHDL-2008 that converts cleanly to Verilog

## 🎯 Implementation Phases (Do This Order)

### Phase 1: Project Setup (5 minutes)
```bash
# Create directory structure
mkdir -p modules/probe_hero8/{common,datadef,core,top,tb/{common,datadef,core,top}}

# Copy state machine template
cp templates/state_machine_base/state_machine_base.vhd modules/probe_hero8/core/probe_hero8_core.vhd
```

### Phase 2: Datadef Packages (15 minutes)
Create these packages in `modules/probe_hero8/datadef/`:

**`probe_config_pkg.vhd`** - Probe configuration types:
```vhdl
-- Probe selection, voltage levels, timing parameters
-- Validation functions for probe parameters
-- ALARM bit definitions
```

**`probe_status_pkg.vhd`** - Status and monitoring:
```vhdl
-- Status register layout
-- Error code definitions  
-- Health monitoring types
```

### Phase 3: Core Entity (20 minutes)
**File**: `modules/probe_hero8/core/probe_hero8_core.vhd`

**States to implement**:
- `ST_IDLE` (0x2) - Default operational state
- `ST_ARMED` (0x3) - Ready to fire, waiting for trigger
- `ST_FIRING` (0x4) - Actively firing probe
- `ST_COOLING` (0x5) - Post-fire cooling period
- `ST_HARD_FAULT` (0xF) - Safety-critical error state

**Key Features**:
- Parameter validation on reset
- Trigger detection and firing sequence
- Cooling timer with safety timeout
- ALARM bit generation for invalid parameters
- Status register updates

### Phase 4: Core Testbench (15 minutes)
**File**: `modules/probe_hero8/tb/core/probe_hero8_core_tb.vhd`

**Test Coverage**:
- Reset and enable/disable sequences
- State transitions (IDLE → ARMED → FIRING → COOLING)
- Parameter validation (valid/invalid probe selection)
- Firing sequence (trigger detection, timing, voltage)
- Error handling (invalid parameters → HARDFAULT)
- ALARM bit behavior

**GHDL Validation**:
```bash
ghdl -a --std=08 modules/probe_hero8/datadef/*.vhd
ghdl -a --std=08 modules/probe_hero8/core/*.vhd  
ghdl -a --std=08 modules/probe_hero8/tb/core/*.vhd
ghdl -e --std=08 probe_hero8_core_tb
ghdl -r --std=08 probe_hero8_core_tb
```

### Phase 5: Top Integration (10 minutes)
**File**: `modules/probe_hero8/top/probe_hero8_top.vhd`

**Requirements**:
- **MUST use direct instantiation**: `entity WORK.probe_hero8_core`
- External interface for platform control
- Register exposure (control, config, status)
- **NO CustomWrapper entity body**

### Phase 6: Top Testbench (10 minutes)
**File**: `modules/probe_hero8/tb/top/probe_hero8_top_tb.vhd`

**Requirements**:
- **MUST use direct instantiation** for all modules
- Test system integration
- Validate register interface
- End-to-end functionality

### Phase 7: System Validation (5 minutes)
- Run all testbenches
- Verify GHDL compilation
- Check timing and FSM behavior
- Validate error recovery

## 🔧 Technical Requirements (Non-Negotiable)

### VHDL-2008 + Verilog Portability
- ✅ Use `std_logic`, `std_logic_vector`, `unsigned`, `signed`
- ✅ FSMs: `std_logic_vector` encoding + constants (NO enums)
- ✅ Avoid VHDL-only features (records in RTL, subtypes, etc.)
- ✅ Records ALLOWED in datadef packages only

### Direct Instantiation (Required for Top Layer)
```vhdl
-- ✅ CORRECT (required for top layer)
U1: entity WORK.probe_hero8_core
    port map (
        clk => clk,
        rst_n => rst_n,
        -- ... other ports
    );

-- ❌ FORBIDDEN in top layer
-- component probe_hero8_core is ... end component;
-- U1: probe_hero8_core port map (...);
```

### State Machine Implementation
```vhdl
-- State constants (4-bit encoding)
constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
constant ST_ARMED      : std_logic_vector(3 downto 0) := "0011";  -- 0x3  
constant ST_FIRING     : std_logic_vector(3 downto 0) := "0100";  -- 0x4
constant ST_COOLING    : std_logic_vector(3 downto 0) := "0101";  -- 0x5
constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
```

### Testbench Requirements
- **Success**: Print `'ALL TESTS PASSED'`
- **Failure**: Print `'TEST FAILED'`
- **Completion**: Always print `'SIMULATION DONE'`
- **Progress**: Print individual test results

## 🚨 Critical Success Factors

1. **Start Coding Immediately** - Don't overthink, implement and iterate
2. **Use the State Machine Template** - Copy from `templates/state_machine_base/`
3. **Follow Directory Structure** - `common/datadef/core/top/tb/` organization
4. **Test Early and Often** - Run GHDL after each major component
5. **Direct Instantiation** - Required for all top-layer files
6. **Parameter Validation** - Safety-critical parameters must be validated on reset

## 📊 Evaluation Criteria

Your implementation will be evaluated on:
- **Development Speed** (30%) - How quickly you complete the implementation
- **Code Quality** (40%) - Adherence to VOLO standards, proper structure
- **Developer Experience** (20%) - How easy it is to understand and maintain
- **Implementation Accuracy** (10%) - Correctness of functionality

## 🎯 Success Definition

**You've succeeded when**:
- ✅ All testbenches pass with `'ALL TESTS PASSED'`
- ✅ GHDL compiles without errors (`ghdl --std=08`)
- ✅ Core functionality works (state transitions, parameter validation, firing sequence)
- ✅ Top-level integration works end-to-end
- ✅ Code follows VOLO standards (direct instantiation, VHDL-2008, Verilog portability)

## 🚀 Ready to Start?

**Your first action**: Create the directory structure and copy the state machine template. Then start implementing the datadef packages.

**Remember**: This is about speed AND quality. Move fast, but do it right. The condensed approach means less planning overhead, not less attention to detail.

**Go build ProbeHero8!** 🚀
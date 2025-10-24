# Inspectable FSM Pattern - Requirements Document

**Pattern Name:** `inspectable_fsm_observer`
**Purpose:** Reusable pattern for making ANY VHDL state machine observable via oscilloscope
**Date:** 2025-10-24
**Author:** Human/AI collaborative design

---

## 1. Overview

**Problem**: State machines are invisible on deployed hardware. Internal signals don't exist after synthesis. Debugging requires:
- Simulation (doesn't catch hardware-specific issues)
- ILA/Chipscope (requires re-synthesis, eats resources, slows iterations)
- Printf debugging (doesn't exist in hardware!)

**Solution**: Generic "observer" module that maps ANY state machine to oscilloscope-friendly voltage levels with semantic meaning.

**Core Principle**: "If we can see it on the oscilloscope, we can debug it in real-time on hardware."

---

## 2. Design Goals

### 2.1 Non-Invasive
- Existing FSM code **unchanged**
- Observer watches state signal (parallel connection)
- No impact on FSM timing or behavior
- Can be added/removed without modifying FSM

### 2.2 Semantic Voltage Encoding
**Key Innovation**: Use voltage **polarity** to indicate system health

```
Positive voltages = Normal state progression (increasing stairstep)
    +0.5V → +1.0V → +1.5V → +2.0V → +2.5V

Zero voltage = IDLE/RESET state (ground reference)
    0.0V

Negative voltages = FAULT/ERROR states (immediate visual indicator)
    -0.5V, -1.0V, -1.5V, -2.0V

Benefits:
✅ Instant visual on oscilloscope (waveform goes negative = fault!)
✅ Simple trigger: "voltage < 0" catches ANY error
✅ Sign bit = hardware-level indication
✅ Semantic encoding: voltage direction = system health
```

### 2.3 Human-Readable Labels
- State names (not just numbers): "IDLE", "LOADING", "READY", "ERROR"
- Auto-generated oscilloscope trigger table
- Voltage → state name decoder (Python helper)

### 2.4 Configurable Voltage Spacing
- **Voltage guard bands** (2-3 bit left shift)
- Creates ~3-4× voltage margin between states
- Robust to ADC/DAC quantization noise
- Example: State differs by 4mV, not 0.8mV

### 2.5 Reusable Across Projects
- Generic VHDL entity (works with any FSM encoding)
- Configuration package or generics
- Drop-in pattern for any module

---

## 3. Reference Implementations

### 3.1 Inspiration: `EMFI_Seq_stair.vhd`

**Location**: `modules/EMFI-Seq/core/EMFI_Seq_stair.vhd`

**Pattern**:
```vhdl
-- One-hot state → voltage staircase
entity onehot_analog_monitor is
    port (
        state_oh    : in  std_logic_vector(3 downto 0);  -- One-hot FSM state
        level_s1    : in  signed(15 downto 0);           -- Configurable voltages
        level_s2    : in  signed(15 downto 0);
        level_s3    : in  signed(15 downto 0);
        level_s4    : in  signed(15 downto 0);
        dac_out_s16 : out signed(15 downto 0)            -- Oscilloscope output
    );
end entity;

-- Combinational MUX (no clock, minimal complexity)
with state_oh select
    dac_out_s16 <= level_s1 when "0001",
                   level_s2 when "0010",
                   level_s3 when "0100",
                   level_s4 when "1000",
                   CODE_Z   when others;  -- Failsafe
```

**Lessons**:
- ✅ Runtime-configurable voltages (via Control registers)
- ✅ Combinational (no clock, no timing issues)
- ✅ Failsafe for invalid states (0.0V)
- ✅ Uses `Moku_Voltage_pkg` for accurate voltage conversion
- ❌ Limited to one-hot encoding (need generic solution)
- ❌ No negative voltage encoding for faults

### 3.2 Inspiration: `debug_mux.vhd`

**Location**: `modules/inspectable_buffer_loader/core/debug_mux.vhd`

**Pattern**:
```vhdl
-- 8 selectable debug views per output channel
entity debug_mux is
    port (
        debug_select : in  std_logic_vector(2 downto 0);  -- View selection (0-7)
        -- Status signals
        state        : in  std_logic_vector(2 downto 0);
        fault        : in  std_logic;
        valid        : in  std_logic;
        addr         : in  unsigned(10 downto 0);
        -- Output
        debug_out    : out signed(15 downto 0)
    );
end entity;

-- View 0: Status Summary with voltage guard bands
when VIEW_STATUS_SUMMARY =>
    debug_out <= state_scaled & fault_scaled & valid_scaled & addr_scaled;
    -- Left-shifted for voltage spacing (2-3 bits)
```

**Lessons**:
- ✅ Multiple debug views (8 selectable perspectives)
- ✅ Voltage guard bands (2-3 bit left shift)
- ✅ Combinational MUX (simple, predictable)
- ✅ Composite views (combine multiple signals)
- ❌ Hardcoded for specific module (need generic abstraction)

---

## 4. Generic FSM Observer Design

### 4.1 Core Entity

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Moku_Voltage_pkg.all;

entity fsm_observer is
    generic (
        STATE_COUNT    : positive := 8;    -- Number of states in FSM
        STATE_WIDTH    : positive := 3;    -- Bits for state encoding
        USE_NEGATIVE   : boolean  := true  -- Enable negative voltages for faults
    );
    port (
        -- Input: Current FSM state
        state_vector   : in  std_logic_vector(STATE_WIDTH-1 downto 0);

        -- Optional: Fault indicator (maps to negative voltage if enabled)
        fault_flag     : in  std_logic := '0';

        -- Configuration: Voltage levels per state (runtime or compile-time)
        -- Option A: Compile-time via package
        -- Option B: Runtime via input ports (like EMFI_Seq_stair)

        -- Output: Oscilloscope voltage
        voltage_out    : out signed(15 downto 0)
    );
end entity fsm_observer;
```

### 4.2 Configuration Approaches

#### Option A: Compile-Time Package (Recommended for simplicity)

```vhdl
-- fsm_config_pkg.vhd
package fsm_config_pkg is
    -- State name constants (for documentation/trigger table generation)
    constant STATE_IDLE      : natural := 0;
    constant STATE_LOADING   : natural := 1;
    constant STATE_WRITING   : natural := 2;
    constant STATE_VALIDATING: natural := 3;
    constant STATE_READY     : natural := 4;
    constant STATE_RUNNING   : natural := 5;
    constant STATE_ERROR     : natural := 6;  -- Negative voltage!
    constant STATE_FAULT     : natural := 7;  -- Negative voltage!

    -- Voltage assignments (using Moku_Voltage_pkg)
    type state_voltage_map is array (natural range <>) of signed(15 downto 0);

    constant MY_FSM_VOLTAGES : state_voltage_map(0 to 7) := (
        STATE_IDLE       => voltage_to_digital(0.0),    -- Ground reference
        STATE_LOADING    => voltage_to_digital(0.5),    -- First action
        STATE_WRITING    => voltage_to_digital(1.0),    -- Active work
        STATE_VALIDATING => voltage_to_digital(1.5),    -- Verification
        STATE_READY      => voltage_to_digital(2.0),    -- Success
        STATE_RUNNING    => voltage_to_digital(2.5),    -- Operational
        STATE_ERROR      => voltage_to_digital(-0.5),   -- ⚠️ FAULT (negative!)
        STATE_FAULT      => voltage_to_digital(-1.0)    -- ⚠️ CRITICAL (negative!)
    );

    -- Human-readable names (for Python trigger table generation)
    type state_name_array is array (natural range <>) of string(1 to 16);
    constant MY_FSM_NAMES : state_name_array(0 to 7) := (
        STATE_IDLE       => "IDLE            ",
        STATE_LOADING    => "LOADING         ",
        STATE_WRITING    => "WRITING         ",
        STATE_VALIDATING => "VALIDATING      ",
        STATE_READY      => "READY           ",
        STATE_RUNNING    => "RUNNING         ",
        STATE_ERROR      => "ERROR           ",
        STATE_FAULT      => "FAULT           "
    );
end package;
```

**Benefits**:
- ✅ Compile-time type checking (wrong state number = compile error)
- ✅ Human-readable names in one place
- ✅ Python script can parse package for auto-generation
- ❌ Requires recompilation to change voltages

#### Option B: Runtime Configuration (More flexible)

```vhdl
-- Like EMFI_Seq_stair.vhd: voltage levels as input ports
entity fsm_observer_runtime is
    generic (
        STATE_COUNT : positive := 8
    );
    port (
        state_vector : in  std_logic_vector(2 downto 0);

        -- Runtime-configurable voltages (from MCC Control registers)
        level_0      : in  signed(15 downto 0);
        level_1      : in  signed(15 downto 0);
        level_2      : in  signed(15 downto 0);
        level_3      : in  signed(15 downto 0);
        level_4      : in  signed(15 downto 0);
        level_5      : in  signed(15 downto 0);
        level_6      : in  signed(15 downto 0);
        level_7      : in  signed(15 downto 0);

        voltage_out  : out signed(15 downto 0)
    );
end entity;
```

**Benefits**:
- ✅ Change voltages without recompilation
- ✅ Experiment with spacing on hardware
- ❌ More Control register bits consumed
- ❌ Requires Python code to set voltages

### 4.3 Voltage Encoding Strategy

**Positive Voltage Stairstep** (normal states):
```
IDLE       =  0.0V  (ground reference)
LOADING    = +0.5V  (0.5V steps)
WRITING    = +1.0V
VALIDATING = +1.5V
READY      = +2.0V
RUNNING    = +2.5V

Guard Band: 0.1V margin (±0.05V)
Trigger: 0.45V < voltage < 0.55V → "LOADING"
```

**Negative Voltage Faults** (error states):
```
ERROR      = -0.5V  (first error level)
FAULT      = -1.0V  (critical error)
CRITICAL   = -1.5V  (system failure)

Guard Band: 0.1V margin
Trigger: voltage < 0 → "ANY FAULT"
```

**Why This Works**:
- Oscilloscope waveform visually shows progress (stairstep up)
- Negative excursion = instant "something is wrong" indicator
- Sign bit (MSB) = hardware-level fault detection
- Simple mental model: "up = good, down = bad"

### 4.4 Guard Band Implementation

```vhdl
-- Voltage guard band: left-shift by 2-3 bits
-- Creates 4× voltage spacing (3.2mV vs 0.8mV)

architecture rtl of fsm_observer is
    constant GUARD_BITS : natural := 2;  -- Left-shift by 2 bits (×4 spacing)

    signal state_int : integer range 0 to STATE_COUNT-1;
    signal voltage_raw : signed(15 downto 0);
begin
    state_int <= to_integer(unsigned(state_vector));

    -- Lookup voltage (from package or input ports)
    voltage_raw <= MY_FSM_VOLTAGES(state_int);

    -- Apply guard band (optional - voltages may already include guard band)
    -- voltage_out <= shift_left(voltage_raw, GUARD_BITS);

    voltage_out <= voltage_raw;  -- If voltages pre-shifted in package
end architecture;
```

---

## 5. Auto-Generated Trigger Table

### 5.1 Python Generator Script

```python
#!/usr/bin/env python3
"""
Generate oscilloscope trigger table from VHDL FSM configuration package.

Usage:
    python generate_fsm_triggers.py modules/my_module/common/fsm_config_pkg.vhd

Outputs:
    - Markdown trigger table (docs/my_module_triggers.md)
    - Python decoder functions (tests/my_module_decoders.py)
    - MokuBench test helpers (tests/test_my_module_triggers.py)
"""

import re
from pathlib import Path

def parse_vhdl_fsm_config(vhdl_file):
    """Extract state names, voltages, and digital codes from VHDL package"""
    with open(vhdl_file, 'r') as f:
        content = f.read()

    # Parse constant STATE_XXX : natural := N;
    states = {}
    for match in re.finditer(r'constant\s+STATE_(\w+)\s*:\s*natural\s*:=\s*(\d+)', content):
        name = match.group(1)
        value = int(match.group(2))
        states[value] = name

    # Parse voltage assignments
    voltages = {}
    for match in re.finditer(r'STATE_(\w+)\s*=>\s*voltage_to_digital\(([-\d.]+)\)', content):
        name = match.group(1)
        voltage = float(match.group(2))
        voltages[name] = voltage

    return states, voltages

def generate_markdown_table(states, voltages):
    """Generate Markdown oscilloscope trigger reference table"""

    lines = []
    lines.append("# FSM Oscilloscope Trigger Table")
    lines.append("")
    lines.append("| State | Voltage | Digital Code | Trigger Range | Notes |")
    lines.append("|-------|---------|--------------|---------------|-------|")

    for state_num in sorted(states.keys()):
        state_name = states[state_num]
        voltage = voltages.get(state_name, 0.0)
        digital = int((voltage / 5.0) * 32768)  # Moku ±5V scale

        # Trigger range: ±0.05V margin
        trigger_min = voltage - 0.05
        trigger_max = voltage + 0.05

        # Fault indicator
        notes = "**FAULT**" if voltage < 0 else ""

        lines.append(f"| {state_name:12} | {voltage:+5.1f}V | 0x{digital:04X} | "
                    f"{trigger_min:+4.2f}V to {trigger_max:+4.2f}V | {notes} |")

    return "\n".join(lines)

def generate_python_decoder(states, voltages):
    """Generate Python voltage → state name decoder"""

    code = []
    code.append("def decode_fsm_state(voltage: float) -> str:")
    code.append('    """Decode oscilloscope voltage to FSM state name"""')
    code.append("")

    for state_num in sorted(states.keys()):
        state_name = states[state_num]
        voltage = voltages.get(state_name, 0.0)
        margin = 0.1

        code.append(f"    if {voltage - margin:.2f} <= voltage <= {voltage + margin:.2f}:")
        code.append(f'        return "{state_name}"')

    code.append('    return "UNKNOWN"')

    return "\n".join(code)

# Example output:
"""
| State        | Voltage | Digital Code | Trigger Range         | Notes      |
|--------------|---------|--------------|----------------------|------------|
| IDLE         |  +0.0V  | 0x0000       | -0.05V to +0.05V     |            |
| LOADING      |  +0.5V  | 0x199A       | +0.45V to +0.55V     |            |
| WRITING      |  +1.0V  | 0x3333       | +0.95V to +1.05V     |            |
| READY        |  +2.0V  | 0x6666       | +1.95V to +2.05V     |            |
| ERROR        |  -0.5V  | 0xE666       | -0.55V to -0.45V     | **FAULT**  |
"""
```

### 5.2 MokuBench Test Helpers

```python
# Auto-generated from FSM configuration
def voltage_to_state(voltage: float) -> dict:
    """Convert oscilloscope voltage to FSM state info"""

    # Moku ±5V scale
    digital = int((voltage / 5.0) * 32768)

    # Decode state
    state_name = decode_fsm_state(voltage)
    is_fault = voltage < 0

    return {
        'voltage': voltage,
        'digital': digital,
        'state_name': state_name,
        'is_fault': is_fault
    }

# Usage in hardware tests:
data = osc.get_data()
voltage = data['ch1'][len(data['ch1']) // 2]
state = voltage_to_state(voltage)
print(f"FSM State: {state['state_name']} ({state['voltage']:+.2f}V)")
if state['is_fault']:
    print("⚠️  FAULT DETECTED!")
```

---

## 6. Integration Pattern

### 6.1 Existing FSM (Unchanged)

```vhdl
-- Your existing state machine (no modifications!)
entity my_module_core is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        -- ... ports ...
    );
end entity;

architecture rtl of my_module_core is
    -- State machine encoding (any style)
    signal state : std_logic_vector(2 downto 0);

    constant STATE_IDLE   : std_logic_vector(2 downto 0) := "000";
    constant STATE_ACTIVE : std_logic_vector(2 downto 0) := "001";
    -- ... more states ...
begin
    -- Normal FSM logic (unchanged)
    process(clk, reset)
    begin
        if reset = '1' then
            state <= STATE_IDLE;
        elsif rising_edge(clk) then
            case state is
                when STATE_IDLE   => -- ...
                when STATE_ACTIVE => -- ...
                -- ...
            end case;
        end if;
    end process;
end architecture;
```

### 6.2 Top-Level Integration (Observer Added)

```vhdl
-- Top.vhd (CustomWrapper architecture for MCC)
architecture my_module of CustomWrapper is
    -- Signals
    signal state_vector : std_logic_vector(2 downto 0);
    signal fault_flag   : std_logic;
begin
    -- Instantiate existing core (unchanged)
    CORE_INST : entity work.my_module_core
        port map (
            clk    => Clk,
            reset  => Reset,
            -- ... other ports ...

            -- Export state for observer (NEW)
            state_out => state_vector
        );

    -- Instantiate FSM observer (NEW)
    FSM_OBSERVER : entity work.fsm_observer
        generic map (
            STATE_COUNT => 8,
            STATE_WIDTH => 3
        )
        port map (
            state_vector => state_vector,
            fault_flag   => fault_flag,
            voltage_out  => OutputB  -- Dedicated debug channel
        );

    -- OutputA = normal function (waveform, data, etc.)
    -- OutputB = FSM observer (debug channel)
end architecture;
```

---

## 7. Design Patterns

### 7.1 Pattern: Compile-Time Configuration

**Use When**:
- FSM states are fixed (not runtime-configurable)
- Want type safety and compile-time checks
- Python tools will generate trigger tables

**Files**:
```
modules/my_module/
├── common/
│   └── my_module_fsm_pkg.vhd    (state definitions + voltages)
├── core/
│   └── my_module_core.vhd       (FSM implementation)
└── top/
    └── Top.vhd                   (instantiate core + observer)

volo_common/
└── observer/
    └── fsm_observer.vhd          (generic observer entity)

docs/
└── my_module_fsm_triggers.md    (auto-generated trigger table)

tests/
└── my_module_decoders.py        (auto-generated Python helpers)
```

### 7.2 Pattern: Runtime Configuration

**Use When**:
- Want to experiment with voltage spacing on hardware
- FSM states change dynamically
- Educational/teaching modules (students adjust voltages)

**Files**:
```
modules/my_module/
├── core/
│   └── my_module_core.vhd
└── top/
    └── Top.vhd                   (map Control registers to observer)

-- In Top.vhd:
FSM_OBSERVER : entity work.fsm_observer_runtime
    port map (
        state_vector => state,
        level_0      => signed(Control3(31 downto 16)),  -- IDLE voltage
        level_1      => signed(Control3(15 downto 0)),   -- LOADING voltage
        level_2      => signed(Control4(31 downto 16)),  -- WRITING voltage
        -- ...
        voltage_out  => OutputB
    );
```

---

## 8. Success Criteria

### 8.1 Observer Module
- [ ] Generic entity compiles with GHDL (VHDL-2008)
- [ ] Works with binary, one-hot, and gray-code FSM encodings
- [ ] Negative voltage encoding for faults works
- [ ] Voltage guard bands implemented (configurable)
- [ ] Combinational (no clock, no timing issues)

### 8.2 Configuration
- [ ] Package-based configuration option (compile-time)
- [ ] Runtime configuration option (input ports)
- [ ] Human-readable state names defined
- [ ] Voltage assignments use Moku_Voltage_pkg

### 8.3 Auto-Generation
- [ ] Python script parses VHDL package
- [ ] Generates Markdown trigger table
- [ ] Generates Python decoder functions
- [ ] Generates MokuBench test helpers

### 8.4 Integration
- [ ] Drop-in pattern (existing FSM unchanged)
- [ ] State signal exported from core
- [ ] Observer instantiated in Top.vhd
- [ ] OutputB dedicated to debug (OutputA = function)

### 8.5 Hardware Validation
- [ ] Oscilloscope shows distinct voltage levels
- [ ] Positive voltages = normal progression (stairstep)
- [ ] Negative voltages = faults (instant visual)
- [ ] Voltage guard bands prevent noise corruption
- [ ] Trigger table matches observed voltages

---

## 9. Open Questions

1. **One-Hot FSM Support**: Should observer auto-detect one-hot encoding?
2. **Multi-State Faults**: How to encode different fault types in negative range?
3. **Voltage Overlap**: What if FSM has >10 states (voltage range limited)?
4. **Dynamic State Count**: Support FSMs with variable state count?
5. **Gray Code**: Special handling for gray-code FSMs?

---

## 10. References

### 10.1 Existing Code
- **modules/EMFI-Seq/core/EMFI_Seq_stair.vhd** - One-hot → voltage pattern
- **modules/inspectable_buffer_loader/core/debug_mux.vhd** - Multi-view debug
- **modules/volo_common/common/Moku_Voltage_pkg.vhd** - Voltage conversion

### 10.2 Documentation
- **docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md** - Complete debugging methodology
- **Serena memory: oscilloscope_debugging_techniques** - AI context
- **.claude/commands/debug-hardware.md** - Slash command
- **AGENTS.md** - Workflow quick reference

### 10.3 Example Workflow
- **inspectable_buffer_loader** (2025-10-24) - 6/6 CocotB tests, 4/5 hardware tests passed
- Git commits: `c6136b8` (voltage scaling), `12410bf` (polling), `d718da2` (state paths)

---

## 11. Next Steps

### Phase 1: Design Document (This Document)
- ✅ Capture requirements and goals
- ✅ Define voltage encoding strategy
- ✅ Sketch entity interfaces
- ✅ Plan auto-generation scripts
- ⏳ Review with user (get feedback)

### Phase 2: Implementation
- [ ] Create generic `fsm_observer.vhd` entity
- [ ] Create example FSM configuration package
- [ ] Write Python trigger table generator
- [ ] Write Python decoder helper functions

### Phase 3: Validation
- [ ] CocotB simulation tests (prove pattern works)
- [ ] Apply to existing module (e.g., buffer_loader)
- [ ] Hardware test on Moku (verify voltage encoding)
- [ ] Measure guard band effectiveness

### Phase 4: Documentation & Templates
- [ ] Create "inspectable FSM" template module
- [ ] Write integration guide (step-by-step)
- [ ] Update AGENTS.md with pattern reference
- [ ] Add Serena memory for pattern

---

**END OF REQUIREMENTS DOCUMENT**

---

## Appendix A: Voltage Encoding Example

```
Oscilloscope View (OutputB = FSM Observer):

    2.5V ──────────────  RUNNING (system operational)
    2.0V ─────────   READY (buffer loaded, waiting)
    1.5V ────────  VALIDATING (checking CRC)
    1.0V ───────  WRITING (chunk being written)
    0.5V ──────  LOADING (first chunk received)
    0.0V ─────  IDLE (ground reference)
   -0.5V ──  ERROR (checksum mismatch) ⚠️
   -1.0V ─  FAULT (buffer overflow) ⚠️

Visual pattern:
- Stairstep UP = normal state progression
- Voltage DROP to negative = immediate fault indication
- Sign bit (MSB) = hardware-level error flag
```

## Appendix B: Trigger Setup (Oscilloscope)

```python
# MokuBench example
osc.set_trigger(
    type='Edge',
    source=2,        # Channel 2 (OutputB = FSM observer)
    edge='Rising',
    level=0.75       # Trigger at LOADING state (0.5V + margin)
)

# Capture state transitions:
# Trigger fires when FSM enters LOADING state
# Waveform shows progression: IDLE → LOADING → WRITING → ...

# Fault detection:
osc.set_trigger(
    type='Edge',
    source=2,
    edge='Falling',
    level=-0.1       # Trigger when voltage goes negative (fault!)
)

# Captures exact moment of fault:
# Waveform shows: ... → READY → ERROR (negative excursion)
```

---

**Review Notes**:
- This document focuses on **generic pattern**, not specific protocols
- Emphasizes **semantic voltage encoding** (positive/negative)
- Includes **auto-generation** strategy (trigger tables, decoders)
- Provides **integration examples** (non-invasive)
- Ready for **new window** design work (minimal context needed)

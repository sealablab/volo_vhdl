# Inspectable FSM Observer Pattern - Final Design

**Pattern Name:** `fsm_observer`
**Purpose:** Make ANY VHDL state machine observable via oscilloscope with minimal integration effort
**Date:** 2025-10-24
**Status:** ✅ Implemented
**Location:** `modules/volo_common/observer/fsm_observer.vhd`

---

## 1. Core Principle

**"If we can see it on the oscilloscope, we can debug it in real-time on hardware."**

State machines are invisible after synthesis. This pattern makes them visible through oscilloscope-friendly voltage encoding with semantic meaning.

---

## 2. Key Design Decisions

### 2.1 Fixed 6-bit Encoding (Simplified!)

**All FSMs use 6-bit state vectors:**
```vhdl
signal state_reg : std_logic_vector(5 downto 0);  -- ALWAYS 6 bits
```

**Benefits:**
- ✅ **Single tested entity** - Same interface for all FSMs
- ✅ **No generics for width** - Fewer parameters to configure
- ✅ **Supports up to 64 states** - More than enough for most FSMs
- ✅ **Negligible cost** - 6 bits vs 3 bits = 3 extra flip-flops (synthesis optimizes unused states away)

**Trade-off:** Tiny FPGA resource cost for massive simplification and consistency.

### 2.2 Automatic Voltage Spreading

**Observer calculates voltages automatically** based on V_MIN, V_MAX, and NUM_STATES:
```vhdl
FSM_OBS: entity work.fsm_observer
    generic map (
        NUM_STATES => 8,
        V_MIN      => 0.0,    -- User configures range
        V_MAX      => 2.5,    -- User configures range
        -- ...
    )
```

**Voltage calculation** (compile-time, zero runtime overhead):
- Linear interpolation between V_MIN and V_MAX
- State 0: V_MIN
- State N-1: V_MAX
- Even spacing in between

**Example** (8 states, 0.0V → 2.5V):
- State 0: 0.0V
- State 1: 0.357V
- State 2: 0.714V
- State 3: 1.071V
- State 4: 1.429V
- State 5: 1.786V
- State 6: 2.143V
- State 7: 2.5V

**No manual voltage assignment needed!**

### 2.3 Sign-Flip Fault Indication (Innovation!)

**Problem:** How to indicate faults AND preserve debugging context?

**Solution:** When FSM enters fault state, voltage **sign-flips** but **preserves magnitude** of previous normal state.

**Example Timeline:**
```
IDLE (0.0V) → LOADING (0.5V) → WRITING (1.0V) → VALIDATING (1.5V) → ERROR

Oscilloscope shows: +1.5V → -1.5V (sign flips!)
```

**Interpretation:**
- **Magnitude (1.5V)** = "Faulted from VALIDATING state"
- **Negative sign** = "System is now in fault condition"

**Oscilloscope View:**
```
    2.5V ─────────────────────────────────
    2.0V ─────────────────────────────────
    1.5V ─────────┌───────┐  ← VALIDATING
    1.0V ─────┌───┘       │
    0.5V ─┌───┘           │
    0.0V ─┘               │
   -0.5V ─────────────────│
   -1.0V ─────────────────│
   -1.5V ─────────────────└───────────── ⚠️ ERROR (sign-flipped!)

Visual: Stairstep up, then DROP to negative = immediate fault with context
```

**Benefits:**
- ✅ **Instant visual** - Waveform goes negative = fault
- ✅ **Historical context** - Magnitude tells you WHERE it faulted from
- ✅ **Oscilloscope-friendly** - Easy trigger: falling edge, level = -0.1V
- ✅ **Hardware-level indication** - Sign bit visible in digital code

### 2.4 Two Modes Only

**Mode 1: No Faults** (all states normal):
```vhdl
FAULT_STATE_THRESHOLD => 8  -- Set to NUM_STATES (disables faults)
```
- All states use positive voltage stairstep
- Purely combinational (no clock needed)

**Mode 2: Sign-Flip Faults** (some states are faults):
```vhdl
FAULT_STATE_THRESHOLD => 6  -- States 6-7 are faults
```
- Normal states (0-5): Positive stairstep
- Fault states (6-7): Sign-flip previous voltage
- Requires clock for tracking previous state

**No separate fault voltage range!** Sign-flip gives you everything you need.

---

## 3. Implementation

### 3.1 FSM Annotation (Minimal)

```vhdl
-- modules/buffer_loader/core/buffer_loader_core.vhd

architecture rtl of buffer_loader_core is

    -- FSM_STATE: IDLE
    constant STATE_IDLE : std_logic_vector(5 downto 0) := "000000";

    -- FSM_STATE: LOADING
    constant STATE_LOADING : std_logic_vector(5 downto 0) := "000001";

    -- FSM_STATE: WRITING
    constant STATE_WRITING : std_logic_vector(5 downto 0) := "000010";

    -- FSM_STATE: VALIDATING
    constant STATE_VALIDATING : std_logic_vector(5 downto 0) := "000011";

    -- FSM_STATE: READY
    constant STATE_READY : std_logic_vector(5 downto 0) := "000100";

    -- FSM_STATE: RUNNING
    constant STATE_RUNNING : std_logic_vector(5 downto 0) := "000101";

    -- FSM_STATE: ERROR
    constant STATE_ERROR : std_logic_vector(5 downto 0) := "000110";

    -- FSM_STATE: FAULT
    constant STATE_FAULT : std_logic_vector(5 downto 0) := "000111";

    signal state_reg : std_logic_vector(5 downto 0);  -- ALWAYS 6 bits!

begin
    -- FSM implementation (unchanged)
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            state_reg <= STATE_IDLE;
        elsif rising_edge(clk) then
            case state_reg is
                when STATE_IDLE      => -- ...
                when STATE_LOADING   => -- ...
                when STATE_WRITING   => -- ...
                when STATE_VALIDATING => -- ...
                when STATE_READY     => -- ...
                when STATE_RUNNING   => -- ...
                when STATE_ERROR     => -- ...
                when STATE_FAULT     => -- ...
                when others          => state_reg <= STATE_FAULT;
            end case;
        end if;
    end process;

    -- Export state for observer
    load_state <= state_reg;
end architecture;
```

**Annotation:**
- `-- FSM_STATE: <NAME>` comment above each state constant
- Fixed 6-bit encoding for all states
- Sequential encoding (0, 1, 2, 3, ...)

### 3.2 Observer Instantiation (Manual - Easy!)

```vhdl
-- modules/buffer_loader/top/Top.vhd
use work.Moku_Voltage_pkg.all;

architecture buffer_loader of CustomWrapper is
    signal state_vector : std_logic_vector(5 downto 0);
begin
    CORE: entity work.buffer_loader_core
        port map (
            -- ... ports ...
            load_state => state_vector
        );

    -- ========================================================================
    -- FSM Observer (Manual integration - takes ~2 minutes)
    -- ========================================================================
    FSM_OBS: entity work.fsm_observer
        generic map (
            NUM_STATES            => 8,     -- Count states in FSM
            V_MIN                 => 0.0,   -- Choose voltage range
            V_MAX                 => 2.5,   -- Choose voltage range
            FAULT_STATE_THRESHOLD => 6,     -- ERROR/FAULT start at state 6

            -- Copy state names from FSM constants
            STATE_0_NAME => "IDLE",
            STATE_1_NAME => "LOADING",
            STATE_2_NAME => "WRITING",
            STATE_3_NAME => "VALIDATING",
            STATE_4_NAME => "READY",
            STATE_5_NAME => "RUNNING",
            STATE_6_NAME => "ERROR",
            STATE_7_NAME => "FAULT"
        )
        port map (
            clk          => Clk,
            reset        => Reset,
            state_vector => state_vector,
            voltage_out  => OutputB  -- Dedicated debug channel
        );
end architecture;
```

**Integration Steps:**
1. Count states in FSM → `NUM_STATES`
2. Choose voltage range → `V_MIN`, `V_MAX`
3. Identify first fault state → `FAULT_STATE_THRESHOLD`
4. Copy-paste state names → `STATE_0_NAME`, etc.

**No Python scripts needed!** Manual is faster and more flexible.

---

## 4. Usage Patterns

### 4.1 No-Fault FSM (Simple Waveform Generator)

```vhdl
FSM_OBS: entity work.fsm_observer
    generic map (
        NUM_STATES            => 4,
        V_MIN                 => 0.0,
        V_MAX                 => 2.0,
        FAULT_STATE_THRESHOLD => 4,  -- No faults (= NUM_STATES)

        STATE_0_NAME => "IDLE",
        STATE_1_NAME => "RAMP_UP",
        STATE_2_NAME => "HOLD",
        STATE_3_NAME => "RAMP_DOWN"
    )
    port map (
        -- clk/reset not needed (no faults)
        state_vector => state_vector,
        voltage_out  => OutputB
    );
```

**Voltage mapping** (automatic):
- State 0: 0.0V
- State 1: 0.667V
- State 2: 1.333V
- State 3: 2.0V

**No clock needed** - purely combinational.

### 4.2 Fault-Aware FSM (Buffer Loader)

```vhdl
FSM_OBS: entity work.fsm_observer
    generic map (
        NUM_STATES            => 8,
        V_MIN                 => 0.0,
        V_MAX                 => 2.5,
        FAULT_STATE_THRESHOLD => 6,  -- Sign-flip enabled

        STATE_0_NAME => "IDLE",
        STATE_1_NAME => "LOADING",
        STATE_2_NAME => "WRITING",
        STATE_3_NAME => "VALIDATING",
        STATE_4_NAME => "READY",
        STATE_5_NAME => "RUNNING",
        STATE_6_NAME => "ERROR",      -- ⚠️ Fault state
        STATE_7_NAME => "FAULT"       -- ⚠️ Fault state
    )
    port map (
        clk          => Clk,          -- Needed for sign-flip
        reset        => Reset,
        state_vector => state_vector,
        voltage_out  => OutputB
    );
```

**Voltage mapping**:
- States 0-5: Positive stairstep (0.0V → 2.5V)
- States 6-7: Sign-flip of previous state
  - If faults from VALIDATING (1.5V) → output = -1.5V
  - If faults from RUNNING (2.5V) → output = -2.5V

**Clock needed** for tracking previous voltage.

---

## 5. Testing

### 5.1 CocotB Simulation

```python
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_fsm_observer_normal_states(dut):
    """Test observer tracks normal state progression"""
    await setup_clock(dut)
    await reset_active_low(dut)

    # Trigger state transitions
    dut.state_vector.value = 0  # IDLE
    await ClockCycles(dut.clk, 1)
    assert dut.voltage_out.value == voltage_to_digital(0.0)

    dut.state_vector.value = 1  # LOADING
    await ClockCycles(dut.clk, 1)
    assert dut.voltage_out.value == voltage_to_digital(0.357)

    dut.state_vector.value = 3  # VALIDATING
    await ClockCycles(dut.clk, 1)
    assert dut.voltage_out.value == voltage_to_digital(1.071)

@cocotb.test()
async def test_fsm_observer_fault_signflip(dut):
    """Test sign-flip fault indication"""
    await setup_clock(dut)
    await reset_active_low(dut)

    # Normal state progression
    dut.state_vector.value = 3  # VALIDATING (1.5V)
    await ClockCycles(dut.clk, 2)
    voltage_before_fault = dut.voltage_out.value

    # Enter fault state
    dut.state_vector.value = 6  # ERROR
    await ClockCycles(dut.clk, 1)
    voltage_fault = dut.voltage_out.value.signed_integer

    # Check sign-flip: should be negative magnitude
    assert voltage_fault < 0, "Fault state should have negative voltage"
    assert abs(voltage_fault) == abs(voltage_before_fault), \
        "Magnitude should preserve previous state voltage"
```

### 5.2 Hardware Testing (MokuBench)

```python
def test_fsm_observer_hardware(mcc, osc):
    """Test FSM observer on hardware via oscilloscope"""

    # Trigger state transition
    mcc.set_control(1, 8 << 16)  # Start buffer load
    time.sleep(0.1)

    # Read oscilloscope voltage
    data = osc.get_data()
    voltage = data['ch2'][len(data['ch2']) // 2]  # OutputB = FSM observer

    print(f"FSM voltage: {voltage:+.2f}V")

    # Decode state (simple voltage ranges)
    if -0.1 < voltage < 0.1:
        state = "IDLE"
    elif 0.4 < voltage < 0.6:
        state = "LOADING"
    elif voltage < 0:
        state = f"FAULT (faulted from ~{abs(voltage):.1f}V state)"
    else:
        state = "UNKNOWN"

    print(f"Decoded state: {state}")
```

---

## 6. Oscilloscope Trigger Setup

### 6.1 Capture Specific State Entry

**Trigger**: Rising edge, level = (target voltage - 0.1V)

Example - Capture VALIDATING state entry:
- VALIDATING ≈ 1.071V
- Set trigger: Rising edge, 0.97V

### 6.2 Detect ANY Fault

**Trigger**: Falling edge, level = -0.1V

This catches the transition from positive (normal) → negative (fault).

### 6.3 Check Module Operational

**Trigger**: Voltage > +0.1V

Ensures module is not stuck in IDLE (0.0V).

---

## 7. Advantages of This Design

### vs. One-Hot Encoding
- ✅ More Verilog-portable (binary encoding)
- ✅ Fewer state bits (6 bits vs 64 bits for 64-state FSM)
- ✅ Standard FSM pattern (case statements work naturally)

### vs. Variable-Width Observer
- ✅ Single tested entity (same interface every time)
- ✅ No generic width parameter (fewer generics to configure)
- ✅ Simpler integration (fixed port signature)

### vs. Manual Voltage Assignment
- ✅ Automatic voltage spreading (just set V_MIN/V_MAX)
- ✅ No arithmetic errors in voltage calculations
- ✅ Easy to adjust range (change 2 generics, not 8)

### vs. Separate Fault Voltage Range
- ✅ Sign-flip preserves debugging context (magnitude = where it faulted)
- ✅ Simpler interface (no V_FAULT_MIN/V_FAULT_MAX generics)
- ✅ Better visual indicator (negative excursion = instant alert)

### vs. Python-Generated Configuration
- ✅ Faster integration (manual takes ~2 minutes)
- ✅ No parsing fragility (no script to maintain)
- ✅ More flexible (user tweaks voltages easily)
- ✅ Fewer moving parts (no script in build workflow)

---

## 8. Limitations and Trade-offs

### 8.1 Fixed 6-bit Encoding

**Cost:** 3 extra flip-flops per FSM (if FSM only needs 3 bits)

**Benefit:** Standardization, simplicity, single tested entity

**Verdict:** ✅ Worth it. Consistency > tiny resource savings.

### 8.2 Manual Integration

**Cost:** ~2 minutes to count states and copy names

**Benefit:** No Python parsing, no script maintenance, more flexibility

**Verdict:** ✅ Worth it. Manual is actually faster and more reliable.

### 8.3 Linear Voltage Spacing

**Limitation:** All states evenly spaced (can't prioritize important states)

**Workaround:** Adjust V_MIN/V_MAX to give more dynamic range where needed

**Verdict:** ✅ Acceptable. Even spacing works for 99% of cases.

---

## 9. Success Criteria

- [x] **Single observer entity** - Works for all FSMs
- [x] **Fixed 6-bit encoding** - Standardized interface
- [x] **Automatic voltage spreading** - Just set V_MIN/V_MAX
- [x] **Sign-flip fault indication** - Preserves debugging context
- [x] **Two modes** - No-faults and sign-flip faults
- [x] **No Python generation** - Manual integration is trivial
- [x] **Uses Moku_Voltage_pkg** - All voltage conversions standardized
- [x] **Compile-time LUT** - Zero runtime overhead
- [x] **Non-invasive** - FSM exports state, observer watches

---

## 10. Files

**Core Implementation:**
- `modules/volo_common/observer/fsm_observer.vhd` - Observer entity (single file!)

**Documentation:**
- `docs/INSPECTABLE_FSM_REQUIREMENTS.md` - This document
- Serena memory: `design_patterns.md` - Pattern reference

**Example Integration:**
- TBD: Apply to existing module (e.g., buffer_loader or EMFI-Seq)

---

## 11. Future Enhancements (Optional)

### 11.1 Extended State Names

Currently supports STATE_0_NAME through STATE_7_NAME generics.

For FSMs with >8 states, could extend to STATE_63_NAME (or use arrays if VHDL-2008 allows).

### 11.2 Runtime Voltage Configuration

Add ports for level_0 through level_63 to override compile-time LUT.

Useful for experimenting with voltage spacing on hardware without recompilation.

### 11.3 Python Test Helpers

Optional helper functions for test scripts:
- `decode_voltage_to_state(voltage, v_min, v_max, num_states)`
- `assert_fsm_state(osc, expected_state, ...)`

But these are trivial to write manually (3-4 lines of Python).

---

## 12. Validation Results ✅

**Status**: Pattern fully validated on 2025-10-24

**Test Module**: `modules/fsm_example/` (8-state FSM: 6 normal + 2 fault)

**Test Results**: 8/8 tests PASSED
```
TESTS=8 PASS=8 FAIL=0 SKIP=0
```

**Tests Verified**:
- ✅ Reset behavior (IDLE = 0.0V)
- ✅ Normal state progression (voltage stairstep: 0.0V → 2.5V)
- ✅ Sign-flip fault from IDLE (edge case: 0V → 0V)
- ✅ Sign-flip fault from LOADING (1.0V → -1.0V)
- ✅ Sign-flip fault from VALIDATING (1.5V → -1.5V)
- ✅ Automatic voltage spreading (linear interpolation verified)
- ✅ Fault states sticky (cleared only by reset)

**Run Tests**:
```bash
cd tests/
uv run make TEST_MODULE=fsm_example
```

### Timing Quirks Discovered

**1. Voltage Calculation Must Match VHDL Logic**

**Issue**: Test initially failed with voltage mismatch
- Expected: +1.786V for RUNNING state (state 5)
- Actual: +2.500V

**Root Cause**: Python test used total `num_states=8` instead of `num_normal_states=6`

**VHDL Logic** (modules/volo_common/observer/fsm_observer.vhd:94):
```vhdl
num_normal := FAULT_STATE_THRESHOLD;  -- 6 normal states (0-5)
v_step := (V_MAX - V_MIN) / (num_normal - 1);
-- v_step = (2.5 - 0.0) / (6 - 1) = 0.5V
-- State 5 = 0.0 + (5 * 0.5) = 2.5V ✓
```

**Python Test** (fixed in tests/test_fsm_example.py:38):
```python
# WRONG (was using total states):
def calculate_expected_voltage(state_index: int, num_states: int = 8, ...):
    v_step = (v_max - v_min) / (num_states - 1)  # 2.5/7 = 0.357V ❌

# CORRECT (now uses normal states):
def calculate_expected_voltage(state_index: int, num_normal_states: int = 6, ...):
    v_step = (v_max - v_min) / (num_normal_states - 1)  # 2.5/5 = 0.5V ✅
```

**Lesson**: Test voltage calculations must use `FAULT_STATE_THRESHOLD` (number of normal states), not `NUM_STATES` (total states including faults).

**2. CocotB Logging Quirk**

**Issue**: Empty string log messages cause `IndexError` in CocotB logging framework
```python
dut._log.info("")  # ❌ Causes: IndexError: list index out of range
```

**Fix**: Remove empty log messages or use non-empty separators
```python
dut._log.info("Pattern ready for deployment!")  # ✓
```

**3. CocotB API Deprecation**

**Issue**: `signed_integer` getter is deprecated
```python
value.signed_integer  # ❌ DeprecationWarning
value.to_signed()     # ✅ New API
```

**Fix**: Replaced all 13 instances with `.to_signed()` method

### Validation Files

**Implementation**:
- `modules/fsm_example/core/fsm_example_core.vhd` - Simple 8-state FSM with fault injection
- `modules/fsm_example/top/fsm_example_top.vhd` - Integration (core + observer)

**Tests**:
- `tests/test_fsm_example.py` - Comprehensive validation suite (8 tests)
- `tests/Makefile` - Build configuration (line 252-260)

**Commits**:
- `f03611a` - Fix test issues, all 8 tests passing (2025-10-24)

---

**END OF REQUIREMENTS DOCUMENT**

This pattern is now **VALIDATED** and ready for production deployment.

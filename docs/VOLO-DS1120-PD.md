# VOLO-DS1120-PD Requirements Document (v2.0)

**Last Updated**: 2025-01-27
**Status**: Requirements Finalized
**Target**: Riscure DS1120A EMFI Probe Driver as VOLO Application

---

## 1. Executive Summary

The VOLO-DS1120-PD is a VOLO application that provides a safe, configurable driver for the Riscure DS1120A Electromagnetic Fault Injection (EMFI) probe. It implements a one-shot firing mechanism with safety controls, timing management, and probe feedback monitoring.

---

## 2. DS1120A Probe Interface

### 2.1 Physical Inputs (to Probe)

#### `digital_glitch` (Trigger Input)
- **Purpose**: Trigger input to initiate EMFI pulse
- **Threshold**: Fixed at 2.4V (not configurable in hardware)
- **Signal Type**: Digital trigger, rising edge activated

#### `pulse_amplitude` (Intensity Control)
- **Purpose**: Controls EMFI pulse intensity
- **Range**: 0.5V to 3.3V (linear response)
- **Signal Type**: Analog control voltage
- **Safety**: Must never exceed 3.0V regardless of user input

### 2.2 Physical Outputs (from Probe)

#### `probe_monitor` (Current Monitor)
- **Purpose**: Current consumption feedback during pulse
- **Polarity**: Inverted (more negative = more current)
- **Use**: Future enhancement for pulse verification and characterization

---

## 3. VOLO Application Architecture

### 3.1 Module Dependencies

The VOLO-DS1120-PD application utilizes these existing shared modules:

- **`volo_voltage_pkg.vhd`** (`modules/shared/packages/`)
  - Voltage-to-digital conversion utilities
  - 16-bit signed: ±5V full scale, ~305µV resolution

- **`volo_voltage_threshold_trigger_core.vhd`** (`modules/shared/core/`)
  - Configurable threshold trigger detection

- **`volo_clk_divider.vhd`** (`modules/shared/core/`)
  - Clock division for FSM timing control

- **`fsm_observer.vhd`** (`modules/shared/observer/`)
  - FSM state visualization and debugging

- **Reference**: `fsm_example_core.vhd` (`modules/examples/fsm_example/core/`)
  - Observable FSM pattern reference

### 3.2 Implementation Strategy

Use **three FSM observer instances**:
1. Main FSM for state control
2. Observer for TriggerOut control
3. Observer for IntensityOut control
4. Observer for debug output (analog_v_mon_out)

---

## 4. MCC Signal Mapping

### 4.1 Inputs (16-bit signed)
- **InputA** → `TriggerInput` (external trigger signal)
- **InputB** → `MonitorInput` (probe current feedback)

### 4.2 Outputs (16-bit signed)
- **OutputA** → `TriggerOut` (probe trigger control)
- **OutputB** → `IntensityOut` (probe intensity control)

### 4.3 Voltage Scaling (per `volo_voltage_pkg`)
```
Digital Range: -32768 to +32767 (0x8000 to 0x7FFF)
Voltage Range: -5.0V to +5.0V
Key Values:
  0V   = 0x0000 (0)
  2.4V = 0x3DCF (15729)
  3.0V = 0x4CCD (19661)
  3.3V = 0x54EB (21627)
  5.0V = 0x7FFF (32767)
```

---

## 5. FSM State Machine

### 5.1 State Definitions

| State | Code | Description |
|-------|------|-------------|
| READY | 000 | Initial state, waiting for arm command |
| ARMED | 001 | Armed, waiting for trigger |
| FIRING | 010 | Outputs active, probe firing |
| COOLING | 011 | Mandatory cooldown period |
| DONE | 100 | Successfully fired, awaiting reset |
| TIMEDOUT | 101 | Armed timeout expired |
| HARDFAULT | 111 | Error state (future use) |

### 5.2 State Transitions

```
READY → ARMED     (when armed_bit = 1)
ARMED → FIRING    (when trigger detected OR force_fire = 1)
ARMED → TIMEDOUT  (when delay_cnt expires)
FIRING → COOLING  (after firing_cnt cycles)
COOLING → DONE    (after cooling_cnt cycles)
DONE → READY      (when reset_fsm = 1)
TIMEDOUT → READY  (when reset_fsm = 1)
```

### 5.3 Safety Timing Constraints

| State | Duration | Constraint |
|-------|----------|------------|
| READY | Unlimited | N/A |
| ARMED | delay_cnt cycles | Configurable timeout |
| FIRING | MAX(firing_cnt, 32) | Hard limit 32 cycles |
| COOLING | MAX(cooling_cnt, 8) | Minimum 8 cycles |
| DONE | Unlimited | Until reset |

---

## 6. VOLO Register Map

### 6.1 Register Allocation (CR20-CR30)

| CR# | Name | Type | Bits | Description |
|-----|------|------|------|-------------|
| 20 | Armed | BUTTON | [0] | Arm the probe driver |
| 21 | Force Fire | BUTTON | [0] | Manual trigger |
| 22 | Reset FSM | BUTTON | [0] | Reset to READY state |
| 23 | Timing Control | COUNTER_8BIT | [7:0] | Bits [7:4]: clk_div, [3:0]: delay_cnt upper |
| 24 | Delay Lower | COUNTER_8BIT | [7:0] | delay_cnt lower 8 bits (total 12-bit) |
| 25 | Firing Duration | COUNTER_8BIT | [7:0] | Cycles in FIRING state |
| 26 | Cooling Duration | COUNTER_8BIT | [7:0] | Cycles in COOLING state |
| 27 | Trigger Thresh High | COUNTER_8BIT | [7:0] | Trigger threshold [15:8] |
| 28 | Trigger Thresh Low | COUNTER_8BIT | [7:0] | Trigger threshold [7:0] |
| 29 | Intensity High | COUNTER_8BIT | [7:0] | Output intensity [15:8] |
| 30 | Intensity Low | COUNTER_8BIT | [7:0] | Output intensity [7:0] |

### 6.2 16-bit Value Reconstruction

For 16-bit threshold and intensity values:
```vhdl
trig_threshold <= CR27 & CR28;  -- Concatenate high/low bytes
intensity_value <= CR29 & CR30;  -- Concatenate high/low bytes
```

### 6.3 Clock Divider Integration

CR23[7:4] provides 4-bit clock divider selection:
- 0 = No division (FSM runs at system clock)
- 1-15 = Divide by 2^N (FSM runs slower)

---

## 7. Status Register (16-bit)

| Bits | Field | Description |
|------|-------|-------------|
| [15:13] | Current State | 3-bit FSM state encoding |
| [12] | Triggered | Probe was triggered (sticky) |
| [11] | Timed Out | Armed timeout occurred (sticky) |
| [10] | Fire Count Met | Max fires reached (sticky) |
| [9:8] | Reserved | Future use |
| [7:4] | Spurious Count | Spurious triggers (4-bit saturating) |
| [3:0] | FSM Sub-state | Debug information |

---

## 8. Output Signal Behavior

### 8.1 TriggerOut
- **Idle State**: 0x0000 (0V)
- **Firing State**: Value from intensity registers (CR29/CR30)
- **Transition**: Immediate on FSM state change

### 8.2 IntensityOut
- **Idle State**: 0x0000 (0V)
- **Firing State**: Clamped to MAX(user_value, 0x4CCD) [3.0V max]
- **Transition**: Synchronized with TriggerOut

### 8.3 analog_v_mon_out (Debug)
- **Purpose**: FSM state visualization
- **Encoding**: Maps FSM state to voltage levels for scope observation
- **Implementation**: Via fsm_observer instance

---

## 9. Safety Features

### 9.1 Hardware Protection
- Output voltage clamping (3.0V maximum)
- Minimum cooling period enforcement
- Maximum firing duration limit
- Watchdog timer for armed state

### 9.2 Operational Safety
- One-shot operation (requires re-arm)
- Maximum fire count per session (saturating counter)
- Spurious trigger detection and counting
- All-zero safe state (disabled on reset)

### 9.3 Future Enhancements
- Monitor feedback threshold detection
- Pulse verification via current monitoring
- Adaptive cooling based on intensity
- BRAM-based waveform shaping

---

## 10. Deployment Workflow

### 10.1 Bitstream Loading
1. Load VOLO-DS1120-PD bitstream to Moku slot
2. Module appears "stuck" (awaiting VOLO initialization)

### 10.2 VOLO Loader Sequence
1. Execute `volo_loader.py` script
2. Fill 4KB BRAM buffer (unused in v1.0, reserved for future)
3. Set MCC_READY and control bits
4. Transfer control to volo_main

### 10.3 Configuration
1. Set threshold values (CR27-28)
2. Set intensity values (CR29-30)
3. Configure timing (CR23-26)
4. DO NOT set Armed bit yet

### 10.4 Operation
1. External script arms module (CR20 = 1)
2. FSM transitions READY → ARMED
3. Waits for trigger or timeout
4. On trigger: ARMED → FIRING → COOLING → DONE
5. Read status register for results
6. Reset FSM for next shot (CR22 = 1)

---

## 11. Testing Considerations

### 11.1 CocotB Test Coverage
- FSM state transitions
- Timing constraint enforcement
- Threshold trigger detection
- Force-fire functionality
- Spurious trigger counting
- Output voltage clamping
- Watchdog timeout behavior

### 11.2 Hardware Validation
- Oscilloscope verification of output signals
- Probe response measurement
- Timing accuracy validation
- Safety limit testing

---

## 12. Implementation Notes

### 12.1 BRAM Buffer (Reserved)
Current implementation does NOT use the 4KB BRAM buffer. Reserved for:
- Future waveform pattern storage
- Timing sequence tables
- Calibration data
- Multi-shot sequence definitions

### 12.2 Monitor Input Processing
Current implementation samples but does not process MonitorInput. Future:
- Peak detection algorithm
- Integration over firing period
- Threshold comparison for verification
- Fault detection based on unexpected readings

### 12.3 Clock Domain
- FSM runs on divided clock (configurable via CR23[7:4])
- I/O sampling at full system clock rate
- Proper CDC (Clock Domain Crossing) handling required

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-27 | johnycsh | Initial draft |
| 2.0 | 2025-01-27 | Claude | Complete refinement with technical details |

---

## Appendix: Quick Reference

### Key Constants
```vhdl
-- Voltage thresholds
TRIGGER_THRESHOLD_2V4 : signed := x"3DCF";  -- 2.4V
MAX_INTENSITY_3V0     : signed := x"4CCD";  -- 3.0V

-- Timing limits
MAX_FIRING_CYCLES     : natural := 32;
MIN_COOLING_CYCLES    : natural := 8;
MAX_ARM_TIMEOUT       : natural := 4095;  -- 12-bit counter

-- FSM States
STATE_READY    : std_logic_vector(2 downto 0) := "000";
STATE_ARMED    : std_logic_vector(2 downto 0) := "001";
STATE_FIRING   : std_logic_vector(2 downto 0) := "010";
STATE_COOLING  : std_logic_vector(2 downto 0) := "011";
STATE_DONE     : std_logic_vector(2 downto 0) := "100";
STATE_TIMEDOUT : std_logic_vector(2 downto 0) := "101";
STATE_HARDFAULT: std_logic_vector(2 downto 0) := "111";
```

---

**END OF REQUIREMENTS DOCUMENT**
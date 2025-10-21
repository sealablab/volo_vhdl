# TPD Register Map and Integration Guide

## Module Overview

The **TPD (Trivial Probe Driver)** is a complete EMFI (Electromagnetic Fault Injection) pulse driver system consisting of three layers:

```
CustomWrapper (Moku Integration)
    ├─> tpd-med (Wrapper with sticky status & output control)
    │       └─> emfi-fsm (Core FSM)
    └─> Register mapping & trigger logic
```

## Register Map

### Control0 [31:0] - Main Control Register

| Bits    | Field            | Type     | Description                                    |
|---------|------------------|----------|------------------------------------------------|
| 31      | gDisable         | RW       | Global disable (1=disable all outputs)         |
| 30-24   | Reserved         | -        | Reserved for future use                        |
| 23      | SOFT-TRIGGER     | RW       | Software trigger (write 1 to trigger sequence) |
| 22-16   | IntensityLut-Idx | RW       | Intensity LUT index (reserved for future)      |
| 15-12   | Probe_cooldown   | RW       | Cooldown cycles (4-bit, extended to 8-bit)     |
| 11-8    | Probe_fire       | RW       | Firing cycles (4-bit, extended to 8-bit)       |
| 7-0     | Reserved         | -        | Reserved for future use                        |

### Control1 [31:0] - Timing and Level Control

| Bits    | Field            | Type     | Description                                    |
|---------|------------------|----------|------------------------------------------------|
| 31-16   | trig_out_level   | RW       | Trigger output level (signed 16-bit)           |
| 15-8    | Reserved         | -        | Reserved for future use                        |
| 7-0     | delay_cnt        | RW       | Delay cycles (8-bit unsigned)                  |

**Note**: Currently, both `trig_out_level` and `intens_out_level` use the same value from Control1[31:16]. Future versions may split these into separate registers.

### Control2-15 - Reserved

Reserved for future extensions.

## Input/Output Map

### Inputs

| Signal  | Bit(s) | Description                                               |
|---------|--------|-----------------------------------------------------------|
| InputA  | [0]    | External trigger input (OR'd with SOFT-TRIGGER)           |
| InputA  | [15:1] | Reserved                                                  |
| InputB  | All    | Reserved for future use                                   |
| InputC  | All    | Reserved for future use                                   |

### Outputs

| Signal  | Type          | Description                                        |
|---------|---------------|----------------------------------------------------|
| OutputA | signed(15:0)  | Trigger output (active during FIRING state)        |
| OutputB | signed(15:0)  | Intensity output (active during FIRING state)      |
| OutputC | signed(15:0)  | Status register (8-bit extended to 16-bit signed)  |

## Status Register (OutputC[7:0])

| Bit | Field   | Type       | Description                                    |
|-----|---------|------------|------------------------------------------------|
| 7-5 | Reserved| -          | Reserved (always 0)                            |
| 4   | DONE    | Sticky     | Set when sequence completes                    |
| 3   | COOLING | Live       | High only during COOLING state (NOT sticky)    |
| 2   | FIRING  | Sticky     | Set when entering FIRING state                 |
| 1   | DELAY   | Sticky     | Set when entering DELAY state                  |
| 0   | READY   | Sticky     | Set when entering READY state                  |

**Sticky Bits**: Once set, remain high until reset
**Live Bits**: Reflect current state only (COOLING bit)

## Operation Sequence

### 1. Initialization

```vhdl
-- Configure timing parameters
Control0[15:12] <= "0010";  -- cooldown = 2 cycles
Control0[11:8]  <= "0010";  -- firing = 2 cycles
Control1[7:0]   <= x"02";   -- delay = 2 cycles

-- Configure output levels
Control1[31:16] <= x"1234"; -- trigger/intensity level
```

### 2. Trigger

```vhdl
-- Option A: Software trigger
Control0[23] <= '1';  -- Set SOFT-TRIGGER bit

-- Option B: External trigger
InputA[0] <= '1';     -- Assert external trigger

-- Option C: Both (OR'd together)
```

### 3. State Sequence

```
RESET → READY → DELAY → FIRING → COOLING → DONE
  ↓       ↓       ↓        ↓        ↓        ↓
Status  0x01    0x03     0x07     0x0F     0x17
```

### 4. Output Behavior

| State   | OutputA (trigger) | OutputB (intensity) | Status Bits           |
|---------|-------------------|---------------------|-----------------------|
| READY   | 0x0000            | 0x0000              | READY sticky          |
| DELAY   | 0x0000            | 0x0000              | READY, DELAY sticky   |
| FIRING  | trig_out_level    | intens_out_level    | All sticky + FIRING   |
| COOLING | 0x0000            | 0x0000              | All sticky + COOLING  |
| DONE    | 0x0000            | 0x0000              | All sticky except COOLING |

### 5. Reset

To run another sequence, assert `Reset` signal or use hardware reset.

## Timing Diagrams

### Basic Pulse Sequence (delay=2, firing=2, cooldown=2)

```
Cycle:      0   1   2   3   4   5   6   7   8   9  10  11  12
Trigger:    ___/‾‾‾\___________________________________________________
State:      RST|RDY|RDY|DLY|DLY|FIR|FIR|FIR|COL|COL|COL|DON|DON
OutputA:    000|000|000|000|000|VAL|VAL|VAL|000|000|000|000|000
Status[0]:  0  |1   |1   |1   |1   |1   |1   |1   |1   |1   |1   |1
Status[1]:  0  |0   |0   |1   |1   |1   |1   |1   |1   |1   |1   |1
Status[2]:  0  |0   |0   |0   |0   |1   |1   |1   |1   |1   |1   |1
Status[3]:  0  |0   |0   |0   |0   |0   |0   |0   |1   |1   |1   |0
Status[4]:  0  |0   |0   |0   |0   |0   |0   |0   |0   |0   |0   |1
```

Note: Actual output values have 1 cycle delay due to registered outputs.

## Global Disable Behavior

When `Control0[31] = 1` (gDisable):
- All triggers are blocked (`trig_in` forced to 0)
- OutputA and OutputB are forced to 0
- Status register continues to reflect internal state
- FSM continues to operate but cannot be triggered

## Safety Features

1. **Sticky Status Bits**: Provide history of states visited
2. **Global Disable**: Emergency stop capability
3. **Registered Outputs**: All outputs synchronized to clock
4. **Trigger OR Logic**: Multiple trigger sources for flexibility
5. **Zero Default**: Outputs default to zero when not in FIRING state

## File Structure

```
modules/TPD/
├── core/
│   ├── emfi-fsm.vhd          # Core FSM (RESET→READY→DELAY→FIRING→COOLING→DONE)
│   └── tpd-med.vhd           # Wrapper with sticky status & output control
├── top/
│   └── CustomWrapper.vhd     # Moku integration layer
├── tb/
│   └── (testbenches)
├── cocotb_utils.py           # Shared test utilities
├── emfi_fsm_test_002.py      # FSM-only test
├── tpd_med_test_001.py       # Wrapper test
└── Makefile.cocotb           # CocoTB build system
```

## Compilation

```bash
# GHDL compilation
ghdl -a --std=08 core/emfi-fsm.vhd
ghdl -a --std=08 core/tpd-med.vhd
ghdl -a --std=08 top/CustomWrapper.vhd

# CocoTB testing
make -f Makefile.cocotb          # Run tests
make -f Makefile.cocotb WAVES=1  # Generate waveforms
```

## Example Usage (Python/Moku API)

```python
# Configure TPD parameters
moku.set_control_register(0,
    (0 << 31) |          # gDisable = 0 (enabled)
    (0 << 23) |          # SOFT-TRIGGER = 0 (off)
    (0 << 16) |          # IntensityLut-Index = 0
    (3 << 12) |          # Probe_cooldown = 3
    (5 << 8)             # Probe_fire = 5
)

# Set timing and levels
moku.set_control_register(1,
    (0x2000 << 16) |     # trig_out_level = 0x2000
    (0x10)               # delay_cnt = 16
)

# Software trigger
moku.set_control_register(0,
    moku.get_control_register(0) | (1 << 23)  # Set SOFT-TRIGGER
)

# Read status
status = moku.get_output_c() & 0xFF
if status & (1 << 4):  # Check DONE bit
    print("Sequence complete!")
```

## Future Enhancements

1. **IntensityLut**: Implement lookup table for output levels
2. **Separate intensity level**: Split Control1 or use Control2
3. **Multiple sequences**: Add sequence chaining support
4. **Delay on DONE**: Optional delay before returning to READY
5. **Fault detection**: Use HARD_FAULT state for error conditions

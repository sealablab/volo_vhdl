# PulseStar Hardware Validation Plan

## Overview
This document guides the comparison between hardware observations and simulation test expectations.

**Bitstream**: `25ff049_mokugo_4.0.3_2_bitstreams.tar` (synthesized 2025-10-23)

**Goal**: Deploy to real Moku device, observe behavior, and update simulation tests to match reality.

---

## Quick Start

```bash
# From project root
uv run python scripts/test_pulsestar_hardware.py --ip 192.168.1.100
```

The script will guide you through 7 tests with manual observations on the oscilloscope.

---

## Test Scenarios (Hardware vs Simulation)

### Test 1: MCC_READY Safe Boot

**Simulation Expectation** (`test_mcc_ready_initialization`):
- All outputs = 0 during all-zero state (CR0=0)
- UART idle = 0x8000 (high, -1.0V)
- After MCC_READY=1, outputs activate

**Hardware Observation**:
- [ ] All oscilloscope channels near zero before config
- [ ] UART (Ch3) at high voltage (~-1.0V)
- [ ] After configuration, waveforms appear

**Comparison Notes**:
```
Simulation: (fill in after running test_pulsestar)
Hardware: (fill in after hardware test)
Discrepancies: (list any differences)
```

---

### Test 2: Remote Enable/Disable

**Simulation Expectation** (`test_remote_enable_disable`):
- Enable=1 (CR0[30]=1) → Outputs active
- Enable=0 (CR0[30]=0) → Outputs = 0
- Re-enable → Outputs resume

**Hardware Observation**:
- [ ] Waveforms present when enabled
- [ ] All channels go to zero when disabled
- [ ] Waveforms resume when re-enabled

**Comparison Notes**:
```
Simulation:
Hardware:
Discrepancies:
```

---

### Test 3: I/Q Phase Relationship

**Simulation Expectation** (`test_iq_phase_relationship`):
- OutputA (I) = sine wave, starts near zero
- OutputB (Q) = cosine wave, starts near max (>20000 counts)
- Phase offset: 90° (Q leads I)

**Hardware Observation**:
- [ ] Ch1 (I) and Ch2 (Q) are sinusoids
- [ ] XY mode shows circular Lissajous (perfect 90°)
- [ ] Measure phase: Q leads I by ~90° (use cursors)

**Comparison Notes**:
```
Simulation I phase: ~0 at start
Simulation Q phase: ~32767 at start
Hardware I phase:
Hardware Q phase:
Discrepancies:
```

---

### Test 4: Frequency Control

**Simulation Expectation** (`test_frequency_control`):
- Div=1: Fast waveforms (~488 kHz)
- Div=240: Slow waveforms (~2.0 kHz)
- Changing Div changes output frequency proportionally

**Hardware Observation**:
- [ ] Div=1 produces visibly faster waveforms
- [ ] Div=240 produces slower waveforms
- [ ] Measure frequencies:
  - Div=1: _______ Hz (expected ~488 kHz)
  - Div=240: _______ Hz (expected ~2.0 kHz)

**Comparison Notes**:
```
Simulation Div=1 changes:
Simulation Div=240 changes:
Hardware Div=1 frequency:
Hardware Div=240 frequency:
Discrepancies:
```

---

### Test 5: Trigger Pulse Generation

**Simulation Expectation** (`test_trigger_pulse_generation`):
- OutputD generates periodic pulses
- Interval: 32000 clocks = 256 μs @ 125 MHz
- Width: 100 clocks = 800 ns @ 125 MHz
- At least 2 pulses detected in 500 clock cycles

**Hardware Observation**:
- [ ] Ch4 (Input D) shows periodic pulses
- [ ] Measure interval: _______ μs (expected 256 μs)
- [ ] Measure width: _______ ns (expected 800 ns)
- [ ] Pulses are consistent and stable

**Comparison Notes**:
```
Simulation interval: 256 μs (expected)
Simulation width: 800 ns (expected)
Hardware interval:
Hardware width:
Discrepancies:
```

**Critical**: If simulation hangs here, it suggests:
- Trigger generator not producing pulses (logic bug)
- Wrong register configuration in testbench
- Timing issue (pulse too narrow to detect)

---

### Test 6: UART Serial Output

**Simulation Expectation** (`test_uart_transmission`):
- OutputC transmits "VOLO" ASCII pattern
- Baud rate: 115200 (Div=1084)
- Format: 8N1
- Start bit detected within 5000 cycles

**Hardware Observation**:
- [ ] Ch3 (Input C) shows UART pulses
- [ ] Idle state is high voltage
- [ ] Start bits (low) visible
- [ ] Measure bit time: _______ μs (expected ~8.68 μs)

**Comparison Notes**:
```
Simulation start bit: Detected within 5000 cycles
Hardware bit time:
Hardware pattern visible:
Discrepancies:
```

**Critical**: If simulation hangs here, it suggests:
- UART never sends start bit (logic bug)
- Baud divider not working
- Wrong register configuration

---

### Test 7: Summary

**Simulation Expectation** (`test_summary`):
- All 6 tests complete successfully
- Module operates correctly end-to-end

**Hardware Observation**:
- [ ] All features work as expected
- [ ] No unexpected behavior observed

---

## Control Register Map

| Register | Bits     | Field             | Value Example | Description                     |
|----------|----------|-------------------|---------------|---------------------------------|
| Control0 | [31]     | MCC_READY         | 1             | Auto-set by MCC (active-high)   |
| Control0 | [30]     | User Enable       | 1             | 1=enable, 0=disable             |
| Control0 | [29]     | Clock Enable      | 1             | 1=run, 0=freeze                 |
| Control0 | [28:21]  | Frequency Divider | 240           | 0-255 division ratio            |
| Control0 | [20:0]   | Reserved          | 0             | Future use                      |
| Control1 | [31:16]  | UART Baud Div     | 1084          | 115200 baud                     |
| Control1 | [15:0]   | Trigger Interval  | 32000         | 256 μs @ 125 MHz                |
| Control2 | [31:24]  | Trigger Width     | 100           | 800 ns @ 125 MHz                |
| Control2 | [23:0]   | Reserved          | 0             | Future use                      |

**Standard Configuration** (from README):
```python
mcc.set_control(0, 0xC0F00000)  # MCC_READY + Enable + ClkEn + Div=240
mcc.set_control(1, 0x043C7D00)  # Baud=1084, Interval=32000
mcc.set_control(2, 0x64000000)  # PulseWidth=100
```

---

## Expected Signal Characteristics

### OutputA (I Channel)
- **Type**: Sine wave (256-point LUT)
- **Amplitude**: ±32767 (full-scale 16-bit signed)
- **Frequency**: 125 MHz / (Div+1) / 256
  - Div=240 → ~2.0 kHz
  - Div=1 → ~488 kHz
- **Phase**: Starts at 0° (sine wave)

### OutputB (Q Channel)
- **Type**: Cosine wave (90° offset from I)
- **Amplitude**: ±32767 (full-scale)
- **Frequency**: Same as I channel
- **Phase**: 90° ahead of I (cosine wave)

### OutputC (UART Serial)
- **Type**: UART 8N1 serial
- **Pattern**: "VOLO" ASCII (0x56, 0x4F, 0x4C, 0x4F)
- **Baud Rate**: 125 MHz / (Baud_Div+1)
  - Baud_Div=1084 → 115200 baud
- **Idle**: High (0x7FFF = -1.0V)
- **Start Bit**: Low (0x8000 = +1.0V)

### OutputD (Trigger Pulse)
- **Type**: Periodic pulse
- **Interval**: Trigger_Interval * 8ns (125 MHz clock)
  - 32000 → 256 μs
- **Width**: Trigger_Width * 8ns
  - 100 → 800 ns
- **Active**: 0x7FFF (-1.0V)
- **Idle**: 0x0000 (0V)

---

## Known Simulation Issues

### Infinite Loop (Reported 2025-10-23)
- **Symptom**: Test never completes, CPU at 99%
- **Process**: `./customwrapper --vpi=... --wave=dump.ghw`
- **Suspected Tests**:
  1. `test_trigger_pulse_generation` (waits for pulses)
  2. `test_uart_transmission` (waits for start bit)

### Possible Root Causes
1. **VHDL Logic Bug**: Trigger/UART never activate
2. **Testbench Config**: Wrong register values prevent operation
3. **Timing Issue**: Pulses too narrow/fast for testbench to detect
4. **Clock Divider**: Not producing clk_en pulses

**Hardware test will reveal**: If features work on hardware but fail in sim, it's a testbench issue. If they fail on both, it's a VHDL bug.

---

## Post-Hardware Test Actions

After running hardware tests, update this checklist:

### 1. Document Observations
- [ ] Fill in all "Hardware Observation" sections above
- [ ] Take oscilloscope screenshots (save to `modules/PulseStar/docs/`)
- [ ] Measure actual frequencies, timings, phase offsets

### 2. Compare to Simulation
- [ ] Run simulation tests (if they complete with timeout)
- [ ] Note any discrepancies between hardware and simulation
- [ ] Identify which tests hung in simulation

### 3. Fix Simulation Tests
Based on hardware validation:
- [ ] Update register values in testbenches if incorrect
- [ ] Adjust timeout values if needed (now 10s default)
- [ ] Fix any VHDL bugs discovered on hardware
- [ ] Add notes about hardware-validated behavior

### 4. Update Documentation
- [ ] Add hardware test results to this file
- [ ] Update README.txt with measured characteristics
- [ ] Create oscilloscope screenshot gallery
- [ ] Document any design changes

---

## Hardware Test Command Reference

```bash
# Basic test (default bitstream)
uv run python scripts/test_pulsestar_hardware.py --ip 192.168.1.100

# Custom bitstream location
uv run python scripts/test_pulsestar_hardware.py \
    --ip 192.168.1.100 \
    --bitstream path/to/custom_bitstream.tar

# Test specific Moku device
uv run python scripts/test_pulsestar_hardware.py --ip 10.0.0.5
```

---

## Troubleshooting

### Connection Issues
- Verify Moku IP address: `ping 192.168.1.100`
- Check Moku web interface is accessible
- Ensure no other instruments are running (relinquish ownership)

### Bitstream Loading Issues
- Verify bitstream file exists and is valid
- Check Moku platform ID matches (platform_id=2 for Moku:Go)
- Try rebooting Moku device

### No Waveforms on Oscilloscope
- Verify signal routing connections
- Check oscilloscope timebase (±1ms default)
- Increase voltage scale if signals too small
- Verify MCC_READY=1 and Enable=1

### UART Not Visible
- UART bit time is ~8.68 μs - may need to zoom in
- Check Ch3 trigger settings
- Use edge trigger on falling edge (start bit)

---

## Next Steps After Validation

1. **If all hardware tests PASS**:
   - Root cause of simulation hang is testbench issue
   - Update simulation to match hardware config
   - Re-run simulations with fixed configs

2. **If some hardware tests FAIL**:
   - Identify which features don't work
   - Debug VHDL logic for those features
   - Fix bugs and rebuild bitstream
   - Re-test on hardware

3. **Compare and Document**:
   - Create comparison table (expected vs actual)
   - Update design documentation
   - Add hardware validation badge to README

---

**Last Updated**: 2025-01-23
**Status**: Ready for hardware validation
**Bitstream**: `25ff049_mokugo_4.0.3_2_bitstreams.tar` (1.9 MB)

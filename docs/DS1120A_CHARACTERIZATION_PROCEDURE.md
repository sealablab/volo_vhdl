# DS1120A EMFI Probe Characterization Procedure

## Overview

Safe, systematic characterization of the Riscure DS1120A Unidirectional EMFI Probe using Moku:Go.

**Status**: Scripts tested and working with Moku at 192.168.13.159
**Date**: 2025-01-24
**Author**: Volo VHDL Project


![[volo_vhdl/docs/DS1120A-characterization-.jpeg]]
## Hardware Requirements

### Essential Equipment
- **DS1120A probe** with interchangeable tips (1.5mm, 4mm)
- **Moku:Go device** (tested at 192.168.13.159)
- **24V DC power supply** (center-positive barrel jack)
- **3× SMA cables** (50Ω, male-to-male, <1m recommended)
- **Computer** with Python 3.11+ and moku package installed

### Probe Specifications (DS1120A)
- **Pulse width**: 50ns (fixed, hardware-determined)
- **Power range**: 5-100% (below 5% unreliable)
- **Propagation delay**: ~50ns (trigger → coil current)
- **Max current (4mm tip)**: 56A @ 100% power
- **Current monitor**: -1.4V to 0V transient pulse

## Safety Precautions

### Before Starting
- ✅ No target device connected (probe fires into air for characterization)
- ✅ 24V external PSU connected and stable
- ✅ All SMA cables properly terminated (50Ω)
- ✅ Probe tip selected and securely mounted
- ✅ Start at minimum power (5%) only

### During Testing
- ⚠️ Do NOT exceed 50% power without reviewing results first
- ⚠️ Do NOT rapid-fire pulses (allow >1ms between triggers)
- ⚠️ Monitor current feedback - unexpected readings = STOP
- ⚠️ If probe tip gets hot, reduce power or increase delay between pulses

### Red Flags (Stop Immediately)
- 🚨 Current monitor shows no pulse → Check connections
- 🚨 Current monitor saturates at limits → Reduce power
- 🚨 Erratic behavior → Check PSU voltage stability
- 🚨 Probe tip discoloration → Reduce power, increase delays

## Physical Connections

### Wiring Diagram
```
[Moku:Go OutputA] --SMA--> [DS1120A: digital_glitch]   (Trigger)
                              ↓
[Moku:Go DACOut1] --SMA--> [DS1120A: pulse_amplitude]  (Power Control)
                              ↓
                          [DS1120A Probe]
                              ↓
[Moku:Go InputA] <--SMA-- [DS1120A: coil_current]     (Monitor)

[24V PSU] ---barrel---> [DS1120A: power_24vdc]
```

### Connection Sequence (Important!)
1. **First**: Connect 24V PSU to probe (power OFF initially)
2. **Second**: Connect current monitor (coil_current → Moku InputA)
3. **Third**: Connect power control (Moku DACOut1 → pulse_amplitude)
4. **Fourth**: Connect trigger (Moku OutputA → digital_glitch)
5. **Finally**: Power ON 24V PSU

**Never connect/disconnect while PSU is powered!**

## Software Setup

### Python Environment
```bash
cd /path/to/volo_vhdl
uv sync --no-install-project  # Setup environment

# Verify moku package installed
uv pip list | grep moku
```

### Test Scripts Available

#### 1. `test_ds1120a_simple.py` - Basic Connectivity Test
**Purpose**: Verify Moku connection and Data Logger functionality
**Duration**: ~5 seconds
**Safety**: No probe interaction

```bash
cd tests
uv run python test_ds1120a_simple.py
```

**Expected Output**:
- ✓ Connected to Moku:Go
- ✓ Data Logger deployed
- ✓ Captured ~250k samples

#### 2. `test_ds1120a_full.py` - Complete Characterization
**Purpose**: Full 3-phase characterization with power sweep
**Duration**: ~60 seconds
**Safety**: Starts at 5%, sweeps to 50% maximum

```bash
cd tests
uv run python test_ds1120a_full.py
```

**Expected Output**:
```
PHASE 1: CONNECTION VERIFICATION
- Moku connection established
- DataLogger + WaveformGenerator deployed
- Ready to capture at 25 MSa/s

PHASE 2: MINIMUM POWER TEST (5%)
- Power set to 5% (0.165V)
- Trigger configured
- Waveform captured (~300k samples)

PHASE 3: POWER SWEEP
- Tests: 5%, 10%, 20%, 30%, 40%, 50%
- Measures peak current vs. DAC voltage
- Validates monotonic increase
```

## Characterization Phases

### Phase 1: Connection Verification
**Goal**: Verify all hardware connections without firing probe

**Steps**:
1. Connect to Moku:Go device
2. Deploy Data Logger (slot 1) and Waveform Generator (slot 2)
3. Confirm 25 MSa/s sample rate available
4. Monitor input noise floor

**Pass Criteria**:
- Moku connection succeeds
- Both instruments deploy without errors
- Noise floor < ±50mV on current monitor input

**If Fail**: Check physical connections, Moku IP address, network

---

### Phase 2: Minimum Power Trigger Test
**Goal**: Verify probe responds at lowest safe power (5%)

**Steps**:
1. Set DAC output to 0.165V (5% power)
2. Configure square wave trigger (1 kHz, 50% duty)
3. Capture 10ms waveform at 25 MSa/s
4. Analyze current monitor signal

**Pass Criteria**:
- DAC voltage set correctly (0.165V ± 0.01V)
- Current monitor shows oscillating signal (not flat)
- Signal swing > 0.1V peak-to-peak

**Expected Waveforms**:
- At 5% power, expect small square wave from trigger
- Current monitor may show some coupling even without probe pulse

**If Fail**:
- No signal → Check trigger cable connection
- Flat signal → Check current monitor cable
- Excessive signal → Verify power at 5% only

---

### Phase 3: Power Sweep Characterization
**Goal**: Map DAC voltage to probe current output

**Steps**:
1. Test at: 5%, 10%, 20%, 30%, 40%, 50% power
2. For each level:
   - Set DAC voltage (power% × 3.3V / 100)
   - Wait 100ms settling time
   - Capture 10ms waveform
   - Measure peak/mean current monitor voltage
3. Verify monotonic increase (higher power → higher current)

**Pass Criteria**:
- All captures succeed (or most succeed with "End of stream" on some)
- Peak current monitor voltage increases with power
- Linear relationship between DAC voltage and peak current
- No saturation or clipping at 50%

**Expected Data** (approximate, no probe connected):
| Power % | DAC Voltage | Expected Signal      |
|---------|-------------|----------------------|
| 5%      | 0.165V      | Small square wave    |
| 10%     | 0.330V      | Larger square wave   |
| 20%     | 0.660V      | 2× amplitude         |
| 30%     | 0.990V      | 3× amplitude         |
| 40%     | 1.320V      | 4× amplitude         |
| 50%     | 1.650V      | 5× amplitude         |

**With Probe Connected** (future):
- At 5%: ~-0.07V to -0.2V peak (negative pulse)
- At 50%: ~-0.7V peak (half of max -1.4V)
- Pulse width: 17-20ns (at current monitor)
- Shape: Sharp negative spike

**If Fail**:
- Non-monotonic → Check probe PSU stability
- Saturation early → Reduce power increments
- No trend → Verify power control connection

---

## Data Interpretation

### Without Probe Connected (Current Tests)
**What You See**: Square wave from Waveform Generator Ch1
**Why**: Trigger signal capacitively couples to current monitor input
**Useful For**: Verifying signal path, timing relationships, Moku API

**Key Metrics**:
- Waveform frequency: 1 kHz (trigger frequency)
- Signal swing: Scales with DAC voltage (power setting)
- No 50ns pulses observed (probe not connected)

### With Probe Connected (Future Tests)
**What You'll See**: Sharp negative pulses at trigger frequency
**Why**: Real coil current during EM pulse generation
**Useful For**: Actual probe characterization

**Key Metrics**:
- Pulse width: 17-20ns (at current monitor, probe internal is 50ns)
- Peak voltage: -1.4V @ 100% (4mm tip), -1.2V @ 100% (1.5mm tip)
- Shape: Clean spike, not square wave
- Timing: ~50ns delay from trigger edge

### Validation Checklist
- [ ] Peak voltage increases monotonically with power
- [ ] No unexpected clipping or saturation
- [ ] Sample rate sufficient (25 MSa/s = 40ns/sample)
- [ ] Enough samples captured (>10,000 per test)
- [ ] DAC voltage matches commanded power level
- [ ] Noise floor acceptable between pulses (<50mV)

## Known Issues & Workarounds

### Issue 1: "End of stream" Errors
**Symptom**: Every other capture in Phase 3 fails with "End of stream"
**Impact**: Only 50% of power sweep points succeed
**Workaround**: Already implemented - `stop_streaming()` between captures
**Root Cause**: Moku Data Logger streaming state management
**Status**: Acceptable for characterization (enough data points)

### Issue 2: Moku:Go Has Only 1 Waveform Channel
**Symptom**: Cannot use separate channels for trigger and power
**Impact**: Must time-multiplex or use same output for both
**Current Solution**: Use WaveformGen Ch1 for trigger, then switch to DC for power
**Future Solution**: Use Oscilloscope/WaveformGen in different slots with routing

### Issue 3: Max Sample Rate 25 MSa/s (2 channels)
**Symptom**: Cannot achieve 1.25 GSa/s for 50ns pulse capture
**Impact**: Only ~2 samples per 50ns pulse (40ns/sample)
**Workaround**: Acceptable for envelope measurement, not fine structure
**Better Solution**: Use 1 channel only → 125 MSa/s (future work)

### Issue 4: Capacitive Coupling Without Probe
**Symptom**: Seeing square wave instead of sharp pulses
**Impact**: None - expected behavior without probe
**Explanation**: Trigger signal couples through cables/air to current monitor
**Action**: Normal - proceed to next phase

## Next Steps (With Probe Connected)

### Safety Progression
1. **5% Power, Single Pulse**: Verify negative spike appears
2. **10% Power, Single Pulse**: Confirm 2× amplitude
3. **20% Power, 10 Pulses**: Check consistency
4. **50% Power, 100 Pulses**: Thermal assessment
5. **75% Power** (with target or dummy load only)
6. **100% Power** (hardened targets only)

### Advanced Characterization
- [ ] Timing precision: Trigger edge to pulse peak
- [ ] Pulse width measurement (FWHM)
- [ ] Tip comparison (1.5mm vs 4mm current)
- [ ] Frequency sweep (max safe pulse rate)
- [ ] Thermal behavior (probe tip temperature vs. power/rate)
- [ ] Target-less field strength (H-field probe measurement)

### Integration with Test Bench Framework
- [ ] Create `ExternalHardware` config for DS1120A
- [ ] Use `BenchConfig` YAML for reproducible setups
- [ ] Integrate with MokuBackend for multi-instrument control
- [ ] Add probe configs to `.serena/memories/riscure_ds1120a.md`

## Troubleshooting

### Problem: Cannot Connect to Moku
**Check**:
- Moku powered on and network connected
- IP address correct (192.168.13.159)
- Computer on same network
- Firewall not blocking connection
- Run: `ping 192.168.13.159`

### Problem: No Data Captured
**Check**:
- Data Logger deployed successfully
- Sample rate not too high (max 25 MSa/s for 2 channels)
- Duration not too long (max ~10 seconds)
- Streaming stopped before new capture

### Problem: DAC Voltage Not Setting
**Check**:
- Waveform Generator deployed (slot 2)
- Using correct channel (Ch1 only on Moku:Go)
- DC waveform needs `dc_level` parameter (not `amplitude`)
- Voltage within range (0-3.3V)

### Problem: Current Monitor Flat
**Check**:
- Cable connected to DS1120A "coil_current" output
- Cable connected to Moku InputA
- Moku Data Logger using Input1 (maps to InputA)
- AC coupling enabled (default)
- Input range adequate (±5V recommended)

## References

### Documentation
- **DS1120A Datasheet**: `tests/docs/datasheets/DS1120A_DS1121A_datasheet.pdf`
- **Probe Catalog**: `.serena/memories/riscure_ds1120a.md`
- **Reference Images**: `tests/docs/images/ds1120a_top.jpg`
- **Bench Config**: `tests/bench_configs/ds1120a_basic.yaml`

### Related Work
- **Bench Framework**: `docs/BENCH_FRAMEWORK_DESIGN.md`
- **Moku API Docs**: https://apis.liquidinstruments.com/
- **EMFI Theory**: External references (TBD)

### Test Scripts
- **Simple Test**: `tests/test_ds1120a_simple.py`
- **Full Characterization**: `tests/test_ds1120a_full.py`
- **Future: Framework Integration**: `tests/test_ds1120a_bench.py` (TBD)

## Revision History

| Date       | Version | Changes                                      |
|------------|---------|----------------------------------------------|
| 2025-01-24 | 1.0     | Initial characterization procedure created   |
|            |         | Scripts tested with Moku at 192.168.13.159   |
|            |         | No probe connected - signal path verified    |

---

**END OF DOCUMENT**

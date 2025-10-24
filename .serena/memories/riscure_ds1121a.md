# Riscure DS1121A - EMFI Probe (Bidirectional)

---
vendor: Riscure
model: DS1121A
category: emfi_probe
variant: bidirectional
power_type: external_12vdc
moku_compatible: true
related_devices:
  - riscure_ds1120a
datasheet: docs/datasheets/DS1120A_DS1121A_datasheet.pdf
---

## Overview

Electromagnetic Fault Injection (EMFI) probe with **simultaneous injection and measurement** capability. Bidirectional design allows EM glitching while sensing target chip emissions through the same probe tip.

**Key Characteristics:**
- **Bidirectional**: Inject faults AND measure EM emissions simultaneously
- **Adjustable pulse width**: 4-200ns (software configurable)
- **Higher frequency**: 50 MHz pulse rate
- **Lower power**: 100V, 92A (safer for sensitive targets)
- **Faster response**: 18-20ns propagation delay
- **Built-in LEDs**: Power and Activity indicators

## Physical Connectors

### Top Panel

**Note**: Exact connector positions not yet photographed. Based on datasheet and device images:

| Connector Type | Gender | Signal Name | Direction | Description |
|---------------|--------|-------------|-----------|-------------|
| **Barrel Jack** | 2.1mm/2.5mm center-positive | `power_12vdc` | INPUT | 12VDC working voltage |
| **SMA** | Female | `digital_glitch` | INPUT | Trigger signal (from Moku/pattern generator) |
| **SMA** | Female | `pulse_amplitude` | INPUT | Analog power control (from Moku DAC) |
| **SMA** | Female | `coil_current` | OUTPUT | Current monitor (to scope/Moku input) |
| **SMA** | Female | `em_sense` | OUTPUT | EM measurement output (simultaneous sensing) |

**Visual Indicators:**
- **Power LED**: Indicates device powered on
- **Activity LED**: Indicates glitch activity

### Bottom

| Position | Connector Type | Description |
|----------|---------------|-------------|
| Bottom mount | **SMA threaded** | Interchangeable probe tip (1.5mm/4mm, 3 or 5 windings) |

### Connector Electrical Characteristics

| Connector | Impedance | Voltage Range | Notes |
|-----------|-----------|---------------|-------|
| `digital_glitch` (SMA) | 50Ω | 0-3.3V TTL | Rising edge triggered |
| `pulse_amplitude` (SMA) | 50Ω | 0-3.3V analog | Linear control 1-100% power |
| `coil_current` (SMA) | 50Ω | -2V to 0V | Transient pulse, use AC coupling |
| `em_sense` (SMA) | 50Ω | TBD | Target EM emissions (to be characterized) |
| `power_12vdc` (Barrel) | N/A | 12V DC | External PSU required (3V-100V internal) |

## Signal Interface

### Inputs (Driven by Moku/Controller)

| Signal Name | Connector | Voltage Range | Description | Moku Port Compatibility |
|-------------|-----------|---------------|-------------|-------------------------|
| `digital_glitch` | SMA Female | 0-3.3V TTL | Trigger pulse initiates EM glitch | OutputA, OutputB (TTL mode) |
| `pulse_amplitude` | SMA Female | 0-3.3V analog | Power level control (linear 1-100%) | DACOut1, DACOut2 |
| `power_12vdc` | Barrel Jack | 12V DC | Working voltage (internal 3-100V operation) | External PSU (not Moku) |

**Trigger Timing:**
- **Pulse width**: 4-200ns ±10% (adjustable via software/hardware configuration)
- **Propagation delay** (trigger → coil current): ~18ns ±10% (4mm tip, 5 windings)
- **Propagation delay** (trigger → EM tip): ~20ns ±10% (4mm tip, 5 windings)
- **Min trigger pulse**: Adjustable (matches configured pulse width)
- **Max pulse frequency**: 50 MHz (vs 1 MHz for DS1120A)

**Power Control:**
- **Range**: 1-100% (finer control than DS1120A's 5-100%)
- **Scaling**: Linear voltage-to-power mapping (to be characterized)
- **Internal voltage**: 3V-100V ±10%

### Outputs (Read by Moku/Scope)

| Signal Name | Connector | Voltage Range | Description | Moku Port Compatibility |
|-------------|-----------|---------------|-------------|-------------------------|
| `coil_current` | SMA Female | -2V to 0V | Real-time coil current waveform (transient) | InputA, InputB (AC coupled, 50Ω term) |
| `em_sense` | SMA Female | TBD | Target EM emissions (simultaneous measurement) | InputA, InputB (AC coupled, 50Ω term) |

**Current Monitor:**
- **Peak voltage**: -2V ±10% (4mm tip, 5 windings)
- **Pulse width**: 4-200ns ±10% (matches configured pulse width)
- **Bandwidth**: >50 MHz
- **Coupling**: AC coupling recommended
- **Termination**: 50Ω required

**EM Sense (Unique to DS1121A):**
- **Purpose**: Measure target chip EM emissions during or between glitches
- **Bandwidth**: TBD (to be characterized)
- **Sensitivity**: TBD (to be characterized)
- **Use cases**:
  - EM-based triggering (detect target operation state)
  - Side-channel analysis (correlate emissions with faults)
  - Timing verification (confirm glitch during sensitive operation)

### Physical Outputs (Non-Electrical)

| Output | Description |
|--------|-------------|
| **EM probe tip** | Bidirectional: injects EM glitches AND senses target emissions through same tip |

## Electrical Specifications

| Parameter | Value | Tolerance | Notes |
|-----------|-------|-----------|-------|
| Max voltage over coil | 100V | ±10% | Internal voltage (lower than DS1120A) |
| Max internal current | 92A | ±10% | Internal to probe |
| Max coil current (4mm tip, 5 windings) | 69A | ±10% | Higher than DS1120A despite lower voltage |
| EM pulse power control | 1-100% | N/A | Finer control than DS1120A (starts at 1%) |
| Pulse width (adjustable) | 4-200ns | ±10% | Software/hardware configurable |
| Max switching freq (constant power) | 1 MHz | N/A | For thermal stability |
| Pulse frequency | 50 MHz | N/A | Max instantaneous rate (thermal limits apply) |
| Working voltage | 12V DC | N/A | External PSU |
| Power range (internal) | 3V-100V | ±10% | Internal operation |
| Operating temperature | 0-70°C | N/A | Ambient temperature range |

## Probe Tips (Interchangeable)

All tips use SMA threaded mount. DS1121A offers precision tip selection:

| Tip Type | Diameter | Windings | Max Current (4mm tip) | Use Case |
|----------|----------|----------|-----------------------|----------|
| High precision | 1.5mm | 3 windings | Lower | Ultra-fine targeting |
| High precision | 1.5mm | 5 windings | Medium | Fine targeting, better coupling |
| Standard | 4mm | 3 windings | Medium | General purpose |
| Standard | 4mm | 5 windings | 69A ±10% | Maximum field strength |

**Winding Count Impact:**
- **5 windings**: Stronger coupling, better measurement sensitivity, higher inductance
- **3 windings**: Faster response, lower inductance, less coupling
- **Tip selection affects**: Propagation delay, max current, measurement sensitivity

## Typical Wiring Diagram

```
[Moku OutputA] --SMA--> [digital_glitch] ---> [DS1121A] --probe tip--> [Target DUT]
                                                   ↑                         ↓
[Moku DACOut1] --SMA--> [pulse_amplitude] --------┘                         ↓
                                                   ↓                         ↓
                        [coil_current] --SMA--> [Moku InputA]                ↓
                        [em_sense] -----SMA--> [Moku InputB] <-- (EM sense) -┘
                                                   ↑
[12V PSU] --barrel--> [power_12vdc] --------------┘
```

## Signal Flow (for Diagram Generation)

**Inputs:**
- `digital_glitch`: External trigger → DS1121A
- `pulse_amplitude`: External DAC → DS1121A
- `power_12vdc`: External PSU → DS1121A

**Outputs:**
- `coil_current`: DS1121A → External scope/ADC (injection monitor)
- `em_sense`: DS1121A → External scope/ADC (target EM measurement)
- `em_field`: DS1121A probe tip ↔ Target DUT (bidirectional physical coupling)

**Example BenchConfig Routing:**
```python
ExternalHardware(
    device_type='riscure_ds1121a',
    connections=[
        {'probe': 'digital_glitch', 'moku': 'OutputA'},
        {'probe': 'pulse_amplitude', 'moku': 'DACOut1'},
        {'probe': 'coil_current', 'moku': 'InputA'},
        {'probe': 'em_sense', 'moku': 'InputB'}
    ],
    settings={
        'probe_tip': '4mm_5_windings',
        'pulse_width_ns': 50,  # Configurable via external hardware
        'external_psu_voltage': 12
    }
)
```

## Comparison to DS1120A

See [[riscure_ds1120a]] for unidirectional variant.

| Feature | DS1120A (Unidirectional) | DS1121A (Bidirectional) |
|---------|--------------------------|-------------------------|
| **Direction** | Injection only | Injection + Measurement |
| **Max voltage** | 450V | 100V |
| **Max current** | 64A | 92A |
| **Pulse width** | 50ns (fixed) | 4-200ns (adjustable) |
| **Pulse frequency** | 1 MHz | 50 MHz |
| **Propagation delay** | 40-50ns | 18-20ns |
| **Power control** | 5-100% | 1-100% |
| **EM sensing** | ❌ No | ✅ Yes (`em_sense` output) |
| **Working voltage** | 24-450V DC | 12V DC |
| **LEDs** | None | Power + Activity |
| **Use case** | Hardened targets, simple setup | Adaptive attacks, EM triggering, sensitive targets |

**When to use DS1121A:**
- ✓ Need EM-based triggering (sense target state before glitch)
- ✓ Want to measure target emissions
- ✓ Need adjustable pulse width (4-200ns range)
- ✓ Higher frequency operation (50 MHz)
- ✓ Sensitive targets (100V safer than 450V)
- ✓ Closed-loop attacks (measure effect in real-time)

**When to use DS1120A:**
- ✓ Hardened targets requiring high power (450V)
- ✓ Simpler setup (fewer connections)
- ✓ Don't need EM sensing
- ✓ Fixed pulse width sufficient (50ns)

## Moku-Go Integration Notes

**Moku Output Ports** (driving probe):
- **OutputA/B** (TTL mode): Connect to `digital_glitch`
  - Configure as digital output, TTL levels (0/3.3V)
  - Pulse width determines EM pulse width (4-200ns)

- **DACOut1/2**: Connect to `pulse_amplitude`
  - Configure as DC-coupled, 0-3.3V range
  - Value controls power 1-100% (characterization needed)

**Moku Input Ports** (reading probe):
- **InputA**: Connect to `coil_current`
  - AC-coupled, 50Ω termination, ±5V range
  - Monitor injection pulse

- **InputB**: Connect to `em_sense`
  - AC-coupled, 50Ω termination, ±5V range
  - Capture target EM emissions

**Example Dual-Channel Moku Configuration:**
```python
# Trigger output (OutputA) with adjustable width
moku.set_digital_output('A', ttl_mode=True)
moku.configure_pulse_width('A', width_ns=50)  # 4-200ns

# Power control (DACOut1)
power_percent = 75
dac_voltage = (power_percent / 100.0) * 3.3
moku.set_dac_output(1, dac_voltage)

# Current monitor (InputA)
moku.configure_input('A', coupling='AC', impedance='50ohm', range='5V')

# EM sense (InputB) - simultaneous measurement
moku.configure_input('B', coupling='AC', impedance='50ohm', range='5V')
```

## Advanced Use Cases

### EM-Based Triggering
Use `em_sense` to trigger glitch based on target activity:
1. Monitor target EM emissions via `em_sense` → Moku InputB
2. Use pattern recognition to detect sensitive operation
3. Trigger `digital_glitch` when pattern detected
4. Verify timing via `coil_current` monitor

### Closed-Loop Fault Injection
1. Inject glitch via `digital_glitch`
2. Simultaneously monitor target response via `em_sense`
3. Adapt power/timing based on measured EM response
4. Iterate until fault achieved

### Side-Channel Analysis
1. Capture EM emissions via `em_sense` during normal operation
2. Correlate with known operations (crypto, authentication, etc.)
3. Identify vulnerable timing windows
4. Target those windows with precision glitches

## Safety and Handling

- ⚠️ **Permanent damage risk**: Can destroy unprotected chips
- ⚠️ **ESD sensitive**: Use grounded wrist strap when handling
- ✓ Lower voltage than DS1120A (100V vs 450V) - safer for sensitive targets
- ✓ Visual feedback via LEDs (power, activity)
- ✓ Always verify power level and pulse width before first trigger
- ✓ Test on sacrificial DUT first

## External Requirements

**Not Included:**
- **12V PSU**: Center-positive barrel connector
- **Coaxial cables**: 4× SMA male-to-male, 50Ω (suggest <1m length)
- **Pulse width configuration**: May require external software/hardware interface (TBD)
- **XYZ positioning stage**: Optional (Keysight DS1010A compatible)

## To Be Characterized

The following parameters need experimental characterization:
- [ ] `em_sense` voltage range and sensitivity
- [ ] `em_sense` frequency response and bandwidth
- [ ] Pulse width configuration method (software/hardware interface)
- [ ] Voltage-to-power mapping for `pulse_amplitude`
- [ ] `em_sense` signal-to-noise ratio at various distances
- [ ] Optimal probe tip selection for measurement vs. injection

## References

- **Datasheet**: `docs/datasheets/DS1120A_DS1121A_datasheet.pdf`
- **Related device**: [[riscure_ds1120a]] (unidirectional variant)
- **Usage examples**: TBD (to be added when tests written)
- **Moku integration**: See [[bench_config_framework]] for BenchConfig usage

# MCC Debugging Techniques and Boot Process Insights

## Overview

This memory documents systematic techniques for debugging MCC (Moku Cloud Compile) modules when they don't respond to configuration or exhibit unexpected behavior. These patterns were discovered during PulseStar hardware validation (2025-01-23).

## Critical Discovery: Clock Enable Bit (Control0[29])

### The Problem

Modules were deploying successfully but showed no activity even after `set_control()` calls. Outputs remained static at 0V regardless of configuration.

### Root Cause

**Missing Clock Enable bit in Control0[29]**. The MCC CustomWrapper integration requires THREE control bits for module operation:

```
Control0[31] = MCC_READY (active-high) - Set by MCC after deployment
Control0[30] = User Enable (active-high) - User-controlled enable/disable
Control0[29] = Clock Enable (active-high) - **MANDATORY** for clocked logic
```

**Correct Configuration Pattern:**
```
0xE0000000 = bits 31+30+29 set (MCC_READY + Enable + ClkEn)
```

**Wrong Pattern (DO NOT USE):**
```
0xC0000000 = bits 31+30 set (missing Clock Enable!)
→ Module remains frozen even when "enabled"
```

### Full Example with Divider

```python
# For Div=240 (0xF0 in bits 23:16):
Control0 = 0xEEF00000  # Bits: 31+30+29 + divider
# 0xEE = 1110_1110 = MCC_READY | Enable | ClkEn | divider bits
```

## Debugging Tools

Three systematic debugging scripts were created (located in `scripts/`):

### 1. `observe_mcc_boot.py` - Boot Process Observer

**Purpose**: Understand module behavior during bitstream deployment and configuration.

**What it does**:
- Deploys bitstream to Moku MCC slot
- Captures outputs BEFORE configuration (all-zero state)
- Applies configuration and captures outputs AFTER
- Compares initial vs configured state

**Usage**:
```bash
uv run python scripts/observe_mcc_boot.py \
  --ip 192.168.13.159 \
  --bitstream bitstreams/module_name.tar.gz \
  --config "0:0xEEF00000,1:0x043C7D00"
```

**Key Insights from Boot Observation**:
- **Safe modules** boot with all outputs at ~0V
- **Unsafe modules** may have undefined outputs (e.g., PulseStar Q channel at 5.002V)
- Simple reference modules (sample_counter) boot safely and respond correctly
- Complex modules may need explicit safe-boot initialization

### 2. `debug_mcc_config.py` - Configuration Debugger

**Purpose**: Systematically test why `set_control()` doesn't activate modules.

**What it does**:
- Tests multiple Control0 bit patterns:
  - MCC_READY only (bit 31)
  - User Enable only (bit 30)
  - Clock Enable only (bit 29)
  - Combinations: bits 31+30, 31+30+29, etc.
- Varies settle times (10ms → 1000ms)
- Varies oscilloscope timebases (10μs → 10ms)
- Analyzes zero-crossings and signal dynamics

**Usage**:
```bash
uv run python scripts/debug_mcc_config.py \
  --ip 192.168.13.159 \
  --bitstream bitstreams/module_name.tar.gz
```

**Critical Findings**:
- Pattern 0xE0000000 (bits 31+30+29) activates modules ✓
- Pattern 0xC0000000 (bits 31+30) FAILS - module frozen ✗
- Pattern 0x60000000 (bits 30+29, no MCC_READY) FAILS ✗
- Timing/settle variations had NO effect (root cause was bit 29)

### 3. `test_*_hardware_auto.py` - Automated Hardware Validation

**Purpose**: Fully automated hardware testing without manual probe connections.

**Key Features**:
- Deploys bitstream via MCC API
- Routes signals via Multi-Instrument Mode connections
- Captures waveforms via Oscilloscope API
- Performs frequency analysis, phase measurement, etc.

**Example**: `scripts/test_pulsestar_hardware_auto.py`

## MCC API Patterns

### Multi-Instrument Mode Setup

```python
from moku.instruments import MultiInstrument, Oscilloscope, CloudCompile

# Connect (force_connect if connection exists)
moku = MultiInstrument(ip_address, platform_id=2, force_connect=True)

# Deploy bitstream to Slot 2
mcc = moku.set_instrument(2, CloudCompile, bitstream=str(bitstream_path))

# Setup oscilloscope in Slot 1
osc = moku.set_instrument(1, Oscilloscope)
osc.set_timebase(-1e-3, 1e-3)  # ±1ms window

# Route signals (only 2 channels in MIM)
connections = [
    dict(source="Slot2OutA", destination="Slot1InA"),
    dict(source="Slot2OutB", destination="Slot1InB"),
]
moku.set_connections(connections=connections)
```

### Oscilloscope API in MIM

```python
# Trigger configuration (use "ChannelA", not "Input1"!)
osc.set_trigger(type="Edge", source="ChannelA", level=0.0, 
                mode="Auto", edge="Rising")

# Capture data
data = osc.get_data()
ch1 = np.array(data['ch1'])
ch2 = np.array(data['ch2'])
time = np.array(data['time'])
```

**MIM Limitations**:
- Oscilloscope only exposes 2 channels (InA, InB)
- OutC/OutD require Data Logger or different routing
- No `set_frontend()` in MIM (raises MokuException)
- Source names different from standalone mode

### Register Read Pattern

```python
# get_control() returns LIST of all 32 registers
all_regs = mcc.get_control()
cr0, cr1, cr2 = all_regs[0], all_regs[1], all_regs[2]

# NOT: cr0 = mcc.get_control(0)  # TypeError!
```

## Boot Process Comparison

### Safe Boot (sample_counter)

```
Initial State (after bitstream load):
  OutputA: 0.0000V ✓
  OutputB: 0.0000V ✓

Configured State (0xE0000000):
  OutputA: -0.1400V (std=2.9521V) ✓ DYNAMIC
  OutputB: -0.0006V (std=0.0115V) ✓ DYNAMIC
```

### Unsafe Boot (PulseStar)

```
Initial State (after bitstream load):
  OutputA: 0.0000V ✓
  OutputB: 5.0023V ✗ (cosine LUT defaults to max)

Configured State (0xEE000000):
  OutputA: 0.3154V (std=3.4794V) ✓ DYNAMIC
  OutputB: 0.5205V (std=3.5421V) ✓ DYNAMIC
```

**Key Insight**: PulseStar cosine LUT initializes to max value (32767 = 5V DAC output). This is a VHDL initialization issue, not a configuration problem.

## Simulation vs Hardware Correlation

With the corrected Control0 configuration (0xE0000000), simulation behavior now matches hardware:

### Before Correction (0xC0000000)
- **Simulation**: Infinite loops, tests hung
- **Hardware**: Static outputs, no waveforms

### After Correction (0xE0000000)
- **Simulation**: Tests pass (2/7 passing + cosine bug)
- **Hardware**: Waveforms detected, module responds
- **Match**: Both show same cosine initialization bug (OutputB = 32767)

## Best Practices

### 1. Always Use Full Enable Pattern

```python
# Template for MCC module configuration:
CR0_BASE = 0xE0000000  # MCC_READY + Enable + ClkEn
CR0_WITH_DIV = CR0_BASE | (divider << 16)  # Add divider in bits 23:16
```

### 2. Verify Boot Safety

Before deploying to production:
1. Run `observe_mcc_boot.py` with all-zero config
2. Check all outputs are at safe levels (<0.1V)
3. If unsafe, add explicit reset/initialization logic

### 3. Systematic Debugging Workflow

When modules don't respond:

1. **Verify bitstream deployed**: Check MCC slot status
2. **Test with simple_counter**: Confirm MCC infrastructure works
3. **Run debug_mcc_config.py**: Find working bit pattern
4. **Compare with reference**: Use sample_counter as baseline
5. **Update Control0 patterns**: Apply bit 29 to all configs

### 4. Reference Module Testing

Keep `bitstreams/simple_counter.tar.gz` available:
- Boots safely (all outputs 0V)
- Responds correctly to configuration
- Use as sanity check for MCC API issues

## Common Pitfalls

1. **Missing Clock Enable**: Most common issue, module frozen
2. **Wrong source names**: Use "ChannelA" not "Input1" in MIM
3. **Channel limits**: Oscilloscope only has 2 channels in MIM
4. **Register read API**: Returns list, not single value
5. **Assuming safe boot**: Always verify outputs at bitstream load

## Integration with Testing

Update CocotB tests to use correct patterns:

```python
# OLD (WRONG):
await mcc_set_regs(dut, {
    0: 0xC0F00000,  # Missing Clock Enable!
    1: 0x043C7D00,
    2: 0x64000000
}, set_mcc_ready=True)

# NEW (CORRECT):
await mcc_set_regs(dut, {
    0: 0xEEF00000,  # Includes Clock Enable (bit 29)
    1: 0x043C7D00,
    2: 0x64000000
}, set_mcc_ready=True)
```

## Related Documentation

- `mcc_routing_concepts.md` - MCC signal routing patterns
- `instrument_cloud_compile.md` - CloudCompile instrument usage
- `instrument_oscilloscope.md` - Oscilloscope API and MIM limitations
- `mcc_build_pattern.md` - Building MCC bitstreams

## Tools Location

All debugging tools in `scripts/` directory:
- `observe_mcc_boot.py` - Boot process observer
- `debug_mcc_config.py` - Configuration debugger
- `test_*_hardware_auto.py` - Automated hardware validation

**Author**: Claude Code (2025-01-23)  
**Hardware**: Moku:Go @ 192.168.13.159  
**Test Module**: PulseStar calibration signal generator

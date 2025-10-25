# PulseStar - Multi-Channel Calibration Signal Generator

**PulseStar** is a 4-channel calibration signal generator designed for verifying inter-instrument communication and signal integrity on Moku platforms.

## Overview

PulseStar generates four precisely-related calibration signals:
- **OutputA**: I Channel (Sine wave)
- **OutputB**: Q Channel (Cosine wave, 90° phase offset)
- **OutputC**: UART Serial ("VOLO" ASCII pattern)
- **OutputD**: Trigger Pulses (synchronization reference)

## Key Features

✅ **MCC_READY Convention** - Safe default behavior during bitstream load
✅ **I/Q Quadrature Signals** - Perfect 90° phase relationship for lock-in/phasemeter testing
✅ **Configurable Frequency** - Via clock divider (0-255 division ratio)
✅ **UART Serial Output** - Digital pattern for communication testing
✅ **Trigger Generation** - Programmable pulse width and interval
✅ **Remote Control** - Enable/disable via MCC control registers

## Module Architecture

```
PulseStar/
├── datadef/
│   └── waveform_lut_pkg.vhd       # 256-point sine/cosine LUTs
├── core/
│   ├── waveform_gen_core.vhd      # I/Q signal generator (uses clk_divider_core)
│   ├── trigger_gen_core.vhd       # Programmable trigger pulses
│   └── uart_tx_core.vhd           # UART transmitter ("VOLO" pattern)
└── top/
    └── Top.vhd                     # CustomWrapper integration
```

## Control Register Map

### Control0 - Main Configuration
```
Bit [31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
Bit [30]:    Global Enable (1=enable, 0=disable)
Bit [29]:    Clock Enable (1=run, 0=freeze all outputs)
Bits[28:21]: Frequency Divider (0-255) - base frequency control
Bits[20:0]:  Reserved
```

### Control1 - Timing Parameters
```
Bits[31:16]: UART Baud Divider (clk / (baud_div+1) = baud_rate)
             Example: 1084 → 115200 baud @ 125MHz
Bits[15:0]:  Trigger Pulse Interval (clock cycles between pulses)
```

### Control2 - Pulse Configuration
```
Bits[31:24]: Trigger Pulse Width (clock cycles per pulse)
Bits[23:0]:  Reserved
```

## Python MokuBench Usage

### Basic Configuration
```python
from moku.instruments import MultiInstrument, CloudCompile

m = MultiInstrument('192.168.1.100', platform_id=2)
mcc = m.set_instrument(2, CloudCompile, bitstream="pulsestar.tar.gz")

# Configure: 1kHz I/Q, 115200 baud UART, 1ms trigger interval
mcc.set_control(0, 0xC0F00000)  # MCC_READY + Enable + ClkEn + Div=240 (≈1kHz)
mcc.set_control(1, 0x043C7D00)  # Baud=1084 (115200), Interval=32000 (256μs)
mcc.set_control(2, 0x64000000)  # PulseWidth=100 clocks (800ns @ 125MHz)
```

### Routing for Oscilloscope Monitoring
```python
# Route PulseStar outputs to Oscilloscope (Slot 1)
connections = [
    dict(source="Slot2OutA", destination="Slot1InA"),  # I channel → OSC Ch1
    dict(source="Slot2OutB", destination="Slot1InB"),  # Q channel → OSC Ch2
    dict(source="Slot2OutD", destination="Slot1InC"),  # Trigger → OSC Ch3
    dict(source="Slot2OutA", destination="Output1"),   # I channel → Physical OUT1
]
m.set_connections(connections=connections)
```

### Remote Enable/Disable
```python
# Disable outputs (keep MCC_READY=1)
mcc.set_control(0, 0x80F00000)  # MCC_READY=1, Enable=0

# Re-enable outputs
mcc.set_control(0, 0xC0F00000)  # MCC_READY=1, Enable=1
```

## Output Specifications

### OutputA - I Channel (Sine)
- **Format**: 16-bit signed (-32768 to +32767)
- **Waveform**: Sine wave from 256-point LUT
- **Phase**: 0° reference
- **Frequency**: System clock / (freq_div + 1) / 256

### OutputB - Q Channel (Cosine)
- **Format**: 16-bit signed (-32768 to +32767)
- **Waveform**: Cosine wave from 256-point LUT
- **Phase**: 90° offset from OutputA
- **Frequency**: Identical to OutputA

### OutputC - UART Serial
- **Format**: 16-bit signed (0x7FFF=high, 0x8000=low)
- **Protocol**: 8N1 (8 data bits, no parity, 1 stop bit)
- **Pattern**: "VOLO" (0x56 0x4F 0x4C 0x4F) repeating
- **Baud Rate**: 125MHz / (baud_div + 1)
- **Example**: baud_div=1084 → 115200 baud

### OutputD - Trigger Pulse
- **Format**: 16-bit signed (0x7FFF=active, 0x0000=idle)
- **Interval**: Configurable (clock cycles between pulses)
- **Width**: Configurable (clock cycles per pulse)
- **Use Case**: Synchronization, external triggering

## Calibration Use Cases

### 1. Lock-In Amplifier Validation
```python
# Configure 10kHz I/Q signals
mcc.set_control(0, 0xC0018000)  # Div=24 → ~10kHz @ 125MHz/256

# Route to lock-in amplifier instrument
connections = [
    dict(source="Slot2OutA", destination="Slot3InA"),  # I → Lock-in Ref
    dict(source="Slot2OutB", destination="Slot3InB"),  # Q → Lock-in Signal
]
```

**Expected**: Lock-in should measure exactly 90° phase difference

### 2. Spectrum Analyzer Frequency Response
```python
# Sweep frequency from 1kHz to 100kHz
for div in range(240, 12, -10):  # Decrease divider = higher freq
    mcc.set_control(0, 0xC0000000 | (div << 21))
    time.sleep(0.1)
    # Spectrum analyzer should track frequency changes
```

### 3. Data Logger UART Decoding
```python
# Configure 9600 baud for slow capture
mcc.set_control(1, 0x3415 << 16)  # baud_div=13333 → 9600 baud

# Data logger should decode: "VOLO" repeating
```

### 4. Oscilloscope Trigger Synchronization
```python
# Configure 1ms trigger interval
mcc.set_control(1, 0x0001F400)  # interval=128000 clocks (1.024ms @ 125MHz)
mcc.set_control(2, 0xC8000000)  # width=200 clocks (1.6μs)

# Use OutputD as oscilloscope external trigger
```

## Testing

### Run CocotB Tests
```bash
cd tests/
uv run make TEST_MODULE=pulsestar
```

### Test Coverage
- ✅ MCC_READY initialization (safe boot)
- ✅ Remote enable/disable control
- ✅ I/Q phase relationship (90° offset)
- ✅ Frequency control via divider
- ✅ Trigger pulse generation
- ✅ UART serial transmission

## Dependencies

- **volo_common**: Provides `clk_divider_core` for frequency generation
- **MCC CustomWrapper**: Standard 4-input/4-output interface

## Technical Details

### Sine/Cosine LUT
- **Size**: 256 entries
- **Format**: 16-bit signed
- **Amplitude**: Full-scale (±32767)
- **Precision**: ~1.4° angular resolution

### Frequency Calculation
```
Output Frequency (Hz) = System Clock (Hz) / (freq_div + 1) / 256

Examples @ 125MHz:
- freq_div=0   → 488.3 kHz (max)
- freq_div=1   → 244.1 kHz
- freq_div=24  → 19.5 kHz
- freq_div=240 → 2.0 kHz
- freq_div=255 → 1.9 kHz (min)
```

### UART Baud Rate Calculation
```
Baud Rate = System Clock (Hz) / (baud_div + 1)

Examples @ 125MHz:
- baud_div=0    → 125 Mbaud (max, not standard)
- baud_div=1084 → 115200 baud (standard)
- baud_div=13333 → 9600 baud (standard)
```

## Build and Deploy

### Compile Module
```bash
cd modules/
make clean && make compile
```

### Package for Cloud Compile
```bash
cd modules/PulseStar/
./build_cloudcompile.sh  # (if script exists)
```

### Deploy to Moku
Upload `pulsestar.tar.gz` to Moku via Cloud Compile interface

## Troubleshooting

### No Outputs After Configuration
- **Check**: Control0[31] (MCC_READY) should be 1
- **Check**: Control0[30] (Enable) should be 1
- **Check**: Control0[29] (ClkEn) should be 1

### I/Q Signals Not in Quadrature
- **Verify**: Using Oscilloscope to monitor both channels
- **Expected**: 90° phase difference at all frequencies
- **Tolerance**: ±2° (limited by 256-point LUT)

### UART Decode Errors
- **Check**: Baud rate calculation matches receiver
- **Check**: Using 8N1 format
- **Expected Pattern**: "VOLO" (0x56 0x4F 0x4C 0x4F)

### Trigger Pulses Missing
- **Check**: Control1[15:0] (interval) > Control2[31:24] (width)
- **Check**: Width and interval are non-zero
- **Verify**: OutputD transitions between 0x0000 and 0x7FFF

## Author

**Claude Code**
Date: 2025-01-22
Branch: feature/PulseStar

## References

- `CLAUDE.md` - Project coding standards
- `tests/test_pulsestar.py` - CocotB test suite
- `modules/volo_common/` - Shared clk_divider_core

# SimpleWaveGen Waveform Generation Guide

This guide explains how to generate and view waveform files for the SimpleWaveGen module using GHDL and GTKWave.

## Prerequisites

- **GHDL**: VHDL compiler and simulator (VHDL-2008 support required)
- **GTKWave**: Waveform viewer for VCD files
- **Bash shell**: For running the waveform generation script

## Quick Start

### 1. Generate Waveform Files

Run the automated waveform generation script:

```bash
cd modules/SimpleWaveGen
./generate_waveforms.sh
```

This script will:
- Compile the SimpleWaveGen module
- Generate VCD files for different test scenarios
- Create 4 waveform files for analysis

### 2. View Waveforms with GTKWave

Open the generated VCD files in GTKWave:

```bash
# View core module waveforms
gtkwave SimpleWaveGen_core_square.vcd
gtkwave SimpleWaveGen_core_triangle.vcd
gtkwave SimpleWaveGen_core_sine.vcd

# View top-level integration
gtkwave SimpleWaveGen_top_integration.vcd
```

## Generated Waveform Files

| File | Description | Duration | Content |
|------|-------------|----------|---------|
| `SimpleWaveGen_core_square.vcd` | Core square wave generation | 1000ns | Square wave output, clock, enable |
| `SimpleWaveGen_core_triangle.vcd` | Core triangle wave generation | 1000ns | Triangle wave output, clock, enable |
| `SimpleWaveGen_core_sine.vcd` | Core sine wave generation | 1000ns | Sine wave output, clock, enable |
| `SimpleWaveGen_top_integration.vcd` | Top-level integration test | 500ns | Register interface, fault handling |

## Manual Waveform Generation

If you prefer to generate waveforms manually:

### Core Module Testbench

```bash
# Compile
ghdl -a --std=08 common/platform_interface_pkg.vhd
ghdl -a --std=08 core/SimpleWaveGen_core.vhd
ghdl -a --std=08 tb/core/SimpleWaveGen_core_tb.vhd

# Elaborate
ghdl -e --std=08 SimpleWaveGen_core_tb

# Run with VCD output
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=waveform.vcd --stop-time=1000ns
```

### Top-Level Testbench

```bash
# Compile (includes dependencies)
ghdl -a --std=08 common/platform_interface_pkg.vhd
ghdl -a --std=08 core/SimpleWaveGen_core.vhd
ghdl -a --std=08 top/SimpleWaveGen_top.vhd
ghdl -a --std=08 tb/top/SimpleWaveGen_top_tb.vhd

# Elaborate
ghdl -e --std=08 SimpleWaveGen_top_tb

# Run with VCD output
ghdl -r --std=08 SimpleWaveGen_top_tb --vcd=waveform.vcd --stop-time=500ns
```

## GTKWave Configuration

Use the provided `SimpleWaveGen.gtkw` configuration file for optimal signal viewing:

```bash
gtkwave SimpleWaveGen.gtkw SimpleWaveGen_core_square.vcd
```

This configuration:
- Organizes signals into logical groups
- Highlights important waveforms
- Sets appropriate time ranges
- Provides consistent viewing experience

## Signal Analysis

### Key Signals to Monitor

1. **Clock Signals**
   - `clk`: System clock (10ns period)
   - `clk_en`: Clock enable from divider

2. **Control Signals**
   - `rst`: Reset signal
   - `en`: Module enable
   - `cfg_safety_wave_select`: Wave type selection

3. **Output Signals**
   - `wave_out[15:0]`: 16-bit waveform output
   - `fault_out`: Error indicator
   - `stat[7:0]`: Status register

4. **Register Interface** (Top-level)
   - `wavegen_ctrl_wr`: Control register write
   - `wave_select_data`: Wave selection data
   - `wavegen_status_rd`: Status register read

### Waveform Characteristics

- **Square Wave**: Toggles between high/low values
- **Triangle Wave**: Ramps up and down linearly
- **Sine Wave**: Smooth sinusoidal variation
- **Clock Enable**: Controls waveform update rate

## Troubleshooting

### Common Issues

1. **Compilation Errors**
   - Ensure GHDL supports VHDL-2008 (`--std=08`)
   - Check all dependencies are compiled first

2. **VCD File Not Generated**
   - Verify simulation runs to completion
   - Check file permissions in output directory

3. **GTKWave Display Issues**
   - Use the provided `.gtkw` configuration file
   - Ensure GTKWave version compatibility

### Debug Commands

```bash
# Check GHDL version
ghdl --version

# Verify VHDL-2008 support
ghdl -a --std=08 --help

# Check GTKWave version
gtkwave --version
```

## Advanced Usage

### Custom Waveform Generation

Modify the testbench timing or add custom test scenarios:

```vhdl
-- Add custom test patterns
wait for CLK_PERIOD * 100;  -- Longer observation time
-- Add custom signal assignments
```

### Batch Processing

Generate multiple waveform files with different parameters:

```bash
# Generate waveforms with different clock frequencies
for freq in 10 20 50; do
    ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=wave_${freq}MHz.vcd --stop-time=1000ns
done
```

## Integration with Build System

The waveform generation integrates with the project's build system:

```bash
# From modules/ directory
make compile-single-module MODULE_NAME=SimpleWaveGen

# Then generate waveforms
cd SimpleWaveGen
./generate_waveforms.sh
```

This ensures consistent compilation and dependency management across all waveform generation tasks.

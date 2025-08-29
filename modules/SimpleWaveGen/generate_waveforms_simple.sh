#!/bin/bash

# SimpleWaveGen Simple Waveform Generation Script
# Generates VCD files for GTKWave viewing with proper compilation steps

echo "=== SimpleWaveGen Simple Waveform Generation ==="
echo ""

# Set working directory
cd "$(dirname "$0")"

# Clean previous builds
echo "Cleaning previous builds..."
make clean > /dev/null 2>&1

echo "=== Compiling and Generating Waveforms ==="

# Compile packages and modules
echo "1. Compiling packages and modules..."
ghdl -a --std=08 common/platform_interface_pkg.vhd
ghdl -a --std=08 core/SimpleWaveGen_core.vhd
ghdl -a --std=08 top/SimpleWaveGen_top.vhd

# Compile testbenches
echo "2. Compiling testbenches..."
ghdl -a --std=08 tb/core/SimpleWaveGen_core_tb.vhd
ghdl -a --std=08 tb/top/SimpleWaveGen_top_tb.vhd

# Elaborate testbenches
echo "3. Elaborating testbenches..."
ghdl -e --std=08 SimpleWaveGen_core_tb
ghdl -e --std=08 SimpleWaveGen_top_tb

echo "✅ Compilation and elaboration complete!"
echo ""

# Generate VCD files
echo "=== Generating Waveform Files ==="

# Core module testbench - Square wave
echo "1. Generating core module square wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_square.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_square.vcd"

# Core module testbench - Triangle wave  
echo "2. Generating core module triangle wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_triangle.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_triangle.vcd"

# Core module testbench - Sine wave
echo "3. Generating core module sine wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_sine.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_sine.vcd"

# Top-level integration testbench
echo "4. Generating top-level integration test..."
ghdl -r --std=08 SimpleWaveGen_top_tb --vcd=SimpleWaveGen_top_integration.vcd --stop-time=500ns
echo "   ✅ Generated: SimpleWaveGen_top_integration.vcd"

echo ""
echo "=== Waveform Files Ready ==="
echo "Generated VCD files:"
echo "  • SimpleWaveGen_core_square.vcd      - Core square wave generation"
echo "  • SimpleWaveGen_core_triangle.vcd    - Core triangle wave generation"  
echo "  • SimpleWaveGen_core_sine.vcd        - Core sine wave generation"
echo "  • SimpleWaveGen_top_integration.vcd  - Top-level integration test"
echo ""
echo "=== Viewing with GTKWave ==="
echo "To view waveforms, run:"
echo "  gtkwave SimpleWaveGen_core_square.vcd"
echo "  gtkwave SimpleWaveGen_core_triangle.vcd"
echo "  gtkwave SimpleWaveGen_core_sine.vcd"
echo "  gtkwave SimpleWaveGen_top_integration.vcd"
echo ""
echo "=== Quick View ==="
echo "For immediate viewing, run:"
echo "  gtkwave SimpleWaveGen_core_square.vcd &"
echo ""
echo "✅ All waveform files generated successfully!"

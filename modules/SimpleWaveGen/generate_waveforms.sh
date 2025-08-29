#!/bin/bash

# SimpleWaveGen Waveform Generation Script
# Generates VCD files for GTKWave viewing

echo "=== SimpleWaveGen Waveform Generation ==="
echo ""

# Set working directory
cd "$(dirname "$0")"

# Clean previous builds
echo "Cleaning previous builds..."
make clean > /dev/null 2>&1

# Compile the module
echo "Compiling SimpleWaveGen module..."
cd .. && make compile-single-module MODULE_NAME=SimpleWaveGen

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

echo "✅ Compilation successful!"
echo ""

# Elaborate testbenches
echo "Elaborating testbenches..."
ghdl -e --std=08 SimpleWaveGen_core_tb
ghdl -e --std=08 SimpleWaveGen_top_tb
echo "✅ Testbenches elaborated successfully!"
echo ""

# Generate VCD files for different test scenarios

echo "=== Generating Waveform Files ==="

# 1. Core module testbench - Square wave
echo "1. Generating core module square wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_square.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_square.vcd"

# 2. Core module testbench - Triangle wave  
echo "2. Generating core module triangle wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_triangle.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_triangle.vcd"

# 3. Core module testbench - Sine wave
echo "3. Generating core module sine wave..."
ghdl -r --std=08 SimpleWaveGen_core_tb --vcd=SimpleWaveGen_core_sine.vcd --stop-time=1000ns
echo "   ✅ Generated: SimpleWaveGen_core_sine.vcd"

# 4. Top-level integration testbench
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
echo "✅ All waveform files generated successfully!"

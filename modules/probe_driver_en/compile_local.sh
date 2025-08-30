#!/bin/bash
# Compilation script for local GHDL testing of probe_driver module
# This script compiles the probe_driver_interface module without CustomWrapper
# to avoid conflicts with the vendor's compiler package

set -e  # Exit on any error

echo "=== Compiling Probe Driver Module for Local Testing ==="

# Clean up previous compilation artifacts
echo "Cleaning up previous compilation artifacts..."
rm -f work-obj*.cf
rm -f *_tb
rm -f *.o
rm -f *.exe

# Compile packages in dependency order
echo "Compiling common packages..."
ghdl -a --std=08 common/*.vhd

echo "Compiling datadef packages..."
ghdl -a --std=08 datadef/*.vhd

echo "Compiling core modules..."
if [ -d "core" ] && [ "$(ls -A core/*.vhd 2>/dev/null)" ]; then
    ghdl -a --std=08 core/*.vhd
else
    echo "  No core modules found - skipping core compilation"
fi

echo "Compiling top-level interface module..."
ghdl -a --std=08 top/probe_driver_interface.vhd

echo "Compiling testbenches..."
if [ -d "tb/common" ] && [ "$(ls -A tb/common/*.vhd 2>/dev/null)" ]; then
    ghdl -a --std=08 tb/common/*.vhd
fi
if [ -d "tb/datadef" ] && [ "$(ls -A tb/datadef/*.vhd 2>/dev/null)" ]; then
    ghdl -a --std=08 tb/datadef/*.vhd
fi
if [ -d "tb/core" ] && [ "$(ls -A tb/core/*.vhd 2>/dev/null)" ]; then
    ghdl -a --std=08 tb/core/*.vhd
fi
if [ -d "tb/top" ] && [ "$(ls -A tb/top/*.vhd 2>/dev/null)" ]; then
    ghdl -a --std=08 tb/top/*.vhd
fi

echo "=== Compilation Complete ==="
echo ""
echo "Available testbenches:"
echo "  - probe_driver_interface_tb (top-level interface test)"
echo ""
echo "To run a testbench:"
echo "  ghdl -e --std=08 <testbench_entity_name>"
echo "  ghdl -r --std=08 <testbench_entity_name>"
echo ""
echo "Example:"
echo "  ghdl -e --std=08 probe_driver_interface_tb"
echo "  ghdl -r --std=08 probe_driver_interface_tb"
echo ""
echo "Note: The 'assertion failed' message at the end is expected - it terminates the simulation."
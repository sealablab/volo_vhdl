# Volo VHDL Project Overview

## Project Purpose
**Volo VHDL** is a VHDL-2008 project designed for **Verilog portability**, targeting FPGA development for Moku devices. The project features an AI-powered workflow, standardized module architecture, and comprehensive build/test infrastructure using GHDL.

## Key Objectives
- VHDL-2008 code that can be easily converted to Verilog
- FPGA bitstream generation for Moku devices
- AI-assisted development workflow for rapid, consistent VHDL development
- Comprehensive testing with GHDL simulator
- Standardized module architecture across the project

## Target Platform
- **Hardware**: Moku devices (custom FPGA-based measurement/control platform)
- **Development**: GHDL simulation and testing
- **Deployment**: MCC (Moku Custom Core) bitstream

## Working Example
**SimpleWaveGen** is a complete, tested reference implementation successfully deployed to a Moku device. It demonstrates the full workflow from GHDL testing to successful hardware deployment.

## Repository Context
- **Git repository**: Yes
- **Current branch**: feature/BPD-01
- **Main branch**: main
- **Platform**: Darwin (macOS) ARM64
- **Location**: /Users/johnycsh/volo_codes/volo_vhdl

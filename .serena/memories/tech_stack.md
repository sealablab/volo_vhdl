# Tech Stack

## Languages and Standards
- **VHDL-2008**: Primary development language with strict Verilog portability rules
- **VHDL Standard**: Always use `--std=08` flag for GHDL compilation

## Tools and Build System
- **GHDL 5.0.1**: VHDL simulator and analyzer
  - Version: GHDL 5.0.1 (4.1.0.r602.g37ad91899) [Dunoon edition]
  - Compiler: GNAT Version: 14.2.0
  - Code generator: llvm 19.1.7
  - Location: /opt/homebrew/bin/ghdl
- **Make**: GNU Make 3.81 for build automation
  - Location: /usr/bin/make
- **Git**: Version control

## Platform
- **OS**: Darwin (macOS)
- **Kernel**: Darwin Kernel Version 25.0.0
- **Architecture**: ARM64 (Apple Silicon)
- **Machine**: arm64

## Libraries and Packages
- **Standard IEEE libraries**: 
  - `std_logic_1164` (std_logic, std_logic_vector)
  - `numeric_std` (unsigned, signed)
- **Work library**: Unified work library shared across all modules

## FPGA Target
- **Platform**: Moku devices
- **Toolchain**: MCC (Moku Custom Core) for bitstream generation
- **Integration**: CustomWrapper interface for platform control

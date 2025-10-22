# Tech Stack

## Languages and Standards
- **VHDL-2008**: Primary development language with strict Verilog portability rules
- **VHDL Standard**: Always use `--std=08` flag for GHDL compilation
- **Python 3.11+**: Testing framework (CocotB)

## Tools and Build System
- **GHDL 5.0.1**: VHDL simulator and analyzer
  - Version: GHDL 5.0.1 (4.1.0.r602.g37ad91899) [Dunoon edition]
  - Compiler: GNAT Version: 14.2.0
  - Code generator: llvm 19.1.7
  - Location: /opt/homebrew/bin/ghdl
  - **Usage**: Simulation backend only (via CocotB)
- **CocotB 2.0.0**: HDL testing framework (NEW - as of 2025-01-22)
  - Python-based coroutine testbenches
  - Location: /opt/homebrew/lib/python3.11/site-packages/cocotb
  - **Status**: Active - preferred for all new tests
- **Make**: GNU Make 3.81 for build automation
  - Location: /usr/bin/make
- **Git**: Version control

## Testing Strategy
- **Current**: CocotB with Python (preferred)
  - Modern async/await syntax
  - Shared test utilities in `tests/conftest.py`
  - Better debugging and CI/CD integration
  - Example: `tests/test_clk_divider_core.py`
- **Legacy**: GHDL testbenches (DEPRECATED)
  - ⚠️ DO NOT CREATE NEW GHDL TESTBENCHES
  - Being phased out in favor of CocotB
  - See `archive/` for old documentation

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
- **CocotB Utilities**: Custom shared fixtures in `tests/conftest.py`

## FPGA Target
- **Platform**: Moku devices
- **Toolchain**: MCC (Moku Custom Core) for bitstream generation
- **Integration**: CustomWrapper interface for platform control

## Migration Status (as of 2025-01-22)
- **✅ Completed**: clk_divider_core (CocotB)
- **🗑️ Archived**: stoplight_core (outdated patterns)
- **⏳ In Progress**: CocotB migration for remaining modules

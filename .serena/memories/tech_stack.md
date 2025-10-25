# Tech Stack

## Core Python Abstractions ⭐

### MokuConfig - THE Central Deployment Model
**Location**: `models/moku/platform_config.py`
**Priority**: CRITICAL - Load in every context window
**Purpose**: Single source of truth for deployment specifications

**Key Models**:
- `MokuConfig` - Top-level deployment spec (slots + routing + platform)
- `SlotConfig` - Per-slot instrument configuration
- `MokuConnection` - Signal routing specification
- `MokuGoPlatform` - Physical hardware specification

**Consumers**:
- `tools/moku_go.py` - CLI deployment tool
- CocotB tests (future) - Simulation setup
- Config generators - Deployment automation

**See**: Serena memory `mokuconfig_core_abstraction` for complete details

### Supporting Python Models

**Infrastructure Models** (`models/bench/`):
- `BenchBench` - Physical bench infrastructure (wiring, PDU, DUT)
- `PhysicalWiring` - Cable connections with direction validation
- `WiredDevice` - Device signal with validation
- `PDU` - Power distribution unit
- `DUT` - Device under test

**Device Models** (`models/riscure/`, `models/dummy/`):
- `DS1120A` - EMFI probe physical interface
- `DummyProbe` - Unknown device placeholder
- Device Catalog - Centralized device registry

**Platform Models** (`models/moku/`):
- `MokuGoPlatform` - Moku:Go hardware specifications
- `MokuDeviceInfo` - Network discovery metadata
- `MokuDeviceCache` - Device name→IP resolution

**See**: Serena memory `mokuconfig_and_benchbench_framework` for relationships

---

## Languages and Standards
- **VHDL-2008**: Primary development language with strict Verilog portability rules
- **VHDL Standard**: Always use `--std=08` flag for GHDL compilation
- **Python 3.11+**: Testing framework (CocotB) and Pydantic models

## Python Dependencies
- **Pydantic 2.0+**: Data validation and type safety for all models
- **CocotB 2.0.0**: HDL testing framework
- **Moku Library 3.0+**: Hardware deployment via MCC API
- **Typer**: CLI framework for `tools/moku_go.py`
- **Rich**: Terminal formatting and progress displays
- **Zeroconf**: Network device discovery

**Install with**:
```bash
uv sync --no-install-project
```

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
- **UV**: Python package manager (replaces pip/virtualenv)
  - Fast dependency resolution
  - Project-based environments
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
- **Platform**: Moku devices (Moku:Go, Moku:Lab, Moku:Pro)
- **Toolchain**: MCC (Moku Custom Core) for bitstream generation
- **Integration**: CustomWrapper interface for platform control
- **Deployment**: `tools/moku_go.py` CLI tool with MokuConfig

## Deployment Workflow
1. **Design**: VHDL module with MCC integration (CustomWrapper)
2. **Test Locally**: CocotB simulation with GHDL backend
3. **Package**: `scripts/build_mcc_package.py` creates CloudCompile zip
4. **Synthesize**: Upload to Moku Cloud Compile web interface
5. **Import**: `scripts/import_mcc_build.py` stages bitstream
6. **Deploy**: `tools/moku_go.py deploy` using MokuConfig
7. **Validate**: Hardware testing with same CocotB tests (future)

## Migration Status (as of 2025-10-25)
- **✅ Completed**: 
  - clk_divider_core (CocotB)
  - MokuConfig promotion (Pydantic models)
  - moku_go.py deployment tool
- **🗑️ Archived**: 
  - stoplight_core (outdated patterns)
  - Old BenchConfig monolith
- **⏳ In Progress**: 
  - CocotB migration for remaining modules
  - Moku Platform Simulator expansion

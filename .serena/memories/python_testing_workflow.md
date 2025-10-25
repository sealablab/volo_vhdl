# Python Testing Workflow (UV + CocotB + MokuBench)

**Created**: 2025-10-24  
**Last Updated**: 2025-10-24

## Overview

Complete workflow for Python-based testing infrastructure including UV dependency management, CocotB simulation, and MokuBench hardware deployment.

---

## 1. UV Python Environment Setup

### What is UV?

UV is a fast, modern Python package manager that replaces pip/virtualenv/pip-tools:
- **10-100× faster** than pip
- **Reproducible** dependency resolution
- **Compatible** with standard Python packaging (pyproject.toml)
- **Documentation**: https://docs.astral.sh/uv/

### Installation

```bash
# macOS/Linux
brew install uv

# Or via pip
pip install uv
```

### Project Dependencies

All dependencies are defined in `pyproject.toml`:

```toml
[project]
name = "volo-vhdl"
requires-python = ">=3.11"

dependencies = [
    "cocotb>=1.8.0",          # Testing framework
    "pydantic>=2.0.0",        # Bench framework validation
    "moku>=3.0.0",            # Hardware backend (Moku API)
    "pyyaml>=6.0.0",          # MCC package builder
    "numpy>=1.24.0",          # Data analysis
]
```

### First-Time Setup

```bash
# From project root
cd /path/to/volo_vhdl/

# Sync dependencies (creates .venv and installs packages)
uv sync --no-install-project

# Verify installation
uv pip list | grep -E "(cocotb|moku|pydantic)"
```

**Output**:
```
cocotb       2.0.0
moku         3.3.1
pydantic     2.10.5
```

### Virtual Environment Location

- **Path**: `.venv/` in project root
- **Python**: 3.12.8 (or whatever system Python >=3.11)
- **Activation**: Not needed when using `uv run`

---

## 2. Running Tests with UV

### CocotB Simulation Tests

**ALWAYS use `uv run` to ensure correct environment:**

```bash
# Navigate to tests directory
cd tests/

# Run specific module test
uv run make TEST_MODULE=clk_divider_core

# Run all tests (if target exists)
uv run make test-all

# Run with waveforms
WAVES=1 uv run make TEST_MODULE=buffer_waveform_gen

# Run without waveforms (faster)
WAVES=0 uv run make TEST_MODULE=buffer_waveform_gen
```

**Why `uv run`?**
- Automatically activates `.venv` environment
- Ensures correct Python version (>=3.11)
- No need to manually source activate scripts
- Works consistently across platforms

### MokuBench Hardware Tests

**Pattern**: `uv run python tests/test_<module>_hardware.py`

```bash
# From project root
uv run python tests/test_buffer_waveform_hardware.py --ip 192.168.13.159

# With debug output
uv run python tests/test_buffer_waveform_hardware.py --ip 192.168.13.159 --debug

# Custom bitstream path
uv run python tests/test_buffer_waveform_hardware.py \
    --ip 192.168.13.159 \
    --bitstream modules/my_module/bitstream.tar
```

### Python Scripts (MCC Package Builder, etc.)

```bash
# Build CloudCompile package
uv run python scripts/build_mcc_package.py modules/buffer_waveform_gen

# Any other Python script
uv run python scripts/my_script.py
```

---

## 3. Common Issues and Solutions

### Issue 1: "No module named 'pydantic'" or similar

**Symptom**: Import errors when running tests  
**Cause**: Dependencies not synced  
**Solution**:
```bash
uv sync --no-install-project
```

### Issue 2: "Moku Python API not available"

**Symptom**: `ImportError` when using MokuBench  
**Cause**: moku package not installed OR wrong instrument names  
**Solution**:
```bash
# Check if installed
uv pip list | grep moku

# Should show: moku  3.3.1

# If not installed, sync dependencies
uv sync --no-install-project
```

**Known Issue (Fixed 2025-10-24)**: 
- `hardware.py` was importing `FIRFilterBuilder` (doesn't exist)
- Correct name: `FIRFilterBox`
- Fixed in commit

### Issue 3: UV using wrong Python environment

**Symptom**: `uv pip list` shows packages from miniforge3/conda instead of `.venv`  
**Cause**: UV checking global environment instead of project .venv  
**Why it's OK**: `uv run` still uses the correct .venv for execution

**Verification**:
```bash
# Check .venv Python version
source .venv/bin/activate
python --version  # Should show 3.12.x
pip list | grep moku
deactivate

# Or use uv run directly
uv run python --version
uv run python -c "import moku; print('✓ Moku available')"
```

### Issue 4: CocotB not finding DUT modules

**Symptom**: `make TEST_MODULE=...` fails with import errors  
**Cause**: GHDL work directory or source paths incorrect  
**Solution**: Check `tests/Makefile` for correct VHDL_SOURCES paths

---

## 4. Bench Configuration Framework

### Architecture

The Bench Framework provides **unified configuration** for both simulation and hardware:

```python
from tests.moku_platform_simulator import BenchConfig, SlotConfig, Connection
from tests.moku_platform_simulator.config import MOKU_GO
from tests.moku_platform_simulator.hardware import HardwareBackend  # Real hardware
from tests.moku_platform_simulator.simulation import SimulationBackend  # CocotB sim

# Same config works for BOTH backends!
config = MokuPlatformConfig(
    platform=MOKU_GO,
    slots={
        1: SlotConfig(
            instrument='CloudCompile',
            bitstream='my_module.tar',
            control_registers={
                0: 0xE0640000  # MCC_READY + Enable + ClkEn + Div=100
            }
        ),
        2: SlotConfig(
            instrument='Oscilloscope',
            settings={'timebase': (-5e-3, 5e-3)}
        )
    },
    connections=[
        Connection(source='Slot1OutA', destination='Slot2InA')
    ]
)
```

### Hardware Backend Usage

```python
import asyncio

async def test_hardware():
    # Create backend
    backend = HardwareBackend.from_config(
        config, 
        ip_address='192.168.13.159'
    )
    
    # Deploy to Moku
    await backend.setup()  # Connects, deploys, routes, configures
    
    # Run and collect data
    data = await backend.run(duration_ms=100)
    
    # Access instruments
    osc = backend.get_instrument('Oscilloscope')
    osc_data = data[2]  # Slot 2
    
    # Cleanup
    await backend.teardown()

# Run
asyncio.run(test_hardware())
```

### Control Register Helpers

**Always use `mcc_cr0()` helper** for Control0 (3-bit control scheme):

```python
from conftest import mcc_cr0

# Correct usage
SlotConfig(
    instrument='CloudCompile',
    control_registers={
        0: mcc_cr0(divider=240),  # Returns 0xEEF00000
        1: 0x043C7D00              # Module params
    }
)

# ❌ WRONG - Missing bit 29 (ClkEn)
control_registers={
    0: 0xC0640000  # MODULE WILL FREEZE!
}
```

**mcc_cr0() signature**:
```python
def mcc_cr0(divider=0, extra_bits=0):
    """
    Returns: 0xE0000000 | (divider << 16) | extra_bits
    
    Bit 31: MCC_READY = 1
    Bit 30: Enable = 1
    Bit 29: ClkEn = 1 (⚠️ CRITICAL!)
    Bits 23:16: Clock divider (0-255)
    """
```

---

## 5. File Locations

### Core Files

- **Dependencies**: `pyproject.toml` (project root)
- **UV Setup Doc**: `docs/UV_SETUP.md`
- **Test Directory**: `tests/`
- **Bench Framework**: `tests/moku_platform_simulator/`
- **Test Utilities**: `tests/conftest.py`

### Bench Framework Modules

```
tests/moku_platform_simulator/
├── __init__.py
├── backend.py          # Abstract Backend class
├── config.py           # BenchConfig, SlotConfig, Connection
├── hardware.py         # HardwareBackend (Moku API)
├── simulation.py       # SimulationBackend (CocotB)
└── simulators/
    └── oscilloscope.py  # Oscilloscope simulator
```

### Test Patterns

```
tests/
├── conftest.py                          # Shared utilities (mcc_cr0, etc.)
├── test_<module>_core.py                # CocotB unit tests
├── test_<module>_hardware.py            # MokuBench hardware tests
└── test_bench_framework_poc.py          # Framework tests
```

---

## 6. Workflow Examples

### Example 1: Add New Dependency

```bash
# Add package
uv add numpy

# Package added to pyproject.toml automatically
# .venv updated automatically

# Commit changes
git add pyproject.toml uv.lock
git commit -m "Add numpy for data analysis"
```

### Example 2: Create New Hardware Test

```python
#!/usr/bin/env python3
"""tests/test_my_module_hardware.py"""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from tests.moku_platform_simulator import BenchConfig, SlotConfig
from tests.moku_platform_simulator.config import MOKU_GO
from tests.moku_platform_simulator.hardware import HardwareBackend
from conftest import mcc_cr0

async def main():
    config = MokuPlatformConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                bitstream='modules/my_module/bitstream.tar',
                control_registers={0: mcc_cr0(divider=100)}
            )
        }
    )
    
    backend = HardwareBackend.from_config(config, ip_address='192.168.13.159')
    await backend.setup()
    data = await backend.run(duration_ms=100)
    await backend.teardown()

if __name__ == '__main__':
    asyncio.run(main())
```

Run:
```bash
uv run python tests/test_my_module_hardware.py
```

### Example 3: CocotB Test with Bench Framework

```python
import cocotb
from conftest import setup_clock, reset_active_low, mcc_cr0
from tests.moku_platform_simulator import BenchConfig, SlotConfig
from tests.moku_platform_simulator.simulation import SimulationBackend

@cocotb.test()
async def test_my_module(dut):
    await setup_clock(dut)
    await reset_active_low(dut)
    
    config = MokuPlatformConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                control_registers={0: mcc_cr0()}
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'channels': ['output']}
            )
        }
    )
    
    backend = SimulationBackend.from_config(config, dut)
    await backend.setup()
    data = await backend.run(duration_ms=1.0)
    
    osc = backend.get_instrument('Oscilloscope')
    assert osc.verify_incrementing('output', count=10)
```

Run:
```bash
cd tests/
uv run make TEST_MODULE=my_module
```

---

## 7. Moku API Instruments (Available in moku 3.3.1)

**Verified instrument names** (import from `moku.instruments`):

```python
from moku.instruments import (
    MultiInstrument,              # Multi-instrument mode manager
    Oscilloscope,                 # 2-channel oscilloscope
    WaveformGenerator,            # Arbitrary waveform generator
    CloudCompile,                 # Custom FPGA bitstreams
    Datalogger,                   # High-speed data logger
    SpectrumAnalyzer,             # Frequency domain analysis
    LogicAnalyzer,                # Digital signal analyzer
    Phasemeter,                   # Phase/frequency measurement
    LockInAmp,                    # Lock-in amplifier
    PIDController,                # PID controller
    FrequencyResponseAnalyzer,    # Bode plots, impedance
    DigitalFilterBox,             # IIR/FIR filters
    FIRFilterBox,                 # FIR filter designer ⚠️ NOT FIRFilterBuilder!
    ArbitraryWaveformGenerator,   # AWG with LUT
    TimeFrequencyAnalyzer,        # Time-frequency analysis
    LaserLockBox,                 # Laser frequency stabilization
    NeuralNetwork,                # Neural network inference
)
```

**⚠️ Common Mistake**: Importing `FIRFilterBuilder` (doesn't exist) instead of `FIRFilterBox`

---

## 8. CloudCompile Routing Constraints

**CloudCompile outputs** (Moku:Go/Lab/Pro):
- ✅ `Slot1OutA` - Output channel A
- ✅ `Slot1OutB` - Output channel B
- ❌ `Slot1OutC` - **Does NOT exist**
- ❌ `Slot1OutD` - **Does NOT exist**

**Valid routing**:
```python
Connection(source='Slot1OutA', destination='Slot2InA'),  # ✓
Connection(source='Slot1OutB', destination='Slot2InB'),  # ✓
```

**Invalid routing**:
```python
Connection(source='Slot1OutD', destination='Slot2InB'),  # ❌ ERROR!
```

**Implication**: Debug outputs (like OutputD status bits) cannot be routed to oscilloscope. Use OutputA or OutputB for debugging.

---

## 9. Checklist for New Tests

### CocotB Simulation Test

- [ ] Create `test_<module>_core.py` in `tests/`
- [ ] Add entry to `tests/Makefile` with VHDL_SOURCES
- [ ] Import utilities from `conftest.py`
- [ ] Use `await setup_clock()` and `await reset_*()` helpers
- [ ] Run: `uv run make TEST_MODULE=<module>`
- [ ] Verify: "ALL TESTS PASSED" in output

### MokuBench Hardware Test

- [ ] Bitstream exists at `modules/<module>/*.tar`
- [ ] Create `test_<module>_hardware.py` in `tests/`
- [ ] Import `HardwareBackend` from `bench_framework`
- [ ] Use `mcc_cr0()` helper for Control0
- [ ] Only route to OutA/OutB (not OutC/OutD)
- [ ] Run: `uv run python tests/test_<module>_hardware.py --ip <IP>`
- [ ] Verify: Test completes without exceptions

---

## 10. Related Documentation

- **UV Setup**: `docs/UV_SETUP.md`
- **CocotB Testing**: `cocotb_testing_guide` (Serena memory)
- **Bench Framework**: `bench_config_framework` (Serena memory)
- **MCC Debugging**: `mcc_debugging_techniques` (Serena memory)
- **Design Patterns**: `design_patterns` (Serena memory) - MCC 3-bit control scheme

---

## 11. Quick Reference Commands

```bash
# ========== UV Environment ==========
uv sync --no-install-project           # Sync dependencies
uv add <package>                       # Add new dependency
uv pip list                            # List installed packages

# ========== CocotB Tests ==========
cd tests/
uv run make TEST_MODULE=clk_divider_core
uv run make TEST_MODULE=buffer_waveform_gen
WAVES=1 uv run make TEST_MODULE=...   # With waveforms

# ========== Hardware Tests ==========
uv run python tests/test_buffer_waveform_hardware.py --ip 192.168.13.159
uv run python tests/test_my_module_hardware.py --ip <IP> --debug

# ========== MCC Packaging ==========
uv run python scripts/build_mcc_package.py modules/<module>

# ========== Verification ==========
uv run python -c "import moku; print('✓ Moku API available')"
uv run python -c "import cocotb; print('✓ CocotB available')"
uv run python -c "from conftest import mcc_cr0; print(f'mcc_cr0() = 0x{mcc_cr0():08X}')"
```

---

## 12. Troubleshooting Checklist

**Import errors?**
1. Run `uv sync --no-install-project`
2. Verify `.venv/` exists
3. Check `uv run python -c "import <package>"`

**CocotB tests failing?**
1. Check `tests/Makefile` VHDL_SOURCES paths
2. Ensure using `uv run make`
3. Review `tests/conftest.py` for helpers

**Hardware deployment errors?**
1. Verify bitstream path exists
2. Check IP address reachable (ping)
3. Review Control0 value (use `mcc_cr0()`)
4. Validate routing (only OutA/OutB)

**Static waveform output?**
1. Verify MCC_READY + Enable + ClkEn all set
2. Check clock divider value
3. Confirm buffer loaded correctly
4. Inspect FPGA status outputs

---

**Last Updated**: 2025-10-24  
**Test Status**: buffer_waveform_gen deployed successfully, buffer loading protocol verified

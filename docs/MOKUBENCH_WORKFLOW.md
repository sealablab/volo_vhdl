# MokuBench Deployment Workflow

Complete workflow for deploying VHDL modules to Moku hardware using the Bench Framework.

## Overview

**MokuBench** = Hardware deployment backend for Bench Framework
- Uses Moku Multi-Instrument Mode API
- Deploys custom VHDL via CloudCompile
- Same BenchConfig as simulation (SimBench)
- Workflow: Design → SimBench (local test) → MokuBench (hardware)

---

## Phase 3 Milestones

### ✅ Milestone 1: Connection Test (CURRENT)
- Connect to Moku device
- Initialize MultiInstrument mode
- Verify connectivity
- **Status**: Test script ready (`tests/mokubench_connection_test.py`)

### 🔲 Milestone 2: BitStream Build & Upload
- Package VHDL for CloudCompile
- Upload to Moku Cloud Compile service
- Download synthesized bitstream
- **Status**: Build script ready (`modules/simple_counter/build_cloudcompile.sh`)

### 🔲 Milestone 3: Minimal Deployment
- Implement HardwareBackend.setup()
- Deploy CloudCompile bitstream to slot
- Set control registers
- Verify deployment

### 🔲 Milestone 4: Full MokuBench
- Add Oscilloscope data collection
- Implement connection routing
- Compare SimBench vs MokuBench results
- Complete Phase 3!

---

## Complete Workflow

### Step 1: Build CloudCompile Package

```bash
# Navigate to module
cd modules/simple_counter/

# Run build script (creates cloudcompile_package/)
./build_cloudcompile.sh

# Output:
# ✓ Package ready: cloudcompile_package/
# ✓ GHDL compilation test passed
```

**What it does**:
- Copies: `mcc-Top.vhd`, `simple_counter_core.vhd`, `Top.vhd`
- Creates `README.txt` with documentation
- Tests compilation with GHDL
- Ready for CloudCompile upload

### Step 2: Upload to Moku Cloud Compile

```bash
# Create zip for upload
cd cloudcompile_package/
zip -r simple_counter.zip *.vhd

# Upload via web interface
# URL: https://cloud-compile.liquidinstruments.com/
```

**CloudCompile Web Interface**:
1. Navigate to https://cloud-compile.liquidinstruments.com/
2. Click "New Project"
3. Upload `simple_counter.zip`
4. Select platform (Moku:Go / Moku:Pro)
5. Click "Synthesize"
6. Wait ~5-10 minutes (Vivado synthesis)
7. Download `simple_counter.tar.gz` bitstream

**Store bitstream**: `bitstreams/simple_counter.tar.gz`

### Step 3: Test Moku Connection

```bash
# Run connection test (Milestone 1)
cd tests/
uv run python mokubench_connection_test.py --ip 192.168.1.100 --platform 2

# Expected output:
# [1/5] Connecting to Moku...
# [2/5] Querying platform info...
# [3/5] Checking available slots...
# [4/5] Verifying MultiInstrument mode...
# [5/5] Disconnecting...
# ✓ ALL TESTS PASSED
```

**Troubleshooting**:
- Verify Moku powered on and on network
- Check IP address (ping test)
- Check firewall settings
- Use `force_connect=True` if device shows "in use"

### Step 4: Deploy with MokuBench

```python
# Create bench configuration (same as SimBench!)
from bench_framework import HardwareBackend, BenchConfig, SlotConfig, Connection
from bench_framework.config import MOKU_GO

config = BenchConfig(
    platform=MOKU_GO,
    slots={
        1: SlotConfig(
            instrument='CloudCompile',
            bitstream='bitstreams/simple_counter.tar.gz',
            control_registers={
                0: 0xE0000000  # MCC_READY + Enable + ClkEn
            }
        ),
        2: SlotConfig(
            instrument='Oscilloscope',
            settings={'timebase': (-5e-3, 5e-3)}
        )
    },
    connections=[
        Connection(source='Slot1OutA', destination='Slot2InA'),  # Counter → Scope
    ]
)

# Deploy to hardware
bench = HardwareBackend.from_config(config, ip='192.168.1.100')
bench.setup()  # Deploy bitstream, configure instruments, establish routing
data = bench.run(duration_ms=100)  # Capture data

# Access oscilloscope data
osc = bench.get_instrument('Oscilloscope')
print(f"Captured samples: {len(osc_data['ch1'])}")
```

### Step 5: Compare SimBench vs MokuBench

```python
import asyncio
from bench_framework import SimulationBackend, HardwareBackend

# Same config for both!
config = BenchConfig(...)

# Test in simulation first
async def sim_test():
    sim_bench = SimulationBackend.from_config(config, dut)
    await sim_bench.setup()
    sim_data = await sim_bench.run(duration_ms=100)
    return sim_data

# Deploy to hardware
def hw_test():
    hw_bench = HardwareBackend.from_config(config, ip='192.168.1.100')
    hw_bench.setup()
    hw_data = hw_bench.run(duration_ms=100)
    return hw_data

# Compare results
sim_result = asyncio.run(sim_test())
hw_result = hw_test()

# Verify behavior matches (within ADC/DAC quantization)
assert_similar(sim_result, hw_result)
```

---

## Control Register Convention

### Standard Mapping (All MokuBench Modules)

```
Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
Control0[30]:    User Enable (1=enable, 0=disable)
Control0[29:0]:  Module-specific configuration
Control1-31:     User-defined parameters
```

### Simple Counter Example

```python
# Python
mcc.set_control(0, 0xE0000000)
# Bits: 31=1 (MCC_READY), 30=1 (Enable), 29=1 (ClkEn)

# VHDL (Top.vhd)
mcc_ready    <= Control0(31);
user_enable  <= Control0(30);
user_clk_en  <= Control0(29);
global_enable <= mcc_ready and user_enable;  # Safe enable logic
```

**Why Control0[31]?**
During FPGA bitstream load, all registers start at `0x00000000`. Network delay (10-200ms) before config arrives. Using bit 31 as MCC_READY ensures module stays disabled during all-zero state, preventing glitches.

---

## Directory Structure

```
volo_vhdl/
├── modules/
│   └── simple_counter/
│       ├── core/
│       │   └── simple_counter_core.vhd          # Core logic
│       ├── top/
│       │   └── Top.vhd                          # CustomWrapper architecture
│       ├── build_cloudcompile.sh                # Package build script
│       └── cloudcompile_package/                # Ready for upload
│           ├── mcc-Top.vhd                      # CustomWrapper entity
│           ├── simple_counter_core.vhd          # Core (copy)
│           ├── Top.vhd                          # Architecture (copy)
│           └── README.txt                       # Upload instructions
├── bitstreams/
│   └── simple_counter.tar.gz                    # Downloaded from CloudCompile
├── tests/
│   ├── bench_framework/                         # Framework code
│   │   ├── config.py                            # BenchConfig models
│   │   ├── backend.py                           # Backend ABC
│   │   ├── simulation.py                        # SimBench
│   │   └── hardware.py                          # MokuBench
│   ├── mokubench_connection_test.py             # Milestone 1 test
│   └── test_mokubench_simple_counter.py         # Full deployment test
└── docs/
    ├── BENCH_FRAMEWORK_DESIGN.md                # Framework design
    └── MOKUBENCH_WORKFLOW.md                    # This file
```

---

## Common Issues

### CloudCompile Upload Fails
- **Check**: VHDL files are VHDL-2008 compliant
- **Check**: All files use IEEE standard libraries
- **Check**: No syntax errors (test with `ghdl -a`)
- **Fix**: Run `build_cloudcompile.sh` to verify local compilation

### Bitstream Deployment Fails
- **Check**: Bitstream matches platform (Moku:Go vs Moku:Pro)
- **Check**: Bitstream file path is correct
- **Check**: Moku has space for bitstream (~10-50 MB)
- **Fix**: Verify with `mokubench_connection_test.py` first

### Module Not Responding
- **Check**: Control0[31] (MCC_READY) is set to 1
- **Check**: Control registers match VHDL expectations
- **Check**: Connections route signals correctly
- **Fix**: Read back Control0 with `mcc.get_control(0)`

### Oscilloscope Shows No Signal
- **Check**: Connection routing (source → destination)
- **Check**: Module outputs are non-zero
- **Check**: Timebase settings appropriate for signal
- **Fix**: Test with static output first (e.g., `OutputA <= x"FFFF"`)

---

## Next Steps (Milestone 2 & 3)

**You are here**: Package built, ready for CloudCompile upload

**Next**:
1. **Upload** `simple_counter.zip` to CloudCompile
2. **Download** `simple_counter.tar.gz` bitstream
3. **Test** connection with `mokubench_connection_test.py`
4. **Implement** `HardwareBackend.setup()` method
5. **Deploy** with full MokuBench workflow!

---

## References

- **Bench Framework Design**: `docs/BENCH_FRAMEWORK_DESIGN.md`
- **CloudCompile API**: Serena memory `instrument_cloud_compile.md`
- **MCC Routing**: Serena memory `mcc_routing_concepts.md`
- **Platform Models**: Serena memory `platform_models.md`
- **Simple Counter Source**: `modules/simple_counter/`

# Platform Models - Quick Reference

## Overview
This project now includes **platform hardware models** for all four Moku devices to support high-fidelity testbenches and accurate block diagrams.

**Key Principle**: CustomWrapper modules are **platform-agnostic**. These models define the physical reality of each device, NOT portability constraints.

## CustomWrapper Interface (Standard Across ALL Platforms)

**IMPORTANT**: The CustomWrapper entity is **identical** on all platforms:

```vhdl
entity CustomWrapper is
    port (
        Clk     : in  std_logic;
        Reset   : in  std_logic;

        -- 4 analog inputs (signed 16-bit)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        InputD  : in  signed(15 downto 0);

        -- 4 analog outputs (signed 16-bit)
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        OutputD : out signed(15 downto 0);

        -- 32 control registers (std_logic_vector 32-bit)
        Control0  : in  std_logic_vector(31 downto 0);
        -- ... Control1-30 ...
        Control31 : in  std_logic_vector(31 downto 0);
    );
end entity CustomWrapper;
```

**MCC Routing**: Physical ADC/DAC channels (2-8 per platform) are **mapped** to virtual CustomWrapper I/O via user-configurable MCC routing.

---

## Quick Comparison

| Platform       | Slots | Physical ADC | Physical DAC | Virtual I/O per Slot | Control Regs | DIO  | Target Use        |
|----------------|-------|--------------|--------------|----------------------|--------------|------|-------------------|
| **Moku:Go**    | 2     | 2ch 12-bit 125MS/s | 2ch 12-bit 125MS/s | 4 in / 4 out | 32 (CR0-31) | 16   | Education, portable |
| **Moku:Lab**   | 2     | 2ch 12-bit 500MS/s | 2ch 16-bit 1GS/s   | 4 in / 4 out | 32 (CR0-31) | Trig | Research benchtop |
| **Moku:Pro**   | 4     | 4ch 18-bit† 1.25GS/s | 4ch 16-bit 1.25GS/s | 4 in / 4 out | 32 (CR0-31) | -    | High-performance |
| **Moku:Delta** | 8     | 8ch 20-bit† 5GS/s | 8ch 14-bit 10GS/s   | 4 in / 4 out | 32 (CR0-31) | 32   | Ultimate performance |

† *Blended ADC (dual bit-depth for wide dynamic range)*

**Key Insight**: All slots have **4 virtual inputs, 4 virtual outputs, 32 control registers** regardless of physical channel count. MCC routing maps physical I/O to virtual I/O.

---

## Using in CocotB Tests

### Basic Example
```python
import cocotb
from platform_models import MOKU_GO, get_platform
from conftest import setup_clock, reset_active_high

@cocotb.test()
async def test_on_moku_go(dut):
    """Test with Moku:Go timing characteristics"""
    platform = MOKU_GO

    # Use platform-appropriate clock (125 MHz for Moku:Go)
    await setup_clock(dut, period_ns=platform['clk_period_ns'])
    await reset_active_high(dut)

    dut._log.info(f"Testing on {platform['name']}")
    dut._log.info(f"  Slots: {platform['slots']}")
    dut._log.info(f"  Physical ADC: {platform['physical_adc_channels']}ch @ {platform['adc_bits']}-bit")
    dut._log.info(f"  Virtual I/O: {platform['virtual_inputs_per_slot']} inputs, {platform['virtual_outputs_per_slot']} outputs")

    # Test all 4 virtual inputs (even if platform has fewer physical ADCs)
    dut.InputA.value = 0x1234
    dut.InputB.value = 0x5678
    dut.InputC.value = 0xABCD
    dut.InputD.value = 0xEF00

    # Your test logic here...
```

### Platform-Agnostic Testing
```python
import os
from platform_models import get_platform

@cocotb.test()
async def test_cross_platform(dut):
    """Test on target platform from environment variable"""
    target = os.getenv('TARGET_PLATFORM', 'go')  # Default to Moku:Go
    platform = get_platform(target)

    await setup_clock(dut, period_ns=platform['clk_period_ns'])
    # ... test logic
```

Run with:
```bash
TARGET_PLATFORM=lab make TEST_MODULE=my_module
TARGET_PLATFORM=delta make TEST_MODULE=my_module
```

---

## Files Created

### 1. **Serena Memory**: `platform_models.md`
**Location**: Serena memory (access via `mcp__serena__read_memory`)
**Content**:
- Detailed specifications table
- Architecture notes (CustomWrapper slots, MCC routing)
- Testbench integration strategy
- Platform-specific details (form factor, key features)
- Block diagram examples

**When to read**: Understanding platform differences, writing documentation, creating diagrams

### 2. **Python Constants**: `tests/platform_models.py`
**Location**: `/tests/platform_models.py`
**Content**:
- Python dictionaries (`MOKU_GO`, `MOKU_LAB`, `MOKU_PRO`, `MOKU_DELTA`)
- Helper function `get_platform(name)` for flexible lookup
- Helper function `get_clock_freq_mhz(platform)` for calculations

**When to use**: Writing CocotB tests, scripting, automation

---

## CustomWrapper Abstraction

### What CustomWrapper Provides
CustomWrapper is the **platform-agnostic interface**:
- Standard ports: `Clk`, `Reset`, `InputA`, `InputB`, `OutputA`, `OutputB`, `Control0-N`, `Output0-M`
- MCC handles all platform-specific details (bit widths, routing, synthesis)
- Your module **does not need** platform-specific code

### What Platform Models Provide
Platform models inform **testbench realism**:
- Clock periods matching actual synthesis frequencies
- Expected bit widths for overflow testing
- Number of slots for multi-instrument scenarios
- Physical constraints for documentation/diagrams

**Golden Rule**: Write modules to CustomWrapper standard. Use platform models for testing accuracy, not for conditional logic in RTL.

---

## MCC Routing (Conceptual)

MCC provides **dynamic signal routing** between slots and physical I/O:

```
┌─────────────────────────────────────────────┐
│  Moku:Pro (4 Slots)                         │
│                                             │
│  Physical ADCs (IN1-4)                      │
│         │ │ │ │                             │
│  ┌──────▼─▼─▼─▼──────────────┐ MCC Routing │
│  │  ┌──────┐  ┌──────┐       │             │
│  │  │Slot1 │  │Slot2 │       │ User config │
│  │  └──┬───┘  └───┬──┘       │ via GUI/API │
│  │     │          │           │             │
│  │  ┌──▼───┐  ┌──▼───┐       │             │
│  │  │Slot3 │  │Slot4 │       │             │
│  │  └──────┘  └──────┘       │             │
│  └──────┬─┬─┬─┬───────────────┘             │
│         │ │ │ │                             │
│  Physical DACs (OUT1-4)                     │
└─────────────────────────────────────────────┘
```

**Implications for Testing**:
- Single-module tests: Focus on CustomWrapper interface
- Multi-slot tests (future): Model simplified routing between slot instances

---

## Block Diagram Guidelines

When creating system diagrams:

1. **Show platform** (Go/Lab/Pro/Delta) as outer box
2. **Show physical I/O** (BNC connectors for ADC/DAC)
3. **Show N slots** as CustomWrapper execution contexts
4. **Show your module** inside a slot
5. **Indicate MCC routing** (dashed lines, labeled as "MCC")

**Example** (Moku:Go with one active module):
```
┌─────────────────────────────────────┐
│  Moku:Go                            │
│  ┌───────┐  ┌───────┐   (Physical) │
│  │ IN1   │  │ IN2   │      BNCs    │
│  └───┬───┘  └───┬───┘              │
│      │          │                   │
│   ┌──▼──────────▼──────────┐ MCC   │
│   │  Slot 1: YourModule    │       │
│   │  (CustomWrapper)       │       │
│   │                        │       │
│   │  Slot 2: (Empty)       │       │
│   └──┬──────────┬──────────┘       │
│      │          │                   │
│  ┌───▼───┐  ┌───▼───┐              │
│  │ OUT1  │  │ OUT2  │   (BNCs)     │
│  └───────┘  └───────┘              │
└─────────────────────────────────────┘
```

---

## Next Steps

### For Current Work
- ✅ Platform specs documented (Serena + Python)
- ✅ CocotB integration ready (`tests/platform_models.py`)
- 🔲 **Optional**: Add platform info to existing test docstrings
- 🔲 **Optional**: Update `tests/README.md` with platform model usage

### For Future Enhancements
- 🔲 Parse Vivado synthesis logs to extract **actual clock rates**
- 🔲 Multi-slot testbenches (simulate inter-slot communication)
- 🔲 Platform-specific CI/CD (run tests with all platform timings)

---

## FAQ

**Q: Do I need to modify my VHDL modules for different platforms?**
A: No! CustomWrapper abstraction ensures portability. Platform models are for **testing realism only**.

**Q: Which platform should I test against?**
A: Start with your **deployment target**. If unknown, use **Moku:Go** (most conservative timing) or **Moku:Lab** (common research platform).

**Q: How accurate are the clock periods?**
A: They're **estimates** based on sample rates. Actual synthesis clocks depend on MCC/Vivado. Extract real values from build logs for precision.

**Q: Can I run the same module on all platforms?**
A: Yes! That's the power of CustomWrapper. MCC handles platform-specific synthesis, routing, and optimization.

**Q: What if my module needs platform-specific features?**
A: Use **generics** for configurable behavior (e.g., `NUM_CHANNELS`). Let MCC set generic values at synthesis, not your code.

---

## Resources

- **Serena Memory**: `mcp__serena__read_memory` → `platform_models`
- **Python Constants**: `tests/platform_models.py`
- **Datasheets**: `mcc_datasheets/*.pdf`
- **Testing Guide**: `tests/README.md` (CocotB framework)
- **Project Overview**: `CLAUDE.md` (CustomWrapper patterns)

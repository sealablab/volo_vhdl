# Moku Platform Models

## Purpose
This document provides **physical hardware specifications** for all Moku platforms to support:
1. **High-fidelity testbenches** (CocotB tests matching real hardware)
2. **Block diagrams** reflecting actual device architecture
3. **Performance expectations** for deployed CustomWrapper modules

**Key Concept**: CustomWrapper modules are **platform-agnostic**. They run in "slots" provided by MCC. The differences below reflect the physical resources available and synthesis performance, NOT module portability constraints.

---

## CustomWrapper Interface (Standard Across All Platforms)

**IMPORTANT**: The CustomWrapper entity is **identical** on all platforms. MCC provides this standard interface:

```vhdl
entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;

        -- Input signals (ADC data, signed 16-bit)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        InputD  : in  signed(15 downto 0);

        -- Output signals (DAC data, signed 16-bit)
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        OutputD : out signed(15 downto 0);

        -- Control registers (32-bit each, from Moku platform)
        Control0  : in  std_logic_vector(31 downto 0);
        Control1  : in  std_logic_vector(31 downto 0);
        -- ... (Control2-30) ...
        Control31 : in  std_logic_vector(31 downto 0);
    );
end entity CustomWrapper;
```

**Key Points**:
- **4 analog inputs** (InputA/B/C/D) - MCC routes physical ADCs to these
- **4 analog outputs** (OutputA/B/C/D) - MCC routes these to physical DACs
- **32 control registers** (Control0-31) - User-configurable via Moku GUI/API
- **16-bit signed** data path (uniform across all platforms)
- **32-bit std_logic_vector** control registers

**MCC Abstraction**: Physical ADC/DAC bit widths (12-bit, 16-bit, etc.) are **abstracted** by MCC. Your module always sees 16-bit signed data regardless of platform.

---

## Platform Comparison Table

| Specification           | **Moku:Go**        | **Moku:Lab**         | **Moku:Pro**              | **Moku:Delta**            |
|-------------------------|--------------------|-----------------------|----------------------------|----------------------------|
| **CustomWrapper Slots** | 2                  | 2                     | 4                          | 8                          |
| **Physical ADC Channels** | 2                | 2                     | 4                          | 8                          |
| **ADC Resolution**      | 12-bit             | 12-bit                | 10-bit + 18-bit (blended)  | 14-bit + 20-bit (blended)  |
| **ADC Sample Rate**     | 125 MSa/s          | 500 MSa/s             | 5 GSa/s (1ch) / 1.25 GSa/s (4ch) | 5 GSa/s (all 8ch)         |
| **Input Bandwidth**     | 30 MHz             | 200 MHz               | 300/600 MHz (selectable)   | 2 GHz                      |
| **Physical DAC Channels** | 2                | 2                     | 4                          | 8                          |
| **DAC Resolution**      | 12-bit             | 16-bit                | 16-bit                     | 14-bit                     |
| **DAC Sample Rate**     | 125 MSa/s          | 1 GSa/s               | 1.25 GSa/s                 | 10 GSa/s                   |
| **Output Bandwidth**    | 20 MHz             | 300 MHz               | 500 MHz                    | 2 GHz                      |
| **Digital I/O (DIO)**   | 16 channels        | Trigger + 10MHz sync  | Not specified              | 32 channels (2×16)         |
| **DIO Logic Level**     | 3.3V (5V tolerant) | N/A                   | N/A                        | TTL                        |
| **FPGA**                | Zynq-based         | Xilinx Zynq 7020      | Xilinx Ultrascale+         | Xilinx Ultrascale+ RFSoC   |
| **Multi-Instrument**    | 2 simultaneous     | 2 simultaneous        | 4 simultaneous             | 8 simultaneous             |
| **Typical Synth Clock** | ~125 MHz*          | ~500 MHz*             | ~1.25 GHz*                 | ~5 GHz*                    |
| **CustomWrapper I/O**   | 4 in / 4 out       | 4 in / 4 out          | 4 in / 4 out               | 4 in / 4 out               |
| **Control Registers**   | 32 (Control0-31)   | 32 (Control0-31)      | 32 (Control0-31)           | 32 (Control0-31)           |

\* *Synthesis clock rates are **estimates** based on sample rates. Actual clocks depend on MCC synthesis and can be extracted from Vivado logs.*

**Note**: "Physical ADC/DAC Channels" refers to hardware on the device. CustomWrapper always provides **4 virtual inputs/outputs** regardless of physical channel count. MCC handles routing/mapping.

---

## Architecture Notes

### CustomWrapper Slot Model
Each platform provides **N slots** where CustomWrapper modules execute:
- **Moku:Go**: 2 slots
- **Moku:Lab**: 2 slots  
- **Moku:Pro**: 4 slots
- **Moku:Delta**: 8 slots

**Each slot has the identical CustomWrapper interface**:
- 4 inputs (InputA/B/C/D)
- 4 outputs (OutputA/B/C/D)
- 32 control registers (Control0-31)

### MCC Routing System
MCC provides **dynamic signal routing** between physical I/O and slot virtual I/O:

**Physical → Virtual Mapping**:
- Physical ADCs (e.g., IN1, IN2 on Moku:Go) → **Any slot's InputA/B/C/D**
- Physical DACs (e.g., OUT1, OUT2 on Moku:Go) ← **Any slot's OutputA/B/C/D**
- Cross-slot routing: Slot 1 OutputA → Slot 2 InputB (internal signal path)

**Example** (Moku:Go with 2 physical ADCs, 2 slots):
```
Physical IN1 (ADC) → MCC Router → Slot 1 InputA
                                → Slot 1 InputB  (duplicate signal)
                                → Slot 2 InputA  (share ADC between slots)

Physical IN2 (ADC) → MCC Router → Slot 2 InputC

Slot 1 OutputA → MCC Router → Physical OUT1 (DAC)
Slot 1 OutputB → MCC Router → Slot 2 InputD  (inter-slot signal)
Slot 2 OutputA → MCC Router → Physical OUT2 (DAC)
```

**Key Insight**: Even though Moku:Go has only **2 physical ADCs**, each slot still has **4 virtual inputs**. MCC routing determines which physical signals map to which virtual inputs.

### Testbench Mapping
When writing CocotB tests:
- **Focus on CustomWrapper interface** (4 inputs, 4 outputs, 32 control registers)
- Platform models inform **clock period** and **physical resource limits**
- No need to model MCC routing in tests (handled by MCC at deployment)
- Test all 4 inputs/outputs even if target platform has fewer physical channels

---

## Platform Details

### Moku:Go - Portable Design Tool
**Target Use**: Education, prototyping, portable testing  
**Form Factor**: Compact oval device with integrated connectors  
**Key Features**:
- 2 BNC analog I/O, 16-ch DIO via cable
- Wi-Fi hotspot, USB-C data
- Optional 4-ch programmable power supplies (M2 model)
- 14 built-in instruments

**Physical Ports**:
- **2× Analog Inputs (BNC)**: 12-bit @ 125 MSa/s, ±25V range → Maps to InputA/B/C/D via MCC
- **2× Analog Outputs (BNC)**: 12-bit @ 125 MSa/s, ±5V range ← Maps from OutputA/B/C/D via MCC
- **16× Digital I/O**: 3.3V logic (5V tolerant), 125 MSa/s

**CustomWrapper Slots**: 2  
**Virtual I/O per Slot**: 4 inputs, 4 outputs (MCC routes 2 physical ADCs/DACs)

**Testbench Parameters**:
```python
# tests/platform_models.py
MOKU_GO = {
    'name': 'Moku:Go',
    'slots': 2,
    'physical_adc_channels': 2,      # Physical BNC inputs
    'physical_dac_channels': 2,      # Physical BNC outputs
    'virtual_inputs_per_slot': 4,    # CustomWrapper InputA/B/C/D
    'virtual_outputs_per_slot': 4,   # CustomWrapper OutputA/B/C/D
    'control_registers': 32,         # Control0-31
    'dio_channels': 16,
    'clk_period_ns': 8.0,            # 125 MHz
    'adc_bits': 12,
    'dac_bits': 12,
}
```

---

### Moku:Lab - Research Platform
**Target Use**: Research labs, benchtop integration  
**Form Factor**: Cylindrical enclosure with front/rear I/O  
**Key Features**:
- Zynq 7020 FPGA (larger fabric than Go)
- 500 ppb clock stability
- <1 μs input-to-output latency
- 30 nV/√Hz noise performance above 100 kHz

**Physical Ports**:
- **2× Analog Inputs (BNC)**: 12-bit @ 500 MSa/s, 1Vpp or 10Vpp, 50Ω/1MΩ
- **2× Analog Outputs (BNC)**: 16-bit @ 1 GSa/s, 2Vpp into 50Ω
- Trigger input (BNC)
- 10 MHz sync in/out (BNC)

**CustomWrapper Slots**: 2  
**Virtual I/O per Slot**: 4 inputs, 4 outputs

**Testbench Parameters**:
```python
MOKU_LAB = {
    'name': 'Moku:Lab',
    'slots': 2,
    'physical_adc_channels': 2,
    'physical_dac_channels': 2,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 0,               # Trigger + sync, not general DIO
    'clk_period_ns': 2.0,            # 500 MHz
    'adc_bits': 12,
    'dac_bits': 16,
}
```

---

### Moku:Pro - High-Performance Platform
**Target Use**: Advanced research, quantum computing, high-speed applications  
**Form Factor**: Rack-mountable 1U chassis  
**Key Features**:
- Xilinx Ultrascale+ FPGA
- Blended ADC (10-bit + 18-bit) for wide dynamic range
- 4 simultaneous instrument slots
- 240 GB SSD for data logging
- <650 ns input-to-output latency

**Physical Ports**:
- **4× Analog Inputs (BNC)**: Dual ADC @ 5 GSa/s (1ch) or 1.25 GSa/s (4ch)
- **4× Analog Outputs (BNC)**: 16-bit @ 1.25 GSa/s
- Trigger input, 10 MHz ref in/out
- 240 GB internal SSD

**CustomWrapper Slots**: 4  
**Virtual I/O per Slot**: 4 inputs, 4 outputs  
**Note**: Physical channels (4) match virtual I/O count - perfect 1:1 mapping possible

**Testbench Parameters**:
```python
MOKU_PRO = {
    'name': 'Moku:Pro',
    'slots': 4,
    'physical_adc_channels': 4,      # Matches virtual I/O!
    'physical_dac_channels': 4,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 0,
    'clk_period_ns': 0.8,            # 1.25 GHz (4-channel mode)
    'adc_bits': 18,                  # Blended (10-bit + 18-bit)
    'dac_bits': 16,
}
```

---

### Moku:Delta - Ultimate Performance
**Target Use**: Cutting-edge research, multi-channel systems, MIMO applications  
**Form Factor**: Rack-mountable chassis  
**Key Features**:
- Xilinx Ultrascale+ RFSoC FPGA
- 8 simultaneous instrument slots (most capable platform)
- Blended ADC (14-bit + 20-bit) with <10 nV/√Hz noise floor
- ±1 ppb clock stability
- 1 TB internal SSD
- 127 ns input-to-output delay
- GPS timing reference module

**Physical Ports**:
- **8× Analog Inputs (BNC)**: 14-bit + 20-bit @ 5 GSa/s, 2 GHz bandwidth
- **8× Analog Outputs (BNC)**: 14-bit @ 10 GSa/s, 2 GHz bandwidth
- 32× Digital I/O (2 sets of 16 bidirectional)
- 100 Gb/s QSFP, 2× 10 Gb/s SFP, 1 Gb/s Ethernet
- GPS timing, 10/100 MHz clock ref

**CustomWrapper Slots**: 8  
**Virtual I/O per Slot**: 4 inputs, 4 outputs  
**Note**: 8 physical channels, 8 slots × 4 virtual I/O = 32 virtual channels total (MCC routing required)

**Testbench Parameters**:
```python
MOKU_DELTA = {
    'name': 'Moku:Delta',
    'slots': 8,
    'physical_adc_channels': 8,
    'physical_dac_channels': 8,
    'virtual_inputs_per_slot': 4,
    'virtual_outputs_per_slot': 4,
    'control_registers': 32,
    'dio_channels': 32,
    'clk_period_ns': 0.2,            # 5 GHz
    'adc_bits': 20,                  # Blended (14-bit + 20-bit)
    'dac_bits': 14,
}
```

---

## Testbench Integration Strategy

### High-Fidelity Testing Principles
1. **Clock Period**: Use platform-appropriate clock periods in CocotB tests to match synthesis reality
2. **All I/O Ports**: Test all 4 inputs and 4 outputs, even if target platform has fewer physical channels
3. **Control Registers**: Test with Control0-31 (32 registers available)
4. **Multi-Slot Scenarios**: For advanced tests, simulate multiple slots sharing physical ADCs (future work)

### Example CocotB Usage
```python
# tests/test_my_module.py
import cocotb
from cocotb.triggers import RisingEdge
from conftest import setup_clock, reset_active_high, init_mcc_inputs

# Import platform models
from platform_models import MOKU_GO, MOKU_LAB, MOKU_PRO, MOKU_DELTA

@cocotb.test()
async def test_on_moku_go(dut):
    """Test module behavior on Moku:Go target platform"""
    platform = MOKU_GO
    
    # Setup clock matching Moku:Go synthesis (~125 MHz)
    await setup_clock(dut, period_ns=platform['clk_period_ns'])
    await reset_active_high(dut)
    await init_mcc_inputs(dut)
    
    # Test all 4 virtual inputs (even though Go has only 2 physical ADCs)
    dut.InputA.value = 0x1234
    dut.InputB.value = 0x5678
    dut.InputC.value = 0x0000  # May be unused, but test anyway
    dut.InputD.value = 0x0000
    
    dut._log.info(f"Testing on {platform['name']} ({platform['slots']} slots)")
```

### Block Diagram Abstraction
When creating diagrams, represent:
- **Platform box** (Go/Lab/Pro/Delta) with physical BNC connectors
- **N CustomWrapper slots** inside the platform, each with 4 virtual inputs/outputs
- **MCC routing layer** showing physical → virtual mapping
- **Your module** inside a slot with full 4×4 I/O interface

---

## Physical vs Virtual I/O

### Understanding the Abstraction

**Physical I/O**: Actual BNC connectors on the device
- Moku:Go: 2 ADC, 2 DAC
- Moku:Lab: 2 ADC, 2 DAC
- Moku:Pro: 4 ADC, 4 DAC
- Moku:Delta: 8 ADC, 8 DAC

**Virtual I/O**: CustomWrapper interface (same on all platforms)
- Every slot: 4 inputs (InputA/B/C/D), 4 outputs (OutputA/B/C/D)

**MCC Routing**: Maps physical ↔ virtual
- User configures via Moku GUI/API
- Flexible routing: One physical ADC → multiple virtual inputs
- Cross-slot routing: Slot 1 output → Slot 2 input

### Design Implications

**For VHDL Developers**:
- Always use all 4 inputs/outputs in CustomWrapper architecture
- Unused virtual I/O can be left unconnected or driven to safe defaults
- Don't assume InputA = physical IN1 (MCC handles mapping)

**For Testbench Authors**:
- Drive all 4 inputs in tests (validate full interface)
- Monitor all 4 outputs (even if some are unused)
- Physical limits don't constrain virtual I/O usage in tests

---

## Future Enhancements

### Synthesis Log Integration
When MCC builds are performed, extract actual synthesis clock rates from Vivado logs:
```bash
# Example: Parse Vivado timing report
grep "Requirement:" build_log.txt | grep "Clk"
# Update this memory with actual achieved clock rates
```

### Multi-Slot Testbenches
For complex scenarios (e.g., two modules interacting via MCC routing):
- Instantiate multiple CustomWrapper modules in one CocotB test
- Model simplified MCC routing (signal muxing between slots)
- Validate inter-slot communication patterns

**Note**: This is a **future capability** - not needed for current single-module tests.

---

## Summary

**For Testbench Authors**:
- Use platform-appropriate clock periods from the table above
- Focus on CustomWrapper interface: 4 inputs, 4 outputs, 32 control registers
- Test all virtual I/O regardless of physical channel count

**For Module Developers**:
- Write to CustomWrapper standard (4 in, 4 out, 32 control regs)
- Platform abstraction works - same module runs everywhere
- Test on representative clock frequencies to catch timing issues early

**For Documentation**:
- Cite specific platforms when describing performance (e.g., "Tested on Moku:Go @ 125 MHz")
- Use block diagrams showing slot architecture and MCC routing
- Distinguish between physical BNC channels and virtual CustomWrapper I/O

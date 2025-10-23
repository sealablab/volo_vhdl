# MCC Slot Routing Guide for VHDL Developers

## Overview

This guide explains how **Moku Cloud Compile (MCC) routing** works from a VHDL developer's perspective. Understanding routing helps you design testbenches, create accurate diagrams, and debug deployment issues.

**Key Principle**: Your VHDL module sees a **fixed CustomWrapper interface** (4 inputs, 4 outputs, 32 control regs). **MCC routing** handles all the dynamic mapping between physical I/O and your virtual interface.

---

## MCC Routing Architecture

### The Two Layers

```
┌─────────────────────────────────────────────────────┐
│  Physical Layer (Hardware BNC Connectors)           │
│  • IN1, IN2 (ADCs)                                  │
│  • OUT1, OUT2 (DACs)                                │
│  • DIO (digital I/O)                                │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  MCC Routing Layer (User-Configurable via Python)  │
│  • Connects physical I/O ↔ slot virtual I/O         │
│  • Connects slot outputs ↔ slot inputs (cross-slot) │
│  • Many-to-many routing (one ADC → multiple slots)  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Virtual Layer (CustomWrapper Interface)            │
│  • Slot 1: InputA/B/C/D, OutputA/B/C/D              │
│  • Slot 2: InputA/B/C/D, OutputA/B/C/D              │
│  • Slot N: InputA/B/C/D, OutputA/B/C/D              │
└─────────────────────────────────────────────────────┘
```

---

## Connection API (Python)

### Basic Syntax

```python
from moku.instruments import MultiInstrument, CloudCompile, Oscilloscope

m = MultiInstrument('192.168.1.100', platform_id=2, force_connect=True)

# Load your VHDL module into Slot 1
mcc = m.set_instrument(1, CloudCompile, bitstream="path/to/bitstream.tar.gz")

# Load Oscilloscope into Slot 2 for monitoring
osc = m.set_instrument(2, Oscilloscope)

# Configure connections
connections = [
    dict(source="Input1", destination="Slot1InA"),      # Physical IN1 → Your module InputA
    dict(source="Slot1OutA", destination="Slot2InA"),   # Your module OutputA → Oscilloscope Ch1
    dict(source="Slot1OutA", destination="Output1"),    # Your module OutputA → Physical OUT1
]

m.set_connections(connections=connections)
```

### Connection Sources and Destinations

| Type | Format | Example | Description |
|------|--------|---------|-------------|
| **Physical Input** | `Input1`, `Input2` | `"Input1"` | ADC BNC connectors (Moku:Go has 2) |
| **Physical Output** | `Output1`, `Output2` | `"Output1"` | DAC BNC connectors (Moku:Go has 2) |
| **Slot Virtual Input** | `SlotXInA/B/C/D` | `"Slot1InA"` | CustomWrapper InputA on Slot 1 |
| **Slot Virtual Output** | `SlotXOutA/B/C/D` | `"Slot2OutB"` | CustomWrapper OutputB on Slot 2 |
| **Digital I/O** | `DIO` | `"DIO"` | 16-channel digital I/O (Moku:Go) |

**Mapping to CustomWrapper Ports**:
- `Slot1InA` = `InputA` signal in your VHDL CustomWrapper architecture (Slot 1)
- `Slot1InB` = `InputB` signal in your VHDL CustomWrapper architecture (Slot 1)
- `Slot1InC` = `InputC` signal in your VHDL CustomWrapper architecture (Slot 1)
- `Slot1InD` = `InputD` signal in your VHDL CustomWrapper architecture (Slot 1)
- `Slot1OutA` = `OutputA` signal in your VHDL CustomWrapper architecture (Slot 1)
- (... and so on for OutB/C/D)

---

## Common Routing Patterns

### Pattern 1: Simple Physical I/O Pass-Through
**Use Case**: Test your module with external signals

```python
connections = [
    dict(source="Input1", destination="Slot1InA"),   # Physical IN1 → Module InputA
    dict(source="Input2", destination="Slot1InB"),   # Physical IN2 → Module InputB
    dict(source="Slot1OutA", destination="Output1"), # Module OutputA → Physical OUT1
    dict(source="Slot1OutB", destination="Output2"), # Module OutputB → Physical OUT2
]
```

**VHDL Perspective**:
```vhdl
-- Your module in Slot 1 sees:
InputA  ← Physical IN1 (ADC)
InputB  ← Physical IN2 (ADC)
InputC  ← Unconnected (driven to 0 by MCC)
InputD  ← Unconnected (driven to 0 by MCC)

OutputA → Physical OUT1 (DAC)
OutputB → Physical OUT2 (DAC)
OutputC → Nowhere (unused)
OutputD → Nowhere (unused)
```

---

### Pattern 2: Dual-Slot with Monitoring
**Use Case**: Your module in Slot 2, Oscilloscope in Slot 1 for monitoring

```python
connections = [
    dict(source="Input1", destination="Slot1InA"),   # External signal → Oscilloscope Ch1
    dict(source="Slot2OutA", destination="Slot1InB"), # Your module output → Oscilloscope Ch2
    dict(source="Slot2OutA", destination="Output1"),  # Your module output → Physical OUT1
]
```

**Signal Flow**:
```
Physical IN1 (BNC) → Oscilloscope InputA (display external signal on Ch1)
Your Module OutputA → Oscilloscope InputB (display your output on Ch2)
                   → Physical OUT1 (BNC) (send to target device)
```

**VHDL Perspective** (Slot 2):
```vhdl
-- Your module in Slot 2:
InputA/B/C/D  ← All unconnected (driven to 0)
OutputA       → Oscilloscope Slot1 InputB + Physical OUT1 (fan-out)
OutputB/C/D   → Unused
```

---

### Pattern 3: Cross-Slot Processing Pipeline
**Use Case**: Chain two Cloud Compile modules together

```python
mcc1 = m.set_instrument(1, CloudCompile, bitstream="preprocessor.tar.gz")
mcc2 = m.set_instrument(2, CloudCompile, bitstream="postprocessor.tar.gz")

connections = [
    dict(source="Input1", destination="Slot1InA"),   # Physical IN1 → Preprocessor
    dict(source="Slot1OutA", destination="Slot2InA"), # Preprocessor → Postprocessor
    dict(source="Slot2OutA", destination="Output1"),  # Postprocessor → Physical OUT1
]
```

**Signal Flow**:
```
Physical IN1 → Slot 1 (Preprocessor) → Slot 2 (Postprocessor) → Physical OUT1
```

**VHDL Perspective**:
- **Slot 1 module**: Receives InputA from IN1, sends OutputA to Slot 2
- **Slot 2 module**: Receives InputA from Slot 1, sends OutputA to OUT1

---

### Pattern 4: Multi-Input Aggregation
**Use Case**: One module processes multiple physical inputs

```python
connections = [
    dict(source="Input1", destination="Slot1InA"),
    dict(source="Input2", destination="Slot1InB"),
    dict(source="Input1", destination="Slot1InC"),  # Duplicate IN1 → InputC
    dict(source="Slot1OutA", destination="Output1"),
]
```

**VHDL Perspective** (Slot 1):
```vhdl
InputA ← Physical IN1
InputB ← Physical IN2
InputC ← Physical IN1 (same signal as InputA!)
InputD ← Unconnected (0)
```

**Use Cases**:
- Compare two channels (InputA vs InputB)
- Differential signal processing (InputC = reference copy of InputA)
- Multi-tap filtering (reuse same input signal)

---

## Control Registers

### Setting Control Registers (Python API)

```python
mcc = m.set_instrument(1, CloudCompile, bitstream="my_module.tar.gz")

# Set individual control registers
mcc.set_control(0, 0x40000001)  # Control0 = 0x40000001 (MCC_READY + user bits)
mcc.set_control(1, 0x0000007F)  # Control1 = 127 (delay parameter)
mcc.set_control(5, 0x0000199A)  # Control5 = 6554 (voltage level)
```

**VHDL Perspective**:
```vhdl
architecture MyModule of CustomWrapper is
    signal mcc_ready   : std_logic;
    signal user_enable : std_logic;
    signal delay_param : unsigned(31 downto 0);
    signal voltage_level : unsigned(31 downto 0);
begin
    mcc_ready <= Control0(31);
    user_enable <= Control0(30);
    delay_param <= unsigned(Control1);
    voltage_level <= unsigned(Control5);

    -- Your logic here...
end architecture;
```

**Notes**:
- Python `set_control()` maps directly to VHDL `ControlN` ports
- Control0[31] is **reserved for MCC_READY** (set automatically by MCC after config load)
- Control0[30] typically used for user enable
- Control1-31 are yours to define

---

## Routing Rules and Constraints

### ✅ Allowed Connections

| Source | Destination | Example | Notes |
|--------|-------------|---------|-------|
| Physical Input → Slot Input | `Input1` → `Slot1InA` | External ADC to module input | Standard |
| Slot Output → Physical Output | `Slot1OutA` → `Output1` | Module output to DAC | Standard |
| Slot Output → Slot Input | `Slot1OutA` → `Slot2InB` | Cross-slot signal path | Very common |
| Physical Input → Multiple Slot Inputs | `Input1` → `Slot1InA`, `Slot2InA` | Fan-out (one ADC to two modules) | Allowed |
| Slot Output → Multiple Destinations | `Slot1OutA` → `Output1`, `Slot2InA` | Fan-out (output to DAC + another slot) | Allowed |

### ❌ Forbidden Connections

| Invalid Connection | Why It's Forbidden |
|-------------------|-------------------|
| Slot Input → Anything | Inputs are **destinations only**, never sources |
| Physical Output → Anything | Outputs are **destinations only**, never sources |
| Slot Output → Same Slot Input | No internal loopback within a slot (use VHDL logic instead) |

---

## Real-World Example: EMFI-Seq Deployment

### Configuration (from screenshot)

```python
# Moku:Go - 2 slots
m = MultiInstrument('192.168.1.100', platform_id=2, force_connect=True)

# Slot 1: Oscilloscope (monitoring)
osc = m.set_instrument(1, Oscilloscope)

# Slot 2: EMFI-Seq (custom VHDL module)
mcc = m.set_instrument(2, CloudCompile, bitstream="emfi_seq.tar.gz")

# Routing configuration
connections = [
    # Physical inputs (currently unused in development)
    # dict(source="Input1", destination="Slot1InA"),  # Optional: external trigger

    # Internal monitoring: EMFI output → Oscilloscope
    dict(source="Slot2OutA", destination="Slot1InA"),  # EMFI pulse → Osc Ch1
    dict(source="Slot2OutB", destination="Slot1InB"),  # EMFI status → Osc Ch2

    # Physical output: EMFI pulse to target device
    dict(source="Slot2OutA", destination="Output1"),   # EMFI pulse → OUT1 BNC
]

m.set_connections(connections=connections)

# Configure EMFI-Seq via control registers
mcc.set_control(0, 0xC0000001)  # MCC_READY + Enable
mcc.set_control(1, 0x000000FF)  # DelayS1 = 255 clock cycles
mcc.set_control(2, 0x00000064)  # PulseWidth = 100 cycles
mcc.set_control(5, 0x00001000)  # Voltage level
```

### VHDL Module (Slot 2)

```vhdl
architecture EMFI_Seq of CustomWrapper is
    signal mcc_ready : std_logic;
    signal user_enable : std_logic;
    signal global_enable : std_logic;
    signal emfi_pulse_out : signed(15 downto 0);
    signal status_out : signed(15 downto 0);
begin
    -- Extract MCC_READY and enable
    mcc_ready <= Control0(31);
    user_enable <= Control0(30);
    global_enable <= mcc_ready and user_enable;

    -- EMFI logic here...

    -- Outputs:
    OutputA <= emfi_pulse_out;  -- → Oscilloscope InputA + Physical OUT1
    OutputB <= status_out;      -- → Oscilloscope InputB
    OutputC <= (others => '0'); -- Unused
    OutputD <= (others => '0'); -- Unused
end architecture;
```

### What the Oscilloscope Sees

| Oscilloscope Channel | Connected To | Displays |
|---------------------|--------------|----------|
| **Channel 1** | Slot2OutA (EMFI pulse) | Real-time EMFI pulse waveform |
| **Channel 2** | Slot2OutB (status signals) | Module status, timing markers |

---

## Implications for VHDL Development

### 1. **Design for Flexibility**
Your module doesn't know (and shouldn't care) which physical I/O it's connected to:

```vhdl
-- ✅ GOOD: Use all 4 virtual inputs, let MCC routing decide sources
process(Clk)
begin
    if rising_edge(Clk) then
        if InputA /= 0 then
            trigger_detected <= '1';
        end if;

        signal_sum <= InputA + InputB + InputC + InputD;  -- Use all inputs
    end if;
end process;

-- ❌ BAD: Assuming InputA = Physical IN1
-- Don't hardcode physical I/O assumptions in VHDL!
```

### 2. **Drive All Outputs**
Even if you only use OutputA, **drive all outputs to known values**:

```vhdl
OutputA <= my_signal;
OutputB <= (others => '0');  -- Explicitly drive unused outputs
OutputC <= (others => '0');
OutputD <= (others => '0');
```

Why? MCC might route unused outputs somewhere (e.g., for debugging). Undriven outputs can cause synthesis warnings or unexpected behavior.

### 3. **Testbench Simplification**
In CocotB tests, you **don't simulate MCC routing**. Just drive CustomWrapper ports directly:

```python
@cocotb.test()
async def test_my_module(dut):
    # Drive virtual inputs directly (no routing simulation needed)
    dut.InputA.value = 0x1234
    dut.InputB.value = 0x5678

    # Monitor virtual outputs directly
    await ClockCycles(dut.Clk, 10)
    assert dut.OutputA.value == expected_value
```

**Routing is MCC's job, not yours!** Tests focus on VHDL logic correctness.

### 4. **Debugging Connection Issues**
If your module doesn't work on hardware but passes CocotB tests:

**Check Python routing**:
```python
# Add this to your deployment script
print("Current connections:", m.get_connections())
```

**Common mistakes**:
- ❌ Forgot to route physical input to slot input
- ❌ Routed output to wrong slot/physical port
- ❌ Typo in connection name (`"Slot1InA"` vs `"Slot1lnA"` ← lowercase 'L')

---

## Platform-Specific Routing Limits

| Platform | Slots | Physical ADC/DAC | Notes |
|----------|-------|------------------|-------|
| **Moku:Go** | 2 | 2 ADC / 2 DAC | Limited physical I/O, use internal routing |
| **Moku:Lab** | 2 | 2 ADC / 2 DAC | Same as Go, higher performance |
| **Moku:Pro** | 4 | 4 ADC / 4 DAC | Perfect match: 4 slots × 4 virtual I/O = 16 channels, 4 physical × 4 = 16 |
| **Moku:Delta** | 8 | 8 ADC / 8 DAC | 8 slots × 4 I/O = 32 virtual channels, 8 physical I/O |

**Key Insight**:
- **Moku:Go/Lab**: Limited to 2 physical I/O, so cross-slot routing is **essential** for multi-slot setups
- **Moku:Pro/Delta**: More physical I/O allows dedicated connections per slot (less routing complexity)

---

## Summary for VHDL Developers

### What You Need to Know:
1. ✅ **CustomWrapper interface is fixed**: 4 inputs (A/B/C/D), 4 outputs (A/B/C/D), 32 control regs
2. ✅ **MCC routing is external**: Configured via Python API, **not in VHDL**
3. ✅ **Naming convention**: `SlotXInA` = `InputA` on CustomWrapper in Slot X
4. ✅ **Fan-out is allowed**: One source can connect to multiple destinations
5. ✅ **Drive all outputs**: Even unused ones (to safe defaults like `0x0000`)

### What You DON'T Need to Worry About:
1. ❌ Physical I/O mapping (MCC handles it)
2. ❌ Cross-slot signal paths (MCC handles it)
3. ❌ Routing simulation in testbenches (just test CustomWrapper interface)

### Golden Rule:
**Write your VHDL to the CustomWrapper standard. Let MCC routing handle everything else.**

---

## References

- **Platform Models**: `docs/PLATFORM_MODELS.md` (physical I/O specs per platform)
- **MCC Templates**: `mcc_templates/mcc-Top.vhd` (CustomWrapper entity definition)
- **Python API Examples**: `mcc_py_api_examples/` (routing examples)
- **EMFI-Seq Diagrams**: `docs/EMFI_Seq_Operational_Diagram.md` (real-world routing example)
- **Liquid Instruments API Docs**: https://apis.liquidinstruments.com/

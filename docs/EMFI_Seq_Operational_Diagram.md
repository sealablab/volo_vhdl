# EMFI-Seq Operational Configuration (Moku:Go)

**Typical Use Case**: Development and monitoring setup

## Configuration Overview
- **Slot 1**: Moku Oscilloscope (built-in instrument for monitoring)
- **Slot 2**: EMFI-Seq (custom module under development)
- **Platform**: Moku:Go (2 slots, 2 physical ADC/DAC, 16 DIO)

## Signal Flow





graph TB
    subgraph Physical_IO["🔌 Moku:Go Physical I/O"]
        direction TB
        IN1["IN1 (BNC)<br/>ADC 12-bit @ 125 MSa/s<br/>Connected to: External signal source"]
        IN2["IN2 (BNC)<br/>ADC 12-bit @ 125 MSa/s<br/>Connected to: EMFI output monitor"]

        OUT1["OUT1 (BNC)<br/>DAC 12-bit @ 125 MSa/s<br/>Oscilloscope display output"]
        OUT2["OUT2 (BNC)<br/>DAC 12-bit @ 125 MSa/s<br/>EMFI-Seq pulse output"]

        DIO["16-ch DIO<br/>Available for trigger/control"]
    end

    subgraph MCC_Routing["MCC Routing Layer (User-Configured)"]
        direction LR
        Router["MCC Signal Router<br/><br/>Routing Configuration:<br/>• IN1 → Oscilloscope InputA<br/>• IN2 → Oscilloscope InputB (monitors EMFI out)<br/>• Oscilloscope OutputA → OUT1 (display)<br/>• EMFI-Seq OutputA → OUT2 (pulse output)<br/>• EMFI-Seq OutputA → Oscilloscope InputB (internal monitor)"]
    end

    subgraph Slot1["Slot 1: Moku Oscilloscope (Built-in Instrument)"]
        direction TB
        OSC_Control["Control Registers:<br/>Control0-31<br/>(Oscilloscope settings via Moku GUI)"]
        OSC_Inputs["Virtual Inputs:<br/>InputA: External signal (from IN1)<br/>InputB: EMFI-Seq output (internal)<br/>InputC: Unused<br/>InputD: Unused"]
        OSC_Module["Moku Oscilloscope<br/><br/>• Dual-channel monitoring<br/>• Real-time waveform display<br/>• Trigger capabilities<br/>• Data logging"]
        OSC_Outputs["Virtual Outputs:<br/>OutputA: Display waveform → OUT1<br/>OutputB: Unused<br/>OutputC: Unused<br/>OutputD: Unused"]

        OSC_Inputs --> OSC_Module
        OSC_Control --> OSC_Module
        OSC_Module --> OSC_Outputs
    end

    subgraph Slot2["Slot 2: EMFI-Seq (Custom Module)"]
        direction TB
        EMFI_Control["Control Registers (MCC_READY pattern):<br/>Control0[31]: MCC_READY (auto-set by MCC)<br/>Control0[30]: User Enable<br/>Control0-8: FSM configuration, timing, voltage levels<br/>(See modules/EMFI-Seq/top/Top.vhd)"]
        EMFI_Inputs["Virtual Inputs:<br/>InputA: Trigger input (optional)<br/>InputB: Unused<br/>InputC: Unused<br/>InputD: Unused"]
        EMFI_Module["EMFI-Seq Module<br/><br/>Components:<br/>• FSM Core (sequencer logic)<br/>• Analog Monitor<br/>• Pulse generation<br/>• Safety interlocks"]
        EMFI_Outputs["Virtual Outputs:<br/>OutputA: EM fault injection pulse → OUT2<br/>OutputB: Status/monitor signals<br/>OutputC: Unused<br/>OutputD: Unused"]

        EMFI_Inputs --> EMFI_Module
        EMFI_Control --> EMFI_Module
        EMFI_Module --> EMFI_Outputs
    end

    subgraph Network["Network Control (Wi-Fi/Ethernet)"]
        MokuApp["Moku:Go App<br/>(iPad/macOS/Windows)<br/><br/>• Oscilloscope GUI (Slot 1)<br/>• EMFI-Seq controls (Slot 2)<br/>• Real-time monitoring"]
    end

    %% Physical to MCC Router
    IN1 -.->|ADC data| Router
    IN2 -.->|ADC data| Router

    %% MCC Router to Slots
    Router -.->|Routed signal| OSC_Inputs
    Router -.->|Unused| EMFI_Inputs

    %% Slots to MCC Router
    OSC_Outputs -.->|Display output| Router
    EMFI_Outputs -.->|Pulse + monitor| Router

    %% MCC Router to Physical
    Router -.->|To display| OUT1
    Router -.->|EMFI pulse| OUT2

    %% Inter-slot monitoring (internal MCC routing)
    EMFI_Outputs -.->|Internal routing<br/>for real-time monitoring| OSC_Inputs

    %% Network control
    MokuApp -.->|Control registers<br/>via network| OSC_Control
    MokuApp -.->|Control registers<br/>via network| EMFI_Control

    %% Styling
    classDef physical fill:#e1f5ff,stroke:#0066cc,stroke-width:3px
    classDef slot fill:#fff4e6,stroke:#ff9800,stroke-width:2px
    classDef builtin fill:#e8f5e9,stroke:#4caf50,stroke-width:2px
    classDef router fill:#f0f0f0,stroke:#666,stroke-width:2px,stroke-dasharray: 5 5
    classDef network fill:#fce4ec,stroke:#e91e63,stroke-width:2px

    class IN1,IN2,OUT1,OUT2,DIO physical
    class Slot1 builtin
    class Slot2 slot
    class Router router
    class MokuApp network




## Operational Workflow

### 1. **Startup Sequence**
1. Power on Moku:Go
2. Connect to Moku:Go via Wi-Fi/Ethernet (iPad/macOS/Windows app)
3. Load instruments:
   - Slot 1: Launch Oscilloscope (built-in)
   - Slot 2: Upload EMFI-Seq bitstream (via Moku Cloud Compile)
4. MCC initializes Control0-31 to 0x00000000 (safe state)
5. Network config arrives (~10-200ms delay)
6. MCC sets Control0[31]=1 (MCC_READY flag)
7. EMFI-Seq enables (Control0[30] set by user)

### 2. **MCC Routing Configuration** (via Moku GUI)
- **IN1** → Oscilloscope Channel 1 (external signal monitoring)
- **IN2** → Oscilloscope Channel 2 (EMFI output feedback monitoring)
- **EMFI-Seq OutputA** → **OUT2** (physical EMFI pulse output)
- **EMFI-Seq OutputA** → **Oscilloscope InputB** (internal routing for real-time monitoring)
- **Oscilloscope OutputA** → **OUT1** (display/logging output)

### 3. **Physical Connections** (BNC Cables)
- **IN1**: Connect to signal source (trigger, timing reference, etc.)
- **IN2**: Optional feedback probe (monitor EMFI pulse)
- **OUT1**: Connect to external display/logger (oscilloscope output)
- **OUT2**: **EMFI pulse output** → Target device under test

### 4. **Real-Time Monitoring**
- Oscilloscope (Slot 1) displays:
  - **Channel 1**: External input from IN1
  - **Channel 2**: EMFI-Seq pulse output (via internal routing)
- iPad/macOS app shows:
  - Live waveforms from Oscilloscope
  - EMFI-Seq control panel (timing, voltage, enable)
  - Status indicators (MCC_READY, faults, etc.)

### 5. **Development Iteration**
1. Adjust EMFI-Seq parameters via Moku app (Control0-8 registers)
2. Observe pulse output on Oscilloscope (real-time)
3. Modify VHDL code locally
4. Recompile with GHDL/CocotB tests (validate locally)
5. Upload new bitstream via Moku Cloud Compile
6. Test on hardware, repeat

---

## Key Benefits of This Setup

✅ **Dual-slot monitoring**: Oscilloscope observes EMFI-Seq output without external equipment
✅ **Internal signal routing**: No need for physical loopback cables
✅ **Real-time feedback**: Waveforms visible on iPad/macOS during development
✅ **Safe development**: MCC_READY pattern ensures safe startup (no glitches during config load)
✅ **Portable**: Entire setup fits in Moku:Go device (no external oscilloscope needed)

---

## Register Map Summary

### Slot 1 (Oscilloscope)
Controlled entirely via Moku GUI - no manual register access needed.

### Slot 2 (EMFI-Seq)
See `modules/EMFI-Seq/top/Top.vhd` for detailed register map.

**Key registers**:
- **Control0[31]**: MCC_READY (auto-set by MCC, read-only from user perspective)
- **Control0[30]**: Global Enable (user-controlled via Moku app)
- **Control0[29:0]**: Module-specific configuration (delays, voltages, FSM params)
- **Control1-8**: Extended configuration (see Top.vhd)

---

## Tested Configuration
- **Platform**: Moku:Go (2 slots, 125 MHz synthesis clock)
- **Test Framework**: CocotB (see `tests/test_emfi_seq_top.py`)
- **Status**: 6/8 tests passing (as of 2025-10-22)
- **Known Issues**: FSM timing under refinement, MCC_READY integration complete

---

**For CocotB test setup, see**: `docs/EMFI_Seq_Test_Diagram.md`
**For platform details, see**: `docs/PLATFORM_MODELS.md`

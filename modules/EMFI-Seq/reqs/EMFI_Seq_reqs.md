# Module Specification: sequencer-one-hot-4S

**Purpose:**  
Implements a simple 4-state one-hot sequencer with programmable per-state delays,  
sticky status bits, synchronous reset, and explicit clock/logic enables.  
Automatically wraps from S4 back to S1.

---

## 1. High-Level Summary

| Feature | Description |
|----------|--------------|
| **Type** | Synchronous 4-state sequencer (one-hot FSM) |
| **Clocking** | Single clock domain |
| **Reset** | Synchronous, active-high |
| **Clock enable** | `clk_en` gates all sequential updates (reset unaffected) |
| **Enable** | `en` controls advancement and delay counting |
| **Wrap behavior** | After S4, wraps automatically to S1 |
| **Delay behavior** | `delay=0` means “advance on the next enabled clock” |
| **Sticky status** | Bits 0–3 of `status_out` set once per state entry; only cleared on reset |
| **Vivado / MCC** | Fully synthesizable, VHDL-2008 compliant |

---

## 2. I/O Interface

### Control Inputs

| Name | Type | Width | Description |
|------|------|--------|-------------|
| `clk` | `std_logic` | 1 | Primary system clock |
| `rst` | `std_logic` | 1 | Synchronous, active-high reset (not gated by `clk_en`) |
| `clk_en` | `std_logic` | 1 | Clock enable — when low, all registers hold their value |
| `en` | `std_logic` | 1 | Logic enable — when low, state and counter hold (clock still runs) |

---

### Delay Inputs

| Name | Type | Width | Description |
|------|------|--------|-------------|
| `delay_s1` | `unsigned` | 7 | Delay for state S1 |
| `delay_s2` | `unsigned` | 7 | Delay for state S2 |
| `delay_s3` | `unsigned` | 7 | Delay for state S3 |
| `delay_s4` | `unsigned` | 7 | Delay for state S4 |

Each delay is loaded when entering its corresponding state.  
The active delay counter decrements every cycle while `clk_en='1'` and `en='1'`.  
When it reaches zero, the sequencer advances to the next state.

---

### Outputs

| Name | Type | Width | Description |
|------|------|--------|-------------|
| `status_out` | `unsigned` | 7 | Sticky status register: bits 0–3 mark first entry to S1..S4; bits 4–6 reserved (0) |
| `state_oh_out` | `std_logic_vector` | 4 | One-hot encoded current state (S1..S4) for easy probing |

---

## 3. State Definition and Encoding

| State Name | One-Hot Encoding | Next State | Delay Source | Status Bit | Description |
|-------------|------------------|-------------|---------------|-------------|--------------|
| **S1** | `0001` | S2 | `delay_s1` | 0 | Reset entry state; marks bit0 of `status_out` |
| **S2** | `0010` | S3 | `delay_s2` | 1 | Marks bit1 of `status_out` |
| **S3** | `0100` | S4 | `delay_s3` | 2 | Marks bit2 of `status_out` |
| **S4** | `1000` | S1 (wrap) | `delay_s4` | 3 | Marks bit3 of `status_out`; wraps to S1 |

---

## 4. Functional Requirements

### Reset Behavior
- On the first rising edge of `clk` when `rst='1'`:
  - `state_oh_out` ← S1 (`"0001"`)
  - `status_out` ← all zeros except bit0 ← 1
  - `delay_cnt` ← `delay_s1`
- Reset is synchronous and **not gated by `clk_en`**.

### Sequencing Rules
- State transitions occur **only** when:
  - `clk_en='1'`  
  - `en='1'`  
  - and `delay_cnt = 0`
- When a transition occurs:
  - The next state is loaded into `state_oh_out`.
  - The corresponding state’s delay value is loaded into `delay_cnt`.
  - The matching sticky status bit (0–3) is set high permanently.

### Delay Counting
- While `clk_en='1'` and `en='1'`:
  - `delay_cnt ← delay_cnt - 1` each cycle, until it reaches 0.
- If `delay_cnt = 0` when entering a state:
  - The FSM will advance on the **next** enabled clock (ZERO_ADVANCE_NEXT behavior).
- When `en='0'`, the counter holds its value.
- When `clk_en='0'`, **all** registers (including counter and state) hold.

### Wrap Condition
- When S4 completes (delay count reaches 0):
  - The sequencer wraps automatically to S1.
  - `status_out(0)` is set (already sticky).

### Status Register Rules
- Bits 0–3 correspond to first entry into S1..S4 respectively.
- Once set, they remain high until reset.
- Bits 4–6 are reserved (always ‘0’).

---

## 5. Timing Summary

| Event | Condition | Action |
|--------|------------|--------|
| Rising clock edge | `rst='1'` | Reset sequence |
| Rising clock edge | `clk_en='1'` and `en='1'` and `delay_cnt>0` | Decrement delay counter |
| Rising clock edge | `clk_en='1'` and `en='1'` and `delay_cnt=0` | Advance to next state and set sticky bit |
| Rising clock edge | `clk_en='0'` | Hold all registers |
| Rising clock edge | `en='0'` | Hold state and counter (status unchanged) |

---

## 6. Behavioral Example (Nominal Timing)

| Cycle | clk_en | en | state_oh_out | delay_cnt | Comments |
|--------|--------|----|---------------|-------------|-----------|
| 0 | 1 | X | S1 | `delay_s1` | Reset complete |
| N | 1 | 1 | S1 | 0 | Counter expires |
| N+1 | 1 | 1 | S2 | `delay_s2` | Advance to S2; set `status_out(1)` |
| … | 1 | 1 | S3 | … | Continue sequence |
| … | 1 | 1 | S4 | 0 | On next cycle, wraps to S1 |

---

## 7. Implementation Notes

- All logic is synchronous to `clk`; no asynchronous paths.
- Reset branch executes regardless of `clk_en`.
- Ideal for simple timing or trigger sequencing in FPGA designs.
- Compatible with Vivado 2022.2 and Moku Cloud Compiler (MCC).

---

## 8. Derived Outputs / Internal Signals (for reference)

| Name | Type | Description |
|------|------|--------------|
| `delay_cnt` | `unsigned(6 downto 0)` | Active down-counter loaded per-state |
| `status_reg` | `unsigned(6 downto 0)` | Internal sticky register mirrored to `status_out` |

---

## 9. Known Simplifications

- No generics or helper functions (ZERO_ADVANCE_NEXT behavior fixed).
- No parameterized state count (fixed at 4).
- No branching conditions beyond sequential progression.
- Designed for clarity and teaching purposes rather than optimization.

---

**End of Specification**

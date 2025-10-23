# VHDL Delta-Cycle Race Conditions - Patterns and Solutions

**Author**: Volo Engineering with Claude Code
**Date**: 2025-10-23
**Context**: Lessons from SimpleSerial V1 TX development

## Problem: Index-Dependent Signal Races

### Symptom
When you increment an index signal and immediately use it to select from an array, the selection may use the **old** index value, not the new one.

**Example Bug**:
```vhdl
signal byte_idx : unsigned(4 downto 0);
signal current_byte : std_logic_vector(7 downto 0);
signal high_nibble : std_logic_vector(3 downto 0);

-- Combinational assignment
current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);
high_nibble <= current_byte(7 downto 4);  -- BUG: May use old current_byte!

-- Sequential logic
when STATE_SEND_HEX_LOW =>
    if uart_done = '1' then
        byte_idx <= byte_idx + 1;  -- Increment index
        uart_data <= nibble_to_hex_ascii(high_nibble);  -- WRONG! Old nibble!
    end if;
```

**Observed Behavior**: Sending `0x00112233` resulted in `00011223` (wrong nibble order).

### Root Cause
VHDL delta cycles:
1. `byte_idx` updates (scheduled for next delta)
2. `current_byte` reads `byte_idx` (gets OLD value in this delta)
3. `high_nibble` reads `current_byte` (gets nibble from OLD byte)
4. Only in the NEXT delta cycle does everything settle correctly

## Solution 1: Direct Read (Preferred)

**Bypass intermediate signals** - read directly from source using the index:

```vhdl
-- DON'T do this (two-level dependency):
current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);
high_nibble <= current_byte(7 downto 4);  -- Depends on current_byte
low_nibble <= current_byte(3 downto 0);

-- DO this (direct read):
current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);
high_nibble <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8 + 4);  -- Direct!
low_nibble <= payload_latch(to_integer(byte_idx) * 8 + 3 downto to_integer(byte_idx) * 8);       -- Direct!
```

**Benefit**: Eliminates the race - nibbles update in the same delta cycle as `byte_idx`.

## Solution 2: Settling State (If Direct Read Not Possible)

Add an FSM state that waits one cycle for signals to settle:

```vhdl
constant STATE_LOAD_BYTE : std_logic_vector(3 downto 0) := "0010";

when STATE_SEND_HEX_LOW =>
    if uart_done = '1' then
        byte_idx <= byte_idx + 1;        -- Increment index
        current_state <= STATE_LOAD_BYTE;  -- Wait for settling
    end if;

when STATE_LOAD_BYTE =>
    -- Now current_byte reflects the NEW byte_idx value
    uart_data <= nibble_to_hex_ascii(high_nibble);  -- Correct nibble!
    current_state <= STATE_SEND_HEX_HIGH;
```

**Downside**: Adds extra FSM states and latency.

## General Pattern Recognition

**Watch for**:
- Index signals feeding array/vector slicing
- Multi-level combinational dependencies (A → B → C)
- Immediate use of updated values in same process cycle

**Fix strategy**:
1. First choice: Direct read from source (eliminates intermediate signal)
2. Second choice: Add settling delay (extra clock cycle)
3. Never assume: Same-cycle update of dependent signals

## Debugging Tips

If you see **wrong data order** or **stale values**:
1. Check for index-dependent signal chains
2. Trace the dependency: Does signal B depend on signal A?
3. Ask: "Could signal B read the old value of signal A?"
4. Solution: Break the chain with direct reads or settling states

## Related Resources
- See `design_patterns.md` (Serena memory) - Section on FSM design
- See `ghdl_patterns_and_solutions.md` - Simulation debugging

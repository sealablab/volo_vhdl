# CocotB UART Testing Patterns

**Author**: Volo Engineering with Claude Code
**Date**: 2025-10-23
**Context**: Lessons from UART TX core and SimpleSerial V1 TX testing

## Pattern 1: UART Byte Capture with Proper Timing

### The Challenge
Sampling UART bits requires precise timing aligned with baud rate. Off-by-one timing errors lead to sampling wrong bits or framing errors.

### Correct Pattern

```python
async def capture_uart_byte(dut, timeout_cycles=350000):
    """Capture a single UART byte (8N1 format)"""

    # 1. Wait for START bit (falling edge on TX)
    for _ in range(timeout_cycles):
        if dut.uart_tx.value == 0:
            break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError(f"No UART start bit detected")

    # 2. Calculate timing (example: 38400 baud @ 125 MHz)
    baud_divider = 3255  # clk_freq / baud_rate
    half_bit = baud_divider // 2

    # 3. Sample START bit (should be 0)
    await ClockCycles(dut.clk, half_bit)  # ← CRITICAL: Half bit for first sample!
    start_bit = int(dut.uart_tx.value)
    assert start_bit == 0, f"Start bit should be 0, got {start_bit}"

    # 4. Sample 8 DATA bits (LSB first)
    data_bits = []
    for _ in range(8):
        await ClockCycles(dut.clk, baud_divider)  # ← Full bit period
        data_bits.append(int(dut.uart_tx.value))

    # 5. Sample STOP bit (should be 1)
    await ClockCycles(dut.clk, baud_divider)
    stop_bit = int(dut.uart_tx.value)
    assert stop_bit == 1, f"Stop bit should be 1, got {stop_bit}"

    # 6. Wait for UART TX core to fully settle
    await ClockCycles(dut.clk, baud_divider // 2)

    # 7. Convert bits to byte (LSB first)
    byte_value = 0
    for i, bit in enumerate(data_bits):
        byte_value |= (bit << i)

    return byte_value
```

### Key Points

**Timing Sequence**:
```
TX Line:  ____╲___D0__D1__D2__D3__D4__D5__D6__D7__╱────
          IDLE  START            DATA           STOP
Sample:        ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑
             HALF  FULL FULL FULL FULL FULL FULL FULL FULL
```

1. **First sample** (START bit): Wait **half** bit period (to middle of bit)
2. **Subsequent samples**: Wait **full** bit period
3. **After STOP bit**: Wait **additional** time for TX core to settle

**Why the extra settling delay?**
- UART TX core may not immediately de-assert `uart_busy` after stop bit
- Back-to-back transmissions can corrupt if started before core fully settles
- Half a bit period provides safety margin

## Pattern 2: Timeout Calculation for UART

### WRONG Approach
```python
# ❌ BAD: Arbitrary timeout
async def wait_for_tx_done(dut, max_cycles=50000):
    for _ in range(max_cycles):
        ...
```

### RIGHT Approach
```python
# ✅ GOOD: Calculate based on actual timing
async def wait_for_tx_done(dut, max_cycles=200000):
    """
    Timeout calculation:
    - Max frame: 1 cmd + 32 hex chars + 1 newline = 34 characters
    - @ 38400 baud: 34 × 260μs ≈ 8.8ms
    - @ 125 MHz (8ns/cycle): 8.8ms = 1,100,000 cycles
    - Use 200,000 cycles as reasonable timeout for typical frames
    """
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.tx_busy.value == 0:
            return
    raise TimeoutError("TX never completed")
```

### Calculation Template
```python
# 1. Calculate character time
char_time_us = (bits_per_char / baud_rate) * 1e6  # 10 bits / 38400 = 260 μs

# 2. Calculate max frame time
max_chars = 34  # Example: SimpleSerial V1 worst case
max_frame_us = char_time_us * max_chars  # 260 × 34 = 8840 μs

# 3. Convert to clock cycles
clk_freq_hz = 125_000_000
cycles = (max_frame_us / 1e6) * clk_freq_hz  # 8840μs @ 125MHz = 1,105,000 cycles

# 4. Add safety margin (e.g., 2×)
timeout_cycles = int(cycles * 2)  # 200,000 is reasonable for typical frames
```

## Pattern 3: Test Wrapper for Timeout Protection

### The Problem
Tests can hang forever with infinite loops. Example:
```python
# ❌ DANGEROUS: Can hang forever!
@cocotb.test()
async def test_something(dut):
    await setup_clock(dut)

    # Infinite loop if TX never completes
    while dut.tx_busy.value == 1:
        await RisingEdge(dut.clk)
```

### Solution: Use `run_with_timeout()` Wrapper

From `conftest.py`:
```python
from conftest import run_with_timeout

@cocotb.test()
async def test_something(dut):
    """Test description"""
    async def test_logic():
        # All test code goes here
        await setup_clock(dut, clk_signal="clk", period_ns=8.0)
        await reset_active_low(dut, rst_signal="n_reset")

        # Test logic...

        dut._log.info("✓ Test PASSED")

    # Wrapper catches timeouts and provides clear error messages
    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_something")
```

**Benefits**:
- ✅ Wall-clock timeout (prevents infinite simulation loops)
- ✅ Clear error messages with test name
- ✅ Consistent pattern across all tests
- ✅ Original error preserved in exception chain

## Pattern 4: Timeout Loop (for helpers, not tests)

For helper functions that need timeouts:
```python
# ✅ GOOD: Timeout loop with clear error
async def wait_for_condition(dut, condition_fn, max_cycles=10000):
    for _ in range(max_cycles):
        if condition_fn():
            return  # Condition met
        await RisingEdge(dut.clk)
    else:
        # Explicit timeout error
        raise TimeoutError(f"Condition not met in {max_cycles} cycles")

# ❌ BAD: while loop with no timeout
async def wait_for_condition_bad(dut, condition_fn):
    while not condition_fn():  # Can loop forever!
        await RisingEdge(dut.clk)
```

## Pattern 5: Back-to-Back UART Transmissions

### The Challenge
When sending multiple UART frames rapidly, the second transmission may start before the UART TX core fully completes the first.

### Solutions

**Option A: Check busy flag in VHDL**
```vhdl
when STATE_IDLE =>
    -- Only accept new transmission if uart_tx_core is idle
    if send_pulse = '1' and uart_busy = '0' then
        -- Start new transmission
    end if;
```

**Option B: Delay between commands in test**
```python
for cmd in commands:
    # Delay to ensure previous transmission fully completed
    await ClockCycles(dut.clk, 10000)

    # Send command
    dut.cmd_byte.value = cmd
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0

    # Capture response
    frame = await capture_uart_string(dut)
```

**Best Practice**: Use both for robustness!

## Common Pitfalls

### Pitfall 1: Insufficient Settling Time
**Problem**: Stop bit sampled, but UART core still busy
```python
# ❌ Immediate capture after stop bit
stop_bit = int(dut.uart_tx.value)

# ✅ Wait for settling
stop_bit = int(dut.uart_tx.value)
await ClockCycles(dut.clk, baud_divider // 2)
```

### Pitfall 2: Wrong First Sample Timing
**Problem**: Sampling start bit at wrong time
```python
# ❌ WRONG: Full bit period after detecting start
if dut.uart_tx.value == 0:  # Start bit detected here
    await ClockCycles(dut.clk, baud_divider)  # Too late! Now at D0

# ✅ CORRECT: Half bit period to middle of start
if dut.uart_tx.value == 0:  # Start bit detected at edge
    await ClockCycles(dut.clk, half_bit)  # Now in middle of start bit
```

### Pitfall 3: Arbitrary Timeouts
**Problem**: Timeout too short causes false failures
```python
# ❌ Arbitrary
for _ in range(1000):  # Why 1000? Not based on timing!

# ✅ Calculated
char_time_cycles = 32500  # 260μs @ 125MHz
timeout = char_time_cycles * num_chars * 2  # With safety margin
for _ in range(timeout):
```

## Reference: UART Timing Math

```python
def uart_timing_calculator(clk_freq_hz, baud_rate, num_chars):
    """Calculate UART timing in clock cycles"""

    # Baud period
    baud_period_s = 1 / baud_rate

    # Clock period
    clk_period_s = 1 / clk_freq_hz

    # Cycles per bit
    cycles_per_bit = int(baud_period_s / clk_period_s)

    # Character time (10 bits for 8N1)
    cycles_per_char = cycles_per_bit * 10

    # Total transmission time
    total_cycles = cycles_per_char * num_chars

    return {
        'cycles_per_bit': cycles_per_bit,
        'cycles_per_char': cycles_per_char,
        'total_cycles': total_cycles,
        'time_us': (total_cycles * clk_period_s) * 1e6
    }

# Example: 38400 baud @ 125 MHz, 34 chars
timing = uart_timing_calculator(125_000_000, 38400, 34)
# → cycles_per_bit: 3255
# → cycles_per_char: 32550
# → total_cycles: 1,106,700
# → time_us: 8853.6
```

## Related Resources
- `conftest.py` - Shared test utilities (`run_with_timeout`, `setup_clock`, etc.)
- `test_uart_tx_core.py` - Reference UART TX test implementation
- `test_simpleserial_v1_tx.py` - Multi-byte protocol test patterns

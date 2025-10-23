# CocotB Testing Guide for Volo VHDL

## Overview
CocotB (Coroutine-based Cosimulation TestBench) is the **standard testing framework** for the Volo VHDL project. It replaces legacy GHDL testbenches with Python-based async/await testing.

⚠️ **DO NOT CREATE NEW GHDL TESTBENCHES** - Use CocotB instead

## Quick Start

### Running Tests
```bash
cd tests/
make TEST_MODULE=clk_divider_core      # Run specific module
make TEST_MODULE=mcc_primitives        # Run MCC primitives test
make TEST_MODULE=simpleserial_v1_tx    # Run SimpleSerial V1 TX test
make test-all                          # Run all tests
make clean                             # Clean artifacts
make waves                             # View waveforms
```

### Environment Variables
```bash
WAVES=1                    # Enable waveform dump (default)
WAVES=0                    # Disable waveforms for faster tests
COCOTB_LOG_LEVEL=DEBUG     # Set log level (DEBUG/INFO/WARNING/ERROR)
```

## Test Structure

### Basic Template (UPDATED - Always Use Timeout Wrapper!)

**OLD pattern (DEPRECATED - no timeout protection)**:
```python
@cocotb.test()
async def test_something(dut):
    await setup_clock(dut)
    # ... test code ...  # ❌ Can hang forever!
```

**NEW pattern (REQUIRED - with timeout wrapper)**:
```python
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low, run_with_timeout

@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Reset Behavior"""
    async def test_logic():
        dut._log.info("=" * 80)
        dut._log.info("Test 1: Reset Behavior")
        dut._log.info("=" * 80)
        
        await setup_clock(dut)
        dut.enable.value = 1
        await reset_active_low(dut)
        
        assert dut.output.value == 0, "Output should be 0 after reset"
        dut._log.info("✓ Reset test PASSED")
    
    # ✅ ALWAYS wrap with timeout protection
    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_reset_behavior")
```

**Why the Timeout Wrapper?**
- ✅ Prevents infinite loops from hanging tests
- ✅ Provides clear error messages with test name
- ✅ Catches stuck simulations (e.g., UART never starts)
- ✅ Wall-clock timeout (prevents simulation from running forever)
- ✅ Preserves original error in exception chain

**Pattern discovered**: 2025-10-23, SimpleSerial V1 TX development. Learned from `modules/PulseStar/` testbenches.

### Shared Utilities (conftest.py)
All tests can use these helpers from `tests/conftest.py`:

**Timeout Protection** (NEW):
- `run_with_timeout(coro, timeout_sec, test_name)` - Wrap all tests with this!

**Clock Management**:
- `setup_clock(dut, period_ns=10, clk_signal="clk")` - Start clock
- Default: 10ns period (100MHz)

**Reset Sequences**:
- `reset_active_low(dut, cycles=2, rst_signal="rst_n")` - Active-low reset
- `reset_active_high(dut, cycles=2, rst_signal="rst")` - Active-high reset (MCC style)
- `reset_dut(dut, active_low=True)` - Auto-detect reset type

**Signal Monitoring**:
- `count_pulses(signal, clk, num_cycles)` - Count signal pulses
- `wait_for_value(signal, expected, clk, timeout=1000)` - Wait for value with timeout
- `capture_signal_sequence(signal, clk, num_cycles)` - Capture value sequence

**Initialization**:
- `init_dut(dut, clock_period_ns=10, active_low_reset=True)` - Complete init (clock + reset)

**Assertions**:
- `assert_signal_value(signal, expected, message)` - Assert with helpful error
- `assert_pulse_count(signal, clk, cycles, expected, tolerance=0)` - Assert pulse count

## CRITICAL: Timeout Patterns (Added 2025-10-23)

### Pattern 1: NEVER Use Infinite While Loops

**WRONG** (can hang forever):
```python
# ❌ DANGEROUS - infinite loop if TX never goes low!
while dut.uart_tx.value == 1:
    await RisingEdge(dut.clk)
```

**RIGHT** (timeout loop):
```python
# ✅ SAFE - timeout with clear error
for _ in range(timeout_cycles):
    if dut.uart_tx.value == 0:
        break
    await RisingEdge(dut.clk)
else:
    raise TimeoutError(f"UART TX never went low in {timeout_cycles} cycles")
```

### Pattern 2: Calculate Timeouts from Hardware Timing

**WRONG** (arbitrary numbers):
```python
# ❌ Why 5000? Not based on real timing!
for _ in range(5000):
    ...
```

**RIGHT** (calculated from specs):
```python
# ✅ Based on actual hardware timing
# UART byte @ 38400 baud, 125MHz clock:
# - Baud period: 1/38400 = 26.04 μs
# - Bit period: 26.04 μs / 125MHz = 3255 cycles
# - Char time (10 bits): 3255 × 10 = 32,550 cycles
# - Safety margin: 2× = 65,000 cycles

async def wait_for_uart_byte(dut, timeout_cycles=65000):
    """
    Timeout calculation:
    - 1 byte (10 bits) @ 38400 baud = 260 μs
    - @ 125 MHz: 260 μs = 32,500 cycles
    - Safety margin: 2× = 65,000 cycles
    """
    for _ in range(timeout_cycles):
        if dut.tx_busy.value == 0:
            return
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError("TX never completed")
```

### Pattern 3: Timeout Calculation Template

```python
def calculate_uart_timeout(clk_freq_hz, baud_rate, num_chars, safety_factor=2):
    """
    Calculate realistic UART timeout in clock cycles
    
    Example:
        timeout = calculate_uart_timeout(125_000_000, 38400, 34)
        # For SimpleSerial V1 max frame (34 chars)
        # Returns ~2.2M cycles
    """
    # Character time (10 bits for 8N1)
    char_time_s = (10 / baud_rate)
    
    # Total frame time
    frame_time_s = char_time_s * num_chars
    
    # Convert to cycles with safety margin
    cycles = int(frame_time_s * clk_freq_hz * safety_factor)
    
    return cycles

# Usage:
timeout = calculate_uart_timeout(125_000_000, 38400, 34)  # 2.2M cycles
```

## UART Testing Patterns (Added 2025-10-23)

### Pattern 1: UART Byte Capture with Proper Timing

**Critical Discovery**: First sample must be HALF bit, subsequent samples FULL bit!

```python
async def capture_uart_byte(dut, timeout_cycles=350000):
    """Capture a single UART byte (8N1 format)"""
    
    # 1. Wait for START bit with timeout
    for _ in range(timeout_cycles):
        if dut.uart_tx.value == 0:
            break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError("No UART start bit detected")
    
    # 2. Calculate timing
    baud_divider = 3255  # 125MHz / 38400
    half_bit = baud_divider // 2
    
    # 3. Sample START bit (CRITICAL: half bit period!)
    await ClockCycles(dut.clk, half_bit)  # ← To middle of start bit
    start_bit = int(dut.uart_tx.value)
    assert start_bit == 0
    
    # 4. Sample 8 DATA bits (full bit periods)
    data_bits = []
    for _ in range(8):
        await ClockCycles(dut.clk, baud_divider)  # ← Full bit
        data_bits.append(int(dut.uart_tx.value))
    
    # 5. Sample STOP bit
    await ClockCycles(dut.clk, baud_divider)
    stop_bit = int(dut.uart_tx.value)
    assert stop_bit == 1
    
    # 6. Wait for UART core to settle (CRITICAL for back-to-back!)
    await ClockCycles(dut.clk, baud_divider // 2)
    
    # 7. Convert to byte (LSB first)
    byte_value = 0
    for i, bit in enumerate(data_bits):
        byte_value |= (bit << i)
    
    return byte_value
```

**Why the settling delay after stop bit?**
- UART TX core may not immediately de-assert `uart_busy`
- Back-to-back transmissions can corrupt without settling time
- Half bit period provides safety margin

### Pattern 2: Back-to-Back UART Transmissions

**Problem**: Second transmission may start before first fully completes.

**Solution 1 - Check busy in VHDL** (PREFERRED):
```vhdl
when STATE_IDLE =>
    -- Only accept new transmission if UART core is idle
    if send_pulse = '1' and uart_busy = '0' then
        -- Start transmission
    end if;
```

**Solution 2 - Add delay in test**:
```python
for cmd in commands:
    # Delay to ensure previous transmission settled
    await ClockCycles(dut.clk, 10000)
    
    # Send new command
    dut.send_pulse.value = 1
    await RisingEdge(dut.clk)
    dut.send_pulse.value = 0
    
    # Capture response
    frame = await capture_uart_string(dut)
```

**Best Practice**: Use BOTH for robustness!

## MCC Module Testing

### MCC_READY Convention (MANDATORY for all MCC modules)

**Control0[31] = MCC_READY flag (ACTIVE-HIGH)**

This convention solves the \"all-zero reset state\" problem during bitstream loading:

**The Problem**:
When an FPGA bitstream is loaded onto Moku hardware:
1. Bitstream loads → all control registers = 0x00000000
2. Network delay (10-200ms typical) before configuration arrives
3. Registers updated over network with actual configuration
4. Module starts operating

During step 2, the module sees **all zeros** on control inputs. Without MCC_READY, this can cause unpredictable behavior.

**The Solution - CR0[31] as MCC_READY**:
```
Control0[31] = 0 → Module DISABLED (safe during all-zero state)
Control0[31] = 1 → Module ENABLED and ready for operation
```

**VHDL Implementation Pattern** (in Top.vhd):
```vhdl
architecture ModuleName of CustomWrapper is
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal global_enable  : std_logic;
begin
    -- Extract MCC_READY flag (CR0[31])
    mcc_ready     <= Control0(31);
    user_enable   <= Control0(30);  -- Example: user-level enable
    
    -- Gate module with MCC_READY (safe during all-zero state)
    global_enable <= mcc_ready and user_enable;
    
    MODULE_INST: entity WORK.ModuleName
        port map (
            Clk    => Clk,
            Reset  => Reset,
            Enable => global_enable,  -- Safe: disabled when CR0[31]=0
            ...
        );
end architecture;
```

**Benefits**:
- ✓ Safe default: All-zero state keeps module disabled
- ✓ Clear semantic: Bit 31 = "configuration valid and ready"
- ✓ Active-high logic: No confusing inversions
- ✓ Network-aware: External system sets CR0[31]=1 after config loaded
- ✓ Testable: CocotB tests simulate realistic initialization

**Example**: See `modules/EMFI-Seq/top/Top.vhd` for reference implementation

### MCC Primitives (NEW - Added 2025-10-22)

The following primitives in `conftest.py` handle MCC initialization with realistic network latency:

**MCC Initialization**:
- `init_mcc_inputs(dut)` - Zero all InputA-D channels
- `mcc_set_regs(dut, control_regs, set_mcc_ready=True, ...)` - Set control registers with network delay
- `wait_for_mcc_ready(dut, settle_cycles=10)` - Wait for module to stabilize
- `wait_for_first_clk_en(dut, clk_en_signal="clk_en", ...)` - Wait for first clock enable pulse
- `mcc_disable(dut, ...)` - Clear MCC_READY to safely disable module

### MCC Test Initialization Pattern (UPDATED)

**Old pattern** (DEPRECATED - manual register writes):
```python
async def init_control_registers(dut):
    dut.Control0.value = 0x00000000
    dut.Control1.value = 0
    # ... manual initialization
```

**New pattern** (RECOMMENDED - uses MCC primitives):
```python
from conftest import (
    setup_clock,
    reset_active_high,
    init_mcc_inputs,
    mcc_set_regs,
    wait_for_mcc_ready,
    run_with_timeout  # ← Always include!
)

@cocotb.test()
async def test_mcc_initialization(dut):
    async def test_logic():
        # Step 1: Hardware startup
        await setup_clock(dut, clk_signal="Clk")
        await reset_active_high(dut, rst_signal="Reset")
        await init_mcc_inputs(dut)
        
        # Step 2: Simulate network delay + configuration load
        await mcc_set_regs(dut, {
            0: 0x40000001,  # User bits (CR0[31] set automatically)
            1: 0x0000007F,  # Module config
            5: 0x0000199A   # Voltage level
        }, set_mcc_ready=True)  # Automatically sets CR0[31]=1
        
        # Step 3: Wait for module to settle
        await wait_for_mcc_ready(dut)
        
        # Now safe to test module behavior
        dut._log.info("✓ Test PASSED")
    
    # ✅ ALWAYS wrap with timeout
    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_mcc_initialization")
```

### CustomWrapper Entity Stub

For testing MCC modules (those using CustomWrapper), you need the CustomWrapper entity stub:

**File**: `mcc_templates/CustomWrapper_test_stub.vhd`

**Interface** (from MCC spec):
```vhdl
entity CustomWrapper is
    port (
        -- System
        Clk, Reset : in std_logic;
       
        -- Inputs (4 x 16-bit signed ADC)
        InputA, InputB, InputC, InputD : in signed(15 downto 0);
       
        -- Outputs (4 x 16-bit signed DAC)
        OutputA, OutputB, OutputC, OutputD : out signed(15 downto 0);
       
        -- Control Registers (16 x 32-bit std_logic_vector)
        Control0..Control15 : in std_logic_vector(31 downto 0)
    );
end entity CustomWrapper;
```

**Key Points**:
- Control registers are `std_logic_vector(31 downto 0)` NOT `signed`
- Control0[31] = MCC_READY flag (MANDATORY convention)
- MCC provides 16 control registers (Control0-Control15)
- MCC provides 4 input channels (InputA-D) and 4 output channels (OutputA-D)
- Stub must be included in VHDL_SOURCES before module's Top.vhd
- TOPLEVEL must be lowercase: `customwrapper` (GHDL lowercases entity names)

## Test Organization

### File Naming
- Test files: `test_<module_name>.py`
- Example: `test_clk_divider_core.py`, `test_emfi_seq_top.py`, `test_mcc_primitives.py`, `test_simpleserial_v1_tx.py`

### Test Numbering
Use numbered test functions with clear descriptions:
```python
@cocotb.test()
async def test_reset_behavior(dut):
    \"\"\"Test 1: Reset Behavior\"\"\"
    async def test_logic():
        dut._log.info(\"=\" * 80)
        dut._log.info(\"Test 1: Reset Behavior\")
        dut._log.info(\"=\" * 80)
        # ... test code
        dut._log.info(\"✓ Test PASSED\")
    
    await run_with_timeout(test_logic(), timeout_sec=10, test_name=\"test_reset_behavior\")
   
@cocotb.test()
async def test_clock_enable(dut):
    \"\"\"Test 2: Clock Enable Control\"\"\"
    # ... test code
```

### Test Categories
Typical test sequence:
1. **Reset behavior** - Verify reset clears state
2. **MCC initialization** - Verify MCC_READY convention (for MCC modules)
3. **Basic functionality** - Core feature works
4. **Edge cases** - Boundary conditions, special values
5. **Control signals** - Enable, ClkEn, Reset interactions
6. **Randomized inputs** - Runtime-generated test data
7. **Integration** - Multi-module interactions
8. **Summary** - Final validation message

## Best Practices

### 1. ALWAYS Use Timeout Wrapper (NEW!)
```python
@cocotb.test()
async def test_something(dut):
    async def test_logic():
        # All test code here
        pass
    
    # ✅ MANDATORY - prevents infinite loops
    await run_with_timeout(test_logic(), timeout_sec=15, test_name="test_something")
```

### 2. Calculate Timeouts from Specs (NEW!)
```python
# ❌ BAD - arbitrary number
timeout = 5000

# ✅ GOOD - based on hardware timing
baud_rate = 38400
clk_freq = 125_000_000
bits_per_char = 10
cycles_per_char = (clk_freq / baud_rate) * bits_per_char  # 32,552
timeout = cycles_per_char * num_chars * 2  # With safety margin
```

### 3. Use Runtime Randomization
```python
import random

@cocotb.test()
async def test_randomized_delays(dut):
    async def test_logic():
        random.seed()  # Use current time
        delay = random.randint(2, 15)
        dut._log.info(f"Random delay: {delay}")
        dut.delay_config.value = delay
        # ... verify behavior
    
    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_randomized_delays")
```

### 4. Clear Logging
```python
dut._log.info(\"=\" * 80)
dut._log.info(\"Test 3: Random Configuration\")
dut._log.info(\"=\" * 80)
dut._log.info(f\"Config: delay={delay}, threshold={threshold}\")
dut._log.info(\"✓ Test PASSED\")
```

### 5. Helpful Assertions
```python
assert actual == expected, \\
    f\"Mismatch: expected {expected:#x}, got {actual:#x}\"
```

### 6. Test Independence
Each test should:
- Initialize its own clock
- Apply its own reset
- Set all required signals
- Not depend on other tests' state
- Be wrapped in `run_with_timeout()`

### 7. Avoid Magic Numbers
```python
# Bad
dut.config.value = 0x199A

# Good
VOLTAGE_1V1 = 0x199A  # From Moku_Voltage_pkg
dut.config.value = VOLTAGE_1V1
```

## Working Examples

### Simple Core Test
**File**: `tests/test_clk_divider_core.py` (7 tests passing)
- Reset behavior
- Division ratios (power-of-2 and arbitrary)
- Enable control
- Edge cases (div=1, div=256)

### UART Protocol Test (NEW!)
**File**: `tests/test_simpleserial_v1_tx.py` (9 tests passing)
- Multi-byte UART protocol (SimpleSerial V1)
- Hex encoding, payload handling
- Back-to-back transmissions
- **Demonstrates**: Timeout patterns, UART timing, FSM testing
- **Lessons**: Delta-cycle races, enable control semantics, busy flag checking

### Package Test
**File**: `tests/test_moku_voltage_pkg.py` (3 tests passing)
- Package function testing
- Voltage conversion validation

### MCC Integration Test
**File**: `tests/test_emfi_seq_top.py` (7 tests)
- CustomWrapper stub usage
- MCC control register mapping
- Multi-core integration
- Runtime randomization

### MCC Primitives Test
**File**: `tests/test_mcc_primitives.py` (6 tests passing)
- MCC_READY all-zero state safety
- Network latency simulation
- Enable/disable sequences
- Runtime register updates
- Complete initialization workflow

## Common Pitfalls

### 1. Not Using Timeout Wrapper (NEW!)
```python
# ❌ WRONG - can hang forever
@cocotb.test()
async def test_bad(dut):
    while dut.tx_busy.value:  # Infinite loop!
        await RisingEdge(dut.clk)

# ✅ CORRECT - timeout protected
@cocotb.test()
async def test_good(dut):
    async def test_logic():
        for _ in range(timeout):
            if not dut.tx_busy.value:
                break
            await RisingEdge(dut.clk)
        else:
            raise TimeoutError()
    
    await run_with_timeout(test_logic(), timeout_sec=10, test_name="test_good")
```

### 2. Wrong UART Sampling Timing (NEW!)
```python
# ❌ WRONG - samples wrong bits
await ClockCycles(dut.clk, baud_divider)  # Always full bit
start_bit = int(dut.uart_tx.value)

# ✅ CORRECT - half bit for first sample
await ClockCycles(dut.clk, half_bit)  # Half bit to middle
start_bit = int(dut.uart_tx.value)
```

### 3. Clock Signal Naming
```python
# MCC modules use capital Clk
await setup_clock(dut, clk_signal=\"Clk\")

# Core modules use lowercase clk
await setup_clock(dut, clk_signal=\"clk\")
```

### 4. Reset Polarity
```python
# Active-low (rst_n)
await reset_active_low(dut, rst_signal=\"rst_n\")

# Active-high (Reset - MCC style)
await reset_active_high(dut, rst_signal=\"Reset\")
```

## Debugging

### Enable Waveforms
```bash
make TEST_MODULE=my_module WAVES=1
make waves  # View in GTKWave
```

### Increase Log Level
```bash
COCOTB_LOG_LEVEL=DEBUG make TEST_MODULE=my_module
```

### Add Debug Logging
```python
@cocotb.test()
async def test_debug(dut):
    async def test_logic():
        dut._log.info(f\"Signal value: {dut.signal.value}\")
        dut._log.info(f\"State: {dut.state.value}\")
    
    await run_with_timeout(test_logic(), timeout_sec=10, test_name=\"test_debug\")
```

## Adding New Tests

1. **Create test file**: `tests/test_<module>.py`
2. **Add Makefile entry**: Update `tests/Makefile`
3. **Include dependencies**: List all VHDL sources in compilation order
4. **Set TOPLEVEL**: Use lowercase entity name
5. **Write tests**: Use async/await pattern with `run_with_timeout()`
6. **Use MCC primitives**: For MCC modules, use mcc_set_regs(), etc.
7. **Run**: `make TEST_MODULE=<module>`
8. **Update help**: Add to `make list-tests` output

## Reference Files

- **Template**: `tests/test_clk_divider_core.py` - Core module example
- **UART Template**: `tests/test_simpleserial_v1_tx.py` - Protocol testing example (NEW!)
- **MCC Template**: `tests/test_mcc_primitives.py` - MCC initialization example
- **Utilities**: `tests/conftest.py` - Shared helper functions
- **Makefile**: `tests/Makefile` - Build system integration
- **README**: `tests/README.md` - User-facing documentation
- **MCC Stub**: `mcc_templates/CustomWrapper_test_stub.vhd` - CustomWrapper entity
- **Patterns**: `docs/COCOTB_UART_TEST_PATTERNS.md` - UART testing deep dive (NEW!)
- **VHDL Patterns**: `docs/VHDL_DELTA_CYCLE_PATTERNS.md` - Delta-cycle races (NEW!)

## Summary

✅ **DO**:
- **ALWAYS wrap tests with `run_with_timeout()`** (prevents infinite loops)
- Calculate timeouts from hardware specs (not arbitrary numbers)
- Use timeout loops (`for _ in range()`) not `while` loops
- Import helpers from conftest.py
- Use MCC primitives for MCC modules
- Follow MCC_READY convention (CR0[31] active-high)
- Simulate network latency for realistic tests
- Add clear logging and assertions
- Use runtime randomization
- Test each module independently
- For UART: Half bit first sample, full bit after, settling delay after stop

❌ **DON'T**:
- Create new GHDL testbenches
- Use `while` loops without timeouts (can hang forever!)
- Use arbitrary timeout values (calculate from specs!)
- Hard-code test values (use constants)
- Skip MCC_READY implementation in Top.vhd
- Manually write Control0 without mcc_set_regs
- Skip network latency simulation
- Assume instant register updates
- Rely on test execution order
- Forget to add Makefile entry
- Sample UART bits at wrong timing (half/full bit pattern!)

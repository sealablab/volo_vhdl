# CocotB Testing Patterns - Lessons Learned
**Purpose**: Python-based hardware testing best practices for CocotB framework

**Status**: Living document - will migrate to Serena memories when mature

**Last Updated**: 2025-10-23

---

## Tier 1: Critical (Must Follow)

### ✅ DO: Use conftest.py helper functions
- **Available helpers** (from `tests/conftest.py`):
  - `setup_clock(dut)` - Start 10ns period clock (100 MHz)
  - `reset_active_low(dut, rst_signal="n_reset")` - 2-cycle reset
  - `reset_active_high(dut, rst_signal="Reset")` - 2-cycle reset
  - `init_mcc_inputs(dut)` - Initialize MCC platform inputs
  - `mcc_set_regs(dut, regs_dict)` - Set MCC control registers
  - `count_pulses(dut, signal, duration_cycles)` - Count pulses on signal
- **Example**:
  ```python
  from conftest import setup_clock, reset_active_low

  @cocotb.test()
  async def test_reset_behavior(dut):
      await setup_clock(dut)
      dut.enable.value = 1
      await reset_active_low(dut, rst_signal="n_reset")
      assert dut.output.value == 0
  ```

### ✅ DO: Convert LogicArray to int before bitwise operations
- **Problem**: `dut.stat_reg.value & 0x01` fails with TypeError
- **Solution**: `int(dut.stat_reg.value) & 0x01`
- **Example**:
  ```python
  # ❌ BAD
  assert dut.stat_reg.value & 0x01 == 0

  # ✅ GOOD
  assert int(dut.stat_reg.value) & 0x01 == 0
  ```

### ✅ DO: Set all inputs before first clock cycle
- **Pattern**:
  ```python
  await setup_clock(dut)
  dut.enable.value = 1      # Set BEFORE reset
  dut.clk_en.value = 1      # Set BEFORE reset
  dut.mode.value = 0        # Set BEFORE reset
  await reset_active_low(dut)
  ```

### ❌ DON'T: Use empty strings in dut._log.info()
- **Problem**: `dut._log.info("")` causes "IndexError: list index out of range"
- **Solution**: Use non-empty string or skip logging
- **Example**:
  ```python
  # ❌ BAD
  dut._log.info("")
  dut._log.info("")

  # ✅ GOOD
  dut._log.info("Module Summary:")
  dut._log.info("  - Feature 1")
  ```

---

## Tier 2: Important (Strongly Recommended)

### ✅ DO: Test boundary conditions explicitly
- **Examples**:
  - Minimum value (0, 1 cycle)
  - Maximum value (255, 256 cycles)
  - Boundary transitions (mode changes)
- **Pattern** (from test_edge_detector.py):
  ```python
  # Test each mode explicitly
  for mode in [MODE_RISING, MODE_FALLING, MODE_BOTH, MODE_OFF]:
      dut.mode.value = mode
      # Test behavior in this mode
  ```

### ✅ DO: Use descriptive test names and clear assertions
- **Pattern**:
  ```python
  @cocotb.test()
  async def test_rising_edge_detection(dut):
      """Test 2: Rising Edge Detection (mode=00)"""
      dut._log.info("Test 2: Rising Edge Detection")

      # Test with clear assertion messages
      assert dut.edge_out.value == 1, "Rising edge should be detected"
      assert dut.edge_out.value == 0, "Falling edge should NOT be detected in rising-only mode"
  ```

### ✅ DO: Test enable control (freeze/resume behavior)
- **Pattern**:
  ```python
  # Disable mid-operation
  dut.enable.value = 0
  frozen_value = int(dut.output.value)

  await ClockCycles(dut.clk, 10)
  assert int(dut.output.value) == frozen_value, "Output should freeze when disabled"

  # Re-enable
  dut.enable.value = 1
  await ClockCycles(dut.clk, 1)
  # Verify resumed operation
  ```

---

## Tier 3: Nice to Know (Best Practices)

### ✅ DO: Structure tests with clear sections
- **Pattern**:
  ```python
  @cocotb.test()
  async def test_feature(dut):
      """Test N: Feature Description"""
      dut._log.info("=" * 70)
      dut._log.info("Test N: Feature Description")
      dut._log.info("=" * 70)

      # Setup
      await setup_clock(dut)
      await reset_active_low(dut)

      # Test actions
      dut.input.value = 1
      await ClockCycles(dut.clk, 1)

      # Assertions
      assert dut.output.value == expected, "Clear failure message"

      dut._log.info("✓ Feature test PASSED")
  ```

### ✅ DO: Include a summary test at the end
- **Purpose**: Clean test output, confirms all tests ran
- **Example**:
  ```python
  @cocotb.test()
  async def test_summary(dut):
      """Test 10: Summary"""
      dut._log.info("=" * 70)
      dut._log.info("ALL TESTS PASSED!")
      dut._log.info("=" * 70)
      dut._log.info("Module Summary:")
      dut._log.info("  - Feature 1")
      dut._log.info("  - Feature 2")
      dut._log.info("✓ All 9 tests completed successfully!")
  ```

---

## Common Test Patterns

### Pattern 1: Reset Behavior Test
```python
@cocotb.test()
async def test_reset_behavior(dut):
    await setup_clock(dut)
    dut.enable.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    assert dut.output.value == 0, "Output should be 0 after reset"
    assert int(dut.stat_reg.value) & 0x01 == 0, "Status bit should be cleared"
```

### Pattern 2: Back-to-Back Operations Test
```python
@cocotb.test()
async def test_back_to_back(dut):
    await setup_clock(dut)
    await reset_active_low(dut)

    # First operation
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 1)
    # Wait for completion
    await ClockCycles(dut.clk, N)

    # Second operation (immediate, no gap)
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 1)
    assert dut.output.value == expected
```

### Pattern 3: Rapid Toggling Test
```python
@cocotb.test()
async def test_rapid_toggling(dut):
    await setup_clock(dut)
    await reset_active_low(dut)

    edge_count = 0
    for i in range(10):
        dut.input.value = i % 2  # Alternate 0, 1, 0, 1...
        await ClockCycles(dut.clk, 1)
        if dut.edge_out.value == 1:
            edge_count += 1

    assert edge_count >= expected_min
```

---

## Known Issues / Gotchas

1. **Empty log strings**: Causes IndexError - always use non-empty messages
2. **LogicArray bitwise ops**: Must convert to int first
3. **Signal setup timing**: Set all inputs BEFORE reset, not after
4. **Pulse counting**: Off-by-one errors common - verify trigger vs pulse timing

---

## Success Examples

### volo_edge_detector (10/10 tests passing)
- **File**: `tests/test_edge_detector.py`
- **Coverage**: All modes, enable control, rapid toggling, back-to-back edges
- **Pattern**: Clear test structure, good assertion messages

---

**Next Steps**: Add lessons from volo_counter_nbit testing

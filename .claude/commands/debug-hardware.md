# Hardware Debugging Mode (Oscilloscope-Based)

You are debugging a VHDL module on Moku hardware using oscilloscope observation only (no internal signal access).

## Workflow

Follow these steps in order:

### 1. Verify Simulation Baseline

```bash
cd tests/
uv run make TEST_MODULE=<module>_oscilloscope_only
```

**✅ Requirement**: All CocotB oscilloscope-only tests must pass before hardware testing.

### 2. Run Hardware Tests

```bash
cd tests/
uv run python test_<module>_mokubench.py \
  --ip <MOKU_IP> \
  --bitstream ../modules/<module>/latest/*_bitstreams.tar
```

### 3. Debug Failures Incrementally

For each test failure:

**a) Add Diagnostic Output**:
```python
# Verify state before action
status_before = get_state(osc)
print(f"Before: {status_before['state_name']} (Fault={status_before['fault']}, Valid={status_before['valid']})")

# Trigger action
mcc.set_control(1, new_value)

# Poll for result (don't trust single sample!)
for i in range(10):
    time.sleep(0.1)
    status = get_state(osc)
    print(f"  Poll {i}: {status['state_name']}")
    if status['state_name'] == expected:
        break

# Verify final state
print(f"After: {status['state_name']}")
```

**b) Commit Discovery Immediately**:
```bash
git add <test_file>
git commit -m "<Title: What was discovered>

<Problem description>
<Solution applied>
<Hypothesis/reasoning>"
```

**c) Test Again**:
Repeat hardware test to verify fix works.

### 4. Document Findings

After all tests pass (or skip with documentation):

**a) Update Test Docstrings**:
```python
def test_5_checksum_error(mcc, osc):
    """Test 5: Detect checksum mismatch

    ⚠️  KNOWN LIMITATION: Cannot run after Test 4 without power cycle

    State machine has no software reset path from RUNNING→IDLE.
    Workarounds:
    1. Run Test 5 standalone (comment out Test 4)
    2. Swap test order (Test 5 before Test 4)
    3. Power cycle hardware between runs
    """
```

**b) Update Serena Memory** (if new techniques discovered):
```python
mcp__serena__write_memory(
    memory_name="oscilloscope_debugging_techniques",
    content="<append new discoveries>"
)
```

## Key Principles

### ⚠️ Common Pitfalls (Check FIRST on failure)

1. **Voltage Scaling Error** (5× mistake):
   - Moku uses **±5V** full scale, not ±1V!
   - Check `voltage_to_digital()` function
   - Search for: `/ 1.0)` and change to `/ 5.0)`

2. **Single Sample Miss** (oscilloscope latency):
   - Don't trust single `osc.get_data()` call
   - Use 10-poll loop with 0.1s intervals
   - Print each poll result for visibility

3. **Sticky Fault Flags** (hardware reset only):
   - Use Valid flag as primary indicator
   - Fault flag may be from previous test
   - Check: `status['valid'] == True` (not fault)

4. **State Machine Limitations** (no software reset):
   - Map state transitions before testing
   - Check prerequisites before each test
   - Skip gracefully if state incompatible

### Git Commit Pattern

**User Request (2025-10-24)**:
> "Use the same messages you print to me (literally, the same, do not regenerate them) in your git commit messages."

**Benefits**:
- Token efficiency (don't duplicate)
- Learning trail (git history = debugging journey)
- Reproducibility (others can follow steps)

**Example**:
```python
# Print to user:
print("  ⚠ Fault detected - switching to Error Diagnostics (View 6)")
print("  → Error code: 0x2 (OVERFLOW)")

# Commit with SAME message:
git commit -m "Test 4 debug: Detected buffer overflow via View 6

- ⚠ Fault detected - switching to Error Diagnostics (View 6)
- → Error code: 0x2 (OVERFLOW)
- Root cause: write_ptr exceeded buffer_length"
```

### Test Structure (CocotB ↔ MokuBench Mirroring)

**Must be identical** so methodology works in both simulation and hardware:

```python
# CocotB (simulation):
dut.control1.value = 8 << 16
await ClockCycles(dut.clk, 2)
osc_voltage = float(dut.debug_out_a.value.signed_integer) / 32768.0 * 5.0
status = decode_view_0_status_summary(osc_voltage)

# MokuBench (hardware):
mcc.set_control(1, 8 << 16)
time.sleep(0.2)  # Wait for propagation
data = osc.get_data()
osc_voltage = data['ch1'][len(data['ch1']) // 2]
status = decode_view_0_status_summary(osc_voltage)  # SAME function!
```

### Debugging Checklist

When test fails, check in this order:

1. ✅ CocotB test passes? (simulation baseline)
2. ✅ Voltage scaling ±5V? (not ±1V)
3. ✅ Polling for transitions? (10× with 0.1s)
4. ✅ State verified before action? (print initial state)
5. ✅ Valid flag used? (not sticky Fault flag)
6. ✅ Multiple views checked? (View 0 → View 6)
7. ✅ Delays sufficient? (0.1-0.2s after writes)
8. ✅ State machine path valid? (map transitions)

### Multi-View Debug Strategy

```python
# Start with Status Summary (View 0)
set_debug_views(mcc, VIEW_STATUS_SUMMARY)
status = decode_view_0(get_voltage(osc))

if status['fault']:
    # Drill down with Error Diagnostics (View 6)
    print("  ⚠ Fault detected - switching to View 6")
    set_debug_views(mcc, VIEW_ERROR_DIAGNOSTICS)
    time.sleep(0.1)

    error = decode_view_6(get_voltage(osc))
    print(f"  Error code: {error['error_code']}")
    print(f"  Error state: {error['error_state']}")
```

## Reference Documentation

- **Comprehensive Guide**: `docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md`
- **AI Context**: Serena memory `oscilloscope_debugging_techniques`
- **Example Module**: `modules/inspectable_buffer_loader/`
- **Example Tests**: `tests/test_inspectable_buffer_loader_mokubench.py`

## Success Criteria

Tests are complete when:
- ✅ All CocotB oscilloscope-only tests pass (simulation)
- ✅ Hardware tests mirror CocotB exactly (same structure)
- ✅ Tests PASS or SKIP gracefully (with documentation)
- ✅ Known limitations documented (in test docstrings)
- ✅ Git history shows incremental discoveries (commits)
- ✅ Serena memory updated (if new techniques discovered)

**Example Success**: `inspectable_buffer_loader` (2025-10-24)
- 6/6 CocotB tests PASSED
- 4/5 MokuBench tests PASSED, 1 SKIPPED (documented)
- 5 incremental git commits (learning trail)
- State machine limitation discovered and documented

---

Now begin debugging. Report each discovery as you find it, and commit immediately with the same message.

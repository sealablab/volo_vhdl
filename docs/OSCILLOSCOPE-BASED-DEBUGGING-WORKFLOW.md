# Oscilloscope-Based Hardware Debugging Workflow

**Author**: Discovered through human/AI collaborative debugging (2025-10-24)
**Module**: inspectable_buffer_loader (build 25ff4c4)
**Key Insight**: Incremental debugging with git commits creates a learning trail

## Philosophy

**Principle**: "Show, don't tell" - Make hardware state visible through oscilloscope outputs, not internal signals.

**Benefits**:
- Debugging methodology matches user's actual workflow (oscilloscope observation)
- No dependency on internal signal access (works on deployed bitstreams)
- Test scripts work identically in simulation (CocotB) and hardware (MokuBench)
- Git history documents the debugging journey for future reference

## Workflow Overview

```
1. Design Phase      → Add debug multiplexers (8 views per output channel)
2. Simulation Phase  → CocotB oscilloscope-only tests (baseline truth)
3. Synthesis Phase   → CloudCompile deployment (incoming/ folder pattern)
4. Hardware Phase    → MokuBench tests (mirrors CocotB exactly)
5. Debug Phase       → Incremental fixes with git commits
6. Documentation     → Capture learnings in Serena memories
```

## Design Phase: Debug Multiplexer Architecture

### Pattern: 8 Selectable Views per Output Channel

```vhdl
-- Control0 bit allocation for debug:
--   [26:24] = DEBUG_SELECT_A (OutputA view: 0-7)
--   [23:21] = DEBUG_SELECT_B (OutputB view: 0-7)

-- Standard debug views (customize per module):
--   View 0: Status Summary (state + fault + valid + address)
--   View 1: Data Comparison (expected vs actual)
--   View 2: Write Activity (indexes + pointers)
--   View 3: Data Snapshot (first/last chunk words)
--   View 4: Memory Readback (BRAM contents at address)
--   View 5: Timing Diagnostics (strobe protocol, counters)
--   View 6: Error Diagnostics (error codes + state capture)
--   View 7: Reserved (future use)
```

### Voltage Guard Bands (CRITICAL for oscilloscope readability)

```vhdl
-- Left-shift debug values by 2-3 bits to create voltage spacing
-- Example: state=3 → output=0x000C (not 0x0003)
-- Voltage difference: 4× larger (~3.2mV instead of ~0.8mV)
-- Prevents ADC quantization noise from blurring adjacent values
```

### Reference Implementation
- **Module**: `modules/inspectable_buffer_loader/core/debug_mux.vhd`
- **View Count**: 8 per channel (16 total debug views)
- **Guard Band**: 2-bit left shift (multiply by 4)

## Simulation Phase: CocotB Oscilloscope-Only Tests

### Key Principle: Test WITHOUT Internal Signal Access

```python
# ❌ BAD: Accessing internal signals
assert dut.state_reg.value == IDLE_STATE

# ✅ GOOD: Decoding oscilloscope voltage
osc_voltage = float(dut.debug_out_a.value.signed_integer) / 32768.0 * 5.0
status = decode_view_0_status_summary(osc_voltage)
assert status['state_name'] == "IDLE"
```

### Voltage Decoding (Moku Platform Specification)

```python
def voltage_to_digital(voltage: float) -> int:
    """Convert oscilloscope voltage to 16-bit signed digital value

    Moku platform specification:
    - Digital range: -32768 to +32767 (16-bit signed)
    - Voltage range: -5.0V to +5.0V (full-scale analog)
    - Scaling: 32768 / 5.0V = 6553.6 digital per volt
    """
    digital = int((voltage / 5.0) * 32768)  # NOT ±1V!
    return max(-32768, min(32767, digital))
```

**Common Mistake**: Assuming ±1V full scale → 5× voltage error!

### Test Structure

```python
# Test mirrors hardware workflow exactly:
1. Setup clock and reset
2. Configure debug views (Control0[26:21])
3. Perform action (e.g., set Control1)
4. Read oscilloscope voltage
5. Decode voltage to digital value
6. Extract debug fields
7. Assert expected behavior

# Example from inspectable_buffer_loader:
@cocotb.test()
async def test_2_observe_state_transition_idle_to_loading(dut):
    """Test 2: Watch IDLE → LOADING transition via oscilloscope"""
    # Setup
    await setup_clock(dut, clk_signal="clk")
    set_debug_views(dut, VIEW_STATUS_SUMMARY)
    await reset_active_low(dut, rst_signal="n_reset")

    # Observe initial state
    osc_voltage = float(dut.debug_out_a.value.signed_integer) / 32768.0 * 5.0
    status_before = decode_view_0_status_summary(osc_voltage)

    # Trigger action
    dut.control1.value = 8 << 16
    await ClockCycles(dut.clk, 2)

    # Verify transition
    osc_voltage = float(dut.debug_out_a.value.signed_integer) / 32768.0 * 5.0
    status_after = decode_view_0_status_summary(osc_voltage)
    assert status_after['state_name'] == "LOADING"
```

### Benefits of Oscilloscope-Only Testing
- Tests work identically on hardware (no code changes)
- Forces proper debug view design
- Validates voltage scaling early (simulation catches ±1V vs ±5V errors)
- Creates "known-good" baseline before hardware deployment

## Hardware Phase: MokuBench Testing

### Pattern: Mirror CocotB Tests Exactly

```python
# CocotB (simulation):
dut.control1.value = 8 << 16
await ClockCycles(dut.clk, 2)
osc_voltage = float(dut.debug_out_a.value.signed_integer) / 32768.0 * 5.0

# MokuBench (hardware):
mcc.set_control(1, 8 << 16)
time.sleep(0.2)  # Wait for propagation
data = osc.get_data()
osc_voltage = data['ch1'][len(data['ch1']) // 2]

# Same decoding function for both!
status = decode_view_0_status_summary(osc_voltage)
```

### Hardware-Specific Issues Discovered

#### 1. Oscilloscope Sampling Latency

**Problem**: Single oscilloscope sample may show cached data from before MCC register write.

**Solution**: Poll multiple times to catch transition

```python
# ❌ Single sample (may miss transition):
mcc.set_control(1, 8 << 16)
time.sleep(0.2)
data = osc.get_data()
status = decode_view_0_status_summary(data['ch1'][...])

# ✅ Poll until transition detected:
mcc.set_control(1, 8 << 16)
for i in range(10):
    time.sleep(0.1)
    data = osc.get_data()
    status = decode_view_0_status_summary(data['ch1'][...])
    print(f"  Poll {i}: {status['state_name']}")
    if status['state_name'] == "LOADING":
        break
```

**Git Commit**: `12410bf` - "Test 2 debug: Poll oscilloscope to catch state transition"

#### 2. Sticky Fault Flags

**Problem**: Fault flags only clear on hardware reset (n_reset), not software reset (clearing Control0).

**Solution**: Use Valid flag as primary success indicator

```python
# ❌ Checking only fault flag:
assert status['fault'] == False  # Fails if previous test set fault

# ✅ Checking Valid flag (updated per operation):
assert status['valid'] == True   # Primary success indicator
if status['fault']:
    print("  ⚠ Note: Fault flag is sticky (cleared only on hardware reset)")
    print("  ✓ But Valid=True indicates buffer loaded successfully!")
```

**Git Commit**: `ba4ddb5` - "Test 4 adjusted for sticky fault flag"

#### 3. State Machine Path Limitations

**Problem**: Some state machines have no software-controllable reset path.

**Example**: `IDLE → LOADING → ... → READY ⟷ RUNNING` (no path back to IDLE)

**Solution**: Detect state before test, skip if prerequisites not met

```python
def test_5_checksum_error(mcc, osc):
    """Test 5: Requires IDLE state to trigger new load"""

    # Check prerequisites
    status = get_current_state(osc)
    if status['state_name'] not in ["IDLE", "LOADING"]:
        print(f"⚠️  SKIPPING: Module in {status['state_name']} state")
        print("   Cannot trigger new load without hardware reset")
        print("   Workarounds: 1) Run test standalone, 2) Swap test order")
        return

    # Continue with test...
```

**Git Commit**: `d718da2` - "CRITICAL DISCOVERY: State machine has no software reset path"

## Debug Phase: Incremental Git Commits

### Pattern: Commit Each Discovery Immediately

**User Request (2025-10-24)**:
> "please check all changes in to this debug script as you iterate (even if they are small).
> The git history is a great way to show off your learning. You can use the same messages
> you print to me (literally, the same, do not regenerate them) in your git commit messages."

### Benefits
1. **Learning Trail**: Git history documents debugging journey
2. **Token Efficiency**: Don't duplicate messages to user and git (reuse exactly)
3. **Reproducibility**: Others can follow same debugging steps
4. **Rollback**: Easy to undo failed hypotheses
5. **Documentation**: Commit messages explain "why" not just "what"

### Commit Message Format

```bash
# Template:
git commit -m "<Title: What was discovered>

<Problem description>
<Solution/fix applied>
<Hypothesis/reasoning>

Git Commit: <short-hash> - <one-line summary>"
```

### Example from inspectable_buffer_loader

```
Commit: 12410bf
Message: Test 2 debug: Poll oscilloscope multiple times to catch state transition

- Add 10-poll loop with 0.1s intervals to detect IDLE→LOADING transition
- Issue: Oscilloscope may show cached data from before Control1 write
- Hypothesis: MCC set_control() or oscilloscope sampling has propagation delay
```

### Workflow

```python
# 1. Make incremental change
# 2. Test on hardware
# 3. Print result to user
# 4. Use SAME message in git commit

print("  ⚠ Note: Fault flag is sticky (cleared only on hardware reset)")
print("  ✓ But Valid=True indicates buffer loaded successfully!")

# Commit with same message:
git commit -m "Test 4 adjusted for sticky fault flag

- Use Valid=True as primary success indicator
- Fault flag only clears on hardware reset (n_reset signal)
- Previous tests may leave fault flag set
- ⚠ Note: Fault flag is sticky (cleared only on hardware reset)
- ✓ But Valid=True indicates buffer loaded successfully!"
```

## Oscilloscope Debugging Tips & Tricks

### 1. Voltage Guard Bands

**Problem**: Adjacent digital values (e.g., state=3 vs state=4) too close in voltage (~0.8mV)

**Solution**: Left-shift by 2-3 bits before output

```vhdl
-- Without guard band:
debug_out <= to_signed(to_integer(state_reg), 16);
-- state=3 → 0x0003 → 0.46mV (easily corrupted by noise)

-- With guard band:
debug_out <= to_signed(to_integer(state_reg) * 4, 16);
-- state=3 → 0x000C → 1.83mV (4× spacing, much cleaner)
```

### 2. Poll Multiple Times for Transitions

**Problem**: Single sample may miss fast transitions or show cached data

**Solution**: Loop with delays to catch transition

```python
# Poll 10× with 100ms intervals (1 second total)
for i in range(10):
    time.sleep(0.1)
    data = osc.get_data()
    status = decode_status(data['ch1'][...])
    print(f"  Poll {i}: {status['state_name']}")
    if status['state_name'] == expected_state:
        break
```

### 3. Verify State Before and After Actions

**Problem**: Assumptions about initial state may be wrong

**Solution**: Always read state before triggering action

```python
# ✅ Explicit verification:
status_before = get_state(osc)
print(f"Before: {status_before['state_name']}")

mcc.set_control(1, new_value)
time.sleep(0.2)

status_after = get_state(osc)
print(f"After: {status_after['state_name']}")
assert status_after != status_before  # Verify change occurred
```

### 4. Use Multiple Views for Root Cause Analysis

**Pattern**: Start with Status Summary (View 0), drill down with specialized views

```python
# Step 1: Detect fault in View 0 (Status Summary)
status = decode_view_0(osc_voltage)
if status['fault']:
    print("  ⚠ Fault detected - switching to Error Diagnostics (View 6)")
    mcc.set_control(0, mcc_cr0() | (6 << 21))  # Switch to View 6
    time.sleep(0.1)

    # Step 2: Read error details from View 6
    error_info = decode_view_6_error_diagnostics(osc_voltage)
    print(f"  Error code: {error_info['error_code']}")
    print(f"  Error state: {error_info['error_state']}")
```

### 5. Account for Sticky Flags

**Problem**: Hardware reset-only flags persist across software resets

**Solution**: Use non-sticky flags as primary indicators

```python
# Priority order for success detection:
# 1. Valid flag (updated per operation)
# 2. State (shows current progress)
# 3. Fault flag (sticky, may be from previous operation)

assert status['valid'] == True      # Primary indicator
assert status['state_name'] in ["READY", "RUNNING"]  # Secondary
# Don't assert status['fault'] == False  # Sticky, unreliable
```

### 6. Understand State Machine Paths Before Testing

**Problem**: Tests fail due to impossible state transitions

**Solution**: Map state machine before writing tests

```
State Machine Diagram (inspectable_buffer_loader):

    IDLE
     ↓ (buffer_length > 0)
   LOADING
     ↓ (LOAD_STROBE)
   WRITING_CHUNK
     ↓ (chunk complete)
   WRITING_BRAM
     ↓ (LOAD_COMPLETE)
   VALIDATING
     ↓ (checksum OK)
   READY ⟷ RUNNING
   ↑       (enable toggle)

⚠️ No path back to IDLE without hardware reset!
```

**Test Ordering Implications**:
- Tests requiring IDLE state must run first
- Later tests must adapt to READY/RUNNING states
- Some tests may need standalone execution

### 7. Correct Voltage Scaling (CRITICAL)

**Problem**: Assuming ±1V full scale → 5× voltage error

**Solution**: Always use Moku platform specification (±5V)

```python
# ❌ WRONG (common mistake):
digital = int((voltage / 1.0) * 32768)  # Off by 5×!

# ✅ CORRECT:
digital = int((voltage / 5.0) * 32768)  # Moku full scale

# Reference: modules/volo_common/common/Moku_Voltage_pkg.vhd
# constant MOKU_VOLTAGE_MIN : real := -5.0;
# constant MOKU_VOLTAGE_MAX : real := 5.0;
```

## Documentation Phase: Capture Learnings

### Update Serena Memories After Debugging Session

```bash
# After successful debugging session, capture learnings:
mcp__serena__write_memory(
    memory_name="oscilloscope_debugging_techniques",
    content="<tips and tricks discovered>"
)

# Update module-specific documentation:
mcp__serena__write_memory(
    memory_name="inspectable_buffer_loader_hardware_validation",
    content="<hardware test results and known issues>"
)
```

### Document Known Limitations in Code

```python
def test_5_checksum_error(mcc, osc):
    """Test 5: Detect checksum mismatch via oscilloscope

    ⚠️  KNOWN LIMITATION: This test can only run ONCE per hardware power cycle!

    The state machine has no software-controllable path from RUNNING→IDLE.
    Once Test 4 loads a buffer, we cannot trigger a new load without hardware reset.

    Workarounds:
    1. Run ONLY Test 5 (comment out Test 4)
    2. Swap test order (Test 5 before Test 4)
    3. Power cycle hardware between test runs
    """
```

## Complete Example: inspectable_buffer_loader

### Timeline of Discoveries (Git History)

```
c6136b8 - Integrate Moku_Voltage_pkg and fix ±5V voltage scaling bug (5× error!)
cb966f7 - Add incoming/ folder pattern for CloudCompile workflow iteration
ba4ddb5 - Test 5 debug: Add state verification + Control2 propagation delay
12410bf - Test 2 debug: Poll oscilloscope to catch state transition
d718da2 - CRITICAL: State machine has no software-controllable reset path

Result: 4/5 tests pass, 1 skipped (design limitation documented)
```

### Lessons Learned

1. **Voltage Scaling**: Moku uses ±5V, not ±1V (5× error caught by voltage package integration)
2. **Oscilloscope Latency**: Poll multiple times to catch transitions (100ms intervals)
3. **Sticky Flags**: Use Valid flag as primary indicator (Fault is sticky)
4. **State Machine Paths**: Map transitions before testing (found RUNNING→IDLE impossible)
5. **Guard Bands**: 2-3 bit left-shift essential for oscilloscope readability

### Success Metrics

- ✅ All CocotB oscilloscope-only tests pass (6/6)
- ✅ Hardware tests mirror CocotB exactly (same test structure)
- ✅ Voltage scaling validated (±5V specification)
- ✅ Debug views provide sufficient observability
- ✅ Git history documents debugging journey (5 incremental commits)
- ✅ Known limitations documented (state machine reset path)

## Future Improvements

### For Next Module

1. **Design**: Add software-controllable reset to state machine
2. **Testing**: Create test ordering guidelines (IDLE-requiring tests first)
3. **Documentation**: State machine diagrams in module README
4. **Automation**: Script to check test prerequisites (state validation)

### Specialized Prompt Consideration

**Question**: Should we create a specialized prompt for this workflow?

**Options**:
1. Slash command: `.claude/commands/debug-hardware.md`
2. Documentation: `docs/OSCILLOSCOPE-DEBUGGING-WORKFLOW.md` (this file)
3. Serena memory: `oscilloscope_debugging_techniques.md` (AI context)
4. AGENTS.md section: Quick reference for common workflow

**Recommendation**: All four! Each serves different purpose:
- Slash command → Quick invocation when debugging
- Documentation → Human-readable comprehensive guide
- Serena memory → AI context for autonomous debugging
- AGENTS.md → Workflow summary for quick lookup

## Slash Command Template

```markdown
# /debug-hardware

You are debugging a VHDL module on Moku hardware using oscilloscope-based testing.

Follow this workflow:

1. **Verify CocotB tests pass** (oscilloscope-only, no internal signals)
2. **Run matching MokuBench hardware tests** (mirrors CocotB exactly)
3. **For each failure**:
   - Add diagnostic output (status before/after action)
   - Poll oscilloscope multiple times if testing transitions
   - Check multiple debug views for root cause
   - Commit incremental fix with same message shown to user
4. **Document discoveries**:
   - State machine limitations
   - Voltage scaling issues
   - Timing/propagation delays
   - Sticky flag behavior
5. **Update Serena memories** after session

Key principles:
- Oscilloscope is ground truth (no internal signal access)
- Git commits = learning trail (commit every discovery)
- User messages = commit messages (don't duplicate)
- Poll multiple times for transitions (100ms intervals)
- Use Valid flag, not Fault (sticky flags unreliable)

Reference: docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md
```

## Conclusion

This workflow transforms hardware debugging from "trial and error" to "systematic discovery":

1. **Oscilloscope-only testing** ensures methodology matches user workflow
2. **Incremental git commits** create a learning trail for future reference
3. **CocotB/MokuBench mirroring** provides simulation baseline before hardware
4. **Debug multiplexers** make internal state visible without probes
5. **Voltage guard bands** ensure oscilloscope readability

**Most Important**: Git history documents the debugging journey, making this a **teaching workflow** not just a testing workflow.

---

**Generated**: 2025-10-24
**Module**: inspectable_buffer_loader (build 25ff4c4)
**Hardware**: Moku:Go (192.168.13.159)
**Test Results**: 4/5 PASSED, 1 SKIPPED (documented limitation)

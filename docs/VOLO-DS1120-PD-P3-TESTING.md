# System Prompt P3: VOLO-DS1120-PD Testing and Debugging

**Purpose**: Debug and fix CocotB tests for DS1120-PD probe driver VOLO application.

---

## Phase 2 Completion Status

Phase 2 has been completed with the following implementations:

### Completed Components:
1. **FSM Core Module** (`ds1120_pd_fsm.vhd`)
   - State machine with safety features
   - Timeout protection
   - Spurious trigger counting
   - Fire count tracking

2. **Main Integration** (`DS1120_PD_volo_main.vhd`)
   - Integrated clock divider
   - Threshold trigger module
   - FSM observer for debug
   - Voltage clamping (3.0V max)

3. **Package** (`ds1120_pd_pkg.vhd`)
   - State encodings
   - Voltage constants
   - Safety limits
   - Helper functions

4. **CocotB Tests** (`test_ds1120_pd_volo.py`)
   - 7 comprehensive tests defined
   - Using new pytest/CocotB infrastructure

### Current Test Status:
- Tests are defined but may need debugging
- Test runner is configured in `test_configs.py`
- Uses MCC CustomWrapper test stub

---

## Your Tasks for Phase 3:

### 1. Fix Test Execution Issues
- Resolve any GHDL compilation errors
- Fix waveform generation issues
- Ensure all source files are correctly referenced

### 2. Debug Test Failures
- Analyze test output for failures
- Fix hierarchy access issues for FSM state checking
- Adjust timing if needed
- Verify register mappings

### 3. Validate Safety Features
- Confirm 3.0V clamping works
- Verify timeout behavior
- Test spurious trigger counting
- Check FSM state transitions

### 4. Document Test Results
- Create test report with pass/fail status
- Document any limitations or known issues
- Note areas for future improvement

---

## Key Files to Review:

### Implementation Files:
- `modules/DS1120-PD/common/ds1120_pd_pkg.vhd`
- `modules/DS1120-PD/core/ds1120_pd_fsm.vhd`
- `modules/DS1120-PD/volo_main/DS1120_PD_volo_main.vhd`
- `modules/DS1120-PD/volo_main/DS1120-PD_volo_shim.vhd`

### Test Infrastructure:
- `tests/test_configs.py` - Test configuration (line 113-137 for DS1120-PD)
- `tests/test_ds1120_pd_volo.py` - CocotB test suite
- `tests/run.py` - Test runner
- `tests/conftest.py` - Test utilities

### Shared Modules:
- `modules/shared/core/volo_clk_divider.vhd`
- `modules/shared/core/volo_voltage_threshold_trigger_core.vhd`
- `modules/shared/observer/fsm_observer.vhd`
- `modules/shared/packages/volo_voltage_pkg.vhd`

---

## Test Running Commands:

```bash
# Run tests without waveforms (faster)
uv run python tests/run.py ds1120_pd_volo --no-waves

# Run with waveforms for debugging
uv run python tests/run.py ds1120_pd_volo

# Run verbose for more detail
uv run python tests/run.py ds1120_pd_volo --verbose

# List all available tests
uv run python tests/run.py --list
```

---

## Known Issues to Address:

1. **Hierarchy Access**: The test function `get_fsm_state()` may need adjustment based on actual MCC wrapper hierarchy
2. **GHDL Options**: Wave generation option format may need fixing
3. **Timing**: Some tests may need timing adjustments for proper FSM state transitions
4. **Register Mapping**: Verify CR20-CR30 are correctly mapped through shim

---

## Success Criteria:

Phase 3 is complete when:
1. All 7 tests compile without errors
2. At least 5 tests pass completely
3. Safety features are verified (especially voltage clamping)
4. Test report documents results and any limitations
5. Code is ready for MCC CloudCompile synthesis

---

## Test Coverage Checklist:

- [ ] Test 1: Reset behavior - FSM returns to READY
- [ ] Test 2: Arm and trigger - FSM responds to trigger input
- [ ] Test 3: Intensity clamping - 3.0V limit enforced
- [ ] Test 4: Timeout behavior - Armed state times out
- [ ] Test 5: Full cycle - Complete state machine flow
- [ ] Test 6: Clock divider - Timing affected by clock division
- [ ] Test 7: VOLO_READY scheme - 3-bit control enables module

---

## Notes from Phase 2:

- FSM uses active-low reset internally (`rst_n`) but main module uses active-high
- Clock divider output is `clk_en` signal, not a divided clock
- Threshold trigger includes hysteresis (threshold_low = threshold_high - 0x0100)
- FSM observer outputs debug voltage on OutputB
- Status register assembly in main module includes fire count and spurious count

---

**Next Steps**: Start by running the test suite and analyzing any compilation or runtime errors. Focus on getting basic tests (reset, arm/trigger) working first before moving to more complex tests.
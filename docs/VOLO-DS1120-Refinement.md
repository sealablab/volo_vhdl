
# VOLO-DS1120-Refinement-Qs

I've analyzed the VOLO-DS1120-PD requirements document. This is an interesting application - a VOLO
  wrapper for controlling a Riscure DS1120A EMFI (Electromagnetic Fault Injection) probe. Let me
  provide feedback on potential issues and areas needing refinement:

  🔴 Critical Issues to Address

  1. Register Type Mismatch

  The document specifies 16-bit signed threshold registers (trig_in_thresh, monitor_in_thresh), but
  VOLO's type system only supports:
  - COUNTER_8BIT (0-255)
  - PERCENT (0-100)
  - BUTTON (0 or 1)

  Question: How should we map the 16-bit threshold values? Options:
  - Use two 8-bit registers (high/low bytes)?
  - Use the full 32-bit CR register directly (bypass VOLO type system)?
  - Scale thresholds to fit 8-bit range?

  2. Incomplete Sections

  - Line 21: Section title "The" is incomplete
  - Line 72: "I suspect we can actually use the" trails off

  Question: What were you planning to describe in these sections?

  3. Module Dependencies

  The document references modules not in the standard VOLO infrastructure:
  - volo_voltage_pkg.vhd
  - volo_voltage_threshold_trigger_core.vhd
  - fsm_observer.vhd
  - fsm_example_core.vhd

  Question: Are these existing modules in shared/volo/ or modules/*/common/? Should they be created as
   part of this app?

  🟡 Design Clarifications Needed

  4. I/O Signal Mapping

  The document mentions:
  - Inputs: TriggerInput, MonitorInput (16-bit unsigned)
  - Outputs: TriggerOut, IntensityOut, analog_v_mon_out (16-bit)

  Question: How do these map to MCC's CustomWrapper signals?
  - InputA/InputB are 16-bit signed in MCC
  - OutputA/OutputB are 16-bit signed in MCC
  - Should we use: InputA→TriggerInput, InputB→MonitorInput, OutputA→TriggerOut, OutputB→IntensityOut?

  5. Voltage Representation

  The document mentions specific voltages (0V, 2.4V, 3.3V).

  Question: What's the ADC/DAC scaling?
  - Full 16-bit range (-32768 to +32767) maps to what voltage range?
  - Is 0V = 0x0000? What's 3.3V in hex?

  6. FSM Observer Integration

  You mention using fsm_observer.vhd to drive outputs.

  Question: Is the intent to:
  - Have one main FSM + three observer instances?
  - Or have the FSM directly control outputs + observers for debugging?

  🟢 Suggested Refinements

  7. Register Allocation

  Given VOLO's CR20-CR30 limit (11 registers max) and 32-bit width, consider:

  registers:
    # Control (CR20-22)
    - name: Armed
      reg_type: button
      cr_number: 20
      description: Arm the probe driver

    - name: Force Fire
      reg_type: button
      cr_number: 21
      description: Manually trigger firing sequence

    - name: Reset FSM
      reg_type: button
      cr_number: 22
      description: Reset to READY state

    # Timing (CR23-25)
    - name: Arm Timeout
      reg_type: counter_8bit
      cr_number: 23
      description: Clock cycles before timeout in ARMED state

    - name: Firing Duration
      reg_type: counter_8bit
      cr_number: 24
      description: Clock cycles in FIRING state (max 32)

    - name: Cooling Duration
      reg_type: counter_8bit
      cr_number: 25
      description: Clock cycles in COOLING state (min 8)

    # Thresholds - Need special handling for 16-bit
    # CR26-27 for trigger threshold (split into two parts?)
    # CR28-29 for monitor threshold (split into two parts?)
    # CR30 reserved for status readback?

  8. Safety Enhancements

  Add to requirements:
  - Watchdog timer for overall operation
  - Maximum fire count per session
  - Minimum time between successive armings
  - Status bits for fault conditions

  9. BRAM Buffer Future Use

  Document potential future uses:
  - Waveform patterns for pulse shaping?
  - Timing sequence tables?
  - Calibration data?

--
-----
✅ Complete! VOLO-DS1120-PD Documentation Refined and System Prompts Created

  I've successfully:

  1. Refined the Requirements Document (v2.0)

  - ✅ Addressed all your feedback points
  - ✅ Resolved register type mismatches (split 16-bit values into 8-bit pairs)
  - ✅ Located and documented all module dependencies
  - ✅ Added voltage scaling details (±5V = ±32768, with key values)
  - ✅ Clarified FSM observer strategy (3 instances for elegant control)
  - ✅ Added comprehensive safety features and timing constraints

  2. Created Two System Prompts

  P1: VOLO-App Definition (docs/VOLO-DS1120-PD-P1-SystemPrompt.md)

  - YAML app definition creation
  - Infrastructure generation with generate_volo_app.py
  - Starter VHDL template with proper module dependencies
  - Build system integration guidance

  P2: VHDL Implementation (docs/VOLO-DS1120-PD-P2-SystemPrompt.md)

  - Complete FSM core implementation
  - Safety feature integration (voltage clamping, timing enforcement)
  - Module interconnection (threshold trigger, clock divider, observers)
  - Comprehensive CocotB test suite (7 tests)

  3. Key Design Decisions

  - Register Mapping: CR27-28 for trigger threshold, CR29-30 for intensity (16-bit split)
  - CR23 Dual Purpose: [7:4] clock divider, [3:0] delay counter upper nibble
  - Safety First: Hard-coded 3.0V limit, mandatory cooling, timeout protection
  - Observable FSM: Using fsm_observer for both control and debugging
  - Clock Division: 4-bit divider for flexible FSM timing control

  4. Files Created/Updated

  ✅ docs/VOLO-DS1120-PD.md (v2.0 - complete refinement)
  ✅ docs/VOLO-DS1120-PD-P1-SystemPrompt.md (Phase 1 prompt)
  ✅ docs/VOLO-DS1120-PD-P2-SystemPrompt.md (Phase 2 prompt)
  ✅ Committed to git with comprehensive message

  Next Steps

  You can now use these prompts in fresh Claude context windows:

  5. Phase 1: Use P1 prompt to generate the YAML definition and initial VHDL structure
  6. Phase 2: Use P2 prompt to complete the implementation with full FSM logic and tests

  The prompts are designed to be self-contained with all necessary context, references, and
  implementation details. Each phase has clear success criteria and validation checklists.

  The VOLO-DS1120-PD is now ready for implementation as a safe, reliable EMFI probe driver! 🚀
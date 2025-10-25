
  # DS1120A EMFI Probe Characterization Plan

  ## Context

  I have a **Riscure DS1120A Unidirectional EMFI Probe** and need to create a safe,
  systematic characterization procedure using a **Moku:Go** device.

  ## Available Resources

  ### Hardware
  - DS1120A probe with SMA connectors (trigger, amplitude, current monitor)
  - Moku:Go with available ports (OutputA/B, InputA/B, DACOut1/2)
  - 24V DC power supply (center-positive barrel jack)
  - 3× SMA coaxial cables (50Ω)
  - Multiple probe tips (1.5mm, 4mm, positive/negative polarity)

  ### Documentation
  The probe catalog is documented in Serena memory:
  - Read `.serena/memories/riscure_ds1120a.md` for complete electrical specs
  - Datasheet: `tests/docs/datasheets/DS1120A_DS1121A_datasheet.pdf`
  - Reference photos: `tests/docs/images/ds1120a_top.jpg`

  ### Key Probe Specifications (from catalog)
  - **Inputs**:
    - `digital_glitch` (SMA): 0-3.3V TTL trigger (rising edge)
    - `pulse_amplitude` (SMA): 0-3.3V analog (5-100% power control)
    - `power_24vdc` (barrel): 24-450V DC external PSU
  - **Output**:
    - `coil_current` (SMA): -1.4V to 0V (transient pulse monitor)
  - **Timing**:
    - Fixed 50ns pulse width (hardware-determined)
    - ~50ns propagation delay

  ## Objectives

  1. **Safely connect** and verify the probe with Moku:Go
  2. **Characterize voltage-to-power mapping** (currently unknown, assumed linear)
  3. **Capture current monitor waveforms** at various power levels
  4. **Document timing characteristics** (propagation delay, pulse shape)
  5. **Validate catalog specifications** against real measurements

  ## Constraints & Preferences

  - **Safety first**: Start at minimum power (5%), no target device initially
  - **Prefer Moku Data Logger instrument** over Oscilloscope (more interesting!)
  - **Systematic approach**: Phase-by-phase testing with validation at each step
  - **Python-based**: Use Moku Python API (moku package) for automation
  - **Data collection**: Log results for future reference and calibration

  ## Requested Deliverables

  Please provide:

  1. **Test Procedure Document** with:
     - Step-by-step connection sequence (what to connect when)
     - Safety checklists for each phase
     - Moku configuration settings (coupling, impedance, ranges)
     - Expected vs. actual behavior validation

  2. **Python Test Script(s)** using Moku API:
     - Phase 1: Connection verification (passive monitoring)
     - Phase 2: Minimum power trigger test
     - Phase 3: Power sweep characterization (5% → 100%)
     - Phase 4: Waveform capture and analysis

  3. **Data Logger Configuration**:
     - How to use Data Logger instrument for this application
     - Sampling rate, duration, trigger settings
     - What metrics to log (peak current, timing, etc.)

  4. **Safety Considerations**:
     - What could go wrong at each phase?
     - Emergency shutdown procedures
     - Equipment protection strategies

  5. **Expected Results**:
     - What waveforms should I see?
     - How to validate correct operation?
     - Red flags that indicate problems

  ## Questions to Address

  - Should I use Data Logger's continuous logging or triggered capture mode?
  - What sampling rate is needed to resolve the 50ns pulse accurately?
  - How to correlate trigger timing with current monitor feedback?
  - Should I characterize each probe tip separately (1.5mm vs 4mm)?
  - How to safely test without a target (just fire into air)?

  ## Additional Context

  This probe will eventually be used for fault injection attacks on secure hardware.
  For now, I just want to understand its behavior and verify safe operation before
  connecting to any target devices.

  Please create a comprehensive, beginner-friendly test plan that assumes I'm
  careful but not an expert in EMFI testing. Include plenty of "what could go wrong"
  warnings and validation checkpoints.

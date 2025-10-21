# TPD Module - MCC Deployment Guide

## Critical: CustomWrapper Architecture Pattern

⚠️ **MCC does NOT allow VHDL files to define `entity CustomWrapper`** ⚠️

MCC's build script (lines 76-79) explicitly checks for and **rejects** any VHDL file containing:
```vhdl
entity CustomWrapper is
```

This is by design - MCC provides the CustomWrapper **entity declaration** automatically.

### Solution: Architecture-Only Pattern

MCC expects users to upload:
1. Core module files with their own entities (e.g., `TPD_Top.vhd`)
2. A `Top.vhd` file defining an **architecture** for CustomWrapper (NOT an entity!)

**Top.vhd pattern:**
```vhdl
architecture rtl of CustomWrapper is
begin
    U_TPD: entity WORK.TPD_Top
        port map (...);
end architecture rtl;
```

This is similar to the DCSequencer example in MCC documentation.

---

## Original Issue Analysis

Your synthesis log showed MCC using the **old template CustomWrapper** with `ProbeDriver.vhd` instead of the new **TPD module stack**.

### Synthesis Log Issues

1. **Line 160-168**: Wrong modules being synthesized
   - Using: `/lib/CustomWrapper.vhd` (MCC template)
   - Instantiating: `probe_driver` (old module)
   - **Should instantiate**: `TPD_Top` (our TPD module)

2. **Line 166**: Sensitivity list warning in ProbeDriver.vhd
   ```
   WARNING: [Synth 8-614] signal 'clk_en' is read in the process
   but is not in the sensitivity list
   ```
   - Indicates a combinational process missing a signal
   - This is in the OLD ProbeDriver, not the new TPD module

3. **Line 192**: Unused counter removed
   ```
   WARNING: [Synth 8-6014] Unused sequential element cnt_reg was removed
   ```
   - Optimization warning in old ProbeDriver

---

## Deployment Steps

### 1. Upload TPD Files to MCC

The TPD module requires these files (already prepared in `mcc_deploy/`):

```
mcc_deploy/
├── Top.vhd          (CustomWrapper architecture - instantiates TPD_Top)
├── TPD_Top.vhd      (Top-level Moku integration)
├── emfi_fsm.vhd     (Core FSM)
└── tpd_med.vhd      (Wrapper with sticky status)
```

**IMPORTANT**:
- Do NOT upload a file defining `entity CustomWrapper`! MCC will reject it.
- The `Top.vhd` file only defines the architecture body for CustomWrapper.

### 2. MCC Upload Process

**Via Moku Cloud Compile (MCC) Web Interface:**

1. Navigate to your Moku device's custom instrument page

2. Click "Upload Source Files" or "Deploy Custom Instrument"

3. Upload all 4 files from `mcc_deploy/`:
   - `Top.vhd` (CustomWrapper architecture)
   - `TPD_Top.vhd` (Core integration)
   - `emfi_fsm.vhd` (FSM logic)
   - `tpd_med.vhd` (Wrapper with status)

4. Configure I/O mapping (if not auto-detected):
   - Output A: Trigger output
   - Output B: Intensity output
   - Output C: Status register
   - Input A: External trigger (bit 0)

5. Click "Compile" or "Deploy"

**Via Command Line (if using MCC API):**

```bash
# From modules/TPD directory
cd mcc_deploy

# Upload files (adjust command to your MCC tool)
moku-deploy upload Top.vhd TPD_Top.vhd emfi_fsm.vhd tpd_med.vhd \
  --device YOUR_MOKU_ID \
  --instrument-name "TPD-EMFI-Driver"
```

### 3. Verify Correct Files Are Used

After upload, check the synthesis log for:

✅ **Correct indicators:**
```
INFO: synthesizing module 'CustomWrapper' [.../src/Top.vhd]
INFO: synthesizing module 'TPD_Top' [.../src/TPD_Top.vhd]
INFO: synthesizing module 'tpd_med' [.../src/tpd_med.vhd]
INFO: synthesizing module 'emfi_fsm' [.../src/emfi_fsm.vhd]
```

Note: All 4 modules should be synthesized in this order.

❌ **Wrong indicators (compilation errors):**
```
ERROR: [DRC INBB-3] Black Box Instances: Cell ... of type 'CustomWrapper'
has undefined contents and is considered a black box
```
This indicates `Top.vhd` was not uploaded or not recognized.

❌ **Wrong indicators (old module still active):**
```
INFO: synthesizing module 'probe_driver'
INFO: synthesizing module 'clk_divider'
```
This indicates old files need to be cleared from MCC workspace.

---

## Expected Synthesis Results

### Resource Usage (from TPD module)

Based on the module design, expect:
- **LUTs**: ~200-300 (small FSM + control logic)
- **Flip-Flops**: ~100-150 (registers + state)
- **No DSPs**: Pure logic design
- **No BRAM**: No memory blocks needed

### Expected Warnings (Normal)

These warnings are **expected and safe** for the TPD module:

1. **Unused ports** - Moku interface has many optional signals:
   ```
   WARNING: Port InputB[15:0] is either unconnected or has no load
   WARNING: Port InputC[15:0] is either unconnected or has no load
   WARNING: Port OutputD[15:0] has no driver
   ```
   This is normal - TPD only uses InputA, OutputA/B/C.

2. **Unused Sync signals**:
   ```
   WARNING: Port Sync[31:0] is either unconnected or has no load
   ```
   Normal - TPD doesn't use synchronization signals.

### Warnings That Should NOT Appear

❌ **These indicate wrong files uploaded:**
```
WARNING: signal 'clk_en' is read in the process but is not in sensitivity list
WARNING: Unused sequential element cnt_reg was removed
```

These are from the old ProbeDriver - they should NOT appear with TPD module.

---

## Testing After Deployment

### 1. Configure Registers

```python
from moku.instruments import CustomInstrument

# Connect to Moku
moku = CustomInstrument('192.168.xxx.xxx', force_connect=True)

# Configure Control0: firing=5, cooldown=3
moku.set_control_register(0,
    (0 << 31) |     # gDisable = 0 (enabled)
    (0 << 23) |     # SOFT-TRIGGER = 0
    (3 << 12) |     # Probe_cooldown = 3 cycles
    (5 << 8)        # Probe_fire = 5 cycles
)

# Configure Control1: delay=10, output_level=0x2000
moku.set_control_register(1,
    (0x2000 << 16) | # trig_out_level = 0x2000
    (10)             # delay_cnt = 10 cycles
)
```

### 2. Software Trigger

```python
# Trigger a pulse sequence
current = moku.get_control_register(0)
moku.set_control_register(0, current | (1 << 23))  # Set SOFT-TRIGGER

# Wait for completion (check status register)
import time
time.sleep(0.001)  # 1ms

status = moku.get_output(2) & 0xFF  # OutputC = status register
if status & (1 << 4):  # Check DONE bit
    print("Pulse sequence completed!")
    print(f"Status: 0x{status:02X}")
```

### 3. Monitor Outputs

```python
# Read outputs
trigger_out = moku.get_output(0)    # OutputA
intensity_out = moku.get_output(1)  # OutputB
status_reg = moku.get_output(2)     # OutputC

print(f"Trigger:   0x{trigger_out:04X}")
print(f"Intensity: 0x{intensity_out:04X}")
print(f"Status:    0x{status_reg:02X}")

# Decode status bits
status_bits = {
    'READY':   (status_reg >> 0) & 1,
    'DELAY':   (status_reg >> 1) & 1,
    'FIRING':  (status_reg >> 2) & 1,
    'COOLING': (status_reg >> 3) & 1,
    'DONE':    (status_reg >> 4) & 1,
}
print(f"Status flags: {status_bits}")
```

---

## Troubleshooting

### Issue: Black box error for CustomWrapper

**Error**:
```
ERROR: [DRC INBB-3] Black Box Instances: Cell ... of type 'CustomWrapper'
has undefined contents and is considered a black box
```

**Solution**: `Top.vhd` was not uploaded or recognized
1. Verify `Top.vhd` is in the uploaded files list
2. Check that `Top.vhd` contains `architecture rtl of CustomWrapper is`
3. Re-upload all 4 files together

### Issue: Still seeing old ProbeDriver module

**Solution**: Clear MCC workspace and re-upload
1. Delete all source files from MCC web interface
2. Upload all 4 TPD files fresh
3. Force re-compile

### Issue: Synthesis fails with "entity TPD_Top not found"

**Solution**: Files not uploaded together or compilation order issue
1. Ensure all 4 files are uploaded in the same session
2. MCC should auto-detect dependencies
3. Check synthesis log for which files are being read

### Issue: Outputs always zero

**Check**:
1. `Control0[31]` = 0 (gDisable should be 0)
2. Trigger has been asserted
3. Status register shows progression (READY→DELAY→FIRING→DONE)

---

## File Checksums

Verify you have the correct files:

```bash
cd mcc_deploy
md5sum *.vhd
```

Expected files:
- `Top.vhd` (~1800 bytes) - CustomWrapper architecture
- `TPD_Top.vhd` (~7475 bytes) - Top-level integration
- `emfi_fsm.vhd` (~5650 bytes) - Core FSM
- `tpd_med.vhd` (~6151 bytes) - Wrapper module

---

## Next Steps After Successful Deployment

1. **Test basic functionality**
   - Software trigger
   - Status register monitoring
   - Output levels during FIRING

2. **Test external trigger**
   - Connect signal to InputA[0]
   - Verify OR logic with software trigger

3. **Characterize timing**
   - Measure actual pulse widths
   - Verify delay/firing/cooldown cycle counts

4. **Integration with EMFI hardware**
   - Connect OutputA to pulse driver
   - Adjust output levels as needed

---

## See Also

- **TPD_REGISTER_MAP.md** - Complete register documentation
- **emfi_fsm.md** - FSM state machine details
- **TPD_MED.md** - Wrapper module specifications
- **CocoTB tests** - Reference test cases for expected behavior

# TPD Module - MCC Deployment Guide

## Critical: CustomWrapper Naming Restriction

⚠️ **MCC does NOT allow VHDL files to define `entity CustomWrapper`** ⚠️

MCC's build script (lines 76-79) explicitly checks for and **rejects** any VHDL file containing:
```vhdl
entity CustomWrapper is
```

This is by design - MCC reserves the `CustomWrapper` entity name for its template system.

### Solution

Our TPD top-level module is named **`TPD_Top`** (not CustomWrapper):
- File: `TPD_Top.vhd`
- Entity: `entity TPD_Top is`

You must either:
1. Edit MCC's CustomWrapper template to instantiate `TPD_Top`, OR
2. Use the provided `CustomWrapper_Body_Template.vhd` as a reference

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
├── TPD_Top.vhd                        (Top-level Moku integration)
├── emfi_fsm.vhd                       (Core FSM)
├── tpd_med.vhd                        (Wrapper with sticky status)
└── CustomWrapper_Body_Template.vhd    (Reference template for MCC)
```

**IMPORTANT**: Do NOT upload a file named `CustomWrapper.vhd`! MCC will reject it.

### 2. MCC Upload Process

**Via Moku Cloud Compile (MCC) Web Interface:**

1. Navigate to your Moku device's custom instrument page

2. Click "Upload Source Files" or "Deploy Custom Instrument"

3. Upload these 3 files from `mcc_deploy/`:
   - `TPD_Top.vhd`
   - `emfi_fsm.vhd`
   - `tpd_med.vhd`

4. **Edit the CustomWrapper template** in MCC:
   - Find the CustomWrapper architecture editor in MCC
   - Replace the body with instantiation of `TPD_Top`
   - Use `CustomWrapper_Body_Template.vhd` as reference
   - The template should instantiate: `entity WORK.TPD_Top`

5. Configure outputs:
   - Output A: Trigger output
   - Output B: Intensity output
   - Output C: Status register

6. Click "Compile" or "Deploy"

**Via Command Line (if using MCC API):**

```bash
# From modules/TPD directory
cd mcc_deploy

# Upload files (adjust command to your MCC tool)
moku-deploy upload TPD_Top.vhd emfi_fsm.vhd tpd_med.vhd \
  --device YOUR_MOKU_ID \
  --instrument-name "TPD-EMFI-Driver"

# Then manually edit CustomWrapper template through web interface
```

### 3. Verify Correct Files Are Used

After upload, check the synthesis log for:

✅ **Correct indicators:**
```
INFO: synthesizing module 'CustomWrapper' [.../lib/CustomWrapper.vhd]
INFO: synthesizing module 'TPD_Top' [.../src/TPD_Top.vhd]
INFO: synthesizing module 'tpd_med'
INFO: synthesizing module 'emfi_fsm'
```

❌ **Wrong indicators (old module or missing TPD_Top):**
```
INFO: synthesizing module 'probe_driver'
INFO: synthesizing module 'clk_divider'
# OR
INFO: synthesizing module 'CustomWrapper'
# (but no TPD_Top being instantiated)
```

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

### Issue: Still seeing ProbeDriver warnings

**Solution**: Clear MCC cache and re-upload
1. Delete all source files from MCC web interface
2. Upload only the 3 TPD files
3. Force re-compile

### Issue: "Entity CustomWrapper already defined"

**Solution**: MCC is finding both old and new CustomWrapper
1. Remove any existing CustomWrapper.vhd from uploads
2. Upload fresh copy from `mcc_deploy/CustomWrapper.vhd`

### Issue: Synthesis fails with "entity tpd_med not found"

**Solution**: Files uploaded in wrong order
1. Ensure all 3 files are uploaded together
2. MCC should auto-detect dependencies

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
- `TPD_Top.vhd` (~7475 bytes) - Top-level integration
- `emfi_fsm.vhd` (5650 bytes) - Core FSM
- `tpd_med.vhd` (6151 bytes) - Wrapper module
- `CustomWrapper_Body_Template.vhd` (~4382 bytes) - Template reference

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

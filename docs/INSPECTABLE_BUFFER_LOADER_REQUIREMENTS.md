# Inspectable Buffer Loader - Requirements Document

**Module Name:** `inspectable_buffer_loader`
**Purpose:** MCC buffer loading with maximum hardware debuggability
**Date:** 2025-10-24
**Author:** Claude Code (with user feedback)

---

## 1. Overview

This module implements the MCC streaming buffer loader protocol with a focus on **real-time hardware inspectability**. Lessons learned from `buffer_waveform_gen`:

- ✅ Simulation passing != hardware working
- ✅ Need to "see inside" the module while running on real hardware
- ✅ Oscilloscope channels are our debug window (not synthesized away!)
- ✅ Digital signals through analog paths need voltage spacing

**Core Principle:** If we can't observe it on hardware, we can't debug it.

---

## 2. Functional Requirements

### 2.1 Core Functionality
- Load arbitrary buffers (up to 1024 words × 32-bit) via MCC Control Registers
- Stream data in 8-word chunks with STROBE protocol
- CRC32 validation (IEEE 802.3)
- Playback loaded waveform to OutputA
- **NEW:** Dynamic debug output selection on OutputA and OutputB

### 2.2 Protocol Compatibility
- Maintain backward compatibility with existing `mcc_load_buffer()` Python helper
- **NEW:** Add optional readback command to verify buffer contents
- **NEW:** Add optional single-step mode (load one chunk, stop, inspect)

---

## 3. Debug Architecture

### 3.1 Analog-Aware Debug Outputs

**Challenge:** Digital debug signals routed through ADC/DAC analog paths suffer from:
- Quantization noise (±1-2 LSBs)
- Analog filtering/coupling effects
- Limited voltage resolution (~0.8 mV/bit on 16-bit DAC with 3.3V range)

**Solution:** "Voltage Guard Bands"
- Shift debug values left by 2-3 bits before output
- Creates distinct voltage steps between values
- LSB noise becomes irrelevant
- Example: State machine values spaced 4× apart

```vhdl
-- BAD: Direct output (states differ by ~0.8mV)
debug_out <= "0000000000000" & state;  -- state=3 → 0x0003

-- GOOD: Left-shifted (states differ by ~3.2mV, 4× more margin)
debug_out <= "0000000000" & state & "00";  -- state=3 → 0x000C
```

### 3.2 Debug Output Channels

**OutputA:** Configurable (waveform playback OR debug view)
- Default: Waveform playback (normal operation)
- Debug modes: Selectable via Control0[26:24]

**OutputB:** Dedicated debug channel
- Always shows debug information
- Selectable via Control0[23:21]

**Why two channels?**
- Can compare signals side-by-side on 2-channel scope
- Example: OutputA=expected CRC, OutputB=computed CRC
- Can monitor waveform quality while debugging (OutputA=waveform, OutputB=debug)

### 3.3 Debug Views (Selectable)

Each debug view outputs a 16-bit signed value with voltage guard bands.

#### View 0: Status Summary (DEFAULT for OutputB)
```
Bit[15:13] = state << 2           (3 bits shifted → 12 bits voltage range)
Bit[12]    = fault << 12          (isolated bit, max voltage if set)
Bit[11]    = valid << 11          (isolated bit)
Bit[10:0]  = buffer_addr << 2     (11 bits shifted → safe readout)
```

#### View 1: CRC Comparison
```
OutputA = expected_crc[15:0] << 2    (low 16 bits of expected CRC)
OutputB = computed_crc[15:0] << 2    (low 16 bits of computed CRC)
```
**Use case:** Visually compare on oscilloscope - should match at VALIDATING state

#### View 2: Write Activity
```
Bit[15:11] = chunk_word_idx << 3     (0-7 → clearly separated)
Bit[10:0]  = write_ptr << 2          (current write address)
```
**Use case:** Verify chunks are being written sequentially

#### View 3: Chunk Data Snapshot
```
OutputA = chunk_data[0][15:0] << 2   (first word of current chunk)
OutputB = chunk_data[7][15:0] << 2   (last word of current chunk)
```
**Use case:** Verify data integrity - see actual values being written

#### View 4: BRAM Readback
```
OutputA = Control0[10:0] selects address
OutputB = bram[address][15:0] << 2   (read from BRAM at selected address)
```
**Use case:** Verify buffer was written correctly (ground truth check)

#### View 5: Timing Diagnostics
```
Bit[15]    = strobe_edge << 15       (isolated pulse visualization)
Bit[14]    = strobe_ack << 14        (acknowledgment flag)
Bit[13]    = load_complete << 13     (completion signal)
Bit[12:0]  = words_written << 2      (running count)
```
**Use case:** Debug STROBE protocol timing issues

#### View 6: Error Diagnostics
```
Bit[15:13] = last_error_code << 2    (0=none, 1=CRC fail, 2=overflow, ...)
Bit[12:8]  = error_state << 3        (state where error occurred)
Bit[7:0]   = error_details           (context-specific debug info)
```
**Use case:** Persistent error capture (sticky until reset)

#### View 7: Reserved (Future Use)

### 3.4 Debug Control Register Map

**Control0 - Primary Control + Debug Selection**
```
Bit[31]    = MCC_READY (auto-set by MCC)
Bit[30]    = User Enable
Bit[29]    = Clock Enable
Bit[28]    = LOAD_COMPLETE
Bit[27]    = LOAD_STROBE
Bit[26:24] = DEBUG_SELECT_A (OutputA debug view, 0-7)
Bit[23:21] = DEBUG_SELECT_B (OutputB debug view, 0-7)
Bit[20:16] = Reserved
Bit[15:0]  = Context (used by some debug views, e.g., BRAM readback address)
```

**Control1 - Metadata (buffer length)**
```
Bit[31:16] = buffer_length (words to load)
Bit[15:0]  = Reserved
```

**Control2 - Metadata (CRC32)**
```
Bit[31:0]  = expected_crc (IEEE 802.3 CRC32)
```

**Control3-10 - Data Chunk (8 × 32-bit words)**
```
8 words per chunk (standard MCC streaming)
```

---

## 4. Enhanced Protocol Features

### 4.1 Single-Step Mode (NEW)
When `DEBUG_SELECT_A = 7` or `DEBUG_SELECT_B = 7`:
- FSM pauses after writing each chunk
- Allows inspection before proceeding
- Python sends another STROBE pulse to continue

### 4.2 BRAM Readback Mode (NEW)
When `DEBUG_SELECT_B = 4`:
- Control0[10:0] = read address
- OutputB shows BRAM contents at that address
- Allows verification without modifying state machine

### 4.3 Explicit Error Codes
Instead of just "fault=1", capture specific error:
```
ERROR_NONE        = 0
ERROR_CRC         = 1
ERROR_OVERFLOW    = 2  (buffer_length > BUFFER_SIZE)
ERROR_UNDERFLOW   = 3  (incomplete chunk)
ERROR_TIMEOUT     = 4  (reserved for future)
```

---

## 5. MCC Deployment Workflow (Standard)

All MCC modules should follow this workflow (established in `buffer_waveform_gen`):

### 5.1 Build Phase
```bash
cd modules/inspectable_buffer_loader
python ../../scripts/build_mcc_package.py .
```
**Generates:**
- `cloudcompile_package/*.vhd` (collected source files)
- `cloudcompile_package/BUILD_MANIFEST.txt` (git hash, SHA256 checksums, timestamp)
- `cloudcompile_package/README.txt` (usage guide)
- `cloudcompile_package/inspectable_buffer_loader.zip` (ready to upload)

### 5.2 Manual Upload Phase (Human-Assisted)
1. Go to https://cloud-compile.liquidinstruments.com/
2. Upload individual `.vhd` files from `cloudcompile_package/` (NOT the .zip)
3. Wait for synthesis (~5-10 minutes)
4. Download `25ff***_mokugo_*_synthesis.log` and `25ff***_mokugo_*_bitstreams.tar`
5. Save both to `~/Downloads/` (script will auto-detect newest)

### 5.3 Import Phase (Automated)
```bash
python scripts/import_mcc_build.py modules/inspectable_buffer_loader
```
**Actions:**
- Scans `~/Downloads/` for newest MCC files (by modification time)
- Moves them to `modules/inspectable_buffer_loader/latest/`
- Creates `BUILD_INFO.txt` linking BUILD_MANIFEST → bitstream
- Shows summary with MCC job ID and next steps

### 5.4 Verification
```bash
cat modules/inspectable_buffer_loader/latest/BUILD_INFO.txt
```
**Confirms:**
- Git commit hash matches current source
- File checksums match BUILD_MANIFEST
- Traceability: source → bitstream

### 5.5 Hardware Testing
```bash
cd tests
python test_inspectable_buffer_hardware.py \
    --ip 192.168.13.159 \
    --bitstream ../modules/inspectable_buffer_loader/latest/25ff***_bitstreams.tar
```
**Note:** Bitstream path is CLI argument (no hardcoded paths!)

---

## 6. Design Principles

### 6.1 Voltage Guard Bands
- All debug values shifted left 2-3 bits
- Creates ~3-4× voltage margin between adjacent values
- Robust to ADC quantization noise

### 6.2 Dual-Channel Debug
- Two independent oscilloscope channels
- Can compare signals (expected vs actual)
- Can monitor function + debug simultaneously

### 6.3 Non-Intrusive Inspection
- BRAM readback doesn't modify state machine
- Debug selection doesn't affect core logic
- Can switch debug views without resetting

### 6.4 Explicit Error Capture
- Error code + state where it occurred
- Sticky until reset (survives transient issues)
- Removes ambiguity ("why did it fail?")

### 6.5 Build Traceability
- BUILD_MANIFEST.txt links source → bitstream
- Git hash + SHA256 checksums
- Eliminates "wrong version" debugging

---

## 7. Success Criteria

### 7.1 Simulation
- [ ] All CocotB tests pass (same coverage as `buffer_waveform_gen`)
- [ ] Debug views accessible in simulation
- [ ] BRAM readback mode works

### 7.2 Hardware
- [ ] Buffer loads successfully on real Moku
- [ ] Can switch debug views via Control0 bits
- [ ] Oscilloscope shows distinct voltage levels for each debug value
- [ ] BRAM readback matches expected data
- [ ] Waveform playback works when debug disabled

### 7.3 Workflow
- [ ] BUILD_MANIFEST generation works
- [ ] Import script correctly identifies latest files
- [ ] BUILD_INFO.txt provides full traceability
- [ ] Hardware test uses CLI argument for bitstream (no hardcoded paths)

---

## 8. File Structure

```
modules/inspectable_buffer_loader/
├── common/
│   └── (shared packages if needed)
├── core/
│   ├── inspectable_buffer_loader_core.vhd   (main logic)
│   └── debug_mux.vhd                         (debug output selection)
├── top/
│   └── Top.vhd                               (CustomWrapper architecture)
├── mcc_package.yaml                          (build manifest)
├── cloudcompile_package/                     (generated by build script)
│   ├── *.vhd
│   ├── BUILD_MANIFEST.txt
│   ├── README.txt
│   └── inspectable_buffer_loader.zip
└── latest/                                   (imported MCC results)
    ├── 25ff***_synthesis.log
    ├── 25ff***_bitstreams.tar
    └── BUILD_INFO.txt

tests/
├── test_inspectable_buffer_loader.py         (CocotB simulation tests)
└── test_inspectable_buffer_loader_hardware.py (real Moku hardware test)
```

---

## 9. Dependencies

**Reused from `volo_common`:**
- `mcc_loader_pkg.vhd` (state definitions, chunk type)
- `crc32_core.vhd` (CRC32 computation)
- `clk_divider_core.vhd` (playback rate control)

**New modules:**
- `inspectable_buffer_loader_core.vhd` (enhanced loader with debug)
- `debug_mux.vhd` (selectable debug output routing)

---

## 10. Python Test Helpers

### 10.1 Required CLI Arguments (No Hardcoded Paths!)
```python
parser.add_argument('--ip', required=True, help='Moku IP address')
parser.add_argument('--bitstream', required=True, help='Path to bitstream .tar file')
parser.add_argument('--debug-view-a', default=0, type=int, help='OutputA debug view (0-7)')
parser.add_argument('--debug-view-b', default=0, type=int, help='OutputB debug view (0-7)')
```

### 10.2 Debug View Decoder
```python
def decode_debug_view(voltage: float, view_id: int) -> dict:
    """
    Decode oscilloscope voltage back to debug values.
    Accounts for left-shift (voltage guard bands).

    Returns dict with human-readable field names.
    """
    # Convert voltage to 16-bit digital value
    digital = int((voltage / 3.3) * 65536) - 32768

    if view_id == 0:  # Status Summary
        state = (digital >> 13) & 0x7  # Undo left-shift
        fault = (digital >> 12) & 0x1
        valid = (digital >> 11) & 0x1
        addr = (digital >> 2) & 0x7FF
        return {'state': state, 'fault': fault, 'valid': valid, 'addr': addr}
    # ... other views
```

---

## 11. Open Questions / Future Enhancements

1. **Single-step mode details:** Should FSM auto-resume after timeout, or require explicit command?
2. **Debug streaming:** Could we stream debug history (last N events) via outputs?
3. **Trigger capture:** Use STROBE edge as oscilloscope trigger for precise timing capture?
4. **Color coding:** Map debug values to specific voltage ranges for visual pattern recognition?

---

## 12. References

- **Original module:** `modules/buffer_waveform_gen/`
- **Build script:** `scripts/build_mcc_package.py`
- **Import script:** `scripts/import_mcc_build.py`
- **MCC workflow memory:** `.serena/memories/mcc_cloudcompile_packaging.md`
- **CocotB testing guide:** `tests/README.md`
- **Serena memories:** `coding_standards.md`, `design_patterns.md`, `mcc_debugging_techniques.md`

---

**END OF REQUIREMENTS DOCUMENT**

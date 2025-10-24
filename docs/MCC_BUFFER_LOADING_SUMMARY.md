# MCC Buffer Loading - Implementation Summary

## What Was Built

A complete, production-ready **MCC Buffer Loading Protocol** for streaming up to 16KB of configuration data into FPGA bitstreams during initialization.

---

## Key Files Created

### VHDL Components (`modules/volo_common/`)

1. **`common/mcc_loader_pkg.vhd`**
   - Package with types (`mcc_load_state_t`, `mcc_chunk_t`)
   - Constants (buffer size, control bit positions)
   - Helper functions (extract metadata, state checks)

2. **`core/crc32_core.vhd`**
   - IEEE 802.3 CRC32 calculator
   - Processes 32-bit words incrementally
   - Single-cycle update per word

3. **`core/mcc_buffer_loader.vhd`**
   - 6-state machine: IDLE → LOADING → VALIDATING → READY → RUNNING (or ERROR)
   - STROBE edge detector for chunk synchronization
   - BRAM buffer (4KB default, configurable to 16KB)
   - Automatic CRC validation
   - Read interface for module core

### Python Helpers (`tests/conftest.py`)

4. **`set_regs(dut, control_regs, ...)`** - NEW!
   - Simple, immediate register writes (no network latency)
   - Use for fast testing and non-MCC modules

5. **`mcc_network_set_regs(dut, control_regs, ...)`** - RENAMED!
   - Simulates realistic MCC network latency (10-200ms)
   - Use for MCC-specific testing (buffer loading, etc.)

6. **`mcc_load_buffer(dut, buffer_data, ...)`**
   - High-level helper for buffer loading workflow
   - Computes CRC32, sends metadata, streams chunks
   - Returns load summary (`length`, `num_chunks`, `expected_crc`)

7. **`mcc_set_regs`** - ALIAS (backward compatibility)
   - Points to `mcc_network_set_regs()` for existing code

### Documentation

8. **`docs/MCC_BUFFER_LOADING.md`**
   - Complete protocol specification
   - Timing analysis (proves no handshaking needed!)
   - Python & VHDL integration patterns
   - Performance analysis, testing guide

9. **`docs/MCC_BUFFER_LOADING_EXAMPLE.vhd`**
   - Full Top.vhd integration example
   - Shows signal extraction, bundling, instantiation

### Demo Module (`modules/buffer_waveform_gen/`)

10. **`core/buffer_waveform_gen_core.vhd`**
    - Simple waveform generator that reads from loaded buffer
    - Demonstrates buffer read interface usage

11. **`top/Top.vhd`**
    - Complete MCC integration example
    - Shows buffer loader + clock divider + core
    - Maps debug/status to OutputD

12. **`tests/test_buffer_waveform_gen.py`**
    - 6 comprehensive CocotB tests:
      1. Basic buffer loading with CRC validation
      2. Waveform playback verification
      3. Buffer wrap-around testing
      4. Buffer readback integrity check
      5. CRC error detection (ERROR state)
      6. All tests passed marker

---

## Protocol Quick Reference

### Python Workflow

```python
# Load buffer with network latency simulation
samples = [int(32767 * math.sin(2*math.pi*i/256)) for i in range(256)]
result = await mcc_load_buffer(dut, buffer_data=samples)

# Enable module (no network latency for fast testing)
await set_regs(dut, {0: mcc_cr0(divider=100)}, set_mcc_ready=True)
```

### VHDL Integration Pattern

```vhdl
-- Extract control signals
load_complete <= Control0(28);
load_strobe   <= Control0(27);
buffer_length <= unsigned(Control1(31 downto 16));
expected_crc  <= Control2;
chunk_data <= (Control3, Control4, ..., Control10);

-- Instantiate loader
U_LOADER: entity WORK.mcc_buffer_loader
    generic map (BUFFER_SIZE => 1024)
    port map (
        load_complete => load_complete,
        load_strobe => load_strobe,
        buffer_length => buffer_length,
        expected_crc => expected_crc,
        chunk_data => chunk_data,
        buffer_addr => addr_from_core,
        buffer_dout => data_to_core,
        ...
    );
```

---

## Key Design Decisions

### 1. Fire-and-Forget Protocol

**No handshaking needed** because:
- Network write: ~50ms (typical)
- FPGA latching: ~128ns (worst case)
- **Ratio: 390,625× margin!**

### 2. CRC32 Validation

- IEEE 802.3 polynomial (standard Ethernet CRC)
- Computed incrementally during chunk streaming
- Validated at end of LOADING phase
- Mismatch → ERROR state (sticky fault flag)

### 3. Primitive Separation

**Why separate `set_regs()` and `mcc_network_set_regs()`?**

Original `mcc_set_regs()` had network latency **enabled by default**, which was:
- ✅ Perfect for MCC buffer loading (realistic timing)
- ❌ Confusing for general testing (unnecessary delays)

**New approach**:
- `set_regs()` - Fast, no latency (default for testing)
- `mcc_network_set_regs()` - Realistic latency (MCC-specific)
- `mcc_set_regs` - Alias for backward compatibility

### 4. Register Reuse

Control1 and Control2 serve **dual purposes**:
- **LOADING phase**: Buffer metadata (length + CRC)
- **RUNNING phase**: Module configuration

This works because metadata is latched in IDLE→LOADING transition!

---

## Testing the Demo Module

```bash
cd tests/
uv run make TEST_MODULE=buffer_waveform_gen
```

**Expected output**:
```
Test 1: Basic Buffer Loading with CRC Validation ✓
Test 2: Waveform Playback from Buffer ✓
Test 3: Buffer Wrap-Around ✓
Test 4: Buffer Readback Verification ✓
Test 5: CRC Error Detection ✓
Test 6: All Tests Passed ✓
```

**Test highlights**:
- Test 1: Loads 64 words with **network latency**, verifies CRC validation
- Test 2: Loads 256-sample sine wave, verifies playback
- Test 3: Confirms buffer wraps correctly (address 15 → 0)
- Test 4: Reads back all data, verifies integrity
- Test 5: Intentionally corrupts CRC, verifies ERROR state
- Test 6: All tests passed marker

---

## Performance

| Buffer Size | Chunks | Network Time* | FPGA Time | Total |
|-------------|--------|---------------|-----------|-------|
| 1KB (256w) | 32 | ~1.6s | 4µs | ~1.6s |
| **4KB (1024w)** | **128** | **~6.4s** | **16µs** | **~6.4s** |
| 16KB (4096w) | 512 | ~25.6s | 65µs | ~25.6s |

*Assuming 50ms per chunk (realistic network latency)

**Bottleneck**: Network, not FPGA!

**Optimization**: Use Control3-31 (29 words/chunk) → 3.6× faster!

---

## Next Steps

### Using in Your Module

1. **Add to Top.vhd**:
   - Extract control signals (bits 28:27 from Control0)
   - Bundle Control3-10 into chunk array
   - Instantiate `mcc_buffer_loader`
   - Connect buffer read interface to your core

2. **Update Core**:
   - Add buffer read ports (`buffer_addr`, `buffer_data`)
   - Check `buffer_valid` before enabling
   - Use loaded data in your logic

3. **Create CocotB Test**:
   - Call `mcc_load_buffer()` during setup
   - Use `set_regs()` for fast testing
   - Use `mcc_network_set_regs()` for realistic MCC timing

### Example Use Cases

- **Waveform generators**: Pre-load sine, chirp, arbitrary shapes
- **FIR filters**: Load coefficient tables
- **AWGs**: Complex waveform data
- **Neural networks**: Weight matrices
- **Lock-ins**: Reference waveforms
- **LUTs**: Calibration, nonlinearity correction

---

## Documentation References

- **`docs/MCC_BUFFER_LOADING.md`** - Complete protocol spec
- **`docs/MCC_BUFFER_LOADING_EXAMPLE.vhd`** - Integration example
- **`modules/buffer_waveform_gen/`** - Demo module (reference implementation)
- **`tests/test_buffer_waveform_gen.py`** - Test examples
- **`tests/conftest.py`** - Python helper functions

---

## Questions & Troubleshooting

### Q: How do I know if buffer loading succeeded?

Check `buffer_valid` and `load_fault` signals (OutputD in demo):
- `buffer_valid=1, load_fault=0` → Success!
- `buffer_valid=0, load_fault=1` → CRC error
- `load_state=0b111` → ERROR state

### Q: Can I reload the buffer?

Not without resetting the module. Buffer is loaded once during LOADING phase.

### Q: What if I need more than 16KB?

Options:
1. Use larger chunks (Control3-31 = 29 words)
2. Compress data in Python, decompress in FPGA
3. Use multiple buffer loader instances

### Q: Why is loading slow?

Network latency (~50ms per chunk) is the bottleneck, not FPGA. This is realistic for Moku hardware.

### Q: When should I use `set_regs()` vs `mcc_network_set_regs()`?

- **`set_regs()`**: Fast testing, development, non-MCC modules
- **`mcc_network_set_regs()`**: MCC buffer loading, realistic timing tests

---

**Author**: Claude Code
**Date**: 2025-01-23
**Status**: Production-ready ✅

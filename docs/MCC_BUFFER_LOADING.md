# MCC Buffer Loading Protocol

## Overview

The MCC Buffer Loading Protocol enables streaming arbitrary-sized data buffers (up to 16KB) into FPGA bitstreams during module initialization via MCC Control Registers. It uses a **fire-and-forget** one-way communication protocol with CRC32 validation.

**Key Innovation**: Leverages the timing disparity between network operations (10-200ms) and FPGA logic (nanoseconds) to eliminate the need for bidirectional handshaking.

## Why This Exists

MCC modules often need more configuration data than fits in Control0-Control2:
- **Waveform generators**: Pre-loaded samples (sine, chirp, custom shapes)
- **FIR filters**: Coefficient tables
- **Arbitrary waveform generators**: Complex waveform data
- **Neural networks**: Weight matrices
- **Lock-in amplifiers**: Reference waveforms
- **Lookup tables**: Calibration data, nonlinearity correction

Traditional approach (hardcode in VHDL) has drawbacks:
- ❌ Requires recompilation for different data
- ❌ No runtime configurability
- ❌ Limited to small datasets

**MCC Buffer Loading** solves this:
- ✅ Load arbitrary data at runtime
- ✅ No bitstream recompilation needed
- ✅ Up to 16KB (4096 words) per buffer
- ✅ CRC32 validation ensures integrity
- ✅ Simple fire-and-forget protocol

## Protocol Design

### Key Principles

1. **One-Way Communication**: Python → FPGA only (no readback)
2. **Atomic Writes**: `mcc_set_regs()` updates all registers simultaneously
3. **Timing Asymmetry**: Network is SLOW (10-200ms), FPGA is FAST (8ns @ 125MHz)
4. **Fire-and-Forget**: FPGA always finishes before next network write
5. **Length-Prefixed**: Metadata (length + CRC) sent first
6. **CRC Validation**: FPGA computes CRC during streaming, validates at end

### State Machine

```
IDLE → (metadata rx) → LOADING → (LOAD_COMPLETE) → VALIDATING
                                                       ↓
READY ← (CRC match) ←──────────────────────────────────┘
  ↓                     ↓
  ↓                   ERROR (CRC mismatch)
  ↓
RUNNING (global_enable)
```

**States**:
- **IDLE**: Waiting for metadata (buffer_length + expected_crc)
- **LOADING**: Accepting data chunks, computing CRC
- **VALIDATING**: Comparing computed CRC vs expected CRC
- **READY**: Success! Buffer valid, waiting for module enable
- **RUNNING**: Normal operation, buffer read-only
- **ERROR**: CRC mismatch, FAULT flag set (sticky)

### Register Allocation

| Register | Bits | Purpose | Phase |
|----------|------|---------|-------|
| **Control0[31]** | 1 | MCC_READY (standard) | All |
| **Control0[30]** | 1 | User Enable (standard) | All |
| **Control0[29]** | 1 | Clock Enable (standard) | All |
| **Control0[28]** | 1 | LOAD_COMPLETE ("Python done sending") | LOADING |
| **Control0[27]** | 1 | LOAD_STROBE (pulse per chunk) | LOADING |
| **Control0[26:0]** | 27 | Module-specific config | RUNNING |
| **Control1[31:16]** | 16 | Buffer length (words, max 65535) | LOADING |
| **Control1[15:0]** | 16 | Reserved (future: flags) | - |
| **Control2[31:0]** | 32 | Expected CRC32 | LOADING |
| **Control3-10** | 8×32 | Data chunk (8 words = 256 bits) | LOADING |

**Note**: Control1 and Control2 are used for buffer metadata during LOADING, then **overwritten** with module configuration during RUNNING. This is safe because buffer metadata is latched in IDLE→LOADING transition.

### Chunk Streaming

- **Chunk size**: 8 words (Control3-10)
- **Chunk payload**: 256 bits per transfer
- **Max buffer**: 4096 words (512 chunks)
- **Strobe mechanism**: Rising edge detection on Control0[27]
- **Padding**: Last chunk zero-padded if buffer_length not multiple of 8

## Python API

### Basic Usage

```python
from conftest import mcc_load_buffer, mcc_set_regs, mcc_cr0

# Step 1: Load buffer (up to 4096 words)
waveform_data = [0x12345678, 0xABCDEF00, ...]  # 1024 words
result = await mcc_load_buffer(dut, buffer_data=waveform_data)

# Step 2: FPGA auto-validates (IDLE → LOADING → VALIDATING → READY)
# If CRC matches, state = READY
# If CRC fails, state = ERROR (load_fault = '1')

# Step 3: Enable module for normal operation (READY → RUNNING)
await mcc_set_regs(dut, {
    0: mcc_cr0(divider=240),  # Overwrites LOAD_COMPLETE/LOAD_STROBE (OK!)
    1: 0x043C7D00,            # Overwrites buffer_length (OK!)
    2: 0x64000000             # Overwrites expected_crc (OK!)
}, set_mcc_ready=True)
```

### Function Signature

```python
async def mcc_load_buffer(dut, buffer_data,
                          chunk_size=8,
                          settle_cycles=1000,
                          simulate_network_delay=True):
    """
    Args:
        dut: Device Under Test (CustomWrapper entity)
        buffer_data: List of 32-bit words (up to 4096)
        chunk_size: Words per chunk (default: 8 for Control3-10)
        settle_cycles: Wait time after LOAD_COMPLETE (default: 1000 cycles)
        simulate_network_delay: Enable latency simulation (default: True)

    Returns:
        Dict: {'length': int, 'num_chunks': int, 'expected_crc': int}
    """
```

### Protocol Sequence (Python Side)

1. **Compute CRC32** (Python `zlib.crc32()`)
2. **Send metadata**: `Control1 = (length << 16)`, `Control2 = crc`
3. **Stream chunks**:
   - For each chunk: `mcc_set_regs({0: STROBE, 3-10: data})`
   - Clear STROBE: `Control0 = 0`
4. **Signal completion**: `Control0 = LOAD_COMPLETE`
5. **Wait**: 1000 cycles for FPGA validation

## VHDL Integration

### Components

Located in `modules/volo_common/`:

1. **`common/mcc_loader_pkg.vhd`**: Package with types, constants, helpers
2. **`core/crc32_core.vhd`**: CRC32 calculator (IEEE 802.3 polynomial)
3. **`core/mcc_buffer_loader.vhd`**: Buffer loader with state machine

### Top-Level Integration Pattern

```vhdl
library WORK;
use WORK.mcc_loader_pkg.all;

architecture MyModule of CustomWrapper is
    -- Extract control signals
    signal load_complete : std_logic;
    signal load_strobe   : std_logic;
    signal buffer_length : unsigned(15 downto 0);
    signal expected_crc  : std_logic_vector(31 downto 0);
    signal chunk_data    : mcc_chunk_t;  -- Control3-10

    -- Loader outputs
    signal load_state    : mcc_load_state_t;
    signal buffer_valid  : std_logic;
    signal load_fault    : std_logic;

    -- Buffer read interface
    signal buffer_addr   : unsigned(11 downto 0);
    signal buffer_data   : std_logic_vector(31 downto 0);

begin
    -- Extract signals from Control registers
    load_complete <= Control0(28);
    load_strobe   <= Control0(27);
    buffer_length <= unsigned(Control1(31 downto 16));
    expected_crc  <= Control2;

    -- Bundle Control3-10 into array
    chunk_data(0) <= Control3;
    chunk_data(1) <= Control4;
    -- ... chunk_data(7) <= Control10

    -- Instantiate loader
    U_BUFFER_LOADER: entity WORK.mcc_buffer_loader
        generic map (BUFFER_SIZE => 1024)  -- 4KB
        port map (
            clk => Clk, n_reset => n_reset,
            load_complete => load_complete,
            load_strobe => load_strobe,
            global_enable => global_enable,
            buffer_length => buffer_length,
            expected_crc => expected_crc,
            chunk_data => chunk_data,
            load_state => load_state,
            buffer_valid => buffer_valid,
            load_fault => load_fault,
            buffer_addr => buffer_addr,  -- From module core
            buffer_dout => buffer_data   -- To module core
        );

    -- Your module core uses buffer_addr/buffer_data to read loaded data
    U_CORE: entity WORK.my_module_core
        port map (
            enable => global_enable and buffer_valid,  -- Only run when buffer valid!
            buffer_addr => buffer_addr,  -- Output: address to read
            buffer_data => buffer_data,  -- Input: data at address
            ...
        );
end architecture;
```

See `docs/MCC_BUFFER_LOADING_EXAMPLE.vhd` for complete example.

## CRC32 Implementation

### Algorithm

- **Polynomial**: IEEE 802.3 (Ethernet) = 0x04C11DB7
- **Initial value**: 0xFFFFFFFF
- **Final XOR**: 0xFFFFFFFF (applied by Python `zlib.crc32()`)
- **Byte order**: Little-endian (process byte 0 first)

### Python Side

```python
import zlib

crc_bytes = b''.join(word.to_bytes(4, byteorder='little') for word in buffer_data)
expected_crc = zlib.crc32(crc_bytes) & 0xFFFFFFFF
# zlib.crc32() already applies final XOR, so this is the expected value
```

### FPGA Side

```vhdl
-- crc32_core.vhd processes 4 bytes per 32-bit word
-- Computes CRC incrementally on each STROBE pulse
-- Output: crc_out (before final XOR)

-- In mcc_buffer_loader.vhd:
if (not crc_current) = expected_crc_reg then
    -- Match! (applying final XOR with 'not' operator)
    state_reg <= LOAD_STATE_READY;
else
    -- Mismatch!
    state_reg <= LOAD_STATE_ERROR;
end if;
```

## Timing Analysis

### Why No Handshaking Needed

**Network write latency** (Python → FPGA):
- Moku network: ~10-200ms per `mcc_set_regs()` call
- Typical: ~50ms average

**FPGA latching time** (per chunk):
- STROBE edge detection: 1 cycle = 8ns @ 125MHz
- BRAM write (8 words): 8 cycles (loop unrolled) = 64ns
- CRC update (8 words): 8 cycles = 64ns
- **Total**: ~128ns worst case

**Ratio**: 50ms / 128ns = **390,625× margin**

Even with **fastest** network (10ms) and **slowest** FPGA (1µs if synthesis is terrible), margin is still 10,000×.

**Conclusion**: FPGA will **always** finish before next network write. No handshaking required!

### Settle Time

After LOAD_COMPLETE, Python waits 1000 cycles (8µs) for validation:
- CRC comparison: 1 cycle
- State transition: 1 cycle
- **Total needed**: ~10 cycles

1000 cycles = **100× safety margin**. Comedically large, but ensures robustness.

## Error Handling

### CRC Mismatch

If computed CRC ≠ expected CRC:
1. State machine transitions to **ERROR**
2. `load_fault` output goes high (sticky)
3. `buffer_valid` goes low
4. Module core should **NOT** enable (check `buffer_valid` first!)

**Recovery**: Reset required (no automatic retry)

### Buffer Overflow

If more chunks sent than `buffer_length` specified:
- FPGA ignores extra words (write pointer clipped at `buffer_length`)
- CRC computation continues (mismatch likely)
- State → ERROR

### Partial Chunks

If `buffer_length` not multiple of 8:
- Python zero-pads last chunk
- FPGA writes all 8 words (padding stored in BRAM)
- Module core should only read up to `buffer_length`

## Performance

### Buffer Sizes

| Size | Words | Chunks | Python Time* | FPGA Time | Total Time |
|------|-------|--------|--------------|-----------|------------|
| 1KB | 256 | 32 | 1.6s | 4µs | ~1.6s |
| 4KB | 1024 | 128 | 6.4s | 16µs | ~6.4s |
| 16KB | 4096 | 512 | 25.6s | 65µs | ~25.6s |

*Assuming 50ms per chunk (network latency)

**Bottleneck**: Network, not FPGA!

### Optimization Possibilities

If 25s is too slow for 16KB:
1. **Reduce network delay**: Optimize Moku API (not user-controllable)
2. **Increase chunk size**: Use Control3-31 (29 words) instead of Control3-10 (8 words)
   - 29 words/chunk → 142 chunks for 4KB → **7.1s** (3.6× faster!)
3. **Compress data**: Send compressed, decompress in FPGA (complex)

Current design uses Control3-10 (8 words) for simplicity and register availability.

## Testing

See `docs/MCC_BUFFER_LOADING_EXAMPLE.vhd` for CocotB test pattern.

**Key test cases**:
1. **Basic loading**: 64 words (8 chunks), verify CRC pass
2. **Large buffer**: 1024 words (128 chunks), verify CRC pass
3. **CRC mismatch**: Corrupt data, verify ERROR state
4. **Partial chunk**: 65 words (9th chunk partial), verify padding
5. **Buffer readback**: Read buffer via buffer_addr/buffer_dout, verify data
6. **State transitions**: Verify IDLE → LOADING → VALIDATING → READY → RUNNING

## Files

### VHDL Components

- `modules/volo_common/common/mcc_loader_pkg.vhd` - Package (types, constants)
- `modules/volo_common/core/crc32_core.vhd` - CRC32 calculator
- `modules/volo_common/core/mcc_buffer_loader.vhd` - Buffer loader core

### Python Helpers

- `tests/conftest.py::mcc_load_buffer()` - Main loading function

### Documentation

- `docs/MCC_BUFFER_LOADING.md` - This file
- `docs/MCC_BUFFER_LOADING_EXAMPLE.vhd` - Integration example
- `design_patterns.md` - Pattern #N (TBD)

## Future Enhancements

### Phase 2: Larger Chunks

Use Control3-31 (29 words) instead of Control3-10 (8 words):
- **Pros**: 3.6× faster loading
- **Cons**: Fewer registers for module config during LOADING

### Phase 3: Multiple Buffers

Support multiple independent buffers:
- `Control1[15:0]` = buffer_id (0-255)
- Instantiate multiple `mcc_buffer_loader` instances
- Each buffer has independent validation

### Phase 4: Compression

Add decompression in FPGA:
- Load compressed data (faster network transfer)
- Decompress to full buffer (requires complex VHDL)
- Trade-off: FPGA resources vs network time

## Comparison to Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **Hardcode in VHDL** | Simple, fast | No runtime config, requires recompilation |
| **Control0-2 only** | Simple protocol | Limited to 96 bits |
| **This protocol** | Runtime config, 16KB max, validated | Slower (25s for 16KB), one-way only |
| **External memory** | Unlimited size | Requires external hardware (SPI flash, etc.) |

## Related Documentation

- `mcc_debugging_techniques.md` - MCC 3-bit control scheme
- `design_patterns.md` - MCC integration patterns
- `cocotb_testing_guide.md` - Testing framework

---

**Author**: Claude Code
**Date**: 2025-01-23
**Version**: 1.0

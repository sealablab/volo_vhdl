# SimpleSerial and Pinata UART Protocols

## Purpose
This document describes the **SimpleSerial protocol** (ChipWhisperer standard) and the **Riscure Pinata protocol** (simplified variant) for use in side-channel analysis (SCA) and fault injection (FI) applications. This is the reference for implementing VHDL UART communication modules.

---

## Protocol Comparison Summary

| Feature | SimpleSerial V1.1 | SimpleSerial V2.1 | Pinata Protocol |
|---------|-------------------|-------------------|-----------------|
| **Baud Rate** | 38400 bps | 230400 bps | **115200 bps** |
| **Data Encoding** | Hex ASCII | Binary + COBS | **Raw binary** |
| **Line Terminator** | '\n' (0x0A) | None (COBS framing) | **None** |
| **Max Payload** | 64 bytes | 249 bytes | Unknown (likely 64) |
| **Error Checking** | None | CRC (poly 0x4D) | **None** |
| **Sub-commands** | No | Yes | **No** |
| **Format** | Cmd + Hex Data + '\n' | Cmd + SubCmd + Len + Data + CRC | **Cmd + Raw Data** |

---

## SimpleSerial V1.1 (ChipWhisperer Standard)

### Serial Settings
- **Baud rate**: 38400 bps
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None

### Message Format

**TX Format** (Host → Target):
```
<command><hex_data>\n
```

**Example**: Command 'a' with data [0x01, 0x03, 0xFF]
```
a0103FF\n
(7 bytes: 0x61 0x30 0x31 0x30 0x33 0x46 0x46 0x0A)
```

**RX Format** (Target → Host):
```
<response><hex_data>\n
```

**Acknowledgement**: 'z' command (ASCII 0x7A)
```
z00\n  (success, no data)
```

### Common Commands
- **'a'** - AES encryption (16 bytes plaintext → 16 bytes ciphertext)
- **'t'** - Trigger (no data, just sync signal)
- **'p'** - Set plaintext
- **'k'** - Set key
- **'v'** - Version query (reserved)
- **'w'** - Info query (reserved)
- **'z'** - Acknowledgement (reserved)

### Data Encoding Rules
- Each data byte → 2 hex ASCII characters (uppercase)
  - 0x01 → "01" (0x30 0x31)
  - 0xFF → "FF" (0x46 0x46)
- Message terminated with newline (0x0A)
- No CRLF (just LF)

### Buffer Requirements for V1
- **TX**: Max 64 bytes data → 128 hex chars + 1 cmd + 1 newline = **130 bytes**
- **RX**: Same as TX
- **Recommended FIFO**: 256 bytes (2× max message)

### Example Transactions

**Trigger command** (simplest):
```
t\n
TX: [0x74, 0x0A]  (2 bytes)
```

**Set key** (16 bytes):
```
k000102030405060708090A0B0C0D0E0F\n
TX: [0x6B, 0x30, 0x30, ...] (35 bytes total)
```

---

## SimpleSerial V2.1 (ChipWhisperer Advanced)

### Serial Settings
- **Baud rate**: 230400 bps
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None

### Message Format

**TX Format** (before COBS encoding):
```
<cmd><subcmd><len><data><crc>
```

**Example**: Command 'a' (0x61), subcommand 0, data [0x01, 0x03, 0xFF]
```
[0x61, 0x00, 0x03, 0x01, 0x03, 0xFF, 0xB9]
(7 bytes before COBS encoding)
```

### COBS Encoding
- Consistent Overhead Byte Stuffing
- Eliminates null bytes (0x00) for framing
- Adds packet delimiter (0x00 byte)
- Overhead: ~1 byte per 254 bytes

### CRC Calculation
- Polynomial: 0x4D (CRC-8)
- Covers: cmd + subcmd + len + data
- Appended after data

### Common Commands
- **'a'** - AES (0x61)
- **'t'** - Trigger (0x74)
- **'e'** - Error/acknowledgement (0x65)
- **'v'** - Version (0x76, reserved)
- **'w'** - Info (0x77, reserved)

### Buffer Requirements for V2
- **TX**: Max 249 bytes data + 4 overhead + COBS → **~260 bytes**
- **RX**: Same
- **Recommended FIFO**: 512 bytes

---

## Riscure Pinata Protocol (Simplified)

### Serial Settings
- **Baud rate**: **115200 bps** ✓
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None (disabled)

### Message Format

**TX Format**:
```
<cmd><raw_data_bytes>
```

**Key Differences from SimpleSerial**:
- ❌ **No hex encoding** (data sent as raw bytes)
- ❌ **No line terminator** (no '\n' or CRLF)
- ✓ **Simpler implementation** (just cmd + data)

### Example Transactions

**Trigger command** (simplest):
```
t
TX: [0x74]  (1 byte only!)
```

**Data command 'd'** with 3 bytes:
```
d<byte1><byte2><byte3>
TX: [0x64, 0x01, 0x03, 0xFF]  (4 bytes)
```

**Encryption command 'e'** with 16-byte plaintext:
```
e<16 bytes of plaintext>
TX: [0x65, 0x00, 0x11, 0x22, ..., 0xFF]  (17 bytes)
```

### Implemented Commands
- **'e'** - Encryption (exact usage TBD)
- **'d'** - Data (exact usage TBD)
- **'t'** - Trigger (**priority for initial implementation**)

### Buffer Requirements for Pinata
- **TX**: Assume max 64 bytes data + 1 cmd = **65 bytes**
- **RX**: Same (if bidirectional in future)
- **Recommended FIFO**: 256 bytes (comfortable margin)

### Notes
- Protocol details inferred from community reverse engineering
- Official Pinata documentation at: https://github.com/Keysight/Pinata
- Pinata board: ARM Cortex-M4F @ 168 MHz, STM32F4 based
- Designed for SCA/FI training

---

## VHDL Implementation Considerations

### Target: Moku-Go Platform
- **System clock**: 125 MHz (8 ns period)
- **Interface**: 16-channel DIO (3.3V logic, 5V tolerant)
- **CustomWrapper integration**: DIO mapped to Input/Output slots

### Baud Rate Generation

**For 115200 baud** (Pinata priority):
- Bit period: 1/115200 = 8.68 μs
- Clocks per bit @ 125 MHz: 8.68 μs / 8 ns = **1085 clocks**
- Actual baud: 125 MHz / 1085 = **115207 baud** (0.006% error) ✓

**For 38400 baud** (SimpleSerial V1):
- Bit period: 1/38400 = 26.04 μs
- Clocks per bit @ 125 MHz: 26.04 μs / 8 ns = **3255 clocks**
- Actual baud: 125 MHz / 3255 = **38402 baud** (0.005% error) ✓

**For 230400 baud** (SimpleSerial V2):
- Bit period: 1/230400 = 4.34 μs
- Clocks per bit @ 125 MHz: 4.34 μs / 8 ns = **542 clocks**
- Actual baud: 125 MHz / 542 = **230627 baud** (0.099% error) ✓

**Verdict**: All three baud rates are **easily achievable** with <0.1% error!

### Module Architecture Recommendations

**Phase 1: TX-Only, Pinata Protocol** (Initial target)
- Single byte commands ('t' trigger)
- Raw byte transmission (no hex encoding)
- No line terminator
- 256-byte TX FIFO
- Configurable baud rate divider via Control register

**Phase 2: SimpleSerial V1 TX Support**
- Add hex encoding logic (byte → 2 ASCII hex chars)
- Add newline terminator
- Support 38400 baud

**Phase 3: Full Bidirectional**
- Add RX path
- Acknowledgement handling ('z' or 'e' responses)

### Suggested Module Name
**`uart_simple_tx`** - UART transmitter for SimpleSerial/Pinata protocols

---

## Testing Strategy

### CocotB Test Priorities

**Test 1**: Baud rate accuracy
- Generate known bit patterns
- Measure timing with simulation clock
- Verify <1% error

**Test 2**: Trigger command ('t')
- Send 0x74 (Pinata) or "t\n" (SimpleSerial V1)
- Verify correct UART framing (start bit, 8 data bits, stop bit)

**Test 3**: Multi-byte transmission
- Queue multiple bytes in FIFO
- Verify sequential transmission
- Check FIFO empty/full flags

**Test 4**: Control register configuration
- Set baud rate divider
- Trigger transmission via control bit
- Read status register (busy, FIFO level)

### Hardware Validation
- Deploy to Moku-Go
- Connect DIO TX pin to logic analyzer
- Send trigger commands
- Verify 115200 baud @ 3.3V logic
- Test with real Pinata board

---

## Control Register Design (Preliminary)

**Control0** (MCC 3-bit scheme + UART config):
```
[31]    = MCC_READY (set by MCC)
[30]    = Enable (user enable/disable)
[29]    = ClkEn (clock enable)
[28:16] = Baud rate divider (13 bits, 0-8191)
          1085 for 115200 baud
          3255 for 38400 baud
          542 for 230400 baud
[15:8]  = TX data byte (write here to queue byte)
[7]     = TX trigger (write 1 to send byte)
[6:4]   = Protocol select
          000 = Pinata (raw, no terminator)
          001 = SimpleSerial V1 (hex + '\n')
          010 = SimpleSerial V2 (binary + COBS)
[3:0]   = Reserved
```

**Status0** (Read-only):
```
[31]    = TX busy (1 = transmitting)
[30]    = FIFO full
[29]    = FIFO empty
[28:16] = FIFO level (0-255)
[15:8]  = Last transmitted byte (debug)
[7]     = FAULT (sticky)
[6]     = ALARM (sticky)
[5:0]   = Reserved
```

---

## References

- ChipWhisperer SimpleSerial Docs: https://chipwhisperer.readthedocs.io/en/latest/simpleserial.html
- Riscure Pinata Repository: https://github.com/Keysight/Pinata
- Community Blog (Protocol Analysis): https://www.j-michel.org/blog/2018/02/21/porting-riscure-2016-ctf-on-chipwhisperer

---

## Revision History

- **2025-10-23**: Initial version (Phase 1: Pinata TX-only target)
- **Future**: Add SimpleSerial V1/V2 full support, RX path

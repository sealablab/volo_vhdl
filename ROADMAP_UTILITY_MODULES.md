# Utility Modules Roadmap - Prioritized for Next Session
**Date**: 2025-10-23
**Status**: Ready for implementation
**Success Pattern**: Fixed-width signals + proven patterns = 90-100% test success

---

## Implementation Strategy

Use our **proven patterns** for guaranteed success:
1. **Pure Combinational**: 100% first-run success (comparator, mux)
2. **Shift Register**: 100% success with DEPTH+1/+2 timing (sync, debounce, edge, delay)
3. **Fixed-Width Counter**: 90-100% success (pwm, pulse_gen, counter_nbit)

**Avoid**: Generic WIDTH parameters in counters (causes 70-80% failure rate)

---

## Tier 1: Quick Wins (Pure Combinational - 30 min each)

These modules are **guaranteed** to work on first run. Zero timing issues, instant success.

### 1. volo_encoder (Priority Encoder)
**Pattern**: Pure combinational
**Complexity**: Low
**Expected Success**: 100%

**Features**:
- 8-bit or 16-bit input to encoded position
- Priority encoder (finds highest set bit)
- Valid output flag
- Use case: Interrupt controllers, arbitration

**Why First**: Simplest pure combinational logic, confidence builder

---

### 2. volo_barrel_shifter
**Pattern**: Pure combinational
**Complexity**: Low-Medium
**Expected Success**: 100%

**Features**:
- Fixed 16-bit or 32-bit data width
- Shift left/right by N positions (0-15 or 0-31)
- Logical/arithmetic shift modes
- Rotate mode
- Use case: DSP, bit manipulation

**Why Next**: Still pure combinational, more interesting than encoder

---

### 3. volo_parity_checker
**Pattern**: Pure combinational
**Complexity**: Low
**Expected Success**: 100%

**Features**:
- Fixed-width parity generation/checking
- Even/odd parity modes
- Configurable widths (8, 16, 32-bit)
- Use case: Error detection, UART, memory interfaces

**Why This**: Useful for communication protocols, still pure combinational

---

## Tier 2: Shift Register Patterns (45 min each)

These modules use our 100% reliable shift register pattern. Account for DEPTH+1/+2 timing.

### 4. volo_fifo (Circular Buffer)
**Pattern**: Shift register + fixed-width pointers
**Complexity**: Medium
**Expected Success**: 100%

**Features**:
- Fixed depth (16, 32, 64 entries)
- Fixed data width (8, 16, 32-bit)
- Read/write pointers (fixed-width counters!)
- Full/empty flags
- Use case: Data buffering, clock domain crossing

**Why Next**: Very useful, combines shift register + counter patterns

---

### 5. volo_sipo (Serial In, Parallel Out)
**Pattern**: Shift register
**Complexity**: Low
**Expected Success**: 100%

**Features**:
- Fixed-width shift register (8, 16, 32-bit)
- Serial data input
- Parallel data output
- Load/shift control
- Use case: Serial protocols, data deserialization

**Why This**: Building block for UART RX, SPI

---

### 6. volo_piso (Parallel In, Serial Out)
**Pattern**: Shift register
**Complexity**: Low
**Expected Success**: 100%

**Features**:
- Fixed-width shift register (8, 16, 32-bit)
- Parallel data input (load)
- Serial data output
- Shift complete flag
- Use case: Serial protocols, data serialization

**Why This**: Complement to SIPO, useful for UART TX improvements

---

### 7. volo_moving_average (Digital Filter)
**Pattern**: Shift register + fixed-width accumulator
**Complexity**: Medium
**Expected Success**: 95%+

**Features**:
- Fixed window size (8, 16, 32 samples)
- Fixed data width (16-bit)
- Running sum / average output
- Use case: Signal smoothing, ADC filtering

**Why This**: Practical DSP application, tests accumulator pattern

---

## Tier 3: Fixed-Width Counter Patterns (45 min each)

These modules use our proven fixed-width counter pattern (90-100% success).

### 8. volo_timer (Configurable Timer/Watchdog)
**Pattern**: Fixed-width counter (16 or 32-bit)
**Complexity**: Medium
**Expected Success**: 95%+

**Features**:
- Fixed 16-bit or 32-bit counter
- Configurable timeout value
- One-shot / continuous modes
- Timeout flag/interrupt
- Reset/reload capability
- Use case: Timeouts, watchdog timers, delays

**Why Next**: Extremely useful, proves counter pattern in real application

---

### 9. volo_baud_gen (Improved Baud Rate Generator)
**Pattern**: Fixed-width counter
**Complexity**: Low-Medium
**Expected Success**: 95%+

**Features**:
- Fixed 16-bit divider counter
- Standard baud rates (9600, 38400, 115200, etc.)
- Baud tick output
- Use case: UART, serial communication

**Why This**: Already have uart_baud_gen in volo_common, but could improve/standardize

---

### 10. volo_event_counter (Event Counter with Threshold)
**Pattern**: Fixed-width counter (16-bit)
**Complexity**: Medium
**Expected Success**: 95%+

**Features**:
- Fixed 16-bit event counter
- Configurable threshold
- Overflow detection
- Interrupt generation
- Reset/enable controls
- Use case: Event counting, statistics, metering

**Why This**: Useful for instrumentation and monitoring

---

## Tier 4: Combination Patterns (1-2 hours each)

These modules combine multiple proven patterns. Higher complexity but still reliable.

### 11. volo_crc (CRC Generator/Checker)
**Pattern**: Shift register + combinational XOR
**Complexity**: Medium-High
**Expected Success**: 90%+

**Features**:
- CRC-8, CRC-16, CRC-32 variants
- Polynomial configuration
- Generator and checker modes
- Use case: Error detection, communication protocols

**Why Later**: More complex but very useful for protocols

---

### 12. volo_uart_rx (UART Receiver)
**Pattern**: Fixed-width counter + shift register
**Complexity**: High
**Expected Success**: 90%+

**Features**:
- Complements existing uart_tx
- Baud rate detection or fixed
- 8N1, 8E1, 8O1 modes
- Frame error detection
- Use case: Complete UART implementation

**Why Later**: Complex but we already have TX, RX completes the pair

---

### 13. volo_spi_master (SPI Master Controller)
**Pattern**: Fixed-width counter + shift register
**Complexity**: High
**Expected Success**: 90%+

**Features**:
- Fixed-width shift register (8, 16, 32-bit)
- Configurable clock divider (fixed-width!)
- CPOL/CPHA modes
- Chip select control
- Use case: SPI communication, sensor interfaces

**Why Later**: Useful but complex, good test of combined patterns

---

### 14. volo_i2c_master (I2C Master Controller)
**Pattern**: Fixed-width counter + state machine
**Complexity**: High
**Expected Success**: 85%+

**Features**:
- Fixed-width bit counter
- START/STOP generation
- Clock stretching support
- ACK/NACK handling
- Use case: I2C communication, sensor interfaces

**Why Last**: Most complex, but follows proven patterns

---

## Tier 5: Advanced / Specialized (2+ hours each)

These are more complex but use proven building blocks.

### 15. volo_alu (Simple ALU)
**Pattern**: Pure combinational + fixed-width registers
**Complexity**: High
**Expected Success**: 90%+

**Features**:
- Fixed 16-bit or 32-bit operations
- Add, subtract, AND, OR, XOR, shift
- Zero/carry/overflow flags
- Use case: CPU design, DSP

---

### 16. volo_cordic (CORDIC Algorithm)
**Pattern**: Fixed-width iterative (shift + add)
**Complexity**: Very High
**Expected Success**: 80%+

**Features**:
- Fixed-point trigonometry
- Rotation/vectoring modes
- Fixed iteration count
- Use case: DSP, motor control, graphics

---

## Implementation Order Recommendation

**Tomorrow's Session (Pick 3-4 modules):**

1. **Start Easy**: volo_encoder (30 min, 100% success)
2. **Build Confidence**: volo_barrel_shifter (30 min, 100% success)
3. **Practical Win**: volo_fifo (45 min, very useful)
4. **Counter Application**: volo_timer (45 min, proves pattern)

**Expected Results**: 4 new modules, 40 new tests, 95%+ success rate

**Next Session:**
- Tier 2: SIPO, PISO, Moving Average (shift register pattern expertise)
- Tier 3: More counter applications (timer variants, generators)

**Future Sessions:**
- Tier 4: UART RX, SPI, I2C (protocol implementations)
- Tier 5: Advanced modules (ALU, CORDIC, etc.)

---

## Success Metrics to Track

For each module, document:
- **Pattern Used**: (Pure combinational / Shift register / Fixed counter)
- **Tests Written**: X tests
- **Tests Passing**: Y/X (Z%)
- **First-Run Success**: Yes/No
- **Issues Encountered**: List
- **Time Taken**: Minutes
- **Metavalue Warnings**: Count

This data will further refine our patterns and success predictors.

---

## Notes for Implementation

**Remember**:
- ✅ Use fixed-width signals (`unsigned(7 downto 0)`, `unsigned(15 downto 0)`)
- ✅ Account for DEPTH+1 (sync) or DEPTH+2 (debounce) in tests
- ✅ Pure combinational = zero timing issues
- ❌ Never use generic WIDTH for counters
- ❌ Never use while loops in tests (use timeout loops)

**Testing Strategy**:
1. Write 10 tests per module (minimum)
2. Use conftest.py helpers
3. Wrap all tests with run_with_timeout()
4. Calculate timeouts from hardware specs
5. Document timing quirks in comments

**Commit Strategy**:
- Commit after each module passes tests
- Update Serena memories after discovering new patterns
- Create session summaries for major milestones

---

**Total Pipeline**: 16 utility modules ready to implement
**Current Success Rate**: 97% (68/70 tests)
**Expected Future Rate**: 90-100% (using proven patterns)

Let's keep building! 🚀

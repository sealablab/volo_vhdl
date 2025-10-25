# Shared Modules Audit

**Date**: 2025-10-25
**Status**: Reorganization in progress

## Overview

This document categorizes all shared VHDL modules by maturity, usage, and testing status. Modules are organized into tiers to guide instrument developers on which modules are production-ready vs. experimental.

## Tier 1: Critical Infrastructure (Mandatory)

These modules are **required** for all instruments and are well-tested.

| Module | Status | Description |
|--------|--------|-------------|
| **volo_clk_divider** | ✅ Production | Configurable clock divider - used in ALL instruments |
| **volo_voltage_pkg** | ✅ Production | Type-safe voltage conversion utilities (16-bit signed) - mandatory for analog/digital interfaces |

**Note**: Both modules renamed for naming consistency (2025-10-25)
- `clk_divider_core` → `volo_clk_divider`
- `Moku_Voltage_pkg` → `volo_voltage_pkg` (not Moku-specific)

## Tier 2: General-Purpose Digital Primitives (Recommended)

Well-tested, general-purpose modules suitable for most instruments.

### Synchronization & Timing
| Module | Tests | Description |
|--------|-------|-------------|
| volo_synchronizer | ✅ CocotB | CDC-safe multi-stage synchronizer |
| volo_edge_detector | ✅ CocotB | Rising/falling edge detection |
| volo_delay_line | ✅ CocotB | Configurable signal delay |

### Logic Primitives
| Module | Tests | Description |
|--------|-------|-------------|
| volo_comparator | ✅ CocotB | Digital comparator |
| volo_mux | ✅ CocotB | Multiplexer |

### Counters & Generators
| Module | Tests | Description |
|--------|-------|-------------|
| volo_counter_nbit | ✅ CocotB | N-bit configurable counter |
| volo_pwm | ✅ CocotB | PWM generator |
| volo_debouncer | ✅ CocotB | Input debouncer |

## Tier 3: Communication Protocols (ChipWhisperer/EMFI)

Modules for UART and SimpleSerial communication with ChipWhisperer targets.

| Module | Tests | Description |
|--------|-------|-------------|
| volo_uart_tx_core | ✅ CocotB | UART transmitter core |
| volo_uart_baud_gen | ✅ CocotB | UART baud rate generator |
| volo_simpleserial_v1_tx | ✅ CocotB | SimpleSerial v1 protocol TX |
| volo_simpleserial_v2_tx | ✅ CocotB | SimpleSerial v2 protocol TX |

## Untested Modules (⚠️ Breaking Change)

**Status**: Moved to `modules/untested/` (2025-10-25)

These modules are **not recommended** for new instruments until they receive CocotB tests. Existing instruments using these modules will need migration or testing before next deployment.

| Module | Previous Use | Migration Path |
|--------|-------------|----------------|
| volo_pulse_generator | None | Add CocotB tests |
| volo_uart_pattern_tx | **PulseStar** | Add CocotB tests or migrate to tested UART modules |
| mcc_buffer_loader | None | Add CocotB tests |
| volo_sequencer_4state | None | Add CocotB tests |
| volo_onehot_monitor | **EMFI-Seq** | Migrate to `inspectable_fsm_monitor` (generic replacement) |

**Impact Assessment**:
- **PulseStar**: Uses `volo_uart_pattern_tx` - will need testing or replacement before next deployment
- **EMFI-Seq**: Uses `volo_onehot_monitor` - should migrate to `inspectable_fsm_monitor`

## Deprecated Modules (Removed)

| Module | Reason | Date |
|--------|--------|------|
| crc32_core | Unused, no tests | 2025-10-25 |
| simple_counter | Superseded by `volo_counter_nbit` | 2025-10-25 |
| probe_driver | Unused | 2025-10-25 |

## Usage Statistics

**Current Instrument Usage** (scanned 2025-10-25):

### PulseStar
- volo_clk_divider (via waveform_gen_core)
- volo_uart_pattern_tx ⚠️ (moved to untested)
- trigger_gen_core (instrument-specific)
- waveform_gen_core (instrument-specific)

### EMFI-Seq
- volo_clk_divider
- volo_voltage_pkg
- volo_onehot_monitor ⚠️ (moved to untested)
- emfi_seq_core (instrument-specific)

### SimpleWaveGen
- volo_clk_divider
- SimpleWaveGen_core (instrument-specific)

## Testing Coverage

- **Total shared modules**: 19 (before cleanup)
- **With CocotB tests**: 13 (68%)
- **Currently used in instruments**: 4 modules
  - Tested: 2 (volo_clk_divider, volo_voltage_pkg)
  - Untested: 2 (volo_uart_pattern_tx, volo_onehot_monitor)

## Recommendations for New Instruments

1. **Always use Tier 1 modules** (volo_clk_divider, volo_voltage_pkg)
2. **Prefer Tier 2 modules** over custom implementations
3. **Use Tier 3 for ChipWhisperer integration** (EMFI/glitching workflows)
4. **Avoid untested modules** until they receive CocotB coverage
5. **Document any new shared modules** and add CocotB tests before promotion

## Next Steps

- [ ] Rename `clk_divider_core` → `volo_clk_divider`
- [ ] Rename `Moku_Voltage_pkg` → `volo_voltage_pkg`
- [ ] Move untested modules to `modules/untested/`
- [ ] Remove deprecated modules
- [ ] Update `Makefile.deps`
- [ ] Update instrument imports
- [ ] Write CocotB tests for untested modules (future work)
- [ ] Migrate EMFI-Seq to `inspectable_fsm_monitor` (future work)

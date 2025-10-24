#!/usr/bin/env python3
"""
Hardware Test Script for inspectable_buffer_loader

Tests buffer loading with real-time oscilloscope debug view monitoring.
Implements voltage decoding helpers to interpret debug outputs from hardware.

Usage:
    uv run python test_inspectable_buffer_loader_hardware.py \
        --ip 192.168.13.159 \
        --bitstream modules/inspectable_buffer_loader/latest/25ff41d_mokugo_4.0.3_2_bitstreams.tar
"""

import argparse
import sys
import time
import struct
from pathlib import Path
from typing import Dict, List, Tuple

from moku.instruments import MultiInstrument, CloudCompile, Oscilloscope

# Add conftest helpers
sys.path.insert(0, str(Path(__file__).parent))
from conftest import mcc_cr0

# ============================================================================
# Debug View IDs
# ============================================================================
VIEW_STATUS_SUMMARY = 0
VIEW_CRC_COMPARISON = 1
VIEW_WRITE_ACTIVITY = 2
VIEW_CHUNK_SNAPSHOT = 3
VIEW_BRAM_READBACK = 4
VIEW_TIMING_DIAG = 5
VIEW_ERROR_DIAG = 6
VIEW_RESERVED = 7

# ============================================================================
# Voltage Decoding Helpers
# ============================================================================

def voltage_to_digital(voltage: float) -> int:
    """
    Convert oscilloscope voltage to 16-bit signed digital value.

    Oscilloscope range: -1.0V to +1.0V (typically)
    Digital range: -32768 to +32767 (16-bit signed)

    Args:
        voltage: Voltage reading from oscilloscope (V)

    Returns:
        16-bit signed integer
    """
    # Assuming oscilloscope is configured for ±1V range
    # Adjust if your scope has different range
    digital = int((voltage / 1.0) * 32768)
    return max(-32768, min(32767, digital))


def decode_view_0_status_summary(voltage: float) -> Dict:
    """
    Decode View 0: Status Summary

    Bit[15:13] = state (3 bits)
    Bit[12]    = fault (1 bit)
    Bit[11]    = valid (1 bit)
    Bit[10:0]  = buffer_addr (11 bits)
    """
    digital = voltage_to_digital(voltage)

    # Extract bit fields (handle signed)
    unsigned = digital & 0xFFFF

    state = (unsigned >> 13) & 0x7
    fault = (unsigned >> 12) & 0x1
    valid = (unsigned >> 11) & 0x1
    addr = unsigned & 0x7FF

    state_names = {
        0: "IDLE",
        1: "LOADING",
        2: "VALIDATING",
        3: "READY",
        4: "RUNNING",
        5: "WRITING_CHUNK",
        7: "ERROR"
    }

    return {
        'state': state,
        'state_name': state_names.get(state, f"UNKNOWN({state})"),
        'fault': bool(fault),
        'valid': bool(valid),
        'addr': addr,
        'voltage': voltage,
        'digital': digital
    }


def decode_view_1_crc_comparison(voltage_a: float, voltage_b: float) -> Dict:
    """
    Decode View 1: CRC Comparison

    OutputA = expected_crc[15:2] << 2
    OutputB = computed_crc[15:2] << 2
    """
    digital_a = voltage_to_digital(voltage_a)
    digital_b = voltage_to_digital(voltage_b)

    # Undo the shift (>> 2)
    expected_crc_low = (digital_a & 0xFFFF) >> 2
    computed_crc_low = (digital_b & 0xFFFF) >> 2

    match = expected_crc_low == computed_crc_low

    return {
        'expected_crc_low': expected_crc_low,
        'computed_crc_low': computed_crc_low,
        'match': match,
        'voltage_a': voltage_a,
        'voltage_b': voltage_b
    }


def decode_view_2_write_activity(voltage: float) -> Dict:
    """
    Decode View 2: Write Activity

    Bit[15:13] = chunk_word_idx (3 bits)
    Bit[12:11] = "00" (spacing)
    Bit[10:0]  = write_ptr (11 bits)
    """
    digital = voltage_to_digital(voltage)
    unsigned = digital & 0xFFFF

    chunk_idx = (unsigned >> 13) & 0x7
    write_ptr = unsigned & 0x7FF

    return {
        'chunk_word_idx': chunk_idx,
        'write_ptr': write_ptr,
        'voltage': voltage,
        'digital': digital
    }


def decode_view_3_chunk_snapshot(voltage_a: float, voltage_b: float) -> Dict:
    """
    Decode View 3: Chunk Data Snapshot

    OutputA = chunk_data[0][15:2] << 2 (first word)
    OutputB = chunk_data[7][15:2] << 2 (last word)
    """
    digital_a = voltage_to_digital(voltage_a)
    digital_b = voltage_to_digital(voltage_b)

    # Undo shift
    first_word_low = (digital_a & 0xFFFF) >> 2
    last_word_low = (digital_b & 0xFFFF) >> 2

    return {
        'first_word_low': first_word_low,
        'last_word_low': last_word_low,
        'voltage_a': voltage_a,
        'voltage_b': voltage_b
    }


def decode_view_4_bram_readback(voltage: float) -> Dict:
    """
    Decode View 4: BRAM Readback

    OutputB = bram[address][15:2] << 2
    Address selected via Control0[10:0]
    """
    digital = voltage_to_digital(voltage)

    # Undo shift
    bram_data_low = (digital & 0xFFFF) >> 2

    return {
        'bram_data_low': bram_data_low,
        'voltage': voltage,
        'digital': digital
    }


def decode_view_5_timing_diag(voltage: float) -> Dict:
    """
    Decode View 5: Timing Diagnostics

    Bit[15]    = strobe_edge
    Bit[14]    = strobe_ack
    Bit[13]    = load_complete
    Bit[12:0]  = words_written
    """
    digital = voltage_to_digital(voltage)
    unsigned = digital & 0xFFFF

    strobe_edge = (unsigned >> 15) & 0x1
    strobe_ack = (unsigned >> 14) & 0x1
    load_complete = (unsigned >> 13) & 0x1
    words_written = unsigned & 0x1FFF

    return {
        'strobe_edge': bool(strobe_edge),
        'strobe_ack': bool(strobe_ack),
        'load_complete': bool(load_complete),
        'words_written': words_written,
        'voltage': voltage,
        'digital': digital
    }


def decode_view_6_error_diag(voltage: float) -> Dict:
    """
    Decode View 6: Error Diagnostics

    Bit[15:13] = error_code (3 bits)
    Bit[12:10] = error_state (3 bits)
    Bit[9:8]   = "00" (spacing)
    Bit[7:0]   = error_details (8 bits)
    """
    digital = voltage_to_digital(voltage)
    unsigned = digital & 0xFFFF

    error_code = (unsigned >> 13) & 0x7
    error_state = (unsigned >> 10) & 0x7
    error_details = unsigned & 0xFF

    error_names = {
        0: "NONE",
        1: "CRC_MISMATCH",
        2: "OVERFLOW",
        3: "UNDERFLOW",
        4: "TIMEOUT"
    }

    return {
        'error_code': error_code,
        'error_name': error_names.get(error_code, f"UNKNOWN({error_code})"),
        'error_state': error_state,
        'error_details': error_details,
        'voltage': voltage,
        'digital': digital
    }


# ============================================================================
# Hardware Test Functions
# ============================================================================

def setup_bench(m: MultiInstrument, ip: str, bitstream_path: str) -> Tuple[CloudCompile, Oscilloscope]:
    """
    Setup bench configuration: CloudCompile + Oscilloscope

    Returns:
        (mcc, osc) tuple
    """
    print(f"\n{'='*70}")
    print(f"Setting up MokuBench: CloudCompile + Oscilloscope")
    print(f"{'='*70}")

    # Deploy CloudCompile to Slot 1
    print(f"\n[1/3] Deploying CloudCompile bitstream...")
    print(f"  Bitstream: {bitstream_path}")
    mcc = m.set_instrument(1, CloudCompile, bitstream=bitstream_path)
    print(f"  ✓ CloudCompile deployed to Slot 1")

    # Deploy Oscilloscope to Slot 2
    print(f"\n[2/3] Deploying Oscilloscope...")
    osc = m.set_instrument(2, Oscilloscope)
    print(f"  ✓ Oscilloscope deployed to Slot 2")

    # Configure routing
    print(f"\n[3/3] Configuring signal routing...")
    m.set_connections([
        {'source': 'Slot1OutA', 'destination': 'Slot2InA'},  # Debug A → Osc Ch1
        {'source': 'Slot1OutB', 'destination': 'Slot2InB'},  # Debug B → Osc Ch2
    ])
    print(f"  ✓ Routing: Slot1OutA → Slot2InA (Osc Ch1)")
    print(f"  ✓ Routing: Slot1OutB → Slot2InB (Osc Ch2)")

    # Configure oscilloscope
    osc.set_timebase(-5e-3, 5e-3)  # ±5ms window
    print(f"  ✓ Oscilloscope timebase: ±5ms")

    print(f"\n{'='*70}")
    print(f"✅ Bench setup complete!")
    print(f"{'='*70}\n")

    return mcc, osc


def test_1_module_initialization(mcc: CloudCompile, osc: Oscilloscope):
    """
    Test 1: Module Initialization

    Verify module starts in IDLE state with debug outputs working.
    """
    print(f"\n{'='*70}")
    print(f"TEST 1: Module Initialization")
    print(f"{'='*70}")

    # Set debug views: View 0 (Status) on both outputs
    print(f"\n[1/2] Setting debug views (View 0 on both outputs)...")
    mcc.set_control(0, mcc_cr0() | (VIEW_STATUS_SUMMARY << 24) | (VIEW_STATUS_SUMMARY << 21))
    time.sleep(0.1)
    print(f"  ✓ DEBUG_SELECT_A = {VIEW_STATUS_SUMMARY} (Status Summary)")
    print(f"  ✓ DEBUG_SELECT_B = {VIEW_STATUS_SUMMARY} (Status Summary)")

    # Capture oscilloscope data
    print(f"\n[2/2] Capturing oscilloscope data...")
    data = osc.get_data()
    print(f"  ✓ Captured {len(data['ch1'])} samples")

    # Decode status from both channels (should be identical)
    ch1_voltage = data['ch1'][len(data['ch1']) // 2]  # Mid-sample
    ch2_voltage = data['ch2'][len(data['ch2']) // 2]

    status_a = decode_view_0_status_summary(ch1_voltage)
    status_b = decode_view_0_status_summary(ch2_voltage)

    print(f"\n📊 Decoded Status (OutputA):")
    print(f"  State: {status_a['state_name']} ({status_a['state']})")
    print(f"  Fault: {status_a['fault']}")
    print(f"  Valid: {status_a['valid']}")
    print(f"  Address: {status_a['addr']}")
    print(f"  Voltage: {status_a['voltage']:.6f} V")
    print(f"  Digital: {status_a['digital']} (0x{status_a['digital'] & 0xFFFF:04X})")

    # Verify IDLE state
    if status_a['state_name'] == 'IDLE':
        print(f"\n✅ TEST 1 PASSED: Module in IDLE state")
    else:
        print(f"\n❌ TEST 1 FAILED: Expected IDLE, got {status_a['state_name']}")
        return False

    return True


def test_2_buffer_loading_simple(mcc: CloudCompile, osc: Oscilloscope):
    """
    Test 2: Simple Buffer Loading

    Load a small buffer (8 words = 1 chunk) and monitor state transitions.
    """
    print(f"\n{'='*70}")
    print(f"TEST 2: Simple Buffer Loading (8 words)")
    print(f"{'='*70}")

    # Prepare test data (8 words = 1 chunk)
    test_data = [0x12345678 + i for i in range(8)]
    print(f"\nTest data (8 words):")
    for i, word in enumerate(test_data):
        print(f"  [{i}] = 0x{word:08X}")

    # Compute XOR checksum (simple: XOR all words together)
    from functools import reduce
    import operator
    expected_checksum = reduce(operator.xor, test_data)
    print(f"\nExpected Checksum (XOR): 0x{expected_checksum:08X}")

    # Set metadata (buffer length + checksum)
    print(f"\n[1/4] Setting metadata...")
    mcc.set_control(1, len(test_data) << 16)  # Buffer length in upper 16 bits
    mcc.set_control(2, expected_checksum)  # Expected checksum
    print(f"  ✓ Buffer length: {len(test_data)} words")
    print(f"  ✓ Expected Checksum: 0x{expected_checksum:08X}")

    # Load chunk (Control3-10)
    print(f"\n[2/4] Loading chunk...")
    for i in range(8):
        mcc.set_control(3 + i, test_data[i])
    print(f"  ✓ Chunk data written to Control3-10")

    # Pulse LOAD_STROBE and set LOAD_COMPLETE
    print(f"\n[3/4] Pulsing LOAD_STROBE and setting LOAD_COMPLETE...")
    cr0_base = mcc_cr0() | (VIEW_STATUS_SUMMARY << 24) | (VIEW_STATUS_SUMMARY << 21)
    mcc.set_control(0, cr0_base | (1 << 27))  # STROBE high
    time.sleep(0.05)  # Wait for chunk to be written (8 cycles @ 125MHz = 64ns, but add margin)
    mcc.set_control(0, cr0_base | (1 << 28) | (1 << 27))  # LOAD_COMPLETE + STROBE both high
    time.sleep(0.01)
    mcc.set_control(0, cr0_base)  # Both low
    print(f"  ✓ STROBE pulsed and LOAD_COMPLETE set")

    # Wait for processing
    print(f"\n[4/4] Waiting for state transitions...")
    time.sleep(0.1)

    # Capture status
    data = osc.get_data()
    status = decode_view_0_status_summary(data['ch1'][len(data['ch1']) // 2])

    print(f"\n📊 Final Status:")
    print(f"  State: {status['state_name']}")
    print(f"  Fault: {status['fault']}")
    print(f"  Valid: {status['valid']}")

    if status['state_name'] in ['READY', 'RUNNING'] and not status['fault']:
        print(f"\n✅ TEST 2 PASSED: Buffer loaded successfully!")
        return True
    else:
        print(f"\n❌ TEST 2 FAILED: State={status['state_name']}, Fault={status['fault']}")

        # Switch to error diagnostics view if fault
        if status['fault']:
            print(f"\n🔍 Switching to Error Diagnostics (View 6)...")
            mcc.set_control(0, mcc_cr0() | (VIEW_ERROR_DIAG << 24) | (VIEW_ERROR_DIAG << 21))
            time.sleep(0.1)
            data = osc.get_data()
            error = decode_view_6_error_diag(data['ch1'][len(data['ch1']) // 2])
            print(f"\n📊 Error Details:")
            print(f"  Error: {error['error_name']} (code={error['error_code']})")
            print(f"  Error State: {error['error_state']}")
            print(f"  Details: 0x{error['error_details']:02X}")

        return False


# ============================================================================
# Main Test Runner
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Test inspectable_buffer_loader on hardware')
    parser.add_argument('--ip', required=True, help='Moku IP address (e.g., 192.168.13.159)')
    parser.add_argument('--bitstream', required=True, help='Path to bitstream .tar file')
    args = parser.parse_args()

    # Validate bitstream path
    bitstream_path = Path(args.bitstream)
    if not bitstream_path.exists():
        print(f"❌ Bitstream not found: {args.bitstream}")
        print(f"   Expected location: modules/inspectable_buffer_loader/latest/25ff*_bitstreams.tar")
        return 1

    print(f"✓ Using bitstream: {args.bitstream}")

    # Connect to Moku
    print(f"\n{'='*70}")
    print(f"Connecting to Moku at {args.ip}...")
    print(f"{'='*70}")

    try:
        m = MultiInstrument(args.ip, platform_id=2, force_connect=True)
        print(f"✓ Connected to Moku:Go")

        # Setup bench
        mcc, osc = setup_bench(m, args.ip, args.bitstream)

        # Run tests
        test_1_module_initialization(mcc, osc)
        test_2_buffer_loading_simple(mcc, osc)

        print(f"\n{'='*70}")
        print(f"✅ All tests complete!")
        print(f"{'='*70}\n")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    finally:
        print(f"\nDisconnecting...")
        m.relinquish_ownership()

    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""
Debug investigation for inspectable_buffer_loader

Deep dive into debug views to understand the fault condition.
"""

import sys
import time
import struct
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from test_inspectable_buffer_loader_hardware import *

def investigate_fault(mcc, osc):
    """Run multiple debug views to understand what's happening"""

    print(f"\n{'='*70}")
    print(f"INVESTIGATION: Detailed Debug Views")
    print(f"{'='*70}")

    # Prepare same test data
    test_data = [0x12345678 + i for i in range(8)]
    from functools import reduce
    import operator
    expected_checksum = reduce(operator.xor, test_data)

    # Set metadata
    print(f"\n[1/6] Setting metadata...")
    mcc.set_control(1, len(test_data) << 16)
    mcc.set_control(2, expected_checksum)
    print(f"  ✓ Buffer length: {len(test_data)}")
    print(f"  ✓ Expected Checksum (XOR): 0x{expected_checksum:08X}")

    # Load chunk
    print(f"\n[2/6] Loading chunk...")
    for i in range(8):
        mcc.set_control(3 + i, test_data[i])
    print(f"  ✓ Chunk loaded")

    # Check View 5 (Timing) BEFORE strobing
    print(f"\n[3/6] Checking timing BEFORE STROBE...")
    mcc.set_control(0, mcc_cr0() | (VIEW_TIMING_DIAG << 24) | (VIEW_TIMING_DIAG << 21))
    time.sleep(0.1)
    data = osc.get_data()
    timing_before = decode_view_5_timing_diag(data['ch1'][len(data['ch1']) // 2])
    print(f"  Strobe edge: {timing_before['strobe_edge']}")
    print(f"  Load complete: {timing_before['load_complete']}")
    print(f"  Words written: {timing_before['words_written']}")

    # Pulse STROBE and set LOAD_COMPLETE
    print(f"\n[4/6] Pulsing STROBE...")
    cr0_base = mcc_cr0() | (VIEW_STATUS_SUMMARY << 24) | (VIEW_TIMING_DIAG << 21)
    mcc.set_control(0, cr0_base | (1 << 27))  # STROBE high
    time.sleep(0.01)
    mcc.set_control(0, cr0_base | (1 << 28))  # LOAD_COMPLETE high, STROBE low
    time.sleep(0.1)

    # Check View 5 (Timing) AFTER strobing
    print(f"\n[5/6] Checking timing AFTER STROBE...")
    mcc.set_control(0, mcc_cr0() | (VIEW_TIMING_DIAG << 24) | (VIEW_TIMING_DIAG << 21))
    time.sleep(0.1)
    data = osc.get_data()
    timing_after = decode_view_5_timing_diag(data['ch1'][len(data['ch1']) // 2])
    print(f"  Strobe edge: {timing_after['strobe_edge']}")
    print(f"  Load complete: {timing_after['load_complete']}")
    print(f"  Words written: {timing_after['words_written']}")

    # Check View 1 (CRC Comparison)
    print(f"\n[6/6] Checking CRC comparison...")
    mcc.set_control(0, mcc_cr0() | (VIEW_CRC_COMPARISON << 24) | (VIEW_CRC_COMPARISON << 21))
    time.sleep(0.1)
    data = osc.get_data()
    crc_comp = decode_view_1_crc_comparison(
        data['ch1'][len(data['ch1']) // 2],
        data['ch2'][len(data['ch2']) // 2]
    )
    print(f"  Expected CRC (low 16): 0x{crc_comp['expected_crc_low']:04X}")
    print(f"  Computed CRC (low 16): 0x{crc_comp['computed_crc_low']:04X}")
    print(f"  Match: {crc_comp['match']}")

    # Final status
    print(f"\n[7/7] Final status...")
    mcc.set_control(0, mcc_cr0() | (VIEW_STATUS_SUMMARY << 24) | (VIEW_STATUS_SUMMARY << 21))
    time.sleep(0.1)
    data = osc.get_data()
    status = decode_view_0_status_summary(data['ch1'][len(data['ch1']) // 2])
    print(f"  State: {status['state_name']}")
    print(f"  Fault: {status['fault']}")
    print(f"  Valid: {status['valid']}")
    print(f"  Address: {status['addr']}")

    print(f"\n{'='*70}")
    print(f"Investigation complete")
    print(f"{'='*70}")

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', required=True, help='Moku IP address')
    parser.add_argument('--bitstream', required=True, help='Path to bitstream .tar file')
    args = parser.parse_args()

    bitstream = args.bitstream

    print(f"Connecting to {args.ip}...")
    m = MultiInstrument(args.ip, platform_id=2, force_connect=True)

    # Setup
    mcc = m.set_instrument(1, CloudCompile, bitstream=bitstream)
    osc = m.set_instrument(2, Oscilloscope)
    m.set_connections([
        {'source': 'Slot1OutA', 'destination': 'Slot2InA'},
        {'source': 'Slot1OutB', 'destination': 'Slot2InB'},
    ])
    osc.set_timebase(-5e-3, 5e-3)

    # Run investigation
    investigate_fault(mcc, osc)

    m.relinquish_ownership()

if __name__ == '__main__':
    main()

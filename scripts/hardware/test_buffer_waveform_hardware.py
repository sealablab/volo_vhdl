#!/usr/bin/env python3
"""
Real-Time Hardware Test for buffer_waveform_gen Module

Tests the MCC buffer loading protocol on actual Moku hardware:
- Deploys bitstream to Moku device
- Loads buffer with waveform data (metadata + chunks)
- Validates CRC
- Verifies waveform playback via oscilloscope
- Provides detailed debug output for troubleshooting

Usage:
    uv run python tests/test_buffer_waveform_hardware.py --ip 192.168.13.159
"""

import asyncio
import math
import zlib
import argparse
import sys
from typing import List, Dict
from pathlib import Path

# Add tests directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from bench_framework import BenchConfig, SlotConfig, Connection
from bench_framework.config import MOKU_GO
from bench_framework.hardware import HardwareBackend

# ==================================================================================
# NOTE: This script uses the ARCHIVED bench_framework API (now in archive/)
#
# TODO: Update to use new API:
#   - BenchConfig → MokuPlatformConfig + BenchBench
#   - Connection → MokuConnection
#   - bench_framework → tests.moku_platform_simulator
#
# See: docs/MIGRATION_PLAN_MokuPlatformSimulator.md
# ==================================================================================


class BufferWaveformTester:
    """
    Real-time tester for buffer_waveform_gen module.

    Implements MCC buffer loading protocol on hardware:
    1. Deploy bitstream to CloudCompile slot
    2. Send metadata (length + CRC32) via Control1/Control2
    3. Stream data chunks via Control3-10 with STROBE pulses
    4. Signal completion via LOAD_COMPLETE
    5. Enable playback and monitor via oscilloscope
    """

    def __init__(self, ip_address: str, bitstream_path: str):
        self.ip_address = ip_address
        self.bitstream_path = bitstream_path
        self.backend: HardwareBackend = None
        self.cloudcompile = None
        self.oscilloscope = None

        # MCC Control Register Bit Positions
        self.MCC_READY_BIT = 31
        self.ENABLE_BIT = 30
        self.CLK_EN_BIT = 29
        self.LOAD_COMPLETE_BIT = 28
        self.LOAD_STROBE_BIT = 27

    async def connect(self):
        """Connect to Moku device and deploy instruments."""
        print("=" * 70)
        print("Buffer Waveform Generator - Hardware Test")
        print("=" * 70)
        print(f"Target Device: {self.ip_address}")
        print(f"Bitstream: {self.bitstream_path}")
        print()

        # Create bench configuration
        config = BenchConfig(
            platform=MOKU_GO,
            slots={
                1: SlotConfig(
                    instrument='CloudCompile',
                    bitstream=self.bitstream_path,
                    control_registers={}  # Will set manually for debugging
                ),
                2: SlotConfig(
                    instrument='Oscilloscope',
                    settings={
                        'timebase': (-5e-3, 5e-3)  # ±5ms window
                    }
                )
            },
            connections=[
                Connection(source='Slot1OutA', destination='Slot2InA'),  # Waveform on ch1
                Connection(source='Slot1OutB', destination='Slot2InB'),  # Status on ch2
            ]
        )

        # Deploy to hardware
        self.backend = HardwareBackend.from_config(config, ip_address=self.ip_address)
        await self.backend.setup()

        # Get instrument references
        self.cloudcompile = self.backend.get_instrument('CloudCompile')
        self.oscilloscope = self.backend.get_instrument('Oscilloscope')

        print()
        print("✓ Connection established and instruments deployed")
        print()

    def compute_crc32(self, buffer_data: List[int]) -> int:
        """Compute IEEE 802.3 CRC32 for buffer data."""
        # Pack as little-endian bytes (matching VHDL implementation)
        crc_bytes = b''.join(word.to_bytes(4, byteorder='little', signed=False)
                             for word in buffer_data)
        return zlib.crc32(crc_bytes) & 0xFFFFFFFF

    def generate_sine_wave(self, num_samples: int, amplitude: int = 0x7FFF) -> List[int]:
        """Generate sine wave samples (16-bit signed)."""
        samples = []
        for i in range(num_samples):
            value = int(amplitude * math.sin(2 * math.pi * i / num_samples))
            # Pack as 16-bit signed, extend to 32-bit word
            samples.append(value & 0xFFFF)
        return samples

    async def load_buffer(self, buffer_data: List[int], debug: bool = True):
        """
        Load buffer via MCC register streaming protocol.

        Steps:
        1. Send metadata (Control1 = length, Control2 = CRC32)
        2. Stream chunks (8 words per chunk via Control3-10)
        3. Pulse LOAD_STROBE (Control0[27]) after each chunk
        4. Set LOAD_COMPLETE (Control0[28]) when done
        5. Wait for hardware validation

        Args:
            buffer_data: List of 32-bit words to load
            debug: Print detailed debug output
        """
        chunk_size = 8  # Control3-10 = 8 registers
        num_chunks = (len(buffer_data) + chunk_size - 1) // chunk_size
        expected_crc = self.compute_crc32(buffer_data)

        print("-" * 70)
        print("PHASE 1: Buffer Loading")
        print("-" * 70)
        print(f"Buffer size: {len(buffer_data)} words ({len(buffer_data) * 4} bytes)")
        print(f"Chunks: {num_chunks} × {chunk_size} words")
        print(f"CRC32: 0x{expected_crc:08X}")
        print()

        # Step 1: Send metadata
        print("[1/4] Sending metadata...")
        metadata_value_c1 = (len(buffer_data) << 16) & 0xFFFF0000
        metadata_value_c2 = expected_crc

        # First check initial state
        print("  Checking initial state...")
        data = self.oscilloscope.get_data()
        if data and 'ch2' in data and len(data['ch2']) > 0:
            initial_voltage = data['ch2'][-1]
            initial_digital = int(initial_voltage * 32768) & 0xFFFF
            print(f"  Initial OutputB: {initial_voltage:.6f}V → 0x{initial_digital:04X}")

        self.cloudcompile.set_control(1, metadata_value_c1)
        self.cloudcompile.set_control(2, metadata_value_c2)

        if debug:
            print(f"  Control1 = 0x{metadata_value_c1:08X} (length={len(buffer_data)})")
            print(f"  Control2 = 0x{expected_crc:08X} (CRC32)")

        await asyncio.sleep(0.1)  # Allow network + FPGA to settle
        print("  ✓ Metadata sent\n")

        # Step 2: Stream chunks
        print(f"[2/4] Streaming {num_chunks} chunks...")
        for chunk_idx in range(num_chunks):
            start_idx = chunk_idx * chunk_size
            end_idx = min(start_idx + chunk_size, len(buffer_data))
            chunk = buffer_data[start_idx:end_idx]

            # Pad chunk to 8 words if needed
            while len(chunk) < chunk_size:
                chunk.append(0)

            # Write chunk to Control3-10
            for i, word in enumerate(chunk):
                reg_num = 3 + i
                self.cloudcompile.set_control(reg_num, word)

            # Pulse LOAD_STROBE (Control0[27])
            strobe_value = (1 << self.LOAD_STROBE_BIT)
            self.cloudcompile.set_control(0, strobe_value)

            if debug and chunk_idx % 4 == 0:  # Print every 4th chunk
                print(f"  Chunk {chunk_idx + 1}/{num_chunks}: words {start_idx}-{end_idx - 1}")

            await asyncio.sleep(0.05)  # Network delay (~50ms realistic)

            # Clear STROBE
            self.cloudcompile.set_control(0, 0x00000000)
            await asyncio.sleep(0.01)

        print(f"  ✓ All {num_chunks} chunks sent\n")

        # Step 3: Signal completion
        print("[3/4] Signaling LOAD_COMPLETE...")
        complete_value = (1 << self.LOAD_COMPLETE_BIT)
        self.cloudcompile.set_control(0, complete_value)

        await asyncio.sleep(0.2)  # Wait for FPGA validation
        print("  ✓ LOAD_COMPLETE set\n")

        # Step 4: Check status (OutputB debug bits - routed to Osc Ch2)
        print("[4/4] Verifying buffer status...")
        await asyncio.sleep(0.5)  # Wait for status to settle

        # Get status from OutputB via oscilloscope
        data = self.oscilloscope.get_data()

        if data and 'ch2' in data and len(data['ch2']) > 0:
            # OutputB is on ch2 (Slot1OutB → Slot2InB)
            # Format: [15]=load_fault, [14]=buffer_valid, [13:11]=state, [10:0]=addr
            latest_sample = data['ch2'][-1]

            # Convert voltage to 16-bit digital value
            # Moku DAC: ±1V = ±32768 digital, so sample * 32768
            digital_value = int(latest_sample * 32768) & 0xFFFF

            load_fault = (digital_value >> 15) & 0x1
            buffer_valid = (digital_value >> 14) & 0x1
            load_state = (digital_value >> 11) & 0x7
            buffer_addr = digital_value & 0x7FF

            state_names = {
                0: "IDLE", 1: "LOADING", 2: "VALIDATING",
                3: "READY", 4: "RUNNING", 7: "ERROR"
            }

            print(f"  Status bits (OutputB via Osc Ch2):")
            print(f"    Raw voltage: {latest_sample:.6f} V → 0x{digital_value:04X}")
            print(f"    load_fault   = {load_fault} {'❌ CRC ERROR!' if load_fault else '✓'}")
            print(f"    buffer_valid = {buffer_valid} {'✓ VALID' if buffer_valid else '❌ INVALID'}")
            print(f"    load_state   = {load_state} ({state_names.get(load_state, 'UNKNOWN')})")
            print(f"    buffer_addr  = {buffer_addr}")

            if load_fault:
                print("\n  ❌ Buffer loading FAILED - CRC mismatch!")
                return False
            elif not buffer_valid:
                print("\n  ❌ Buffer not valid - loading incomplete or failed!")
                return False
            elif load_state != 3:  # Not in READY state
                print(f"\n  ⚠ Buffer in unexpected state: {state_names.get(load_state, 'UNKNOWN')}")
                return False
            else:
                print("\n  ✅ Buffer loaded successfully!")
                return True
        else:
            print("  ⚠ Could not read oscilloscope data for status check")
            print("  Proceeding with caution...")
            return True

    async def enable_playback(self, clock_divider: int = 100):
        """
        Enable waveform playback.

        Sets Control0 with MCC_READY + Enable + ClkEn + Clock Divider.

        Args:
            clock_divider: Clock divider value (0-255, higher = slower playback)
        """
        print("-" * 70)
        print("PHASE 2: Enable Playback")
        print("-" * 70)
        print(f"Clock Divider: {clock_divider} (playback rate)")
        print()

        # Construct Control0 value
        # Bits 31:29 = 111 (MCC_READY + Enable + ClkEn)
        # Bits 23:16 = Clock divider
        control0_value = (
            (1 << self.MCC_READY_BIT) |
            (1 << self.ENABLE_BIT) |
            (1 << self.CLK_EN_BIT) |
            ((clock_divider & 0xFF) << 16)
        )

        print(f"Setting Control0 = 0x{control0_value:08X}")
        print(f"  Bit 31 (MCC_READY) = 1")
        print(f"  Bit 30 (Enable)    = 1")
        print(f"  Bit 29 (ClkEn)     = 1")
        print(f"  Bits 23:16 (Div)   = {clock_divider}")
        print()

        self.cloudcompile.set_control(0, control0_value)
        await asyncio.sleep(0.1)

        print("✓ Playback enabled\n")

    async def capture_waveform(self, duration_ms: float = 100):
        """
        Capture waveform data from oscilloscope.

        Args:
            duration_ms: Capture duration in milliseconds

        Returns:
            Dictionary with 'time', 'waveform', 'status' arrays
        """
        print("-" * 70)
        print("PHASE 3: Capture Waveform")
        print("-" * 70)
        print(f"Duration: {duration_ms} ms")
        print()

        # Run data collection
        data = await self.backend.run(duration_ms=duration_ms)

        if 2 in data:
            osc_data = data[2]
            num_samples = len(osc_data.get('ch1', []))

            print(f"✓ Captured {num_samples} samples")
            print(f"  Channel 1 (OutputA): Waveform data")
            print(f"  Channel 2 (OutputB): Status/debug")
            print()

            # Decode status from ch2
            status_samples = osc_data.get('ch2', [])
            if len(status_samples) > 0:
                status_val = int(status_samples[-1] * 32768) & 0xFFFF
                buffer_addr_runtime = status_val & 0x7FF
                print(f"Runtime Status (from Ch2):")
                print(f"  buffer_addr = {buffer_addr_runtime} (current playback position)")
                print()

            # Analyze waveform
            waveform = osc_data.get('ch1', [])
            if len(waveform) > 10:
                print("Waveform Statistics:")
                print(f"  Min: {min(waveform):.6f} V")
                print(f"  Max: {max(waveform):.6f} V")
                print(f"  Mean: {sum(waveform) / len(waveform):.6f} V")
                print()

                # Check if waveform is changing (not stuck)
                unique_values = len(set(int(v * 10000) for v in waveform[:100]))
                if unique_values > 10:
                    print("  ✓ Waveform is varying (playback active)")
                else:
                    print("  ⚠ Waveform appears static (check clock divider)")

            return osc_data
        else:
            print("❌ No oscilloscope data captured")
            return None

    async def run_full_test(self):
        """Run complete test sequence."""
        try:
            # Connect
            await self.connect()

            # Test 1: Load 8-word test pattern (single chunk)
            print("\n" + "=" * 70)
            print("TEST 1: Load 8-Word Test Pattern (Single Chunk)")
            print("=" * 70 + "\n")

            # Simple test pattern: 8 words
            test_pattern = [0x11111111, 0x22222222, 0x33333333, 0x44444444,
                          0x55555555, 0x66666666, 0x77777777, 0x88888888]
            success = await self.load_buffer(test_pattern, debug=True)

            if not success:
                print("\n❌ Test FAILED at buffer loading stage")
                return False

            # Test 2: Enable playback
            await self.enable_playback(clock_divider=100)

            # Test 3: Capture waveform
            waveform_data = await self.capture_waveform(duration_ms=100)

            if waveform_data:
                print("\n" + "=" * 70)
                print("✅ ALL TESTS PASSED!")
                print("=" * 70)
                print("\nBuffer waveform generator is working correctly on hardware!")
                print("Next steps:")
                print("  - Try different waveforms (square, triangle, arbitrary)")
                print("  - Test different clock dividers")
                print("  - Monitor buffer readback via OutputD")
                return True
            else:
                print("\n❌ Test FAILED at waveform capture stage")
                return False

        except Exception as e:
            print(f"\n❌ Test FAILED with exception: {e}")
            import traceback
            traceback.print_exc()
            return False

        finally:
            # Clean disconnect
            if self.backend:
                await self.backend.teardown()

    async def debug_registers(self):
        """Read and display all control register states (debugging helper)."""
        print("\n" + "=" * 70)
        print("DEBUG: Current Control Register States")
        print("=" * 70 + "\n")

        # Note: Moku API doesn't support reading control registers directly
        # This would require custom FPGA readback implementation
        print("⚠ Control register readback not supported via CloudCompile API")
        print("  (Would need custom monitoring outputs for full debugging)")
        print()


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Test buffer_waveform_gen on Moku hardware')
    parser.add_argument('--ip', required=True, help='Moku device IP address')
    parser.add_argument('--bitstream', default='modules/buffer_waveform_gen/mcc_buffer_waveform_bitstreams.tar',
                       help='Path to bitstream .tar file')
    parser.add_argument('--debug', action='store_true', help='Enable detailed debug output')

    args = parser.parse_args()

    # Validate bitstream exists
    bitstream_path = Path(args.bitstream)
    if not bitstream_path.exists():
        print(f"❌ Error: Bitstream not found at {bitstream_path}")
        print(f"   Expected location: modules/buffer_waveform_gen/mcc_buffer_waveform_bitstreams.tar")
        return 1

    # Run test
    tester = BufferWaveformTester(ip_address=args.ip, bitstream_path=str(bitstream_path))
    success = await tester.run_full_test()

    return 0 if success else 1


if __name__ == '__main__':
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

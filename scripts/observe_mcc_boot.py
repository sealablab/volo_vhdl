#!/usr/bin/env python3
"""
MCC Boot Process Observer

Deploy a module and observe what happens during the "boot" sequence:
- Initial register values
- Initial output values (before configuration)
- Behavior after configuration

Usage:
    uv run python scripts/observe_mcc_boot.py --ip 192.168.13.159 --bitstream bitstreams/simple_counter.tar.gz

Author: Claude Code
Date: 2025-01-23
"""

import argparse
import sys
import time
import numpy as np
from pathlib import Path

try:
    from moku.instruments import MultiInstrument, Oscilloscope, CloudCompile
except ImportError:
    print("ERROR: moku package not installed. Run: uv sync")
    sys.exit(1)


class MCCBootObserver:
    """Observe MCC boot behavior with different modules"""

    def __init__(self, ip_address: str, bitstream_path: str):
        self.ip = ip_address
        self.bitstream_path = Path(bitstream_path)
        self.moku = None
        self.osc = None
        self.mcc = None

    def connect_and_deploy(self):
        """Deploy bitstream and setup routing"""
        print("=" * 70)
        print("MCC BOOT PROCESS OBSERVER")
        print("=" * 70)
        print(f"\nBitstream: {self.bitstream_path.name}")
        print(f"Moku IP: {self.ip}")

        # Connect
        print("\n[1/3] Connecting to Moku...")
        self.moku = MultiInstrument(self.ip, platform_id=2, force_connect=True)
        print("✓ Connected")

        # Deploy bitstream
        print(f"\n[2/3] Deploying {self.bitstream_path.name}...")
        if not self.bitstream_path.exists():
            raise FileNotFoundError(f"Bitstream not found: {self.bitstream_path}")

        self.mcc = self.moku.set_instrument(2, CloudCompile,
                                            bitstream=str(self.bitstream_path))
        print("✓ Bitstream deployed to Slot 2")

        # Setup oscilloscope
        print("\n[3/3] Setting up Oscilloscope...")
        self.osc = self.moku.set_instrument(1, Oscilloscope)
        self.osc.set_timebase(-1e-3, 1e-3)  # ±1ms window

        # Route outputs to oscilloscope
        connections = [
            dict(source="Slot2OutA", destination="Slot1InA"),
            dict(source="Slot2OutB", destination="Slot1InB"),
        ]
        self.moku.set_connections(connections=connections)
        print("✓ Routing: Slot2 → Oscilloscope")

        print("\n✓ Setup complete!")

    def observe_initial_state(self):
        """Observe outputs immediately after deployment (before config)"""
        print("\n" + "=" * 70)
        print("OBSERVATION 1: Initial State (Immediately After Bitstream Load)")
        print("=" * 70)

        # Try to read control registers
        print("\n[Registers] Attempting to read initial control registers...")
        try:
            # MCC API might not have registers populated yet
            regs = self.mcc.get_control()
            print(f"  Found {len(regs)} registers")
            print(f"  Control0: 0x{regs[0]:08X}")
            print(f"  Control1: 0x{regs[1]:08X}")
            print(f"  Control2: 0x{regs[2]:08X}")
            print(f"  Control3: 0x{regs[3]:08X}")
        except Exception as e:
            print(f"  Cannot read registers yet: {e}")

        # Capture waveforms
        print("\n[Outputs] Capturing initial output values...")
        time.sleep(0.1)  # Brief settle time

        self.osc.set_trigger(type="Edge", source="ChannelA", level=0.0, mode="Auto", edge="Rising")
        data = self.osc.get_data()

        ch1 = np.array(data['ch1'])
        ch2 = np.array(data['ch2'])

        print(f"\n  OutputA (Ch1):")
        print(f"    Min: {np.min(ch1):.4f} V")
        print(f"    Max: {np.max(ch1):.4f} V")
        print(f"    Mean: {np.mean(ch1):.4f} V")
        print(f"    Std: {np.std(ch1):.4f} V")

        print(f"\n  OutputB (Ch2):")
        print(f"    Min: {np.min(ch2):.4f} V")
        print(f"    Max: {np.max(ch2):.4f} V")
        print(f"    Mean: {np.mean(ch2):.4f} V")
        print(f"    Std: {np.std(ch2):.4f} V")

        # Check if outputs are changing or static
        if np.std(ch1) > 0.01:
            print(f"\n  ⚠ OutputA is DYNAMIC (std={np.std(ch1):.4f}V) - not static!")
        else:
            print(f"\n  ✓ OutputA is STATIC (DC level = {np.mean(ch1):.4f}V)")

        if np.std(ch2) > 0.01:
            print(f"  ⚠ OutputB is DYNAMIC (std={np.std(ch2):.4f}V) - not static!")
        else:
            print(f"  ✓ OutputB is STATIC (DC level = {np.mean(ch2):.4f}V)")

        return {
            'ch1_mean': np.mean(ch1),
            'ch2_mean': np.mean(ch2),
            'ch1_std': np.std(ch1),
            'ch2_std': np.std(ch2)
        }

    def observe_after_config(self, config: dict):
        """Observe outputs after configuration"""
        print("\n" + "=" * 70)
        print("OBSERVATION 2: After Configuration")
        print("=" * 70)

        print(f"\nApplying configuration:")
        for reg, value in config.items():
            self.mcc.set_control(reg, value)
            print(f"  Control{reg} = 0x{value:08X}")

        # Wait for module to respond
        time.sleep(0.2)

        # Capture waveforms
        print("\n[Outputs] Capturing post-config output values...")
        data = self.osc.get_data()

        ch1 = np.array(data['ch1'])
        ch2 = np.array(data['ch2'])

        print(f"\n  OutputA (Ch1):")
        print(f"    Min: {np.min(ch1):.4f} V")
        print(f"    Max: {np.max(ch1):.4f} V")
        print(f"    Mean: {np.mean(ch1):.4f} V")
        print(f"    Std: {np.std(ch1):.4f} V")

        print(f"\n  OutputB (Ch2):")
        print(f"    Min: {np.min(ch2):.4f} V")
        print(f"    Max: {np.max(ch2):.4f} V")
        print(f"    Mean: {np.mean(ch2):.4f} V")
        print(f"    Std: {np.std(ch2):.4f} V")

        # Check behavior
        if np.std(ch1) > 0.01:
            print(f"\n  ✓ OutputA is DYNAMIC (actively changing)")
        else:
            print(f"\n  ⚠ OutputA is STATIC (stuck at {np.mean(ch1):.4f}V)")

        if np.std(ch2) > 0.01:
            print(f"  ✓ OutputB is DYNAMIC (actively changing)")
        else:
            print(f"  ⚠ OutputB is STATIC (stuck at {np.mean(ch2):.4f}V)")

        return {
            'ch1_mean': np.mean(ch1),
            'ch2_mean': np.mean(ch2),
            'ch1_std': np.std(ch1),
            'ch2_std': np.std(ch2)
        }

    def observe_disable(self):
        """Observe what happens when module is disabled"""
        print("\n" + "=" * 70)
        print("OBSERVATION 3: After Disable")
        print("=" * 70)

        print("\nDisabling module (Control0[30] = 0)...")
        # Read current CR0, clear enable bit
        regs = self.mcc.get_control()
        cr0_disabled = regs[0] & ~(1 << 30)  # Clear bit 30
        self.mcc.set_control(0, cr0_disabled)
        print(f"  Control0 = 0x{cr0_disabled:08X}")

        time.sleep(0.1)

        # Capture waveforms
        data = self.osc.get_data()
        ch1 = np.array(data['ch1'])
        ch2 = np.array(data['ch2'])

        print(f"\n  OutputA: Mean={np.mean(ch1):.4f}V, Std={np.std(ch1):.4f}V")
        print(f"  OutputB: Mean={np.mean(ch2):.4f}V, Std={np.std(ch2):.4f}V")

    def run_observations(self, config: dict):
        """Run complete observation sequence"""
        try:
            self.connect_and_deploy()

            # Observation 1: Initial state
            initial = self.observe_initial_state()

            # Observation 2: After config
            configured = self.observe_after_config(config)

            # Observation 3: After disable (skip - API issue)
            # self.observe_disable()

            # Summary
            print("\n" + "=" * 70)
            print("BOOT PROCESS SUMMARY")
            print("=" * 70)

            print("\nInitial State (after bitstream load):")
            print(f"  OutputA: {initial['ch1_mean']:.4f}V (std={initial['ch1_std']:.4f})")
            print(f"  OutputB: {initial['ch2_mean']:.4f}V (std={initial['ch2_std']:.4f})")

            print("\nConfigured State:")
            print(f"  OutputA: {configured['ch1_mean']:.4f}V (std={configured['ch1_std']:.4f})")
            print(f"  OutputB: {configured['ch2_mean']:.4f}V (std={configured['ch2_std']:.4f})")

            print("\nKey Insights:")
            if abs(initial['ch1_mean']) < 0.1 and abs(initial['ch2_mean']) < 0.1:
                print("  ✓ Both outputs start near 0V (safe boot)")
            else:
                print(f"  ⚠ Outputs NOT at 0V initially!")
                if abs(initial['ch1_mean']) > 0.1:
                    print(f"    - OutputA = {initial['ch1_mean']:.4f}V (expected ~0V)")
                if abs(initial['ch2_mean']) > 0.1:
                    print(f"    - OutputB = {initial['ch2_mean']:.4f}V (expected ~0V)")

            if configured['ch1_std'] > 0.01 or configured['ch2_std'] > 0.01:
                print("  ✓ Module responds to configuration (outputs change)")
            else:
                print("  ⚠ Module does NOT respond to configuration")

            return True

        except Exception as e:
            print(f"\n✗ Observation failed: {e}")
            import traceback
            traceback.print_exc()
            return False
        finally:
            if self.moku:
                self.moku.relinquish_ownership()
                print("\n✓ Moku connection closed")


def main():
    parser = argparse.ArgumentParser(description="Observe MCC boot process")
    parser.add_argument('--ip', required=True, help='Moku device IP address')
    parser.add_argument('--bitstream', required=True, help='Bitstream file path')
    parser.add_argument('--config', help='Config in format "0:0xC0000001,1:0x0000007F"')

    args = parser.parse_args()

    # Parse config if provided, otherwise use default
    if args.config:
        config = {}
        for pair in args.config.split(','):
            reg, val = pair.split(':')
            config[int(reg)] = int(val, 16)
    else:
        # Default: Enable with MCC_READY
        config = {0: 0xC0000001}

    observer = MCCBootObserver(args.ip, args.bitstream)
    success = observer.run_observations(config)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

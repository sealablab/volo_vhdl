#!/usr/bin/env python3
"""MokuBench Phasemeter Test - Phase/Frequency Measurement (Deployment Only)"""
import argparse, asyncio, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from bench_framework import HardwareBackend, BenchConfig, SlotConfig

MOKU_GO = {'id': 2, 'name': 'Moku:Go', 'slots': 2, 'inputs': ['Input1', 'Input2'], 'outputs': ['Output1', 'Output2'], 'clock': 125e6}

async def run_test(ip: str):
    config = BenchConfig(platform=MOKU_GO, slots={1: SlotConfig(instrument='Phasemeter', settings={})}, connections=[], metadata={'test': 'phasemeter'})
    backend = HardwareBackend.from_config(config, ip_address=ip)
    await backend.setup()
    print("✓ Phasemeter deployed successfully!")
    await backend.teardown()
    return True

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', required=True)
    args = parser.parse_args()
    sys.exit(0 if asyncio.run(run_test(args.ip)) else 1)

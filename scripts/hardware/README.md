# Hardware Deployment Scripts

Scripts for deploying and testing VHDL modules on **real Moku hardware**.

## What Goes Here

- Bitstream deployment tests
- Hardware validation scripts
- Real-world performance testing
- MCC register debugging on hardware

## Current Scripts

- `test_buffer_waveform_hardware.py` - Deploy buffer waveform generator to Moku
- `test_inspectable_buffer_loader_hardware.py` - Test buffer loader on hardware
- `test_inspectable_buffer_loader_mokubench.py` - Full bench integration test

## Usage

```bash
# Deploy to hardware
uv run python scripts/hardware/test_buffer_waveform_hardware.py --ip 192.168.13.159

# With specific bitstream
uv run python scripts/hardware/test_buffer_waveform_hardware.py \
    --ip 192.168.13.159 \
    --bitstream modules/my_module/latest/bitstream.tar
```

## Note

⚠️ These scripts currently use the **archived** `bench_framework` API.
They need to be updated to use the new `MokuPlatformConfig` + `BenchBench` models.

See: `docs/MIGRATION_PLAN_MokuPlatformSimulator.md`

# MokuBench Integration Scripts

Full bench integration tests using multiple Moku instruments together.

## What Goes Here

- Multi-instrument test campaigns
- Bench-level integration tests
- Instrument interaction validation
- Cross-module testing

## Current Scripts

- `mokubench_connection_test.py` - Verify bench wiring
- `mokubench_datalogger_test.py` - Data logger integration
- `mokubench_deployment_test.py` - Full deployment validation
- `mokubench_logic_test.py` - Logic analyzer integration
- `mokubench_phasemeter_test.py` - Phasemeter integration
- `mokubench_spectrum_test.py` - Spectrum analyzer integration
- `mokubench_waveformgen_test.py` - Waveform generator integration

## Usage

```bash
# Run bench connection test
uv run python scripts/mokubench/mokubench_connection_test.py

# Run specific instrument test
uv run python scripts/mokubench/mokubench_datalogger_test.py --ip 192.168.13.159
```

## Integration with BenchBench

These scripts should eventually use the `BenchBench` model from `models/bench/benchbench.py` to reference physical bench configurations.

Example future usage:
```python
from models.bench.benchbench import BenchBench
from tests.moku_platform_simulator import MokuPlatformConfig, HardwareBackend

# Load physical bench
bench = BenchBench.from_yaml('benches/B106.yaml')

# Define platform config
config = MokuPlatformConfig(...)

# Deploy to hardware
backend = HardwareBackend(config, bench)
await backend.setup()
```

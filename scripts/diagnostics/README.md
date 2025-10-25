# Hardware Diagnostic Scripts

Tools for diagnosing **physical hardware connections and behavior**.

## What Goes Here

- Connection diagnostic tools
- Probe characterization scripts
- Register debugging utilities
- Physical wiring verification

## Current Scripts

### DS1120A Diagnostics

- `test_ds1120a_connection_diagnostic.py` - Systematically test wiring
- `test_ds1120a_characterization.py` - Characterize probe behavior
- `test_ds1120a_power_sweep_diagnostic.py` - Test power range (5-50%)
- `test_ds1120a_audible_test.py` - Verify glitch trigger with audio feedback
- `test_ds1120a_*.py` - Various routing and isolation tests

### Register Debugging

- `test_cr0_probing.py` - Debug MCC Control Register 0
- `test_debug_investigation.py` - General debugging utility

### Device Catalog

- `test_probe_catalog.py` - Validate device catalog and models

## Usage

```bash
# Diagnose physical wiring
uv run python scripts/diagnostics/test_ds1120a_connection_diagnostic.py

# Characterize probe
uv run python scripts/diagnostics/test_ds1120a_characterization.py \
    --ip 192.168.13.159
```

## Note

⚠️ These scripts currently use the **archived** `bench_framework` API.
They need to be updated to use the new `MokuPlatformConfig` + `BenchBench` models.

See: `docs/MIGRATION_PLAN_MokuPlatformSimulator.md`

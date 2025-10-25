# MokuConfig - Core Deployment Abstraction

**Priority**: 🔴 CRITICAL - Load in EVERY context window
**Status**: Active - Core abstraction as of 2025-10-25
**Location**: `models/moku/platform_config.py`

## Overview

`MokuConfig` is THE central deployment abstraction for the Volo VHDL project. It is the single source of truth for multi-instrument deployment specifications.

**Key Insight**: Write deployment config ONCE → Use everywhere (simulation, hardware, documentation)

## Core Concept

MokuConfig bridges three worlds:
1. **VHDL Hardware** - Module bitstreams and control registers
2. **Simulation** - CocotB behavioral models (future)
3. **Hardware Deployment** - Real Moku device via `tools/moku_go.py`

## Model Structure

```python
MokuConfig(
    platform: MokuGoPlatform,          # Hardware specs (IN/OUT ports, clock, slots)
    slots: dict[int, SlotConfig],      # Instrument assignments (1-4 for Moku:Go)
    routing: list[MokuConnection],     # MCC routing matrix
    metadata: dict[str, Any]           # Optional deployment metadata
)

SlotConfig(
    instrument: str,                    # 'CloudCompile', 'Oscilloscope', etc.
    bitstream: str | None,              # Path to .tar bitstream
    control_registers: dict[int, int],  # CR0, CR1, CR2 values
    settings: dict[str, Any]            # Instrument-specific settings
)

MokuConnection(
    source: str,                        # 'Input1', 'Slot2OutA', etc.
    destination: str                    # 'Slot1InA', 'Output1', etc.
)
```

## Usage Patterns

### Pattern 1: CLI-Generated Config (Quick)
```bash
# moku_go.py auto-generates MokuConfig internally
uv run python tools/moku_go.py deploy \
    --device MokuB106 \
    --bitstream modules/PulseStar/latest/*.tar \
    --slot 2
```

Generated config:
- Slot 2: CloudCompile with specified bitstream
- Default routing: Slot2OutA→Output1, Slot2OutB→Output2
- Metadata: deployment timestamp

### Pattern 2: Explicit Config File (Reusable)
```json
{
  "platform": {
    "ip_address": "192.168.13.159",
    "device_name": "MokuB106"
  },
  "slots": {
    "2": {
      "instrument": "CloudCompile",
      "bitstream": "modules/PulseStar/latest/25ffbe_mokugo_bitstreams.tar",
      "control_registers": {
        "0": 3758096384,
        "1": 71237888,
        "2": 1677721600
      }
    }
  },
  "routing": [
    {"source": "Slot2OutA", "destination": "Output1"},
    {"source": "Slot2OutB", "destination": "Output2"}
  ],
  "metadata": {
    "test_campaign": "PulseStar-v2-characterization",
    "created": "2025-10-25T..."
  }
}
```

Deploy:
```bash
uv run python tools/moku_go.py deploy --device MokuB106 --config deploy.json
```

### Pattern 3: Programmatic Generation
```python
from models.moku import MokuConfig, SlotConfig, MokuConnection, MOKU_GO_PLATFORM

config = MokuConfig(
    platform=MOKU_GO_PLATFORM,
    slots={
        2: SlotConfig(
            instrument='CloudCompile',
            bitstream='modules/PulseStar/latest/25ffbe_mokugo_bitstreams.tar',
            control_registers={
                0: 0xE0000000,  # MCC 3-bit control scheme
                1: 0x043C7D00,
                2: 0x64000000
            }
        )
    },
    routing=[
        MokuConnection(source='Slot2OutA', destination='Output1'),
        MokuConnection(source='Slot2OutB', destination='Output2')
    ],
    metadata={'test_campaign': 'PulseStar-v2'}
)

# Export to file
with open('configs/pulsestar.json', 'w') as f:
    f.write(config.model_dump_json(indent=2))
```

### Pattern 4: CocotB Simulation (Future)
```python
# tests/test_pulsestar_mokubench.py
from models.moku import MokuConfig

config = MokuConfig.model_validate_json(Path('configs/pulsestar.json').read_text())

@cocotb.test()
async def test_with_mokuconfig(dut):
    # Deploy behavioral model using same config
    await deploy_mokuconfig(dut, config)
    # ... test logic
```

## Validation Features

MokuConfig validates at creation time:
- ✅ Slot numbers within platform limits (1-2 for Moku:Go, 1-4 for Moku:Lab)
- ✅ At least one slot configured
- ✅ Port names non-empty
- ✅ Bitstream paths exist (validated at deploy time)
- ✅ Routing references valid ports (via `validate_routing()` method)

Example validation:
```python
config = MokuConfig(
    platform=MOKU_GO_PLATFORM,
    slots={5: SlotConfig(...)}  # ERROR: Slot 5 out of range (1-2)
)
# ValidationError: Slot 5 out of range for platform (1-2)
```

## Integration Points

### tools/moku_go.py (Primary Consumer)
**Load from JSON:**
```python
deployment_config = MokuConfig.model_validate_json(config_file.read_text())
```

**Create from CLI args:**
```python
deployment_config = MokuConfig(
    platform=MOKU_GO_PLATFORM,
    slots={slot: SlotConfig(instrument='CloudCompile', bitstream=path)},
    routing=[MokuConnection(source=f'Slot{slot}OutA', destination='Output1')]
)
```

**Deploy to hardware:**
```python
# Iterate over slots
for slot_num, slot_config in deployment_config.slots.items():
    moku.set_instrument(slot_num, CloudCompile, bitstream=slot_config.bitstream)

# Configure routing
connections = [conn.to_dict() for conn in deployment_config.routing]
moku.set_connections(connections)
```

### CocotB Tests (Future Integration)
**Sim setup:**
```python
async def deploy_mokuconfig(dut, config: MokuConfig):
    """Deploy behavioral models per MokuConfig specification."""
    for slot_num, slot_config in config.slots.items():
        # Create behavioral instrument model
        await setup_slot(dut, slot_num, slot_config)
    
    # Configure routing
    await setup_routing(dut, config.routing)
```

**Validation:**
- Same config for simulation AND hardware
- Git-tracked config files ensure reproducibility

### BenchBench Integration (Future)
**Separation of concerns:**
- BenchBench = physical wiring (static, weeks/months)
- MokuConfig = deployment spec (per-test, minutes)

**Validation:**
```python
# Load bench config
bench = load_benchbench('benches/B106.yaml')

# Load deployment config
config = MokuConfig.model_validate_json(...)

# Validate routing against physical wiring
for conn in config.routing:
    if conn.destination.startswith('Output'):
        port = conn.destination.replace('Output', 'OUT')
        wired = bench.get_wired_device(port)
        if not wired:
            warnings.warn(f"{port} not physically wired in bench!")
```

## Serialization

**Export to JSON:**
```python
config.model_dump_json(Path('deploy.json').write_text(indent=2))
```

**Import from JSON:**
```python
config = MokuConfig.model_validate_json(Path('deploy.json').read_text())
```

**Export to dict:**
```python
config_dict = config.to_dict()
```

**Import from dict:**
```python
config = MokuConfig.from_dict(config_dict)
```

## Benefits

1. **Type Safety** - Pydantic validation catches errors at config-time (not runtime)
2. **Dual Backend** - Same config works for simulation AND hardware
3. **Reproducibility** - Version-controlled JSON configs in `configs/` directory
4. **Documentation** - Self-documenting deployment specifications
5. **Tooling** - Single model powers entire deployment workflow
6. **Testing** - Validated configs prevent deployment failures
7. **Composability** - Configs can be programmatically generated/modified

## Related Models

**Supporting Models (same package):**
- `SlotConfig` - Per-slot instrument configuration
- `MokuConnection` - Signal routing specification
- `MokuGoPlatform` - Physical hardware specification

**Infrastructure Models (separate concern):**
- `BenchBench` - Physical bench infrastructure (see `mokuconfig_and_benchbench_framework`)
- `PhysicalWiring` - Cable connections with validation
- `PDU`, `DUT` - Lab infrastructure

## Common Workflows

### Workflow 1: Quick Single-Bitstream Deploy
```bash
# One command, auto-generated config
uv run python tools/moku_go.py deploy \
    --device MokuB106 \
    --bitstream modules/EMFI-Seq/latest/*.tar
```

### Workflow 2: Multi-Instrument Complex Deploy
```bash
# Step 1: Create config file (configs/emfi_dual_scope.json)
# Step 2: Deploy using config
uv run python tools/moku_go.py deploy \
    --device MokuB106 \
    --config configs/emfi_dual_scope.json
```

### Workflow 3: Test Campaign with Reproducibility
```bash
# Step 1: Generate configs programmatically
python scripts/generate_test_configs.py --campaign emfi-v2

# Step 2: Run test suite with versioned configs
for config in configs/emfi-v2/*.json; do
    uv run python tools/moku_go.py deploy --device MokuB106 --config $config
    pytest tests/test_emfi_campaign.py
done

# Step 3: Commit configs to git
git add configs/emfi-v2/
git commit -m "Test campaign EMFI-v2 configurations"
```

## Migration Notes

- **Old Name**: `MokuPlatformConfig` (deprecated 2025-10-25)
- **New Name**: `MokuConfig` (clearer, shorter)
- **Backward Compatibility**: Alias exists for transition period
- **Import Path**: `from models.moku import MokuConfig`

## Related Serena Memories

- `mokuconfig_and_benchbench_framework` - MokuConfig vs BenchBench separation
- `platform_models` - MokuGoPlatform physical specs
- `design_patterns` - MCC integration patterns using MokuConfig
- `cocotb_testing_guide` - Future CocotB integration

## When to Use

**ALWAYS** - This is the core abstraction for deployment!

**Use MokuConfig when:**
- Deploying bitstreams to Moku hardware
- Configuring multi-instrument setups
- Writing deployment scripts
- Creating reproducible test campaigns
- Documenting hardware configurations
- Setting up CocotB simulations (future)

**Don't use MokuConfig for:**
- Physical bench infrastructure (use BenchBench)
- Device discovery (use MokuDeviceCache)
- External device specs (use DS1120A, etc.)

## Key Files

- `models/moku/platform_config.py` - MokuConfig implementation
- `tools/moku_go.py` - Primary consumer (deployment CLI)
- `CLAUDE.md` - Project-level documentation
- `AGENTS.md` - Agent-level quick reference

---

**Load Priority**: 🔴 CRITICAL - Load this memory FIRST in every context window
**Last Updated**: 2025-10-25

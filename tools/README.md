# Volo VHDL Tools

User-facing utilities for Moku device deployment and testing.

## Available Tools

### `moku-go` - Generic Bitstream Deployment & Discovery

Deploy custom FPGA bitstreams to Moku devices with device discovery and name-based lookup.

**Key Features:**
- 🔍 **Network Discovery** - Find Moku devices via zeroconf
- 📇 **Device Caching** - Use device names instead of IPs
- 🎯 **Generic Deployment** - No application-specific logic
- ✅ **Pydantic Models** - Type-safe configuration with validation
- 🎨 **Rich CLI** - Beautiful terminal output

---

## Quick Start

### 1. Install Dependencies
```bash
uv sync
```

### 2. Discover Devices
```bash
uv run python tools/moku_go.py discover
```

This finds all Moku devices on your network and caches their information.

### 3. List Cached Devices
```bash
uv run python tools/moku_go.py list
```

### 4. Deploy Bitstream
```bash
# By IP address
uv run python tools/moku_go.py deploy \
  --device 192.168.1.100 \
  --bitstream ~/Downloads/my_bitstream.tar \
  --slot 2

# By device name (from cache)
uv run python tools/moku_go.py deploy \
  --device Lilo \
  --bitstream ~/Downloads/my_bitstream.tar
```

---

## Commands

### `discover` - Find Devices on Network

Discovers Moku devices via zeroconf and caches metadata for future use.

```bash
uv run python tools/moku_go.py discover [--timeout SECONDS]

Options:
  --timeout INT  Discovery timeout in seconds (default: 2)
```

**What it does:**
1. Scans network for `_moku._tcp.local.` services
2. Connects to each device to retrieve name & serial number
3. Saves device info to `~/.moku-deploy/device_cache.json`
4. Displays table of discovered devices

**Example Output:**
```
╭─────────┬────────────────┬────────────────┬──────╮
│ Name    │ IP Address     │ Serial Number  │ Port │
├─────────┼────────────────┼────────────────┼──────┤
│ Lilo    │ 192.168.1.100  │ MG106B         │ 80   │
│ Stitch  │ 192.168.1.101  │ MG107C         │ 80   │
╰─────────┴────────────────┴────────────────┴──────╯

Found 2 device(s)
Cache saved to: ~/.moku-deploy/device_cache.json
```

---

### `list` - Show Cached Devices

Lists all cached devices from previous discovery runs.

```bash
uv run python tools/moku_go.py list
```

**Example Output:**
```
╭─────────┬────────────────┬────────────────┬───────────╮
│ Name    │ IP Address     │ Serial Number  │ Last Seen │
├─────────┼────────────────┼────────────────┼───────────┤
│ Lilo    │ 192.168.1.100  │ MG106B         │ 5m ago    │
│ Stitch  │ 192.168.1.101  │ MG107C         │ 1h ago    │
╰─────────┴────────────────┴────────────────┴───────────╯
```

---

### `deploy` - Deploy Bitstream to Device

Deploys custom FPGA bitstreams to Moku devices with optional routing configuration.

```bash
uv run python tools/moku_go.py deploy [OPTIONS]

Required (one of):
  --device, -d TEXT      Device IP address or name (required)
  --bitstream, -b FILE   Path to bitstream .tar file
  --config, -c FILE      Path to deployment config JSON

Optional:
  --slot, -s INT         Slot number (1-4, default: 2)
  --force, -f            Force connection if device in use
```

#### Deployment Modes

**Mode 1: Quick Deployment (CLI arguments)**
```bash
uv run python tools/moku_go.py deploy \
  --device 192.168.1.100 \
  --bitstream bitstreams/simple_counter.tar \
  --slot 2
```

Creates minimal config with default routing:
- Bitstream → specified slot
- Slot outputs → physical outputs (Output1, Output2)

**Mode 2: Advanced Deployment (JSON config)**
```bash
uv run python tools/moku_go.py deploy \
  --device Lilo \
  --config configs/my_deployment.json
```

Uses Pydantic models for full control over:
- Multiple slot configurations
- Custom routing connections
- Control register values
- Metadata

---

## Configuration Files

Deployment configurations use **Pydantic models** from `models/moku/` and are saved as JSON.

### Example: Simple Deployment Config

```json
{
  "platform": {
    "name": "Moku:Go",
    "ip_address": "192.168.1.100",
    "slots": 2,
    "clock_mhz": 125
  },
  "slots": {
    "2": {
      "instrument": "CloudCompile",
      "bitstream": "/path/to/bitstream.tar",
      "control_registers": {
        "0": 3758096384
      }
    }
  },
  "routing": [
    {"source": "Slot2OutA", "destination": "Output1"},
    {"source": "Slot2OutB", "destination": "Output2"}
  ],
  "metadata": {
    "description": "Simple counter deployment",
    "deployed_at": "2025-10-24T23:30:00"
  }
}
```

### Pydantic Models Used

All configuration uses validated Pydantic models:
- **`MokuPlatformConfig`** - Complete deployment specification
- **`SlotConfig`** - Per-slot instrument configuration
- **`MokuConnection`** - Signal routing connections
- **`MokuDeviceInfo`** - Discovered device metadata

See `models/moku/` for model definitions and validation rules.

---

## Directory Structure

```
tools/
├── moku_go.py              # Main CLI tool
├── README.md               # This file
└── configs/                # Example deployment configs
    ├── default_slot1.json  # Generic: Bitstream in slot 1
    └── default_slot2.json  # Generic: Bitstream in slot 2
```

---

## Device Cache

Device information is cached in `~/.moku-deploy/device_cache.json` using the `MokuDeviceCache` Pydantic model.

**Cache Structure:**
```json
{
  "192.168.1.100": {
    "ip": "192.168.1.100",
    "port": 80,
    "canonical_name": "Lilo",
    "serial_number": "MG106B",
    "zeroconf_name": "Moku-MG106B._moku._tcp.local.",
    "last_seen": "2025-10-24T23:30:00"
  }
}
```

**Benefits:**
- Use device names instead of IPs
- Faster connection (no discovery each time)
- Offline device lookup

**Refresh cache:**
```bash
uv run python tools/moku_go.py discover
```

---

## Examples

### Example 1: First Time Setup
```bash
# Discover devices on network
uv run python tools/moku_go.py discover

# List discovered devices
uv run python tools/moku_go.py list

# Deploy using device name
uv run python tools/moku_go.py deploy \
  --device Lilo \
  --bitstream ~/Downloads/my_design.tar
```

### Example 2: Quick Deployment (No Discovery)
```bash
# Deploy directly using IP
uv run python tools/moku_go.py deploy \
  --device 192.168.13.159 \
  --bitstream ~/Downloads/25ff4c4_mokugo_4.0.3_2_bitstreams.tar \
  --slot 2 \
  --force
```

### Example 3: Advanced Configuration
```bash
# Create deployment config with custom routing
cat > my_deployment.json << 'EOF'
{
  "platform": {"name": "Moku:Go", "slots": 2},
  "slots": {
    "1": {"instrument": "CloudCompile", "bitstream": "design1.tar"},
    "2": {"instrument": "CloudCompile", "bitstream": "design2.tar"}
  },
  "routing": [
    {"source": "Input1", "destination": "Slot1InA"},
    {"source": "Slot1OutA", "destination": "Slot2InA"},
    {"source": "Slot2OutA", "destination": "Output1"}
  ]
}
EOF

# Deploy with config
uv run python tools/moku_go.py deploy \
  --device Lilo \
  --config my_deployment.json
```

---

## Troubleshooting

### Device Not Found
```
Device 'Lilo' not found. Run 'discover' first or use IP address.
```

**Solution:** Run discovery to update cache:
```bash
uv run python tools/moku_go.py discover
```

### Connection Failed
```
✗ Deployment failed: Device is busy
```

**Solution:** Force connection:
```bash
uv run python tools/moku_go.py deploy --device 192.168.1.100 --bitstream file.tar --force
```

### Bitstream Not Found
```
Bitstream not found: /path/to/bitstream.tar
```

**Solution:** Verify bitstream path exists:
```bash
ls ~/Downloads/*.tar
```

---

## Integration with Moku-Go CLI

This tool **replaces** the standalone Moku-Go CLI with a generic version that:
- ✅ Keeps device discovery (zeroconf)
- ✅ Keeps device caching
- ✅ Keeps name-based lookup
- ✅ Uses existing Pydantic models (`MokuPlatformConfig`)
- ❌ Removes EMFI-Seq specific logic
- ❌ Removes Oscilloscope special-casing

The original Moku-Go CLI is preserved in `Moku-Go/` for reference.

---

## Development

### Adding New Features

The tool uses existing Pydantic models from `models/moku/`:

```python
from models.moku import (
    MokuPlatformConfig,
    SlotConfig,
    MokuConnection,
    MokuDeviceInfo,
)

# All configuration is type-safe and validated!
config = MokuPlatformConfig(
    platform=MOKU_GO_PLATFORM,
    slots={1: SlotConfig(instrument='CloudCompile', bitstream='file.tar')},
    routing=[MokuConnection(source='Slot1OutA', destination='Output1')]
)
```

### Testing

```bash
# Test help
uv run python tools/moku_go.py --help

# Test discovery (safe, read-only)
uv run python tools/moku_go.py discover

# Test list (offline)
uv run python tools/moku_go.py list

# Test deployment (requires hardware)
uv run python tools/moku_go.py deploy \
  --device 192.168.1.100 \
  --bitstream test.tar \
  --force
```

---

## References

- **Pydantic Models**: `models/moku/` - Type-safe configuration
- **Moku API Docs**: https://apis.liquidinstruments.com/
- **Original Moku-Go CLI**: `Moku-Go/` directory
- **Device Cache**: `~/.moku-deploy/device_cache.json`

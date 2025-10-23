# Moku Instrument: Logic Analyzer

## Purpose
Digital signal capture and analysis. Records multi-channel digital waveforms with triggering. Useful for **debugging custom module digital outputs**, protocol analysis, or timing verification.

---

## Key Python API

### Initialization (Multi-Instrument Mode)
```python
from moku.instruments import MultiInstrument, LogicAnalyzer

m = MultiInstrument('192.168.1.100', platform_id=2)
la = m.set_instrument(1, LogicAnalyzer)
```

### Configuration Methods

**Set Sample Rate**:
```python
la.set_samplerate(rate)
# Example: la.set_samplerate(125e6)  # 125 MSa/s (max for Moku:Go)
```

**Set Trigger**:
```python
la.set_trigger(source, edge, channel_mask)
# Example: la.set_trigger(source="DIO", edge="Rising", channel_mask=0x0001)
# Triggers on DIO channel 0 rising edge
```

### Data Acquisition

**Get Logic Data**:
```python
data = la.get_data()
# Returns dict with digital channel data (0/1 values)
# data['ch0'], data['ch1'], ..., data['ch15'] for 16 channels
```

---

## Routing Patterns

### Pattern: Monitor Custom Module Digital Outputs
**Note**: Logic Analyzer connects to **DIO pins**, not virtual CustomWrapper outputs.

```python
la = m.set_instrument(1, LogicAnalyzer)

# DIO pins must be routed to custom module or external signals
# (DIO routing is platform-specific, not via CustomWrapper)

la.set_samplerate(125e6)
la.set_trigger(source="DIO", edge="Rising", channel_mask=0x01)
data = la.get_data()

# Analyze digital timing
print("Channel 0:", data['ch0'])
print("Channel 1:", data['ch1'])
```

---

## References
- **Examples**: `mcc_py_api_examples/logic_analyzer_*.py`

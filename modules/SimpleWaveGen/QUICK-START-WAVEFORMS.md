# 🚀 SimpleWaveGen Waveform Quick Start

## **Generate Waveforms in 3 Steps**

### **Step 1: Run the Simple Script**
```bash
cd modules/SimpleWaveGen
./generate_waveforms_simple.sh
```

### **Step 2: View with GTKWave**
```bash
# View square wave generation
gtkwave SimpleWaveGen_core_square.vcd

# View triangle wave generation  
gtkwave SimpleWaveGen_core_triangle.vcd

# View sine wave generation
gtkwave SimpleWaveGen_core_sine.vcd

# View top-level integration
gtkwave SimpleWaveGen_top_integration.vcd
```

### **Step 3: Use GTKWave Configuration (Optional)**
```bash
# Use pre-configured signal groups and highlighting
gtkwave SimpleWaveGen.gtkw SimpleWaveGen_core_square.vcd
```

## **What You'll See**

- **Square Wave**: Toggles between high/low values
- **Triangle Wave**: Linear ramping up and down  
- **Sine Wave**: Smooth sinusoidal variation
- **Clock & Control**: System timing and enable signals
- **Status & Faults**: Module health and error indicators

## **Troubleshooting**

- **Script fails**: Make sure you're in `modules/SimpleWaveGen/` directory
- **GTKWave not found**: Install with `brew install gtkwave` (macOS)
- **VCD files empty**: Check that simulation completed successfully

## **Advanced Usage**

- **Custom timing**: Modify `--stop-time=1000ns` in the script
- **Signal focus**: Use GTKWave's signal browser to focus on specific signals
- **Save views**: Save your GTKWave configuration for future use

---
*For detailed documentation, see `README-Waveforms.md`*

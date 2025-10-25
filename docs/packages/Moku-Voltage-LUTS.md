# Moku-Voltage-LUTS

The **Moku Cloud Compile (MCC)** platform and **Moku:Go** hardware use **signed 16-bit integers** to represent analog voltages at their DAC/ADC interfaces. This is a common convention in FPGA-based instrumentation:

- **Digital range**: -32768 … +32767 (0x8000 … 0x7FFF)
    
- **Voltage range**: -5.0 V … +5.0 V (full-scale analog input/output)
    

This means every digital step corresponds to roughly **305 µV** (10 V / 65536).

| **Voltage (V)** | **Digital (dec)** | **Digital (hex)** |
| --------------- | ----------------- | ----------------- |
| 0.0             | 0                 | 0x0000            |
| +1.0            | +6554             | 0x199A            |
| +2.4            | +15729            | 0x3DCF            |
| +2.5            | +16384            | 0x4000            |
| +3.0            | +19661            | 0x4CCD            |
| +3.3            | +21627            | 0x54EB            |
| +5.0            | +32767            | 0x7FFF            |


| **Voltage (V)** | **Digital (dec)** | **Digital (hex)** |
| --------------- | ----------------- | ----------------- |
| −5.0            | −32768            | 0x8000            |
| −3.3            | −21627            | 0xAA85            |
| −3.0            | −19661            | 0xB333            |
| −2.5            | −16384            | 0xC000            |
| −2.4            | −15729            | 0xC231            |
| −1.0            | −6554             | 0xE666            |


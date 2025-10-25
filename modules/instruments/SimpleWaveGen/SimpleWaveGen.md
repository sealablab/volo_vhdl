# SimpleWaveGen

This document describes the SimpleWaveGen module

## Dependences
* `clk_divider`
* `Moku_Voltage_pkg`

## Requirements
The **SimpleWaveGen** is an example module. It should be capable of producing three distinct output waves. These include
- Square wave
- Triangle wave
- Sine wave


## SimpleWaveGen: Inputs


### Control-inputs 
The default inputs (reset, enable, clk, clk_en)


### Configuration inputs
* A 2-bit wave_select field


## SimpleWaveGen: Outputs
* Square_Out (16-bit signed)
* Triangle_Out (16-bit signed)
* Sine_Out (16-bit signed)


## Reset behavior:
Simple syncronous reset. 


## Clock behavior:
**SimpleWaveGen** should utilize the 'clk' and 'clk_en' inputs to allow its input clock to be easily dividied



# Testbenches
Create a __minimal__ testbench for the module. Unlike other testbenches, the goal of this one is simply to validate that the three Wave outputs are non-zero over a small amount of time. 


## Follow up questions
- Amplitude Configruation Register ?
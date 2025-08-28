
# probe_driver_top_regs
This file describes how the ControlRegisters in CustomWrapper should be interpreteted


## CR0-Top
Defines bits in the top level Control0 register
### Bit-31: global nEnable:
- toggling this will disable all the vhdl submodules that have an 'enable' signal

## Bit-23: soft_trig_in
* toggling this bit will be treated as if the top level `trig_in` signal was high. Sets itself back to zero after probe_driver_core enters the `IDLE` state
## Bits 22-16: 7-bit index into intensity lut
All other bits currently reserved

## Bits 15-8: 8

## CR1-Top
Defines bits in the Toip level Control1 register
### Bits 31-16: 16-bit unsigned duration


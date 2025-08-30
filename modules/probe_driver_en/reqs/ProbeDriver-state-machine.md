# ProbDriver-state-machine
This file describe sthe
``` python
RESET -> IDLE: (on enabled) -> ARMED: (on trig_in) -> FIRING -> COOL_DOWN
```

# States
* Reset
* IDLE
* ARMED
* FIRING
* COOL_DOWN
* HARD_FAULT

## `Reset
`Reset` may technically be omitted from the state machine definition assuming the Reset handlers are simple enough.

## `IDLE`:
the `IDLE` state is entered once all  inputs are validated and enable is high.

## `ARMED`
`ARMED` state is entered after 'IDLE'. (only when module is enabled)

## `FIRING`
`FIRING` state is entered from armed when `trig_in` is high.

The `FIRING` state shall:
- set `Intensity_Out` to the provided IntensityLut[`Intensity_index`]\
- set `Trigger_Out` to the constant `0x5421`  

## `COOL_DOWN
`COOL_DOWN` state is entered from armed after `Duration` clock cycles have elapsed. 

## `HARD_FAULT`
The ProbeDriver shall enter the `HARD_FAULT` state 
- when any user provided lookup table cannot be validated
- any other validation errors



The [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-status-reg|ProbeDriver-status-reg]] shall be updated as the state machine passes through these states

# See Also
## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-status-reg|ProbeDriver-status-reg]]
## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-requirements|ProbeDriver-requirements]]

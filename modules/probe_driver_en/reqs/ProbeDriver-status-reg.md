---
created: 2025-08-26
modified: 2025-08-26
---


# ProeDriver-status-reg
The ProbeDriver Status register type shall includes the following bits

## BIT0: `armed`
the `Armed` bit shall remain high whenever the ProbeDriver is enabled


## BIT1: `firing`
the `Firing` bit shall remain high whenever the ProbeDriver is in the `Firing` state

## BIT2: `fired`
the `Fired` bit will __go high__ when entering the `Firing` state, and it will __remain high__ until reset (aka 'sticky')


## BIT3: `cool`
the `Cooldown` bit will __go high__ whenever the ProbeDriver is in the cooldown state.


## BIT4: `alarm`
the `Alarm` bit will be set whenever the ProbeDriver has to clamp or otherwise override any provided inputs. 
## Bit5: fault
the `Fault` bit indicates that the ProbeDriver was initialized with an invalid LUT or 
# See Also
## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-requirements|ProbeDriver-requirements]]

## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-state-machine|ProbeDriver-state-machine]]

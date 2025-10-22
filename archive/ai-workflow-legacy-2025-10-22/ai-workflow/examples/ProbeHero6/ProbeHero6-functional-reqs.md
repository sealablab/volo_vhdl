# ProbeHero6
**ProbeHero6** is a VHDL module designed to drive various SCA and FI probes.
Conceptually ProbeHero6 is similar to a simple signal generator. 
This document describes the __functional__ requirements.

Before reviewing it be sure to review the
PREV: [[volo_vhdl/volo_codes_workflow/ProbeHero6/ProbeHero6-functional-reqs|ProbeHero6-functional-reqs]]


## ProbeHero6 functionality
the core functionality of ProbeHero6 should be implemented as a __state machine__. When generating it be sure to double check the current projects __README-STATE-MACHINES__ rules for proper gneration.


## Reset and parameter validation
During reset all input configuration values should be validated according to their specifications.  If necessary, a seperate state 'PARAM_VALIDATION' may be addedd (although)


## Timing requirements
When the module is in the 'ARMED' state and `trig_in` goes high:
__no more than **one**__ clock cycle shall elapse before the module outputs are set appropriately.



## Theory of operation
The probedriver should start out int.. yaddda yadda



# See Also
[[volo_vhdl/volo_codes_workflow/ProbeHero6/ProbeHero6-Interface-reqs|ProbeHero6-Interface-reqs]]





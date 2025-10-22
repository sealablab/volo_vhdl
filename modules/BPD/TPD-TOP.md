# TPD-TOP


**Trivial Probe Driver** (aka `timed probe driver`)

The goal of __Trivial Probe Driver__ is to serve as a temporary on-ramp until the moku `get_control_register` API is officially implemented.

AAFAAA

## Next: [[volo_vhdl/modules/BPD/BPD-prompts/BPD-Getting-started-from-ProbeHero|BPD-Getting-started-from-ProbeHero]]


## TPD Overview

**TPD** is derived from **BPD** with the main caveat that it is 
a) smaller in scope
b) intentionally paired down so that it can be used to 'bind-fire' a Riscure-probe. 

This is possible by setting apporopriate probe feedback threshold limit so that we can deduce that either
a) the probe fired (we can observe it from the Probe current monitor) -or-
b) the timeout_timer has expired without any observable delta.


Again. the primary motivator for this model is to __work__ around the lack of a moku read control register api.

x

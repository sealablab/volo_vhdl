# 🚀 **TODO: Phase 0S** `StateMachines`


## 🚀 **Starting Points for StateMachines:**

I think it would be wise to include a minimal set of states as well as a (very) minimal state machine in the base vhdl module workflow. The base state-machine should probably include:

- RESET -- although this is not actually required in many current modules
- READY -- post reset, all input parameteres verified. By default we then will transition to:
- IDLE -- CUSTOM module code generally begins here

I think we should also include a 
- HARD_FAULT -- modules should enter this when input parameters fail to validate, as well as any other safety critical failures.
- Once a module enters `HARD_FAULT` it should the 'FAULT' bit in the module status register. By convention this is the topmost bit. The module shall not leave `HARD_FAULT` via any mechanism short of the `reset` control signal resetting the module.
-
### Datadefs minimal properties
a proper datad defintion should __clearly__ define:
	- datastructure widths, valid ranges, 
	as well as vhdl functions that implement and identify these bounds.
 p
### @DEX: Can you analyze the current set of 'datadefintions' and come up with more properties ?

4. Test with ProbeHero7**
- Use the refined requirements we created today
- Generate complete VHDL implementation
- Validate against VOLO coding standards
---


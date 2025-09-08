# 🚀 **TODO: Phase 0S** `StateMachines`


## 🚀 **Starting Points for StateMachines:**

I think it would be wise to include a minimal set of states as well as a (very) minimal state machine in the base vhdl module workflow. The base state-machine should probably include:

- RESET -- although this is not actually required in many current modules
- READY -- post reset, all input parameteres verified. By default we then will transition to:
- IDLE -- CUSTOM module code generally begins here

I think we should also include a 
- HARD_FAULT -- modules should enter this when input parameters fail to validate, as well as any other safety critical failures.
- Once a module enters `HARD_FAULT` it should the 'FAULT' bit in the module status register. By convention this is the topmost bit. The module shall not leave `HARD_FAULT` via any mechanism short of the `reset` control signal resetting the module.

I am hesitant to proscribe the exact names etc of these states myself. Is there an obvious industry convention? 


Also: What do you think about 'encoding' the resulting template state transition diagram as a **mermaidjs** diagram? It seems somewhat experimental, but computers and humans both seem to speak it pretty well. 😅

If you think we can resolve this in a single context window, give me a sign by creating a new feature branch

----
While Dex cooks on that lets think of our next move..

we now have a base state machine - 
should we update the AGENTS.md and rules.mdc __now__.. or should we perhaps clearly define the (default) reset mechanism and input parameter verification approach? 

Once we have the state machine base commited and a reset testing / testbench handling convention sorted it may make more sense to 'merge' them both at once. 
(conceptually anyway). 


# VOLO-DS1120-Refinement-Qs

I've analyzed the VOLO-DS1120-PD requirements document. This is an interesting application - a VOLO
  wrapper for controlling a Riscure DS1120A EMFI (Electromagnetic Fault Injection) probe. Let me
  provide feedback on potential issues and areas needing refinement:

  🔴 Critical Issues to Address

  1. Register Type Mismatch

## 1) register type mismatch
Good catch! I actually did that on purpose to see if you would catch it.

For now I think we should use two 8-bit counters. In the future we will enhance the VOLO-APP type system. 

  ## 2) Incomplete Sections
Disgregard. My mistake. 


  ## 3) Module Dependencies

  The document references modules not in the standard VOLO infrastructure:
  - volo_voltage_pkg.vhd
  - volo_voltage_threshold_trigger_core.vhd
  - fsm_observer.vhd
  - fsm_example_core.vhd

All of those files can in fact be found if you perform a recursive search under @modules. User serena to find them. 

  🟡 Design Clarifications Needed

  ## 4) I/O Signal Mapping
Good catch! Thse should all be 16-signed values. My mistake.


  - InputA→TriggerInput, 
  - InputB→MonitorInput, 
  - OutputA→TriggerOut, 
  - OutputB→IntensityOut?

## 5). Voltage Representation

The volo_voltage_pkg defines this

  # 6)  FSM Observer Integration

  You mention using fsm_observer.vhd to drive outputs.

  Question: Is the intent to:
  - Have one main FSM + three observer instances?
  - Or have the FSM directly control outputs + observers for debugging?

My original idea was to have one main FSM and three observers. It seems like an elegant re-usable approach.

  🟢 Suggested Refinements

## 7. Register Allocation

  Given VOLO's CR20-CR30 limit (11 registers max) and 32-bit width, consider:
I like your suggestions.  As far as the splitting 16-bit values into two parts, I am comfortable guiding that detail by hand during the code generation phase. 

## 8. Safety Enhancements

  Add to requirements:
  - Watchdog timer for overall operation
  - Maximum fire count per session
  - Minimum time between successive armings
  - Status bits for fault conditions

- Watchdog timer is a great idea
- maximum fire count is also a great idea 

I _dont_ think we neeed a minimum time between successive armings - the 'cooldown' state is responsible for ensuring that. 

  ## 9 . BRAM Buffer Future Use
These are all great ideas and likely will be used in future iterations. I think we should simply state that at this point the BRAM buffer will be unused for simplicity

# 10: clk-divider
I forgot to add the `volo-clk-divider` module as a required depedency. 
We should instantiate a clk-divider in our volo-app-main (I'm thinking with a 4-bit divider) that is used to drive the state machine (and thus, everything) else. 

This will necessitate another 8-bit 'counter' register type that we will mask down to four internally. 



## 11 Spurious Trigger Handling: 
Count spurious triggers in an internal register, but use it to craft that status bits. 

  
Claude,

I would like you to help me design a new first-class abstraction for our entire project. I call it the 'volo-app'

## Volo-app
A 'Volo-app' is our projects take on a Liquid Instruments 'Instrument'. A volo-app consists of:
- A bitsream that implements the Moku CustomWrapper interface 
- A 4KB binary buffer that will be loaded into BRAM
It also will contain a human-friendly abstracted set of 'Application' level registers. These registers will be implemented on top of the MCC CustomWrapper ControlRegisters. 

The application level control registers will have human friendly descriptions and a very limited type system (initially just unsigned counters as well as 'percent' that will be mapped onto the volo_percent_pkg)


I would like you to help me:
- refine the abstraction a little (dont go overboard!)
- create a pydantic model

__eventually__ we may use the Volo-app abstraction to automatically generate a simple GUI for the user that will reach out and utilzie the moku set_regs() API to load in new values. That is worth keeping in mind but not what we are going to implement first.

The 'Volo-Apps' will:
- be loaded by the current **completely standard** 1st party moku library as a bitstream.
- Our apps are designed to __WAIT__ until a handful of bits in CR0 get toggled - this will be handled by a utility script that we will call **volo_loader** 
- These apps will then read in 4KB of data over a streaming protocol that leverages the set_regs api to fill up a BRAM buffer
- Once that is complete __then__ the 'volo-app' proceeds to run. 

**DONT** 
- get caught up on the details of the network loading protocol - I will fill in the blanks later
- get caught up creating elaborate new datatypes for the applications.
## DO
- help me pin-down the abstraction in a manner that maintains __clear seperation of responsibilities__ 
- Remember - a **volo-app** __is__ a valid MCC bitstream and can be loaded as such __but__
- not all MCC bitstreams are **volo-apps**

Ask follow up questions - once you have all the information I want you to:
- craft an implementation plan and an associated system prompt so that we can begin addding this in a fresh context (unless you think you have enough room still)

## Volo-app workflow  (**volo_load**)

## S1) the bitstream is loaded
From the perspective of a user, a bitstream for a volo-app will appeared 'stuck' when loaded with first party tools. This is to be expected. 

## S2) volo_load
**volo_load** will then take over the moku session, twiddle the correct bits to enable the volo_app, proceed to load the 4KB buffer over the network, and then it will pass control off to the 'volo_app_main' VHDL module. 


Ask follow up questions, then write out an implementation plan for us


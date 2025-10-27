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




----


⏺ Looking at your volo-app abstraction proposal, I can see this builds nicely on top of your existing MCC infrastructure. I have some
  clarifying questions before we design the Pydantic model:

  Clarifying Questions

  1. Relationship to MokuConfig
Think of volo-app as a completely separate deployment path. We may use first party tools to load the bitstream, but we don't expect them to more than get the bitstream loaded. 

  2. BRAM Loader Protocol Details

  You mentioned not getting caught up in details, but I need minimum info for the model:
  - Which Control Registers does the loader use for streaming? (e.g., CR1-CR3 for data staging?)

There is a 4KB bram buffer available, and the loader uses CR10-CR14 for transmission. 
(We have done the work already, but I dont want you to get cauht up on the details).


  ##  What happens to CR0[31:29] during loading? (Your MCC_READY convention uses these bits)
Great question!! 
The volo_apps **implement** the MCC_READY convention you just described. In fact, we may renamy the MCC_READY to 'VOLO_READY' etc to clarify that
- the (currently called) `MCC_READY` convention was one of or own making to allow us to make this transition. 

  3. Application Register Abstraction

  For the "human-friendly application registers":
  - How many registers can a volo-app expose? (e.g., 4 app registers = CR4-CR7?)
  For now assume they will be mapped in to CR20-CR30 (or at least that is the maximum amount available). We may update this in the future, but its good to have design constratins. 
  
  - Register types needed:
    - Unsigned counter (bit width? 8/16/32?): 8-bit counters
    - Percent (0-100%? Or 0.0-1.0 mapped to volo_percent_pkg?): **volo_percent_pkg** (7-bits, but 0-100 indexes)
    - boolean bits - which i think we will actually calll 'buttons' as they primarily will be used to represent an abstract push-button via mcc set_regs

  4. BRAM Buffer Specification
a) 4096 bytes, but again. Don't worry about what goes in., Thats not your problem!

  5. VHDL Module Naming Convention

  You mentioned "volo_app_main" - is this:
  - A mandatory entity name that all volo-apps must implement?
  - Or just conceptual (the core logic after loading completes)?
  it is just what my brain came up with - help me refine the concept

  6. Packaging and Deployment

  Should the Pydantic model:
  - Bundle both bitstream .tar + .bin buffer file together?: YES
  - Separate concerns: VoLoApp model references them independently: elaborate?
  - Embed buffer: Store 4KB directly in JSON/YAML as base64?: NO! Just a reference to a location on disk.

  7. Validation Strategy

  Should the model validate:
  - Bitstream actually implements volo-app interface (has loader FSM)? NO!
  - Buffer is exactly 4KB?: NO (just a filepath)
  - Register definitions don't conflict with loader protocol registers: No. Interesting proposal though. Maybe in a future revision

  ---
  Context I'm working with:
  - Your existing MokuConfig uses Pydantic and targets deployment
  - You have MCC 3-bit control scheme (CR0[31:29])
  - You want minimal type system (unsigned, percent) - keeps it simple ✓

  Once you answer these, I'll design:
  1. Pydantic models for VoLoApp + AppRegister abstraction
  2. Implementation plan with file structure
  3. System prompt for fresh context execution

  What's your priority on these questions? (I can make reasonable assumptions if some are "defer for later")
--- 




  ##  VHDL Naming Convention Recommendation

Actually lets discuss how I envision this working from a synthesis perspective for a moment.

**ALL** volo-apps will have a (hopefully static!) `MCC-TOP-volo-loader` that
- implements the CustomWrapper interface and serves as the 'Top' level file from the perspective of MCC

The 'volo-app-main' module will (application specifically) but hopefully in an automated manner:
- assign the CR's available in 'MCC-TOP-volo-loader.vhd' into the friendly named registers for that application
__ we are basically trying to create a small shim__ so that applications implementing 'volo-app' will for the most part be unaware of the higher level MCC wrapper. 

Now would be a great time to nail down a required naming scheme. I want it to be
- clear
- consistent
- repeatable




  1. Directory name: I used volo_main/ - prefer volo/, app/, or something else?
  1: `volo_main` sounds good
  2. Signal naming: Yes
  3. BRAM interface: Should ALL apps get BRAM signals, or only if they use the buffer?
  We will expose them to all apps for the sake of consistency. They can simply ignore the existence of the buffer if they dont need it. 
  4. Loader FSM: `shared/volo/` sounds good or 
  5. Template location: `shared/volo/templates/ ` 👍



  Option A: Start Implementing Now

  # Create directory structure
  mkdir -p models/volo

  # Start with Task 1.1: Pydantic Models
  # See docs/VOLO_APP_IMPLEMENTATION_PLAN.md for checklist

  Option B: Review and Refine

  Take time to review the design documents and ask any clarifying questions before starting.

  Option C: Fresh Context Later

  When you're ready to implement in a fresh context, just:
  1. Read docs/VOLO_APP_FRESH_CONTEXT.md
  2. Follow Phase 1 checklist
  3. Reference docs/VOLO_APP_DESIGN.md for details


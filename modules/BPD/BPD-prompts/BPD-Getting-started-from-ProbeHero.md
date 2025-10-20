# BPD-Getting-started-from-ProbeHero

Roo, 


---
Before we get started, 

---
We have Iterated on the variations of the ProbeHero requirements many, many times now.

I would like your help taking the best parts of what we have learned and re-factoring them into a new project. The new project  is called Basic Probe Driver (or BPD) for short.

It is tempting to simply utilize the (already synthesized and functioning) VHDL files and testbenches  as a 'reference implementation' - but the goal of this task is not to provide VHDL source code. The goal of this task is to distill the requirements and lessons learned through much of the previous iterations into a set of deliverable requirements that, in theory, would allow two different teams to generate functionally equivalent VHDL/Verilog.

I would like your help creating a set of **requirements** documents that will, in theory, allow two different developer teams to create functionally equivalent modules.

Here are some basic ground rules:
- we do __not__ need to include hyper-specific rules about verilog or VHDL features. 
- we can **assume** both teams are familiar with both MCC and the entire Moku-Go platform
- What do you think of providing some sort of 'placeholder files'  that consists (mostly) of requirements as well as certain pre-described datastructures etc? Ordinarily I wouldn't particuarly care to micro-manage of impose that level of control over another teams implementation - but this is is sort of 'proof of concept' to try and provide a requirements document that **another teams** set of AI agents can build upon - so placing the requirements in a hierarchical manner that mimics the (expected) filesystem layout would make sense to me.

- is it easier to describe the requirements in a top-down or bottom up approach? 
- For the fundamental datastructures, how do we describe them? would it be inappropriate to simply include our vhdl examples (trimmed down)? I feel like what i __want__ to do as a software programmer is the equivalent of providing `C Header files` that describe simple common datastructures, while leaving the implementation up to the developer. 
- I am unimpressed with the current ghdl based unit-tests, and am considering moving to `cocotb`. **IF** we were to specify compliance tests, I would like to (try) and describe them in terms of `cocotb`. 
- 
### Response
## Questions for Clarification
1)  Requirements Structure:


2) I think layered documentation would make sense. Ideally I would actually like the requirements document to exist on disk in a manner that corresponds obviously with the __actual__ module file structure itself.

- VHDL record definitions as reference (include simplified VHDL records as "API contract")
- Yes. However, we went our API-contract record definitions to __not__ require any VHDL centric concepts that would struggle to map to verilog

3 ) Behavioral-only specs - but include with simple examples. 
Let us consider refining them into CoCoTB testbenches in a later iteration. 

1. Scope for BPD v1.0:

- a) Minimal viable (core firing behavior + basic safety only)

1. Target Audience Assumption:
The target audience are professional HDL developers who have knowledge of the MCC platform and product line. 


__Before we begin__ I have some basic status and control register interfaces. These interfaces differ slightly from previous versions of ProbeHero, but conceptually the mapping is very obvious. I will provide these before we begin.


1 Tab

Browser
## Datastructure definitions:
Included in our previous `ProbeHero module` were a handful of datastructures, specifically:

-  PercentLUT
-  ProbeConfig
-  GlobalProbeTable


### 
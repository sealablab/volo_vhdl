# VOLO-TESTING-IMPROVEMENTS

Claude, 

I recently identified two major flaws in our agenting based workflow. Both of them relate to parsing extraneous text from two different tools (ghdl and cocotb).

Details follow.

## Cocotb text outputs overwhelming
The default behavior of cocotb is to generate a __ton__ of text output. 
This makes perfect sense for humans and CI/CD toolchains, but it is __terrible__ for LLMS. 

Can we:
 construct our cocotb tests to have various output levels and by convention **start with the most basic** tests and increment forward. 

Somewhat relatedly, i think it would be good to place the tests for each module in a more organized manner.  F.ex)

`tests/__MODULE_HERE/P1_MODULE.py`
`tests/__MODULE_HERE/P2_MODULE.py`
...
We may need to create some sort of 
`tets/__MODULE_HERE/MODULE_CONSTANTS.py` to accomodate this.

## GHDL metavalue outputs
So far we have simply been ignoring ghdl metavalue issues, but this is crushing your context window. We need to either 
a) invoke ghdl in a way that complely suppresses these
b) come up with some python post-processor to feed the them through before you read them.  

Claude,
You and I just created a brand new vhdl module design and test specification, 


----
Great! Now that we have implemented the solution I want to pick up testing the most recent module, VOLO-DS1120-PD. 

There is an (old) system prompt I generated after aborting the testing phase. It is at
[[volo_vhdl/docs/VOLO-DS1120-PD-P3-TESTING|VOLO-DS1120-PD-P3-TESTING]]

<!-- I also had the P2 agent save the following suggestions: -->
[<!-- [volo_vhdl/docs/DS1120-PD-P1-Lessons_Learned|DS1120-PD-P1-Lessons_Learned]] -->



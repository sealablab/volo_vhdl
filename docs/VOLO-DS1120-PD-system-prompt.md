Prompt:
Claude,
I would like you to help me design and implement our first VOLO-APP. In this case it is the **VOLO-DS1120-PD**. 
Please review @VOLO_APP_FRESH_CONTEXT,  and then I will give you the requirements document. 


I want you to: 
1) help me refine the document (if necessary)
2) generate a system prompt I can then run in a new context.

In particular, I am curious if you think we can/should break the implementation into two parts

## P1) The 'VOLO-App' definition
- This includes generating the relevant VoloApp definitin yaml file 
- crafting the 'template' VOLO-DS1120-PD vhd files. 

## P2) VOLO-App VHDL generation
Phase two should consist of 
	- a system prompt suitable for the VHDL generation (and CocoTB testbenches)

I suspect this seperation of duties will be very effective. 

Ask followup questions.

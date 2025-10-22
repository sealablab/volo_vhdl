# TPD_02.md
`feature/TPD-02`

## Code generation tips
**syncronos reset**: always

## Test-prompt
Dex, / Codex
I want you to design a minimal VHDL module with the following control inputs inputs
- rst
- clk
- en

The module should implement a simple state machine, with the following four states
## States
### S1: 
S1 is entered after reset
## S2:
S2 is entered from S1
## S3:
S3 is entered from S3
## S4
S4 is entered from S3


## Inputs
The module should take in four 7-bit delay counters (one for each state)

## Outputs
The module should have one 7-bit output status register 
##  State/status register
When S1 is entered bit-1  in the status register should be set high
When S2 is entered bit-2 should be set high, etc.

All status bits should be sticky (do not clear them when transitioning out of a state)


## Functional requirements
Once the module has reached S4 the status register should have 4 high bits. 
These are only clearable on reset.

## Reset behavior
Implement a simple syncronous reset handler.








## What do we want to __preserve__ from TPD01 ?

- the basic EMFI state machine [[volo_vhdl/modules/TPD_02/emfi_fsm|emfi_fsm]]
- the medium wrapper [[volo_vhdl/modules/TPD_02/tpd_med|tpd_med]]

## what we want to change:
s/n_reset/Reset

## Work-on
[[volo_vhdl/modules/TPD_02/TPD_Top|TPD_Top]]
[[volo_vhdl/modules/TPD_02/Top|Top]]


## What do we want to iterate:

- clarify the register usage
- clarify the Moku/TOP level file 
- clarify the reset behavior
- 
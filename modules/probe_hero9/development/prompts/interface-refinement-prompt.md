# Interface Refinement Prompt Template

## Context
You are refining the interface requirements for ProbeHero9, a VHDL module for driving probe systems.

## Current Requirements
[Link to current requirements file: `../requirements/interface/PH9-interface-reqs-current.md`]

## Refinement Focus
- [ ] Signal naming and conventions
- [ ] Port definitions and types
- [ ] Timing requirements
- [ ] Error handling interfaces
- [ ] Status register layout

## VOLO Standards Compliance
- Use `ctrl_*` prefix for control signals
- Use `cfg_*` prefix for configuration signals  
- Use `stat_*` prefix for status signals
- Follow VHDL-2008 with Verilog portability
- Use direct instantiation for top layer

## Output Format
Create updated requirements in:
`../requirements/interface/PH9-interface-reqs-v[NEXT].md`

## Questions to Consider
1. What are the target frequency and timing requirements?
2. What are the interface requirements with other modules?
3. What are the reset requirements (synchronous vs asynchronous)?
4. Are there specific area or resource constraints?

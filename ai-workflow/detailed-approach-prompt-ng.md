# Detailed Approach Implementation Prompt (NG)

## 🎯 Mission
Implement ProbeHero8 using the **detailed approach** with the **enhanced rules system** from main-ng branch.

## 📋 Approach Philosophy
- **Comprehensiveness over speed**: Focus on thorough understanding and analysis
- **Extensive documentation**: Provide comprehensive context and rationale
- **Quality over efficiency**: Ensure maximum code quality and standards compliance
- **Risk mitigation**: Thorough analysis and planning before implementation

## 🔧 Enhanced Rules System Integration
Apply ALL relevant patterns from the enhanced rules system:

### Process & State Machine Patterns (PROC)
- **PROC-01**: Avoid unintended latches
- Use clocked processes for all storage elements

### Signal & Assignment Patterns (SIG)
- **SIG-01**: Single-writer for signals
- **SIG-02**: Named association & explicit conversions
- **SIG-03**: Signal priority & truth table

### Timing & Clock Patterns (TIM)
- **TIM-01**: Constrain critical paths
- Use pipeline registers for long combinatorial logic

### Resource & Structure Patterns (RES)
- **RES-01**: BRAM inference patterns
- Use proper array + clocked process style

### Portability & Standards Patterns (STD)
- **STD-01**: Use portable subset for Verilog
- Stick to basic types and explicit FSM encoding

### Testbench Patterns (TB)
- **TB-01**: Clock and reset processes
- **TB-02**: Deterministic stimulus
- **TB-03**: Single-writer discipline for signals
- **TB-04**: Boundary and fault injection checks
- **TB-05**: Clock & timing management
- **TB-06**: Reset & initialization testing

## 📁 Implementation Plan
Follow: `TODO-PH8-implementation-plan-DETAILED-NG.md`

## 📊 Progress Tracking
Update: `experiment-results-ng/detailed-approach/progress-log.md`

## ⏱️ Time Tracking
Update: `experiment-results-ng/detailed-approach/time-tracking.md`

## 🎯 Success Criteria
- Comprehensive ProbeHero8 implementation
- All tests pass with GHDL
- ALL enhanced rules system patterns applied where relevant
- Comprehensive documentation and analysis
- Progress and time tracking completed
- Developer experience ratings provided
- Rules system effectiveness evaluation completed

## 🚀 Ready to implement!

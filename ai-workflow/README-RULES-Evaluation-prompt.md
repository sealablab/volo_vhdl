# Enhanced Rules System Evaluation Prompt

## Context
You are evaluating candidate rules discovered during the **ProbeHero8 Implementation Plan Experiment** comparing condensed vs detailed VHDL development approaches. The experiment validated the effectiveness of the enhanced rules system and discovered 8 new candidate patterns.

## Experiment Results Summary
- **Winner**: Detailed Approach (9.25/10 vs 7.75/10)
- **Key Finding**: Enhanced rules system was highly effective (9-10/10 ratings) in both approaches
- **New Patterns**: 8 candidate rules discovered during real VHDL implementation
- **Validation**: All patterns were successfully applied in working VHDL code that compiles with GHDL

## Candidate Rules to Evaluate

### From Condensed Approach
- **PROC-02**: Function declarations in architectures
- **VS-03**: Variable name hiding in nested scopes  
- **GHDL-04**: Metavalue warnings in NUMERIC_STD operations

### From Detailed Approach
- **TIM-02**: Pipeline registers for complex calculations
- **SIG-04**: Comprehensive status reporting in top-level modules
- **TB-07**: Comprehensive test vector design
- **TB-08**: System integration testing with operational mode validation

## Evaluation Criteria
1. **Generality**: Does the pattern apply to common VHDL development scenarios?
2. **Verification**: Was the pattern successfully applied in working code?
3. **Error Prevention**: Does it prevent common VHDL/GHDL issues?
4. **Clarity**: Is the Problem/Cause/Solution format clear and actionable?
5. **Integration**: Does it fit well with existing rules system structure?

## Key Context for Evaluation

### Rules System Structure
- **Location**: `ng/README-synth-vhdl-tips-ng.md` and `ng/README-ghdl-testbench-tips-ng.md`
- **Format**: Problem/Cause/Solution/Pattern/Tags structure
- **Categories**: PROC, SIG, TIM, RES, STD, TB, VS, GHDL
- **Status**: All candidates are marked as `#candidate #unreviewed`

### Implementation Evidence
- **Working Code**: All patterns were applied in `modules/probe_hero8/` implementations
- **Compilation**: All code compiles successfully with `ghdl --std=08`
- **Test Coverage**: Patterns validated through comprehensive testbenches
- **Real Issues**: Patterns solved actual problems encountered during development

### Enhanced Rules System Effectiveness
- **SIG-02** (Named Association): Highly effective in both approaches
- **SIG-03** (Signal Priority): Excellent guidance for control signal hierarchy
- **TB-05** (Clock Management): Critical for proper testbench timing
- **TB-06** (Reset Testing): Essential for robust initialization testing

## Files to Reference
- `ng/README-synth-vhdl-tips-ng.md` - Current rules with new candidates
- `ng/README-ghdl-testbench-tips-ng.md` - Testbench rules with new candidates
- `modules/probe_hero8/` - Implementation evidence
- `EXPERIMENT_CONVERSATION_SUMMARY.md` - Complete experiment context
- `experiment-results-ng/MANUAL_COMPARISON_RESULTS.md` - Detailed analysis

## Your Task
1. **Review each candidate rule** against the evaluation criteria
2. **Promote qualified candidates** to the main rules system
3. **Refine patterns** if needed for clarity or completeness
4. **Update Quick Index** with new rule entries
5. **Maintain consistency** with existing rules system structure

## Expected Output
- Updated rules files with promoted candidates
- Updated Quick Index entries
- Brief rationale for promotion/rejection decisions
- Any refinements made to pattern descriptions

## Success Criteria
- All high-quality candidates are integrated into the main rules system
- Quick Index is updated with new entries
- Rules maintain the established Problem/Cause/Solution/Pattern format
- Integration preserves the machine-friendly structure for AI agents

---
*This evaluation is based on real VHDL development experience with GHDL compilation validation.*
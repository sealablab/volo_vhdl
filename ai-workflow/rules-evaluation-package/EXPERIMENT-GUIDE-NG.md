# ProbeHero8 Implementation Plan Experiment Guide (NG)

## 🎯 Overview

This guide provides instructions for running the ProbeHero8 Implementation Plan Experiment using the enhanced rules system from the `main-ng` branch.

## 🚀 Quick Start

### Option 1: Full Automated Experiment
```bash
./run-full-experiment-ng.sh
```
This runs the entire experiment with guided prompts for each phase.

### Option 2: Step-by-Step Manual Execution
```bash
# 1. Setup experiment infrastructure
./setup-ng-experiment.sh

# 2. Run condensed approach
./start-condensed-ng.sh

# 3. Run detailed approach  
./start-detailed-ng.sh

# 4. Compare results
./compare-results-ng.sh
```

## 📋 What Each Script Does

### `setup-ng-experiment.sh`
- Creates experiment results directory structure
- Sets up progress tracking files for both approaches
- Creates implementation plans with enhanced rules system integration
- Prepares comparison framework

### `start-condensed-ng.sh`
- Creates feature branch for condensed approach
- Sets up condensed approach tracking
- Creates implementation prompt with enhanced rules system
- Focuses on speed and efficiency

### `start-detailed-ng.sh`
- Creates feature branch for detailed approach
- Sets up detailed approach tracking
- Creates implementation prompt with comprehensive rules system
- Focuses on thoroughness and quality

### `compare-results-ng.sh`
- Analyzes progress logs and time tracking
- Calculates weighted scores based on evaluation criteria
- Generates comprehensive comparison report
- Provides recommendations for future projects

## 🔧 Enhanced Rules System Integration

The experiment evaluates the effectiveness of these enhanced rules system patterns:

### Signal & Assignment Patterns (SIG)
- **SIG-02**: Named association & explicit conversions
- **SIG-03**: Signal priority & truth table

### Testbench Patterns (TB)
- **TB-05**: Clock & timing management
- **TB-06**: Reset & initialization testing

### Additional Patterns (Applied in Detailed Approach)
- **PROC-01**: Avoid unintended latches
- **SIG-01**: Single-writer for signals
- **TIM-01**: Constrain critical paths
- **RES-01**: BRAM inference patterns
- **STD-01**: Use portable subset for Verilog
- **TB-01 through TB-04**: Additional testbench patterns

## 📊 Evaluation Criteria

### Primary Metrics (Weighted)
- **Development Speed (30%)**: Total time from start to completion
- **Code Quality (40%)**: Functional correctness, standards compliance, test coverage
- **Developer Experience (20%)**: Clarity, usability, efficiency, satisfaction
- **Implementation Accuracy (10%)**: How closely results match requirements

### Secondary Metrics (Bonus/Penalty)
- **Error Recovery Time**: Time spent debugging and fixing issues
- **Documentation Quality**: Quality of implementation documentation
- **Innovation/Insights**: Discoveries and improvements made

## 📁 Directory Structure

```
experiment-results-ng/
├── condensed-approach/
│   ├── progress-log.md
│   └── time-tracking.md
├── detailed-approach/
│   ├── progress-log.md
│   └── time-tracking.md
├── comparison-results.md
└── EXPERIMENT-SUMMARY-NG.md
```

## 🎯 Success Criteria

Both approaches should produce:
- Working ProbeHero8 implementation
- Comprehensive test coverage
- VOLO standards compliance
- Proper error handling and validation
- Enhanced rules system pattern application
- Progress and time tracking completion
- Developer experience ratings

## 📝 Implementation Guidelines

### Condensed Approach
- Focus on speed and efficiency
- Apply essential rules system patterns only
- Minimal documentation
- Quick decision-making

### Detailed Approach
- Focus on comprehensiveness and quality
- Apply all relevant rules system patterns
- Extensive documentation
- Thorough analysis and planning

## 🔍 Results Analysis

The comparison script automatically:
- Extracts ratings from progress logs
- Calculates weighted scores
- Determines the winning approach
- Evaluates rules system effectiveness
- Generates recommendations

## 🚀 Next Steps After Experiment

1. **Review Results**: Check `comparison-results.md` for detailed analysis
2. **Apply Learnings**: Use winning approach for future implementations
3. **Improve Rules**: Refine rules system based on effectiveness data
4. **Share Knowledge**: Document insights for the development team

## 🆘 Troubleshooting

### Common Issues
- **"Experiment not set up"**: Run `./setup-ng-experiment.sh` first
- **"Not in git repository"**: Ensure you're in the project root directory
- **"Not on main-ng branch"**: Switch to main-ng branch before running scripts

### Getting Help
- Check the progress logs in `experiment-results-ng/` for detailed information
- Review the implementation plans for guidance
- Consult the enhanced rules system documentation in `ng/` directory

## 📈 Expected Outcomes

### If Hypothesis is Correct
- Condensed plan shows 15-25% faster development
- Equivalent or better code quality
- Higher developer satisfaction scores
- Strong rules system effectiveness

### If Hypothesis is Incorrect
- Detailed plan provides better guidance
- More context leads to better decisions
- Comprehensive planning prevents errors
- Rules system effectiveness varies by approach

---

**Ready to discover which planning approach works better for VHDL development with enhanced rules system! 🚀**
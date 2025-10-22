#!/bin/bash

# Start Detailed Approach Implementation (NG)
# Automated script for running the detailed approach with enhanced rules system

set -e  # Exit on any error

echo "🚀 Starting Detailed Approach Implementation (NG)"
echo "=================================================="
echo "Using enhanced rules system from main-ng branch"
echo ""

# Check if setup has been run
if [ ! -d "experiment-results-ng" ]; then
    echo "❌ Error: Experiment not set up. Run ./setup-ng-experiment.sh first"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Ensure we're on main-ng branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main-ng" ]; then
    echo "⚠️  Warning: Not on main-ng branch (currently on: $current_branch)"
    echo "Switching to main-ng branch..."
    git checkout main-ng
fi

echo "✅ On branch: $(git branch --show-current)"

# Create feature branch for detailed approach
echo "🌿 Creating feature branch for detailed approach..."
git checkout -b feature/probehero8-detailed-ng

# Update progress log with start time
echo "📊 Updating progress log with start time..."
sed -i.bak "s/- \*\*Start Time\*\*: /- **Start Time**: $(date)/" experiment-results-ng/detailed-approach/progress-log.md
sed -i.bak "s/- \*\*Start Time\*\*: /- **Start Time**: $(date)/" experiment-results-ng/detailed-approach/time-tracking.md

# Create implementation prompt
echo "📋 Creating implementation prompt..."
cat > detailed-approach-prompt-ng.md << 'EOF'
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
EOF

# Commit the setup
echo "💾 Committing detailed approach setup..."
git add experiment-results-ng/detailed-approach/ detailed-approach-prompt-ng.md TODO-PH8-implementation-plan-DETAILED-NG.md
git commit -m "Detailed Approach NG: Setup progress tracking and implementation prompt

- Created progress log for detailed implementation approach (NG)
- Set up time tracking for accurate measurement
- Created implementation prompt with comprehensive enhanced rules system integration
- Ready to begin implementation with comprehensive planning + enhanced rules"

echo ""
echo "✅ Detailed approach setup complete!"
echo ""
echo "📋 You are now on branch: $(git branch --show-current)"
echo ""
echo "📄 Implementation files created:"
echo "   - TODO-PH8-implementation-plan-DETAILED-NG.md"
echo "   - detailed-approach-prompt-ng.md"
echo "   - experiment-results-ng/detailed-approach/progress-log.md"
echo "   - experiment-results-ng/detailed-approach/time-tracking.md"
echo ""
echo "🎯 Next steps:"
echo "1. Read the detailed implementation plan: TODO-PH8-implementation-plan-DETAILED-NG.md"
echo "2. Review the implementation prompt: detailed-approach-prompt-ng.md"
echo "3. Begin Phase 1: Comprehensive Analysis & Planning"
echo "4. Track your progress in experiment-results-ng/detailed-approach/"
echo ""
echo "🔧 Enhanced rules system patterns to apply (ALL relevant):"
echo "   - PROC-01: Avoid unintended latches"
echo "   - SIG-01: Single-writer for signals"
echo "   - SIG-02: Named association & explicit conversions"
echo "   - SIG-03: Signal priority & truth table"
echo "   - TIM-01: Constrain critical paths"
echo "   - RES-01: BRAM inference patterns"
echo "   - STD-01: Use portable subset for Verilog"
echo "   - TB-01 through TB-06: All testbench patterns"
echo ""
echo "🎯 Remember: Focus on comprehensiveness, quality, and thorough analysis!"
echo ""
echo "📊 Start time: $(date)"
echo ""
echo "🚀 Ready to implement ProbeHero8 with detailed approach + enhanced rules!"
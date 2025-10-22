#!/bin/bash

# Start Condensed Approach Implementation (NG)
# Automated script for running the condensed approach with enhanced rules system

set -e  # Exit on any error

echo "🚀 Starting Condensed Approach Implementation (NG)"
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

# Create feature branch for condensed approach
echo "🌿 Creating feature branch for condensed approach..."
git checkout -b feature/probehero8-condensed-ng

# Update progress log with start time
echo "📊 Updating progress log with start time..."
sed -i.bak "s/- \*\*Start Time\*\*: /- **Start Time**: $(date)/" experiment-results-ng/condensed-approach/progress-log.md
sed -i.bak "s/- \*\*Start Time\*\*: /- **Start Time**: $(date)/" experiment-results-ng/condensed-approach/time-tracking.md

# Create implementation prompt
echo "📋 Creating implementation prompt..."
cat > condensed-approach-prompt-ng.md << 'EOF'
# Condensed Approach Implementation Prompt (NG)

## 🎯 Mission
Implement ProbeHero8 using the **condensed approach** with the **enhanced rules system** from main-ng branch.

## 📋 Approach Philosophy
- **Speed over comprehensiveness**: Focus on getting things done quickly
- **Essential information only**: Use only the information you need
- **Action-oriented**: Focus on "what to do" rather than "why to do it"
- **Efficiency**: Minimize cognitive overhead and context switching

## 🔧 Enhanced Rules System Integration
Apply these specific patterns from the enhanced rules system:

### SIG-02: Named Association & Explicit Conversions
```vhdl
u_core: entity work.core
  port map (
    clk   => clk,
    rst   => rst,
    a_in  => std_logic_vector(a_u),
    b_in  => std_logic_vector(b_u),
    y_out => y
  );
```

### SIG-03: Signal Priority & Truth Table
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      y <= (others => '0');     -- highest priority
    elsif ce = '1' then
      if en = '1' then
        y <= next_y;
      end if;
    end if;
  end if;
end process;
```

### TB-05: Clock & Timing Management
```vhdl
wait until rising_edge(clk);
if ce = '1' then
  drive_inputs;
end if;
```

### TB-06: Reset & Initialization Testing
```vhdl
rst <= '1'; wait for 10*CLK_PERIOD;
rst <= '0'; wait until rising_edge(clk);
assert outputs = DEFAULTS report "post-reset defaults wrong" severity error;
```

## 📁 Implementation Plan
Follow: `TODO-PH8-implementation-plan-CONDENSED-NG.md`

## 📊 Progress Tracking
Update: `experiment-results-ng/condensed-approach/progress-log.md`

## ⏱️ Time Tracking
Update: `experiment-results-ng/condensed-approach/time-tracking.md`

## 🎯 Success Criteria
- Working ProbeHero8 implementation
- All tests pass with GHDL
- Enhanced rules system patterns applied
- Progress and time tracking completed
- Developer experience ratings provided

## 🚀 Ready to implement!
EOF

# Commit the setup
echo "💾 Committing condensed approach setup..."
git add experiment-results-ng/condensed-approach/ condensed-approach-prompt-ng.md TODO-PH8-implementation-plan-CONDENSED-NG.md
git commit -m "Condensed Approach NG: Setup progress tracking and implementation prompt

- Created progress log for condensed implementation approach (NG)
- Set up time tracking for accurate measurement
- Created implementation prompt with enhanced rules system integration
- Ready to begin implementation with streamlined planning + enhanced rules"

echo ""
echo "✅ Condensed approach setup complete!"
echo ""
echo "📋 You are now on branch: $(git branch --show-current)"
echo ""
echo "📄 Implementation files created:"
echo "   - TODO-PH8-implementation-plan-CONDENSED-NG.md"
echo "   - condensed-approach-prompt-ng.md"
echo "   - experiment-results-ng/condensed-approach/progress-log.md"
echo "   - experiment-results-ng/condensed-approach/time-tracking.md"
echo ""
echo "🎯 Next steps:"
echo "1. Read the condensed implementation plan: TODO-PH8-implementation-plan-CONDENSED-NG.md"
echo "2. Review the implementation prompt: condensed-approach-prompt-ng.md"
echo "3. Begin Phase 1: Core Entity Development"
echo "4. Track your progress in experiment-results-ng/condensed-approach/"
echo ""
echo "🔧 Enhanced rules system patterns to apply:"
echo "   - SIG-02: Named association & explicit conversions"
echo "   - SIG-03: Signal priority & truth table"
echo "   - TB-05: Clock & timing management"
echo "   - TB-06: Reset & initialization testing"
echo ""
echo "🎯 Remember: Focus on speed, efficiency, and getting things done!"
echo ""
echo "📊 Start time: $(date)"
echo ""
echo "🚀 Ready to implement ProbeHero8 with condensed approach + enhanced rules!"
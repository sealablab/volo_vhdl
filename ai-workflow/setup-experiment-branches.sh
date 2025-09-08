#!/bin/bash

# ProbeHero8 Implementation Plan Experiment Setup
# Creates feature branches for both detailed and condensed approaches

set -e  # Exit on any error

echo "🚀 Setting up ProbeHero8 Implementation Plan Experiment"
echo "=================================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Ensure we're on main branch and up to date
echo "📋 Syncing with main branch..."
git checkout main
git pull origin main

# Create experiment tracking directory
echo "📁 Creating experiment tracking directory..."
mkdir -p experiment-results
mkdir -p experiment-results/detailed-approach
mkdir -p experiment-results/condensed-approach

# Create detailed approach branch
echo "🌿 Creating detailed approach branch..."
git checkout -b feature/probehero8-detailed-plan
echo "✅ Created branch: feature/probehero8-detailed-plan"

# Copy detailed plan to experiment directory
cp TODO-PH8-implementation-plan.md experiment-results/detailed-approach/
echo "📄 Copied detailed plan to experiment directory"

# Create initial commit for detailed approach
git add experiment-results/detailed-approach/
git commit -m "Experiment: Setup detailed plan approach

- Created feature branch for detailed implementation plan
- Copied detailed plan to experiment tracking directory
- Ready to begin implementation with comprehensive planning approach"

# Switch back to main
git checkout main

# Create condensed approach branch
echo "🌿 Creating condensed approach branch..."
git checkout -b feature/probehero8-condensed-plan
echo "✅ Created branch: feature/probehero8-condensed-plan"

# Copy condensed plan to experiment directory
cp TODO-PH8-implementation-plan-CONDENSED.md experiment-results/condensed-approach/
echo "📄 Copied condensed plan to experiment directory"

# Create initial commit for condensed approach
git add experiment-results/condensed-approach/
git commit -m "Experiment: Setup condensed plan approach

- Created feature branch for condensed implementation plan
- Copied condensed plan to experiment tracking directory
- Ready to begin implementation with streamlined planning approach"

# Switch back to main
echo "🔄 Returning to main branch..."
git checkout main

# Create experiment metadata
echo "📊 Creating experiment metadata..."
cat > experiment-results/experiment-metadata.md << 'EOF'
# ProbeHero8 Implementation Plan Experiment

## Experiment Setup
- **Start Date**: $(date)
- **Hypothesis**: Condensed plans will produce faster, more focused development
- **Branches Created**:
  - `feature/probehero8-detailed-plan` - Comprehensive planning approach
  - `feature/probehero8-condensed-plan` - Streamlined planning approach

## Tracking Files
- `detailed-approach/` - Results and artifacts from detailed plan
- `condensed-approach/` - Results and artifacts from condensed plan
- `comparison-results.md` - Final comparison and analysis

## Next Steps
1. Choose which approach to implement first
2. Switch to appropriate branch and begin implementation
3. Track progress using provided evaluation criteria
4. Document findings throughout the process
EOF

git add experiment-results/
git commit -m "Experiment: Add experiment metadata and tracking structure

- Created experiment metadata with setup information
- Established tracking structure for both approaches
- Ready to begin comparative implementation study"

echo ""
echo "✅ Experiment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Choose your starting approach:"
echo "   - git checkout feature/probehero8-detailed-plan"
echo "   - git checkout feature/probehero8-condensed-plan"
echo ""
echo "2. Begin implementation following the chosen plan"
echo ""
echo "3. Track your progress using the evaluation criteria"
echo ""
echo "4. Document findings in experiment-results/"
echo ""
echo "🎯 Good luck with the experiment!"
#!/bin/bash

# Run Full Experiment (NG)
# Master script to run the entire ProbeHero8 Implementation Plan Experiment unattended

set -e  # Exit on any error

echo "🚀 ProbeHero8 Implementation Plan Experiment (NG) - Full Automation"
echo "=================================================================="
echo "This script will run the entire experiment unattended using the enhanced rules system"
echo ""

# Function to wait for user input
wait_for_user() {
    echo ""
    echo "⏸️  PAUSED: $1"
    echo "Press Enter to continue, or Ctrl+C to exit..."
    read -r
}

# Function to check if we're in the right directory
check_environment() {
    if [ ! -f "README.md" ] || [ ! -d "modules" ]; then
        echo "❌ Error: Not in the correct project directory"
        echo "Please run this script from the project root directory"
        exit 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Error: Not in a git repository"
        exit 1
    fi
}

# Function to setup experiment
setup_experiment() {
    echo "📋 Step 1: Setting up experiment infrastructure..."
    ./setup-ng-experiment.sh
    echo "✅ Experiment setup complete!"
}

# Function to run condensed approach
run_condensed_approach() {
    echo ""
    echo "📋 Step 2: Running condensed approach..."
    wait_for_user "Ready to start condensed approach implementation?"
    
    ./start-condensed-ng.sh
    
    echo ""
    echo "🎯 Condensed approach setup complete!"
    echo "📝 Now implement ProbeHero8 using the condensed approach:"
    echo "   1. Follow: TODO-PH8-implementation-plan-CONDENSED-NG.md"
    echo "   2. Apply enhanced rules system patterns (SIG-02, SIG-03, TB-05, TB-06)"
    echo "   3. Track progress in: experiment-results-ng/condensed-approach/"
    echo "   4. Update time tracking as you work"
    echo ""
    wait_for_user "Complete the condensed approach implementation, then press Enter to continue"
}

# Function to run detailed approach
run_detailed_approach() {
    echo ""
    echo "📋 Step 3: Running detailed approach..."
    wait_for_user "Ready to start detailed approach implementation?"
    
    ./start-detailed-ng.sh
    
    echo ""
    echo "🎯 Detailed approach setup complete!"
    echo "📝 Now implement ProbeHero8 using the detailed approach:"
    echo "   1. Follow: TODO-PH8-implementation-plan-DETAILED-NG.md"
    echo "   2. Apply ALL relevant enhanced rules system patterns"
    echo "   3. Track progress in: experiment-results-ng/detailed-approach/"
    echo "   4. Update time tracking as you work"
    echo ""
    wait_for_user "Complete the detailed approach implementation, then press Enter to continue"
}

# Function to compare results
compare_results() {
    echo ""
    echo "📋 Step 4: Comparing results..."
    wait_for_user "Ready to analyze and compare results?"
    
    ./compare-results-ng.sh
    
    echo "✅ Results comparison complete!"
}

# Function to show final summary
show_final_summary() {
    echo ""
    echo "🎉 EXPERIMENT COMPLETE!"
    echo "======================="
    echo ""
    echo "📊 Results available in:"
    echo "   - experiment-results-ng/comparison-results.md"
    echo "   - experiment-results-ng/EXPERIMENT-SUMMARY-NG.md"
    echo ""
    echo "🔍 Key findings:"
    if [ -f "experiment-results-ng/comparison-results.md" ]; then
        echo "   - Winner: $(grep -A1 "Overall Winner" experiment-results-ng/comparison-results.md | tail -1 | sed 's/.*: //')"
        echo "   - Rules system impact: See comparison-results.md for details"
    else
        echo "   - See comparison-results.md for detailed analysis"
    fi
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Review the detailed comparison results"
    echo "   2. Apply learnings to future ProbeHero implementations"
    echo "   3. Consider rules system improvements based on results"
    echo "   4. Share results with the development team"
    echo ""
    echo "📈 Enhanced rules system evaluation complete!"
    echo "   - SIG-02: Named association & explicit conversions"
    echo "   - SIG-03: Signal priority & truth table"
    echo "   - TB-05: Clock & timing management"
    echo "   - TB-06: Reset & initialization testing"
    echo ""
    echo "🎯 Thank you for participating in the ProbeHero8 Implementation Plan Experiment (NG)!"
}

# Main execution
main() {
    echo "🔍 Checking environment..."
    check_environment
    
    echo "✅ Environment check passed!"
    echo "📍 Current directory: $(pwd)"
    echo "🌿 Current branch: $(git branch --show-current)"
    echo ""
    
    # Run the experiment steps
    setup_experiment
    run_condensed_approach
    run_detailed_approach
    compare_results
    show_final_summary
}

# Handle interruption
trap 'echo ""; echo "❌ Experiment interrupted by user"; exit 1' INT

# Run main function
main

echo ""
echo "🏁 Experiment completed successfully!"
echo "📊 All results saved to experiment-results-ng/ directory"
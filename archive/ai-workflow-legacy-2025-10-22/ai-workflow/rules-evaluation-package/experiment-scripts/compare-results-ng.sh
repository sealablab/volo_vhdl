#!/bin/bash

# Compare Results (NG)
# Automated script for comparing condensed vs detailed approach results

set -e  # Exit on any error

echo "📊 Comparing ProbeHero8 Implementation Plan Results (NG)"
echo "======================================================="
echo "Analyzing condensed vs detailed approach with enhanced rules system"
echo ""

# Check if experiment results exist
if [ ! -d "experiment-results-ng" ]; then
    echo "❌ Error: Experiment results not found. Run the experiment first."
    exit 1
fi

# Check if both approaches have been completed
if [ ! -f "experiment-results-ng/condensed-approach/progress-log.md" ] || [ ! -f "experiment-results-ng/detailed-approach/progress-log.md" ]; then
    echo "❌ Error: Both approaches must be completed before comparison."
    echo "Missing progress logs. Please complete both implementations first."
    exit 1
fi

echo "✅ Found experiment results for both approaches"
echo ""

# Create analysis script
echo "🔍 Creating analysis script..."
cat > analyze-results-ng.py << 'EOF'
#!/usr/bin/env python3
"""
ProbeHero8 Implementation Plan Results Analyzer (NG)
Analyzes condensed vs detailed approach results with enhanced rules system
"""

import re
import os
from datetime import datetime

def extract_ratings(file_path):
    """Extract ratings from progress log"""
    ratings = {}
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Extract ratings
        rating_patterns = {
            'developer_experience': r'Developer Experience Rating.*?(\d+)',
            'plan_effectiveness': r'Plan Effectiveness Rating.*?(\d+)',
            'rules_effectiveness': r'Rules System Effectiveness.*?(\d+)',
            'overall_satisfaction': r'Overall Satisfaction.*?(\d+)'
        }
        
        for key, pattern in rating_patterns.items():
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                ratings[key] = int(match.group(1))
            else:
                ratings[key] = None
                
    except FileNotFoundError:
        print(f"Warning: Could not find {file_path}")
        
    return ratings

def extract_times(file_path):
    """Extract time information from time tracking"""
    times = {}
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Extract total time
        total_match = re.search(r'Total Development Time.*?(\d+.*?)', content, re.IGNORECASE)
        if total_match:
            times['total_time'] = total_match.group(1).strip()
        else:
            times['total_time'] = 'Not specified'
            
    except FileNotFoundError:
        print(f"Warning: Could not find {file_path}")
        
    return times

def calculate_scores(ratings):
    """Calculate weighted scores based on evaluation criteria"""
    weights = {
        'developer_experience': 0.20,
        'plan_effectiveness': 0.20,
        'rules_effectiveness': 0.20,
        'overall_satisfaction': 0.20
    }
    
    total_score = 0
    valid_ratings = 0
    
    for key, weight in weights.items():
        if ratings.get(key) is not None:
            total_score += ratings[key] * weight * 10  # Convert to 100-point scale
            valid_ratings += 1
    
    if valid_ratings > 0:
        return total_score / valid_ratings
    else:
        return 0

def main():
    print("🔍 Analyzing ProbeHero8 Implementation Plan Results (NG)")
    print("=" * 60)
    
    # Extract data from both approaches
    condensed_ratings = extract_ratings('experiment-results-ng/condensed-approach/progress-log.md')
    detailed_ratings = extract_ratings('experiment-results-ng/detailed-approach/progress-log.md')
    
    condensed_times = extract_times('experiment-results-ng/condensed-approach/time-tracking.md')
    detailed_times = extract_times('experiment-results-ng/detailed-approach/time-tracking.md')
    
    # Calculate scores
    condensed_score = calculate_scores(condensed_ratings)
    detailed_score = calculate_scores(detailed_ratings)
    
    # Determine winner
    if condensed_score > detailed_score:
        winner = "Condensed Approach"
        winner_score = condensed_score
        loser_score = detailed_score
    elif detailed_score > condensed_score:
        winner = "Detailed Approach"
        winner_score = detailed_score
        loser_score = condensed_score
    else:
        winner = "Tie"
        winner_score = condensed_score
        loser_score = detailed_score
    
    # Generate comparison report
    report = f"""
# ProbeHero8 Implementation Plan Comparison Results (NG) - Automated Analysis

## Analysis Summary
- **Analysis Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Rules System**: Enhanced structured rules (v1.1)
- **Branch**: main-ng

## Overall Winner
- **Approach**: {winner}
- **Condensed Score**: {condensed_score:.1f}/100
- **Detailed Score**: {detailed_score:.1f}/100
- **Score Difference**: {abs(condensed_score - detailed_score):.1f} points

## Detailed Comparison

### Condensed Approach Results
- **Total Development Time**: {condensed_times.get('total_time', 'Not specified')}
- **Developer Experience Rating**: {condensed_ratings.get('developer_experience', 'Not specified')}/10
- **Plan Effectiveness Rating**: {condensed_ratings.get('plan_effectiveness', 'Not specified')}/10
- **Rules System Effectiveness**: {condensed_ratings.get('rules_effectiveness', 'Not specified')}/10
- **Overall Satisfaction**: {condensed_ratings.get('overall_satisfaction', 'Not specified')}/10
- **Calculated Score**: {condensed_score:.1f}/100

### Detailed Approach Results
- **Total Development Time**: {detailed_times.get('total_time', 'Not specified')}
- **Developer Experience Rating**: {detailed_ratings.get('developer_experience', 'Not specified')}/10
- **Plan Effectiveness Rating**: {detailed_ratings.get('plan_effectiveness', 'Not specified')}/10
- **Rules System Effectiveness**: {detailed_ratings.get('rules_effectiveness', 'Not specified')}/10
- **Overall Satisfaction**: {detailed_ratings.get('overall_satisfaction', 'Not specified')}/10
- **Calculated Score**: {detailed_score:.1f}/100

## Key Insights

### Rules System Impact
- **Condensed Rules Effectiveness**: {condensed_ratings.get('rules_effectiveness', 'Not specified')}/10
- **Detailed Rules Effectiveness**: {detailed_ratings.get('rules_effectiveness', 'Not specified')}/10
- **Rules System Winner**: {'Condensed' if condensed_ratings.get('rules_effectiveness', 0) > detailed_ratings.get('rules_effectiveness', 0) else 'Detailed' if detailed_ratings.get('rules_effectiveness', 0) > condensed_ratings.get('rules_effectiveness', 0) else 'Tie'}

### Development Experience
- **Condensed Developer Experience**: {condensed_ratings.get('developer_experience', 'Not specified')}/10
- **Detailed Developer Experience**: {detailed_ratings.get('developer_experience', 'Not specified')}/10
- **Experience Winner**: {'Condensed' if condensed_ratings.get('developer_experience', 0) > detailed_ratings.get('developer_experience', 0) else 'Detailed' if detailed_ratings.get('developer_experience', 0) > condensed_ratings.get('developer_experience', 0) else 'Tie'}

## Recommendations

### For Future Projects
- **Use {winner} When**:
  - Looking for {'speed and efficiency' if winner == 'Condensed Approach' else 'comprehensive analysis and quality'}
  - Rules system effectiveness is {'high' if (condensed_ratings.get('rules_effectiveness', 0) if winner == 'Condensed Approach' else detailed_ratings.get('rules_effectiveness', 0)) >= 7 else 'moderate'}

### Rules System Improvements
- Both approaches show {'strong' if min(condensed_ratings.get('rules_effectiveness', 0), detailed_ratings.get('rules_effectiveness', 0)) >= 7 else 'moderate'} rules system effectiveness
- Consider {'expanding' if max(condensed_ratings.get('rules_effectiveness', 0), detailed_ratings.get('rules_effectiveness', 0)) >= 8 else 'refining'} the rules system based on results

## Conclusion

### Hypothesis Validation
- **Was the hypothesis correct?**: {'Yes' if winner == 'Condensed Approach' else 'No' if winner == 'Detailed Approach' else 'Inconclusive'}
- **Key evidence**: {winner} achieved higher overall score ({winner_score:.1f} vs {loser_score:.1f})
- **Confidence level**: {'High' if abs(condensed_score - detailed_score) >= 10 else 'Medium' if abs(condensed_score - detailed_score) >= 5 else 'Low'}

### Final Recommendation
Based on the results, **{winner}** is recommended for future ProbeHero implementations, with enhanced rules system integration.

---

*This analysis was generated automatically on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} as part of the ProbeHero8 Implementation Plan Experiment (NG).*
"""
    
    # Write the report
    with open('experiment-results-ng/comparison-results.md', 'w') as f:
        f.write(report)
    
    print("✅ Analysis complete!")
    print(f"📊 Winner: {winner}")
    print(f"📈 Condensed Score: {condensed_score:.1f}/100")
    print(f"📈 Detailed Score: {detailed_score:.1f}/100")
    print(f"📄 Report saved to: experiment-results-ng/comparison-results.md")

if __name__ == "__main__":
    main()
EOF

# Make the analysis script executable
chmod +x analyze-results-ng.py

# Run the analysis
echo "🔍 Running automated analysis..."
python3 analyze-results-ng.py

# Create summary report
echo "📄 Creating summary report..."
cat > experiment-results-ng/EXPERIMENT-SUMMARY-NG.md << EOF
# ProbeHero8 Implementation Plan Experiment Summary (NG)

## 🎯 Experiment Overview
- **Date**: $(date)
- **Branch**: main-ng
- **Rules System**: Enhanced structured rules (v1.1)
- **Hypothesis**: Condensed plans will produce faster, more focused development with equivalent or better code quality

## 📊 Quick Results
- **Winner**: [See comparison-results.md for detailed analysis]
- **Rules System Impact**: [See comparison-results.md for detailed analysis]
- **Key Insights**: [See comparison-results.md for detailed analysis]

## 📁 Files Generated
- \`comparison-results.md\` - Detailed comparison and analysis
- \`condensed-approach/progress-log.md\` - Condensed approach progress tracking
- \`condensed-approach/time-tracking.md\` - Condensed approach time tracking
- \`detailed-approach/progress-log.md\` - Detailed approach progress tracking
- \`detailed-approach/time-tracking.md\` - Detailed approach time tracking

## 🚀 Next Steps
1. Review the detailed comparison in \`comparison-results.md\`
2. Apply learnings to future ProbeHero implementations
3. Consider rules system improvements based on results
4. Share results with the development team

## 🔧 Enhanced Rules System Evaluation
The experiment evaluated the effectiveness of the enhanced rules system (v1.1) including:
- SIG-02: Named association & explicit conversions
- SIG-03: Signal priority & truth table
- TB-05: Clock & timing management
- TB-06: Reset & initialization testing

See \`comparison-results.md\` for detailed rules system impact analysis.

---

*Generated on $(date) as part of the ProbeHero8 Implementation Plan Experiment (NG)*
EOF

echo ""
echo "✅ Comparison complete!"
echo ""
echo "📊 Results saved to:"
echo "   - experiment-results-ng/comparison-results.md"
echo "   - experiment-results-ng/EXPERIMENT-SUMMARY-NG.md"
echo ""
echo "🎯 Key findings:"
echo "   - See comparison-results.md for detailed analysis"
echo "   - Enhanced rules system effectiveness evaluated"
echo "   - Recommendations for future projects included"
echo ""
echo "🚀 Experiment complete! Review the results and apply learnings to future implementations."
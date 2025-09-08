#!/bin/bash

# Compare Results from Both Implementation Approaches
# Analyzes and compares the results from detailed vs condensed approaches

set -e  # Exit on any error

echo "📊 Comparing Implementation Plan Results"
echo "======================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Create comparison results file
echo "📋 Creating comparison results..."
cat > experiment-results/comparison-results.md << 'EOF'
# ProbeHero8 Implementation Plan Comparison Results

## Experiment Overview
- **Hypothesis**: Condensed plans will produce faster, more focused development with equivalent or better code quality
- **Date**: $(date)
- **Approaches Compared**:
  - Detailed Plan: Comprehensive planning with extensive documentation
  - Condensed Plan: Streamlined planning with essential information only

## Results Summary

### Overall Winner
- **Approach**: [TO BE FILLED]
- **Total Score**: [TO BE FILLED]
- **Key Advantage**: [TO BE FILLED]

### Metric-by-Metric Comparison

#### 1. Development Speed (30% weight)
| Approach | Time | Score | Notes |
|----------|------|-------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| **Winner** | [TO BE FILLED] | | |

#### 2. Code Quality (40% weight)
| Approach | Score | Functional | Standards | Tests | Docs | Notes |
|----------|-------|------------|-----------|-------|------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| **Winner** | [TO BE FILLED] | | | | | |

#### 3. Developer Experience (20% weight)
| Approach | Score | Clarity | Usability | Efficiency | Satisfaction | Notes |
|----------|-------|---------|-----------|------------|--------------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| **Winner** | [TO BE FILLED] | | | | | |

#### 4. Implementation Accuracy (10% weight)
| Approach | Score | Requirements Match | Feature Completeness | Notes |
|----------|-------|-------------------|---------------------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| **Winner** | [TO BE FILLED] | | | |

### Secondary Metrics

#### Error Recovery Time
| Approach | Time | Score | Notes |
|----------|------|-------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] | [TO BE FILLED] |

#### Documentation Quality
| Approach | Score | Notes |
|----------|-------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] |

#### Innovation/Insights
| Approach | Score | Notes |
|----------|-------|-------|
| Detailed | [TO BE FILLED] | [TO BE FILLED] |
| Condensed | [TO BE FILLED] | [TO BE FILLED] |

## Detailed Analysis

### Strengths of Detailed Approach
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

### Strengths of Condensed Approach
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

### Weaknesses of Detailed Approach
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

### Weaknesses of Condensed Approach
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

## Key Insights

### What Surprised Us
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

### What Confirmed Our Expectations
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

### What We Learned
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

## Recommendations

### For Future Projects
- **Use Detailed Plans When**:
  - [TO BE FILLED]
  - [TO BE FILLED]
  - [TO BE FILLED]

- **Use Condensed Plans When**:
  - [TO BE FILLED]
  - [TO BE FILLED]
  - [TO BE FILLED]

### Process Improvements
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

## Conclusion

### Hypothesis Validation
- **Was the hypothesis correct?**: [TO BE FILLED]
- **Key evidence**: [TO BE FILLED]
- **Confidence level**: [TO BE FILLED]

### Final Recommendation
[TO BE FILLED]

### Next Steps
- [TO BE FILLED]
- [TO BE FILLED]
- [TO BE FILLED]

---

*This comparison was generated on $(date) as part of the ProbeHero8 Implementation Plan Experiment.*
EOF

# Create README for implementation plan tips
echo "📝 Creating implementation plan tips..."
cat > README-implementation-plan-tips.md << 'EOF'
# Implementation Plan Tips

## Based on ProbeHero8 Experiment Results

*This document contains insights and recommendations based on the comparative study of detailed vs condensed implementation plans.*

## Key Findings

### [TO BE UPDATED AFTER EXPERIMENT]

## Best Practices

### When to Use Detailed Plans
- [TO BE FILLED]

### When to Use Condensed Plans  
- [TO BE FILLED]

### Hybrid Approaches
- [TO BE FILLED]

## Template Recommendations

### Detailed Plan Template
- [TO BE FILLED]

### Condensed Plan Template
- [TO BE FILLED]

## Process Improvements

### Planning Phase
- [TO BE FILLED]

### Implementation Phase
- [TO BE FILLED]

### Validation Phase
- [TO BE FILLED]

## Tools and Techniques

### Time Tracking
- [TO BE FILLED]

### Progress Monitoring
- [TO BE FILLED]

### Quality Assessment
- [TO BE FILLED]

---

*This document will be updated with specific recommendations after the experiment is complete.*
EOF

# Commit the comparison framework
git add experiment-results/comparison-results.md README-implementation-plan-tips.md
git commit -m "Experiment: Create comparison framework and results template

- Created comparison results template for analyzing both approaches
- Set up README for implementation plan tips based on results
- Ready to fill in results after both implementations are complete"

echo ""
echo "✅ Comparison framework created!"
echo ""
echo "📋 Files created:"
echo "- experiment-results/comparison-results.md (comparison template)"
echo "- README-implementation-plan-tips.md (tips document)"
echo ""
echo "📄 Next steps:"
echo "1. Complete both implementations"
echo "2. Fill in the comparison results template"
echo "3. Update the implementation plan tips with findings"
echo "4. Commit final results"
echo ""
echo "🎯 The framework is ready for your experiment results!"
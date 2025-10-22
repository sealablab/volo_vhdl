cat > stale_tbd/README.md << 'EOF'
# Stale Files Archive

This directory contains files that were moved from the main `ai-workflow/` directory to keep them organized but not lose them.

## Directory Structure

### experiments/
- **probehero8/**: ProbeHero8 experiment results and analysis
  - `experiment-results/`: Original experiment results
  - `experiment-results-ng/`: Next-generation experiment results
- **general/**: General experiment files
  - `EXPERIMENT-README.md`: Experiment documentation
  - `experiment-hypothesis.md`: Experiment hypothesis
  - `evaluation-criteria.md`: Evaluation criteria
  - `compare-results.sh`: Results comparison script
  - `detailed-approach-prompt*.md`: Detailed approach prompts
  - `README-implementation-plan-tips.md`: Implementation tips

### development/
- **roadmaps/**: Development roadmap documents
  - `BASE-MODULE-DEVELOPMENT-ROADMAP*.md`: Base module development roadmaps
  - `STOPLIGHT-MODULE-ROADMAP.md`: Stoplight module roadmap
- **todos/**: TODO and planning documents
  - `TODO-PH8-*.md`: ProbeHero8 TODO files
  - `TODO-PHASE*.md`: Phase TODO files
  - `TODO-TOMOROOW.md`: Tomorrow's TODO
- **analysis/**: Analysis documents
  - `DATADEF_ANALYSIS*.md`: Data definition analysis
  - `README-0D-DataDefs.md`: Data definitions README

### scripts/
- `setup-experiment-branches.sh`: Experiment branch setup
- `start-condensed-approach.sh`: Condensed approach script
- `start-detailed-approach.sh`: Detailed approach script

### temp/
- `t.txt`, `t2.txt`, `ret.txt`: Temporary text files
- `WIP_*.md`: Work-in-progress documents

### archives/
- `enhanced-rules-evaluation-package.tar.gz`: Compressed evaluation package

## Files Kept in ai-workflow/ (Active)
- `ng/`: Active rules and guidelines
- `templates/`: Active templates
- `prompts/`: Active prompts
- `examples/`: Active examples
- `modules/`: Active modules (volo_base, volo_common)
- `rules-evaluation-package/`: Active evaluation package
- `README*.md`: Active documentation

## Notes
- Files were moved on: $(date)
- All files preserved their original content
- Directory structure organized by function and project
- Easy to find specific files by category
EOF

# ProbeHero8 Implementation Plan Experiment Scripts

## Overview
These scripts were used to run the complete ProbeHero8 Implementation Plan Experiment comparing condensed vs detailed approaches for VHDL development with the enhanced rules system.

## Scripts

### `run-full-experiment-ng.sh`
- **Purpose**: Master script to run the entire experiment unattended
- **Usage**: `./run-full-experiment-ng.sh`
- **Features**: Guided prompts for each phase, automated workflow
- **Dependencies**: All other scripts

### `setup-ng-experiment.sh`
- **Purpose**: Create experiment infrastructure and tracking files
- **Usage**: `./setup-ng-experiment.sh`
- **Creates**: 
  - `experiment-results-ng/` directory structure
  - Progress tracking files for both approaches
  - Implementation plans with enhanced rules system integration
  - Comparison framework

### `start-condensed-ng.sh`
- **Purpose**: Set up and start condensed approach implementation
- **Usage**: `./start-condensed-ng.sh`
- **Features**:
  - Creates feature branch for condensed approach
  - Sets up progress tracking
  - Creates implementation prompt with enhanced rules system
  - Focuses on speed and efficiency

### `start-detailed-ng.sh`
- **Purpose**: Set up and start detailed approach implementation
- **Usage**: `./start-detailed-ng.sh`
- **Features**:
  - Creates feature branch for detailed approach
  - Sets up comprehensive progress tracking
  - Creates implementation prompt with all rules system patterns
  - Focuses on thoroughness and quality

### `compare-results-ng.sh`
- **Purpose**: Analyze and compare results from both approaches
- **Usage**: `./compare-results-ng.sh`
- **Features**:
  - Analyzes progress logs and time tracking
  - Calculates weighted scores based on evaluation criteria
  - Generates comprehensive comparison report
  - Provides recommendations for future projects

## Experiment Workflow

### Option 1: Full Automated Experiment
```bash
./run-full-experiment-ng.sh
```

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

## Requirements
- Git repository with main-ng branch
- Bash shell
- GHDL (for VHDL compilation)
- Project root directory with modules/ structure

## Key Features
- **Enhanced Rules System Integration**: All scripts designed to work with enhanced rules system (v1.1)
- **Progress Tracking**: Comprehensive logging and time tracking
- **Automated Comparison**: Weighted scoring and analysis
- **Git Integration**: Feature branch management and merging
- **Reproducible**: Complete experiment can be re-run

## Results
- **Winner**: Detailed Approach (9.25/10 vs 7.75/10)
- **New Rules**: 8 candidate patterns discovered
- **Validation**: All patterns successfully applied in working VHDL code
- **Effectiveness**: Enhanced rules system rated 9-10/10 in both approaches

## Archive Purpose
These scripts are preserved for:
- **Reproducibility**: Future experiments can use the same methodology
- **Reference**: Understanding how the experiment was conducted
- **Improvement**: Basis for future experiment design
- **Documentation**: Complete record of the experimental process

---
*Scripts used in ProbeHero8 Implementation Plan Experiment (NG)*
*Date: August 30, 2025*
*Enhanced Rules System: v1.1*
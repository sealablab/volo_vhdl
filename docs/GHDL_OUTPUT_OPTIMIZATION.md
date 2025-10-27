# GHDL Output Optimization for LLM Context Preservation

## Problem Statement

GHDL produces verbose output during simulation, particularly:
- **Metavalue warnings**: "NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0"
- **Null warnings**: "NUMERIC_STD.'=': null argument detected, returning FALSE"
- **Initialization warnings**: Numerous warnings at time 0
- **Duplicate warnings**: Same warning repeated hundreds of times
- **Internal messages**: Elaboration info, bound checks, etc.

This verbosity rapidly consumes LLM context windows, reducing development efficiency.

## Solution: Three-Pronged Approach

### 1. Optimal GHDL Invocation Flags

Use these runtime flags to minimize output at the source:

```bash
# RECOMMENDED: Suppress initialization warnings only
ghdl -r <entity> --ieee-asserts=disable-at-0

# AGGRESSIVE: Disable all IEEE assertions
ghdl -r <entity> --ieee-asserts=disable

# WITH TIMEOUT: Prevent runaway simulations
ghdl -r <entity> --ieee-asserts=disable-at-0 --stop-time=1ms

# QUIET MODE: Combine multiple suppressions
ghdl -r <entity> \
  --ieee-asserts=disable-at-0 \
  --assert-level=error \
  --stop-delta=1000
```

### 2. Python Output Filter

When GHDL flags aren't enough, use our intelligent filter:

```bash
# Basic usage
ghdl -r entity | python tests/ghdl_output_filter.py

# Aggressive filtering for LLMs
ghdl -r entity | python tests/ghdl_output_filter.py --level aggressive

# Levels available:
# - aggressive: Maximum suppression (best for LLMs)
# - normal: Balanced (default)
# - minimal: Light filtering
# - none: Pass-through
```

### 3. CocotB Integration

Update test configurations to use optimal settings:

```python
# In test_configs.py or run.py
ghdl_args = [
    "--std=08",
    "--ieee-asserts=disable-at-0",  # Suppress init warnings
]

# For runtime in CocotB
sim_args = [
    "--wave=dump.ghw",
    "--ieee-asserts=disable-at-0",
    "--assert-level=error",  # Only stop on errors
]
```

## Implementation Examples

### Example 1: Manual GHDL Run (Minimal Output)

```bash
# Compile
ghdl -a --std=08 *.vhd

# Run with maximum suppression
ghdl -r counter_nbit \
  --ieee-asserts=disable-at-0 \
  --assert-level=none \
  | python tests/ghdl_output_filter.py --level aggressive
```

### Example 2: CocotB Test Runner Update

```python
# tests/run.py modification
def run_test(self, test_name: str) -> bool:
    # ...

    # Add optimal GHDL flags
    build_args = config.ghdl_args.copy()
    build_args.extend([
        "--ieee-asserts=disable-at-0",  # Key optimization
    ])

    # Add runtime flags
    sim_args = []
    if self.waves:
        sim_args.append("--wave=dump.ghw")

    # Add suppression flags
    sim_args.extend([
        "--ieee-asserts=disable-at-0",
        "--assert-level=error",
    ])

    # ...
```

### Example 3: Makefile Integration (Legacy)

```makefile
# Add to Makefile
GHDL_RUN_FLAGS = --ieee-asserts=disable-at-0 --assert-level=error

test-%:
    ghdl -r $* $(GHDL_RUN_FLAGS) | python tests/ghdl_output_filter.py
```

## Effectiveness Comparison

### Before (Standard GHDL)
```
ghdl:info: simulation stopped by --stop-time
./counter_tb:info: simulation stopped at 1ms
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@0ms:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
... [500+ similar lines] ...
Test 1: PASSED
Test 2: PASSED
ALL TESTS PASSED
```
**Output: ~500 lines, ~8000 tokens**

### After (Optimized)
```
Test 1: PASSED
Test 2: PASSED
ALL TESTS PASSED

[GHDL Output Filter - Level: aggressive]
  Total lines: 523
  Filtered: 498 (95.2% reduction)
  - Metavalue warnings: 245
  - Null warnings: 89
  - Initialization warnings: 134
  - Duplicate warnings: 30
```
**Output: ~10 lines, ~100 tokens (98.75% reduction)**

## Quick Reference

### Environment Variables
```bash
# For test runner
export GHDL_FILTER_LEVEL=aggressive  # or normal, minimal, none
export GHDL_SUPPRESS_METAVALUE=1     # Use --ieee-asserts=disable-at-0
```

### Command Line
```bash
# Compile (unchanged)
ghdl -a --std=08 *.vhd

# Run with suppression
ghdl -r entity --ieee-asserts=disable-at-0

# Run with filter
ghdl -r entity | python tests/ghdl_output_filter.py --level aggressive

# Combined (maximum suppression)
ghdl -r entity --ieee-asserts=disable-at-0 --assert-level=none \
  | python tests/ghdl_output_filter.py --level aggressive
```

## Key GHDL Runtime Options

| Option | Description | Use Case |
|--------|-------------|----------|
| `--ieee-asserts=disable-at-0` | Disable IEEE warnings at time 0 | **ALWAYS USE** - Eliminates init noise |
| `--ieee-asserts=disable` | Disable all IEEE assertions | Aggressive suppression |
| `--assert-level=error` | Only stop on errors, not warnings | Reduce verbosity |
| `--assert-level=none` | Never stop on assertions | Maximum suppression |
| `--stop-time=<TIME>` | Stop after specified time | Prevent runaway sims |
| `--stop-delta=<N>` | Stop after N delta cycles | Catch infinite loops |
| `--unbuffered` | Immediate output | Real-time filtering |

## Benefits

1. **98% reduction** in output verbosity
2. **Preserves critical information** (errors, test results)
3. **Configurable levels** for different use cases
4. **No code changes required** in VHDL
5. **Works with existing tests**

## Migration Guide

1. **Update test runners**: Add `--ieee-asserts=disable-at-0` to all GHDL invocations
2. **Add filter script**: Place `ghdl_output_filter.py` in tests directory
3. **Update CI/CD**: Pipe GHDL output through filter in pipelines
4. **Document in README**: Add usage examples for team

## Conclusion

By combining GHDL runtime flags with intelligent Python filtering, we achieve a **95-98% reduction** in simulation output while preserving all important information. This makes GHDL simulation output suitable for LLM-based development workflows without sacrificing debugging capability when needed.
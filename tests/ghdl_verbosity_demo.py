#!/usr/bin/env python3
"""
GHDL Verbosity Demonstration Script

Shows the dramatic difference in GHDL output with and without optimizations.

Usage:
    python tests/ghdl_verbosity_demo.py

Author: Volo Engineering
Date: 2025-01-26
"""

import os
import sys


def print_separator():
    print("=" * 70)


def simulate_unoptimized_ghdl():
    """Simulate typical unoptimized GHDL output"""
    print("\n")
    print_separator()
    print("UNOPTIMIZED GHDL OUTPUT (Default)")
    print_separator()
    print()

    output = """ghdl:info: simulation started
ghdl:info: elaboration of design hierarchy
./work-obj08.cf:info: loading package STANDARD
./work-obj08.cf:info: loading package NUMERIC_STD
./work-obj08.cf:info: loading entity counter_nbit
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@0ms:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@0ms:(assertion warning): NUMERIC_STD."<": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."<=": metavalue detected, returning FALSE
@0ms:(assertion warning): NUMERIC_STD."+": null argument detected, returning X
@0ms:(assertion warning): STD_LOGIC_1164."=": metavalue detected, returning FALSE
@10ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@10ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@20ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@20ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@30ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@30ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@40ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@40ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@50ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@50ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@60ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@60ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@70ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@70ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@80ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@80ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@90ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@90ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@100ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@100ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
[... 200+ more similar lines ...]
@990ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@990ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
@1000ns:(assertion warning): NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
@1000ns:(assertion warning): NUMERIC_STD."=": metavalue detected, returning FALSE
Test 1: Reset behavior - PASSED
Test 2: Count up - PASSED
Test 3: Count down - PASSED
Test 4: Load value - PASSED
ALL TESTS PASSED
ghdl:info: simulation stopped at 1ms"""

    print(output)
    print()
    lines = output.count('\n') + 1
    # Rough token estimate: ~15 tokens per line for technical output
    tokens = lines * 15
    print(f"TOTAL OUTPUT: {lines} lines")
    print(f"ESTIMATED TOKENS: ~{tokens} tokens")
    print()


def simulate_optimized_ghdl():
    """Simulate GHDL output with --ieee-asserts=disable-at-0"""
    print_separator()
    print("OPTIMIZED GHDL OUTPUT (--ieee-asserts=disable-at-0)")
    print_separator()
    print()

    output = """Test 1: Reset behavior - PASSED
Test 2: Count up - PASSED
Test 3: Count down - PASSED
Test 4: Load value - PASSED
ALL TESTS PASSED"""

    print(output)
    print()
    lines = output.count('\n') + 1
    tokens = lines * 10  # Simpler output = fewer tokens per line
    print(f"TOTAL OUTPUT: {lines} lines")
    print(f"ESTIMATED TOKENS: ~{tokens} tokens")
    print()


def simulate_filtered_output():
    """Simulate GHDL output with Python filter (aggressive)"""
    print_separator()
    print("FILTERED OUTPUT (--ieee-asserts=disable-at-0 + Python filter)")
    print_separator()
    print()

    output = """Test 1: Reset behavior - PASSED
Test 2: Count up - PASSED
Test 3: Count down - PASSED
Test 4: Load value - PASSED
ALL TESTS PASSED

[GHDL Output Filter - Level: aggressive]
  Total lines: 248
  Filtered: 241 (97.2% reduction)
  - Metavalue warnings: 198
  - Initialization warnings: 12
  - Duplicate warnings: 31"""

    print(output)
    print()
    lines = output.count('\n') + 1
    tokens = lines * 10
    print(f"TOTAL OUTPUT: {lines} lines")
    print(f"ESTIMATED TOKENS: ~{tokens} tokens")
    print()


def main():
    print("\n" + "=" * 70)
    print("GHDL OUTPUT VERBOSITY COMPARISON")
    print("=" * 70)
    print("\nThis demonstrates the impact of GHDL output optimizations")
    print("on LLM context window consumption.")

    simulate_unoptimized_ghdl()
    simulate_optimized_ghdl()
    simulate_filtered_output()

    print_separator()
    print("SUMMARY")
    print_separator()
    print()
    print("Unoptimized:     ~250 lines, ~3750 tokens")
    print("Optimized:       5 lines,    ~50 tokens   (98.7% reduction)")
    print("Filtered:        11 lines,   ~110 tokens  (97.1% reduction)")
    print()
    print("RECOMMENDATIONS:")
    print("1. ALWAYS use: ghdl -r <entity> --ieee-asserts=disable-at-0")
    print("2. For LLMs: Add --assert-level=error")
    print("3. For maximum suppression: Pipe through Python filter")
    print()
    print("COMMAND EXAMPLES:")
    print()
    print("# Basic optimization (recommended)")
    print("ghdl -r my_entity --ieee-asserts=disable-at-0")
    print()
    print("# Maximum optimization (for LLMs)")
    print("ghdl -r my_entity --ieee-asserts=disable-at-0 --assert-level=error \\")
    print("  | python tests/ghdl_output_filter.py --level aggressive")
    print()
    print("# In test runner (automatic)")
    print("export GHDL_FILTER_LEVEL=aggressive")
    print("uv run python tests/run.py my_test")
    print()


if __name__ == "__main__":
    main()
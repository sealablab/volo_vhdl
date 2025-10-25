#!/usr/bin/env python3
"""
CocotB Python Test Runner for Volo VHDL

Replaces Makefile-based test system with native Python runner.
Uses CocotB 2.0+ Python API for build and test orchestration.

Usage:
    python tests/run.py volo_clk_divider              # Run single test
    python tests/run.py --all                        # Run all tests
    python tests/run.py --category=volo_common       # Run category
    python tests/run.py --list                       # List available tests
    python tests/run.py volo_clk_divider --no-waves  # Disable waveforms

Author: Claude Code (CocotB Python Runner Migration)
Date: 2025-01-25
"""

import sys
import argparse
from pathlib import Path
from typing import Optional
import os

# Add tests directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from test_configs import TESTS_CONFIG, get_test_names, get_tests_by_category, get_categories

# CocotB imports
try:
    from cocotb_tools.runner import get_runner
except ImportError:
    print("❌ CocotB tools not found! Install with: uv sync")
    sys.exit(1)


class TestRunner:
    """CocotB test runner using Python API"""

    def __init__(self, waves: bool = True, verbose: bool = False):
        self.waves = waves
        self.verbose = verbose
        self.tests_dir = Path(__file__).parent

    def run_test(self, test_name: str) -> bool:
        """
        Run a single test.
        Returns True if test passed, False otherwise.
        """
        if test_name not in TESTS_CONFIG:
            print(f"❌ Test '{test_name}' not found!")
            print(f"Available tests: {', '.join(get_test_names())}")
            return False

        config = TESTS_CONFIG[test_name]

        print("=" * 70)
        print(f"Running test: {test_name}")
        print(f"Category: {config.category}")
        print(f"Toplevel: {config.toplevel}")
        print(f"Test module: {config.test_module}")
        print("=" * 70)

        # Validate source files exist
        missing_sources = [str(src) for src in config.sources if not src.exists()]
        if missing_sources:
            print(f"❌ Missing source files:")
            for src in missing_sources:
                print(f"  - {src}")
            return False

        # Create GHDL runner
        runner = get_runner("ghdl")

        # Set working directory to tests/
        os.chdir(self.tests_dir)

        # Build configuration
        build_args = config.ghdl_args.copy()

        # Add waveform support
        if self.waves:
            sim_args = ["--wave=dump.ghw"]
        else:
            sim_args = []

        # Set CocotB environment variables
        os.environ["COCOTB_REDUCED_LOG_FMT"] = "1"
        os.environ["COCOTB_LOG_LEVEL"] = "DEBUG" if self.verbose else "INFO"

        try:
            # Build HDL
            print("\n📦 Building HDL sources...")
            runner.build(
                vhdl_sources=[str(src) for src in config.sources],
                hdl_toplevel=config.toplevel,
                always=True,
                build_args=build_args,
            )

            # Run tests
            print("\n🧪 Running CocotB tests...")
            runner.test(
                hdl_toplevel=config.toplevel,
                test_module=config.test_module,
                test_args=sim_args,
            )

            print("\n" + "=" * 70)
            print(f"✅ Test '{test_name}' PASSED")
            print("=" * 70)
            return True

        except Exception as e:
            print("\n" + "=" * 70)
            print(f"❌ Test '{test_name}' FAILED")
            print(f"Error: {e}")
            print("=" * 70)
            return False

    def run_all_tests(self) -> dict:
        """
        Run all configured tests.
        Returns dict of {test_name: passed}
        """
        results = {}
        test_names = get_test_names()

        print(f"\n🚀 Running {len(test_names)} tests...\n")

        for i, test_name in enumerate(test_names, 1):
            print(f"\n[{i}/{len(test_names)}] {test_name}")
            results[test_name] = self.run_test(test_name)

        # Summary
        print("\n" + "=" * 70)
        print("TEST SUMMARY")
        print("=" * 70)

        passed = sum(1 for v in results.values() if v)
        failed = len(results) - passed

        for test_name, passed_flag in results.items():
            status = "✅ PASS" if passed_flag else "❌ FAIL"
            print(f"{status}: {test_name}")

        print("=" * 70)
        print(f"Results: {passed} passed, {failed} failed, {len(results)} total")
        print("=" * 70)

        return results

    def run_category(self, category: str) -> dict:
        """
        Run all tests in a category.
        Returns dict of {test_name: passed}
        """
        tests = get_tests_by_category(category)

        if not tests:
            print(f"❌ Category '{category}' not found!")
            print(f"Available categories: {', '.join(get_categories())}")
            return {}

        print(f"\n🚀 Running {len(tests)} tests in category '{category}'...\n")

        results = {}
        for i, test_name in enumerate(sorted(tests.keys()), 1):
            print(f"\n[{i}/{len(tests)}] {test_name}")
            results[test_name] = self.run_test(test_name)

        # Summary
        passed = sum(1 for v in results.values() if v)
        failed = len(results) - passed

        print("\n" + "=" * 70)
        print(f"Category '{category}': {passed} passed, {failed} failed")
        print("=" * 70)

        return results

    def list_tests(self):
        """List all available tests"""
        print("Available CocotB Tests")
        print("=" * 70)

        for category in get_categories():
            tests = get_tests_by_category(category)
            print(f"\n{category.upper()} ({len(tests)} tests):")
            for test_name in sorted(tests.keys()):
                config = tests[test_name]
                print(f"  - {test_name:30s} ({config.test_module})")

        print("\n" + "=" * 70)
        print(f"Total: {len(TESTS_CONFIG)} tests")
        print("=" * 70)


def main():
    parser = argparse.ArgumentParser(
        description="CocotB Python Test Runner for Volo VHDL",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tests/run.py volo_clk_divider              # Run single test
  python tests/run.py --all                        # Run all tests
  python tests/run.py --category=volo_common       # Run category
  python tests/run.py --list                       # List tests
  python tests/run.py volo_clk_divider --no-waves  # No waveforms
        """,
    )

    parser.add_argument(
        "test_name",
        nargs="?",
        help="Name of test to run (e.g., volo_clk_divider)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Run all tests",
    )
    parser.add_argument(
        "--category",
        type=str,
        help="Run all tests in category (e.g., volo_common, uart, instruments)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all available tests",
    )
    parser.add_argument(
        "--no-waves",
        action="store_true",
        help="Disable waveform generation (faster)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output (DEBUG log level)",
    )

    args = parser.parse_args()

    # Create runner
    runner = TestRunner(waves=not args.no_waves, verbose=args.verbose)

    # Handle commands
    if args.list:
        runner.list_tests()
        return 0

    elif args.all:
        results = runner.run_all_tests()
        # Exit with non-zero if any tests failed
        return 0 if all(results.values()) else 1

    elif args.category:
        results = runner.run_category(args.category)
        return 0 if all(results.values()) else 1

    elif args.test_name:
        success = runner.run_test(args.test_name)
        return 0 if success else 1

    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())

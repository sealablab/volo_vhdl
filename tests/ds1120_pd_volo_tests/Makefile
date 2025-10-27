# DS1120-PD VOLO Test Makefile
# Following VOLO CocotB Testing Standard

# Module configuration
MODULE_NAME = ds1120_pd_volo
TEST_DIR = $(shell pwd)

# Default test level (LLM-optimized)
TEST_LEVEL ?= P1_BASIC

# Verbosity control (minimal by default)
COCOTB_VERBOSITY ?= MINIMAL
export COCOTB_VERBOSITY

# GHDL filtering (aggressive by default)
GHDL_FILTER_LEVEL ?= aggressive
export GHDL_FILTER_LEVEL

# Test targets
.PHONY: all p1 p2 p3 clean help

all: p1

p1:
	@echo "Running P1 Basic Tests (minimal output)..."
	@TEST_LEVEL=P1_BASIC python ../run.py $(MODULE_NAME)

p2:
	@echo "Running P2 Intermediate Tests..."
	@TEST_LEVEL=P2_INTERMEDIATE python ../run.py $(MODULE_NAME)

p3:
	@echo "Running P3 Comprehensive Tests..."
	@TEST_LEVEL=P3_COMPREHENSIVE python ../run.py $(MODULE_NAME)

debug:
	@echo "Running with debug output..."
	@TEST_LEVEL=P3_COMPREHENSIVE COCOTB_VERBOSITY=DEBUG python ../run.py $(MODULE_NAME)

clean:
	@echo "Cleaning test artifacts..."
	@rm -rf __pycache__ *.pyc
	@rm -rf sim_build
	@rm -f *.vcd *.ghw *.xml

help:
	@echo "DS1120-PD VOLO Test Suite"
	@echo ""
	@echo "Usage:"
	@echo "  make        - Run P1 basic tests (default, LLM-friendly)"
	@echo "  make p1     - Run P1 basic tests explicitly"
	@echo "  make p2     - Run P2 intermediate tests"
	@echo "  make p3     - Run P3 comprehensive tests"
	@echo "  make debug  - Run with full debug output"
	@echo "  make clean  - Remove test artifacts"
	@echo ""
	@echo "Environment Variables:"
	@echo "  TEST_LEVEL        - P1_BASIC (default), P2_INTERMEDIATE, P3_COMPREHENSIVE"
	@echo "  COCOTB_VERBOSITY  - SILENT, MINIMAL (default), NORMAL, VERBOSE, DEBUG"
	@echo ""
	@echo "Examples:"
	@echo "  make                                    # Quick P1 test"
	@echo "  make p2                                 # Intermediate tests"
	@echo "  COCOTB_VERBOSITY=VERBOSE make p3       # Comprehensive with details"
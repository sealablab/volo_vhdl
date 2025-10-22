# Makefile for CocotB Tests
# Volo VHDL Project - CocotB Migration
#
# Usage:
#   make                    # Run all tests
#   make MODULE=clk_divider # Run specific module tests
#   make clean              # Clean artifacts
#   make waves              # View waveforms (if GTKWave installed)

# Default simulator
SIM ?= ghdl

# VHDL standard
VHDL_STANDARD = 08

# Project paths
PROJECT_ROOT = ..
MODULES_DIR = $(PROJECT_ROOT)/modules
VOLO_COMMON = $(MODULES_DIR)/volo_common

# GHDL flags
GHDL_ARGS = --std=$(VHDL_STANDARD) --workdir=work

# Waveform options (optional)
WAVES ?= 1
ifeq ($(WAVES),1)
    SIM_ARGS += --wave=dump.ghw
endif

# Default module (if no TEST_MODULE specified)
TEST_MODULE ?= clk_divider_core

# Source files for each module
# clk_divider_core test
ifeq ($(TEST_MODULE),clk_divider_core)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd
    TOPLEVEL = clk_divider_core
    COCOTB_TEST_MODULES = test_clk_divider_core
endif

# moku_pct_pkg test
ifeq ($(TEST_MODULE),moku_pct_pkg)
    VHDL_SOURCES = $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(VOLO_COMMON)/common/Moku_Pct_pkg.vhd \
                   moku_pct_pkg_tb_wrapper.vhd
    TOPLEVEL = moku_pct_pkg_tb_wrapper
    COCOTB_TEST_MODULES = test_moku_pct_pkg
endif


# CocotB configuration
export COCOTB_REDUCED_LOG_FMT=1
export COCOTB_LOG_LEVEL=INFO

# Include CocotB makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: help list-tests clean-all waves

help:
	@echo "Volo VHDL CocotB Test Suite"
	@echo ""
	@echo "Usage:"
	@echo "  make                         - Run tests for default module ($(TEST_MODULE))"
	@echo "  make TEST_MODULE=<name>      - Run tests for specific module"
	@echo "  make list-tests              - List available test modules"
	@echo "  make clean                   - Clean test artifacts"
	@echo "  make waves                   - View waveforms (requires GTKWave)"
	@echo ""
	@echo "Available modules:"
	@echo "  - clk_divider_core     (volo_common/core)"
	@echo "  - moku_pct_pkg         (volo_common/common)"
	@echo ""
	@echo "Environment variables:"
	@echo "  WAVES=1                - Enable waveform dump (default)"
	@echo "  WAVES=0                - Disable waveform dump"
	@echo "  SIM=ghdl               - Simulator (default: ghdl)"
	@echo "  COCOTB_LOG_LEVEL=INFO  - Log level (DEBUG, INFO, WARNING, ERROR)"

list-tests:
	@echo "Available CocotB test modules:"
	@echo "  - test_clk_divider_core.py"
	@echo "  - test_moku_pct_pkg.py"
	@echo ""
	@echo "To add more tests, create test_<module>.py and update this Makefile"

clean-all: clean
	@echo "Cleaning all test artifacts..."
	@rm -rf work/
	@rm -f *.ghw *.vcd
	@rm -f results.xml
	@rm -rf __pycache__/
	@echo "Clean complete"

waves:
	@if [ -f dump.ghw ]; then \
		gtkwave dump.ghw; \
	else \
		echo "No waveform file found. Run tests with WAVES=1 first."; \
	fi

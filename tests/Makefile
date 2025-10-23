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

# moku_voltage_pkg test
ifeq ($(TEST_MODULE),moku_voltage_pkg)
    VHDL_SOURCES = $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   moku_voltage_pkg_tb_wrapper.vhd
    TOPLEVEL = moku_voltage_pkg_tb_wrapper
    COCOTB_TEST_MODULES = test_moku_voltage_pkg
endif

# moku_pct_pkg test
ifeq ($(TEST_MODULE),moku_pct_pkg)
    VHDL_SOURCES = $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(VOLO_COMMON)/common/Moku_Pct_pkg.vhd \
                   moku_pct_pkg_tb_wrapper.vhd
    TOPLEVEL = moku_pct_pkg_tb_wrapper
    COCOTB_TEST_MODULES = test_moku_pct_pkg
endif

# emfi_seq_top test
ifeq ($(TEST_MODULE),emfi_seq_top)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd \
                   $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_fsm.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_stair.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/EMFI_Seq.vhd \
                   $(PROJECT_ROOT)/mcc_templates/CustomWrapper_test_stub.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/Top.vhd
    TOPLEVEL = customwrapper
    COCOTB_TEST_MODULES = test_emfi_seq_top
endif

# mcc_primitives test (uses EMFI-Seq as test vehicle)
ifeq ($(TEST_MODULE),mcc_primitives)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd \
                   $(VOLO_COMMON)/common/Moku_Voltage_pkg.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_fsm.vhd \
                   $(MODULES_DIR)/EMFI-Seq/core/EMFI_Seq_stair.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/EMFI_Seq.vhd \
                   $(PROJECT_ROOT)/mcc_templates/CustomWrapper_test_stub.vhd \
                   $(MODULES_DIR)/EMFI-Seq/top/Top.vhd
    TOPLEVEL = customwrapper
    COCOTB_TEST_MODULES = test_mcc_primitives
endif

# bench_framework_poc test (Phase 1 PoC: simple_counter)
ifeq ($(TEST_MODULE),bench_framework_poc)
    VHDL_SOURCES = $(MODULES_DIR)/simple_counter/core/simple_counter_core.vhd
    TOPLEVEL = simple_counter_core
    COCOTB_TEST_MODULES = test_bench_framework_poc
    export BENCH_FRAMEWORK_PATH=$(PROJECT_ROOT)/tests
endif

# pulsestar test (4-channel calibration generator)
ifeq ($(TEST_MODULE),pulsestar)
    VHDL_SOURCES = $(VOLO_COMMON)/core/clk_divider_core.vhd \
                   $(MODULES_DIR)/PulseStar/datadef/waveform_lut_pkg.vhd \
                   $(MODULES_DIR)/PulseStar/core/waveform_gen_core.vhd \
                   $(MODULES_DIR)/PulseStar/core/trigger_gen_core.vhd \
                   $(MODULES_DIR)/PulseStar/core/uart_tx_core.vhd \
                   $(PROJECT_ROOT)/mcc_templates/CustomWrapper_test_stub.vhd \
                   $(MODULES_DIR)/PulseStar/top/Top.vhd
    TOPLEVEL = customwrapper
    COCOTB_TEST_MODULES = test_pulsestar
endif

# uart_baud_gen test (Volo UART components)
ifeq ($(TEST_MODULE),uart_baud_gen)
    VHDL_SOURCES = $(VOLO_COMMON)/common/volo_uart_pkg.vhd \
                   $(VOLO_COMMON)/core/volo_uart_baud_gen.vhd
    TOPLEVEL = uart_baud_gen
    COCOTB_TEST_MODULES = test_uart_baud_gen
endif

# uart_tx_core test (Volo UART components)
ifeq ($(TEST_MODULE),uart_tx_core)
    VHDL_SOURCES = $(VOLO_COMMON)/common/volo_uart_pkg.vhd \
                   $(VOLO_COMMON)/core/volo_uart_baud_gen.vhd \
                   $(VOLO_COMMON)/core/volo_uart_tx_core.vhd
    TOPLEVEL = uart_tx_core
    COCOTB_TEST_MODULES = test_uart_tx_core
endif


# CocotB configuration
export COCOTB_REDUCED_LOG_FMT=1
export COCOTB_LOG_LEVEL=INFO

# Include CocotB makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: help list-tests test-all clean-all waves

# Run all tests sequentially
test-all:
	@echo "======================================================================="
	@echo "Running ALL CocotB Tests"
	@echo "======================================================================="
	@echo ""
	@$(MAKE) TEST_MODULE=clk_divider_core
	@echo ""
	@echo "======================================================================="
	@echo ""
	@$(MAKE) TEST_MODULE=moku_voltage_pkg
	@echo ""
	@echo "======================================================================="
	@echo ""
	@$(MAKE) TEST_MODULE=moku_pct_pkg
	@echo ""
	@echo "======================================================================="
	@echo ""
	@$(MAKE) TEST_MODULE=emfi_seq_top
	@echo ""
	@echo "======================================================================="
	@echo "All tests complete!"
	@echo "======================================================================="

help:
	@echo "Volo VHDL CocotB Test Suite"
	@echo ""
	@echo "Usage:"
	@echo "  make                         - Run tests for default module ($(TEST_MODULE))"
	@echo "  make test-all                - Run ALL test modules sequentially"
	@echo "  make TEST_MODULE=<name>      - Run tests for specific module"
	@echo "  make list-tests              - List available test modules"
	@echo "  make clean                   - Clean test artifacts"
	@echo "  make waves                   - View waveforms (requires GTKWave)"
	@echo ""
	@echo "Available modules:"
	@echo "  - clk_divider_core     (volo_common/core)"
	@echo "  - moku_voltage_pkg     (volo_common/common)"
	@echo "  - moku_pct_pkg         (volo_common/common)"
	@echo "  - emfi_seq_top         (EMFI-Seq/top)"
	@echo "  - bench_framework_poc  (Bench Framework Phase 1 PoC)"
	@echo ""
	@echo "Environment variables:"
	@echo "  WAVES=1                - Enable waveform dump (default)"
	@echo "  WAVES=0                - Disable waveform dump"
	@echo "  SIM=ghdl               - Simulator (default: ghdl)"
	@echo "  COCOTB_LOG_LEVEL=INFO  - Log level (DEBUG, INFO, WARNING, ERROR)"

list-tests:
	@echo "Available CocotB test modules:"
	@echo "  - test_clk_divider_core.py       (7 tests)"
	@echo "  - test_moku_voltage_pkg.py       (3 tests)"
	@echo "  - test_moku_pct_pkg.py           (9 tests)"
	@echo "  - test_emfi_seq_top.py           (8 tests)"
	@echo "  - test_bench_framework_poc.py    (6 tests - Phase 1 PoC)"
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

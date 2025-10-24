# Makefile for volo_encoder_core CocotB tests

# Defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
WAVES ?= 1

# VHDL source files
VHDL_SOURCES = $(PWD)/../../modules/volo_encoder/core/volo_encoder_core.vhd

# Testbench settings
MODULE = test_volo_encoder_core
TOPLEVEL = volo_encoder_core

# GHDL settings
GHDL_ARGS = --std=08

# Waveform settings
ifeq ($(WAVES),1)
    EXTRA_ARGS += --wave=$(TOPLEVEL).ghw
    SIM_ARGS += --wave=$(TOPLEVEL).ghw
endif

# CocotB settings
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

include $(shell cocotb-config --makefiles)/Makefile.sim

# Clean target
clean::
	@rm -rf __pycache__ .pytest_cache results.xml
	@rm -rf *.ghw *.o *.cf work-obj08.cf
	@rm -rf sim_build

# List tests
list-tests:
	@echo "Available tests in $(MODULE):"
	@grep -E "^async def test_" test_*.py | sed 's/async def /  - /' | sed 's/(dut)://'

.PHONY: clean list-tests

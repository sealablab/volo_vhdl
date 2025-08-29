# SimpleWaveGen Module Makefile
# Follows Volo VHDL project standards for automatic integration

# This Makefile integrates with the central modules/Makefile
# Run 'make' from modules/ directory to build all modules with dependencies
# Run 'make' from this directory to build just this module

# Module-specific variables
MODULE_NAME := SimpleWaveGen

# Standard targets that integrate with central build system
.PHONY: all compile test clean help

# Default target
all: compile

# Compile target - delegates to central build system
compile:
	@echo "=== Compiling $(MODULE_NAME) Module ==="
	@cd .. && $(MAKE) compile-single-module MODULE_NAME=$(MODULE_NAME)

# Test target - delegates to central build system  
test: compile
	@echo "=== Testing $(MODULE_NAME) Module ==="
	@cd .. && $(MAKE) test-local MODULE_DIR=$(shell pwd)

# Clean target - removes local compilation artifacts
clean: clean-local

# Local clean target (required by central build system)
clean-local:
	@echo "=== Cleaning $(MODULE_NAME) Module ==="
	@rm -f work-obj*.cf
	@rm -f *_tb
	@rm -f *.o
	@rm -f *.exe
	@echo "=== Module Clean Complete ==="

# Help target
help:
	@echo "$(MODULE_NAME) Module Makefile"
	@echo ""
	@echo "This module integrates with the central build system."
	@echo "Run 'make' from the modules/ directory to build all modules."
	@echo ""
	@echo "Available targets:"
	@echo "  make clean                    - Remove compilation artifacts"
	@echo "  make                          - Compile module (delegates to central system)"
	@echo "  make compile                  - Same as 'make'"
	@echo "  make test                     - Run testbenches (delegates to central system)"
	@echo "  make help                     - Show this help message"
	@echo ""
	@echo "Module structure:"
	@echo "  - common/: platform_interface_pkg.vhd"
	@echo "  - core/: SimpleWaveGen_core.vhd"
	@echo "  - top/: SimpleWaveGen_top.vhd, SimpleWaveGen_customwrapper.vhd"
	@echo "  - tb/: Testbenches for core and top layers"
	@echo ""
	@echo "Dependencies: clk_divider (shared module)"
	@echo ""
	@echo "Example usage:"
	@echo "  cd modules && make clean && make && make test"

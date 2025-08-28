# Makefile for Probe Driver Module
# Provides traditional make workflow: make clean; make; make test

# GHDL compiler settings
GHDL = ghdl
GHDL_FLAGS = --std=08
GHDL_ANALYZE = $(GHDL) -a $(GHDL_FLAGS)
GHDL_ELABORATE = $(GHDL) -e $(GHDL_FLAGS)
GHDL_RUN = $(GHDL) -r $(GHDL_FLAGS)

# Directories
COMMON_DIR = common
DATADEF_DIR = datadef
CORE_DIR = core
TOP_DIR = top
TB_DIR = tb

# Source files
COMMON_SOURCES = $(wildcard $(COMMON_DIR)/*.vhd)
DATADEF_SOURCES = $(wildcard $(DATADEF_DIR)/*.vhd)
CORE_SOURCES = $(wildcard $(CORE_DIR)/*.vhd)
TOP_SOURCES = $(filter-out %_example.vhd,$(wildcard $(TOP_DIR)/*.vhd))

# Testbench files
TB_COMMON_SOURCES = $(wildcard $(TB_DIR)/common/*.vhd)
TB_DATADEF_SOURCES = $(wildcard $(TB_DIR)/datadef/*.vhd)
TB_CORE_SOURCES = $(wildcard $(TB_DIR)/core/*.vhd)
TB_TOP_SOURCES = $(wildcard $(TB_DIR)/top/*.vhd)

# All testbench sources
TB_SOURCES = $(TB_COMMON_SOURCES) $(TB_DATADEF_SOURCES) $(TB_CORE_SOURCES) $(TB_TOP_SOURCES)

# Default target
all: compile

# Compilation target
compile:
	@echo "=== Compiling Probe Driver Module ==="
	@echo "Compiling common packages..."
	@$(GHDL_ANALYZE) $(COMMON_SOURCES)
	@echo "Compiling datadef packages..."
	@$(GHDL_ANALYZE) $(DATADEF_SOURCES)
	@echo "Compiling core modules..."
	@if [ -n "$(CORE_SOURCES)" ]; then \
		$(GHDL_ANALYZE) $(CORE_SOURCES); \
	else \
		echo "  No core modules found - skipping core compilation"; \
	fi
	@echo "Compiling top-level interface module..."
	@$(GHDL_ANALYZE) $(TOP_SOURCES)
	@echo "Compiling testbenches..."
	@if [ -n "$(TB_COMMON_SOURCES)" ]; then $(GHDL_ANALYZE) $(TB_COMMON_SOURCES); fi
	@if [ -n "$(TB_DATADEF_SOURCES)" ]; then $(GHDL_ANALYZE) $(TB_DATADEF_SOURCES); fi
	@if [ -n "$(TB_CORE_SOURCES)" ]; then $(GHDL_ANALYZE) $(TB_CORE_SOURCES); fi
	@if [ -n "$(TB_TOP_SOURCES)" ]; then $(GHDL_ANALYZE) $(TB_TOP_SOURCES); fi
	@echo "=== Compilation Complete ==="

# Test target
test: compile
	@echo "=== Running Testbenches ==="
	@echo "Running probe_driver_interface testbench..."
	@$(GHDL_ELABORATE) probe_driver_interface_tb
	@$(GHDL_RUN) probe_driver_interface_tb
	@echo "Running PercentLut_pkg testbench..."
	@$(GHDL_ELABORATE) PercentLut_pkg_tb
	@$(GHDL_RUN) PercentLut_pkg_tb
	@echo "Running Moku_Voltage_pkg testbench..."
	@$(GHDL_ELABORATE) Moku_Voltage_pkg_tb
	@$(GHDL_RUN) Moku_Voltage_pkg_tb
	@echo "=== All Tests Completed ==="

# Individual test targets
test-probe_driver_interface: compile
	@echo "=== Running probe_driver_interface Testbench ==="
	@$(GHDL_ELABORATE) probe_driver_interface_tb
	@$(GHDL_RUN) probe_driver_interface_tb
	@echo "=== Test Completed ==="

test-PercentLut_pkg: compile
	@echo "=== Running PercentLut_pkg Testbench ==="
	@$(GHDL_ELABORATE) PercentLut_pkg_tb
	@$(GHDL_RUN) PercentLut_pkg_tb
	@echo "=== Test Completed ==="

test-Moku_Voltage_pkg: compile
	@echo "=== Running Moku_Voltage_pkg Testbench ==="
	@$(GHDL_ELABORATE) Moku_Voltage_pkg_tb
	@$(GHDL_RUN) Moku_Voltage_pkg_tb
	@echo "=== Test Completed ==="

# Clean target
clean:
	@echo "=== Cleaning Compilation Artifacts ==="
	@rm -f work-obj*.cf
	@rm -f *_tb
	@rm -f *.o
	@rm -f *.exe
	@echo "=== Clean Complete ==="

# Help target
help:
	@echo "Probe Driver Module Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make clean                    - Remove all compilation artifacts"
	@echo "  make                          - Compile all modules and testbenches"
	@echo "  make compile                  - Same as 'make'"
	@echo "  make test                     - Run all available testbenches"
	@echo "  make test-probe_driver_interface - Run probe_driver_interface testbench"
	@echo "  make test-PercentLut_pkg      - Run PercentLut_pkg testbench"
	@echo "  make test-Moku_Voltage_pkg    - Run Moku_Voltage_pkg testbench"
	@echo "  make help                     - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make clean && make && make test"
	@echo "  make test-probe_driver_interface"
	@echo ""
	@echo "Note: The 'assertion failed' message at the end of tests is expected - it terminates the simulation."

# Quick test (compile and run main testbench only)
quick-test: compile
	@echo "=== Running Quick Test (probe_driver_interface) ==="
	@$(GHDL_ELABORATE) probe_driver_interface_tb
	@$(GHDL_RUN) probe_driver_interface_tb
	@echo "=== Quick Test Completed ==="

# Force rebuild of everything
rebuild: clean compile

# Show available testbenches
list-tests:
	@echo "Available testbenches:"
	@echo "  - probe_driver_interface_tb"
	@echo "  - PercentLut_pkg_tb"
	@echo "  - Moku_Voltage_pkg_tb"

# Show source files
list-sources:
	@echo "Source files:"
	@echo "  Common: $(COMMON_SOURCES)"
	@echo "  Datadef: $(DATADEF_SOURCES)"
	@echo "  Core: $(CORE_SOURCES)"
	@echo "  Top: $(TOP_SOURCES)"
	@echo "  Testbenches: $(TB_SOURCES)"

.PHONY: all compile test clean help quick-test rebuild list-tests list-sources
.PHONY: test-probe_driver_interface test-PercentLut_pkg test-Moku_Voltage_pkg
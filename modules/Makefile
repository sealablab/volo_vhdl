# Central Makefile for Volo VHDL Modules
# Provides hierarchical build system for all modules with dependency support

# GHDL compiler settings
GHDL = ghdl
GHDL_FLAGS = --std=08
GHDL_ANALYZE = $(GHDL) -a $(GHDL_FLAGS)
GHDL_ELABORATE = $(GHDL) -e $(GHDL_FLAGS)
GHDL_RUN = $(GHDL) -r $(GHDL_FLAGS)

# Include dependency configuration (optional)
-include Makefile.deps

# Detect current directory level and module context
CURRENT_DIR := $(shell pwd)
# Set MODULES_ROOT to the directory containing this central Makefile
MODULES_ROOT := /Users/johnycsh/volo_codes/volo_vhdl/modules
PROJECT_ROOT := $(shell dirname $(MODULES_ROOT))

# Determine if we're in a specific module directory
# Check if we're at the modules/ level by comparing current dir with modules root
ifeq ($(CURRENT_DIR),$(MODULES_ROOT))
    # We're at modules/ level - build all modules
    BUILD_MODE := all_modules
    MODULE_NAME := 
else
    # We're in a specific module - extract module name
    MODULE_NAME := $(shell basename $(CURRENT_DIR))
    BUILD_MODE := single_module
endif

# Module directories (only include directories that have Makefiles, and only when at modules/ level)
ifeq ($(BUILD_MODE),all_modules)
    # Use dependency-defined build order if available, otherwise auto-detect
    ifdef MODULE_BUILD_ORDER
        MODULE_DIRS := $(addsuffix /,$(MODULE_BUILD_ORDER))
    else
        MODULE_DIRS := $(shell for dir in */; do if [ -f "$$dir/Makefile" ] && [ "$$dir" != "tb/" ]; then echo "$$dir"; fi; done)
    endif
else
    MODULE_DIRS := 
endif

# MCC template directory
MCC_TEMPLATE_DIR = $(PROJECT_ROOT)/mcc_templates

# Function to get source files for a module
define get_module_sources
$(1)/common/*.vhd $(1)/datadef/*.vhd $(1)/core/*.vhd $(wildcard $(1)/top/*.vhd)
endef

# Function to get testbench files for a module
define get_module_tb_sources
$(wildcard $(1)/tb/common/*.vhd) $(wildcard $(1)/tb/datadef/*.vhd) $(wildcard $(1)/tb/core/*.vhd) $(wildcard $(1)/tb/top/*.vhd)
endef

# Default target
all: compile

# Compilation target - behavior depends on current directory
compile:
ifeq ($(BUILD_MODE),all_modules)
	@echo "=== Compiling All Modules (with dependencies) ==="
	@$(MAKE) compile-with-deps
	@echo "=== All Modules Compilation Complete ==="
else
	@echo "=== Compiling Module: $(MODULE_NAME) ==="
	@$(MAKE) compile-local MODULE_DIR=$(CURRENT_DIR)
endif

# Compile modules with dependency resolution using unified work library
compile-with-deps:
	@echo "Building modules with unified work library..."
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Building shared modules first..."
	@for module in $(SHARED_MODULES); do \
		if [ -d "$$module/" ]; then \
			echo "Building shared module: $$module"; \
			if [ -n "$$(ls $$module/common/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/common/*.vhd; \
			fi; \
			if [ -n "$$(ls $$module/datadef/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/datadef/*.vhd; \
			fi; \
			if [ -n "$$(ls $$module/core/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/core/*.vhd; \
			fi; \
		fi; \
	done
	@echo "Building dependent modules..."
	@for module in $(MODULE_DIRS); do \
		if [ -d "$$module" ] && [ -f "$$module/Makefile" ]; then \
			module_name=$$(basename $$module); \
			if [ "$$module_name" != "$(firstword $(SHARED_MODULES))" ]; then \
				echo "Compiling module: $$module"; \
				if [ -n "$$(ls $$module/common/*.vhd 2>/dev/null)" ]; then \
					$(GHDL_ANALYZE) $$module/common/*.vhd; \
				fi; \
				if [ -n "$$(ls $$module/datadef/*.vhd 2>/dev/null)" ]; then \
					$(GHDL_ANALYZE) $$module/datadef/*.vhd; \
				fi; \
				if [ -n "$$(ls $$module/core/*.vhd 2>/dev/null)" ]; then \
					$(GHDL_ANALYZE) $$module/core/*.vhd; \
				fi; \
				if [ -n "$$(ls $$module/top/*.vhd 2>/dev/null)" ]; then \
					for file in $$module/top/*.vhd; do \
						if [[ "$$file" != *"_example.vhd" ]] && [[ "$$file" != *"_customwrapper.vhd" ]]; then \
							$(GHDL_ANALYZE) "$$file"; \
						fi; \
					done; \
				fi; \
				if [ -n "$$(ls $$module/tb/*/*.vhd 2>/dev/null)" ]; then \
					$(GHDL_ANALYZE) $$module/tb/*/*.vhd; \
				fi; \
				echo ""; \
			fi; \
		fi; \
	done

# Compile a specific module (local version to avoid recursion)
compile-local:
	@echo "Compiling module with dependency support..."
	@echo "Using unified work library from modules directory..."
	@cd $(MODULES_ROOT) && $(MAKE) compile-single-module MODULE_NAME=$(MODULE_NAME)

# Compile a single module from the modules directory (for individual module builds)
compile-single-module:
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Building shared modules first..."
	@for module in $(SHARED_MODULES); do \
		if [ -d "$$module/" ]; then \
			echo "Building shared module: $$module"; \
			if [ -n "$$(ls $$module/common/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/common/*.vhd; \
			fi; \
			if [ -n "$$(ls $$module/datadef/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/datadef/*.vhd; \
			fi; \
			if [ -n "$$(ls $$module/core/*.vhd 2>/dev/null)" ]; then \
				$(GHDL_ANALYZE) $$module/core/*.vhd; \
			fi; \
		fi; \
	done
	@echo "Compiling target module: $(MODULE_NAME)..."
	@echo "Compiling common packages..."
	@if [ -n "$$(ls $(MODULE_NAME)/common/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) $(MODULE_NAME)/common/*.vhd; \
	else \
		echo "  No common packages found - skipping common compilation"; \
	fi
	@echo "Compiling datadef packages..."
	@if [ -n "$$(ls $(MODULE_NAME)/datadef/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) $(MODULE_NAME)/datadef/*.vhd; \
	else \
		echo "  No datadef packages found - skipping datadef compilation"; \
	fi
	@echo "Compiling core modules..."
	@if [ -n "$$(ls $(MODULE_NAME)/core/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) $(MODULE_NAME)/core/*.vhd; \
	else \
		echo "  No core modules found - skipping core compilation"; \
	fi
	@echo "Compiling top modules..."
	@if [ -n "$$(ls $(MODULE_NAME)/top/*.vhd 2>/dev/null)" ]; then \
		for file in $(MODULE_NAME)/top/*.vhd; do \
			if [[ "$$file" != *"_example.vhd" ]] && [[ "$$file" != *"_customwrapper.vhd" ]]; then \
				$(GHDL_ANALYZE) "$$file"; \
			fi; \
		done; \
	else \
		echo "  No top modules found - skipping top compilation"; \
	fi
	@echo "Compiling testbenches..."
	@if [ -n "$$(ls $(MODULE_NAME)/tb/common/*.vhd 2>/dev/null)" ]; then $(GHDL_ANALYZE) $(MODULE_NAME)/tb/common/*.vhd; fi
	@if [ -n "$$(ls $(MODULE_NAME)/tb/datadef/*.vhd 2>/dev/null)" ]; then $(GHDL_ANALYZE) $(MODULE_NAME)/tb/datadef/*.vhd; fi
	@if [ -n "$$(ls $(MODULE_NAME)/tb/core/*.vhd 2>/dev/null)" ]; then $(GHDL_ANALYZE) $(MODULE_NAME)/tb/core/*.vhd; fi
	@if [ -n "$$(ls $(MODULE_NAME)/tb/top/*.vhd 2>/dev/null)" ]; then $(GHDL_ANALYZE) $(MODULE_NAME)/tb/top/*.vhd; fi
	@echo "=== Module Compilation Complete ==="

# Compile a module as a shared library (for cross-module dependencies)
compile-shared:
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Compiling common packages..."
	@if [ -n "$(wildcard $(MODULE_DIR)/common/*.vhd)" ]; then \
		$(GHDL_ANALYZE) $(wildcard $(MODULE_DIR)/common/*.vhd); \
	else \
		echo "  No common packages found - skipping common compilation"; \
	fi
	@echo "Compiling datadef packages..."
	@if [ -n "$(wildcard $(MODULE_DIR)/datadef/*.vhd)" ]; then \
		$(GHDL_ANALYZE) $(wildcard $(MODULE_DIR)/datadef/*.vhd); \
	else \
		echo "  No datadef packages found - skipping datadef compilation"; \
	fi
	@echo "Compiling core modules (shared)..."
	@if [ -n "$(wildcard $(MODULE_DIR)/core/*.vhd)" ]; then \
		$(GHDL_ANALYZE) $(wildcard $(MODULE_DIR)/core/*.vhd); \
	else \
		echo "  No core modules found - skipping core compilation"; \
	fi
	@echo "=== Shared Module Compilation Complete ==="

# Test target - behavior depends on current directory
test: compile
ifeq ($(BUILD_MODE),all_modules)
	@echo "=== Running Tests for All Modules ==="
	@for module in $(MODULE_DIRS); do \
		if [ -d "$$module" ] && [ -f "$$module/Makefile" ]; then \
			echo "Testing module: $$module"; \
			module_dir=$$(pwd)/$$module; \
			$(MAKE) -C $$module test-local MODULE_DIR=$$module_dir; \
			echo ""; \
		fi; \
	done
	@echo "=== All Module Tests Complete ==="
else
	@echo "=== Running Tests for Module: $(MODULE_NAME) ==="
	@$(MAKE) test-local MODULE_DIR=$(CURRENT_DIR)
endif

# Test a specific module (local version to avoid recursion)
test-local:
	@echo "Running available testbenches..."
	@for tb_file in $(wildcard $(MODULE_DIR)/tb/*/*_tb.vhd); do \
		tb_name=$$(basename $$tb_file .vhd); \
		echo "Running $$tb_name..."; \
		$(GHDL_ELABORATE) $$tb_name; \
		$(GHDL_RUN) $$tb_name; \
	done
	@echo "=== Module Tests Complete ==="

# Clean target - behavior depends on current directory
clean:
ifeq ($(BUILD_MODE),all_modules)
	@echo "=== Cleaning All Modules ==="
	@for module in $(MODULE_DIRS); do \
		if [ -d "$$module" ] && [ -f "$$module/Makefile" ]; then \
			echo "Cleaning module: $$module"; \
			module_dir=$$(pwd)/$$module; \
			$(MAKE) -C $$module clean-local MODULE_DIR=$$module_dir; \
		fi; \
	done
	@echo "=== All Modules Clean Complete ==="
else
	@echo "=== Cleaning Module: $(MODULE_NAME) ==="
	@$(MAKE) clean-local
endif

# Local clean target (no recursion)
clean-local:
	@rm -f work-obj*.cf
	@rm -f *_tb
	@rm -f *.o
	@rm -f *.exe
	@echo "=== Module Clean Complete ==="

# Help target - adapts based on current directory
help:
ifeq ($(BUILD_MODE),all_modules)
	@echo "Volo VHDL Modules Makefile"
	@echo ""
	@echo "Current directory: $(CURRENT_DIR)"
	@echo "Build mode: $(BUILD_MODE)"
	@echo ""
	@echo "Available targets:"
	@echo "  make clean                    - Remove all compilation artifacts"
	@echo "  make                          - Compile all modules/testbenches (with dependencies)"
	@echo "  make compile                  - Same as 'make'"
	@echo "  make compile-with-deps        - Compile with dependency resolution"
	@echo "  make test                     - Run all available testbenches"
	@echo "  make help                     - Show this help message"
	@echo ""
	@echo "Dependency features:"
	@echo "  - Shared modules (clk_divider) are built first"
	@echo "  - Dependent modules can reference shared module entities"
	@echo "  - Build order is defined in Makefile.deps"
	@echo ""
	@echo "Example usage:"
	@echo "  make clean && make && make test"
else
	@echo "$(MODULE_NAME) Module Makefile"
	@echo ""
	@echo "Current directory: $(CURRENT_DIR)"
	@echo "Build mode: $(BUILD_MODE)"
	@echo "Module name: $(MODULE_NAME)"
	@echo ""
	@echo "Standard targets:"
	@echo "  make clean                    - Remove all compilation artifacts"
	@echo "  make                          - Compile all modules and testbenches"
	@echo "  make compile                  - Same as 'make'"
	@echo "  make test                     - Run all available testbenches"
	@echo "  make help                     - Show this help message"
	@echo ""
	@echo "Module-specific targets:"
	@$(MAKE) show-module-targets
	@echo ""
	@echo "Example usage:"
	@echo "  make clean && make && make test"
endif

# Individual module targets (for use from modules/ level)
$(MODULE_DIRS):
	@echo "=== Building Module: $@ ==="
	@$(MAKE) -C $@ compile

# List available modules
list-modules:
	@echo "Available modules:"
	@for module in $(MODULE_DIRS); do \
		echo "  - $$module"; \
	done

# Show source files for current module
list-sources:
ifeq ($(BUILD_MODE),single_module)
	@echo "Source files for $(MODULE_NAME):"
	@echo "  Common: $(wildcard $(CURRENT_DIR)/common/*.vhd)"
	@echo "  Datadef: $(wildcard $(CURRENT_DIR)/datadef/*.vhd)"
	@echo "  Core: $(wildcard $(CURRENT_DIR)/core/*.vhd)"
	@echo "  Top: $(wildcard $(CURRENT_DIR)/top/*.vhd)"
	@echo "  Testbenches: $(wildcard $(CURRENT_DIR)/tb/*/*.vhd)"
else
	@echo "Use 'make list-sources' from within a specific module directory"
endif

# Show module-specific targets
show-module-targets:
ifeq ($(MODULE_NAME),probe_driver)
	@echo "  make compile-basic            - Compile basic packages and modules only"
	@echo "  make test-probe_driver_interface - Run probe_driver_interface testbench"
	@echo "  make test-PercentLut_pkg      - Run PercentLut_pkg testbench"
	@echo "  make test-Moku_Voltage_pkg    - Run Moku_Voltage_pkg testbench"
	@echo "  make quick-test               - Compile and run main testbench only"
	@echo "  make list-tests               - Show available testbenches"
else
	@echo "  (No module-specific targets defined)"
endif

# Module-specific targets (only available when in the right module directory)
ifeq ($(MODULE_NAME),probe_driver)
# Additional module-specific targets for probe_driver
compile-basic:
	@echo "=== Compiling Basic Probe Driver Components ==="
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Compiling common packages..."
	@if [ -n "$$(ls common/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) common/*.vhd; \
	fi
	@echo "Compiling datadef packages..."
	@if [ -n "$$(ls datadef/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) datadef/*.vhd; \
	fi
	@echo "Compiling core modules..."
	@if [ -n "$$(ls core/*.vhd 2>/dev/null)" ]; then \
		$(GHDL_ANALYZE) core/*.vhd; \
	else \
		echo "  No core modules found - skipping core compilation"; \
	fi
	@echo "=== Basic Compilation Complete ==="

# Individual test targets for specific testbenches
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

# Quick test (compile and run main testbench only)
quick-test: compile
	@echo "=== Running Quick Test (probe_driver_interface) ==="
	@$(GHDL_ELABORATE) probe_driver_interface_tb
	@$(GHDL_RUN) probe_driver_interface_tb
	@echo "=== Quick Test Completed ==="

# Show available testbenches
list-tests:
	@echo "Available testbenches:"
	@echo "  - probe_driver_interface_tb"
	@echo "  - PercentLut_pkg_tb"
	@echo "  - Moku_Voltage_pkg_tb"
endif

.PHONY: all compile compile-local compile-shared compile-with-deps compile-single-module test test-local clean clean-local help list-modules list-sources show-module-targets $(MODULE_DIRS)
.PHONY: compile-basic test-probe_driver_interface test-PercentLut_pkg test-Moku_Voltage_pkg quick-test list-tests
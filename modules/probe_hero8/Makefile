# Makefile for ProbeHero8 Module
# Enhanced datadef packages with comprehensive unit hinting and validation
# Includes central makefile logic for hierarchical builds

# Include the central makefile from the modules directory
include ../Makefile

# Module-specific overrides and additional targets
# The central makefile handles all the standard targets (compile, test, clean, etc.)
# and provides context-aware help messages with module-specific targets

# ProbeHero8 specific configuration
MODULE_NAME := probe_hero8
ENHANCED_DATADEF := true

# Enhanced datadef packages (probe_hero8 specific)
DATADEF_PACKAGES := \
	Probe_Config_pkg_en \
	Moku_Voltage_pkg_en \
	PercentLut_pkg_en \
	Global_Probe_Table_pkg_en

# Core modules
CORE_MODULES := \
	probe_hero8_core \
	probe_hero8_core_detailed

# Top modules  
TOP_MODULES := \
	probe_hero8_top \
	probe_hero8_top_detailed

# Testbenches
TESTBENCHES := \
	probe_hero8_core_tb \
	probe_hero8_core_detailed_tb \
	probe_hero8_top_tb \
	probe_hero8_top_detailed_tb

# Module-specific targets (only available when in the probe_hero8 directory)
ifeq ($(MODULE_NAME),probe_hero8)

# Enhanced datadef compilation (with dependency order)
compile-datadef:
	@echo "=== Compiling Enhanced Datadef Packages ==="
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Compiling Probe_Config_pkg_en..."
	@$(GHDL_ANALYZE) datadef/Probe_Config_pkg_en.vhd
	@echo "Compiling Moku_Voltage_pkg_en..."
	@$(GHDL_ANALYZE) datadef/Moku_Voltage_pkg_en.vhd
	@echo "Compiling PercentLut_pkg_en..."
	@$(GHDL_ANALYZE) datadef/PercentLut_pkg_en.vhd
	@echo "Compiling Global_Probe_Table_pkg_en..."
	@$(GHDL_ANALYZE) datadef/Global_Probe_Table_pkg_en.vhd
	@echo "=== Enhanced Datadef Compilation Complete ==="

# Core modules compilation
compile-core: compile-datadef
	@echo "=== Compiling Core Modules ==="
	@echo "Compiling probe_hero8_core..."
	@$(GHDL_ANALYZE) core/probe_hero8_core.vhd
	@echo "Compiling probe_hero8_core_detailed..."
	@$(GHDL_ANALYZE) core/probe_hero8_core_detailed.vhd
	@echo "=== Core Modules Compilation Complete ==="

# Top modules compilation
compile-top: compile-core
	@echo "=== Compiling Top Modules ==="
	@echo "Compiling probe_hero8_top..."
	@$(GHDL_ANALYZE) top/probe_hero8_top.vhd
	@echo "Compiling probe_hero8_top_detailed..."
	@$(GHDL_ANALYZE) top/probe_hero8_top_detailed.vhd
	@echo "=== Top Modules Compilation Complete ==="

# Testbenches compilation
compile-testbenches: compile-top
	@echo "=== Compiling Testbenches ==="
	@echo "Compiling core testbenches..."
	@$(GHDL_ANALYZE) tb/core/probe_hero8_core_tb.vhd
	@$(GHDL_ANALYZE) tb/core/probe_hero8_core_detailed_tb.vhd
	@echo "Compiling top testbenches..."
	@$(GHDL_ANALYZE) tb/top/probe_hero8_top_tb.vhd
	@$(GHDL_ANALYZE) tb/top/probe_hero8_top_detailed_tb.vhd
	@echo "=== Testbenches Compilation Complete ==="

# Individual test targets for specific testbenches
test-core: compile-testbenches
	@echo "=== Running Core Testbenches ==="
	@echo "Running probe_hero8_core_tb..."
	@$(GHDL_ELABORATE) probe_hero8_core_tb
	@$(GHDL_RUN) probe_hero8_core_tb
	@echo "Running probe_hero8_core_detailed_tb..."
	@$(GHDL_ELABORATE) probe_hero8_core_detailed_tb
	@$(GHDL_RUN) probe_hero8_core_detailed_tb
	@echo "=== Core Tests Complete ==="

test-top: compile-testbenches
	@echo "=== Running Top Testbenches ==="
	@echo "Running probe_hero8_top_tb..."
	@$(GHDL_ELABORATE) probe_hero8_top_tb
	@$(GHDL_RUN) probe_hero8_top_tb
	@echo "Running probe_hero8_top_detailed_tb..."
	@$(GHDL_ELABORATE) probe_hero8_top_detailed_tb
	@$(GHDL_RUN) probe_hero8_top_detailed_tb
	@echo "=== Top Tests Complete ==="

# Individual testbench targets
test-probe_hero8_core_tb: compile-testbenches
	@echo "=== Running probe_hero8_core_tb ==="
	@$(GHDL_ELABORATE) probe_hero8_core_tb
	@$(GHDL_RUN) probe_hero8_core_tb
	@echo "=== Test Completed ==="

test-probe_hero8_core_detailed_tb: compile-testbenches
	@echo "=== Running probe_hero8_core_detailed_tb ==="
	@$(GHDL_ELABORATE) probe_hero8_core_detailed_tb
	@$(GHDL_RUN) probe_hero8_core_detailed_tb
	@echo "=== Test Completed ==="

test-probe_hero8_top_tb: compile-testbenches
	@echo "=== Running probe_hero8_top_tb ==="
	@$(GHDL_ELABORATE) probe_hero8_top_tb
	@$(GHDL_RUN) probe_hero8_top_tb
	@echo "=== Test Completed ==="

test-probe_hero8_top_detailed_tb: compile-testbenches
	@echo "=== Running probe_hero8_top_detailed_tb ==="
	@$(GHDL_ELABORATE) probe_hero8_top_detailed_tb
	@$(GHDL_RUN) probe_hero8_top_detailed_tb
	@echo "=== Test Completed ==="

# Quick test (compile and run main testbench only)
quick-test: compile-testbenches
	@echo "=== Running Quick Test (probe_hero8_core_tb) ==="
	@$(GHDL_ELABORATE) probe_hero8_core_tb
	@$(GHDL_RUN) probe_hero8_core_tb
	@echo "=== Quick Test Completed ==="

# Enhanced validation test (run detailed testbench)
validation-test: compile-testbenches
	@echo "=== Running Validation Test (probe_hero8_core_detailed_tb) ==="
	@$(GHDL_ELABORATE) probe_hero8_core_detailed_tb
	@$(GHDL_RUN) probe_hero8_core_detailed_tb
	@echo "=== Validation Test Completed ==="

# Show available testbenches
list-tests:
	@echo "Available testbenches:"
	@echo "  - probe_hero8_core_tb (basic core functionality)"
	@echo "  - probe_hero8_core_detailed_tb (comprehensive core validation)"
	@echo "  - probe_hero8_top_tb (basic top integration)"
	@echo "  - probe_hero8_top_detailed_tb (comprehensive top validation)"

# Show enhanced datadef packages
list-datadef:
	@echo "Enhanced datadef packages:"
	@echo "  - Probe_Config_pkg_en (probe configuration with unit hinting)"
	@echo "  - Moku_Voltage_pkg_en (voltage conversion with unit hinting)"
	@echo "  - PercentLut_pkg_en (lookup table with unit hinting)"
	@echo "  - Global_Probe_Table_pkg_en (global probe table with unit hinting)"

# Show module structure
list-structure:
	@echo "ProbeHero8 Module Structure:"
	@echo "  Common: $(wildcard common/*.vhd)"
	@echo "  Datadef: $(wildcard datadef/*.vhd)"
	@echo "  Core: $(wildcard core/*.vhd)"
	@echo "  Top: $(wildcard top/*.vhd)"
	@echo "  Testbenches: $(wildcard tb/*/*.vhd)"

# Enhanced compilation with detailed progress
compile-enhanced: compile-datadef compile-core compile-top compile-testbenches
	@echo "=== Enhanced Compilation Complete ==="
	@echo "All ProbeHero8 components compiled successfully"
	@echo "Enhanced datadef packages with unit hinting: $(DATADEF_PACKAGES)"
	@echo "Core modules: $(CORE_MODULES)"
	@echo "Top modules: $(TOP_MODULES)"
	@echo "Testbenches: $(TESTBENCHES)"

# Clean enhanced artifacts
clean-enhanced: clean-local
	@echo "=== Cleaning Enhanced Artifacts ==="
	@rm -f *_en.o
	@rm -f *_en_tb
	@rm -f work-obj*.cf
	@echo "=== Enhanced Clean Complete ==="

# Show module-specific targets
show-module-targets:
	@echo "ProbeHero8 Module-Specific Targets:"
	@echo "  make compile-datadef           - Compile enhanced datadef packages only"
	@echo "  make compile-core              - Compile core modules (after datadef)"
	@echo "  make compile-top               - Compile top modules (after core)"
	@echo "  make compile-testbenches       - Compile all testbenches"
	@echo "  make compile-enhanced          - Full enhanced compilation with progress"
	@echo ""
	@echo "  make test-core                 - Run all core testbenches"
	@echo "  make test-top                  - Run all top testbenches"
	@echo "  make test-probe_hero8_core_tb  - Run specific core testbench"
	@echo "  make test-probe_hero8_core_detailed_tb - Run detailed core testbench"
	@echo "  make test-probe_hero8_top_tb   - Run specific top testbench"
	@echo "  make test-probe_hero8_top_detailed_tb - Run detailed top testbench"
	@echo "  make quick-test                - Compile and run main testbench only"
	@echo "  make validation-test           - Run comprehensive validation test"
	@echo ""
	@echo "  make list-tests                - Show available testbenches"
	@echo "  make list-datadef              - Show enhanced datadef packages"
	@echo "  make list-structure            - Show module file structure"
	@echo "  make clean-enhanced            - Clean enhanced artifacts"

endif

# Override the default compile target to use enhanced compilation
compile: compile-enhanced

# Override the default test target to run all tests
test: test-core test-top

.PHONY: compile-datadef compile-core compile-top compile-testbenches test-core test-top
.PHONY: test-probe_hero8_core_tb test-probe_hero8_core_detailed_tb test-probe_hero8_top_tb test-probe_hero8_top_detailed_tb
.PHONY: quick-test validation-test list-tests list-datadef list-structure compile-enhanced clean-enhanced

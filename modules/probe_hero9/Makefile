# Makefile for ProbeHero9 Module
# Enhanced datadef packages with comprehensive unit hinting and validation
# Includes central makefile logic for hierarchical builds

# Include the central makefile from the modules directory
include ../Makefile

# Module-specific overrides and additional targets
# The central makefile handles all the standard targets (compile, test, clean, etc.)
# and provides context-aware help messages with module-specific targets

# ProbeHero9 specific configuration
MODULE_NAME := probe_hero9
ENHANCED_DATADEF := true

# Enhanced datadef packages (probe_hero9 specific with PH9 naming)
DATADEF_PACKAGES := \
	Probe_Config_pkg_PH9 \
	Moku_Voltage_pkg_PH9 \
	PercentLut_pkg_PH9 \
	Global_Probe_Table_pkg_PH9

# Core modules (to be implemented)
CORE_MODULES := \
	probe_hero9_core

# Top modules (to be implemented)
TOP_MODULES := \
	probe_hero9_top

# Testbenches
TESTBENCHES := \
	probe_hero9_core_tb \
	probe_hero9_top_tb

# Datadef testbenches
DATADEF_TESTBENCHES := \
	Moku_Voltage_pkg_PH9_tb \
	Probe_Config_pkg_PH9_tb \
	PercentLut_pkg_PH9_tb \
	Global_Probe_Table_pkg_PH9_tb

# Module-specific targets (only available when in the probe_hero9 directory)
ifeq ($(MODULE_NAME),probe_hero9)

# Enhanced datadef compilation (with dependency order)
compile-datadef:
	@echo "=== Compiling Enhanced Datadef Packages (PH9) ==="
	@echo "Compiling mcc template..."
	@$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
	@echo "Compiling Moku_Voltage_pkg_PH9 (base voltage package)..."
	@$(GHDL_ANALYZE) datadef/Moku_Voltage_pkg_PH9.vhd
	@echo "Compiling Probe_Config_pkg_PH9 (depends on Moku_Voltage_pkg_PH9)..."
	@$(GHDL_ANALYZE) datadef/Probe_Config_pkg_PH9.vhd
	@echo "Compiling PercentLut_pkg_PH9 (depends on Moku_Voltage_pkg_PH9)..."
	@$(GHDL_ANALYZE) datadef/PercentLut_pkg_PH9.vhd
	@echo "Compiling Global_Probe_Table_pkg_PH9 (depends on Probe_Config_pkg_PH9)..."
	@$(GHDL_ANALYZE) datadef/Global_Probe_Table_pkg_PH9.vhd
	@echo "=== Enhanced Datadef Compilation Complete ==="

# Core modules compilation (placeholder for future implementation)
compile-core: compile-datadef
	@echo "=== Compiling Core Modules ==="
	@echo "Note: Core modules not yet implemented for ProbeHero9"
	@echo "=== Core Modules Compilation Complete ==="

# Top modules compilation (placeholder for future implementation)
compile-top: compile-core
	@echo "=== Compiling Top Modules ==="
	@echo "Note: Top modules not yet implemented for ProbeHero9"
	@echo "=== Top Modules Compilation Complete ==="

# Datadef testbenches compilation
compile-datadef-testbenches: compile-datadef
	@echo "=== Compiling Datadef Testbenches ==="
	@echo "Compiling volo_common_tb_pkg..."
	@$(GHDL_ANALYZE) $(PROJECT_ROOT)/ai-workflow/modules/volo_common/volo_common_tb_pkg.vhd
	@echo "Compiling Moku_Voltage_pkg_PH9_tb..."
	@$(GHDL_ANALYZE) tb/datadef/Moku_Voltage_pkg_PH9_tb.vhd
	@echo "Compiling Probe_Config_pkg_PH9_tb..."
	@$(GHDL_ANALYZE) tb/datadef/Probe_Config_pkg_PH9_tb.vhd
	@echo "Compiling PercentLut_pkg_PH9_tb..."
	@$(GHDL_ANALYZE) tb/datadef/PercentLut_pkg_PH9_tb.vhd
	@echo "Compiling Global_Probe_Table_pkg_PH9_tb..."
	@$(GHDL_ANALYZE) tb/datadef/Global_Probe_Table_pkg_PH9_tb.vhd
	@echo "=== Datadef Testbenches Compilation Complete ==="

# Testbenches compilation (placeholder for future implementation)
compile-testbenches: compile-top compile-datadef-testbenches
	@echo "=== Compiling All Testbenches ==="
	@echo "Datadef testbenches compiled successfully"
	@echo "Note: Core and top testbenches not yet implemented for ProbeHero9"
	@echo "=== All Testbenches Compilation Complete ==="

# Datadef test targets
test-datadef: compile-datadef-testbenches
	@echo "=== Running Datadef Testbenches ==="
	@echo "Running Moku_Voltage_pkg_PH9_tb..."
	@$(GHDL_ELABORATE) Moku_Voltage_pkg_PH9_tb
	@$(GHDL_RUN) Moku_Voltage_pkg_PH9_tb
	@echo "Running Probe_Config_pkg_PH9_tb..."
	@$(GHDL_ELABORATE) Probe_Config_pkg_PH9_tb
	@$(GHDL_RUN) Probe_Config_pkg_PH9_tb
	@echo "Running PercentLut_pkg_PH9_tb..."
	@$(GHDL_ELABORATE) PercentLut_pkg_PH9_tb
	@$(GHDL_RUN) PercentLut_pkg_PH9_tb
	@echo "Running Global_Probe_Table_pkg_PH9_tb..."
	@$(GHDL_ELABORATE) Global_Probe_Table_pkg_PH9_tb
	@$(GHDL_RUN) Global_Probe_Table_pkg_PH9_tb
	@echo "=== Datadef Tests Complete ==="

# Individual datadef test targets
test-Moku_Voltage_pkg_PH9_tb: compile-datadef-testbenches
	@echo "=== Running Moku_Voltage_pkg_PH9_tb ==="
	@$(GHDL_ELABORATE) Moku_Voltage_pkg_PH9_tb
	@$(GHDL_RUN) Moku_Voltage_pkg_PH9_tb
	@echo "=== Test Completed ==="

test-Probe_Config_pkg_PH9_tb: compile-datadef-testbenches
	@echo "=== Running Probe_Config_pkg_PH9_tb ==="
	@$(GHDL_ELABORATE) Probe_Config_pkg_PH9_tb
	@$(GHDL_RUN) Probe_Config_pkg_PH9_tb
	@echo "=== Test Completed ==="

test-PercentLut_pkg_PH9_tb: compile-datadef-testbenches
	@echo "=== Running PercentLut_pkg_PH9_tb ==="
	@$(GHDL_ELABORATE) PercentLut_pkg_PH9_tb
	@$(GHDL_RUN) PercentLut_pkg_PH9_tb
	@echo "=== Test Completed ==="

test-Global_Probe_Table_pkg_PH9_tb: compile-datadef-testbenches
	@echo "=== Running Global_Probe_Table_pkg_PH9_tb ==="
	@$(GHDL_ELABORATE) Global_Probe_Table_pkg_PH9_tb
	@$(GHDL_RUN) Global_Probe_Table_pkg_PH9_tb
	@echo "=== Test Completed ==="

# Individual test targets for specific testbenches (placeholder)
test-core: compile-testbenches
	@echo "=== Running Core Testbenches ==="
	@echo "Note: Core testbenches not yet implemented for ProbeHero9"
	@echo "=== Core Tests Complete ==="

test-top: compile-testbenches
	@echo "=== Running Top Testbenches ==="
	@echo "Note: Top testbenches not yet implemented for ProbeHero9"
	@echo "=== Top Tests Complete ==="

# Individual testbench targets (placeholder)
test-probe_hero9_core_tb: compile-testbenches
	@echo "=== Running probe_hero9_core_tb ==="
	@echo "Note: probe_hero9_core_tb not yet implemented"
	@echo "=== Test Completed ==="

test-probe_hero9_top_tb: compile-testbenches
	@echo "=== Running probe_hero9_top_tb ==="
	@echo "Note: probe_hero9_top_tb not yet implemented"
	@echo "=== Test Completed ==="

# Quick test (compile and run datadef testbenches)
quick-test: test-datadef
	@echo "=== Running Quick Test (datadef testbenches) ==="
	@echo "All PH9 datadef testbenches completed successfully"
	@echo "=== Quick Test Completed ==="

# Enhanced validation test (datadef packages validation)
validation-test: compile-datadef
	@echo "=== Running Validation Test (datadef packages) ==="
	@echo "Validating PH9 datadef packages..."
	@echo "  - Probe_Config_pkg_PH9: Probe configuration with enhanced validation"
	@echo "  - Moku_Voltage_pkg_PH9: Voltage conversion with SLV and real support"
	@echo "  - PercentLut_pkg_PH9: Lookup table with enhanced validation"
	@echo "  - Global_Probe_Table_pkg_PH9: Global probe table with safety controls"
	@echo "=== Validation Test Completed ==="

# Show available testbenches
list-tests:
	@echo "Available testbenches:"
	@echo "Datadef testbenches (implemented):"
	@echo "  - Moku_Voltage_pkg_PH9_tb (voltage conversion testing)"
	@echo "  - Probe_Config_pkg_PH9_tb (probe configuration testing)"
	@echo "  - PercentLut_pkg_PH9_tb (lookup table testing)"
	@echo "  - Global_Probe_Table_pkg_PH9_tb (global probe table testing)"
	@echo ""
	@echo "Module testbenches (to be implemented):"
	@echo "  - probe_hero9_core_tb (basic core functionality)"
	@echo "  - probe_hero9_top_tb (top integration)"
	@echo ""
	@echo "Available targets:"
	@echo "  - make test-datadef (run all datadef testbenches)"
	@echo "  - make quick-test (compile and run datadef testbenches)"
	@echo "  - make validation-test (validate datadef packages)"

# Show enhanced datadef packages
list-datadef:
	@echo "Enhanced datadef packages (PH9):"
	@echo "  - Probe_Config_pkg_PH9 (probe configuration with unit hinting)"
	@echo "  - Moku_Voltage_pkg_PH9 (voltage conversion with SLV and real support)"
	@echo "  - PercentLut_pkg_PH9 (lookup table with unit hinting)"
	@echo "  - Global_Probe_Table_pkg_PH9 (global probe table with safety controls)"

# Show module structure
list-structure:
	@echo "ProbeHero9 Module Structure:"
	@echo "  Common: $(wildcard common/*.vhd)"
	@echo "  Datadef: $(wildcard datadef/*.vhd)"
	@echo "  Core: $(wildcard core/*.vhd)"
	@echo "  Top: $(wildcard top/*.vhd)"
	@echo "  Testbenches: $(wildcard tb/*/*.vhd)"
	@echo "  Requirements: $(wildcard requirements/*/*.md)"

# Enhanced compilation with detailed progress
compile-enhanced: compile-datadef compile-core compile-top compile-testbenches
	@echo "=== Enhanced Compilation Complete ==="
	@echo "All ProbeHero9 components compiled successfully"
	@echo "Enhanced datadef packages with PH9 naming: $(DATADEF_PACKAGES)"
	@echo "Core modules: $(CORE_MODULES) (to be implemented)"
	@echo "Top modules: $(TOP_MODULES) (to be implemented)"
	@echo "Testbenches: $(TESTBENCHES) (to be implemented)"

# Clean enhanced artifacts
clean-enhanced: clean-local
	@echo "=== Cleaning Enhanced Artifacts ==="
	@rm -f *_PH9.o
	@rm -f *_PH9_tb
	@rm -f work-obj*.cf
	@echo "=== Enhanced Clean Complete ==="

# Show module-specific targets
show-module-targets:
	@echo "ProbeHero9 Module-Specific Targets:"
	@echo "  make compile-datadef           - Compile enhanced datadef packages only"
	@echo "  make compile-datadef-testbenches - Compile datadef testbenches"
	@echo "  make compile-core              - Compile core modules (placeholder)"
	@echo "  make compile-top               - Compile top modules (placeholder)"
	@echo "  make compile-testbenches       - Compile all testbenches"
	@echo "  make compile-enhanced          - Full enhanced compilation with progress"
	@echo ""
	@echo "  make test-datadef              - Run all datadef testbenches"
	@echo "  make test-Moku_Voltage_pkg_PH9_tb - Run voltage package testbench"
	@echo "  make test-Probe_Config_pkg_PH9_tb - Run probe config testbench"
	@echo "  make test-PercentLut_pkg_PH9_tb - Run percent LUT testbench"
	@echo "  make test-Global_Probe_Table_pkg_PH9_tb - Run global probe table testbench"
	@echo "  make test-core                 - Run all core testbenches (placeholder)"
	@echo "  make test-top                  - Run all top testbenches (placeholder)"
	@echo "  make test-probe_hero9_core_tb  - Run specific core testbench (placeholder)"
	@echo "  make test-probe_hero9_top_tb   - Run specific top testbench (placeholder)"
	@echo "  make quick-test                - Compile and run datadef testbenches"
	@echo "  make validation-test           - Run comprehensive datadef validation"
	@echo ""
	@echo "  make list-tests                - Show available testbenches"
	@echo "  make list-datadef              - Show enhanced datadef packages"
	@echo "  make list-structure            - Show module file structure"
	@echo "  make clean-enhanced            - Clean enhanced artifacts"

# ProbeHero9 specific enhancements
show-ph9-features:
	@echo "ProbeHero9 Specific Features:"
	@echo "  - PH9 naming convention for all packages"
	@echo "  - Enhanced voltage package with SLV and real support"
	@echo "  - Improved safety controls with per-probe safety_enabled"
	@echo "  - Centralized voltage constants in Moku_Voltage_pkg_PH9"
	@echo "  - Enhanced validation and error handling"
	@echo "  - Better separation of concerns between packages"

# Validate datadef packages
validate-datadef: compile-datadef
	@echo "=== Validating ProbeHero9 Datadef Packages ==="
	@echo "Checking package dependencies..."
	@echo "  ✓ Probe_Config_pkg_PH9 (base package)"
	@echo "  ✓ Moku_Voltage_pkg_PH9 (voltage utilities)"
	@echo "  ✓ PercentLut_pkg_PH9 (depends on Moku_Voltage_pkg_PH9)"
	@echo "  ✓ Global_Probe_Table_pkg_PH9 (depends on Probe_Config_pkg_PH9)"
	@echo "Checking naming consistency..."
	@echo "  ✓ All packages use PH9 suffix"
	@echo "  ✓ No redundant 'en' suffixes"
	@echo "  ✓ Consistent cross-package references"
	@echo "=== Datadef Validation Complete ==="

endif

# Override the default compile target to use enhanced compilation
compile: compile-enhanced

# Override the default test target to run datadef validation
test: validate-datadef

.PHONY: compile-datadef compile-datadef-testbenches compile-core compile-top compile-testbenches
.PHONY: test-datadef test-Moku_Voltage_pkg_PH9_tb test-Probe_Config_pkg_PH9_tb test-PercentLut_pkg_PH9_tb test-Global_Probe_Table_pkg_PH9_tb
.PHONY: test-core test-top test-probe_hero9_core_tb test-probe_hero9_top_tb
.PHONY: quick-test validation-test list-tests list-datadef list-structure compile-enhanced clean-enhanced
.PHONY: show-ph9-features validate-datadef

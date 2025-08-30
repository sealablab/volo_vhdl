# Makefile for Probe Driver Testbench Directory
# Delegates to parent module makefile

# Delegate all targets to the parent module makefile
%:
	@$(MAKE) -C .. $@

# Override help to show delegation information
help:
	@echo "Probe Driver Testbench Directory Makefile"
	@echo ""
	@echo "This directory delegates all make targets to the parent module."
	@echo "All targets are forwarded to: ../Makefile"
	@echo ""
	@echo "Available targets (delegated to parent):"
	@echo "  make clean                    - Remove all compilation artifacts"
	@echo "  make                          - Compile all modules and testbenches"
	@echo "  make compile                  - Same as 'make'"
	@echo "  make test                     - Run all available testbenches"
	@echo "  make help                     - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make clean && make && make test"
	@echo ""
	@echo "Note: All commands are executed from the parent module directory."

.PHONY: help
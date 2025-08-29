# Volo VHDL Project

Johnny's evolving AI VHDL generation workflow designed for **VHDL-2008 with Verilog portability**.

## Project Structure

```
volo_vhdl/
├─ .cursor/rules              # Project rules for AI agents
├─ AGENTS.md                  # Comprehensive agent guidelines
├─ modules/                   # VHDL modules with standardized structure
│  ├─ README.md              # Module structure documentation
│  └─ [module_name]/
│      ├─ datadef/           # Data structure definitions (Tier 2 rules)
│      ├─ common/            # RTL utility packages (Tier 1 rules)
│      ├─ core/              # Main algorithmic/logic implementation (Tier 1 rules)
│      ├─ top/               # Top-level integration (Tier 1 rules, optional)
│      └─ tb/                # Testbenches (Tier 3 rules)
├─ templates/                 # Reusable VHDL templates
│  └─ README.md              # Template guidelines
└─ docs/                      # Additional documentation
    ├─ STYLE.md              # Coding style guidelines
    ├─ REGISTERS.md          # ctrl_/cfg_/stat_ rules + reset semantics
    └─ WORKFLOW.md           # How to use templates with Cursor
```

## Quick Start

1. **Read the Rules**: Start with `.cursor/rules` and `AGENTS.md`
2. **Follow the Structure**: Use the standardized module layout in `modules/`
3. **Use Templates**: Leverage pre-built templates in `templates/`
4. **Build and Test**: Use the Makefile in each module directory for compilation and testing
5. **Maintain Standards**: Follow VHDL-2008 with Verilog portability guidelines
6. **Direct Instantiation**: Use `entity WORK.module_name` pattern for all top-level files

## Key Features

- **Verilog Portable**: All VHDL code designed for easy conversion
- **Tiered Rule System**: Three-tier approach balancing portability with practicality
- **Standardized Architecture**: Consistent module structure across the project
- **AI Agent Ready**: Comprehensive guidelines for AI-assisted development
- **Template Driven**: Reusable templates following project standards
- **Direct Instantiation**: Mandatory `entity WORK.module_name` pattern for top-level files
- **Platform Interface Packages**: Standardized register interface design patterns
- **Automated Build System**: Centralized dependency management and compilation

## Tiered Rule System

The project uses a **three-tier rule system** to balance Verilog portability requirements with practical VHDL development needs:

- **Tier 1 (Strict RTL)**: `common/`, `core/`, `top/` - Strict Verilog portability rules
- **Tier 2 (Data Definitions)**: `datadef/` - Relaxed rules for LUTs and data structures  
- **Tier 3 (Testbenches)**: `tb/` - Full VHDL-2008 features allowed

This approach ensures synthesizable RTL maintains full Verilog compatibility while allowing appropriate flexibility for data definitions and verification code. See `.cursor/rules.mdc` for complete details.

## Platform Interface Package Approach

The project introduces a **standardized platform interface package approach** for register interface design:

### Key Components
- **Register Field Constants**: Bit position definitions for all register fields
- **Validation Functions**: Safety-critical parameter validation with fault triggering
- **Field Extraction**: Functions to extract specific fields from register data
- **Status Assembly**: Automatic construction of status registers from internal signals
- **Fault Aggregation**: Centralized fault handling across multiple sources

### Benefits
- **Consistency**: Standardized approach across all modules
- **Maintainability**: Centralized register interface logic
- **Verilog Compatibility**: All functions use standard types
- **Reusability**: Can be applied to other modules requiring register interfaces
- **Safety**: Built-in validation prevents invalid configurations

### Example Usage
```vhdl
-- Import the platform interface package
use work.platform_interface_pkg.all;

-- Validate wave selection (safety-critical)
if is_wave_select_valid(wave_select) = '0' then
    fault_out <= '1';  -- Trigger fault for invalid selection
end if;

-- Extract control fields from register data
global_enable <= extract_ctrl_global_enable(ctrl0_data);
div_sel <= extract_clk_div_sel(ctrl0_data);

-- Assemble status register
status_reg <= assemble_status0_reg(enabled, wave_select);
```

## Build System

The project features an **automated build system** that automatically detects and builds all modules:

### Centralized Build Management
```bash
# From modules/ directory - build all modules with dependencies
cd modules
make clean && make compile && make test

# List all available modules
make list-modules

# Build specific module
make compile-single-module MODULE_NAME=SimpleWaveGen
```

### Module-Level Build
Each module includes a comprehensive Makefile for GHDL compilation and testing:

```bash
# Navigate to a module directory
cd modules/probe_driver

# Clean previous builds
make clean

# Compile all modules and testbenches
make

# Run all testbenches
make test

# Run individual testbenches
make test-probe_driver_interface
make test-PercentLut_pkg
make test-Moku_Voltage_pkg

# Quick test (main testbench only)
make quick-test

# Show available targets
make help
```

The Makefile automatically handles:
- Dependency-ordered compilation (packages → core → top → testbenches)
- GHDL VHDL-2008 standard compliance
- Comprehensive test execution with pass/fail reporting
- Clean build artifact management

## Changelog

### [Unreleased] - 2025-01-27
#### Added
- **SimpleWaveGen Module**: Complete waveform generation module with automated build system integration
  - **Standardized Architecture**: Follows project directory structure (common, core, top, tb)
  - **Platform Interface Package**: `platform_interface_pkg.vhd` for register interface management
  - **Minimal Testbench Strategy**: Core testbench for functionality, top testbench for integration
  - **Automated Build Integration**: Automatically detected and built by central build system
  - **VHDL-2008 Compliance**: Full compatibility with GHDL and Verilog portability
  - **Direct Instantiation**: Uses `entity WORK.module_name` pattern as required
  - **Comprehensive Makefile**: Dependency management and test execution

- **Platform Interface Package Approach**: New standardized method for register interface design
  - **Register Field Management**: Bit position constants and field extraction functions
  - **Safety-Critical Validation**: Built-in parameter validation with fault triggering
  - **Status Register Assembly**: Automatic status register construction from internal signals
  - **Amplitude Scaling**: Integrated amplitude scaling with signed arithmetic
  - **Fault Aggregation**: Centralized fault handling across multiple sources
  - **Verilog Compatibility**: All functions use standard types for easy conversion
  - **Reusable Pattern**: Can be applied to other modules requiring register interfaces

- **GHDL Testbench Development Guide**: Comprehensive guide for VHDL testbench development with GHDL
  - Common compilation issues and solutions (procedure parameters, signal vs variable confusion)
  - Infinite loop prevention using `std.env.stop()` instead of `wait;`
  - Best practices for testbench design and organization
  - Debugging techniques and GHDL-specific considerations
  - Practical examples and quick reference commands
  - Clear guidance on when to use complex timeout logic vs simple termination

- **Direct Instantiation Requirements**: Mandatory direct instantiation for all top-level files
  - **Top Layer Files**: All `modules/**/top/*.vhd` files must use `entity WORK.module_name` pattern
  - **Top Layer Testbenches**: All `modules/**/tb/top/*.vhd` files must use direct instantiation
  - **Core Layer Testbenches**: Recommended to use direct instantiation for consistency
  - **Benefits**: Better dependency management, earlier error detection, cleaner code
  - **Pattern**: `U1: entity WORK.module_name port map (...)` instead of component declarations
  - **Updated Guidelines**: Both AGENTS.md and .cursor/rules.mdc updated with comprehensive requirements

- **Trigger Configuration Voltage Integration**: Enhanced `Trigger_Config_pkg` with voltage-based configuration interface
  - Voltage-based configuration using intuitive voltage values (e.g., 1.0V, 2.5V)
  - Digital implementation interface for RTL compatibility
  - Conversion functions between voltage and digital representations
  - Comprehensive validation and utility functions
  - Full integration with `Moku_Voltage_pkg` for Moku platform compatibility
  - 18 comprehensive test cases covering all functionality
  - Maintains backward compatibility with existing digital constants

#### Changed
- **Trigger_Config_pkg**: Complete redesign to support both voltage and digital interfaces
  - Primary interface now uses voltage values for configuration
  - Legacy digital constants maintained for backward compatibility
  - Enhanced validation with tolerance-based voltage comparison (1mV tolerance)

#### Technical Details
- **Voltage Range**: Full Moku platform support (-5V to +5V)
- **Precision**: 1mV tolerance for voltage comparisons
- **Performance**: No floating-point operations in RTL critical path
- **Verilog Compatibility**: Maintained through conversion functions

### [v0.2.0] - 2025-01-27
#### Added
- **Moku_Voltage_pkg**: Comprehensive voltage conversion utilities for Moku platform
  - 16-bit signed ADC/DAC interface support (-32768 to +32767)
  - Voltage range: -5.0V to +5.0V with ~305 µV resolution
  - Conversion functions: voltage ↔ digital with automatic range validation
  - Testbench convenience functions for voltage comparison and validation
  - Common voltage reference points (1V, 2.4V, 2.5V, 3V, 3.3V, 5V)
  - Comprehensive testbench with 50+ test cases

#### Added
- **PercentLut_pkg**: Percentage-based lookup table utilities
  - Efficient percentage-to-value conversion for probe driver applications
  - Comprehensive testbench with edge case coverage
  - Integration with Moku voltage specifications

#### Added
- **Build System**: Comprehensive Makefile-based build system for each module
  - Dependency-ordered compilation (packages → core → top → testbenches)
  - GHDL VHDL-2008 standard compliance
  - Comprehensive test execution with pass/fail reporting
  - Clean build artifact management

### [v0.1.0] - 2025-01-27
#### Added
- **Project Foundation**: Initial VHDL project structure with Verilog portability focus
- **Standardized Module Layout**: Common, datadef, core, top, and testbench directories
- **VHDL-2008 Standards**: Strict coding standards for maximum Verilog compatibility
- **Template System**: Pre-built templates for common VHDL patterns
- **Documentation**: Comprehensive guidelines and best practices

## Recent Updates

The `PercentLut_pkg` has been enhanced with full integration to `Moku_Voltage_pkg`, providing seamless voltage-to-LUT conversion for the Moku platform's 16-bit signed ADC/DAC interfaces.

#### Key Features
- **Voltage Range Support**: Both unipolar (0V to +5V) and bipolar (-5V to +5V) ranges
- **Backward Compatibility**: All existing functions work unchanged
- **Predefined LUTs**: Ready-to-use constants for common voltage ranges
- **Verilog Compatible**: All functions use standard VHDL types

#### Usage Examples

```vhdl
-- Import the packages
use work.PercentLut_pkg.all;
use work.Moku_Voltage_pkg.all;

-- Create a 0V to 5V LUT using Moku voltage conversion
variable my_lut : percent_lut_record_t := create_moku_voltage_lut_record(5.0);

-- Convert 2.5V to LUT index
variable index : natural := moku_voltage_to_percent_index(2.5); -- Returns 50

-- Convert LUT index back to voltage
variable voltage : real := percent_index_to_moku_voltage(50); -- Returns 2.5V

-- Use predefined LUTs
variable lookup_result : std_logic_vector(15 downto 0) := 
    get_percentlut_value_safe(MOKU_5V_LUT, 75); -- 75% of 5V = 3.75V

-- Bipolar voltage conversion (-5V to +5V)
variable bipolar_index : natural := moku_bipolar_voltage_to_percent_index(-2.5); -- Returns 25
variable bipolar_voltage : real := percent_index_to_moku_bipolar_voltage(75); -- Returns +2.5V

-- Custom voltage range LUT
variable custom_lut : percent_lut_record_t := 
    create_voltage_percent_lut_record(0.0, 3.3); -- 0V to 3.3V range
```

#### Available Predefined LUTs
- `MOKU_5V_LUT` - 0V to 5V unipolar range
- `MOKU_3V3_LUT` - 0V to 3.3V unipolar range  
- `MOKU_BIPOLAR_LUT` - -5V to +5V bipolar range

#### Testing
Comprehensive testbench with 53 test cases covering all voltage integration functions, including round-trip conversion tests and boundary condition validation.

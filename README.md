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

## Key Features

- **Verilog Portable**: All VHDL code designed for easy conversion
- **Tiered Rule System**: Three-tier approach balancing portability with practicality
- **Standardized Architecture**: Consistent module structure across the project
- **AI Agent Ready**: Comprehensive guidelines for AI-assisted development
- **Template Driven**: Reusable templates following project standards

## Tiered Rule System

The project uses a **three-tier rule system** to balance Verilog portability requirements with practical VHDL development needs:

- **Tier 1 (Strict RTL)**: `common/`, `core/`, `top/` - Strict Verilog portability rules
- **Tier 2 (Data Definitions)**: `datadef/` - Relaxed rules for LUTs and data structures  
- **Tier 3 (Testbenches)**: `tb/` - Full VHDL-2008 features allowed

This approach ensures synthesizable RTL maintains full Verilog compatibility while allowing appropriate flexibility for data definitions and verification code. See `.cursor/rules.mdc` for complete details.

## Build System

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

## Recent Updates

### PercentLut_pkg with Moku Voltage Integration

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

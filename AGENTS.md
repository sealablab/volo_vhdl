# Volo VHDL Project - Agent Guidelines

## Overview
This document provides guidelines for AI agents working with the Volo VHDL project. The project follows strict VHDL-2008 coding standards designed for **Verilog portability**.

## Core Principles

### VHDL-2008 with Verilog Portability
- **Target**: VHDL-2008 that can be easily converted to Verilog
- **Avoid**: VHDL-only features that don't translate well to Verilog

### Allowed Features
- `std_logic` and `std_logic_vector` types
- `unsigned` and `signed` from `numeric_std` package
- Generics and generate statements
- Synchronous processes with `rising_edge(clk)`
- Synchronous reset mechanisms
- Explicit bit widths for all vectors

### Forbidden Features
- Records in port declarations (except in datadef packages)
- Subtype range constraints
- Enumeration types in RTL code
- Shared variables
- `wait` statements in RTL
- `after` delays
- Resolved custom types
- Physical types
- File I/O operations

## Port Naming Conventions

### Signal Prefixes
- **`ctrl_*`**: Control signals (enable, reset, etc.)
- **`cfg_*`**: Configuration parameters
- **`stat_*`**: Status and monitoring signals

### Port Structure
- Use flat ports (no records)
- Avoid complex type hierarchies
- Keep interfaces simple and Verilog-compatible

## Module Architecture

### Directory Structure
All VHDL modules must follow this standardized structure:
```
modules/
├── module_name/
│   ├── common/     # Shared packages and utilities
│   ├── datadef/    # Data structure definitions and type packages
│   ├── core/       # Main algorithmic/logic implementation
│   ├── top/        # Top-level integration (optional)
│   └── tb/         # Testbenches organized by layer
│       ├── common/     # Tests for common layer packages
│       ├── datadef/    # Tests for datadef packages
│       ├── core/       # Tests for core layer entities
│       └── top/        # Tests for top layer integration
```

## Direct Instantiation Requirements

### **Mandatory for Top Layer**
All files in the `top/` directory (both RTL and testbenches) **MUST** use direct instantiation for internal module connections.

### **Direct Instantiation Pattern**
```vhdl
-- ✅ Correct: Direct instantiation (required for top layer)
U1: entity WORK.module_name
    port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        data_out => data_out
    );

-- ❌ Forbidden in top layer: Component declaration + instantiation
-- component module_name is ... end component;
-- U1: module_name port map (...);
```

### **When to Use Direct Instantiation**
- **REQUIRED**: All top-level integration files (`modules/**/top/*.vhd`)
- **REQUIRED**: All top-level testbenches (`modules/**/tb/top/*.vhd`)
- **RECOMMENDED**: Core layer testbenches (`modules/**/tb/core/*.vhd`)
- **OPTIONAL**: Core layer RTL files (can use either approach)

### **Benefits for Top Layer**
- **Dependency Clarity**: Clear compilation order requirements
- **Error Detection**: Port mismatches caught at analysis time
- **Code Consistency**: Uniform instantiation pattern across top-level files
- **Maintainability**: Easier to track module dependencies

### Layer Responsibilities

#### Common Layer (`modules/**/common/*.vhd`)
- **Purpose**: Define shared types, constants, and utilities used across the module
- **Responsibilities**:
  - Configuration parameter validation functions
  - Utility functions shared across testbenches and modules
  - Common type definitions and constants

#### Datadef Layer (`modules/**/datadef/*.vhd`)
- **Purpose**: Define data structures, types, and constants for Verilog portability
- **Responsibilities**:
  - Data structure definitions (records allowed for organization)
  - Type conversion and packing/unpacking utilities  
  - Constants for bit field definitions and data widths
  - Validation functions for data structures
- **Constraints**:
  - **Record types are ALLOWED** for data organization and type safety
  - Define explicit bit field constants for easy Verilog translation
  - **Note**: Records in datadef packages require manual Verilog conversion

#### Core Layer (`modules/**/core/*.vhd`)
- **Purpose**: Pure logic implementation
- **Constraints**:
  - No register decode logic
  - No platform-specific code
  - Consume typed-by-name flat signals
  - Implement FSMs with `std_logic_vector` state encoding
  - Use constants for state labels (no enums)
  - **Create a default status register**
  - Ideally implement as a state machine

#### Top Layer (`modules/**/top/*.vhd`)
- **Purpose**: Integrate multiple modules and handle system-level concerns
- **Responsibilities**:
  - **External interface** - Connect to platform control system (generally a Moku CustomWrapper)
  - **Register exposure** - Expose appropriate control, configuration, and status registers
  - **Module integration** - Connect core modules using direct instantiation
  - **Important**: DO NOT include MCC CustomWrapper entity body
  - Keep top-level modules clean and focused
  - **Note**: Not all modules will require a 'top' file

**Direct Instantiation Requirement**: All internal module connections in top layer files MUST use direct instantiation (`entity WORK.module_name`) rather than component declarations.

## FSM Implementation
- Use `std_logic_vector` for state encoding
- Define state constants (avoid enumeration types)
- Example:
  ```vhdl
  constant IDLE_STATE  : std_logic_vector(1 downto 0) := "00";
  constant ACTIVE_STATE: std_logic_vector(1 downto 0) := "01";
  ```

## Counters and Timers
- Prefer `unsigned` vectors with explicit widths
- Avoid generic ranges or complex constraints
- Example: `signal counter : unsigned(7 downto 0);`

## Code Style and Comments

### Block Structure
- Clearly mark the end of `if`/`elsif`/`case` blocks
- Use consistent indentation
- Add meaningful comments for complex logic

### Process Structure
- Use synchronous processes with `rising_edge(clk)`
- Implement proper reset handling
- Keep processes focused and readable

## Testbench Requirements (`modules/**/tb/*.vhd`)

### Directory Organization
Testbenches must be organized by the layer they test:
- **`tb/common/`**: Test packages and utilities from `common/` layer
- **`tb/core/`**: Test entities and modules from `core/` layer  
- **`tb/top/`**: Test top-level integration from `top/` layer
- **`tb/datadef/`**: Test datadef packages (special case for data definition packages)

### Naming Convention
- **Testbench files**: `<original_name>_tb.vhd`
- **Entity names**: `<original_name>_tb`
- **Architecture names**: `behavioral` or `test`
- **Process names**: Descriptive (e.g., `test_crc_calculation`, `test_safe_lookup`)

### Allowed Features
- VHDL-2008 features are permitted in testbenches
- `wait` statements are allowed (but not in RTL code being tested)
- Use deterministic stimuli patterns
- Standard libraries: IEEE, STD.TEXTIO, IEEE.STD_LOGIC_TEXTIO
- Helper procedures and functions for test organization

### Required Output Messages
- **Success**: Print `'ALL TESTS PASSED'`
- **Failure**: Print `'TEST FAILED'` 
- **Completion**: Always print `'SIMULATION DONE'`
- **Progress**: Print individual test results for visibility

### **Direct Instantiation in Testbenches**
- **Top Layer Testbenches**: MUST use direct instantiation for all module instantiations
- **Core Layer Testbenches**: RECOMMENDED to use direct instantiation for consistency
- **Datadef/Common Testbenches**: Can use either approach (no requirement)

**Example Top Layer Testbench:**
```vhdl
architecture test of probe_driver_top_tb is
begin
    -- ✅ Required: Direct instantiation in top layer testbenches
    DUT: entity WORK.probe_driver_top
        port map (
            clk => clk,
            rst => rst,
            -- ... other ports
        );
end architecture;
```

### Test Structure Standards
```vhdl
-- Use helper procedures for consistent reporting
procedure report_test(test_name : string; passed : boolean; test_num : inout natural);

-- Organize tests in logical groups
-- Group 1: Basic functionality tests
-- Group 2: Edge case tests  
-- Group 3: Error condition tests
-- Group 4: Integration tests (if applicable)
```

### Package Testing Requirements
For packages containing only functions (no entities):
- Create a simple testbench entity that uses the package
- Test all public functions systematically
- Include comprehensive edge case coverage
- Use multiple test data patterns (linear, pattern-based, edge cases)
- Validate function overloading (if present)

### GHDL Compatibility Requirements
- Must compile with `ghdl --std=08`
- Must elaborate without errors
- Must run to completion with deterministic results
- Avoid vendor-specific constructs
- Use standard file organization for compilation order

### Example Test Process Structure
```vhdl
test_process : process
    variable test_passed : boolean;
    variable test_number : natural := 0;
begin
    -- Test initialization
    write(l, string'("=== TestBench Started ==="));
    writeline(output, l);
    
    -- Individual tests with consistent reporting
    test_passed := (actual_result = expected_result);
    report_test("Test description", test_passed, test_number);
    all_tests_passed <= all_tests_passed and test_passed;
    
    -- Final results
    if all_tests_passed then
        write(l, string'("ALL TESTS PASSED"));
    else
        write(l, string'("TEST FAILED"));
    end if;
    writeline(output, l);
    
    write(l, string'("SIMULATION DONE"));
    writeline(output, l);
    
    wait; -- End simulation
end process;
```

## GHDL Compilation and Execution

### Installation Requirements
- GHDL with VHDL-2008 support
- Recommended: GHDL 5.0+ with LLVM backend

### Standard Compilation Workflow
Execute from repository root directory:

```bash
# 1. Compile packages first (dependency order)
ghdl -a --std=08 modules/module_name/common/*.vhd
ghdl -a --std=08 modules/module_name/datadef/*.vhd  # if present

# 2. Compile core entities
ghdl -a --std=08 modules/module_name/core/*.vhd

# 3. Compile top entities (if present)  
ghdl -a --std=08 modules/module_name/top/*.vhd

# 4. Compile testbenches
ghdl -a --std=08 modules/module_name/tb/**/*.vhd

# 5. Elaborate testbench
ghdl -e --std=08 <testbench_entity_name>

# 6. Run simulation
ghdl -r --std=08 <testbench_entity_name>
```

### Package Testbench Example
```bash
# For PercentLut_pkg testbench
ghdl -a --std=08 modules/probe_driver/datadef/PercentLut_pkg.vhd && \
ghdl -a --std=08 modules/probe_driver/tb/datadef/PercentLut_pkg_tb.vhd && \
ghdl -e --std=08 PercentLut_pkg_tb && \
ghdl -r --std=08 PercentLut_pkg_tb
```

### Compilation Artifacts
GHDL creates compilation artifacts that should be ignored in version control:
- `work-obj*.cf` - GHDL work library files
- `*_tb` - Elaborated testbench executables  
- `*.o` - Object files
- `*.exe` - Windows executables

Add to `.gitignore`:
```
# GHDL compilation artifacts
work-obj*.cf
*_tb
*.o
*.exe
```

### Debugging Failed Compilation
1. **Dependency Issues**: Ensure packages are compiled before entities that use them
2. **VHDL Standard**: Always use `--std=08` flag
3. **File Path Issues**: Use paths relative to repository root
4. **Missing Libraries**: Ensure all required IEEE libraries are available

## Verilog Conversion Guidelines for Records

### Record Usage in Datadef Packages
When using records in `datadef/` packages, follow these guidelines to ensure Verilog compatibility:

#### Record Design Principles
- **Keep records simple**: Avoid nested records or complex type hierarchies
- **Use standard types**: Prefer `std_logic_vector`, `unsigned`, `signed`, and `natural`/`integer`
- **Document bit layouts**: Clearly document the bit field positions for Verilog conversion

#### Example Record Implementation
```vhdl
-- Good: Simple record with conversion utilities
type t_trigger_config is record
    trigger_threshold    : std_logic_vector(15 downto 0);
    duration_min         : natural;
    duration_max         : natural;
    intensity_min        : std_logic_vector(15 downto 0);
    intensity_max        : std_logic_vector(15 downto 0);
end record;

-- Conversion functions for Verilog compatibility
function trigger_config_to_packed(config : t_trigger_config) return std_logic_vector;
function packed_to_trigger_config(packed_data : std_logic_vector) return t_trigger_config;
```

#### Verilog Conversion Strategy
Records in datadef packages should be converted to:
1. **SystemVerilog structs** (preferred for modern tools)
2. **Packed parameter arrays** (for older Verilog tools)
3. **Flat signal groups** with explicit bit positioning

#### Conversion Documentation Requirements
- Document the bit field layout and total width
- Provide Verilog equivalent struct definitions
- Include conversion examples in package comments
- Specify which Verilog standard is targeted (Verilog-2005, SystemVerilog, etc.)

## Template Guidelines (`templates/**`)
- Keep templates minimal
- Ensure Verilog portability
- Follow all global coding rules
- Provide clear examples of proper usage

## Best Practices

### Configuration Parameter Validation

#### Safety-Critical Parameters (Required Validation)
- **Definition**: Parameters that affect module safety or core functionality
- **Validation Requirements**:
  - MUST be validated when module comes out of reset
  - MUST trigger error responses (e.g., FAULT_OUT) for invalid values
  - MUST maintain validation during runtime operation
- **Examples**: Wave selection, operation mode, safety thresholds, data widths
- **Error Response**: Module must enter safe state and assert error outputs
- **Signal Naming**: Use `cfg_safety_*` prefix for clarity

#### Configuration Parameters (Developer Discretion)
- **Definition**: Parameters that enhance performance, provide customization, or tune operation
- **Validation Requirements**:
  - Validation timing is at developer's discretion
  - Can be runtime configurable without safety concerns
  - Should have reasonable bounds checking
- **Examples**: Amplitude scaling, timing adjustments, performance tuning, output ranges
- **Error Response**: Can clamp to valid range, use default values, or ignore
- **Signal Naming**: Use `cfg_*` prefix

#### Implementation Guidelines
- **Reset Validation**: All safety-critical parameters MUST be validated on reset
- **Continuous Monitoring**: Safety-critical parameters should be continuously monitored
- **Error Handling**: Invalid safety-critical parameters must trigger FAULT_OUT or similar
- **Status Reporting**: Current configuration state should be reflected in status registers
- **Signal Distinction**: 
  - **Control signals** (`ctrl_*`): Enable/disable, start/stop operations
  - **Safety-critical parameters** (`cfg_safety_*`): Must be valid for safe operation
  - **Configuration parameters** (`cfg_*`): Can be tuned/adjusted

### Signal Declaration
```vhdl
signal data_bus : std_logic_vector(31 downto 0);
signal counter  : unsigned(15 downto 0);
signal state    : std_logic_vector(2 downto 0);
```

### Process Structure
```vhdl
process(clk, rst_n)
begin
    if rst_n = '0' then
        -- Reset logic
    elsif rising_edge(clk) then
        -- Synchronous logic
    end if;
end process;
```

### Generic Usage
```vhdl
generic (
    DATA_WIDTH : integer := 32;
    ADDR_WIDTH : integer := 8
);
```

## Verification Checklist

### RTL Code Requirements
Before submitting RTL code, ensure:
- [ ] No VHDL-only features used (records, enums in RTL, etc.) - **Exception: Records allowed in datadef packages**
- [ ] All ports use flat signal types (except datadef packages)
- [ ] FSMs use vector state encoding with named constants
- [ ] Proper signal prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- [ ] Explicit bit widths specified for all vectors
- [ ] Synchronous processes with proper reset
- [ ] Clear block end markers and consistent indentation
- [ ] No `wait` statements in RTL code
- [ ] **Top layer files use direct instantiation for all module connections**

### Testbench Requirements  
Before submitting testbenches, ensure:
- [ ] Testbench located in correct `tb/` subdirectory matching tested layer
- [ ] Follows naming convention: `<original_name>_tb.vhd`
- [ ] Entity name follows convention: `<original_name>_tb`
- [ ] Prints `'ALL TESTS PASSED'` on success
- [ ] Prints `'TEST FAILED'` on failure
- [ ] Always prints `'SIMULATION DONE'` at completion
- [ ] Individual test results are reported for visibility
- [ ] Uses deterministic test patterns
- [ ] Compiles successfully with `ghdl --std=08`
- [ ] Runs to completion without errors
- [ ] Comprehensive test coverage including edge cases
- [ ] Helper procedures used for consistent test reporting

### Package Testing (if applicable)
For package testbenches, additionally ensure:
- [ ] All public functions are tested
- [ ] Function overloading tested (if present)
- [ ] Multiple test data patterns used (linear, pattern-based, edge cases)
- [ ] Boundary conditions thoroughly tested
- [ ] Invalid input handling verified

### Datadef Package Testing (if using records)
For datadef packages with records, ensure:
- [ ] Basic record field access works
- [ ] Record constants are valid
- [ ] Simple conversion functions work (if provided)

### Documentation
- [ ] README.md exists for testbench directory with compilation instructions
- [ ] Test coverage and test cases are documented
- [ ] GHDL compilation commands provided

## Questions for Clarification
When working on this project, consider asking:
1. What is the target frequency and timing requirements?
2. Are there specific power constraints or clock gating requirements?
3. What is the target FPGA/ASIC technology?
4. Are there specific verification requirements beyond the basic testbench rules?
5. What are the interface requirements with other modules?
6. Are there specific naming conventions for internal signals?
7. What are the reset requirements (synchronous vs asynchronous)?
8. Are there specific area or resource constraints?

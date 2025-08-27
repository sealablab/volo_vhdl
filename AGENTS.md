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
- Records in port declarations
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
  - Data structure definitions using flat signals instead of records
  - Type conversion and packing/unpacking utilities  
  - Constants for bit field definitions and data widths
  - Validation functions for data structures
- **Constraints**:
  - No record types (use flat signals with explicit bit positions)
  - All types must be Verilog-portable
  - Use `std_logic_vector` for packed data representations
  - Define explicit bit field constants for easy Verilog translation

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
  - **Important**: DO NOT include MCC CustomWrapper entity body
  - Keep top-level modules clean and focused
  - **Note**: Not all modules will require a 'top' file

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

## Template Guidelines (`templates/**`)
- Keep templates minimal
- Ensure Verilog portability
- Follow all global coding rules
- Provide clear examples of proper usage

## Best Practices

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
- [ ] No VHDL-only features used (records, enums in RTL, etc.)
- [ ] All ports use flat signal types
- [ ] FSMs use vector state encoding with named constants
- [ ] Proper signal prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- [ ] Explicit bit widths specified for all vectors
- [ ] Synchronous processes with proper reset
- [ ] Clear block end markers and consistent indentation
- [ ] No `wait` statements in RTL code

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

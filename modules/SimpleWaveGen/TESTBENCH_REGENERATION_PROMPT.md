# SimpleWaveGen Testbench Regeneration Prompt

## Context
I have refactored the SimpleWaveGen module to eliminate code duplication by:
1. Consolidating wave selection constants in `platform_interface_pkg.vhd`
2. Moving sine lookup table to `waveform_common_pkg.vhd`
3. Updating core module to use package functions
4. Cleaning up unused constants and functions

## Current Module Structure
```
modules/SimpleWaveGen/
├── common/
│   ├── platform_interface_pkg.vhd    # Core interface definitions and validation
│   └── waveform_common_pkg.vhd      # Shared waveform components (sine LUT, utilities)
├── core/
│   └── SimpleWaveGen_core.vhd       # Pure waveform generation logic
├── top/
│   └── SimpleWaveGen_top.vhd        # Integration and register interface
└── tb/
    ├── common/                       # Package testbenches (currently empty)
    ├── core/                         # Core module testbench
    └── top/                          # Top-level integration testbench
```

## Functional Requirements
* All safety critical registers are validated with the appropriate utility functions in the `platform_interface_package' 
* `wave_out` increases over time for all valid waveforms.  (true because the square wave should reset to zero) 
* do __not__ create tightly coupled testbenches for each specific wave form. We don't want the complexity.


## Testbench Requirements

### 1. Package Testbenches (`tb/common/`)
- **`waveform_common_pkg_tb.vhd`**: Test sine LUT access, phase increment functions
- **`platform_interface_pkg_tb.vhd`**: Test validation functions, extraction functions

### 2. Core Testbench (`tb/core/`)
**Focus**: Individual module behavior, NOT integration
- Wave generation algorithms (square, triangle, sine)
- Safety-critical parameter validation
- Clock enable behavior
- Status register structure (bit 7 = enabled, bits 2:0 = wave select)
- Fault handling for invalid configurations
- **DO NOT TEST**: Register interface, clock divider integration

### 3. Top Testbench (`tb/top/`)
**Focus**: Integration and system-level behavior, NOT individual modules
- Register interface integration (write/read operations)
- Clock divider integration (verify clock enable generation)
- Fault aggregation across modules
- Status register exposure and readback
- **DO NOT TEST**: Individual wave generation (already covered in core)
- **DO NOT TEST**: Safety validation logic (already covered in core)

## Key Constraints
1. **No Duplication**: Top testbench must NOT duplicate core testbench coverage
2. **Direct Instantiation**: All testbenches must use direct instantiation
3. **GHDL Compatibility**: Must compile and run with `ghdl --std=08`
4. **Status Register Structure**: 
   - Core: `stat(7)` = enabled, `stat(2:0)` = wave select
   - Top: Minimal status exposure (enabled + fault only)
5. **Package Dependencies**: Core and top modules use both packages

## Current Issues to Fix
1. Top testbench references removed constants
2. Status register bit positions mismatch
3. Coverage overlap between testbenches
4. Missing package testbenches

## Expected Output
Please generate:
1. `tb/common/waveform_common_pkg_tb.vhd`
2. `tb/common/platform_interface_pkg_tb.vhd`  
3. `tb/core/SimpleWaveGen_core_tb.vhd` (updated)
4. `tb/top/SimpleWaveGen_top_tb.vhd` (updated)

Each testbench should:
- Follow AGENTS.md guidelines
- Use proper GHDL termination (`stop(0)`)
- Include comprehensive test coverage for its layer
- Avoid duplicating coverage from other layers
- Print proper test results and "SIMULATION DONE"

## Detailed Analysis of Current Issues

### **Current Issues Identified:**

1. **Missing Constants**: The top-level testbench references constants like `STATUS0_ENABLED_BIT`, `STATUS0_WAVE_SELECT_MSB`, etc. that were removed during refactoring.

2. **Coverage Overlap**: Both testbenches test similar functionality:
   - **Core testbench**: Tests wave generation, fault handling, clock enable behavior
   - **Top testbench**: Tests register interface, fault propagation, clock divider integration

3. **Status Register Mismatch**: The core uses `stat(7)` for enabled status, but the top testbench expects different bit positions.

4. **Package Dependencies**: The refactored code now uses `waveform_common_pkg.vhd` which needs proper testing.

### **Suggested Changes to Ensure Proper Test Coverage:**

1. **Core Testbench Focus** (`tb/core/`):
   - Wave generation algorithms (square, triangle, sine)
   - Individual module behavior
   - Safety-critical parameter validation
   - Clock enable behavior
   - Status register structure

2. **Top Testbench Focus** (`tb/top/`):
   - Register interface integration
   - Clock divider integration
   - Fault aggregation across modules
   - Status register exposure
   - **NOT** individual wave generation (already tested in core)

3. **Package Testbench** (`tb/common/`):
   - Test `waveform_common_pkg.vhd` functions
   - Test `platform_interface_pkg.vhd` functions

## Test Coverage Strategy
- **Core**: Test individual waveform generation and validation
- **Top**: Test integration, register interface, and system-level behavior
- **Common**: Test package functions and utilities
- **No Duplication**: Each layer tests only its responsibilities

## Compilation Order
```bash
# 1. Compile packages first
ghdl -a --std=08 common/platform_interface_pkg.vhd
ghdl -a --std=08 common/waveform_common_pkg.vhd

# 2. Compile core entities
ghdl -a --std=08 core/SimpleWaveGen_core.vhd

# 3. Compile top entities
ghdl -a --std=08 top/SimpleWaveGen_top.vhd

# 4. Compile testbenches
ghdl -a --std=08 tb/common/*.vhd
ghdl -a --std=08 tb/core/*.vhd
ghdl -a --std=08 tb/top/*.vhd

# 5. Elaborate and run individual testbenches
ghdl -e --std=08 <testbench_name>
ghdl -r --std=08 <testbench_name>
```

## Reference Files
- **AGENTS.md**: Project coding standards and guidelines
- **README-ghdl-testbench-tips.md**: GHDL-specific testing best practices
- **Current implementation files**: For understanding the refactored structure


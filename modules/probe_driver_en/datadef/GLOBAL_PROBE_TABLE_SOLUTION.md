# Global Probe Table Solution - Complete Implementation

## Overview

This document describes the complete implementation of a **Global Probe Table** solution that provides centralized probe configuration management for the entire project. The solution addresses your requirement to create a pre-defined set of probe configurations that can be exported and used throughout the project.

## What Was Created

### 1. Global_Probe_Table_pkg.vhd
- **Central package** containing all probe configurations
- **Pre-configured probes**: DS1120 and DS1130 with realistic parameters
- **Scalable design** for easy addition of new probe types
- **Type-safe access** functions with bounds checking
- **Verilog compatibility** maintained throughout

### 2. Global_Probe_Table_pkg_tb.vhd
- **Comprehensive testbench** validating all package functionality
- **13 test cases** covering all aspects of the package
- **GHDL compatible** and ready to run

### 3. probe_config_example.vhd
- **Practical example module** showing real-world usage
- **Multiple access patterns** demonstrating different approaches
- **Safety features** and configuration monitoring examples

### 4. Documentation
- **Global_Probe_Table_README.md**: Complete usage guide
- **GLOBAL_PROBE_TABLE_SOLUTION.md**: This summary document

## Key Benefits of This Solution

### ✅ **Centralized Management**
- All probe configurations in one location
- No more duplicated configuration data across modules
- Single source of truth for probe parameters

### ✅ **Easy Expansion**
- Adding new probes requires only 3 simple steps
- No changes needed to existing modules
- Maintains backward compatibility

### ✅ **Type Safety**
- Compile-time validation of probe configurations
- Runtime bounds checking for probe IDs
- Safe default configurations for invalid inputs

### ✅ **Verilog Compatibility**
- Follows all project coding standards
- Records only in datadef packages (as allowed)
- Maintains full Verilog portability

### ✅ **Comprehensive Testing**
- Full test coverage of all functionality
- GHDL compatible and verified working
- All 13 tests passing

## Current Probe Configurations

| Probe | ID | Trigger | Duration | Intensity | Cooldown |
|-------|----|---------|----------|-----------|----------|
| DS1120 | 0 | 3.3V | 100-1000 cycles | 0.5V-5.0V | 50-500 cycles |
| DS1130 | 1 | 2.5V | 150-1200 cycles | 0.3V-4.5V | 75-600 cycles |

## How to Use

### Basic Usage
```vhdl
-- Import the package
use work.Global_Probe_Table_pkg.all;

-- Get probe configuration
signal config : t_probe_config;
config <= get_probe_config(PROBE_ID_DS1120);

-- Safe access with bounds checking
config <= get_probe_config_safe(probe_id);
```

### Digital Configuration Access
```vhdl
-- Get digital representation directly
signal digital_config : t_probe_config_digital;
digital_config <= get_probe_config_digital(PROBE_ID_DS1120);
```

### Validation and Safety
```vhdl
-- Check if probe ID is valid
if is_valid_probe_id(probe_id) then
    config <= get_probe_config(probe_id);
end if;

-- Validate entire table
if is_global_probe_table_valid then
    -- All configurations are valid
end if;
```

## Adding New Probes (3 Simple Steps)

### Step 1: Add Probe ID
```vhdl
constant PROBE_ID_DS1140 : natural := 2;
```

### Step 2: Update Count
```vhdl
constant TOTAL_PROBE_TYPES : natural := 3;
```

### Step 3: Add Configuration
```vhdl
-- Add to GLOBAL_PROBE_TABLE array
PROBE_ID_DS1140 => (
    probe_trigger_voltage => 4.0,
    probe_duration_min     => 200,
    -- ... other parameters
)
```

## File Organization

```
modules/probe_driver/datadef/
├── Global_Probe_Table_pkg.vhd          # Main package
├── Global_Probe_Table_pkg_tb.vhd       # Testbench
├── Global_Probe_Table_README.md        # Usage guide
├── GLOBAL_PROBE_TABLE_SOLUTION.md      # This document
└── probe_config_example.vhd            # Example usage

modules/probe_driver/tb/datadef/
└── Global_Probe_Table_pkg_tb.vhd       # Testbench (duplicate for organization)
```

## Compilation and Testing

### Compilation Order
```bash
# 1. Dependencies
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd
ghdl -a --std=08 modules/probe_driver/datadef/Probe_Config_pkg.vhd

# 2. Global Probe Table package
ghdl -a --std=08 modules/probe_driver/datadef/Global_Probe_Table_pkg.vhd

# 3. Testbench
ghdl -a --std=08 modules/probe_driver/tb/datadef/Global_Probe_Table_pkg_tb.vhd

# 4. Elaborate and run
ghdl -e --std=08 Global_Probe_Table_pkg_tb
ghdl -r --std=08 Global_Probe_Table_pkg_tb
```

### Test Results
```
=== Test Results Summary ===
Total tests executed: 13
ALL TESTS PASSED
SIMULATION DONE
```

## Integration with Existing Code

### Current Modules
- **Probe_Config_pkg.vhd**: Provides base data types and validation
- **Moku_Voltage_pkg.vhd**: Handles voltage-to-digital conversion
- **Global_Probe_Table_pkg.vhd**: NEW - Provides centralized probe configurations

### Usage in Other Modules
```vhdl
-- In any module that needs probe configurations
use work.Global_Probe_Table_pkg.all;

-- Access configurations by probe ID
signal probe_config : t_probe_config;
probe_config <= get_probe_config(PROBE_ID_DS1120);
```

## Future Expansion Scenarios

### Scenario 1: Add New Probe Type
- Follow the 3-step process above
- No changes needed to existing modules
- New probe immediately available throughout project

### Scenario 2: Modify Existing Probe
- Update configuration in `GLOBAL_PROBE_TABLE`
- All modules using that probe automatically get new settings
- No need to modify multiple files

### Scenario 3: Add New Configuration Parameters
- Extend `t_probe_config` record in `Probe_Config_pkg.vhd`
- Update `Global_Probe_Table_pkg.vhd` with new parameters
- Recompile and test

## Best Practices for Usage

1. **Always use safe access functions** when probe ID might be invalid
2. **Validate configurations** before using in critical paths
3. **Use probe ID constants** instead of magic numbers
4. **Test new probe additions** thoroughly before deployment
5. **Document probe specifications** in the configuration table
6. **Keep probe IDs sequential** starting from 0 for easy maintenance

## Compliance with Project Standards

✅ **VHDL-2008**: Uses only VHDL-2008 features  
✅ **Verilog Portability**: Records only in datadef packages  
✅ **Signal Prefixes**: Follows `ctrl_*`, `cfg_*`, `stat_*` conventions  
✅ **Directory Structure**: Properly organized in `datadef/` layer  
✅ **Testbench Standards**: Follows all testbench requirements  
✅ **GHDL Compatibility**: Compiles and runs with GHDL  

## Summary

This Global Probe Table solution provides:

1. **Immediate Value**: Pre-configured DS1120 and DS1130 probes ready to use
2. **Scalability**: Easy addition of new probe types in the future
3. **Maintainability**: Centralized configuration management
4. **Reliability**: Comprehensive testing and validation
5. **Standards Compliance**: Follows all project coding standards

The solution minimizes complexity while maximizing flexibility, making it easy to add new probes in the future while maintaining a clean, maintainable codebase.

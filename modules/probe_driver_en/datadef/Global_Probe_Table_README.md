# Global Probe Table Package

## Overview

The `Global_Probe_Table_pkg` provides a centralized way to store and access pre-configured probe configurations for use throughout the entire project. This package eliminates the need to duplicate probe configuration data across multiple modules and provides a clean, maintainable interface for probe management.

## Key Features

- **Centralized Configuration**: All probe configurations stored in one location
- **Type-Safe Access**: Functions provide safe access to probe configurations
- **Easy Expansion**: Simple process to add new probe types
- **Verilog Compatibility**: Maintains full Verilog portability
- **Validation**: Built-in validation functions for all configurations
- **Digital Conversion**: Automatic conversion between voltage and digital representations

## Current Supported Probes

| Probe ID | Probe Name | Trigger Voltage | Duration Range | Intensity Range | Cooldown Range |
|----------|------------|-----------------|----------------|-----------------|----------------|
| 0        | DS1120     | 3.3V           | 100-1000 cycles | 0.5V-5.0V      | 50-500 cycles  |
| 1        | DS1130     | 2.5V           | 150-1200 cycles | 0.3V-4.5V      | 75-600 cycles  |

## Usage Examples

### Basic Configuration Access

```vhdl
-- Import the package
use work.Global_Probe_Table_pkg.all;

-- Get DS1120 configuration
signal ds1120_config : t_probe_config;
ds1120_config <= get_probe_config(PROBE_ID_DS1120);

-- Get DS1130 configuration
signal ds1130_config : t_probe_config;
ds1130_config <= get_probe_config(PROBE_ID_DS1130);
```

### Safe Configuration Access

```vhdl
-- Safe access with bounds checking (returns default config if invalid ID)
signal safe_config : t_probe_config;
safe_config <= get_probe_config_safe(probe_id);

-- Check if probe ID is valid before accessing
if is_valid_probe_id(probe_id) then
    config <= get_probe_config(probe_id);
else
    -- Handle invalid probe ID
end if;
```

### Digital Configuration Access

```vhdl
-- Get digital representation directly
signal digital_config : t_probe_config_digital;
digital_config <= get_probe_config_digital(PROBE_ID_DS1120);

-- Safe digital access
digital_config <= get_probe_config_digital_safe(probe_id);
```

### Utility Functions

```vhdl
-- Get probe name string
signal probe_name : string;
probe_name := get_probe_name(PROBE_ID_DS1120);  -- Returns "DS1120"

-- List all available probes
signal available_probes : string;
available_probes := list_available_probes();  -- Returns "DS1120, DS1130"

-- Get configuration as formatted string
signal config_string : string;
config_string := get_probe_config_string(PROBE_ID_DS1120);
```

## Adding New Probe Types

To add a new probe type, follow these steps:

### Step 1: Add Probe ID Constant

```vhdl
-- Add new probe identifier constant
constant PROBE_ID_DS1140 : natural := 2;  -- New probe ID
```

### Step 2: Update Total Count

```vhdl
-- Update the total number of supported probes
constant TOTAL_PROBE_TYPES : natural := 3;  -- Changed from 2 to 3
```

### Step 3: Add Configuration to Table

```vhdl
-- Add new probe configuration to the GLOBAL_PROBE_TABLE array
constant GLOBAL_PROBE_TABLE : t_probe_config_array := (
    -- DS1120 Configuration (existing)
    PROBE_ID_DS1120 => (
        probe_trigger_voltage => 3.3,
        probe_duration_min     => 100,
        probe_duration_max     => 1000,
        probe_intensity_min    => 0.5,
        probe_intensity_max    => 5.0,
        probe_cooldown_min     => 50,
        probe_cooldown_max     => 500
    ),
    
    -- DS1130 Configuration (existing)
    PROBE_ID_DS1130 => (
        probe_trigger_voltage => 2.5,
        probe_duration_min     => 150,
        probe_duration_max     => 1200,
        probe_intensity_min    => 0.3,
        probe_intensity_max    => 4.5,
        probe_cooldown_min     => 75,
        probe_cooldown_max     => 600
    ),
    
    -- DS1140 Configuration (NEW)
    PROBE_ID_DS1140 => (
        probe_trigger_voltage => 4.0,      -- 4.0V trigger voltage
        probe_duration_min     => 200,     -- 200 clock cycles minimum duration
        probe_duration_max     => 1500,    -- 1500 clock cycles maximum duration
        probe_intensity_min    => 0.8,     -- 0.8V minimum intensity
        probe_intensity_max    => 5.0,     -- 5.0V maximum intensity
        probe_cooldown_min     => 100,     -- 100 clock cycles minimum cooldown
        probe_cooldown_max     => 800      -- 800 clock cycles maximum cooldown
    )
);
```

### Step 4: Update Probe Name Function

```vhdl
function get_probe_name(probe_id : natural) return string is
begin
    case probe_id is
        when PROBE_ID_DS1120 => return "DS1120";
        when PROBE_ID_DS1130 => return "DS1130";
        when PROBE_ID_DS1140 => return "DS1140";  -- NEW
        when others => return "UNKNOWN";
    end case;
end function;
```

### Step 5: Test the New Configuration

```vhdl
-- In your testbench, verify the new probe works
signal new_probe_config : t_probe_config;
new_probe_config <= get_probe_config(PROBE_ID_DS1140);

-- Verify configuration values
assert new_probe_config.probe_trigger_voltage = 4.0
    report "DS1140 trigger voltage incorrect" severity error;
```

## Validation and Safety Features

### Configuration Validation

```vhdl
-- Validate entire probe table
if is_global_probe_table_valid then
    -- All configurations are valid
else
    -- Handle validation failure
end if;

-- Validate individual probe configuration
if is_valid_probe_config(get_probe_config(probe_id)) then
    -- Configuration is valid
else
    -- Handle invalid configuration
end if;
```

### Bounds Checking

```vhdl
-- Always use safe access functions when probe ID might be invalid
config <= get_probe_config_safe(probe_id);

-- Or check validity first
if is_valid_probe_id(probe_id) then
    config <= get_probe_config(probe_id);
else
    -- Handle invalid probe ID
end if;
```

## Compilation Order

When using this package, ensure proper compilation order:

```bash
# 1. Compile dependencies first
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd
ghdl -a --std=08 modules/probe_driver/datadef/Probe_Config_pkg.vhd

# 2. Compile this package
ghdl -a --std=08 modules/probe_driver/datadef/Global_Probe_Table_pkg.vhd

# 3. Compile modules that use this package
ghdl -a --std=08 modules/probe_driver/core/*.vhd
ghdl -a --std=08 modules/probe_driver/top/*.vhd
```

## Testing

Run the testbench to verify package functionality:

```bash
# Compile and run testbench
ghdl -a --std=08 modules/probe_driver/datadef/Global_Probe_Table_pkg.vhd && \
ghdl -a --std=08 modules/probe_driver/tb/datadef/Global_Probe_Table_pkg_tb.vhd && \
ghdl -e --std=08 Global_Probe_Table_pkg_tb && \
ghdl -r --std=08 Global_Probe_Table_pkg_tb
```

## Best Practices

1. **Always use safe access functions** when probe ID might be invalid
2. **Validate configurations** before using them in critical paths
3. **Use probe ID constants** instead of magic numbers
4. **Test new probe additions** thoroughly before deployment
5. **Document probe specifications** in the configuration table
6. **Keep probe IDs sequential** starting from 0 for easy maintenance

## Future Enhancements

Potential improvements for future versions:

- **Dynamic probe loading** from external configuration files
- **Probe configuration validation** against datasheet specifications
- **Probe compatibility checking** for different operating modes
- **Configuration versioning** for probe firmware updates
- **Probe performance metrics** and optimization suggestions

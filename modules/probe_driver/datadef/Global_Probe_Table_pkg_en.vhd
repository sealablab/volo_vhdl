--------------------------------------------------------------------------------
-- Package: Global_Probe_Table_pkg_en (Enhanced with Unit Hinting)
-- Purpose: Global probe configuration table for pre-defined probe types
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package provides a centralized table of pre-configured probe configurations
-- that can be used throughout the entire project. It allows easy addition of new
-- probe types while maintaining a clean interface for accessing configurations.
-- 
-- ENHANCED FEATURES:
-- - Unit hinting for all voltage, time, and configuration parameters
-- - Enhanced validation functions with unit consistency checking
-- - Comprehensive test data generation with unit awareness
-- - Zero synthesis overhead - pure documentation enhancement
-- 
-- DESIGN PRINCIPLES:
-- - Centralized probe configuration management
-- - Easy addition of new probe types
-- - Type-safe access to configurations
-- - Verilog compatibility maintained
-- - Clear separation of probe identification and configuration
-- - Unit consistency validation for type safety
-- 
-- UNIT CONVENTIONS:
-- - volts: Voltage values (V)
-- - clks: Clock cycle counts (cycles)
-- - index: Array indices and probe IDs (unitless)
-- - bits: Bit field widths and positions (bits)
-- - signal: Signal names and identifiers (unitless)
-- - package: Package names and identifiers (unitless)
-- - module: Module names and identifiers (unitless)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import probe configuration package
use work.Probe_Config_pkg.all;

-- Import PercentLut package for probe-specific intensity LUTs
use work.PercentLut_pkg.all;

package Global_Probe_Table_pkg_en is
    
    -- =============================================================================
    -- PROBE IDENTIFIER CONSTANTS
    -- =============================================================================
    
    -- Probe type identifiers (use descriptive names for clarity)
    -- Units: index (unitless probe identifiers)
    constant PROBE_ID_DS1120 : natural := 0;  -- DS1120 probe identifier [index]
    constant PROBE_ID_DS1130 : natural := 1;  -- DS1130 probe identifier [index]
    
    -- Total number of supported probes (update when adding new probes)
    -- Units: index (count of probe types)
    constant TOTAL_PROBE_TYPES : natural := 2;  -- [index]
    
    -- =============================================================================
    -- PROBE-SPECIFIC INTENSITY LUTs
    -- =============================================================================
    
    -- DS1120: Linear intensity curve optimized for 5V operation
    -- Units: package (LUT configuration record)
    constant DS1120_INTENSITY_LUT : percent_lut_record_t := LINEAR_5V_LUT;  -- [package]
    
    -- DS1130: Custom intensity curve optimized for 3.3V operation  
    -- Units: package (LUT configuration record)
    constant DS1130_INTENSITY_LUT : percent_lut_record_t := MOKU_3V3_LUT;  -- [package]
    
    -- =============================================================================
    -- DEFAULT/SAFE PROBE CONFIGURATION
    -- =============================================================================
    
    -- Safe default configuration for invalid probe IDs
    -- This provides a predictable, safe fallback when probe ID is out of bounds
    -- Units: volts for voltages, clks for durations, package for LUT
    constant DEFAULT_SAFE_PROBE_CONFIG : t_probe_config := (
        probe_trigger_voltage => 0.0,      -- Safe default: 0V (no trigger) [volts]
        probe_duration_min     => 100,     -- Safe default: 100 cycles [clks]
        probe_duration_max     => 100,     -- Safe default: 100 cycles [clks]
        probe_intensity_min    => 0.0,     -- Safe default: 0V (no intensity) [volts]
        probe_intensity_max    => 0.0,     -- Safe default: 0V (no intensity) [volts]
        probe_cooldown_min     => 100,     -- Safe default: 100 cycles [clks]
        probe_cooldown_max     => 100,     -- Safe default: 100 cycles [clks]
        probe_intensity_lut    => LINEAR_5V_LUT  -- Safe, predictable default LUT [package]
    );
    
    -- =============================================================================
    -- PROBE CONFIGURATION TABLE
    -- =============================================================================
    
    -- Array type for storing probe configurations
    -- Units: package (array of probe configuration records)
    type t_probe_config_array is array (0 to TOTAL_PROBE_TYPES-1) of t_probe_config;  -- [package]
    
    -- Global probe configuration table
    -- Add new probe configurations here by extending the array and updating TOTAL_PROBE_TYPES
    -- Units: package (table of probe configurations)
    constant GLOBAL_PROBE_TABLE : t_probe_config_array := (
        -- DS1120 Configuration
        PROBE_ID_DS1120 => (
            probe_trigger_voltage => 3.3,      -- 3.3V trigger voltage [volts]
            probe_duration_min     => 100,     -- 100 clock cycles minimum duration [clks]
            probe_duration_max     => 1000,    -- 1000 clock cycles maximum duration [clks]
            probe_intensity_min    => 0.5,     -- 0.5V minimum intensity [volts]
            probe_intensity_max    => 5.0,     -- 5.0V maximum intensity [volts]
            probe_cooldown_min     => 50,      -- 50 clock cycles minimum cooldown [clks]
            probe_cooldown_max     => 500,     -- 500 clock cycles maximum cooldown [clks]
            probe_intensity_lut    => DS1120_INTENSITY_LUT  -- Probe's own authoritative LUT [package]
        ),
        
        -- DS1130 Configuration
        PROBE_ID_DS1130 => (
            probe_trigger_voltage => 2.5,      -- 2.5V trigger voltage [volts]
            probe_duration_min     => 150,     -- 150 clock cycles minimum duration [clks]
            probe_duration_max     => 1200,    -- 1200 clock cycles maximum duration [clks]
            probe_intensity_min    => 0.3,     -- 0.3V minimum intensity [volts]
            probe_intensity_max    => 4.5,     -- 4.5V maximum intensity [volts]
            probe_cooldown_min     => 75,      -- 75 clock cycles minimum cooldown [clks]
            probe_cooldown_max     => 600,     -- 600 clock cycles maximum cooldown [clks]
            probe_intensity_lut    => DS1130_INTENSITY_LUT  -- Probe's own authoritative LUT [package]
        )
    );
    
    -- =============================================================================
    -- ACCESS FUNCTIONS
    -- =============================================================================
    
    -- Get probe configuration by probe ID
    -- Input: probe_id [index] - Probe identifier
    -- Output: t_probe_config [package] - Probe configuration record
    function get_probe_config(probe_id : natural) return t_probe_config;
    
    -- Get probe configuration by probe ID (with bounds checking)
    -- Input: probe_id [index] - Probe identifier
    -- Output: t_probe_config [package] - Probe configuration record (safe default if invalid)
    function get_probe_config_safe(probe_id : natural) return t_probe_config;
    
    -- Get digital probe configuration by probe ID
    -- Input: probe_id [index] - Probe identifier
    -- Output: t_probe_config_digital [package] - Digital probe configuration record
    function get_probe_config_digital(probe_id : natural) return t_probe_config_digital;
    
    -- Get digital probe configuration by probe ID (with bounds checking)
    -- Input: probe_id [index] - Probe identifier
    -- Output: t_probe_config_digital [package] - Digital probe configuration record (safe default if invalid)
    function get_probe_config_digital_safe(probe_id : natural) return t_probe_config_digital;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Check if probe ID is valid
    -- Input: probe_id [index] - Probe identifier to validate
    -- Output: boolean - True if probe ID is within valid range
    function is_valid_probe_id(probe_id : natural) return boolean;
    
    -- Validate all probe configurations in the table
    -- Output: boolean - True if all probe configurations are valid
    function is_global_probe_table_valid return boolean;
    
    -- Enhanced validation with unit consistency checking
    -- Input: probe_id [index] - Probe identifier to validate
    -- Output: boolean - True if probe configuration is valid and units are consistent
    function is_probe_config_valid_with_units(probe_id : natural) return boolean;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    -- Get probe name string from probe ID
    -- Input: probe_id [index] - Probe identifier
    -- Output: string - Probe name string
    function get_probe_name(probe_id : natural) return string;
    
    -- List all available probe types
    -- Output: string - Comma-separated list of available probe names
    function list_available_probes return string;
    
    -- Get probe configuration as string
    -- Input: probe_id [index] - Probe identifier
    -- Output: string - Formatted probe configuration string
    function get_probe_config_string(probe_id : natural) return string;
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    
    -- Generate test probe configuration with unit validation
    -- Input: probe_id [index] - Probe identifier for test data
    -- Output: t_probe_config [package] - Test probe configuration
    function generate_test_probe_config(probe_id : natural) return t_probe_config;
    
    -- Generate test probe configuration array for all probe types
    -- Output: t_probe_config_array [package] - Array of test probe configurations
    function generate_test_probe_config_array return t_probe_config_array;
    
    -- Generate test probe ID with bounds checking
    -- Input: test_index [index] - Test case index
    -- Output: natural [index] - Test probe ID (valid or invalid based on test case)
    function generate_test_probe_id(test_index : natural) return natural;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Get expected units for probe configuration field
    -- Input: field_name [signal] - Name of the configuration field
    -- Output: string - Expected units for the field
    function get_expected_units(field_name : string) return string;
    
    -- Validate units consistency for probe configuration
    -- Input: config [package] - Probe configuration to validate
    -- Output: boolean - True if all units are consistent with expected values
    function validate_units_consistency(config : t_probe_config) return boolean;

end package Global_Probe_Table_pkg_en;
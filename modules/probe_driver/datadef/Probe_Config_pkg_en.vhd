--------------------------------------------------------------------------------
-- Package: Probe_Config_pkg_en (Enhanced with Unit Hinting)
-- Purpose: Probe configuration datatype for SCA/FI Probe triggers with voltage integration
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package defines probe configuration parameters with both voltage-based
-- configuration interface and digital implementation. The voltage interface provides
-- intuitive configuration while maintaining Verilog compatibility through conversion
-- functions.
-- 
-- ENHANCED FEATURES:
-- - Unit hinting for all voltage, time, and configuration parameters
-- - Enhanced validation functions with unit consistency checking
-- - Comprehensive test data generation with unit awareness
-- - Zero synthesis overhead - pure documentation enhancement
-- 
-- INTEGRATION WITH MOKU_VOLTAGE_PKG:
-- - Uses voltage values for configuration (more intuitive)
-- - Converts to digital values for RTL implementation
-- - Leverages Moku platform voltage specifications (-5V to +5V)
-- - Maintains full Verilog compatibility
-- 
-- UNIT CONVENTIONS:
-- - volts: Voltage values (V)
-- - clks: Clock cycle counts (cycles)
-- - bits: Bit field widths and positions (bits)
-- - signal: Signal names and identifiers (unitless)
-- - package: Package names and identifiers (unitless)
-- - module: Module names and identifiers (unitless)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import Moku voltage conversion utilities
use work.Moku_Voltage_pkg.all;

-- Import PercentLut package for intensity curve LUTs
use work.PercentLut_pkg.all;

package Probe_Config_pkg_en is
    
    -- =============================================================================
    -- DATA WIDTH CONSTANTS
    -- =============================================================================
    
    -- Constants for data widths
    -- Units: bits (bit field widths)
    constant PROBE_TRIGGER_VOLTAGE_WIDTH : natural := 16;  -- 16-bit signed for trigger voltage [bits]
    constant PROBE_DURATION_WIDTH : natural := 16;   -- 16-bit unsigned for duration [bits]
    constant PROBE_INTENSITY_WIDTH : natural := 16;  -- 16-bit signed for voltage intensity [bits]
    
    -- =============================================================================
    -- VOLTAGE-BASED CONFIGURATION INTERFACE
    -- =============================================================================
    
    -- Primary probe configuration using voltage values (configuration layer)
    -- Units: volts for voltages, clks for durations, package for LUT
    type t_probe_config is record
        probe_trigger_voltage : real;  -- Voltage to output to trigger the probe [volts]
        probe_duration_min     : natural;  -- Duration in clock cycles [clks]
        probe_duration_max     : natural;  -- Duration in clock cycles [clks]
        probe_intensity_min    : real;  -- Minimum intensity voltage in volts [volts]
        probe_intensity_max    : real;  -- Maximum intensity voltage in volts [volts]
        probe_cooldown_min     : natural;  -- Cooldown in clock cycles [clks]
        probe_cooldown_max     : natural;  -- Cooldown in clock cycles [clks]
        probe_intensity_lut    : percent_lut_record_t;  -- Probe's own authoritative intensity LUT [package]
    end record;
    
    -- =============================================================================
    -- DIGITAL IMPLEMENTATION INTERFACE
    -- =============================================================================
    
    -- Digital representation for RTL implementation (internal use)
    -- Units: bits for digital values, clks for durations, package for LUT
    type t_probe_config_digital is record
        probe_trigger_voltage : std_logic_vector(PROBE_TRIGGER_VOLTAGE_WIDTH-1 downto 0);  -- [bits]
        probe_duration_min     : natural;  -- Duration in clock cycles [clks]
        probe_duration_max     : natural;  -- Duration in clock cycles [clks]
        probe_intensity_min    : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);  -- [bits]
        probe_intensity_max    : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);  -- [bits]
        probe_cooldown_min     : natural;  -- Cooldown in clock cycles [clks]
        probe_cooldown_max     : natural;  -- Cooldown in clock cycles [clks]
        probe_intensity_lut    : percent_lut_record_t;  -- Probe's own authoritative intensity LUT [package]
    end record;
    
    -- =============================================================================
    -- CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert voltage-based configuration to digital representation
    -- Input: config [package] - Voltage-based probe configuration
    -- Output: t_probe_config_digital [package] - Digital probe configuration
    function probe_config_to_digital(config : t_probe_config) return t_probe_config_digital;
    
    -- Convert digital representation to voltage-based configuration
    -- Input: digital_config [package] - Digital probe configuration
    -- Output: t_probe_config [package] - Voltage-based probe configuration
    function digital_to_probe_config(digital_config : t_probe_config_digital) return t_probe_config;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Validate voltage-based configuration
    -- Input: config [package] - Probe configuration to validate
    -- Output: boolean - True if configuration is valid
    function is_valid_probe_config(config : t_probe_config) return boolean;
    
    -- Validate digital configuration
    -- Input: digital_config [package] - Digital probe configuration to validate
    -- Output: boolean - True if digital configuration is valid
    function is_valid_probe_config_digital(digital_config : t_probe_config_digital) return boolean;
    
    -- Enhanced validation with unit consistency checking
    -- Input: config [package] - Probe configuration to validate
    -- Output: boolean - True if configuration is valid and units are consistent
    function is_probe_config_valid_with_units(config : t_probe_config) return boolean;
    
    -- Enhanced validation with unit consistency checking for digital configuration
    -- Input: digital_config [package] - Digital probe configuration to validate
    -- Output: boolean - True if digital configuration is valid and units are consistent
    function is_probe_config_digital_valid_with_units(digital_config : t_probe_config_digital) return boolean;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    -- Convert configuration to string for debugging
    -- Input: config [package] - Probe configuration to convert
    -- Output: string - String representation of configuration
    function probe_config_to_string(config : t_probe_config) return string;
    
    -- Input: digital_config [package] - Digital probe configuration to convert
    -- Output: string - String representation of digital configuration
    function probe_config_digital_to_string(digital_config : t_probe_config_digital) return string;
    
    -- Check if two configurations are equivalent
    -- Input: config1, config2 [package] - Probe configurations to compare
    -- Output: boolean - True if configurations are equivalent
    function probe_configs_equal(config1, config2 : t_probe_config) return boolean;
    
    -- Input: digital_config1, digital_config2 [package] - Digital probe configurations to compare
    -- Output: boolean - True if digital configurations are equivalent
    function probe_configs_digital_equal(digital_config1, digital_config2 : t_probe_config_digital) return boolean;
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    
    -- Generate test probe configuration with unit validation
    -- Input: test_index [index] - Test case index
    -- Output: t_probe_config [package] - Test probe configuration
    function generate_test_probe_config(test_index : natural) return t_probe_config;
    
    -- Generate test digital probe configuration with unit validation
    -- Input: test_index [index] - Test case index
    -- Output: t_probe_config_digital [package] - Test digital probe configuration
    function generate_test_probe_config_digital(test_index : natural) return t_probe_config_digital;
    
    -- Generate test probe configuration with specific parameters
    -- Input: trigger_voltage [volts], duration_min [clks], duration_max [clks], intensity_min [volts], intensity_max [volts], cooldown_min [clks], cooldown_max [clks]
    -- Output: t_probe_config [package] - Test probe configuration
    function generate_custom_probe_config(trigger_voltage : real; duration_min : natural; duration_max : natural; intensity_min : real; intensity_max : real; cooldown_min : natural; cooldown_max : natural) return t_probe_config;
    
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
    
    -- Validate units consistency for digital probe configuration
    -- Input: digital_config [package] - Digital probe configuration to validate
    -- Output: boolean - True if all units are consistent with expected values
    function validate_units_consistency_digital(digital_config : t_probe_config_digital) return boolean;

end package Probe_Config_pkg_en;
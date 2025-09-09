-- =============================================================================
-- Enhanced Probe Configuration Package
-- =============================================================================
-- 
-- COPIED FROM: modules/probe_hero8/datadef/Probe_Config_pkg_en.vhd
-- DATE: 2025-01-27
-- PURPOSE: Base data definitions for ProbeHero9 development
-- 
-- NOTE: This file may be modified for ProbeHero9-specific enhancements
-- =============================================================================
-- 
-- This enhanced package provides probe configuration data types and validation
-- functions for ProbeHero9. It includes comprehensive validation, error handling,
-- and unit hinting for improved type safety and testbench validation.
-- 
-- DEPENDENCIES:
-- - Moku_Voltage_pkg_en_PH9: For voltage data width and voltage-related constants
--
-- UNIT CONVENTIONS:
-- - voltage values: volts (voltage output levels)
-- - duration values: clks (clock cycles for timing)
-- - intensity values: ratio (percentage/intensity scaling)
-- - index values: index (table/array indices)
-- - signal values: signal (control and status signals)
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Moku_Voltage_pkg_PH9.ALL;

package Probe_Config_pkg_PH9 is

    -- =========================================================================
    -- System Constants with Unit Documentation
    -- =========================================================================
    -- Note: SYSTEM_VOLTAGE_WIDTH now uses VOLTAGE_DATA_WIDTH from Moku_Voltage_pkg_en_PH9
    constant SYSTEM_DURATION_WIDTH : natural := 16; -- Units: bits (duration data width)
    constant SYSTEM_INTENSITY_WIDTH : natural := 7; -- Units: bits (intensity index width)
    constant SYSTEM_MAX_PROBES : natural := 4;      -- Units: count (maximum probe configurations)
    
    -- =========================================================================
    -- Probe Configuration Record with Unit Documentation
    -- =========================================================================
    -- Units: record containing probe configuration data
    type t_probe_config is record
        -- Probe identification
        probe_name : string(1 to 16);                    -- Units: string (probe identifier)
        
        -- Voltage configuration (Units: volts)
        probe_trigger_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        probe_intensity_min   : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        probe_intensity_max   : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        
        -- Timing configuration (Units: clks)
        fire_duration_min     : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        fire_duration_max     : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        cooldown_duration_min : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        cooldown_duration_max : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        
        -- Safety configuration
        safety_enabled        : std_logic;                                          -- Units: signal
        max_fire_rate         : unsigned(15 downto 0);                              -- Units: clks (minimum time between fires)
    end record;
    
    -- =========================================================================
    -- Probe Configuration Array Type
    -- =========================================================================
    -- Units: array of probe configuration records
    type t_probe_config_array is array (0 to SYSTEM_MAX_PROBES-1) of t_probe_config;
    
    -- =========================================================================
    -- Validation Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: probe config (record) -> output: boolean (validity)
    -- Purpose: Validates that a probe configuration is safe and consistent
    function is_valid_probe_config(config : t_probe_config) return boolean;
    
    -- Units: input: voltage (volts), min_voltage (volts), max_voltage (volts) -> output: boolean
    -- Purpose: Validates that a voltage is within safe operating range
    -- Note: Now uses is_voltage_in_range_safe from Moku_Voltage_pkg_en_PH9
    function is_voltage_in_range(voltage : std_logic_vector; min_voltage, max_voltage : std_logic_vector) return boolean;
    
    -- Units: input: duration (clks), min_duration (clks), max_duration (clks) -> output: boolean
    -- Purpose: Validates that a duration is within safe operating range
    function is_duration_in_range(duration : unsigned; min_duration, max_duration : unsigned) return boolean;
    
    -- Units: input: voltage (volts), min_voltage (volts), max_voltage (volts) -> output: voltage (volts)
    -- Purpose: Clamps voltage to safe operating range
    -- Note: Now uses clamp_voltage_safe from Moku_Voltage_pkg_en_PH9
    function clamp_voltage(voltage : std_logic_vector; min_voltage, max_voltage : std_logic_vector) return std_logic_vector;
    
    -- Units: input: duration (clks), min_duration (clks), max_duration (clks) -> output: duration (clks)
    -- Purpose: Clamps duration to safe operating range
    function clamp_duration(duration : unsigned; min_duration, max_duration : unsigned) return unsigned;
    
    -- =========================================================================
    -- Safe Access Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: config array (array), index (index) -> output: probe config (record)
    -- Purpose: Safe access to probe configuration with bounds checking
    function get_probe_config_safe(config_array : t_probe_config_array; index : natural) return t_probe_config;
    
    -- Units: input: config array (array), index (index) -> output: boolean (validity)
    -- Purpose: Validates that an index is valid for the configuration array
    function is_valid_probe_index(index : natural) return boolean;
    
    -- =========================================================================
    -- Default Configuration Constants
    -- =========================================================================
    
    -- Default probe configuration (Units: record)
    constant DEFAULT_PROBE_CONFIG : t_probe_config := (
        probe_name => "DEFAULT_PROBE   ",
        probe_trigger_voltage => x"1000",  -- Units: volts (1.0V)
        probe_intensity_min   => x"0000",  -- Units: volts (0.0V)
        probe_intensity_max   => x"2000",  -- Units: volts (2.0V)
        fire_duration_min     => to_unsigned(10, SYSTEM_DURATION_WIDTH),    -- Units: clks
        fire_duration_max     => to_unsigned(1000, SYSTEM_DURATION_WIDTH),  -- Units: clks
        cooldown_duration_min => to_unsigned(100, SYSTEM_DURATION_WIDTH),   -- Units: clks
        cooldown_duration_max => to_unsigned(10000, SYSTEM_DURATION_WIDTH), -- Units: clks
        safety_enabled        => '1',      -- Units: signal
        max_fire_rate         => to_unsigned(1000, 16)  -- Units: clks
    );
    
    -- Safe default configuration array (Units: array)
    constant DEFAULT_PROBE_CONFIG_ARRAY : t_probe_config_array := (
        0 => DEFAULT_PROBE_CONFIG,
        1 => DEFAULT_PROBE_CONFIG,
        2 => DEFAULT_PROBE_CONFIG,
        3 => DEFAULT_PROBE_CONFIG
    );

end package Probe_Config_pkg_PH9;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body Probe_Config_pkg_PH9 is

    -- =========================================================================
    -- Validation Function Implementations
    -- =========================================================================
    
    function is_valid_probe_config(config : t_probe_config) return boolean is
        variable is_valid : boolean := true;
    begin
        -- Check voltage ranges are consistent
        if config.probe_intensity_min >= config.probe_intensity_max then
            is_valid := false;
        end if;
        
        -- Check duration ranges are consistent
        if config.fire_duration_min >= config.fire_duration_max then
            is_valid := false;
        end if;
        
        if config.cooldown_duration_min >= config.cooldown_duration_max then
            is_valid := false;
        end if;
        
        -- Check for reasonable voltage ranges (basic sanity check)
        if config.probe_trigger_voltage = x"0000" or 
           (config.probe_intensity_min = x"0000" and config.probe_intensity_max = x"0000") then
            is_valid := false;
        end if;
        
        return is_valid;
    end function;
    
    function is_voltage_in_range(voltage : std_logic_vector; min_voltage, max_voltage : std_logic_vector) return boolean is
    begin
        -- Delegate to Moku_Voltage_pkg_en_PH9 function
        return is_voltage_in_range_safe(voltage, min_voltage, max_voltage);
    end function;
    
    function is_duration_in_range(duration : unsigned; min_duration, max_duration : unsigned) return boolean is
    begin
        return (duration >= min_duration) and (duration <= max_duration);
    end function;
    
    function clamp_voltage(voltage : std_logic_vector; min_voltage, max_voltage : std_logic_vector) return std_logic_vector is
    begin
        -- Delegate to Moku_Voltage_pkg_en_PH9 function
        return clamp_voltage_safe(voltage, min_voltage, max_voltage);
    end function;
    
    function clamp_duration(duration : unsigned; min_duration, max_duration : unsigned) return unsigned is
        variable clamped_duration : unsigned(duration'range);
    begin
        if duration < min_duration then
            clamped_duration := min_duration;
        elsif duration > max_duration then
            clamped_duration := max_duration;
        else
            clamped_duration := duration;
        end if;
        return clamped_duration;
    end function;
    
    -- =========================================================================
    -- Safe Access Function Implementations
    -- =========================================================================
    
    function get_probe_config_safe(config_array : t_probe_config_array; index : natural) return t_probe_config is
    begin
        if is_valid_probe_index(index) then
            return config_array(index);
        else
            return DEFAULT_PROBE_CONFIG;
        end if;
    end function;
    
    function is_valid_probe_index(index : natural) return boolean is
    begin
        return (index < SYSTEM_MAX_PROBES);
    end function;

end package body Probe_Config_pkg_PH9;
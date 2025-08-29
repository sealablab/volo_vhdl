--------------------------------------------------------------------------------
-- Package: Probe_Config_pkg
-- Purpose: Probe configuration datatype for SCA/FI Probe triggers with voltage integration
-- Author: johnnyc
-- Date: 2025-08-26
-- 
-- This package defines probe configuration parameters with both voltage-based
-- configuration interface and digital implementation. The voltage interface provides
-- intuitive configuration while maintaining Verilog compatibility through conversion
-- functions.
-- 
-- INTEGRATION WITH MOKU_VOLTAGE_PKG:
-- - Uses voltage values for configuration (more intuitive)
-- - Converts to digital values for RTL implementation
-- - Leverages Moku platform voltage specifications (-5V to +5V)
-- - Maintains full Verilog compatibility
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import Moku voltage conversion utilities
use work.Moku_Voltage_pkg.all;

-- Import PercentLut package for intensity curve LUTs
use work.PercentLut_pkg.all;

package Probe_Config_pkg is
    
    -- =============================================================================
    -- DATA WIDTH CONSTANTS
    -- =============================================================================
    
    -- Constants for data widths

    constant PROBE_TRIGGER_VOLTAGE_WIDTH : natural := 16;  -- 16-bit signed for trigger voltage
    constant PROBE_DURATION_WIDTH : natural := 16;   -- 16-bit unsigned for duration
    constant PROBE_INTENSITY_WIDTH : natural := 16;  -- 16-bit signed for voltage intensity
    
    -- =============================================================================
    -- VOLTAGE-BASED CONFIGURATION INTERFACE
    -- =============================================================================
    
    -- Primary probe configuration using voltage values (configuration layer)
    type t_probe_config is record
        probe_trigger_voltage : real;  -- Voltage to output to trigger the probe
        probe_duration_min     : natural;  -- Duration in clock cycles
        probe_duration_max     : natural;  -- Duration in clock cycles
        probe_intensity_min    : real;  -- Minimum intensity voltage in volts
        probe_intensity_max    : real;  -- Maximum intensity voltage in volts
        probe_cooldown_min     : natural;  -- Cooldown in clock cycles
        probe_cooldown_max     : natural;  -- Cooldown in clock cycles
        probe_intensity_lut    : percent_lut_record_t;  -- Probe's own authoritative intensity LUT
    end record;
    
    -- =============================================================================
    -- DIGITAL IMPLEMENTATION INTERFACE
    -- =============================================================================
    
    -- Digital representation for RTL implementation (internal use)
    type t_probe_config_digital is record
        probe_trigger_voltage : std_logic_vector(PROBE_TRIGGER_VOLTAGE_WIDTH-1 downto 0);
        probe_duration_min     : natural;  -- Duration in clock cycles
        probe_duration_max     : natural;  -- Duration in clock cycles
        probe_intensity_min    : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);
        probe_intensity_max    : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);
        probe_cooldown_min     : natural;  -- Cooldown in clock cycles
        probe_cooldown_max     : natural;  -- Cooldown in clock cycles
        probe_intensity_lut    : percent_lut_record_t;  -- Probe's own authoritative intensity LUT
    end record;
    
    -- =============================================================================
    -- CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert voltage-based configuration to digital representation
    function probe_config_to_digital(config : t_probe_config) return t_probe_config_digital;
    
    -- Convert digital representation to voltage-based configuration
    function digital_to_probe_config(digital_config : t_probe_config_digital) return t_probe_config;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Validate voltage-based configuration
    function is_valid_probe_config(config : t_probe_config) return boolean;
    
    -- Validate digital configuration
    function is_valid_probe_config_digital(digital_config : t_probe_config_digital) return boolean;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    -- Convert configuration to string for debugging
    function probe_config_to_string(config : t_probe_config) return string;
    function probe_config_digital_to_string(digital_config : t_probe_config_digital) return string;
    
    -- Check if two configurations are equivalent
    function probe_configs_equal(config1, config2 : t_probe_config) return boolean;
    function probe_configs_digital_equal(digital_config1, digital_config2 : t_probe_config_digital) return boolean;

end package Probe_Config_pkg;

package body Probe_Config_pkg is
    
    -- =============================================================================
    -- CONVERSION FUNCTIONS
    -- =============================================================================
    
    function probe_config_to_digital(config : t_probe_config) return t_probe_config_digital is
        variable digital_config : t_probe_config_digital;
    begin
        -- Convert trigger voltage to digital using Moku voltage package
        digital_config.probe_trigger_voltage := voltage_to_digital_vector(config.probe_trigger_voltage);
        
        -- Duration values remain the same (natural type)
        digital_config.probe_duration_min := config.probe_duration_min;
        digital_config.probe_duration_max := config.probe_duration_max;
        
        -- Cooldown values remain the same (natural type)
        digital_config.probe_cooldown_min := config.probe_cooldown_min;
        digital_config.probe_cooldown_max := config.probe_cooldown_max;
        
        -- Convert intensity voltages to digital using Moku voltage package
        digital_config.probe_intensity_min := voltage_to_digital_vector(config.probe_intensity_min);
        digital_config.probe_intensity_max := voltage_to_digital_vector(config.probe_intensity_max);
        
        -- LUT field remains the same (percent_lut_record_t type)
        digital_config.probe_intensity_lut := config.probe_intensity_lut;
        
        return digital_config;
    end function;
    
    function digital_to_probe_config(digital_config : t_probe_config_digital) return t_probe_config is
        variable config : t_probe_config;
    begin
        -- Convert digital trigger voltage to voltage using Moku voltage package
        config.probe_trigger_voltage := digital_to_voltage(digital_config.probe_trigger_voltage);
        
        -- Duration values remain the same (natural type)
        config.probe_duration_min := digital_config.probe_duration_min;
        config.probe_duration_max := digital_config.probe_duration_max;
        
        -- Cooldown values remain the same (natural type)
        config.probe_cooldown_min := digital_config.probe_cooldown_min;
        config.probe_cooldown_max := digital_config.probe_cooldown_max;
        
        -- Convert digital intensity values to voltage using Moku voltage package
        config.probe_intensity_min := digital_to_voltage(digital_config.probe_intensity_min);
        config.probe_intensity_max := digital_to_voltage(digital_config.probe_intensity_max);
        
        -- LUT field remains the same (percent_lut_record_t type)
        config.probe_intensity_lut := digital_config.probe_intensity_lut;
        
        return config;
    end function;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    function is_valid_probe_config(config : t_probe_config) return boolean is
    begin
        -- Check voltage ranges using Moku voltage package
        if not is_valid_moku_voltage(config.probe_trigger_voltage) then
            return false;
        end if;
        
        if not is_valid_moku_voltage(config.probe_intensity_min) then
            return false;
        end if;
        
        if not is_valid_moku_voltage(config.probe_intensity_max) then
            return false;
        end if;
        
        -- Check duration constraints
        if config.probe_duration_min > config.probe_duration_max then
            return false;
        end if;
        
        if config.probe_duration_min = 0 or config.probe_duration_max = 0 then
            return false;
        end if;
        
        -- Check cooldown constraints
        if config.probe_cooldown_min > config.probe_cooldown_max then
            return false;
        end if;
        
        if config.probe_cooldown_min = 0 or config.probe_cooldown_max = 0 then
            return false;
        end if;
        
        -- Check intensity range
        if config.probe_intensity_min > config.probe_intensity_max then
            return false;
        end if;
        
        -- Validate LUT (basic validation that LUT exists and is valid)
        if not is_percent_lut_record_valid(config.probe_intensity_lut) then
            return false;
        end if;
        
        return true;
    end function;
    
    function is_valid_probe_config_digital(digital_config : t_probe_config_digital) return boolean is
    begin
        -- Check digital value ranges using Moku voltage package
        if not is_valid_moku_digital(digital_config.probe_trigger_voltage) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.probe_intensity_min) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.probe_intensity_max) then
            return false;
        end if;
        
        -- Check duration constraints
        if digital_config.probe_duration_min > digital_config.probe_duration_max then
            return false;
        end if;
        
        if digital_config.probe_duration_min = 0 or digital_config.probe_duration_max = 0 then
            return false;
        end if;
        
        -- Check cooldown constraints
        if digital_config.probe_cooldown_min > digital_config.probe_cooldown_max then
            return false;
        end if;
        
        if digital_config.probe_cooldown_min = 0 or digital_config.probe_cooldown_max = 0 then
            return false;
        end if;
        
        -- Check intensity range (as unsigned comparison)
        if unsigned(digital_config.probe_intensity_min) > unsigned(digital_config.probe_intensity_max) then
            return false;
        end if;
        
        -- Validate LUT (basic validation that LUT exists and is valid)
        if not is_percent_lut_record_valid(digital_config.probe_intensity_lut) then
            return false;
        end if;
        
        return true;
    end function;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    function probe_config_to_string(config : t_probe_config) return string is
    begin
        return "ProbeConfig(" &
               real'image(config.probe_trigger_voltage) & "V, " &
               integer'image(config.probe_duration_min) & ", " &
               integer'image(config.probe_duration_max) & ", " &
               real'image(config.probe_intensity_min) & "V, " &
               real'image(config.probe_intensity_max) & "V, " &
               integer'image(config.probe_cooldown_min) & ", " &
               integer'image(config.probe_cooldown_max) & ")";
    end function;
    
    function probe_config_digital_to_string(digital_config : t_probe_config_digital) return string is
    begin
        return "ProbeConfig(" &
               digital_to_string(digital_config.probe_trigger_voltage) & ", " &
               integer'image(digital_config.probe_duration_min) & ", " &
               integer'image(digital_config.probe_duration_max) & ", " &
               digital_to_string(digital_config.probe_intensity_min) & ", " &
               digital_to_string(digital_config.probe_intensity_max) & ", " &
               integer'image(digital_config.probe_cooldown_min) & ", " &
               integer'image(digital_config.probe_cooldown_max) & ")";
    end function;
    
    function probe_configs_equal(config1, config2 : t_probe_config) return boolean is
        constant TOLERANCE : real := 0.001;  -- 1 mV tolerance for voltage comparison (accounts for conversion precision)
    begin
        -- Compare voltage values with tolerance
        if abs(config1.probe_trigger_voltage - config2.probe_trigger_voltage) > TOLERANCE then
            return false;
        end if;
        
        if config1.probe_duration_min /= config2.probe_duration_min then
            return false;
        end if;
        
        if config1.probe_duration_max /= config2.probe_duration_max then
            return false;
        end if;
        
        if config1.probe_cooldown_min /= config2.probe_cooldown_min then
            return false;
        end if;
        
        if config1.probe_cooldown_max /= config2.probe_cooldown_max then
            return false;
        end if;
        
        if abs(config1.probe_intensity_min - config2.probe_intensity_min) > TOLERANCE then
            return false;
        end if;
        
        if abs(config1.probe_intensity_max - config2.probe_intensity_max) > TOLERANCE then
            return false;
        end if;
        
        -- LUT comparison not needed for basic functionality
        
        return true;
    end function;
    
    function probe_configs_digital_equal(digital_config1, digital_config2 : t_probe_config_digital) return boolean is
    begin
        -- Direct digital value comparison
        if digital_config1.probe_trigger_voltage /= digital_config2.probe_trigger_voltage then
            return false;
        end if;
        
        if digital_config1.probe_duration_min /= digital_config2.probe_duration_min then
            return false;
        end if;
        
        if digital_config1.probe_duration_max /= digital_config2.probe_duration_max then
            return false;
        end if;
        
        if digital_config1.probe_cooldown_min /= digital_config2.probe_cooldown_min then
            return false;
        end if;
        
        if digital_config1.probe_cooldown_max /= digital_config2.probe_cooldown_max then
            return false;
        end if;
        
        if digital_config1.probe_intensity_min /= digital_config2.probe_intensity_min then
            return false;
        end if;
        
        if digital_config1.probe_intensity_max /= digital_config2.probe_intensity_max then
            return false;
        end if;
        
        return true;
    end function;
    
end package body Probe_Config_pkg;

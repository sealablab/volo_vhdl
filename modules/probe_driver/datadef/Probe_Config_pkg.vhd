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

package Probe_Config_pkg is
    
    -- =============================================================================
    -- DATA WIDTH CONSTANTS
    -- =============================================================================
    
    -- Constants for data widths

    constant PROBE_THRESHOLD_WIDTH : natural := 16;  -- 16-bit signed for voltage threshold
    constant PROBE_DURATION_WIDTH : natural := 16;   -- 16-bit unsigned for duration
    constant PROBE_INTENSITY_WIDTH : natural := 16;  -- 16-bit signed for voltage intensity
    
    -- =============================================================================
    -- VOLTAGE-BASED CONFIGURATION INTERFACE
    -- =============================================================================
    
    -- Primary probe configuration using voltage values (configuration layer)
    type t_probe_config is record
        probe_in_threshold    : real;  -- Voltage threshold in volts
        probe_in_duration_min : natural;  -- Duration in clock cycles
        probe_in_duration_max : natural;  -- Duration in clock cycles
        intensity_in_min        : real;  -- Minimum intensity voltage in volts
        intensity_in_max        : real;  -- Maximum intensity voltage in volts
    end record;
    
    -- =============================================================================
    -- DIGITAL IMPLEMENTATION INTERFACE
    -- =============================================================================
    
    -- Digital representation for RTL implementation (internal use)
    type t_probe_config_digital is record
        probe_in_threshold    : std_logic_vector(PROBE_THRESHOLD_WIDTH-1 downto 0);
        probe_in_duration_min : natural;  -- Duration in clock cycles
        probe_in_duration_max : natural;  -- Duration in clock cycles
        intensity_in_min        : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);
        intensity_in_max        : std_logic_vector(PROBE_INTENSITY_WIDTH-1 downto 0);
    end record;
    
    -- =============================================================================
    -- VOLTAGE-BASED CONFIGURATION CONSTANTS
    -- =============================================================================
    
    -- DS1120 configuration using voltage values
    constant DS1120_CONFIG_VOLTAGE : t_probe_config := (
        probe_in_threshold    => 2.44488,      
        probe_in_duration_min => 2,
        probe_in_duration_max => 31,
        intensity_in_min        => 0.0,          -- 0x0000 = 0.0V
        intensity_in_max        => 3.3          -- 
    );
    
    -- DS1130 configuration using voltage values
    constant DS1130_CONFIG_VOLTAGE : t_probe_config := (
        probe_in_threshold    => 3.3000,      
        probe_in_duration_min => 6,
        probe_in_duration_max => 31,
        intensity_in_min        => 0.0,          -- 0x0000 = 0.0V
        intensity_in_max        => 3.20          
    );
    
    -- =============================================================================
    -- LEGACY DIGITAL CONSTANTS (maintained for backward compatibility)
    -- =============================================================================
    
    -- DS1120 = ProbeConfig(0x20, 2, 31, 0x00, 0x7F00)
    constant DS1120_CONFIG : t_probe_config_digital := (
        probe_in_threshold    => x"0020",
        probe_in_duration_min => 2,
        probe_in_duration_max => 31,
        intensity_in_min        => x"0000",
        intensity_in_max        => x"7F00"
    );

    -- DS1130 = ProbeConfig(0x30, 2, 31, 0x00, 0x7F00)
    constant DS1130_CONFIG : t_probe_config_digital := (
        probe_in_threshold    => x"0030",
        probe_in_duration_min => 2,
        probe_in_duration_max => 31,
        intensity_in_min        => x"0000",
        intensity_in_max        => x"7F00"
    );
    
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
        -- Convert voltage threshold to digital using Moku voltage package
        digital_config.probe_in_threshold := voltage_to_digital_vector(config.probe_in_threshold);
        
        -- Duration values remain the same (natural type)
        digital_config.probe_in_duration_min := config.probe_in_duration_min;
        digital_config.probe_in_duration_max := config.probe_in_duration_max;
        
        -- Convert intensity voltages to digital using Moku voltage package
        digital_config.intensity_in_min := voltage_to_digital_vector(config.intensity_in_min);
        digital_config.intensity_in_max := voltage_to_digital_vector(config.intensity_in_max);
        
        return digital_config;
    end function;
    
    function digital_to_probe_config(digital_config : t_probe_config_digital) return t_probe_config is
        variable config : t_probe_config;
    begin
        -- Convert digital threshold to voltage using Moku voltage package
        config.probe_in_threshold := digital_to_voltage(digital_config.probe_in_threshold);
        
        -- Duration values remain the same (natural type)
        config.probe_in_duration_min := digital_config.probe_in_duration_min;
        config.probe_in_duration_max := digital_config.probe_in_duration_max;
        
        -- Convert digital intensity values to voltage using Moku voltage package
        config.intensity_in_min := digital_to_voltage(digital_config.intensity_in_min);
        config.intensity_in_max := digital_to_voltage(digital_config.intensity_in_max);
        
        return config;
    end function;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    function is_valid_probe_config(config : t_probe_config) return boolean is
    begin
        -- Check voltage ranges using Moku voltage package
        if not is_valid_moku_voltage(config.probe_in_threshold) then
            return false;
        end if;
        
        if not is_valid_moku_voltage(config.intensity_in_min) then
            return false;
        end if;
        
        if not is_valid_moku_voltage(config.intensity_in_max) then
            return false;
        end if;
        
        -- Check duration constraints
        if config.probe_in_duration_min > config.probe_in_duration_max then
            return false;
        end if;
        
        if config.probe_in_duration_min = 0 or config.probe_in_duration_max = 0 then
            return false;
        end if;
        
        -- Check intensity range
        if config.intensity_in_min > config.intensity_in_max then
            return false;
        end if;
        
        return true;
    end function;
    
    function is_valid_probe_config_digital(digital_config : t_probe_config_digital) return boolean is
    begin
        -- Check digital value ranges using Moku voltage package
        if not is_valid_moku_digital(digital_config.probe_in_threshold) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.intensity_in_min) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.intensity_in_max) then
            return false;
        end if;
        
        -- Check duration constraints
        if digital_config.probe_in_duration_min > digital_config.probe_in_duration_max then
            return false;
        end if;
        
        if digital_config.probe_in_duration_min = 0 or digital_config.probe_in_duration_max = 0 then
            return false;
        end if;
        
        -- Check intensity range (as unsigned comparison)
        if unsigned(digital_config.intensity_in_min) > unsigned(digital_config.intensity_in_max) then
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
               real'image(config.probe_in_threshold) & "V, " &
               integer'image(config.probe_in_duration_min) & ", " &
               integer'image(config.probe_in_duration_max) & ", " &
               real'image(config.intensity_in_min) & "V, " &
               real'image(config.intensity_in_max) & "V)";
    end function;
    
    function probe_config_digital_to_string(digital_config : t_probe_config_digital) return string is
    begin
        return "ProbeConfig(" &
               digital_to_string(digital_config.probe_in_threshold) & ", " &
               integer'image(digital_config.probe_in_duration_min) & ", " &
               integer'image(digital_config.probe_in_duration_max) & ", " &
               digital_to_string(digital_config.intensity_in_min) & ", " &
               digital_to_string(digital_config.intensity_in_max) & ")";
    end function;
    
    function probe_configs_equal(config1, config2 : t_probe_config) return boolean is
        constant TOLERANCE : real := 0.001;  -- 1 mV tolerance for voltage comparison (accounts for conversion precision)
    begin
        -- Compare voltage values with tolerance
        if abs(config1.probe_in_threshold - config2.probe_in_threshold) > TOLERANCE then
            return false;
        end if;
        
        if config1.probe_in_duration_min /= config2.probe_in_duration_min then
            return false;
        end if;
        
        if config1.probe_in_duration_max /= config2.probe_in_duration_max then
            return false;
        end if;
        
        if abs(config1.intensity_in_min - config2.intensity_in_min) > TOLERANCE then
            return false;
        end if;
        
        if abs(config1.intensity_in_max - config2.intensity_in_max) > TOLERANCE then
            return false;
        end if;
        
        return true;
    end function;
    
    function probe_configs_digital_equal(digital_config1, digital_config2 : t_probe_config_digital) return boolean is
    begin
        -- Direct digital value comparison
        if digital_config1.probe_in_threshold /= digital_config2.probe_in_threshold then
            return false;
        end if;
        
        if digital_config1.probe_in_duration_min /= digital_config2.probe_in_duration_min then
            return false;
        end if;
        
        if digital_config1.probe_in_duration_max /= digital_config2.probe_in_duration_max then
            return false;
        end if;
        
        if digital_config1.intensity_in_min /= digital_config2.intensity_in_min then
            return false;
        end if;
        
        if digital_config2.intensity_in_max /= digital_config2.intensity_in_max then
            return false;
        end if;
        
        return true;
    end function;
    
end package body Probe_Config_pkg;

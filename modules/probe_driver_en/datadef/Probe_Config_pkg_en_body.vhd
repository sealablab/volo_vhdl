--------------------------------------------------------------------------------
-- Package Body: Probe_Config_pkg_en (Enhanced with Unit Hinting)
-- Purpose: Implementation of enhanced Probe Configuration package functions
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package body implements all the enhanced functions for the Probe Configuration
-- package, including unit validation, enhanced test data generation, and comprehensive
-- validation capabilities.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
use work.Moku_Voltage_pkg_en.all;
use work.Probe_Config_pkg_en.all;

package body Probe_Config_pkg_en is
    
    -- =============================================================================
    -- CONVERSION FUNCTIONS
    -- =============================================================================
    
    function probe_config_to_digital(config : t_probe_config) return t_probe_config_digital is
        variable digital_config : t_probe_config_digital;
    begin
        -- Convert trigger voltage to digital using enhanced Moku voltage package
        -- Units: Input [package], Output [package]
        digital_config.probe_trigger_voltage := voltage_to_digital_vector(config.probe_trigger_voltage);
        
        -- Duration values remain the same (natural type)
        digital_config.probe_duration_min := config.probe_duration_min;
        digital_config.probe_duration_max := config.probe_duration_max;
        
        -- Cooldown values remain the same (natural type)
        digital_config.probe_cooldown_min := config.probe_cooldown_min;
        digital_config.probe_cooldown_max := config.probe_cooldown_max;
        
        -- Convert intensity voltages to digital using enhanced Moku voltage package
        digital_config.probe_intensity_min := voltage_to_digital_vector(config.probe_intensity_min);
        digital_config.probe_intensity_max := voltage_to_digital_vector(config.probe_intensity_max);
        
        -- LUT field remains the same (percent_lut_record_t type)
        digital_config.probe_intensity_lut := config.probe_intensity_lut;
        
        return digital_config;
    end function;
    
    function digital_to_probe_config(digital_config : t_probe_config_digital) return t_probe_config is
        variable config : t_probe_config;
    begin
        -- Convert digital trigger voltage to voltage using enhanced Moku voltage package
        -- Units: Input [package], Output [package]
        config.probe_trigger_voltage := digital_to_voltage(digital_config.probe_trigger_voltage);
        
        -- Duration values remain the same (natural type)
        config.probe_duration_min := digital_config.probe_duration_min;
        config.probe_duration_max := digital_config.probe_duration_max;
        
        -- Cooldown values remain the same (natural type)
        config.probe_cooldown_min := digital_config.probe_cooldown_min;
        config.probe_cooldown_max := digital_config.probe_cooldown_max;
        
        -- Convert digital intensity values to voltage using enhanced Moku voltage package
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
        -- Check voltage ranges using enhanced Moku voltage package
        -- Units: Input [package], Output [boolean]
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
        -- Check digital value ranges using enhanced Moku voltage package
        -- Units: Input [package], Output [boolean]
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
    
    function is_probe_config_valid_with_units(config : t_probe_config) return boolean is
    begin
        -- Enhanced validation with unit consistency checking
        -- Units: Input [package], Output [boolean]
        
        -- Check basic configuration validity
        if not is_valid_probe_config(config) then
            return false;
        end if;
        
        -- Check unit consistency
        if not validate_units_consistency(config) then
            return false;
        end if;
        
        return true;
    end function;
    
    function is_probe_config_digital_valid_with_units(digital_config : t_probe_config_digital) return boolean is
    begin
        -- Enhanced validation with unit consistency checking for digital configuration
        -- Units: Input [package], Output [boolean]
        
        -- Check basic digital configuration validity
        if not is_valid_probe_config_digital(digital_config) then
            return false;
        end if;
        
        -- Check unit consistency
        if not validate_units_consistency_digital(digital_config) then
            return false;
        end if;
        
        return true;
    end function;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    function probe_config_to_string(config : t_probe_config) return string is
    begin
        -- Units: Input [package], Output [string]
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
        -- Units: Input [package], Output [string]
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
        -- Units: Input [package, package], Output [boolean]
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
        -- Units: Input [package, package], Output [boolean]
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
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    
    function generate_test_probe_config(test_index : natural) return t_probe_config is
        variable test_config : t_probe_config;
    begin
        -- Generate test probe configuration with unit validation
        -- Units: Input [index], Output [package]
        case test_index is
            when 0 =>  -- Valid configuration
                test_config := (
                    probe_trigger_voltage => 2.5,
                    probe_duration_min     => 100,
                    probe_duration_max     => 1000,
                    probe_intensity_min    => 0.5,
                    probe_intensity_max    => 4.5,
                    probe_cooldown_min     => 50,
                    probe_cooldown_max     => 500,
                    probe_intensity_lut    => LINEAR_5V_LUT
                );
            when 1 =>  -- Edge case: minimum values
                test_config := (
                    probe_trigger_voltage => -5.0,
                    probe_duration_min     => 1,
                    probe_duration_max     => 1,
                    probe_intensity_min    => -5.0,
                    probe_intensity_max    => -5.0,
                    probe_cooldown_min     => 1,
                    probe_cooldown_max     => 1,
                    probe_intensity_lut    => LINEAR_5V_LUT
                );
            when 2 =>  -- Edge case: maximum values
                test_config := (
                    probe_trigger_voltage => 5.0,
                    probe_duration_min     => 1000,
                    probe_duration_max     => 10000,
                    probe_intensity_min    => 5.0,
                    probe_intensity_max    => 5.0,
                    probe_cooldown_min     => 1000,
                    probe_cooldown_max     => 10000,
                    probe_intensity_lut    => MOKU_3V3_LUT
                );
            when 3 =>  -- Invalid configuration: min > max
                test_config := (
                    probe_trigger_voltage => 3.3,
                    probe_duration_min     => 1000,
                    probe_duration_max     => 100,  -- Invalid: min > max
                    probe_intensity_min    => 4.0,
                    probe_intensity_max    => 2.0,  -- Invalid: min > max
                    probe_cooldown_min     => 500,
                    probe_cooldown_max     => 50,   -- Invalid: min > max
                    probe_intensity_lut    => LINEAR_5V_LUT
                );
            when others =>  -- Default valid configuration
                test_config := (
                    probe_trigger_voltage => 0.0,
                    probe_duration_min     => 100,
                    probe_duration_max     => 1000,
                    probe_intensity_min    => 0.0,
                    probe_intensity_max    => 5.0,
                    probe_cooldown_min     => 100,
                    probe_cooldown_max     => 1000,
                    probe_intensity_lut    => LINEAR_5V_LUT
                );
        end case;
        
        return test_config;
    end function;
    
    function generate_test_probe_config_digital(test_index : natural) return t_probe_config_digital is
        variable test_config : t_probe_config;
        variable digital_config : t_probe_config_digital;
    begin
        -- Generate test digital probe configuration with unit validation
        -- Units: Input [index], Output [package]
        test_config := generate_test_probe_config(test_index);
        digital_config := probe_config_to_digital(test_config);
        return digital_config;
    end function;
    
    function generate_custom_probe_config(trigger_voltage : real; duration_min : natural; duration_max : natural; intensity_min : real; intensity_max : real; cooldown_min : natural; cooldown_max : natural) return t_probe_config is
        variable custom_config : t_probe_config;
    begin
        -- Generate test probe configuration with specific parameters
        -- Units: Input [volts, clks, clks, volts, volts, clks, clks], Output [package]
        custom_config := (
            probe_trigger_voltage => trigger_voltage,
            probe_duration_min     => duration_min,
            probe_duration_max     => duration_max,
            probe_intensity_min    => intensity_min,
            probe_intensity_max    => intensity_max,
            probe_cooldown_min     => cooldown_min,
            probe_cooldown_max     => cooldown_max,
            probe_intensity_lut    => LINEAR_5V_LUT
        );
        return custom_config;
    end function;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS
    -- =============================================================================
    
    function get_expected_units(field_name : string) return string is
    begin
        -- Get expected units for probe configuration field
        -- Units: Input [signal], Output [string]
        if field_name = "probe_trigger_voltage" then
            return "volts";
        elsif field_name = "probe_intensity_min" then
            return "volts";
        elsif field_name = "probe_intensity_max" then
            return "volts";
        elsif field_name = "probe_duration_min" then
            return "clks";
        elsif field_name = "probe_duration_max" then
            return "clks";
        elsif field_name = "probe_cooldown_min" then
            return "clks";
        elsif field_name = "probe_cooldown_max" then
            return "clks";
        elsif field_name = "probe_intensity_lut" then
            return "package";
        else
            return "unknown";
        end if;
    end function;
    
    function validate_units_consistency(config : t_probe_config) return boolean is
    begin
        -- Validate units consistency for probe configuration
        -- Units: Input [package], Output [boolean]
        
        -- Check voltage ranges are reasonable (within Moku platform range)
        if config.probe_trigger_voltage < -5.0 or config.probe_trigger_voltage > 5.0 then
            return false;
        end if;
        
        if config.probe_intensity_min < -5.0 or config.probe_intensity_min > 5.0 then
            return false;
        end if;
        
        if config.probe_intensity_max < -5.0 or config.probe_intensity_max > 5.0 then
            return false;
        end if;
        
        -- Check intensity min <= max
        if config.probe_intensity_min > config.probe_intensity_max then
            return false;
        end if;
        
        -- Check duration ranges are reasonable (1 to 100000 cycles)
        if config.probe_duration_min < 1 or config.probe_duration_min > 100000 then
            return false;
        end if;
        
        if config.probe_duration_max < 1 or config.probe_duration_max > 100000 then
            return false;
        end if;
        
        -- Check duration min <= max
        if config.probe_duration_min > config.probe_duration_max then
            return false;
        end if;
        
        -- Check cooldown ranges are reasonable (1 to 100000 cycles)
        if config.probe_cooldown_min < 1 or config.probe_cooldown_min > 100000 then
            return false;
        end if;
        
        if config.probe_cooldown_max < 1 or config.probe_cooldown_max > 100000 then
            return false;
        end if;
        
        -- Check cooldown min <= max
        if config.probe_cooldown_min > config.probe_cooldown_max then
            return false;
        end if;
        
        return true;
    end function;
    
    function validate_units_consistency_digital(digital_config : t_probe_config_digital) return boolean is
    begin
        -- Validate units consistency for digital probe configuration
        -- Units: Input [package], Output [boolean]
        
        -- Check digital value ranges are reasonable (within 16-bit signed range)
        if not is_valid_moku_digital(digital_config.probe_trigger_voltage) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.probe_intensity_min) then
            return false;
        end if;
        
        if not is_valid_moku_digital(digital_config.probe_intensity_max) then
            return false;
        end if;
        
        -- Check intensity min <= max (as unsigned comparison)
        if unsigned(digital_config.probe_intensity_min) > unsigned(digital_config.probe_intensity_max) then
            return false;
        end if;
        
        -- Check duration ranges are reasonable (1 to 100000 cycles)
        if digital_config.probe_duration_min < 1 or digital_config.probe_duration_min > 100000 then
            return false;
        end if;
        
        if digital_config.probe_duration_max < 1 or digital_config.probe_duration_max > 100000 then
            return false;
        end if;
        
        -- Check duration min <= max
        if digital_config.probe_duration_min > digital_config.probe_duration_max then
            return false;
        end if;
        
        -- Check cooldown ranges are reasonable (1 to 100000 cycles)
        if digital_config.probe_cooldown_min < 1 or digital_config.probe_cooldown_min > 100000 then
            return false;
        end if;
        
        if digital_config.probe_cooldown_max < 1 or digital_config.probe_cooldown_max > 100000 then
            return false;
        end if;
        
        -- Check cooldown min <= max
        if digital_config.probe_cooldown_min > digital_config.probe_cooldown_max then
            return false;
        end if;
        
        return true;
    end function;

end package body Probe_Config_pkg_en;
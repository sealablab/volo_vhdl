--------------------------------------------------------------------------------
-- Package Body: Global_Probe_Table_pkg_en (Enhanced with Unit Hinting)
-- Purpose: Implementation of enhanced Global Probe Table package functions
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package body implements all the enhanced functions for the Global Probe Table
-- package, including unit validation, enhanced test data generation, and comprehensive
-- validation capabilities.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
use work.Probe_Config_pkg_en.all;
use work.Global_Probe_Table_pkg_en.all;

package body Global_Probe_Table_pkg_en is
    
    -- =============================================================================
    -- ACCESS FUNCTIONS
    -- =============================================================================
    
    function get_probe_config(probe_id : natural) return t_probe_config is
    begin
        -- Direct access to the table (assumes probe_id is valid)
        -- Units: Input [index], Output [package]
        return GLOBAL_PROBE_TABLE(probe_id);
    end function;
    
    function get_probe_config_safe(probe_id : natural) return t_probe_config is
    begin
        -- Bounds checking with default configuration return
        -- Units: Input [index], Output [package]
        if is_valid_probe_id(probe_id) then
            return GLOBAL_PROBE_TABLE(probe_id);
        else
            -- Return the predefined safe default configuration
            return DEFAULT_SAFE_PROBE_CONFIG;
        end if;
    end function;
    
    function get_probe_config_digital(probe_id : natural) return t_probe_config_digital is
    begin
        -- Convert voltage configuration to digital
        -- Units: Input [index], Output [package]
        return probe_config_to_digital(GLOBAL_PROBE_TABLE(probe_id));
    end function;
    
    function get_probe_config_digital_safe(probe_id : natural) return t_probe_config_digital is
    begin
        -- Get safe voltage configuration and convert to digital
        -- Units: Input [index], Output [package]
        return probe_config_to_digital(get_probe_config_safe(probe_id));
    end function;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    function is_valid_probe_id(probe_id : natural) return boolean is
    begin
        -- Units: Input [index], Output [boolean]
        return probe_id < TOTAL_PROBE_TYPES;
    end function;
    
    function is_global_probe_table_valid return boolean is
    begin
        -- Check all probe configurations in the table
        -- Units: Output [boolean]
        for probe_idx in 0 to TOTAL_PROBE_TYPES-1 loop
            if not is_valid_probe_config(GLOBAL_PROBE_TABLE(probe_idx)) then
                return false;
            end if;
        end loop;
        return true;
    end function;
    
    function is_probe_config_valid_with_units(probe_id : natural) return boolean is
        variable config : t_probe_config;
    begin
        -- Enhanced validation with unit consistency checking
        -- Units: Input [index], Output [boolean]
        if not is_valid_probe_id(probe_id) then
            return false;
        end if;
        
        config := GLOBAL_PROBE_TABLE(probe_id);
        
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
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    function get_probe_name(probe_id : natural) return string is
    begin
        -- Units: Input [index], Output [string]
        case probe_id is
            when PROBE_ID_DS1120 => return "DS1120";
            when PROBE_ID_DS1130 => return "DS1130";
            when others => return "UNKNOWN";
        end case;
    end function;
    
    function list_available_probes return string is
        variable result : string(1 to 200);  -- Fixed length string
        variable pos : natural := 1;
        variable probe_name : string(1 to 10);  -- Fixed length for probe names
        variable name_len : natural;
    begin
        -- Units: Output [string]
        result := (others => ' ');  -- Initialize with spaces
        pos := 1;
        
        -- Build list of available probes
        for probe_idx in 0 to TOTAL_PROBE_TYPES-1 loop
            if probe_idx > 0 then
                result(pos to pos+1) := ", ";
                pos := pos + 2;
            end if;
            
            -- Get probe name and add to result
            probe_name := (others => ' ');  -- Clear the fixed-length string
            case probe_idx is
                when PROBE_ID_DS1120 => 
                    probe_name(1 to 6) := "DS1120";
                    name_len := 6;
                when PROBE_ID_DS1130 => 
                    probe_name(1 to 6) := "DS1130";
                    name_len := 6;
                when others => 
                    probe_name(1 to 7) := "UNKNOWN";
                    name_len := 7;
            end case;
            
            -- Add the probe name to the result
            result(pos to pos + name_len - 1) := probe_name(1 to name_len);
            pos := pos + name_len;
        end loop;
        
        return result;
    end function;
    
    function get_probe_config_string(probe_id : natural) return string is
    begin
        -- Units: Input [index], Output [string]
        if is_valid_probe_id(probe_id) then
            return get_probe_name(probe_id) & ": " & probe_config_to_string(GLOBAL_PROBE_TABLE(probe_id));
        else
            return "INVALID_PROBE_ID: " & integer'image(probe_id);
        end if;
    end function;
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    

    
    function generate_test_probe_config_array return t_probe_config_array is
        variable test_array : t_probe_config_array;
    begin
        -- Generate test probe configuration array for all probe types
        -- Units: Output [package]
        for probe_idx in 0 to TOTAL_PROBE_TYPES-1 loop
            test_array(probe_idx) := generate_test_probe_config(probe_idx);
        end loop;
        
        return test_array;
    end function;
    
    function generate_test_probe_id(test_index : natural) return natural is
    begin
        -- Generate test probe ID with bounds checking
        -- Units: Input [index], Output [index]
        case test_index is
            when 0 => return PROBE_ID_DS1120;  -- Valid probe ID
            when 1 => return PROBE_ID_DS1130;  -- Valid probe ID
            when 2 => return TOTAL_PROBE_TYPES;  -- Invalid probe ID (out of bounds)
            when 3 => return 99;  -- Invalid probe ID (far out of bounds)
            when others => return test_index mod TOTAL_PROBE_TYPES;  -- Cycle through valid IDs
        end case;
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
    


end package body Global_Probe_Table_pkg_en;
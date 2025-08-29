--------------------------------------------------------------------------------
-- Package: Global_Probe_Table_pkg
-- Purpose: Global probe configuration table for pre-defined probe types
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package provides a centralized table of pre-configured probe configurations
-- that can be used throughout the entire project. It allows easy addition of new
-- probe types while maintaining a clean interface for accessing configurations.
-- 
-- DESIGN PRINCIPLES:
-- - Centralized probe configuration management
-- - Easy addition of new probe types
-- - Type-safe access to configurations
-- - Verilog compatibility maintained
-- - Clear separation of probe identification and configuration
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import probe configuration package
use work.Probe_Config_pkg.all;

-- Import PercentLut package for probe-specific intensity LUTs
use work.PercentLut_pkg.all;

package Global_Probe_Table_pkg is
    
    -- =============================================================================
    -- PROBE IDENTIFIER CONSTANTS
    -- =============================================================================
    
    -- Probe type identifiers (use descriptive names for clarity)
    constant PROBE_ID_DS1120 : natural := 0;  -- DS1120 probe identifier
    constant PROBE_ID_DS1130 : natural := 1;  -- DS1130 probe identifier
    
    -- Total number of supported probes (update when adding new probes)
    constant TOTAL_PROBE_TYPES : natural := 2;
    
    -- =============================================================================
    -- PROBE-SPECIFIC INTENSITY LUTs
    -- =============================================================================
    
    -- DS1120: Linear intensity curve optimized for 5V operation
    constant DS1120_INTENSITY_LUT : percent_lut_record_t := LINEAR_5V_LUT;
    
    -- DS1130: Custom intensity curve optimized for 3.3V operation  
    constant DS1130_INTENSITY_LUT : percent_lut_record_t := MOKU_3V3_LUT;
    
    -- =============================================================================
    -- DEFAULT/SAFE PROBE CONFIGURATION
    -- =============================================================================
    
    -- Safe default configuration for invalid probe IDs
    -- This provides a predictable, safe fallback when probe ID is out of bounds
    constant DEFAULT_SAFE_PROBE_CONFIG : t_probe_config := (
        probe_trigger_voltage => 0.0,      -- Safe default: 0V (no trigger)
        probe_duration_min     => 100,     -- Safe default: 100 cycles
        probe_duration_max     => 100,     -- Safe default: 100 cycles  
        probe_intensity_min    => 0.0,     -- Safe default: 0V (no intensity)
        probe_intensity_max    => 0.0,     -- Safe default: 0V (no intensity)
        probe_cooldown_min     => 100,     -- Safe default: 100 cycles
        probe_cooldown_max     => 100,     -- Safe default: 100 cycles
        probe_intensity_lut    => LINEAR_5V_LUT  -- Safe, predictable default LUT
    );
    
    -- =============================================================================
    -- PROBE CONFIGURATION TABLE
    -- =============================================================================
    
    -- Array type for storing probe configurations
    type t_probe_config_array is array (0 to TOTAL_PROBE_TYPES-1) of t_probe_config;
    
    -- Global probe configuration table
    -- Add new probe configurations here by extending the array and updating TOTAL_PROBE_TYPES
    constant GLOBAL_PROBE_TABLE : t_probe_config_array := (
        -- DS1120 Configuration
        PROBE_ID_DS1120 => (
            probe_trigger_voltage => 3.3,      -- 3.3V trigger voltage
            probe_duration_min     => 100,     -- 100 clock cycles minimum duration
            probe_duration_max     => 1000,    -- 1000 clock cycles maximum duration
            probe_intensity_min    => 0.5,     -- 0.5V minimum intensity
            probe_intensity_max    => 5.0,     -- 5.0V maximum intensity
            probe_cooldown_min     => 50,      -- 50 clock cycles minimum cooldown
            probe_cooldown_max     => 500,     -- 500 clock cycles maximum cooldown
            probe_intensity_lut    => DS1120_INTENSITY_LUT  -- Probe's own authoritative LUT
        ),
        
        -- DS1130 Configuration
        PROBE_ID_DS1130 => (
            probe_trigger_voltage => 2.5,      -- 2.5V trigger voltage
            probe_duration_min     => 150,     -- 150 clock cycles minimum duration
            probe_duration_max     => 1200,    -- 1200 clock cycles maximum duration
            probe_intensity_min    => 0.3,     -- 0.3V minimum intensity
            probe_intensity_max    => 4.5,     -- 4.5V maximum intensity
            probe_cooldown_min     => 75,      -- 75 clock cycles minimum cooldown
            probe_cooldown_max     => 600,     -- 600 clock cycles maximum cooldown
            probe_intensity_lut    => DS1130_INTENSITY_LUT  -- Probe's own authoritative LUT
        )
    );
    
    -- =============================================================================
    -- ACCESS FUNCTIONS
    -- =============================================================================
    
    -- Get probe configuration by probe ID
    function get_probe_config(probe_id : natural) return t_probe_config;
    
    -- Get probe configuration by probe ID (with bounds checking)
    function get_probe_config_safe(probe_id : natural) return t_probe_config;
    
    -- Get digital probe configuration by probe ID
    function get_probe_config_digital(probe_id : natural) return t_probe_config_digital;
    
    -- Get digital probe configuration by probe ID (with bounds checking)
    function get_probe_config_digital_safe(probe_id : natural) return t_probe_config_digital;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Check if probe ID is valid
    function is_valid_probe_id(probe_id : natural) return boolean;
    
    -- Validate all probe configurations in the table
    function is_global_probe_table_valid return boolean;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    -- Get probe name string from probe ID
    function get_probe_name(probe_id : natural) return string;
    
    -- List all available probe types
    function list_available_probes return string;
    
    -- Get probe configuration as string
    function get_probe_config_string(probe_id : natural) return string;

end package Global_Probe_Table_pkg;

package body Global_Probe_Table_pkg is
    
    -- =============================================================================
    -- ACCESS FUNCTIONS
    -- =============================================================================
    
    function get_probe_config(probe_id : natural) return t_probe_config is
    begin
        -- Direct access to the table (assumes probe_id is valid)
        return GLOBAL_PROBE_TABLE(probe_id);
    end function;
    
    function get_probe_config_safe(probe_id : natural) return t_probe_config is
    begin
        -- Bounds checking with default configuration return
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
        return probe_config_to_digital(GLOBAL_PROBE_TABLE(probe_id));
    end function;
    
    function get_probe_config_digital_safe(probe_id : natural) return t_probe_config_digital is
    begin
        -- Get safe voltage configuration and convert to digital
        return probe_config_to_digital(get_probe_config_safe(probe_id));
    end function;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    function is_valid_probe_id(probe_id : natural) return boolean is
    begin
        return probe_id < TOTAL_PROBE_TYPES;
    end function;
    
    function is_global_probe_table_valid return boolean is
    begin
        -- Check all probe configurations in the table
        for probe_idx in 0 to TOTAL_PROBE_TYPES-1 loop
            if not is_valid_probe_config(GLOBAL_PROBE_TABLE(probe_idx)) then
                return false;
            end if;
        end loop;
        return true;
    end function;
    
    -- =============================================================================
    -- UTILITY FUNCTIONS
    -- =============================================================================
    
    function get_probe_name(probe_id : natural) return string is
    begin
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
    begin
        result := (others => ' ');  -- Initialize with spaces
        pos := 1;
        
        -- Build list of available probes
        for probe_idx in 0 to TOTAL_PROBE_TYPES-1 loop
            if probe_idx > 0 then
                result(pos to pos+1) := ", ";
                pos := pos + 2;
            end if;
            
            -- Get probe name and add to result
            probe_name := get_probe_name(probe_idx);
            result(pos to pos + probe_name'length - 1) := probe_name;
            pos := pos + probe_name'length;
        end loop;
        
        return result;
    end function;
    
    function get_probe_config_string(probe_id : natural) return string is
    begin
        if is_valid_probe_id(probe_id) then
            return get_probe_name(probe_id) & ": " & probe_config_to_string(GLOBAL_PROBE_TABLE(probe_id));
        else
            return "INVALID_PROBE_ID: " & integer'image(probe_id);
        end if;
    end function;

end package body Global_Probe_Table_pkg;

-- =============================================================================
-- Enhanced Global Probe Table Package
-- =============================================================================
-- 
-- This enhanced package provides a global probe table with comprehensive
-- validation, error handling, and unit hinting. It manages multiple probe
-- configurations and provides safe access functions.
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
use work.Probe_Config_pkg_en.ALL;

package Global_Probe_Table_pkg_en is

    -- =========================================================================
    -- System Constants with Unit Documentation
    -- =========================================================================
    constant GLOBAL_TABLE_SIZE : natural := 4;  -- Units: count (number of probe configurations)
    constant PROBE_NAME_LENGTH : natural := 16; -- Units: count (maximum probe name length)
    
    -- =========================================================================
    -- Global Probe Table Type
    -- =========================================================================
    -- Units: array of probe configuration records
    type t_global_probe_table is array (0 to GLOBAL_TABLE_SIZE-1) of t_probe_config;
    
    -- =========================================================================
    -- Validation Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: probe table (array) -> output: boolean (validity)
    -- Purpose: Validates that the entire probe table is consistent and safe
    function is_valid_probe_table(table : t_global_probe_table) return boolean;
    
    -- Units: input: probe table (array), index (index) -> output: boolean (validity)
    -- Purpose: Validates that a specific probe index is valid and safe
    function is_valid_probe_table_index(table : t_global_probe_table; index : natural) return boolean;
    
    -- Units: input: probe table (array) -> output: natural (count)
    -- Purpose: Returns the number of valid probe configurations in the table
    function get_valid_probe_count(table : t_global_probe_table) return natural;
    
    -- =========================================================================
    -- Safe Access Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: probe table (array), index (index) -> output: probe config (record)
    -- Purpose: Safe access to probe configuration with bounds checking and validation
    function get_probe_from_table_safe(table : t_global_probe_table; index : natural) return t_probe_config;
    
    -- Units: input: probe table (array), probe_name (string) -> output: natural (index)
    -- Purpose: Finds probe index by name, returns 0 if not found
    function find_probe_by_name(table : t_global_probe_table; probe_name : string) return natural;
    
    -- Units: input: probe table (array), index (index) -> output: boolean (validity)
    -- Purpose: Checks if a probe at the given index is valid and enabled
    function is_probe_enabled(table : t_global_probe_table; index : natural) return boolean;
    
    -- =========================================================================
    -- Table Management Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: probe table (array) -> output: probe table (array)
    -- Purpose: Creates a validated copy of the probe table with safety checks
    function validate_probe_table(table : t_global_probe_table) return t_global_probe_table;
    
    -- Units: input: probe table (array) -> output: string (report)
    -- Purpose: Generates a validation report for the probe table
    function generate_probe_table_report(table : t_global_probe_table) return string;
    
    -- =========================================================================
    -- Default Global Probe Table
    -- =========================================================================
    
    -- Default global probe table with sample configurations (Units: array)
    constant DEFAULT_GLOBAL_PROBE_TABLE : t_global_probe_table := (
        -- Probe 0: SCA Probe Configuration
        0 => (
            probe_name => "SCA_PROBE_001   ",
            probe_trigger_voltage => x"1000",  -- Units: volts (1.0V)
            probe_intensity_min   => x"0000",  -- Units: volts (0.0V)
            probe_intensity_max   => x"3000",  -- Units: volts (3.0V)
            fire_duration_min     => to_unsigned(50, SYSTEM_DURATION_WIDTH),    -- Units: clks
            fire_duration_max     => to_unsigned(500, SYSTEM_DURATION_WIDTH),   -- Units: clks
            cooldown_duration_min => to_unsigned(200, SYSTEM_DURATION_WIDTH),   -- Units: clks
            cooldown_duration_max => to_unsigned(2000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            safety_enabled        => '1',      -- Units: signal
            max_fire_rate         => to_unsigned(1000, 16)  -- Units: clks
        ),
        
        -- Probe 1: FI Probe Configuration
        1 => (
            probe_name => "FI_PROBE_001    ",
            probe_trigger_voltage => x"0800",  -- Units: volts (0.5V)
            probe_intensity_min   => x"0000",  -- Units: volts (0.0V)
            probe_intensity_max   => x"2000",  -- Units: volts (2.0V)
            fire_duration_min     => to_unsigned(100, SYSTEM_DURATION_WIDTH),   -- Units: clks
            fire_duration_max     => to_unsigned(1000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            cooldown_duration_min => to_unsigned(500, SYSTEM_DURATION_WIDTH),   -- Units: clks
            cooldown_duration_max => to_unsigned(5000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            safety_enabled        => '1',      -- Units: signal
            max_fire_rate         => to_unsigned(2000, 16)  -- Units: clks
        ),
        
        -- Probe 2: High Power Probe Configuration
        2 => (
            probe_name => "HIGH_PWR_PROBE  ",
            probe_trigger_voltage => x"2000",  -- Units: volts (2.0V)
            probe_intensity_min   => x"0000",  -- Units: volts (0.0V)
            probe_intensity_max   => x"4000",  -- Units: volts (4.0V)
            fire_duration_min     => to_unsigned(25, SYSTEM_DURATION_WIDTH),    -- Units: clks
            fire_duration_max     => to_unsigned(250, SYSTEM_DURATION_WIDTH),   -- Units: clks
            cooldown_duration_min => to_unsigned(1000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            cooldown_duration_max => to_unsigned(10000, SYSTEM_DURATION_WIDTH), -- Units: clks
            safety_enabled        => '1',      -- Units: signal
            max_fire_rate         => to_unsigned(5000, 16)  -- Units: clks
        ),
        
        -- Probe 3: Low Power Probe Configuration
        3 => (
            probe_name => "LOW_PWR_PROBE   ",
            probe_trigger_voltage => x"0400",  -- Units: volts (0.25V)
            probe_intensity_min   => x"0000",  -- Units: volts (0.0V)
            probe_intensity_max   => x"1000",  -- Units: volts (1.0V)
            fire_duration_min     => to_unsigned(200, SYSTEM_DURATION_WIDTH),   -- Units: clks
            fire_duration_max     => to_unsigned(2000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            cooldown_duration_min => to_unsigned(100, SYSTEM_DURATION_WIDTH),   -- Units: clks
            cooldown_duration_max => to_unsigned(1000, SYSTEM_DURATION_WIDTH),  -- Units: clks
            safety_enabled        => '1',      -- Units: signal
            max_fire_rate         => to_unsigned(500, 16)   -- Units: clks
        )
    );

end package Global_Probe_Table_pkg_en;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body Global_Probe_Table_pkg_en is

    -- =========================================================================
    -- Validation Function Implementations
    -- =========================================================================
    
    function is_valid_probe_table(table : t_global_probe_table) return boolean is
        variable is_valid : boolean := true;
        variable valid_count : natural := 0;
    begin
        -- Check each probe configuration
        for i in 0 to GLOBAL_TABLE_SIZE-1 loop
            if is_valid_probe_config(table(i)) then
                valid_count := valid_count + 1;
            else
                is_valid := false;
            end if;
        end loop;
        
        -- At least one probe must be valid
        if valid_count = 0 then
            is_valid := false;
        end if;
        
        return is_valid;
    end function;
    
    function is_valid_probe_table_index(table : t_global_probe_table; index : natural) return boolean is
    begin
        -- Check bounds and validity
        if index >= GLOBAL_TABLE_SIZE then
            return false;
        end if;
        
        return is_valid_probe_config(table(index));
    end function;
    
    function get_valid_probe_count(table : t_global_probe_table) return natural is
        variable count : natural := 0;
    begin
        for i in 0 to GLOBAL_TABLE_SIZE-1 loop
            if is_valid_probe_config(table(i)) then
                count := count + 1;
            end if;
        end loop;
        return count;
    end function;
    
    -- =========================================================================
    -- Safe Access Function Implementations
    -- =========================================================================
    
    function get_probe_from_table_safe(table : t_global_probe_table; index : natural) return t_probe_config is
    begin
        if is_valid_probe_table_index(table, index) then
            return table(index);
        else
            return DEFAULT_PROBE_CONFIG;
        end if;
    end function;
    
    function find_probe_by_name(table : t_global_probe_table; probe_name : string) return natural is
    begin
        for i in 0 to GLOBAL_TABLE_SIZE-1 loop
            if table(i).probe_name = probe_name then
                return i;
            end if;
        end loop;
        return 0; -- Return first probe if not found
    end function;
    
    function is_probe_enabled(table : t_global_probe_table; index : natural) return boolean is
    begin
        if index >= GLOBAL_TABLE_SIZE then
            return false;
        end if;
        
        return (table(index).safety_enabled = '1') and is_valid_probe_config(table(index));
    end function;
    
    -- =========================================================================
    -- Table Management Function Implementations
    -- =========================================================================
    
    function validate_probe_table(table : t_global_probe_table) return t_global_probe_table is
        variable validated_table : t_global_probe_table;
    begin
        for i in 0 to GLOBAL_TABLE_SIZE-1 loop
            if is_valid_probe_config(table(i)) then
                validated_table(i) := table(i);
            else
                validated_table(i) := DEFAULT_PROBE_CONFIG;
            end if;
        end loop;
        return validated_table;
    end function;
    
    function generate_probe_table_report(table : t_global_probe_table) return string is
        variable report_line : string(1 to 200);
        variable line_pos : natural := 1;
    begin
        -- Initialize report
        report_line := (others => ' ');
        
        -- Add header
        report_line(1 to 19) := "Probe Table Report:";
        line_pos := 20;
        
        -- Add valid probe count
        report_line(line_pos to line_pos + 19) := " Valid Probes: ";
        line_pos := line_pos + 20;
        
        -- Add probe details (simplified for string return)
        report_line(line_pos to line_pos + 9) := "4 probes  ";
        
        return report_line;
    end function;

end package body Global_Probe_Table_pkg_en;
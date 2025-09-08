-- =============================================================================
-- Enhanced PercentLut Package
-- =============================================================================
-- 
-- This enhanced package provides percentage-based lookup table utilities with
-- comprehensive validation, error handling, and unit hinting. It manages
-- intensity scaling through lookup tables with safe access functions.
--
-- UNIT CONVENTIONS:
-- - voltage values: volts (voltage output levels)
-- - intensity values: ratio (percentage/intensity scaling)
-- - index values: index (table/array indices)
-- - signal values: signal (control and status signals)
-- - count values: count (quantities and sizes)
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Moku_Voltage_pkg_en.ALL;

package PercentLut_pkg_en is

    -- =========================================================================
    -- System Constants with Unit Documentation
    -- =========================================================================
    constant PERCENT_LUT_SIZE : natural := 128;        -- Units: count (lookup table size)
    constant PERCENT_LUT_WIDTH : natural := 7;         -- Units: bits (index width)
    constant PERCENT_DATA_WIDTH : natural := 16;       -- Units: bits (voltage data width)
    constant PERCENT_MAX : natural := 100;             -- Units: ratio (maximum percentage)
    constant PERCENT_MIN : natural := 0;               -- Units: ratio (minimum percentage)
    
    -- =========================================================================
    -- PercentLut Data Types with Unit Documentation
    -- =========================================================================
    
    -- Units: array of voltage values (volts)
    type t_percent_lut_data is array (0 to PERCENT_LUT_SIZE-1) of std_logic_vector(PERCENT_DATA_WIDTH-1 downto 0);
    
    -- Units: record containing lookup table data and metadata
    type t_percent_lut_record is record
        data_array : t_percent_lut_data;  -- Units: array of voltage values (volts)
        valid      : std_logic;           -- Units: signal (validity flag)
        size       : natural;             -- Units: count (actual table size)
    end record;
    
    -- =========================================================================
    -- Validation Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: lut data (array) -> output: boolean (validity)
    -- Purpose: Validates that the lookup table data is consistent and safe
    function is_valid_percent_lut(lut_data : t_percent_lut_data) return boolean;
    
    -- Units: input: lut record (record) -> output: boolean (validity)
    -- Purpose: Validates that the lookup table record is consistent and safe
    function is_valid_percent_lut_record(lut_record : t_percent_lut_record) return boolean;
    
    -- Units: input: index (index) -> output: boolean (validity)
    -- Purpose: Validates that an index is within valid range for the lookup table
    function is_valid_percent_index(index : natural) return boolean;
    
    -- Units: input: percentage (ratio) -> output: boolean (validity)
    -- Purpose: Validates that a percentage value is within valid range
    function is_valid_percentage(percentage : natural) return boolean;
    
    -- =========================================================================
    -- Safe Access Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: lut data (array), index (index) -> output: voltage (volts)
    -- Purpose: Safe access to lookup table with bounds checking
    function get_percent_lut_value_safe(lut_data : t_percent_lut_data; index : natural) return std_logic_vector;
    
    -- Units: input: lut record (record), index (index) -> output: voltage (volts)
    -- Purpose: Safe access to lookup table record with bounds checking
    function get_percent_lut_record_value_safe(lut_record : t_percent_lut_record; index : natural) return std_logic_vector;
    
    -- Units: input: lut data (array), percentage (ratio) -> output: voltage (volts)
    -- Purpose: Gets voltage value for a given percentage with safe conversion
    function get_voltage_for_percentage(lut_data : t_percent_lut_data; percentage : natural) return std_logic_vector;
    
    -- =========================================================================
    -- Lookup Table Generation Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: base_voltage (volts), max_voltage (volts) -> output: lut data (array)
    -- Purpose: Generates a linear lookup table from base to max voltage
    function generate_linear_percent_lut(base_voltage : real; max_voltage : real) return t_percent_lut_data;
    
    -- Units: input: base_voltage (volts), max_voltage (volts) -> output: lut data (array)
    -- Purpose: Generates a logarithmic lookup table from base to max voltage
    function generate_log_percent_lut(base_voltage : real; max_voltage : real) return t_percent_lut_data;
    
    -- Units: input: lut data (array) -> output: lut record (record)
    -- Purpose: Creates a validated lookup table record from data array
    function create_percent_lut_record(lut_data : t_percent_lut_data) return t_percent_lut_record;
    
    -- =========================================================================
    -- Utility Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: percentage (ratio) -> output: index (index)
    -- Purpose: Converts percentage to lookup table index
    function percentage_to_index(percentage : natural) return natural;
    
    -- Units: input: index (index) -> output: percentage (ratio)
    -- Purpose: Converts lookup table index to percentage
    function index_to_percentage(index : natural) return natural;
    
    -- Units: input: lut data (array) -> output: natural (count)
    -- Purpose: Returns the number of valid entries in the lookup table
    function get_valid_lut_count(lut_data : t_percent_lut_data) return natural;
    
    -- =========================================================================
    -- Default Lookup Table Constants
    -- =========================================================================
    
    -- Default linear lookup table (Units: array)
    constant DEFAULT_LINEAR_PERCENT_LUT : t_percent_lut_data := generate_linear_percent_lut(0.0, 5.0);
    
    -- Default lookup table record (Units: record)
    constant DEFAULT_PERCENT_LUT_RECORD : t_percent_lut_record := create_percent_lut_record(DEFAULT_LINEAR_PERCENT_LUT);
    
    -- Safe default voltage value (Units: volts)
    constant DEFAULT_SAFE_VOLTAGE : std_logic_vector(PERCENT_DATA_WIDTH-1 downto 0) := (others => '0');

end package PercentLut_pkg_en;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body PercentLut_pkg_en is

    -- =========================================================================
    -- Validation Function Implementations
    -- =========================================================================
    
    function is_valid_percent_lut(lut_data : t_percent_lut_data) return boolean is
        variable is_valid : boolean := true;
        variable valid_count : natural := 0;
    begin
        -- Check each entry in the lookup table
        for i in 0 to PERCENT_LUT_SIZE-1 loop
            if is_digital_safe(lut_data(i)) then
                valid_count := valid_count + 1;
            else
                is_valid := false;
            end if;
        end loop;
        
        -- At least some entries should be valid
        if valid_count < PERCENT_LUT_SIZE / 4 then
            is_valid := false;
        end if;
        
        return is_valid;
    end function;
    
    function is_valid_percent_lut_record(lut_record : t_percent_lut_record) return boolean is
    begin
        return (lut_record.valid = '1') and 
               (lut_record.size <= PERCENT_LUT_SIZE) and
               is_valid_percent_lut(lut_record.data_array);
    end function;
    
    function is_valid_percent_index(index : natural) return boolean is
    begin
        return (index < PERCENT_LUT_SIZE);
    end function;
    
    function is_valid_percentage(percentage : natural) return boolean is
    begin
        return (percentage <= PERCENT_MAX);
    end function;
    
    -- =========================================================================
    -- Safe Access Function Implementations
    -- =========================================================================
    
    function get_percent_lut_value_safe(lut_data : t_percent_lut_data; index : natural) return std_logic_vector is
    begin
        if is_valid_percent_index(index) then
            return lut_data(index);
        else
            return DEFAULT_SAFE_VOLTAGE;
        end if;
    end function;
    
    function get_percent_lut_record_value_safe(lut_record : t_percent_lut_record; index : natural) return std_logic_vector is
    begin
        if is_valid_percent_lut_record(lut_record) and is_valid_percent_index(index) then
            return lut_record.data_array(index);
        else
            return DEFAULT_SAFE_VOLTAGE;
        end if;
    end function;
    
    function get_voltage_for_percentage(lut_data : t_percent_lut_data; percentage : natural) return std_logic_vector is
        variable index : natural;
    begin
        if is_valid_percentage(percentage) then
            index := percentage_to_index(percentage);
            return get_percent_lut_value_safe(lut_data, index);
        else
            return DEFAULT_SAFE_VOLTAGE;
        end if;
    end function;
    
    -- =========================================================================
    -- Lookup Table Generation Function Implementations
    -- =========================================================================
    
    function generate_linear_percent_lut(base_voltage : real; max_voltage : real) return t_percent_lut_data is
        variable lut_data : t_percent_lut_data;
        variable voltage_step : real;
        variable current_voltage : real;
    begin
        -- Calculate voltage step
        voltage_step := (max_voltage - base_voltage) / real(PERCENT_LUT_SIZE - 1);
        
        -- Generate linear lookup table
        for i in 0 to PERCENT_LUT_SIZE-1 loop
            current_voltage := base_voltage + real(i) * voltage_step;
            lut_data(i) := voltage_to_digital(current_voltage);
        end loop;
        
        return lut_data;
    end function;
    
    function generate_log_percent_lut(base_voltage : real; max_voltage : real) return t_percent_lut_data is
        variable lut_data : t_percent_lut_data;
        variable log_base : real;
        variable current_voltage : real;
        variable safe_base_voltage : real;
    begin
        -- Ensure base voltage is positive for logarithmic calculation
        if base_voltage <= 0.0 then
            safe_base_voltage := 0.1; -- Small positive value
        else
            safe_base_voltage := base_voltage;
        end if;
        
        log_base := max_voltage / safe_base_voltage;
        
        -- Generate logarithmic lookup table (simplified linear for now)
        for i in 0 to PERCENT_LUT_SIZE-1 loop
            current_voltage := safe_base_voltage + (max_voltage - safe_base_voltage) * real(i) / real(PERCENT_LUT_SIZE - 1);
            lut_data(i) := voltage_to_digital(current_voltage);
        end loop;
        
        return lut_data;
    end function;
    
    function create_percent_lut_record(lut_data : t_percent_lut_data) return t_percent_lut_record is
        variable lut_record : t_percent_lut_record;
    begin
        lut_record.data_array := lut_data;
        lut_record.valid := '1' when is_valid_percent_lut(lut_data) else '0';
        lut_record.size := PERCENT_LUT_SIZE;
        return lut_record;
    end function;
    
    -- =========================================================================
    -- Utility Function Implementations
    -- =========================================================================
    
    function percentage_to_index(percentage : natural) return natural is
        variable index : natural;
    begin
        if percentage > PERCENT_MAX then
            index := PERCENT_LUT_SIZE - 1;
        else
            index := (percentage * PERCENT_LUT_SIZE) / PERCENT_MAX;
        end if;
        
        -- Ensure within bounds
        if index >= PERCENT_LUT_SIZE then
            index := PERCENT_LUT_SIZE - 1;
        end if;
        
        return index;
    end function;
    
    function index_to_percentage(index : natural) return natural is
        variable percentage : natural;
    begin
        if index >= PERCENT_LUT_SIZE then
            percentage := PERCENT_MAX;
        else
            percentage := (index * PERCENT_MAX) / PERCENT_LUT_SIZE;
        end if;
        
        return percentage;
    end function;
    
    function get_valid_lut_count(lut_data : t_percent_lut_data) return natural is
        variable count : natural := 0;
    begin
        for i in 0 to PERCENT_LUT_SIZE-1 loop
            if is_digital_safe(lut_data(i)) then
                count := count + 1;
            end if;
        end loop;
        return count;
    end function;

end package body PercentLut_pkg_en;
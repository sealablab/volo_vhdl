--------------------------------------------------------------------------------
-- Package Body: PercentLut_pkg_en (Enhanced with Unit Hinting)
-- Purpose: Implementation of enhanced PercentLut package functions
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This package body implements all the enhanced functions for the PercentLut
-- package, including unit validation, enhanced test data generation, and comprehensive
-- validation capabilities.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
use work.Moku_Voltage_pkg_en.all;
use work.PercentLut_pkg_en.all;

package body PercentLut_pkg_en is
    
    -- =============================================================================
    -- CRC VALIDATION FUNCTIONS
    -- =============================================================================
    
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) return std_logic_vector is
        variable crc : std_logic_vector(15 downto 0) := SYSTEM_CRC16_INIT_VALUE;
        variable data_byte : std_logic_vector(7 downto 0);
        variable polynomial : std_logic_vector(15 downto 0) := SYSTEM_CRC16_POLYNOMIAL;
    begin
        -- Units: Input [package], Output [crc]
        -- Calculate CRC-16 for the entire LUT data array
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            -- Process each 16-bit data value as two bytes
            for byte_idx in 0 to 1 loop
                if byte_idx = 0 then
                    data_byte := lut_data(i)(15 downto 8);
                else
                    data_byte := lut_data(i)(7 downto 0);
                end if;
                
                -- CRC calculation for one byte
                for bit_idx in 7 downto 0 loop
                    if (crc(15) xor data_byte(bit_idx)) = '1' then
                        crc := (crc(14 downto 0) & '0') xor polynomial;
                    else
                        crc := crc(14 downto 0) & '0';
                    end if;
                end loop;
            end loop;
        end loop;
        
        return crc;
    end function;
    
    function validate_percent_lut(lut_data : percent_lut_data_array_t; lut_crc : std_logic_vector) return boolean is
        variable calculated_crc : std_logic_vector(15 downto 0);
    begin
        -- Units: Input [package, crc], Output [boolean]
        calculated_crc := calculate_percent_lut_crc(lut_data);
        return (calculated_crc = lut_crc);
    end function;
    
    -- =============================================================================
    -- RECORD VALIDATION FUNCTIONS
    -- =============================================================================
    
    function validate_percent_lut_record(lut_rec : percent_lut_record_t) return boolean is
    begin
        -- Units: Input [package], Output [boolean]
        -- Check if the record is valid
        if lut_rec.valid /= '1' then
            return false;
        end if;
        
        -- Check if size is within valid range
        if unsigned(lut_rec.size) > SYSTEM_PERCENT_LUT_SIZE-1 then
            return false;
        end if;
        
        -- Validate CRC
        if not validate_percent_lut(lut_rec.data_array, lut_rec.crc) then
            return false;
        end if;
        
        return true;
    end function;
    
    function is_percent_lut_record_valid(lut_rec : percent_lut_record_t) return boolean is
    begin
        -- Units: Input [package], Output [boolean]
        return validate_percent_lut_record(lut_rec);
    end function;
    
    -- =============================================================================
    -- INDEX VALIDATION FUNCTIONS
    -- =============================================================================
    
    function is_valid_percent_lut_index(index : std_logic_vector) return boolean is
    begin
        -- Units: Input [index], Output [boolean]
        if index'length < SYSTEM_PERCENT_LUT_INDEX_WIDTH then
            return false;
        end if;
        
        return (unsigned(index) <= SYSTEM_PERCENT_LUT_SIZE-1);
    end function;
    
    function is_valid_percent_lut_index(index : natural) return boolean is
    begin
        -- Units: Input [index], Output [boolean]
        return (index <= SYSTEM_PERCENT_LUT_SIZE-1);
    end function;
    
    -- =============================================================================
    -- RECORD CREATION FUNCTIONS
    -- =============================================================================
    
    function create_percent_lut_record(lut_data : percent_lut_data_array_t) return percent_lut_record_t is
        variable lut_rec : percent_lut_record_t;
    begin
        -- Units: Input [package], Output [package]
        lut_rec.data_array := lut_data;
        lut_rec.crc := (others => '0');  -- No CRC calculation
        lut_rec.valid := '1';
        lut_rec.size := std_logic_vector(to_unsigned(SYSTEM_PERCENT_LUT_SIZE-1, SYSTEM_PERCENT_LUT_INDEX_WIDTH));
        return lut_rec;
    end function;
    
    function create_percent_lut_record_with_crc(lut_data : percent_lut_data_array_t) return percent_lut_record_t is
        variable lut_rec : percent_lut_record_t;
    begin
        -- Units: Input [package], Output [package]
        lut_rec.data_array := lut_data;
        lut_rec.crc := calculate_percent_lut_crc(lut_data);
        lut_rec.valid := '1';
        lut_rec.size := std_logic_vector(to_unsigned(SYSTEM_PERCENT_LUT_SIZE-1, SYSTEM_PERCENT_LUT_INDEX_WIDTH));
        return lut_rec;
    end function;
    
    -- =============================================================================
    -- RECORD ACCESS FUNCTIONS
    -- =============================================================================
    
    function get_percent_lut_data_array(lut_rec : percent_lut_record_t) return percent_lut_data_array_t is
    begin
        -- Units: Input [package], Output [package]
        return lut_rec.data_array;
    end function;
    
    function get_percent_lut_crc(lut_rec : percent_lut_record_t) return std_logic_vector is
    begin
        -- Units: Input [package], Output [crc]
        return lut_rec.crc;
    end function;
    
    function get_percent_lut_valid(lut_rec : percent_lut_record_t) return std_logic is
    begin
        -- Units: Input [package], Output [signal]
        return lut_rec.valid;
    end function;
    
    function get_percent_lut_size(lut_rec : percent_lut_record_t) return std_logic_vector is
    begin
        -- Units: Input [package], Output [index]
        return lut_rec.size;
    end function;
    
    -- =============================================================================
    -- LUT CREATION FUNCTIONS
    -- =============================================================================
    
    function create_percent_lut_with_crc(lut_data : percent_lut_data_array_t) return std_logic_vector is
    begin
        -- Units: Input [package], Output [crc]
        return calculate_percent_lut_crc(lut_data);
    end function;
    
    function create_linear_percent_lut(max_value : natural) return percent_lut_data_array_t is
        variable lut_data : percent_lut_data_array_t;
        variable value : natural;
    begin
        -- Units: Input [index], Output [package]
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            value := (i * max_value) / (SYSTEM_PERCENT_LUT_SIZE-1);
            lut_data(i) := std_logic_vector(to_unsigned(value, SYSTEM_PERCENT_LUT_DATA_WIDTH));
        end loop;
        return lut_data;
    end function;
    
    function create_linear_percent_lut_record(max_value : natural) return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        -- Units: Input [index], Output [package]
        lut_data := create_linear_percent_lut(max_value);
        return create_percent_lut_record_with_crc(lut_data);
    end function;
    
    -- =============================================================================
    -- VOLTAGE CONVERSION FUNCTIONS
    -- =============================================================================
    
    function moku_voltage_to_percent_index(voltage : real) return natural is
        variable index : natural;
    begin
        -- Units: Input [volts], Output [index]
        -- Convert voltage (-5V to +5V) to percent index (0-100)
        if voltage < -5.0 then
            index := 0;
        elsif voltage > 5.0 then
            index := 100;
        else
            index := natural(((voltage + 5.0) / 10.0) * 100.0);
        end if;
        return index;
    end function;
    
    function percent_index_to_moku_voltage(index : natural) return real is
        variable voltage : real;
    begin
        -- Units: Input [index], Output [volts]
        -- Convert percent index (0-100) to voltage (-5V to +5V)
        if index > 100 then
            voltage := 5.0;
        else
            voltage := ((real(index) / 100.0) * 10.0) - 5.0;
        end if;
        return voltage;
    end function;
    
    function moku_bipolar_voltage_to_percent_index(voltage : real) return natural is
        variable index : natural;
    begin
        -- Units: Input [volts], Output [index]
        -- Convert bipolar voltage (-5V to +5V) to percent index (0-100)
        if voltage < -5.0 then
            index := 0;
        elsif voltage > 5.0 then
            index := 100;
        else
            index := natural(((voltage + 5.0) / 10.0) * 100.0);
        end if;
        return index;
    end function;
    
    function percent_index_to_moku_bipolar_voltage(index : natural) return real is
        variable voltage : real;
    begin
        -- Units: Input [index], Output [volts]
        -- Convert percent index (0-100) to bipolar voltage (-5V to +5V)
        if index > 100 then
            voltage := 5.0;
        else
            voltage := ((real(index) / 100.0) * 10.0) - 5.0;
        end if;
        return voltage;
    end function;
    
    function create_moku_voltage_lut(max_voltage : real) return percent_lut_data_array_t is
        variable lut_data : percent_lut_data_array_t;
        variable voltage : real;
        variable digital_value : std_logic_vector(15 downto 0);
    begin
        -- Units: Input [volts], Output [package]
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            voltage := percent_index_to_moku_voltage(i) * (max_voltage / 5.0);
            digital_value := voltage_to_digital_vector(voltage);
            lut_data(i) := digital_value;
        end loop;
        return lut_data;
    end function;
    
    function create_moku_voltage_lut_record(max_voltage : real) return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        -- Units: Input [volts], Output [package]
        lut_data := create_moku_voltage_lut(max_voltage);
        return create_percent_lut_record_with_crc(lut_data);
    end function;
    
    function create_moku_bipolar_voltage_lut return percent_lut_data_array_t is
        variable lut_data : percent_lut_data_array_t;
        variable voltage : real;
        variable digital_value : std_logic_vector(15 downto 0);
    begin
        -- Units: Output [package]
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            voltage := percent_index_to_moku_bipolar_voltage(i);
            digital_value := voltage_to_digital_vector(voltage);
            lut_data(i) := digital_value;
        end loop;
        return lut_data;
    end function;
    
    function create_moku_bipolar_voltage_lut_record return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        -- Units: Output [package]
        lut_data := create_moku_bipolar_voltage_lut;
        return create_percent_lut_record_with_crc(lut_data);
    end function;
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    
    function generate_test_percent_lut_data(test_index : natural) return percent_lut_data_array_t is
        variable test_data : percent_lut_data_array_t;
    begin
        -- Generate test PercentLut data array with unit validation
        -- Units: Input [index], Output [package]
        case test_index is
            when 0 =>  -- Linear 5V LUT
                test_data := create_linear_percent_lut(32767);
            when 1 =>  -- Linear 3.3V LUT
                test_data := create_linear_percent_lut(16383);
            when 2 =>  -- Moku 5V LUT
                test_data := create_moku_voltage_lut(5.0);
            when 3 =>  -- Moku 3.3V LUT
                test_data := create_moku_voltage_lut(3.3);
            when 4 =>  -- Moku bipolar LUT
                test_data := create_moku_bipolar_voltage_lut;
            when others =>  -- Default linear LUT
                test_data := create_linear_percent_lut(32767);
        end case;
        return test_data;
    end function;
    
    function generate_test_percent_lut_record(test_index : natural) return percent_lut_record_t is
        variable test_data : percent_lut_data_array_t;
    begin
        -- Generate test PercentLut record with unit validation
        -- Units: Input [index], Output [package]
        test_data := generate_test_percent_lut_data(test_index);
        return create_percent_lut_record_with_crc(test_data);
    end function;
    
    function generate_test_voltage(test_index : natural) return real is
    begin
        -- Generate test voltage for PercentLut validation
        -- Units: Input [index], Output [volts]
        case test_index is
            when 0 => return -5.0;   -- Minimum voltage
            when 1 => return 0.0;    -- Zero voltage
            when 2 => return 2.5;    -- Mid-range voltage
            when 3 => return 5.0;    -- Maximum voltage
            when 4 => return 3.3;    -- 3.3V reference
            when others => return 0.0;
        end case;
    end function;
    
    function generate_test_percent_index(test_index : natural) return natural is
    begin
        -- Generate test percent index for validation
        -- Units: Input [index], Output [index]
        case test_index is
            when 0 => return 0;      -- Minimum index
            when 1 => return 50;     -- Mid-range index
            when 2 => return 100;    -- Maximum index
            when 3 => return 25;     -- Quarter index
            when 4 => return 75;     -- Three-quarter index
            when others => return 0;
        end case;
    end function;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS
    -- =============================================================================
    
    function get_expected_units(field_name : string) return string is
    begin
        -- Get expected units for PercentLut field
        -- Units: Input [signal], Output [string]
        if field_name = "data_array" then
            return "package";
        elsif field_name = "crc" then
            return "crc";
        elsif field_name = "valid" then
            return "signal";
        elsif field_name = "size" then
            return "index";
        else
            return "unknown";
        end if;
    end function;
    
    function validate_units_consistency(lut_rec : percent_lut_record_t) return boolean is
    begin
        -- Validate units consistency for PercentLut record
        -- Units: Input [package], Output [boolean]
        
        -- Check validity flag
        if lut_rec.valid /= '1' and lut_rec.valid /= '0' then
            return false;
        end if;
        
        -- Check size is within valid range
        if unsigned(lut_rec.size) > SYSTEM_PERCENT_LUT_SIZE-1 then
            return false;
        end if;
        
        -- Check CRC width
        if lut_rec.crc'length /= SYSTEM_PERCENT_LUT_CRC_WIDTH then
            return false;
        end if;
        
        -- Check data array dimensions
        if lut_rec.data_array'length /= SYSTEM_PERCENT_LUT_SIZE then
            return false;
        end if;
        
        -- Check each data element width
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            if lut_rec.data_array(i)'length /= SYSTEM_PERCENT_LUT_DATA_WIDTH then
                return false;
            end if;
        end loop;
        
        return true;
    end function;
    
    function validate_units_consistency_data(lut_data : percent_lut_data_array_t) return boolean is
    begin
        -- Validate units consistency for PercentLut data array
        -- Units: Input [package], Output [boolean]
        
        -- Check array dimensions
        if lut_data'length /= SYSTEM_PERCENT_LUT_SIZE then
            return false;
        end if;
        
        -- Check each data element width
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            if lut_data(i)'length /= SYSTEM_PERCENT_LUT_DATA_WIDTH then
                return false;
            end if;
        end loop;
        
        return true;
    end function;
    
    -- =============================================================================
    -- PREDEFINED LUT CONSTANTS
    -- =============================================================================
    
    -- Predefined LUT data arrays (calculated at package elaboration time)
    -- Units: package (data arrays)
    constant LINEAR_5V_LUT_DATA : percent_lut_data_array_t := create_linear_percent_lut(32767);  -- [package]
    constant LINEAR_3V3_LUT_DATA : percent_lut_data_array_t := create_linear_percent_lut(16383);  -- [package]
    constant MOKU_5V_LUT_DATA : percent_lut_data_array_t := create_moku_voltage_lut(5.0);  -- [package]
    constant MOKU_3V3_LUT_DATA : percent_lut_data_array_t := create_moku_voltage_lut(3.3);  -- [package]
    constant MOKU_BIPOLAR_LUT_DATA : percent_lut_data_array_t := create_moku_bipolar_voltage_lut;  -- [package]
    
    -- Predefined LUT records (calculated at package elaboration time)
    -- Units: package (records)
    constant LINEAR_5V_LUT : percent_lut_record_t := create_linear_percent_lut_record(32767);  -- [package]
    constant LINEAR_3V3_LUT : percent_lut_record_t := create_linear_percent_lut_record(16383);  -- [package]
    constant MOKU_5V_LUT : percent_lut_record_t := create_moku_voltage_lut_record(5.0);  -- [package]
    constant MOKU_3V3_LUT : percent_lut_record_t := create_moku_voltage_lut_record(3.3);  -- [package]
    constant MOKU_BIPOLAR_LUT : percent_lut_record_t := create_moku_bipolar_voltage_lut_record;  -- [package]

end package body PercentLut_pkg_en;
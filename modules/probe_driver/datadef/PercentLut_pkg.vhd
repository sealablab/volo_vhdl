--------------------------------------------------------------------------------
-- Package: PercentLut_pkg
-- Purpose: PercentLut datatype with CRC validation and safe lookup functions (Record-based)
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- DATADEF PACKAGE: This package defines data structures using records for better
-- encapsulation and type safety. This is the main PercentLut_pkg.vhd implementation
-- using record-based data structures.
-- 
-- VERILOG CONVERSION STRATEGY:
-- - Records -> flattened structs with explicit field access
-- - Array types -> parameter arrays or memory initialization files (.mem)
-- - CRC functions -> separate Verilog modules or SystemVerilog functions
-- - Function overloading -> renamed functions (get_percentlut_value_by_vector, etc.)
-- - Record access -> explicit field access (e.g., lut.data_array[index])
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package PercentLut_pkg is
    
    -- Data Definition Constants (cfg_* prefix for configuration parameters)
    constant CFG_PERCENT_LUT_SIZE : natural := 101; -- Indices 0-100
    constant CFG_PERCENT_LUT_INDEX_WIDTH : natural := 7; -- 7 bits to address 0-100
    constant CFG_PERCENT_LUT_DATA_WIDTH : natural := 16; -- 16-bit unsigned data
    constant CFG_PERCENT_LUT_CRC_WIDTH : natural := 16; -- CRC-16
    
    -- CRC-16 polynomial (CRC-16-CCITT: x^16 + x^12 + x^5 + 1)
    constant CFG_CRC16_POLYNOMIAL : std_logic_vector(15 downto 0) := x"1021";
    constant CFG_CRC16_INIT_VALUE : std_logic_vector(15 downto 0) := x"FFFF";
    
    -- PercentLut data type (array types allowed in datadef packages)
    -- VERILOG CONVERSION: Convert to parameter array or .mem file
    type percent_lut_data_array_t is array (0 to CFG_PERCENT_LUT_SIZE-1) of std_logic_vector(CFG_PERCENT_LUT_DATA_WIDTH-1 downto 0);
    
    -- Record-based PercentLut structure
    -- VERILOG CONVERSION: Flatten to individual fields with explicit access
    type percent_lut_record_t is record
        data_array : percent_lut_data_array_t;  -- The actual LUT data
        crc        : std_logic_vector(CFG_PERCENT_LUT_CRC_WIDTH-1 downto 0);  -- CRC validation
        valid      : std_logic;  -- Validity flag
        size       : std_logic_vector(CFG_PERCENT_LUT_INDEX_WIDTH-1 downto 0);  -- Current size (0-100)
    end record;
    
    -- Default/initialization values for the record
    constant CFG_PERCENT_LUT_RECORD_DEFAULT : percent_lut_record_t := (
        data_array => (others => (others => '0')),
        crc        => (others => '0'),
        valid      => '0',
        size       => (others => '0')
    );
    
    -- Function declarations
    
    -- CRC calculation and validation
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) return std_logic_vector;
    function validate_percent_lut(lut_data : percent_lut_data_array_t; lut_crc : std_logic_vector) return boolean;
    
    -- Record-based validation functions
    function validate_percent_lut_record(lut_rec : percent_lut_record_t) return boolean;
    function is_percent_lut_record_valid(lut_rec : percent_lut_record_t) return boolean;
    
    -- Safe lookup functions (with bounds checking and clamping) - Record-based
    function get_percentlut_value_safe(lut_rec : percent_lut_record_t; 
                                      index : std_logic_vector(6 downto 0)) 
                                      return std_logic_vector;
    
    function get_percentlut_value_safe(lut_rec : percent_lut_record_t; 
                                      index : natural) 
                                      return std_logic_vector;
    
    -- Safe lookup functions (with bounds checking and clamping) - Array-based (for compatibility)
    function get_percentlut_value_safe(lut_data : percent_lut_data_array_t; 
                                      index : std_logic_vector(6 downto 0)) 
                                      return std_logic_vector;
    
    function get_percentlut_value_safe(lut_data : percent_lut_data_array_t; 
                                      index : natural) 
                                      return std_logic_vector;
    
    -- Index validation utilities
    function is_valid_percent_lut_index(index : std_logic_vector) return boolean;
    function is_valid_percent_lut_index(index : natural) return boolean;
    
    -- Record manipulation functions
    function create_percent_lut_record(lut_data : percent_lut_data_array_t) return percent_lut_record_t;
    function create_percent_lut_record_with_crc(lut_data : percent_lut_data_array_t) return percent_lut_record_t;
    function update_percent_lut_record_data(lut_rec : percent_lut_record_t; 
                                           new_data : percent_lut_data_array_t) return percent_lut_record_t;
    function update_percent_lut_record_size(lut_rec : percent_lut_record_t; 
                                           new_size : natural) return percent_lut_record_t;
    
    -- Record field access helpers (for Verilog conversion compatibility)
    function get_percent_lut_data_array(lut_rec : percent_lut_record_t) return percent_lut_data_array_t;
    function get_percent_lut_crc(lut_rec : percent_lut_record_t) return std_logic_vector;
    function get_percent_lut_valid(lut_rec : percent_lut_record_t) return std_logic;
    function get_percent_lut_size(lut_rec : percent_lut_record_t) return std_logic_vector;
    
    -- Helper function to create a valid LUT with CRC (legacy compatibility)
    function create_percent_lut_with_crc(lut_data : percent_lut_data_array_t) return std_logic_vector;
    
end package PercentLut_pkg;

package body PercentLut_pkg is
    
    -- CRC-16 calculation function
    function crc16_update(crc_in : std_logic_vector(15 downto 0); 
                         data_byte : std_logic_vector(7 downto 0)) 
                         return std_logic_vector is
        variable crc_temp : std_logic_vector(15 downto 0);
        variable data_temp : std_logic_vector(7 downto 0);
    begin
        crc_temp := crc_in;
        data_temp := data_byte;
        
        for i in 7 downto 0 loop
            if ((crc_temp(15) xor data_temp(i)) = '1') then
                crc_temp := (crc_temp(14 downto 0) & '0') xor CFG_CRC16_POLYNOMIAL;
            else
                crc_temp := crc_temp(14 downto 0) & '0';
            end if;
        end loop;
        
        return crc_temp;
    end function;
    
    -- Calculate CRC for the entire LUT data array
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) 
                                      return std_logic_vector is
        variable crc : std_logic_vector(15 downto 0) := CFG_CRC16_INIT_VALUE;
        variable data_word : std_logic_vector(15 downto 0);
    begin
        -- Process each 16-bit word in the LUT
        for i in 0 to CFG_PERCENT_LUT_SIZE-1 loop
            data_word := lut_data(i);
            -- Process high byte first, then low byte
            crc := crc16_update(crc, data_word(15 downto 8));
            crc := crc16_update(crc, data_word(7 downto 0));
        end loop;
        
        return crc;
    end function;
    
    -- Validate PercentLut by checking CRC
    function validate_percent_lut(lut_data : percent_lut_data_array_t; lut_crc : std_logic_vector) return boolean is
        variable calculated_crc : std_logic_vector(15 downto 0);
    begin
        -- Check that index 0 contains 0x0000
        if lut_data(0) /= x"0000" then
            return false;
        end if;
        
        -- Calculate CRC and compare with stored CRC
        calculated_crc := calculate_percent_lut_crc(lut_data);
        return (calculated_crc = lut_crc);
    end function;
    
    -- Record-based validation functions
    function validate_percent_lut_record(lut_rec : percent_lut_record_t) return boolean is
        variable calculated_crc : std_logic_vector(15 downto 0);
    begin
        -- Check that index 0 contains 0x0000
        if lut_rec.data_array(0) /= x"0000" then
            return false;
        end if;
        
        -- Calculate CRC and compare with stored CRC
        calculated_crc := calculate_percent_lut_crc(lut_rec.data_array);
        return (calculated_crc = lut_rec.crc);
    end function;
    
    function is_percent_lut_record_valid(lut_rec : percent_lut_record_t) return boolean is
    begin
        return (lut_rec.valid = '1') and validate_percent_lut_record(lut_rec);
    end function;
    
    -- Safe lookup function with std_logic_vector index (Record-based)
    function get_percentlut_value_safe(lut_rec : percent_lut_record_t; 
                                      index : std_logic_vector(6 downto 0)) 
                                      return std_logic_vector is
        variable int_index : natural;
    begin
        -- Check if record is valid first
        if lut_rec.valid = '0' then
            return std_logic_vector(to_unsigned(0, CFG_PERCENT_LUT_DATA_WIDTH));
        end if;
        
        int_index := to_integer(unsigned(index));
        -- Clamp to valid range
        if int_index > 100 then
            int_index := 100;
        end if;
        return lut_rec.data_array(int_index);
    end function;
    
    -- Safe lookup function with natural index (Record-based)
    function get_percentlut_value_safe(lut_rec : percent_lut_record_t; 
                                      index : natural) 
                                      return std_logic_vector is
        variable int_index : natural;
    begin
        -- Check if record is valid first
        if lut_rec.valid = '0' then
            return std_logic_vector(to_unsigned(0, CFG_PERCENT_LUT_DATA_WIDTH));
        end if;
        
        int_index := index;
        -- Clamp to valid range
        if int_index > 100 then
            int_index := 100;
        end if;
        return lut_rec.data_array(int_index);
    end function;
    
    -- Safe lookup function with std_logic_vector index (Array-based for compatibility)
    function get_percentlut_value_safe(lut_data : percent_lut_data_array_t; 
                                      index : std_logic_vector(6 downto 0)) 
                                      return std_logic_vector is
        variable int_index : natural;
    begin
        int_index := to_integer(unsigned(index));
        -- Clamp to valid range
        if int_index > 100 then
            int_index := 100;
        end if;
        return lut_data(int_index);
    end function;
    
    -- Safe lookup function with natural index (Array-based for compatibility)
    function get_percentlut_value_safe(lut_data : percent_lut_data_array_t; 
                                      index : natural) 
                                      return std_logic_vector is
        variable int_index : natural;
    begin
        int_index := index;
        -- Clamp to valid range
        if int_index > 100 then
            int_index := 100;
        end if;
        return lut_data(int_index);
    end function;
    
    -- Check if index is valid (0-100) - std_logic_vector version
    function is_valid_percent_lut_index(index : std_logic_vector) return boolean is
        variable index_val : natural;
    begin
        index_val := to_integer(unsigned(index));
        return (index_val <= 100);
    end function;
    
    -- Check if index is valid (0-100) - natural version
    function is_valid_percent_lut_index(index : natural) return boolean is
    begin
        return (index <= 100);
    end function;
    
    -- Record manipulation functions
    function create_percent_lut_record(lut_data : percent_lut_data_array_t) return percent_lut_record_t is
        variable result : percent_lut_record_t;
    begin
        result.data_array := lut_data;
        result.crc := calculate_percent_lut_crc(lut_data);
        result.valid := '1';
        result.size := std_logic_vector(to_unsigned(CFG_PERCENT_LUT_SIZE-1, CFG_PERCENT_LUT_INDEX_WIDTH));
        return result;
    end function;
    
    function create_percent_lut_record_with_crc(lut_data : percent_lut_data_array_t) return percent_lut_record_t is
    begin
        return create_percent_lut_record(lut_data);
    end function;
    
    function update_percent_lut_record_data(lut_rec : percent_lut_record_t; 
                                           new_data : percent_lut_data_array_t) return percent_lut_record_t is
        variable result : percent_lut_record_t;
    begin
        result := lut_rec;
        result.data_array := new_data;
        result.crc := calculate_percent_lut_crc(new_data);
        result.valid := '1';
        return result;
    end function;
    
    function update_percent_lut_record_size(lut_rec : percent_lut_record_t; 
                                           new_size : natural) return percent_lut_record_t is
        variable result : percent_lut_record_t;
    begin
        result := lut_rec;
        if new_size <= 100 then
            result.size := std_logic_vector(to_unsigned(new_size, CFG_PERCENT_LUT_INDEX_WIDTH));
        else
            result.size := std_logic_vector(to_unsigned(100, CFG_PERCENT_LUT_INDEX_WIDTH));
        end if;
        return result;
    end function;
    
    -- Record field access helpers (for Verilog conversion compatibility)
    function get_percent_lut_data_array(lut_rec : percent_lut_record_t) return percent_lut_data_array_t is
    begin
        return lut_rec.data_array;
    end function;
    
    function get_percent_lut_crc(lut_rec : percent_lut_record_t) return std_logic_vector is
    begin
        return lut_rec.crc;
    end function;
    
    function get_percent_lut_valid(lut_rec : percent_lut_record_t) return std_logic is
    begin
        return lut_rec.valid;
    end function;
    
    function get_percent_lut_size(lut_rec : percent_lut_record_t) return std_logic_vector is
    begin
        return lut_rec.size;
    end function;
    
    -- Helper function to create a valid LUT with CRC (legacy compatibility)
    function create_percent_lut_with_crc(lut_data : percent_lut_data_array_t) return std_logic_vector is
    begin
        return calculate_percent_lut_crc(lut_data);
    end function;
    
end package body PercentLut_pkg;
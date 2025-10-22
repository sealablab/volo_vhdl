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

-- Import Moku_Voltage_pkg for voltage conversion support
use work.Moku_Voltage_pkg.all;

package PercentLut_pkg is
    
    -- Data Definition Constants (SYSTEM_* prefix for system parameters that should not be modified)
    constant SYSTEM_PERCENT_LUT_SIZE : natural := 101; -- Indices 0-100
    constant SYSTEM_PERCENT_LUT_INDEX_WIDTH : natural := 7; -- 7 bits to address 0-100
    constant SYSTEM_PERCENT_LUT_DATA_WIDTH : natural := 16; -- 16-bit unsigned data
    constant SYSTEM_PERCENT_LUT_CRC_WIDTH : natural := 16; -- CRC-16
    
    -- CRC-16 polynomial (CRC-16-CCITT: x^16 + x^12 + x^5 + 1)
    constant SYSTEM_CRC16_POLYNOMIAL : std_logic_vector(15 downto 0) := x"1021";
    constant SYSTEM_CRC16_INIT_VALUE : std_logic_vector(15 downto 0) := x"FFFF";
    
    -- PercentLut data type (array types allowed in datadef packages)
    -- VERILOG CONVERSION: Convert to parameter array or .mem file
    type percent_lut_data_array_t is array (0 to SYSTEM_PERCENT_LUT_SIZE-1) of std_logic_vector(SYSTEM_PERCENT_LUT_DATA_WIDTH-1 downto 0);
    
    -- Record-based PercentLut structure
    -- VERILOG CONVERSION: Flatten to individual fields with explicit access
    type percent_lut_record_t is record
        data_array : percent_lut_data_array_t;  -- The actual LUT data
        crc        : std_logic_vector(SYSTEM_PERCENT_LUT_CRC_WIDTH-1 downto 0);  -- CRC validation
        valid      : std_logic;  -- Validity flag
        size       : std_logic_vector(SYSTEM_PERCENT_LUT_INDEX_WIDTH-1 downto 0);  -- Current size (0-100)
    end record;
    
    -- Default/initialization values for the record
	-- JC: This seems both impressive and potentially fragile..
    constant SYSTEM_PERCENT_LUT_RECORD_DEFAULT : percent_lut_record_t := (
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
    
    -- Linear LUT generation functions
    function create_linear_percent_lut(max_value : natural) return percent_lut_data_array_t;
    function create_linear_percent_lut_record(max_value : natural) return percent_lut_record_t;
    
    -- Predefined linear LUTs
    -- LUT for 0V to 4.99999V (0x00 to 0x7FFF)
    constant LINEAR_5V_LUT_DATA : percent_lut_data_array_t;
    constant LINEAR_5V_LUT : percent_lut_record_t;
    
    -- LUT for 0V to 3.3V (0x00 to 0x3FFF) 
    constant LINEAR_3V3_LUT_DATA : percent_lut_data_array_t;
    constant LINEAR_3V3_LUT : percent_lut_record_t;
    
    -- =============================================================================
    -- MOKU VOLTAGE INTEGRATION FUNCTIONS
    -- =============================================================================
    
    -- Create LUT from voltage range (using Moku_Voltage_pkg conversion)
    function create_voltage_percent_lut(min_voltage : real; max_voltage : real) 
        return percent_lut_data_array_t;
    
    -- Create LUT record from voltage range (using Moku_Voltage_pkg conversion)
    function create_voltage_percent_lut_record(min_voltage : real; max_voltage : real) 
        return percent_lut_record_t;
    
    -- Convert voltage to LUT index (0-100) for a given voltage range
    function voltage_to_lut_index(voltage : real; min_voltage : real; max_voltage : real) 
        return natural;
    
    -- Convert LUT index to voltage for a given voltage range
    function lut_index_to_voltage(index : natural; min_voltage : real; max_voltage : real) 
        return real;
    
    -- Convert Moku voltage to PercentLut index (0-100) for unipolar 0V to +5V range
    function moku_voltage_to_percent_index(voltage : real) return natural;
    
    -- Convert PercentLut index to Moku voltage for unipolar 0V to +5V range
    function percent_index_to_moku_voltage(index : natural) return real;
    
    -- Convert Moku voltage to PercentLut index (0-100) for bipolar -5V to +5V range
    function moku_bipolar_voltage_to_percent_index(voltage : real) return natural;
    
    -- Convert PercentLut index to Moku voltage for bipolar -5V to +5V range
    function percent_index_to_moku_bipolar_voltage(index : natural) return real;
    
    -- Create LUT from Moku voltage range (unipolar 0V to +5V)
    function create_moku_voltage_lut(max_voltage : real) return percent_lut_data_array_t;
    
    -- Create LUT record from Moku voltage range (unipolar 0V to +5V)
    function create_moku_voltage_lut_record(max_voltage : real) return percent_lut_record_t;
    
    -- Create LUT from Moku voltage range (bipolar -5V to +5V)
    function create_moku_bipolar_voltage_lut return percent_lut_data_array_t;
    
    -- Create LUT record from Moku voltage range (bipolar -5V to +5V)
    function create_moku_bipolar_voltage_lut_record return percent_lut_record_t;
    
    -- Predefined Moku voltage LUTs
    constant MOKU_5V_LUT_DATA : percent_lut_data_array_t;
    constant MOKU_5V_LUT : percent_lut_record_t;
    
    constant MOKU_3V3_LUT_DATA : percent_lut_data_array_t;
    constant MOKU_3V3_LUT : percent_lut_record_t;
    
    constant MOKU_BIPOLAR_LUT_DATA : percent_lut_data_array_t;
    constant MOKU_BIPOLAR_LUT : percent_lut_record_t;
    
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
                crc_temp := (crc_temp(14 downto 0) & '0') xor SYSTEM_CRC16_POLYNOMIAL;
            else
                crc_temp := crc_temp(14 downto 0) & '0';
            end if;
        end loop;
        
        return crc_temp;
    end function;
    
    -- Calculate CRC for the entire LUT data array
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) 
                                      return std_logic_vector is
        variable crc : std_logic_vector(15 downto 0) := SYSTEM_CRC16_INIT_VALUE;
        variable data_word : std_logic_vector(15 downto 0);
    begin
        -- Process each 16-bit word in the LUT
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
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
            return std_logic_vector(to_unsigned(0, SYSTEM_PERCENT_LUT_DATA_WIDTH));
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
            return std_logic_vector(to_unsigned(0, SYSTEM_PERCENT_LUT_DATA_WIDTH));
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
        result.size := std_logic_vector(to_unsigned(SYSTEM_PERCENT_LUT_SIZE-1, SYSTEM_PERCENT_LUT_INDEX_WIDTH));
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
            result.size := std_logic_vector(to_unsigned(new_size, SYSTEM_PERCENT_LUT_INDEX_WIDTH));
        else
            result.size := std_logic_vector(to_unsigned(100, SYSTEM_PERCENT_LUT_INDEX_WIDTH));
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
    
    -- Linear LUT generation function
    function create_linear_percent_lut(max_value : natural) return percent_lut_data_array_t is
        variable result : percent_lut_data_array_t;
        variable step_value : natural;
    begin
        -- Initialize with zeros
        result := (others => (others => '0'));
        
        -- Generate linear steps from 0 to max_value
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            -- Calculate step value: (i * max_value) / 100
            -- Use integer division for exact steps
            step_value := (i * max_value) / 100;
            
            -- Ensure we don't exceed max_value
            if step_value > max_value then
                step_value := max_value;
            end if;
            
            result(i) := std_logic_vector(to_unsigned(step_value, SYSTEM_PERCENT_LUT_DATA_WIDTH));
        end loop;
        
        return result;
    end function;
    
    -- Linear LUT generation function that returns a record
    function create_linear_percent_lut_record(max_value : natural) return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        lut_data := create_linear_percent_lut(max_value);
        return create_percent_lut_record(lut_data);
    end function;
    
    -- Predefined linear LUTs
    -- LUT for 0V to 4.99999V (0x00 to 0x7FFF = 32767)
    constant LINEAR_5V_LUT_DATA : percent_lut_data_array_t := create_linear_percent_lut(32767);
    constant LINEAR_5V_LUT : percent_lut_record_t := create_linear_percent_lut_record(32767);
    
    -- LUT for 0V to 3.3V (0x00 to 0x3FFF = 16383)
    -- Note: 0x3FFF = 16383, which represents 3.3V on a 5V scale
    -- For true 3.3V representation: (3.3/5.0) * 32767 = 21628
    -- But using 0x3FFF (16383) as requested for exact hex representation
    constant LINEAR_3V3_LUT_DATA : percent_lut_data_array_t := create_linear_percent_lut(16383);
    constant LINEAR_3V3_LUT : percent_lut_record_t := create_linear_percent_lut_record(16383);
    
    -- =============================================================================
    -- MOKU VOLTAGE INTEGRATION FUNCTION IMPLEMENTATIONS
    -- =============================================================================
    
    -- Create LUT from voltage range (using Moku_Voltage_pkg conversion)
    function create_voltage_percent_lut(min_voltage : real; max_voltage : real) 
        return percent_lut_data_array_t is
        variable result : percent_lut_data_array_t;
        variable voltage_step : real;
        variable current_voltage : real;
        variable digital_value : signed(15 downto 0);
        variable unsigned_value : unsigned(15 downto 0);
    begin
        -- Initialize with zeros
        result := (others => (others => '0'));
        
        -- Calculate voltage step size
        voltage_step := (max_voltage - min_voltage) / 100.0;
        
        -- Generate LUT entries
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            -- Calculate current voltage
            current_voltage := min_voltage + (real(i) * voltage_step);
            
            -- Convert voltage to Moku digital value
            digital_value := voltage_to_digital(current_voltage);
            
            -- Convert signed to unsigned for PercentLut storage
            -- Handle negative values by clamping to 0
            if digital_value < 0 then
                unsigned_value := to_unsigned(0, 16);
            else
                unsigned_value := unsigned(digital_value);
            end if;
            
            result(i) := std_logic_vector(unsigned_value);
        end loop;
        
        return result;
    end function;
    
    -- Create LUT record from voltage range (using Moku_Voltage_pkg conversion)
    function create_voltage_percent_lut_record(min_voltage : real; max_voltage : real) 
        return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        lut_data := create_voltage_percent_lut(min_voltage, max_voltage);
        return create_percent_lut_record(lut_data);
    end function;
    
    -- Convert voltage to LUT index (0-100) for a given voltage range
    function voltage_to_lut_index(voltage : real; min_voltage : real; max_voltage : real) 
        return natural is
        variable voltage_range : real;
        variable normalized_voltage : real;
        variable index_real : real;
        variable index_int : natural;
    begin
        -- Clamp voltage to valid range
        if voltage < min_voltage then
            return 0;
        elsif voltage > max_voltage then
            return 100;
        end if;
        
        -- Calculate normalized voltage (0.0 to 1.0)
        voltage_range := max_voltage - min_voltage;
        if voltage_range <= 0.0 then
            return 0;
        end if;
        
        normalized_voltage := (voltage - min_voltage) / voltage_range;
        
        -- Convert to index (0-100)
        index_real := normalized_voltage * 100.0;
        index_int := natural(index_real + 0.5); -- Round to nearest integer
        
        -- Clamp to valid range
        if index_int > 100 then
            index_int := 100;
        end if;
        
        return index_int;
    end function;
    
    -- Convert LUT index to voltage for a given voltage range
    function lut_index_to_voltage(index : natural; min_voltage : real; max_voltage : real) 
        return real is
        variable voltage_range : real;
        variable normalized_index : real;
    begin
        -- Clamp index to valid range
        if index > 100 then
            return max_voltage;
        end if;
        
        -- Calculate voltage range
        voltage_range := max_voltage - min_voltage;
        
        -- Convert index to normalized value (0.0 to 1.0)
        normalized_index := real(index) / 100.0;
        
        -- Convert to voltage
        return min_voltage + (normalized_index * voltage_range);
    end function;
    
    -- Convert Moku voltage to PercentLut index (0-100) for unipolar 0V to +5V range
    function moku_voltage_to_percent_index(voltage : real) return natural is
    begin
        return voltage_to_lut_index(voltage, 0.0, 5.0);
    end function;
    
    -- Convert PercentLut index to Moku voltage for unipolar 0V to +5V range
    function percent_index_to_moku_voltage(index : natural) return real is
    begin
        return lut_index_to_voltage(index, 0.0, 5.0);
    end function;
    
    -- Convert Moku voltage to PercentLut index (0-100) for bipolar -5V to +5V range
    function moku_bipolar_voltage_to_percent_index(voltage : real) return natural is
    begin
        return voltage_to_lut_index(voltage, -5.0, 5.0);
    end function;
    
    -- Convert PercentLut index to Moku voltage for bipolar -5V to +5V range
    function percent_index_to_moku_bipolar_voltage(index : natural) return real is
    begin
        return lut_index_to_voltage(index, -5.0, 5.0);
    end function;
    
    -- Create LUT from Moku voltage range (unipolar 0V to +5V)
    function create_moku_voltage_lut(max_voltage : real) return percent_lut_data_array_t is
    begin
        return create_voltage_percent_lut(0.0, max_voltage);
    end function;
    
    -- Create LUT record from Moku voltage range (unipolar 0V to +5V)
    function create_moku_voltage_lut_record(max_voltage : real) return percent_lut_record_t is
    begin
        return create_voltage_percent_lut_record(0.0, max_voltage);
    end function;
    
    -- Create LUT from Moku voltage range (bipolar -5V to +5V)
    function create_moku_bipolar_voltage_lut return percent_lut_data_array_t is
        variable result : percent_lut_data_array_t;
        variable voltage_step : real;
        variable current_voltage : real;
        variable digital_value : signed(15 downto 0);
        variable unsigned_value : unsigned(15 downto 0);
    begin
        -- Initialize with zeros
        result := (others => (others => '0'));
        
        -- Calculate voltage step size (-5V to +5V = 10V range)
        voltage_step := 10.0 / 100.0; -- 0.1V per step
        
        -- Generate LUT entries
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            -- Calculate current voltage (-5V to +5V)
            current_voltage := -5.0 + (real(i) * voltage_step);
            
            -- Convert voltage to Moku digital value
            digital_value := voltage_to_digital(current_voltage);
            
            -- Convert signed to unsigned for PercentLut storage
            -- Map -32768 to 0, 0 to 16384, +32767 to 32767
            -- Use a simpler approach to avoid bound check issues
            if digital_value < 0 then
                -- Map negative values to 0-16383 range
                -- Add 32768 to shift -32768 to 0, then add 16384 to get proper range
                unsigned_value := to_unsigned(16384 + to_integer(digital_value) + 32768, 16);
            else
                -- Map positive values to 16384-32767 range
                unsigned_value := to_unsigned(16384 + to_integer(digital_value), 16);
            end if;
            
            result(i) := std_logic_vector(unsigned_value);
        end loop;
        
        return result;
    end function;
    
    -- Create LUT record from Moku voltage range (bipolar -5V to +5V)
    function create_moku_bipolar_voltage_lut_record return percent_lut_record_t is
        variable lut_data : percent_lut_data_array_t;
    begin
        lut_data := create_moku_bipolar_voltage_lut;
        return create_percent_lut_record(lut_data);
    end function;
    
    -- Predefined Moku voltage LUTs
    -- LUT for 0V to 5V using Moku voltage conversion
    constant MOKU_5V_LUT_DATA : percent_lut_data_array_t := create_moku_voltage_lut(5.0);
    constant MOKU_5V_LUT : percent_lut_record_t := create_moku_voltage_lut_record(5.0);
    
    -- LUT for 0V to 3.3V using Moku voltage conversion
    constant MOKU_3V3_LUT_DATA : percent_lut_data_array_t := create_moku_voltage_lut(3.3);
    constant MOKU_3V3_LUT : percent_lut_record_t := create_moku_voltage_lut_record(3.3);
    
    -- LUT for -5V to +5V using Moku voltage conversion
    constant MOKU_BIPOLAR_LUT_DATA : percent_lut_data_array_t := create_moku_bipolar_voltage_lut;
    constant MOKU_BIPOLAR_LUT : percent_lut_record_t := create_moku_bipolar_voltage_lut_record;
    
end package body PercentLut_pkg;

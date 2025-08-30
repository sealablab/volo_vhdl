--------------------------------------------------------------------------------
-- Package: PercentLut_pkg_en (Enhanced with Unit Hinting)
-- Purpose: PercentLut datatype with CRC validation and safe lookup functions (Record-based)
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- ENHANCED FEATURES:
-- - Unit hinting for all data types, functions, and parameters
-- - Enhanced validation functions with unit consistency checking
-- - Comprehensive test data generation with unit awareness
-- - Zero synthesis overhead - pure documentation enhancement
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
-- 
-- UNIT CONVENTIONS:
-- - volts: Voltage values (V)
-- - clks: Clock cycle counts (cycles)
-- - index: Array indices and percentages (unitless)
-- - bits: Bit field widths and positions (bits)
-- - signal: Signal names and identifiers (unitless)
-- - package: Package names and identifiers (unitless)
-- - module: Module names and identifiers (unitless)
-- - percent: Percentage values (0-100, unitless)
-- - crc: CRC values (unitless)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import Moku_Voltage_pkg for voltage conversion support
use work.Moku_Voltage_pkg.all;

package PercentLut_pkg_en is
    
    -- =============================================================================
    -- DATA DEFINITION CONSTANTS
    -- =============================================================================
    
    -- Data Definition Constants (SYSTEM_* prefix for system parameters that should not be modified)
    -- Units: index for sizes, bits for widths, percent for percentages
    constant SYSTEM_PERCENT_LUT_SIZE : natural := 101; -- Indices 0-100 [index]
    constant SYSTEM_PERCENT_LUT_INDEX_WIDTH : natural := 7; -- 7 bits to address 0-100 [bits]
    constant SYSTEM_PERCENT_LUT_DATA_WIDTH : natural := 16; -- 16-bit unsigned data [bits]
    constant SYSTEM_PERCENT_LUT_CRC_WIDTH : natural := 16; -- CRC-16 [bits]
    
    -- CRC-16 polynomial (CRC-16-CCITT: x^16 + x^12 + x^5 + 1)
    -- Units: bits for polynomial and initial value
    constant SYSTEM_CRC16_POLYNOMIAL : std_logic_vector(15 downto 0) := x"1021";  -- [bits]
    constant SYSTEM_CRC16_INIT_VALUE : std_logic_vector(15 downto 0) := x"FFFF";  -- [bits]
    
    -- =============================================================================
    -- DATA TYPES
    -- =============================================================================
    
    -- PercentLut data type (array types allowed in datadef packages)
    -- VERILOG CONVERSION: Convert to parameter array or .mem file
    -- Units: package (array of bit vectors)
    type percent_lut_data_array_t is array (0 to SYSTEM_PERCENT_LUT_SIZE-1) of std_logic_vector(SYSTEM_PERCENT_LUT_DATA_WIDTH-1 downto 0);  -- [package]
    
    -- Record-based PercentLut structure
    -- VERILOG CONVERSION: Flatten to individual fields with explicit access
    -- Units: package (record containing data array, CRC, validity, and size)
    type percent_lut_record_t is record
        data_array : percent_lut_data_array_t;  -- The actual LUT data [package]
        crc        : std_logic_vector(SYSTEM_PERCENT_LUT_CRC_WIDTH-1 downto 0);  -- CRC validation [crc]
        valid      : std_logic;  -- Validity flag [signal]
        size       : std_logic_vector(SYSTEM_PERCENT_LUT_INDEX_WIDTH-1 downto 0);  -- Current size (0-100) [index]
    end record;
    
    -- =============================================================================
    -- CRC VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Calculate CRC for PercentLut data array
    -- Input: lut_data [package] - PercentLut data array
    -- Output: std_logic_vector [crc] - Calculated CRC value
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) return std_logic_vector;
    
    -- Validate PercentLut data against CRC
    -- Input: lut_data [package] - PercentLut data array, lut_crc [crc] - Expected CRC
    -- Output: boolean - True if CRC matches
    function validate_percent_lut(lut_data : percent_lut_data_array_t; lut_crc : std_logic_vector) return boolean;
    
    -- =============================================================================
    -- RECORD VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Validate PercentLut record structure
    -- Input: lut_rec [package] - PercentLut record to validate
    -- Output: boolean - True if record is valid
    function validate_percent_lut_record(lut_rec : percent_lut_record_t) return boolean;
    
    -- Check if PercentLut record is valid (alias for validate_percent_lut_record)
    -- Input: lut_rec [package] - PercentLut record to check
    -- Output: boolean - True if record is valid
    function is_percent_lut_record_valid(lut_rec : percent_lut_record_t) return boolean;
    
    -- =============================================================================
    -- INDEX VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Check if index is valid for PercentLut access
    -- Input: index [index] - Index to validate (as std_logic_vector)
    -- Output: boolean - True if index is within valid range
    function is_valid_percent_lut_index(index : std_logic_vector) return boolean;
    
    -- Input: index [index] - Index to validate (as natural)
    -- Output: boolean - True if index is within valid range
    function is_valid_percent_lut_index(index : natural) return boolean;
    
    -- =============================================================================
    -- RECORD CREATION FUNCTIONS
    -- =============================================================================
    
    -- Create PercentLut record from data array (without CRC calculation)
    -- Input: lut_data [package] - PercentLut data array
    -- Output: percent_lut_record_t [package] - PercentLut record
    function create_percent_lut_record(lut_data : percent_lut_data_array_t) return percent_lut_record_t;
    
    -- Create PercentLut record from data array (with CRC calculation)
    -- Input: lut_data [package] - PercentLut data array
    -- Output: percent_lut_record_t [package] - PercentLut record with calculated CRC
    function create_percent_lut_record_with_crc(lut_data : percent_lut_data_array_t) return percent_lut_record_t;
    
    -- =============================================================================
    -- RECORD ACCESS FUNCTIONS
    -- =============================================================================
    
    -- Get data array from PercentLut record
    -- Input: lut_rec [package] - PercentLut record
    -- Output: percent_lut_data_array_t [package] - Data array from record
    function get_percent_lut_data_array(lut_rec : percent_lut_record_t) return percent_lut_data_array_t;
    
    -- Get CRC from PercentLut record
    -- Input: lut_rec [package] - PercentLut record
    -- Output: std_logic_vector [crc] - CRC from record
    function get_percent_lut_crc(lut_rec : percent_lut_record_t) return std_logic_vector;
    
    -- Get validity flag from PercentLut record
    -- Input: lut_rec [package] - PercentLut record
    -- Output: std_logic [signal] - Validity flag from record
    function get_percent_lut_valid(lut_rec : percent_lut_record_t) return std_logic;
    
    -- Get size from PercentLut record
    -- Input: lut_rec [package] - PercentLut record
    -- Output: std_logic_vector [index] - Size from record
    function get_percent_lut_size(lut_rec : percent_lut_record_t) return std_logic_vector;
    
    -- =============================================================================
    -- LUT CREATION FUNCTIONS
    -- =============================================================================
    
    -- Create PercentLut with CRC (returns CRC value)
    -- Input: lut_data [package] - PercentLut data array
    -- Output: std_logic_vector [crc] - Calculated CRC value
    function create_percent_lut_with_crc(lut_data : percent_lut_data_array_t) return std_logic_vector;
    
    -- Create linear PercentLut data array
    -- Input: max_value [index] - Maximum value for linear scaling
    -- Output: percent_lut_data_array_t [package] - Linear PercentLut data array
    function create_linear_percent_lut(max_value : natural) return percent_lut_data_array_t;
    
    -- Create linear PercentLut record
    -- Input: max_value [index] - Maximum value for linear scaling
    -- Output: percent_lut_record_t [package] - Linear PercentLut record
    function create_linear_percent_lut_record(max_value : natural) return percent_lut_record_t;
    
    -- =============================================================================
    -- VOLTAGE CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert Moku voltage to percent index
    -- Input: voltage [volts] - Voltage value to convert
    -- Output: natural [index] - Percent index (0-100)
    function moku_voltage_to_percent_index(voltage : real) return natural;
    
    -- Convert percent index to Moku voltage
    -- Input: index [index] - Percent index (0-100)
    -- Output: real [volts] - Voltage value
    function percent_index_to_moku_voltage(index : natural) return real;
    
    -- Convert Moku bipolar voltage to percent index
    -- Input: voltage [volts] - Bipolar voltage value to convert
    -- Output: natural [index] - Percent index (0-100)
    function moku_bipolar_voltage_to_percent_index(voltage : real) return natural;
    
    -- Convert percent index to Moku bipolar voltage
    -- Input: index [index] - Percent index (0-100)
    -- Output: real [volts] - Bipolar voltage value
    function percent_index_to_moku_bipolar_voltage(index : natural) return real;
    
    -- Create Moku voltage PercentLut
    -- Input: max_voltage [volts] - Maximum voltage for scaling
    -- Output: percent_lut_data_array_t [package] - Moku voltage PercentLut data array
    function create_moku_voltage_lut(max_voltage : real) return percent_lut_data_array_t;
    
    -- Create Moku voltage PercentLut record
    -- Input: max_voltage [volts] - Maximum voltage for scaling
    -- Output: percent_lut_record_t [package] - Moku voltage PercentLut record
    function create_moku_voltage_lut_record(max_voltage : real) return percent_lut_record_t;
    
    -- Create Moku bipolar voltage PercentLut
    -- Output: percent_lut_data_array_t [package] - Moku bipolar voltage PercentLut data array
    function create_moku_bipolar_voltage_lut return percent_lut_data_array_t;
    
    -- Create Moku bipolar voltage PercentLut record
    -- Output: percent_lut_record_t [package] - Moku bipolar voltage PercentLut record
    function create_moku_bipolar_voltage_lut_record return percent_lut_record_t;
    
    -- =============================================================================
    -- ENHANCED TEST DATA GENERATION FUNCTIONS
    -- =============================================================================
    
    -- Generate test PercentLut data array with unit validation
    -- Input: test_index [index] - Test case index
    -- Output: percent_lut_data_array_t [package] - Test PercentLut data array
    function generate_test_percent_lut_data(test_index : natural) return percent_lut_data_array_t;
    
    -- Generate test PercentLut record with unit validation
    -- Input: test_index [index] - Test case index
    -- Output: percent_lut_record_t [package] - Test PercentLut record
    function generate_test_percent_lut_record(test_index : natural) return percent_lut_record_t;
    
    -- Generate test voltage for PercentLut validation
    -- Input: test_index [index] - Test case index
    -- Output: real [volts] - Test voltage value
    function generate_test_voltage(test_index : natural) return real;
    
    -- Generate test percent index for validation
    -- Input: test_index [index] - Test case index
    -- Output: natural [index] - Test percent index
    function generate_test_percent_index(test_index : natural) return natural;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Get expected units for PercentLut field
    -- Input: field_name [signal] - Name of the field
    -- Output: string - Expected units for the field
    function get_expected_units(field_name : string) return string;
    
    -- Validate units consistency for PercentLut record
    -- Input: lut_rec [package] - PercentLut record to validate
    -- Output: boolean - True if all units are consistent with expected values
    function validate_units_consistency(lut_rec : percent_lut_record_t) return boolean;
    
    -- Validate units consistency for PercentLut data array
    -- Input: lut_data [package] - PercentLut data array to validate
    -- Output: boolean - True if all units are consistent with expected values
    function validate_units_consistency_data(lut_data : percent_lut_data_array_t) return boolean;
    
    -- =============================================================================
    -- PREDEFINED LUT CONSTANTS
    -- =============================================================================
    
    -- Predefined LUT data arrays (calculated at package elaboration time)
    -- Units: package (data arrays)
    constant LINEAR_5V_LUT_DATA : percent_lut_data_array_t;  -- [package]
    constant LINEAR_3V3_LUT_DATA : percent_lut_data_array_t;  -- [package]
    constant MOKU_5V_LUT_DATA : percent_lut_data_array_t;  -- [package]
    constant MOKU_3V3_LUT_DATA : percent_lut_data_array_t;  -- [package]
    constant MOKU_BIPOLAR_LUT_DATA : percent_lut_data_array_t;  -- [package]
    
    -- Predefined LUT records (calculated at package elaboration time)
    -- Units: package (records)
    constant LINEAR_5V_LUT : percent_lut_record_t;  -- [package]
    constant LINEAR_3V3_LUT : percent_lut_record_t;  -- [package]
    constant MOKU_5V_LUT : percent_lut_record_t;  -- [package]
    constant MOKU_3V3_LUT : percent_lut_record_t;  -- [package]
    constant MOKU_BIPOLAR_LUT : percent_lut_record_t;  -- [package]

end package PercentLut_pkg_en;
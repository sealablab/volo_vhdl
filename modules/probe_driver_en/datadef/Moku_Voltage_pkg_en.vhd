--------------------------------------------------------------------------------
-- Package: Moku_Voltage_pkg_en
-- Purpose: Moku platform voltage conversion utilities for ADC/DAC interfaces (Enhanced with Unit Hints)
-- Author: johnnyc
-- Date: 2025-01-27
-- Enhanced: 2025-01-27 (Unit hinting integration)
-- 
-- DATADEF PACKAGE: This package provides voltage conversion utilities for the
-- Moku platform's 16-bit signed ADC/DAC interfaces. Enhanced with comprehensive
-- unit hinting for improved type safety and testbench validation.
-- 
-- UNIT CONVENTIONS:
-- - voltage constants: volts (voltage values)
-- - digital constants: bits (digital representation)
-- - resolution constants: volts/bit (conversion ratios)
-- - frequency constants: Hz (clock frequencies)
-- - time constants: secs (time values)
-- 
-- MOKU VOLTAGE SPECIFICATION:
-- - Digital range: -32768 to +32767 (0x8000 to 0x7FFF)
-- - Voltage range: -5.0V to +5.0V (full-scale analog input/output)
-- - Resolution: ~305 µV per digital step (10V / 65536)
-- 
-- VERILOG CONVERSION STRATEGY:
-- - All functions use standard types (signed, std_logic_vector, natural)
-- - No records or complex types in function interfaces
-- - Constants can be directly translated to Verilog parameters
-- - Function overloading uses different parameter types for clarity
-- - Unit hints are pure documentation (zero synthesis impact)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Moku_Voltage_pkg_en is
    
    -- =============================================================================
    -- MOKU VOLTAGE SYSTEM CONSTANTS
    -- =============================================================================
    
    -- Digital range constants (16-bit signed)
    -- Units: bits (digital representation)
    constant MOKU_DIGITAL_MIN : signed(15 downto 0) := to_signed(-32768, 16);  -- 0x8000
    constant MOKU_DIGITAL_MAX : signed(15 downto 0) := to_signed(32767, 16);   -- 0x7FFF
    constant MOKU_DIGITAL_ZERO : signed(15 downto 0) := to_signed(0, 16);      -- 0x0000
    
    -- Voltage range constants (real values in volts)
    -- Units: volts (voltage values)
    constant MOKU_VOLTAGE_MIN : real := -5.0;
    constant MOKU_VOLTAGE_MAX : real := 5.0;
    constant MOKU_VOLTAGE_ZERO : real := 0.0;
    
    -- Resolution and scaling constants
    -- Units: volts/bit (conversion ratios)
    constant MOKU_VOLTAGE_RESOLUTION : real := 10.0 / 65536.0;  -- ~305.18 µV per step
    constant MOKU_DIGITAL_SCALE_FACTOR : real := 32767.0 / 5.0;  -- 6553.4 digital units per volt
    
    -- Common voltage reference points (from Moku-Voltage-LUTS.md)
    -- Units: volts (voltage values)
    constant MOKU_VOLTAGE_1V : real := 1.0;
    constant MOKU_VOLTAGE_2V4 : real := 2.4;
    constant MOKU_VOLTAGE_2V5 : real := 2.5;
    constant MOKU_VOLTAGE_3V : real := 3.0;
    constant MOKU_VOLTAGE_3V3 : real := 3.3;
    constant MOKU_VOLTAGE_5V : real := 5.0;
    
    -- Corresponding digital values for common voltages
    -- Units: bits (digital representation)
    constant MOKU_DIGITAL_1V : signed(15 downto 0) := to_signed(6554, 16);    -- 0x199A
    constant MOKU_DIGITAL_2V4 : signed(15 downto 0) := to_signed(15729, 16);  -- 0x3DCF
    constant MOKU_DIGITAL_2V5 : signed(15 downto 0) := to_signed(16384, 16);  -- 0x4000
    constant MOKU_DIGITAL_3V : signed(15 downto 0) := to_signed(19661, 16);   -- 0x4CCD
    constant MOKU_DIGITAL_3V3 : signed(15 downto 0) := to_signed(21627, 16);  -- 0x54EB
    constant MOKU_DIGITAL_5V : signed(15 downto 0) := to_signed(32767, 16);   -- 0x7FFF
    
    -- Negative voltage digital values
    -- Units: bits (digital representation)
    constant MOKU_DIGITAL_NEG_1V : signed(15 downto 0) := to_signed(-6554, 16);    -- 0xE666
    constant MOKU_DIGITAL_NEG_2V4 : signed(15 downto 0) := to_signed(-15729, 16);  -- 0xC231
    constant MOKU_DIGITAL_NEG_2V5 : signed(15 downto 0) := to_signed(-16384, 16);  -- 0xC000
    constant MOKU_DIGITAL_NEG_3V : signed(15 downto 0) := to_signed(-19661, 16);   -- 0xB333
    constant MOKU_DIGITAL_NEG_3V3 : signed(15 downto 0) := to_signed(-21627, 16);  -- 0xAA85
    constant MOKU_DIGITAL_NEG_5V : signed(15 downto 0) := to_signed(-32768, 16);   -- 0x8000
    
    -- =============================================================================
    -- TYPE DEFINITIONS FOR ENHANCED FEATURES
    -- =============================================================================
    
    -- Array types for test data generation (constrained for function return types)
    -- Units: array of volts (voltage values)
    type real_vector is array (0 to 255) of real;
    
    -- Units: array of bits (digital representation)
    type signed_array is array (0 to 255) of signed(15 downto 0);
    
    -- =============================================================================
    -- VOLTAGE CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert voltage (real) to digital value (signed 16-bit)
    -- Units: input: volts (voltage) -> output: bits (digital representation)
    function voltage_to_digital(voltage : real) return signed;
    
    -- Convert digital value (signed 16-bit) to voltage (real)
    -- Units: input: bits (digital representation) -> output: volts (voltage)
    function digital_to_voltage(digital : signed(15 downto 0)) return real;
    
    -- Convert digital value (std_logic_vector) to voltage (real)
    -- Units: input: bits (digital representation) -> output: volts (voltage)
    function digital_to_voltage(digital : std_logic_vector(15 downto 0)) return real;
    
    -- Convert voltage (real) to digital value (std_logic_vector)
    -- Units: input: volts (voltage) -> output: bits (digital representation)
    function voltage_to_digital_vector(voltage : real) return std_logic_vector;
    
    -- =============================================================================
    -- TESTBENCH CONVENIENCE FUNCTIONS
    -- =============================================================================
    
    -- Check if digital value represents a specific voltage within tolerance
    -- Units: input: bits (digital), volts (expected), volts (tolerance) -> output: boolean (validity)
    function is_voltage_equal(digital : signed(15 downto 0); expected_voltage : real; tolerance_volts : real := 0.001) return boolean;
    function is_voltage_equal(digital : std_logic_vector(15 downto 0); expected_voltage : real; tolerance_volts : real := 0.001) return boolean;
    
    -- Check if digital value is within voltage range
    -- Units: input: bits (digital), volts (min), volts (max) -> output: boolean (validity)
    function is_voltage_in_range(digital : signed(15 downto 0); min_voltage : real; max_voltage : real) return boolean;
    function is_voltage_in_range(digital : std_logic_vector(15 downto 0); min_voltage : real; max_voltage : real) return boolean;
    
    -- Get voltage difference between expected and actual
    -- Units: input: bits (digital), volts (expected) -> output: volts (difference)
    function get_voltage_error(digital : signed(15 downto 0); expected_voltage : real) return real;
    function get_voltage_error(digital : std_logic_vector(15 downto 0); expected_voltage : real) return real;
    
    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================
    
    -- Check if digital value is within valid Moku range
    -- Units: input: bits (digital) -> output: boolean (validity)
    function is_valid_moku_digital(digital : signed(15 downto 0)) return boolean;
    function is_valid_moku_digital(digital : std_logic_vector(15 downto 0)) return boolean;
    
    -- Check if voltage is within valid Moku range
    -- Units: input: volts (voltage) -> output: boolean (validity)
    function is_valid_moku_voltage(voltage : real) return boolean;
    
    -- =============================================================================
    -- STRING CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert digital value to string representation
    -- Units: input: bits (digital) -> output: string (representation)
    function digital_to_string(digital : signed(15 downto 0)) return string;
    function digital_to_string(digital : std_logic_vector(15 downto 0)) return string;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS (Enhanced Features)
    -- =============================================================================
    
    -- Validate that a voltage value is within expected range
    -- Units: input: volts (voltage), volts (min), volts (max) -> output: boolean (validity)
    function validate_voltage_range(value : real; min_val : real; max_val : real) return boolean;
    
    -- Validate that a digital value is within expected range
    -- Units: input: bits (digital), bits (min), bits (max) -> output: boolean (validity)
    function validate_digital_range(value : signed(15 downto 0); min_val : signed(15 downto 0); max_val : signed(15 downto 0)) return boolean;
    
    -- =============================================================================
    -- UNIT-AWARE TEST DATA GENERATION (Enhanced Features)
    -- =============================================================================
    
    -- Generate a single test voltage value with explicit unit validation
    -- Units: input: volts (min), volts (max), index (natural) -> output: volts (voltage)
    function generate_voltage_test_value(min_voltage : real; max_voltage : real; index : natural; total_count : natural) return real;
    
    -- Generate a single test digital value with explicit unit validation
    -- Units: input: volts (min), volts (max), index (natural) -> output: bits (digital)
    function generate_digital_test_value(min_voltage : real; max_voltage : real; index : natural; total_count : natural) return signed;
    
end package Moku_Voltage_pkg_en;

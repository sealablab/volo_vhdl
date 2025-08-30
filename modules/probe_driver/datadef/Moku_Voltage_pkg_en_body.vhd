--------------------------------------------------------------------------------
-- Package Body: Moku_Voltage_pkg_en
-- Purpose: Implementation of Moku platform voltage conversion utilities (Enhanced with Unit Hints)
-- Author: johnnyc
-- Date: 2025-01-27
-- Enhanced: 2025-01-27 (Unit hinting integration)
-- 
-- This package body implements all the functions declared in Moku_Voltage_pkg_en.
-- All functions maintain unit consistency and include enhanced validation features.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package body Moku_Voltage_pkg_en is
    
    -- =============================================================================
    -- VOLTAGE CONVERSION FUNCTIONS
    -- =============================================================================
    
    -- Convert voltage (real) to digital value (signed 16-bit)
    -- Units: input: volts (voltage) -> output: bits (digital representation)
    function voltage_to_digital(voltage : real) return signed is
        variable digital_value : signed(15 downto 0);
    begin
        -- Clamp voltage to valid range
        if voltage < MOKU_VOLTAGE_MIN then
            digital_value := MOKU_DIGITAL_MIN;
        elsif voltage > MOKU_VOLTAGE_MAX then
            digital_value := MOKU_DIGITAL_MAX;
        else
            -- Convert voltage to digital using scale factor
            digital_value := to_signed(integer(voltage * MOKU_DIGITAL_SCALE_FACTOR), 16);
        end if;
        return digital_value;
    end function voltage_to_digital;
    
    -- Convert digital value (signed 16-bit) to voltage (real)
    -- Units: input: bits (digital representation) -> output: volts (voltage)
    function digital_to_voltage(digital : signed(15 downto 0)) return real is
        variable voltage_value : real;
    begin
        -- Convert digital value to voltage using resolution
        voltage_value := real(to_integer(digital)) * MOKU_VOLTAGE_RESOLUTION;
        return voltage_value;
    end function digital_to_voltage;
    
    -- Convert digital value (std_logic_vector) to voltage (real)
    -- Units: input: bits (digital representation) -> output: volts (voltage)
    function digital_to_voltage(digital : std_logic_vector(15 downto 0)) return real is
    begin
        -- Convert std_logic_vector to signed and call the signed version
        return digital_to_voltage(signed(digital));
    end function digital_to_voltage;
    
    -- Convert voltage (real) to digital value (std_logic_vector)
    -- Units: input: volts (voltage) -> output: bits (digital representation)
    function voltage_to_digital_vector(voltage : real) return std_logic_vector is
    begin
        -- Convert voltage to signed and then to std_logic_vector
        return std_logic_vector(voltage_to_digital(voltage));
    end function voltage_to_digital_vector;
    
    -- =============================================================================
    -- TESTBENCH CONVENIENCE FUNCTIONS
    -- =============================================================================
    
    -- Check if digital value represents a specific voltage within tolerance
    -- Units: input: bits (digital), volts (expected), volts (tolerance) -> output: boolean (validity)
    function is_voltage_equal(digital : signed(15 downto 0); expected_voltage : real; tolerance_volts : real := 0.001) return boolean is
        variable actual_voltage : real;
        variable voltage_diff : real;
    begin
        actual_voltage := digital_to_voltage(digital);
        voltage_diff := abs(actual_voltage - expected_voltage);
        return voltage_diff <= tolerance_volts;
    end function is_voltage_equal;
    
    function is_voltage_equal(digital : std_logic_vector(15 downto 0); expected_voltage : real; tolerance_volts : real := 0.001) return boolean is
    begin
        return is_voltage_equal(signed(digital), expected_voltage, tolerance_volts);
    end function is_voltage_equal;
    
    -- Check if digital value is within voltage range
    -- Units: input: bits (digital), volts (min), volts (max) -> output: boolean (validity)
    function is_voltage_in_range(digital : signed(15 downto 0); min_voltage : real; max_voltage : real) return boolean is
        variable actual_voltage : real;
    begin
        actual_voltage := digital_to_voltage(digital);
        return (actual_voltage >= min_voltage) and (actual_voltage <= max_voltage);
    end function is_voltage_in_range;
    
    function is_voltage_in_range(digital : std_logic_vector(15 downto 0); min_voltage : real; max_voltage : real) return boolean is
    begin
        return is_voltage_in_range(signed(digital), min_voltage, max_voltage);
    end function is_voltage_in_range;
    
    -- Get voltage difference between expected and actual
    -- Units: input: bits (digital), volts (expected) -> output: volts (difference)
    function get_voltage_error(digital : signed(15 downto 0); expected_voltage : real) return real is
        variable actual_voltage : real;
    begin
        actual_voltage := digital_to_voltage(digital);
        return actual_voltage - expected_voltage;
    end function get_voltage_error;
    
    function get_voltage_error(digital : std_logic_vector(15 downto 0); expected_voltage : real) return real is
    begin
        return get_voltage_error(signed(digital), expected_voltage);
    end function get_voltage_error;
    
    -- =============================================================================
    -- UNIT VALIDATION FUNCTIONS (Enhanced Features)
    -- =============================================================================
    
    -- Validate that a voltage value is within expected range
    -- Units: input: volts (voltage), volts (min), volts (max) -> output: boolean (validity)
    function validate_voltage_range(value : real; min_val : real; max_val : real) return boolean is
    begin
        -- Voltage should be within Moku platform range and specified range
        return (value >= MOKU_VOLTAGE_MIN) and (value <= MOKU_VOLTAGE_MAX) and
               (value >= min_val) and (value <= max_val);
    end function validate_voltage_range;
    
    -- Validate that a digital value is within expected range
    -- Units: input: bits (digital), bits (min), bits (max) -> output: boolean (validity)
    function validate_digital_range(value : signed(15 downto 0); min_val : signed(15 downto 0); max_val : signed(15 downto 0)) return boolean is
    begin
        -- Digital values should be within 16-bit signed range and specified range
        return (value >= MOKU_DIGITAL_MIN) and (value <= MOKU_DIGITAL_MAX) and
               (value >= min_val) and (value <= max_val);
    end function validate_digital_range;
    
    -- =============================================================================
    -- UNIT-AWARE TEST DATA GENERATION (Enhanced Features)
    -- =============================================================================
    
    -- Generate a single test voltage value with explicit unit validation
    -- Units: input: volts (min), volts (max), index (natural) -> output: volts (voltage)
    function generate_voltage_test_value(min_voltage : real; max_voltage : real; index : natural; total_count : natural) return real is
        variable voltage_step : real;
        variable current_voltage : real;
    begin
        -- Validate input parameters
        if not validate_voltage_range(min_voltage, MOKU_VOLTAGE_MIN, MOKU_VOLTAGE_MAX) then
            report "Invalid min_voltage: " & real'image(min_voltage) & " volts" severity error;
            return 0.0;
        end if;
        
        if not validate_voltage_range(max_voltage, MOKU_VOLTAGE_MIN, MOKU_VOLTAGE_MAX) then
            report "Invalid max_voltage: " & real'image(max_voltage) & " volts" severity error;
            return 0.0;
        end if;
        
        if min_voltage >= max_voltage then
            report "min_voltage must be less than max_voltage" severity error;
            return 0.0;
        end if;
        
        if total_count <= 1 then
            return min_voltage;
        end if;
        
        -- Generate evenly spaced voltage value
        voltage_step := (max_voltage - min_voltage) / real(total_count - 1);
        current_voltage := min_voltage + real(index) * voltage_step;
        
        return current_voltage;
    end function generate_voltage_test_value;
    
    -- Generate a single test digital value with explicit unit validation
    -- Units: input: volts (min), volts (max), index (natural) -> output: bits (digital)
    function generate_digital_test_value(min_voltage : real; max_voltage : real; index : natural; total_count : natural) return signed is
        variable voltage_value : real;
    begin
        -- Generate voltage test value first
        voltage_value := generate_voltage_test_value(min_voltage, max_voltage, index, total_count);
        
        -- Convert voltage to digital
        return voltage_to_digital(voltage_value);
    end function generate_digital_test_value;
    
end package body Moku_Voltage_pkg_en;

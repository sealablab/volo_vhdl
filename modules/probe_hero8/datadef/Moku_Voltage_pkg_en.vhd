-- =============================================================================
-- Enhanced Moku Voltage Package
-- =============================================================================
-- 
-- This enhanced package provides voltage conversion utilities for the MCC platform
-- with comprehensive validation, error handling, and unit hinting. It handles
-- voltage scaling, clamping, and conversion between different voltage representations.
--
-- UNIT CONVENTIONS:
-- - voltage values: volts (voltage output levels)
-- - digital values: bits (digital representation of voltages)
-- - scaling factors: ratio (voltage scaling ratios)
-- - signal values: signal (control and status signals)
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Moku_Voltage_pkg_en is

    -- =========================================================================
    -- System Constants with Unit Documentation
    -- =========================================================================
    constant VOLTAGE_DATA_WIDTH : natural := 16;  -- Units: bits (voltage data width)
    constant VOLTAGE_REFERENCE : real := 5.0;     -- Units: volts (reference voltage)
    constant VOLTAGE_MIN : real := -5.0;          -- Units: volts (minimum voltage)
    constant VOLTAGE_MAX : real := 5.0;           -- Units: volts (maximum voltage)
    constant DIGITAL_MAX : natural := 65535;      -- Units: count (maximum digital value)
    constant DIGITAL_MIN : natural := 0;          -- Units: count (minimum digital value)
    
    -- =========================================================================
    -- Voltage Conversion Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: voltage (volts) -> output: digital (bits)
    -- Purpose: Converts real voltage to 16-bit digital representation
    function voltage_to_digital(voltage : real) return std_logic_vector;
    
    -- Units: input: digital (bits) -> output: voltage (volts)
    -- Purpose: Converts 16-bit digital representation to real voltage
    function digital_to_voltage(digital : std_logic_vector) return real;
    
    -- Units: input: voltage (volts) -> output: voltage (volts)
    -- Purpose: Clamps voltage to safe operating range
    function clamp_voltage_safe(voltage : real) return real;
    
    -- Units: input: digital (bits) -> output: digital (bits)
    -- Purpose: Clamps digital value to valid range
    function clamp_digital_safe(digital : std_logic_vector) return std_logic_vector;
    
    -- =========================================================================
    -- Voltage Scaling Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: voltage (volts), scale_factor (ratio) -> output: voltage (volts)
    -- Purpose: Scales voltage by a factor with safety clamping
    function scale_voltage(voltage : real; scale_factor : real) return real;
    
    -- Units: input: digital (bits), scale_factor (ratio) -> output: digital (bits)
    -- Purpose: Scales digital voltage by a factor with safety clamping
    function scale_digital_voltage(digital : std_logic_vector; scale_factor : real) return std_logic_vector;
    
    -- Units: input: voltage (volts), offset (volts) -> output: voltage (volts)
    -- Purpose: Adds offset to voltage with safety clamping
    function offset_voltage(voltage : real; offset : real) return real;
    
    -- =========================================================================
    -- Validation Functions with Unit Documentation
    -- =========================================================================
    
    -- Units: input: voltage (volts) -> output: boolean (validity)
    -- Purpose: Validates that voltage is within safe operating range
    function is_voltage_safe(voltage : real) return boolean;
    
    -- Units: input: digital (bits) -> output: boolean (validity)
    -- Purpose: Validates that digital value is within valid range
    function is_digital_safe(digital : std_logic_vector) return boolean;
    
    -- Units: input: scale_factor (ratio) -> output: boolean (validity)
    -- Purpose: Validates that scale factor is reasonable
    function is_scale_factor_safe(scale_factor : real) return boolean;
    
    -- =========================================================================
    -- Safe Voltage Operations with Unit Documentation
    -- =========================================================================
    
    -- Units: input: voltage1 (volts), voltage2 (volts) -> output: voltage (volts)
    -- Purpose: Safe addition of two voltages with clamping
    function add_voltages_safe(voltage1, voltage2 : real) return real;
    
    -- Units: input: voltage1 (volts), voltage2 (volts) -> output: voltage (volts)
    -- Purpose: Safe subtraction of two voltages with clamping
    function subtract_voltages_safe(voltage1, voltage2 : real) return real;
    
    -- Units: input: voltage (volts), percentage (ratio) -> output: voltage (volts)
    -- Purpose: Applies percentage scaling to voltage with safety checks
    function apply_percentage_voltage(voltage : real; percentage : real) return real;
    
    -- =========================================================================
    -- Default Voltage Constants
    -- =========================================================================
    
    -- Default voltage values (Units: volts)
    constant DEFAULT_VOLTAGE_ZERO : real := 0.0;
    constant DEFAULT_VOLTAGE_MIN : real := VOLTAGE_MIN;
    constant DEFAULT_VOLTAGE_MAX : real := VOLTAGE_MAX;
    
    -- Default digital values (Units: bits)
    constant DEFAULT_DIGITAL_ZERO : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0) := (others => '0');
    constant DEFAULT_DIGITAL_MAX : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0) := (others => '1');
    constant DEFAULT_DIGITAL_MID : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0) := x"8000";

end package Moku_Voltage_pkg_en;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body Moku_Voltage_pkg_en is

    -- =========================================================================
    -- Voltage Conversion Function Implementations
    -- =========================================================================
    
    function voltage_to_digital(voltage : real) return std_logic_vector is
        variable clamped_voltage : real;
        variable digital_value : natural;
        variable result : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);
    begin
        -- Clamp voltage to safe range
        clamped_voltage := clamp_voltage_safe(voltage);
        
        -- Convert to digital (assuming 16-bit signed representation)
        -- Map -5V to 0, +5V to 65535
        digital_value := natural((clamped_voltage - VOLTAGE_MIN) * real(DIGITAL_MAX) / (VOLTAGE_MAX - VOLTAGE_MIN));
        
        -- Ensure within bounds
        if digital_value > DIGITAL_MAX then
            digital_value := DIGITAL_MAX;
        end if;
        
        result := std_logic_vector(to_unsigned(digital_value, VOLTAGE_DATA_WIDTH));
        return result;
    end function;
    
    function digital_to_voltage(digital : std_logic_vector) return real is
        variable digital_value : natural;
        variable voltage : real;
    begin
        -- Convert digital to natural
        digital_value := to_integer(unsigned(digital));
        
        -- Convert to voltage
        voltage := VOLTAGE_MIN + real(digital_value) * (VOLTAGE_MAX - VOLTAGE_MIN) / real(DIGITAL_MAX);
        
        -- Clamp to safe range
        voltage := clamp_voltage_safe(voltage);
        
        return voltage;
    end function;
    
    function clamp_voltage_safe(voltage : real) return real is
        variable clamped_voltage : real;
    begin
        if voltage < VOLTAGE_MIN then
            clamped_voltage := VOLTAGE_MIN;
        elsif voltage > VOLTAGE_MAX then
            clamped_voltage := VOLTAGE_MAX;
        else
            clamped_voltage := voltage;
        end if;
        return clamped_voltage;
    end function;
    
    function clamp_digital_safe(digital : std_logic_vector) return std_logic_vector is
        variable clamped_digital : std_logic_vector(digital'range);
        variable digital_value : natural;
    begin
        digital_value := to_integer(unsigned(digital));
        
        if digital_value < DIGITAL_MIN then
            clamped_digital := std_logic_vector(to_unsigned(DIGITAL_MIN, digital'length));
        elsif digital_value > DIGITAL_MAX then
            clamped_digital := std_logic_vector(to_unsigned(DIGITAL_MAX, digital'length));
        else
            clamped_digital := digital;
        end if;
        
        return clamped_digital;
    end function;
    
    -- =========================================================================
    -- Voltage Scaling Function Implementations
    -- =========================================================================
    
    function scale_voltage(voltage : real; scale_factor : real) return real is
        variable scaled_voltage : real;
    begin
        -- Validate scale factor
        if not is_scale_factor_safe(scale_factor) then
            return voltage; -- Return original if scale factor is invalid
        end if;
        
        -- Apply scaling
        scaled_voltage := voltage * scale_factor;
        
        -- Clamp to safe range
        scaled_voltage := clamp_voltage_safe(scaled_voltage);
        
        return scaled_voltage;
    end function;
    
    function scale_digital_voltage(digital : std_logic_vector; scale_factor : real) return std_logic_vector is
        variable voltage : real;
        variable scaled_voltage : real;
    begin
        -- Convert to voltage, scale, and convert back
        voltage := digital_to_voltage(digital);
        scaled_voltage := scale_voltage(voltage, scale_factor);
        return voltage_to_digital(scaled_voltage);
    end function;
    
    function offset_voltage(voltage : real; offset : real) return real is
        variable offset_voltage : real;
    begin
        offset_voltage := voltage + offset;
        return clamp_voltage_safe(offset_voltage);
    end function;
    
    -- =========================================================================
    -- Validation Function Implementations
    -- =========================================================================
    
    function is_voltage_safe(voltage : real) return boolean is
    begin
        return (voltage >= VOLTAGE_MIN) and (voltage <= VOLTAGE_MAX);
    end function;
    
    function is_digital_safe(digital : std_logic_vector) return boolean is
        variable digital_value : natural;
    begin
        digital_value := to_integer(unsigned(digital));
        return (digital_value >= DIGITAL_MIN) and (digital_value <= DIGITAL_MAX);
    end function;
    
    function is_scale_factor_safe(scale_factor : real) return boolean is
    begin
        -- Reasonable scale factor range: 0.1 to 10.0
        return (scale_factor >= 0.1) and (scale_factor <= 10.0);
    end function;
    
    -- =========================================================================
    -- Safe Voltage Operation Implementations
    -- =========================================================================
    
    function add_voltages_safe(voltage1, voltage2 : real) return real is
        variable sum_voltage : real;
    begin
        sum_voltage := voltage1 + voltage2;
        return clamp_voltage_safe(sum_voltage);
    end function;
    
    function subtract_voltages_safe(voltage1, voltage2 : real) return real is
        variable diff_voltage : real;
    begin
        diff_voltage := voltage1 - voltage2;
        return clamp_voltage_safe(diff_voltage);
    end function;
    
    function apply_percentage_voltage(voltage : real; percentage : real) return real is
        variable scaled_voltage : real;
    begin
        -- Convert percentage to scale factor (0-100% -> 0.0-1.0)
        scaled_voltage := voltage * (percentage / 100.0);
        return clamp_voltage_safe(scaled_voltage);
    end function;

end package body Moku_Voltage_pkg_en;
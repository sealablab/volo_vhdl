--------------------------------------------------------------------------------
-- Package: Moku_Pct_pkg
-- Purpose: Type-safe percentage-to-voltage conversion for common voltage ranges
-- Author: johnnyc
-- Date: 2025-10-22
--
-- DATADEF PACKAGE: This package provides type-safe percentage (0-100) to voltage
-- conversions for common voltage ranges used in Moku platform applications.
-- Integrates tightly with Moku_Voltage_pkg for actual conversion logic.
--
-- DESIGN PHILOSOPHY:
-- - Each voltage range gets its own distinct subtype for compile-time type safety
-- - 0% = range minimum, 100% = range maximum
-- - Linear scaling (50% = midpoint of range)
-- - Prevents accidental mixing of incompatible ranges at compile time
--
-- SUPPORTED RANGES:
-- - pct_5v0_t:  0V to +5.0V (unipolar, full Moku range)
-- - pct_3v3_t:  0V to +3.3V (common logic level)
-- - pct_2v5_t:  0V to +2.5V (common reference voltage)
-- - pct_bipolar_5v_t:  -5.0V to +5.0V (bipolar, full Moku range)
-- - pct_bipolar_2v5_t: -2.5V to +2.5V (bipolar, centered)
--
-- USAGE EXAMPLE:
--   signal probe_level : pct_3v3_t := 50;  -- 50% of 3.3V = 1.65V
--   dac_out <= pct_3v3_to_digital(probe_level);
--
-- TYPE SAFETY:
--   signal level_3v3 : pct_3v3_t := 50;
--   signal level_5v0 : pct_5v0_t := 75;
--
--   -- This works:
--   dac_out <= pct_3v3_to_digital(level_3v3);
--
--   -- This FAILS at compile time (type mismatch):
--   dac_out <= pct_5v0_to_digital(level_3v3);  -- ERROR!
--
--   -- Explicit conversion required for advanced users:
--   level_5v0 <= pct_5v0_t(level_3v3);  -- Allowed but explicit
--
-- VERILOG CONVERSION STRATEGY:
-- - Subtypes → simple integer ranges in Verilog
-- - Functions → Verilog functions or inline expressions
-- - Type safety → rely on naming conventions (type checking lost in Verilog)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import Moku_Voltage_pkg for voltage conversion
use work.Moku_Voltage_pkg.all;

package Moku_Pct_pkg is

    -- =============================================================================
    -- TYPE-SAFE PERCENTAGE TYPES (0-100)
    -- =============================================================================
    -- Each range gets its own subtype - compiler prevents mixing incompatible ranges

    -- Unipolar ranges (0V to +Vmax)
    subtype pct_5v0_t is natural range 0 to 100;   -- 0V to +5.0V (full Moku range)
    subtype pct_3v3_t is natural range 0 to 100;   -- 0V to +3.3V (common logic level)
    subtype pct_2v5_t is natural range 0 to 100;   -- 0V to +2.5V (common reference)

    -- Bipolar ranges (-Vmax to +Vmax)
    subtype pct_bipolar_5v_t is natural range 0 to 100;   -- -5.0V to +5.0V (full range)
    subtype pct_bipolar_2v5_t is natural range 0 to 100;  -- -2.5V to +2.5V (centered)

    -- =============================================================================
    -- PERCENTAGE TO DIGITAL CONVERSION FUNCTIONS
    -- =============================================================================
    -- Convert percentage (0-100) to Moku digital code (signed 16-bit)
    -- 0% = range minimum, 100% = range maximum

    -- Unipolar conversions
    function pct_5v0_to_digital(pct : pct_5v0_t) return signed;
    function pct_3v3_to_digital(pct : pct_3v3_t) return signed;
    function pct_2v5_to_digital(pct : pct_2v5_t) return signed;

    -- Bipolar conversions
    function pct_bipolar_5v_to_digital(pct : pct_bipolar_5v_t) return signed;
    function pct_bipolar_2v5_to_digital(pct : pct_bipolar_2v5_t) return signed;

    -- =============================================================================
    -- DIGITAL TO PERCENTAGE CONVERSION FUNCTIONS (REVERSE)
    -- =============================================================================
    -- Convert Moku digital code back to percentage (0-100)
    -- Useful for readback, monitoring, and validation

    -- Unipolar reverse conversions
    function digital_to_pct_5v0(digital : signed(15 downto 0)) return pct_5v0_t;
    function digital_to_pct_3v3(digital : signed(15 downto 0)) return pct_3v3_t;
    function digital_to_pct_2v5(digital : signed(15 downto 0)) return pct_2v5_t;

    -- Bipolar reverse conversions
    function digital_to_pct_bipolar_5v(digital : signed(15 downto 0)) return pct_bipolar_5v_t;
    function digital_to_pct_bipolar_2v5(digital : signed(15 downto 0)) return pct_bipolar_2v5_t;

    -- =============================================================================
    -- ESCAPE HATCHES FOR ADVANCED USERS
    -- =============================================================================
    -- These functions allow explicit conversion to/from std_logic_vector
    -- for cases where type safety needs to be bypassed

    -- Convert percentage (natural) to 7-bit std_logic_vector
    function pct_to_slv(pct : natural range 0 to 100) return std_logic_vector;

    -- Convert 7-bit std_logic_vector to percentage (natural)
    function slv_to_pct(slv : std_logic_vector(6 downto 0)) return natural;

    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================

    -- Check if percentage is valid (0-100)
    function is_valid_pct(pct : natural) return boolean;

    -- Clamp percentage to valid range (0-100)
    function clamp_pct(pct : natural) return natural;

end package Moku_Pct_pkg;

package body Moku_Pct_pkg is

    -- =============================================================================
    -- PERCENTAGE TO DIGITAL CONVERSION FUNCTIONS
    -- =============================================================================

    -- Unipolar: 0V to +5.0V
    function pct_5v0_to_digital(pct : pct_5v0_t) return signed is
        variable voltage : real;
    begin
        voltage := real(pct) * 0.05;  -- 0.05 = 5.0V / 100
        return voltage_to_digital(voltage);
    end function;

    -- Unipolar: 0V to +3.3V
    function pct_3v3_to_digital(pct : pct_3v3_t) return signed is
        variable voltage : real;
    begin
        voltage := real(pct) * 0.033;  -- 0.033 = 3.3V / 100
        return voltage_to_digital(voltage);
    end function;

    -- Unipolar: 0V to +2.5V
    function pct_2v5_to_digital(pct : pct_2v5_t) return signed is
        variable voltage : real;
    begin
        voltage := real(pct) * 0.025;  -- 0.025 = 2.5V / 100
        return voltage_to_digital(voltage);
    end function;

    -- Bipolar: -5.0V to +5.0V
    function pct_bipolar_5v_to_digital(pct : pct_bipolar_5v_t) return signed is
        variable voltage : real;
    begin
        voltage := -5.0 + (real(pct) * 0.1);  -- 0.1 = 10.0V / 100 (span is 10V)
        return voltage_to_digital(voltage);
    end function;

    -- Bipolar: -2.5V to +2.5V
    function pct_bipolar_2v5_to_digital(pct : pct_bipolar_2v5_t) return signed is
        variable voltage : real;
    begin
        voltage := -2.5 + (real(pct) * 0.05);  -- 0.05 = 5.0V / 100 (span is 5V)
        return voltage_to_digital(voltage);
    end function;

    -- =============================================================================
    -- DIGITAL TO PERCENTAGE CONVERSION FUNCTIONS (REVERSE)
    -- =============================================================================

    -- Reverse: digital → voltage → percentage for 0V to +5.0V
    function digital_to_pct_5v0(digital : signed(15 downto 0)) return pct_5v0_t is
        variable voltage : real;
        variable pct : integer;
    begin
        voltage := digital_to_voltage(digital);
        pct := integer(voltage / 0.05 + 0.5);  -- Round to nearest
        return clamp_pct(pct);
    end function;

    -- Reverse: digital → voltage → percentage for 0V to +3.3V
    function digital_to_pct_3v3(digital : signed(15 downto 0)) return pct_3v3_t is
        variable voltage : real;
        variable pct : integer;
    begin
        voltage := digital_to_voltage(digital);
        pct := integer(voltage / 0.033 + 0.5);  -- Round to nearest
        return clamp_pct(pct);
    end function;

    -- Reverse: digital → voltage → percentage for 0V to +2.5V
    function digital_to_pct_2v5(digital : signed(15 downto 0)) return pct_2v5_t is
        variable voltage : real;
        variable pct : integer;
    begin
        voltage := digital_to_voltage(digital);
        pct := integer(voltage / 0.025 + 0.5);  -- Round to nearest
        return clamp_pct(pct);
    end function;

    -- Reverse: digital → voltage → percentage for -5.0V to +5.0V
    function digital_to_pct_bipolar_5v(digital : signed(15 downto 0)) return pct_bipolar_5v_t is
        variable voltage : real;
        variable pct : integer;
    begin
        voltage := digital_to_voltage(digital);
        pct := integer((voltage + 5.0) / 0.1 + 0.5);  -- Round to nearest
        return clamp_pct(pct);
    end function;

    -- Reverse: digital → voltage → percentage for -2.5V to +2.5V
    function digital_to_pct_bipolar_2v5(digital : signed(15 downto 0)) return pct_bipolar_2v5_t is
        variable voltage : real;
        variable pct : integer;
    begin
        voltage := digital_to_voltage(digital);
        pct := integer((voltage + 2.5) / 0.05 + 0.5);  -- Round to nearest
        return clamp_pct(pct);
    end function;

    -- =============================================================================
    -- ESCAPE HATCHES FOR ADVANCED USERS
    -- =============================================================================

    function pct_to_slv(pct : natural range 0 to 100) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(pct, 7));
    end function;

    function slv_to_pct(slv : std_logic_vector(6 downto 0)) return natural is
        variable pct : natural;
    begin
        pct := to_integer(unsigned(slv));
        return clamp_pct(pct);
    end function;

    -- =============================================================================
    -- VALIDATION FUNCTIONS
    -- =============================================================================

    function is_valid_pct(pct : natural) return boolean is
    begin
        return (pct >= 0) and (pct <= 100);
    end function;

    function clamp_pct(pct : natural) return natural is
    begin
        if pct > 100 then
            return 100;
        elsif pct < 0 then
            return 0;
        else
            return pct;
        end if;
    end function;

end package body Moku_Pct_pkg;

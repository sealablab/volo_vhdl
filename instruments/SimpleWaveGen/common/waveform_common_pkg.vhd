-- waveform_common_pkg.vhd
-- Shared Waveform Components Package
-- Contains common waveform generation components that can be reused
-- across different waveform generator modules

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

package waveform_common_pkg is
    
    -- ============================================================================
    -- SINE LOOKUP TABLE
    -- ============================================================================
    
    -- 128-point sine lookup table covering 0° to 360°
    -- Values are 16-bit signed integers representing sin(θ) * 32767
    type sine_lut_type is array (0 to 127) of std_logic_vector(15 downto 0);
    constant SINE_LUT_128 : sine_lut_type := (
        x"0000", x"0324", x"0647", x"096A", x"0C8B", x"0FAB", x"12C8", x"15E2",
        x"18F8", x"1C0B", x"1F19", x"2223", x"2528", x"2826", x"2B1F", x"2E11",
        x"30FB", x"33DE", x"36BA", x"398C", x"3C56", x"3F17", x"41CE", x"447A",
        x"471C", x"49B4", x"4C3F", x"4EBF", x"5133", x"539B", x"55F5", x"5842",
        x"5A82", x"5CB4", x"5ED7", x"60EC", x"62F2", x"64E8", x"66CF", x"68A6",
        x"6A6D", x"6C24", x"6DCA", x"6F5F", x"70E2", x"7254", x"73B5", x"7504",
        x"7641", x"776C", x"7884", x"798A", x"7A7D", x"7B5D", x"7C29", x"7CE2",
        x"7D89", x"7E1C", x"7E9C", x"7F09", x"7F62", x"7FA7", x"7FD8", x"7FF6",
        x"7FFF", x"7FF6", x"7FD8", x"7FA7", x"7F62", x"7F09", x"7E9C", x"7E1C",
        x"7D89", x"7CE2", x"7C29", x"7B5D", x"7A7D", x"798A", x"7884", x"776C",
        x"7641", x"7504", x"73B5", x"7254", x"70E2", x"6F5F", x"6DCA", x"6C24",
        x"6A6D", x"68A6", x"66CF", x"64E8", x"62F2", x"60EC", x"5ED7", x"5CB4",
        x"5A82", x"5842", x"55F5", x"539B", x"5133", x"4EBF", x"4C3F", x"49B4",
        x"471C", x"447A", x"41CE", x"3F17", x"3C56", x"398C", x"36BA", x"33DE",
        x"30FB", x"2E11", x"2B1F", x"2826", x"2528", x"2223", x"1F19", x"1C0B",
        x"18F8", x"15E2", x"12C8", x"0FAB", x"0C8B", x"096A", x"0647", x"0324"
    );
    
    -- ============================================================================
    -- WAVEFORM UTILITY FUNCTIONS
    -- ============================================================================
    
    -- Get sine value from lookup table
    -- phase: 7-bit phase value (0-127)
    -- Returns: 16-bit signed sine value
    function get_sine_value(phase : unsigned(6 downto 0)) return std_logic_vector;
    
    -- Increment phase counter with wraparound
    -- current_phase: current 7-bit phase value
    -- Returns: next phase value (wraps from 127 to 0)
    function next_sine_phase(current_phase : unsigned(6 downto 0)) return unsigned;
    
end package waveform_common_pkg;

-- ============================================================================
-- PACKAGE BODY
-- ============================================================================

package body waveform_common_pkg is
    
    -- Get sine value from lookup table
    function get_sine_value(phase : unsigned(6 downto 0)) return std_logic_vector is
    begin
        return SINE_LUT_128(to_integer(phase));
    end function get_sine_value;
    
    -- Increment phase counter with wraparound
    function next_sine_phase(current_phase : unsigned(6 downto 0)) return unsigned is
    begin
        if current_phase >= 127 then
            return to_unsigned(0, 7); -- Wrap to 0
        else
            return current_phase + 1;
        end if;
    end function next_sine_phase;
    
end package body waveform_common_pkg;

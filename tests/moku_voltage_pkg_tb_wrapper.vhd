--------------------------------------------------------------------------------
-- Simple Testbench Wrapper for Moku_Voltage_pkg (CocotB)
-- Purpose: Expose package constants for basic validation testing
-- Author: Claude Code
-- Date: 2025-10-22
--
-- Note: This is a lightweight wrapper since Moku_Voltage_pkg is thoroughly
--       tested through test_moku_pct_pkg.py. We only validate constants here.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import Moku_Voltage_pkg for testing
use work.Moku_Voltage_pkg.all;

entity moku_voltage_pkg_tb_wrapper is
    port (
        -- Expose package constants as output ports for verification
        const_digital_1v      : out signed(15 downto 0);
        const_digital_2v5     : out signed(15 downto 0);
        const_digital_3v3     : out signed(15 downto 0);
        const_digital_5v      : out signed(15 downto 0);
        const_digital_neg_1v  : out signed(15 downto 0);
        const_digital_neg_2v5 : out signed(15 downto 0);
        const_digital_zero    : out signed(15 downto 0);

        -- Simple passthrough for basic sanity check
        test_digital_passthrough : in signed(15 downto 0) := (others => '0');
        test_digital_result      : out signed(15 downto 0)
    );
end entity moku_voltage_pkg_tb_wrapper;

architecture simple of moku_voltage_pkg_tb_wrapper is
begin
    -- Expose constants from package
    const_digital_1v      <= MOKU_DIGITAL_1V;
    const_digital_2v5     <= MOKU_DIGITAL_2V5;
    const_digital_3v3     <= MOKU_DIGITAL_3V3;
    const_digital_5v      <= MOKU_DIGITAL_5V;
    const_digital_neg_1v  <= MOKU_DIGITAL_NEG_1V;
    const_digital_neg_2v5 <= MOKU_DIGITAL_NEG_2V5;
    const_digital_zero    <= MOKU_DIGITAL_ZERO;

    -- Simple passthrough (just verify signals work)
    test_digital_result <= test_digital_passthrough;

end architecture simple;

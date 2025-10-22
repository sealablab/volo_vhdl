--------------------------------------------------------------------------------
-- Test Wrapper for Moku_Pct_pkg
-- Purpose: Provides entity for CocotB testing of Moku_Pct_pkg functions
-- Author: Claude Code
-- Date: 2025-10-22
--
-- This wrapper is a minimal entity that allows CocotB to instantiate
-- and test the Moku_Pct_pkg package functions. Since the package contains
-- only functions (no sequential logic), this wrapper is purely for test
-- infrastructure - the actual tests verify the mathematical conversions.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Moku_Voltage_pkg.all;
use work.Moku_Pct_pkg.all;

entity moku_pct_pkg_tb_wrapper is
    port (
        -- Dummy signals for CocotB (package functions are tested in Python)
        dummy_in  : in  std_logic;
        dummy_out : out std_logic
    );
end entity moku_pct_pkg_tb_wrapper;

architecture rtl of moku_pct_pkg_tb_wrapper is
begin
    -- Pass-through (no actual logic needed - tests are in Python)
    dummy_out <= dummy_in;
end architecture rtl;

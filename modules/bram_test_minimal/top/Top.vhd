--------------------------------------------------------------------------------
-- Minimal BRAM Test - CustomWrapper Top Level
--
-- Description:
--   Ultra-simple BRAM test for debugging synthesis issues.
--   Writes incrementing pattern, reads it back.
--
-- Control Register Map:
--   Control0[31] = MCC_READY
--   Control0[30] = Enable
--   Control0[29] = ClkEn
--   Control0[7:0] = num_words (how many to test, default 16)
--
-- Output Mapping:
--   OutputA: Data read from BRAM (16-bit)
--   OutputB: Status [15:12]=state, [11:8]=num_words, [7:0]=address
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture bram_test_minimal of CustomWrapper is

    -- Control signals
    signal mcc_ready     : std_logic;
    signal user_enable   : std_logic;
    signal clk_enable    : std_logic;
    signal global_enable : std_logic;

    -- Configuration
    signal num_words : unsigned(7 downto 0);

    -- Core outputs
    signal data_out : signed(15 downto 0);
    signal status   : std_logic_vector(15 downto 0);

    signal n_reset : std_logic;

begin

    -- ========================================================================
    -- Control Signal Extraction
    -- ========================================================================
    mcc_ready     <= Control0(31);
    user_enable   <= Control0(30);
    clk_enable    <= Control0(29);

    global_enable <= mcc_ready and user_enable and clk_enable;

    n_reset <= not Reset;

    -- ========================================================================
    -- Configuration Extraction
    -- ========================================================================
    num_words <= unsigned(Control0(7 downto 0));

    -- ========================================================================
    -- BRAM Test Core Instance
    -- ========================================================================
    U_CORE: entity WORK.bram_test_core
        port map (
            clk      => Clk,
            n_reset  => n_reset,
            enable   => global_enable,
            num_words => num_words,
            data_out => data_out,
            status   => status
        );

    -- ========================================================================
    -- Output Mapping
    -- ========================================================================
    OutputA <= data_out;      -- Data from BRAM
    OutputB <= signed(status); -- Debug status
    OutputC <= (others => '0');
    OutputD <= (others => '0');

end architecture bram_test_minimal;

--------------------------------------------------------------------------------
-- Waveform Generator Core - PulseStar I/Q Signal Generator
--
-- Description:
--   Generates synchronized sine and cosine waveforms with configurable frequency.
--   Uses clk_divider_core from volo_common for frequency control and waveform
--   LUT for high-quality I/Q signals.
--
-- Features:
--   - Frequency control via division ratio (0-511)
--   - Phase accumulator with 8-bit index into 256-point LUT
--   - I/Q outputs (sine and cosine, 90° phase relationship)
--   - Synchronous reset and enable control
--
-- Inputs:
--   clk         : System clock (125 MHz)
--   n_reset     : Active-low reset
--   enable      : Functional enable (0=parked, 1=running)
--   clk_en      : Clock enable (0=frozen, 1=running)
--   freq_div    : Frequency divider (0=÷1, 1=÷2, ..., 511=÷512)
--
-- Outputs:
--   i_out       : In-phase output (sine wave, signed 16-bit)
--   q_out       : Quadrature output (cosine wave, signed 16-bit)
--
-- Tier: 1 (Strict RTL - Verilog portable core logic)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Use waveform LUT from datadef layer
use WORK.waveform_lut_pkg.all;

entity waveform_gen_core is
    port (
        -- Clock and Control
        clk         : in  std_logic;
        n_reset     : in  std_logic;
        enable      : in  std_logic;
        clk_en      : in  std_logic;

        -- Configuration
        freq_div    : in  std_logic_vector(7 downto 0);  -- 0-255 division ratio

        -- I/Q Outputs
        i_out       : out signed(15 downto 0);  -- Sine (I channel)
        q_out       : out signed(15 downto 0)   -- Cosine (Q channel)
    );
end entity waveform_gen_core;

architecture rtl of waveform_gen_core is

    -- Clock divider signals
    signal divided_clk_en : std_logic;
    signal div_status     : std_logic_vector(7 downto 0);

    -- Phase accumulator (8-bit for 256-point LUT)
    signal phase_accum : unsigned(7 downto 0);

begin

    -- ========================================================================
    -- Frequency Control: Clock Divider from volo_common
    -- ========================================================================
    U_CLK_DIV: entity WORK.clk_divider_core
        generic map (
            MAX_DIV => 512  -- Support division up to 512
        )
        port map (
            clk         => clk,
            rst_n       => n_reset,
            enable      => enable,
            div_sel     => freq_div,
            clk_en      => divided_clk_en,
            stat_reg    => div_status
        );

    -- ========================================================================
    -- Phase Accumulator: Increments at divided clock rate
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            phase_accum <= (others => '0');

        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then
                    if divided_clk_en = '1' then
                        -- Increment phase on divided clock enable
                        phase_accum <= phase_accum + 1;
                    end if;
                else
                    -- Disabled: reset to start of waveform
                    phase_accum <= (others => '0');
                end if;
            end if;
            -- clk_en='0': phase held frozen
        end if;
    end process;

    -- ========================================================================
    -- Waveform Output: LUT Lookup
    -- ========================================================================
    i_out <= SINE_LUT(to_integer(phase_accum));      -- I channel (0° reference)
    q_out <= COSINE_LUT(to_integer(phase_accum));    -- Q channel (90° offset)

end architecture rtl;

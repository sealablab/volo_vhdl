--------------------------------------------------------------------------------
-- Trigger Pulse Generator - PulseStar Synchronization Pulses
--
-- Description:
--   Generates periodic trigger pulses with configurable interval and width.
--   Used for synchronizing external instruments and marking waveform cycles.
--
-- Features:
--   - Configurable pulse interval (clock cycles between pulses)
--   - Configurable pulse width (clock cycles per pulse)
--   - Clean pulse generation with no glitches
--   - Synchronous reset and enable control
--
-- Inputs:
--   clk             : System clock (125 MHz)
--   n_reset         : Active-low reset
--   enable          : Functional enable (0=idle, 1=running)
--   clk_en          : Clock enable (0=frozen, 1=running)
--   pulse_interval  : Clock cycles between pulses (16-bit, 1-65535)
--   pulse_width     : Clock cycles per pulse (8-bit, 1-255)
--
-- Outputs:
--   trigger_out     : Trigger pulse output (signed 16-bit for CustomWrapper)
--                     High (0x7FFF) during pulse, Low (0x0000) otherwise
--
-- Tier: 1 (Strict RTL - Verilog portable core logic)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity trigger_gen_core is
    port (
        -- Clock and Control
        clk             : in  std_logic;
        n_reset         : in  std_logic;
        enable          : in  std_logic;
        clk_en          : in  std_logic;

        -- Configuration
        pulse_interval  : in  std_logic_vector(15 downto 0);  -- Cycles between pulses
        pulse_width     : in  std_logic_vector(7 downto 0);   -- Cycles per pulse

        -- Output
        trigger_out     : out signed(15 downto 0)
    );
end entity trigger_gen_core;

architecture rtl of trigger_gen_core is

    -- Interval counter (counts up to pulse_interval)
    signal interval_count : unsigned(15 downto 0);

    -- Pulse width counter (counts pulse duration)
    signal width_count : unsigned(7 downto 0);

    -- Pulse active flag
    signal pulse_active : std_logic;

begin

    -- ========================================================================
    -- Trigger Pulse Generator FSM
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            interval_count <= (others => '0');
            width_count    <= (others => '0');
            pulse_active   <= '0';

        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then

                    if pulse_active = '1' then
                        -- Currently in pulse: count pulse width
                        if width_count < unsigned(pulse_width) - 1 then
                            width_count <= width_count + 1;
                        else
                            -- Pulse complete, return to interval counting
                            pulse_active   <= '0';
                            width_count    <= (others => '0');
                            interval_count <= (others => '0');
                        end if;

                    else
                        -- Counting interval between pulses
                        if interval_count < unsigned(pulse_interval) - 1 then
                            interval_count <= interval_count + 1;
                        else
                            -- Interval complete, start pulse
                            pulse_active   <= '1';
                            width_count    <= (others => '0');
                        end if;
                    end if;

                else
                    -- Disabled: reset counters
                    interval_count <= (others => '0');
                    width_count    <= (others => '0');
                    pulse_active   <= '0';
                end if;
            end if;
            -- clk_en='0': all counters frozen
        end if;
    end process;

    -- ========================================================================
    -- Output Mapping: Convert pulse flag to signed output
    -- ========================================================================
    trigger_out <= X"7FFF" when pulse_active = '1' else X"0000";

end architecture rtl;

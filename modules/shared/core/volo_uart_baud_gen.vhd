--------------------------------------------------------------------------------
-- Entity: uart_baud_gen
-- Filename: volo_uart_baud_gen.vhd
-- Purpose: Configurable baud rate generator for UART communication
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Generates a single-cycle tick signal at the configured baud rate.
--   Used by UART TX/RX modules to time bit transmissions.
--
-- Features:
--   - Generic or runtime configurable divider ratio
--   - Single-cycle tick output (not a divided clock)
--   - Enable input for freezing/unfreezing
--   - Active-low reset
--   - Clean, simple counter-based design
--
-- Timing:
--   - Divider value = Clk_Freq / Baud_Rate
--   - Example: 125 MHz / 115200 = 1085
--   - Tick goes high for 1 clock cycle every 'divider' clocks
--
-- Usage Example:
--   For 115200 baud @ 125 MHz:
--     DIV_VALUE = 1085
--     Tick output = 115207 Hz (0.006% error)
--
-- Students: Notice how we use a counter and comparator instead of dividing
-- the clock itself! This is safer for timing closure and easier to verify.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.uart_pkg.all;

entity uart_baud_gen is
    generic (
        -- Maximum divider value (determines counter width)
        -- For 125 MHz → 9600 baud, need ~13021, so 16 bits is safe
        MAX_DIVIDER : natural := 65535  -- 16-bit counter (2^16 - 1)
    );
    port (
        -- Clock and control
        clk         : in  std_logic;                     -- System clock
        rst_n       : in  std_logic;                     -- Active-low reset
        enable      : in  std_logic;                     -- Enable (freeze counter when low)

        -- Configuration
        div_value   : in  std_logic_vector(15 downto 0); -- Baud rate divider (1 to MAX_DIVIDER)

        -- Output
        baud_tick   : out std_logic;                     -- Single-cycle tick at baud rate

        -- Status (optional, for debugging)
        stat_reg    : out std_logic_vector(15 downto 0)  -- Current counter value
    );
end entity uart_baud_gen;

architecture rtl of uart_baud_gen is

    -- Internal signals
    signal counter      : unsigned(15 downto 0);  -- Baud rate counter
    signal div_unsigned : unsigned(15 downto 0);  -- Divider as unsigned
    signal tick_int     : std_logic;               -- Internal tick signal

begin

    -- Convert divider input to unsigned for comparison
    div_unsigned <= unsigned(div_value);

    -- Baud rate generation process
    -- Students: This is a classic "rate divider" pattern!
    baud_gen_proc: process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Reset: Clear counter and tick
            counter  <= (others => '0');
            tick_int <= '0';

        elsif rising_edge(clk) then
            if enable = '1' then
                -- Check if we've reached the divider value
                if counter >= (div_unsigned - 1) then
                    -- Generate tick and reset counter
                    tick_int <= '1';
                    counter  <= (others => '0');
                else
                    -- Increment counter
                    tick_int <= '0';
                    counter  <= counter + 1;
                end if;
            else
                -- Enable low: freeze counter, no ticks
                tick_int <= '0';
                -- Counter holds its value
            end if;
        end if;
    end process baud_gen_proc;

    -- Output assignments
    baud_tick <= tick_int;
    stat_reg  <= std_logic_vector(counter);

    -- =========================================================================
    -- ASSERTIONS (Simulation only)
    -- =========================================================================

    -- synthesis translate_off
    assert_div_nonzero: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' and div_unsigned = 0 then
                report "uart_baud_gen: ERROR - div_value must not be zero!" severity error;
            end if;
        end if;
    end process assert_div_nonzero;

    assert_div_range: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' and div_unsigned > MAX_DIVIDER then
                report "uart_baud_gen: WARNING - div_value exceeds MAX_DIVIDER!" severity warning;
            end if;
        end if;
    end process assert_div_range;
    -- synthesis translate_on

end architecture rtl;

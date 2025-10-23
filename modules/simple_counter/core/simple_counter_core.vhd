--------------------------------------------------------------------------------
-- Simple Counter Core
--
-- Description:
--   16-bit counter module for Bench Framework Phase 1 Proof of Concept.
--   Increments every clock cycle when enabled. Predictable output for testing.
--
-- Features:
--   - 16-bit unsigned counter
--   - Synchronous reset (active-low)
--   - Clock enable support
--   - Functional enable control
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity simple_counter_core is
    port (
        -- Clock and Control
        clk       : in  std_logic;
        n_reset   : in  std_logic;
        clk_en    : in  std_logic;
        enable    : in  std_logic;

        -- Output
        count_out : out std_logic_vector(15 downto 0)
    );
end entity simple_counter_core;

architecture rtl of simple_counter_core is

    -- Internal counter register (unsigned for arithmetic)
    signal counter : unsigned(15 downto 0);

begin

    -- Counter process: Standard 3-level control hierarchy
    -- Priority: reset > clk_en > enable
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Reset: Counter to zero
            counter <= (others => '0');

        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then
                    -- Normal operation: increment counter
                    counter <= counter + 1;
                else
                    -- Disabled: hold current value
                    null;
                end if;
            end if;
            -- clk_en='0': hold state (no updates)
        end if;
    end process;

    -- Output assignment (convert unsigned to std_logic_vector)
    count_out <= std_logic_vector(counter);

end architecture rtl;

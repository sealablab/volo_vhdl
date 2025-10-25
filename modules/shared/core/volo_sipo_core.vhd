--------------------------------------------------------------------------------
-- File: volo_sipo_core.vhd
-- Description: Serial In, Parallel Out Shift Register (SIMPLIFIED)
--
-- Features:
--   - Fixed-width shift register (8-bit default, configurable via generic)
--   - Always shifts LEFT (serial_in → LSB, MSB falls off)
--   - Serial data input
--   - Parallel data output
--   - Shift enable control
--   - Done flag (indicates full word received)
--   - Bit counter
--
-- Behavior:
--   - Shift direction: ALWAYS LEFT
--   - Bit order: Determined by sender (protocol layer concern)
--   - No mode switching - one simple behavior
--
-- Pattern: Shift Register (Tier 2)
-- Expected Success: 95-100%
-- Verilog Portable: Yes
-- Use Cases: Serial protocols, UART RX, SPI, data deserialization
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_sipo_core is
    generic (
        WIDTH : positive := 8  -- 8, 16, or 32 bit variants
    );
    port (
        -- Clock and reset
        clk           : in  std_logic;
        reset         : in  std_logic;  -- Active high

        -- Control
        shift_enable  : in  std_logic;  -- '1' to shift in data
        clear         : in  std_logic;  -- '1' to clear shift register

        -- Serial input
        serial_in     : in  std_logic;

        -- Parallel output
        parallel_out  : out std_logic_vector(WIDTH-1 downto 0);

        -- Status
        bit_count     : out std_logic_vector(7 downto 0);  -- Number of bits received
        done          : out std_logic   -- '1' when full word received
    );
end entity volo_sipo_core;

architecture rtl of volo_sipo_core is

    signal shift_reg : std_logic_vector(WIDTH-1 downto 0);
    signal count     : unsigned(7 downto 0);

begin

    -- Shift register process
    process(clk, reset)
    begin
        if reset = '1' then
            shift_reg <= (others => '0');
            count <= (others => '0');

        elsif rising_edge(clk) then
            if clear = '1' then
                shift_reg <= (others => '0');
                count <= (others => '0');

            elsif shift_enable = '1' then
                -- ALWAYS SHIFT LEFT
                -- New bit enters at LSB (position 0)
                -- Old MSB (position WIDTH-1) falls off
                shift_reg <= shift_reg(WIDTH-2 downto 0) & serial_in;

                -- Increment bit counter (wraps at WIDTH)
                if count < WIDTH then
                    count <= count + 1;
                else
                    count <= to_unsigned(1, 8);  -- Restart count after full word
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    parallel_out <= shift_reg;
    bit_count <= std_logic_vector(count);
    done <= '1' when count = WIDTH else '0';

end architecture rtl;

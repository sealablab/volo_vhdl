--------------------------------------------------------------------------------
-- CRC32 Calculator Core
--
-- Description:
--   Computes IEEE 802.3 (Ethernet) CRC32 on streaming data.
--   Polynomial: 0x04C11DB7 (standard CRC32)
--
-- Operation:
--   1. Assert reset to initialize CRC to 0xFFFFFFFF
--   2. For each data word, assert data_valid and provide data_in
--   3. CRC updates on rising edge when data_valid='1'
--   4. Final CRC available on crc_out (invert for IEEE 802.3 format)
--
-- Features:
--   - Single-cycle update per 32-bit word
--   - Continuous operation (no latency)
--   - Verilog-portable (no enums or records)
--
-- Reference:
--   - Polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 +
--                 x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
--   - Initial value: 0xFFFFFFFF
--   - Final XOR: 0xFFFFFFFF (applied in Python, not here)
--
-- Tier: 1 (Strict RTL - Verilog portable core)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crc32_core is
    port (
        -- Clock and Reset
        clk       : in  std_logic;
        n_reset   : in  std_logic;

        -- Data Input
        data_in   : in  std_logic_vector(31 downto 0);
        data_valid : in  std_logic;  -- '1' to update CRC with data_in

        -- CRC Output
        crc_out   : out std_logic_vector(31 downto 0)  -- Current CRC value
    );
end entity crc32_core;

architecture rtl of crc32_core is

    -- CRC accumulator
    signal crc_reg : std_logic_vector(31 downto 0);

    -- CRC32 polynomial (IEEE 802.3)
    constant CRC32_POLY : std_logic_vector(31 downto 0) := x"04C11DB7";

    -- Function to compute CRC for one byte
    function crc32_byte(
        crc_in  : std_logic_vector(31 downto 0);
        data_byte : std_logic_vector(7 downto 0)
    ) return std_logic_vector is
        variable crc_temp : std_logic_vector(31 downto 0);
        variable data_bit : std_logic;
    begin
        crc_temp := crc_in;

        for i in 0 to 7 loop
            data_bit := data_byte(i) xor crc_temp(31);
            crc_temp := crc_temp(30 downto 0) & '0';  -- Shift left

            if data_bit = '1' then
                crc_temp := crc_temp xor CRC32_POLY;
            end if;
        end loop;

        return crc_temp;
    end function;

begin

    -- ========================================================================
    -- CRC Computation
    -- ========================================================================
    process(clk, n_reset)
        variable crc_next : std_logic_vector(31 downto 0);
    begin
        if n_reset = '0' then
            -- Reset: Initialize to 0xFFFFFFFF (CRC32 standard)
            crc_reg <= x"FFFFFFFF";

        elsif rising_edge(clk) then
            if data_valid = '1' then
                -- Process all 4 bytes of the 32-bit word
                -- Note: Process little-endian byte order (byte 0 first)
                crc_next := crc_reg;
                crc_next := crc32_byte(crc_next, data_in(7 downto 0));    -- Byte 0
                crc_next := crc32_byte(crc_next, data_in(15 downto 8));   -- Byte 1
                crc_next := crc32_byte(crc_next, data_in(23 downto 16));  -- Byte 2
                crc_next := crc32_byte(crc_next, data_in(31 downto 24));  -- Byte 3

                crc_reg <= crc_next;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Output Assignment
    -- ========================================================================
    -- Note: IEEE 802.3 requires final XOR with 0xFFFFFFFF
    -- We do NOT apply it here - Python will do: final_crc = ~crc_out
    crc_out <= crc_reg;

end architecture rtl;

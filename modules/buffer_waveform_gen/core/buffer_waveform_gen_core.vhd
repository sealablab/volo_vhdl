--------------------------------------------------------------------------------
-- Buffer Waveform Generator Core
--
-- Description:
--   Simple waveform generator that reads samples from a pre-loaded buffer.
--   Cycles through buffer sequentially at configurable rate.
--
-- Use Case:
--   Demonstrates MCC buffer loading protocol. Pre-load waveform samples
--   (sine, chirp, arbitrary shapes) via Control Registers during LOADING phase,
--   then play them back during RUNNING phase.
--
-- Operation:
--   - Read address counter increments when enabled and clk_en='1'
--   - Wraps around at buffer_length (not buffer size!)
--   - Output = buffer data at current read address
--   - Rate controlled by clk_en from clock divider
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity buffer_waveform_gen_core is
    port (
        -- Clock and Reset
        clk         : in  std_logic;
        n_reset     : in  std_logic;

        -- Control
        enable      : in  std_logic;  -- Global enable (from MCC_READY AND user_enable)
        clk_en      : in  std_logic;  -- Rate control (from clock divider)

        -- Buffer Configuration
        buffer_length : in  unsigned(15 downto 0);  -- Actual length of loaded data
        buffer_valid  : in  std_logic;              -- '1' when buffer has valid data

        -- Buffer Read Interface
        buffer_addr : out unsigned(11 downto 0);          -- Read address (0-4095)
        buffer_data : in  std_logic_vector(31 downto 0);  -- Data from buffer

        -- Output
        waveform_out : out signed(15 downto 0)  -- Waveform sample (lower 16 bits)
    );
end entity buffer_waveform_gen_core;

architecture rtl of buffer_waveform_gen_core is

    -- Read address counter
    signal read_addr_reg : unsigned(11 downto 0);

begin

    -- ========================================================================
    -- Address Counter
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            read_addr_reg <= (others => '0');

        elsif rising_edge(clk) then
            if enable = '1' and buffer_valid = '1' then
                if clk_en = '1' then
                    -- Increment address, wrap at buffer_length
                    if read_addr_reg < (buffer_length - 1) then
                        read_addr_reg <= read_addr_reg + 1;
                    else
                        read_addr_reg <= (others => '0');  -- Wrap to 0
                    end if;
                end if;
            else
                -- Not enabled or buffer invalid: hold at 0
                read_addr_reg <= (others => '0');
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Output Assignment
    -- ========================================================================
    buffer_addr  <= read_addr_reg;
    waveform_out <= signed(buffer_data(15 downto 0));  -- Use lower 16 bits as signed sample

end architecture rtl;

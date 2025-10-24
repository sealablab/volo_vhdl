--------------------------------------------------------------------------------
-- Minimal BRAM Test Core
--
-- Description:
--   Simplest possible BRAM write/read test to debug synthesis issues.
--   Writes a counter pattern to BRAM, then reads it back.
--
-- Operation:
--   - State IDLE: Wait for enable
--   - State WRITING: Write 0x00, 0x01, 0x02... to addresses 0, 1, 2...
--   - State READING: Read back from BRAM
--   - State DONE: Output last value read
--
-- Expected behavior:
--   - OutputA should show incrementing values during READING
--   - OutputB shows debug: [15:12]=state, [11:0]=address
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bram_test_core is
    port (
        -- Clock and Reset
        clk       : in  std_logic;
        n_reset   : in  std_logic;

        -- Control
        enable    : in  std_logic;

        -- Configuration
        num_words : in  unsigned(7 downto 0);  -- How many words to test (max 256)

        -- Outputs
        data_out  : out signed(15 downto 0);   -- Data read from BRAM
        status    : out std_logic_vector(15 downto 0)  -- Debug status
    );
end entity bram_test_core;

architecture rtl of bram_test_core is

    -- State machine
    constant STATE_IDLE    : std_logic_vector(3 downto 0) := "0000";
    constant STATE_WRITING : std_logic_vector(3 downto 0) := "0001";
    constant STATE_READING : std_logic_vector(3 downto 0) := "0010";
    constant STATE_DONE    : std_logic_vector(3 downto 0) := "0011";

    signal state_reg : std_logic_vector(3 downto 0);

    -- BRAM (256 words × 16 bits)
    type bram_t is array(0 to 255) of std_logic_vector(15 downto 0);
    signal bram : bram_t;

    -- Address counter
    signal addr_reg : unsigned(7 downto 0);

    -- Data register
    signal data_reg : std_logic_vector(15 downto 0);

begin

    -- ========================================================================
    -- State Machine
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            state_reg <= STATE_IDLE;
            addr_reg  <= (others => '0');
            data_reg  <= (others => '0');

        elsif rising_edge(clk) then
            case state_reg is

                -- IDLE: Wait for enable
                when STATE_IDLE =>
                    addr_reg <= (others => '0');
                    if enable = '1' then
                        state_reg <= STATE_WRITING;
                    end if;

                -- WRITING: Write pattern to BRAM
                when STATE_WRITING =>
                    -- Write address value to BRAM (0x00 @ addr 0, 0x01 @ addr 1, etc.)
                    bram(to_integer(addr_reg)) <= std_logic_vector(resize(addr_reg, 16));

                    -- Increment address
                    if addr_reg < (num_words - 1) then
                        addr_reg <= addr_reg + 1;
                    else
                        -- Done writing, start reading
                        addr_reg <= (others => '0');
                        state_reg <= STATE_READING;
                    end if;

                -- READING: Read back from BRAM
                when STATE_READING =>
                    -- Read from BRAM (registered read for BRAM timing)
                    data_reg <= bram(to_integer(addr_reg));

                    -- Increment address
                    if addr_reg < (num_words - 1) then
                        addr_reg <= addr_reg + 1;
                    else
                        state_reg <= STATE_DONE;
                    end if;

                -- DONE: Hold last value
                when STATE_DONE =>
                    -- Stay here
                    null;

                when others =>
                    state_reg <= STATE_IDLE;

            end case;
        end if;
    end process;

    -- ========================================================================
    -- Outputs
    -- ========================================================================
    data_out <= signed(data_reg);

    -- Status: [15:12]=state, [11:8]=num_words, [7:0]=current address
    status <= state_reg & std_logic_vector(num_words(3 downto 0)) & std_logic_vector(addr_reg);

end architecture rtl;

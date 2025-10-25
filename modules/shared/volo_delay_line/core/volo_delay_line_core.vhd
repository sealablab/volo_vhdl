--------------------------------------------------------------------------------
-- File: volo_delay_line_core.vhd
-- Description: Configurable Delay Line - Shift Register Chain
--
-- Features:
--   - Fixed depth shift register chain
--   - Configurable data width (1-bit or multi-bit signals)
--   - Multiple tap points for variable delay
--   - Synchronous operation
--
-- Behavior:
--   - Data shifts through N stages on each clock cycle
--   - Output is delayed by DEPTH cycles
--   - Tap selection allows intermediate delays
--
-- Pattern: Shift Register (Tier 2)
-- Expected Success: 95%+
-- Verilog Portable: Yes
-- Use Cases:
--   - Signal delay compensation
--   - Trigger latency adjustment
--   - Random delay insertion (SCA countermeasure)
--   - Moku voltage signal delay (WIDTH=16)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_delay_line_core is
    generic (
        WIDTH : positive := 1;   -- Signal width (1 for trigger, 16 for Moku voltage)
        DEPTH : positive := 16   -- Number of delay stages
    );
    port (
        -- Clock and control
        clk        : in  std_logic;
        reset      : in  std_logic;  -- Active high
        enable     : in  std_logic;  -- '1' to enable shifting

        -- Data path
        data_in    : in  std_logic_vector(WIDTH-1 downto 0);
        data_out   : out std_logic_vector(WIDTH-1 downto 0);  -- Delayed by DEPTH

        -- Variable tap selection (optional)
        tap_select : in  unsigned(7 downto 0);  -- Select delay stage (0 to DEPTH-1)
        tap_out    : out std_logic_vector(WIDTH-1 downto 0)   -- Output from selected tap
    );
end entity volo_delay_line_core;

architecture rtl of volo_delay_line_core is

    -- Delay line array: each stage holds WIDTH bits
    type delay_array_t is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal delay_line : delay_array_t;

begin

    -- Shift register process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Clear all stages
            for i in 0 to DEPTH-1 loop
                delay_line(i) <= (others => '0');
            end loop;

        elsif rising_edge(clk) then
            if enable = '1' then
                -- Shift data through pipeline
                delay_line(0) <= data_in;

                for i in 1 to DEPTH-1 loop
                    delay_line(i) <= delay_line(i-1);
                end loop;
            end if;
        end if;
    end process;

    -- Fixed output: last stage (maximum delay)
    data_out <= delay_line(DEPTH-1);

    -- Variable tap output: selected stage
    process(delay_line, tap_select)
        variable tap_index : integer range 0 to DEPTH-1;
    begin
        -- Clamp tap_select to valid range
        if tap_select >= DEPTH then
            tap_index := DEPTH - 1;
        else
            tap_index := to_integer(tap_select);
        end if;

        tap_out <= delay_line(tap_index);
    end process;

end architecture rtl;

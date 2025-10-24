--------------------------------------------------------------------------------
-- File: volo_barrel_shifter_core.vhd
-- Description: Barrel Shifter - Pure Combinational Logic
--
-- Features:
--   - Fixed 16-bit data width (configurable for 8/32-bit via generic)
--   - Shift left/right by N positions (0-15)
--   - Logical/arithmetic shift modes
--   - Rotate mode
--   - All operations complete in 1 cycle (pure combinational)
--
-- Pattern: Pure Combinational (Tier 1)
-- Expected Success: 100%
-- Verilog Portable: Yes
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_barrel_shifter_core is
    generic (
        WIDTH : positive := 16  -- 8, 16, or 32 bit variants
    );
    port (
        -- Input
        data_in       : in  std_logic_vector(WIDTH-1 downto 0);
        shift_amount  : in  std_logic_vector(4 downto 0);  -- Max 31 positions

        -- Control
        shift_dir     : in  std_logic;  -- '0' = left, '1' = right
        shift_mode    : in  std_logic_vector(1 downto 0);  -- 00=logical, 01=arithmetic, 10=rotate

        -- Output
        data_out      : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity volo_barrel_shifter_core;

architecture rtl of volo_barrel_shifter_core is

    -- Mode constants
    constant MODE_LOGICAL    : std_logic_vector(1 downto 0) := "00";
    constant MODE_ARITHMETIC : std_logic_vector(1 downto 0) := "01";
    constant MODE_ROTATE     : std_logic_vector(1 downto 0) := "10";

    -- Direction constants
    constant DIR_LEFT  : std_logic := '0';
    constant DIR_RIGHT : std_logic := '1';

begin

    -- Barrel shifter process (pure combinational)
    process(data_in, shift_amount, shift_dir, shift_mode)
        variable shift_amt : integer range 0 to 31;
        variable temp_out : std_logic_vector(WIDTH-1 downto 0);
        variable sign_bit : std_logic;
    begin
        shift_amt := to_integer(unsigned(shift_amount));
        temp_out := data_in;
        sign_bit := data_in(WIDTH-1);  -- For arithmetic right shift

        -- Clamp shift amount to WIDTH
        if shift_amt >= WIDTH then
            shift_amt := WIDTH - 1;
        end if;

        -- Perform shift/rotate based on direction and mode
        if shift_dir = DIR_LEFT then
            -- LEFT SHIFT/ROTATE
            case shift_mode is
                when MODE_LOGICAL | MODE_ARITHMETIC =>
                    -- Logical left (zeros fill from right)
                    temp_out := std_logic_vector(shift_left(unsigned(data_in), shift_amt));

                when MODE_ROTATE =>
                    -- Rotate left
                    temp_out := std_logic_vector(rotate_left(unsigned(data_in), shift_amt));

                when others =>
                    temp_out := data_in;
            end case;

        else
            -- RIGHT SHIFT/ROTATE
            case shift_mode is
                when MODE_LOGICAL =>
                    -- Logical right (zeros fill from left)
                    temp_out := std_logic_vector(shift_right(unsigned(data_in), shift_amt));

                when MODE_ARITHMETIC =>
                    -- Arithmetic right (sign bit fills from left)
                    temp_out := std_logic_vector(shift_right(signed(data_in), shift_amt));

                when MODE_ROTATE =>
                    -- Rotate right
                    temp_out := std_logic_vector(rotate_right(unsigned(data_in), shift_amt));

                when others =>
                    temp_out := data_in;
            end case;
        end if;

        data_out <= temp_out;
    end process;

end architecture rtl;

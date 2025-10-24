--------------------------------------------------------------------------------
-- File: volo_encoder_core.vhd
-- Description: Priority Encoder - Pure Combinational Logic
--
-- Features:
--   - Finds highest set bit (MSB priority)
--   - 8-bit and 16-bit variants (fixed-width)
--   - Valid flag output
--   - All-zero input detection
--
-- Pattern: Pure Combinational (Tier 1)
-- Expected Success: 100%
-- Verilog Portable: Yes
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_encoder_core is
    generic (
        WIDTH : positive := 8  -- 8 or 16 bit variants
    );
    port (
        -- Input
        data_in    : in  std_logic_vector(WIDTH-1 downto 0);

        -- Outputs
        encoded    : out std_logic_vector(3 downto 0);  -- Max 16 positions = 4 bits
        valid      : out std_logic                       -- '1' if any bit set
    );
end entity volo_encoder_core;

architecture rtl of volo_encoder_core is
begin

    -- Priority encoder process (pure combinational)
    process(data_in)
        variable temp_encoded : unsigned(3 downto 0);
        variable found : std_logic;
    begin
        temp_encoded := (others => '0');
        found := '0';

        -- Search from MSB to LSB (priority to highest bit)
        for i in WIDTH-1 downto 0 loop
            if data_in(i) = '1' and found = '0' then
                temp_encoded := to_unsigned(i, 4);
                found := '1';
            end if;
        end loop;

        encoded <= std_logic_vector(temp_encoded);
        valid <= found;
    end process;

end architecture rtl;

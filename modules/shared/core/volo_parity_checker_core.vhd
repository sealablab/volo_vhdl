--------------------------------------------------------------------------------
-- File: volo_parity_checker_core.vhd
-- Description: Parity Generator/Checker - Pure Combinational Logic
--
-- Features:
--   - Fixed-width parity generation/checking (8, 16, 32-bit)
--   - Even/odd parity modes
--   - Generate or check modes
--   - Single-cycle operation (pure combinational)
--
-- Pattern: Pure Combinational (Tier 1)
-- Expected Success: 100%
-- Verilog Portable: Yes
-- Use Cases: Error detection, UART, memory interfaces, communication protocols
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity volo_parity_checker_core is
    generic (
        WIDTH : positive := 8  -- 8, 16, or 32 bit variants
    );
    port (
        -- Input
        data_in       : in  std_logic_vector(WIDTH-1 downto 0);
        parity_in     : in  std_logic;  -- For checking mode

        -- Control
        mode          : in  std_logic;  -- '0' = even parity, '1' = odd parity

        -- Outputs
        parity_out    : out std_logic;  -- Generated parity bit
        parity_error  : out std_logic   -- '1' if parity check fails
    );
end entity volo_parity_checker_core;

architecture rtl of volo_parity_checker_core is

    -- Mode constants
    constant MODE_EVEN : std_logic := '0';
    constant MODE_ODD  : std_logic := '1';

    signal calculated_parity : std_logic;

begin

    -- Parity calculation (pure combinational XOR tree)
    process(data_in, mode)
        variable xor_result : std_logic;
    begin
        -- Calculate XOR of all bits
        xor_result := '0';
        for i in 0 to WIDTH-1 loop
            xor_result := xor_result xor data_in(i);
        end loop;

        -- Apply mode (even/odd)
        if mode = MODE_ODD then
            calculated_parity <= not xor_result;  -- Odd: invert
        else
            calculated_parity <= xor_result;      -- Even: direct
        end if;
    end process;

    -- Generate parity output
    parity_out <= calculated_parity;

    -- Check parity (compare calculated vs. received)
    parity_error <= calculated_parity xor parity_in;

end architecture rtl;

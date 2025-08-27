-- clk_divider_core.vhd
-- Simple reusable clock divider module
-- Provides configurable clock division from 1 to 16 using 4-bit control

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity clk_divider_core is
    port (
        clk         : in  std_logic;                    -- Input clock
        rst_n       : in  std_logic;                    -- Active low reset
        div_sel     : in  std_logic_vector(3 downto 0); -- Division select (0=div1, 1=div2, ..., 15=div16)
        clk_en      : out std_logic;                    -- Clock enable output
        stat_reg    : out std_logic_vector(7 downto 0)  -- Status register
    );
end entity clk_divider_core;

architecture rtl of clk_divider_core is
    signal counter       : unsigned(3 downto 0);
    signal div_value     : unsigned(3 downto 0);
    signal clk_en_int    : std_logic;
    
    -- Function to convert divider select to actual divider value
    function get_div_value(sel : std_logic_vector(3 downto 0)) return unsigned is
    begin
        case sel is
            when "0000" => return to_unsigned(0, 4);   -- Divide by 1 (always enabled)
            when "0001" => return to_unsigned(1, 4);   -- Divide by 2
            when "0010" => return to_unsigned(2, 4);   -- Divide by 3
            when "0011" => return to_unsigned(3, 4);   -- Divide by 4
            when "0100" => return to_unsigned(4, 4);   -- Divide by 5
            when "0101" => return to_unsigned(5, 4);   -- Divide by 6
            when "0110" => return to_unsigned(6, 4);   -- Divide by 7
            when "0111" => return to_unsigned(7, 4);   -- Divide by 8
            when "1000" => return to_unsigned(8, 4);   -- Divide by 9
            when "1001" => return to_unsigned(9, 4);   -- Divide by 10
            when "1010" => return to_unsigned(10, 4);  -- Divide by 11
            when "1011" => return to_unsigned(11, 4);  -- Divide by 12
            when "1100" => return to_unsigned(12, 4);  -- Divide by 13
            when "1101" => return to_unsigned(13, 4);  -- Divide by 14
            when "1110" => return to_unsigned(14, 4);  -- Divide by 15
            when "1111" => return to_unsigned(15, 4);  -- Divide by 16
            when others => return to_unsigned(0, 4);   -- Default to divide by 1
        end case;
    end function;
    
begin
    -- Main clock divider process
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
            clk_en_int <= '0';
        elsif rising_edge(clk) then
            div_value <= get_div_value(div_sel);
            
            -- Special case for divide by 1 (always enable)
            if div_sel = "0000" then
                clk_en_int <= '1';
                counter <= (others => '0');
            else
                -- Normal division logic
                if counter >= div_value then
                    counter <= (others => '0');
                    clk_en_int <= '1';
                else
                    counter <= counter + 1;
                    clk_en_int <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Output assignments
    clk_en <= clk_en_int;
    
    -- Status register: [7:4] = current div_sel, [3:0] = current counter value
    stat_reg <= div_sel & std_logic_vector(counter);
    
end architecture rtl;


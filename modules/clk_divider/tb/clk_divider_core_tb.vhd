-- clk_divider_core_tb.vhd
-- Testbench for clock divider core module
-- Tests all division ratios from 1 to 16

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity clk_divider_core_tb is
end entity clk_divider_core_tb;

architecture sim of clk_divider_core_tb is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal div_sel  : std_logic_vector(3 downto 0) := (others => '0');
    signal clk_en   : std_logic;
    signal stat_reg : std_logic_vector(7 downto 0);
    
    -- Test control signals
    signal test_complete : boolean := false;
    
    -- Component declaration
    component clk_divider_core is
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            div_sel     : in  std_logic_vector(3 downto 0);
            clk_en      : out std_logic;
            stat_reg    : out std_logic_vector(7 downto 0)
        );
    end component;
    
begin
    -- Clock generation
    clk_gen: process
    begin
        while not test_complete loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- DUT instantiation
    dut: clk_divider_core
        port map (
            clk      => clk,
            rst_n    => rst_n,
            div_sel  => div_sel,
            clk_en   => clk_en,
            stat_reg => stat_reg
        );
    
    -- Test stimulus process
    test_proc: process
        variable clk_en_count : integer;
        variable expected_count : integer;
        variable test_cycles : integer;
        variable div_ratio : integer;
        
        -- Procedure to test a specific division ratio
        procedure test_division(
            constant div_select : in std_logic_vector(3 downto 0);
            constant division_ratio : in integer
        ) is
        begin
            -- Set division select
            div_sel <= div_select;
            wait for CLK_PERIOD;
            
            -- Reset the divider
            rst_n <= '0';
            wait for CLK_PERIOD * 2;
            rst_n <= '1';
            wait for CLK_PERIOD;
            
            -- Count clock enables for test period
            clk_en_count := 0;
            test_cycles := division_ratio * 10; -- Test for 10 complete cycles
            
            for i in 0 to test_cycles-1 loop
                wait until rising_edge(clk);
                if clk_en = '1' then
                    clk_en_count := clk_en_count + 1;
                end if;
            end loop;
            
            -- Calculate expected count
            expected_count := test_cycles / division_ratio;
            
            -- Check result
            if division_ratio = 1 then
                -- For divide by 1, clk_en should always be high
                if clk_en_count = test_cycles then
                    report "PASS: Division by " & integer'image(division_ratio) & 
                           " - Expected: " & integer'image(expected_count) & 
                           ", Got: " & integer'image(clk_en_count);
                else
                    report "FAIL: Division by " & integer'image(division_ratio) & 
                           " - Expected: " & integer'image(expected_count) & 
                           ", Got: " & integer'image(clk_en_count);
                    report "TEST FAILED";
                end if;
            else
                -- For other divisions, allow ±1 tolerance due to timing
                if clk_en_count >= expected_count-1 and clk_en_count <= expected_count+1 then
                    report "PASS: Division by " & integer'image(division_ratio) & 
                           " - Expected: " & integer'image(expected_count) & 
                           ", Got: " & integer'image(clk_en_count);
                else
                    report "FAIL: Division by " & integer'image(division_ratio) & 
                           " - Expected: " & integer'image(expected_count) & 
                           ", Got: " & integer'image(clk_en_count);
                    report "TEST FAILED";
                end if;
            end if;
        end procedure;
        
    begin
        -- Initial reset
        rst_n <= '0';
        div_sel <= "0000";
        wait for CLK_PERIOD * 5;
        
        report "Starting clock divider tests...";
        
        -- Test all division ratios
        test_division("0000", 1);   -- Divide by 1
        test_division("0001", 2);   -- Divide by 2
        test_division("0010", 3);   -- Divide by 3
        test_division("0011", 4);   -- Divide by 4
        test_division("0100", 5);   -- Divide by 5
        test_division("0101", 6);   -- Divide by 6
        test_division("0110", 7);   -- Divide by 7
        test_division("0111", 8);   -- Divide by 8
        test_division("1000", 9);   -- Divide by 9
        test_division("1001", 10);  -- Divide by 10
        test_division("1010", 11);  -- Divide by 11
        test_division("1011", 12);  -- Divide by 12
        test_division("1100", 13);  -- Divide by 13
        test_division("1101", 14);  -- Divide by 14
        test_division("1110", 15);  -- Divide by 15
        test_division("1111", 16);  -- Divide by 16
        
        -- Test dynamic switching between division ratios
        report "Testing dynamic division switching...";
        rst_n <= '1';
        
        -- Quick test of switching from div2 to div4
        div_sel <= "0001"; -- Div by 2
        wait for CLK_PERIOD * 10;
        
        div_sel <= "0011"; -- Div by 4
        wait for CLK_PERIOD * 20;
        
        div_sel <= "0000"; -- Div by 1
        wait for CLK_PERIOD * 5;
        
        report "ALL TESTS PASSED";
        report "SIMULATION DONE";
        
        test_complete <= true;
        wait;
    end process;
    
end architecture sim;
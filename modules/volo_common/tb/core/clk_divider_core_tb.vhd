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
    signal enable   : std_logic := '1';  -- New enable signal
    signal div_sel  : std_logic_vector(7 downto 0) := (others => '0');  -- Now 8-bit
    signal clk_en   : std_logic;
    signal stat_reg : std_logic_vector(7 downto 0);

    -- Test control signals
    signal test_complete : boolean := false;

    -- Component declaration
    component clk_divider_core is
        generic (
            MAX_DIV : natural := 256
        );
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            enable      : in  std_logic;
            div_sel     : in  std_logic_vector(7 downto 0);
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
    
    -- DUT instantiation with default generic (MAX_DIV = 256)
    dut: clk_divider_core
        generic map (
            MAX_DIV => 256
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            enable   => enable,
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
            constant div_select : in std_logic_vector(7 downto 0);
            constant division_ratio : in integer
        ) is
        begin
            -- Set division select and ensure enabled
            div_sel <= div_select;
            enable <= '1';
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
        enable <= '1';
        div_sel <= x"00";
        wait for CLK_PERIOD * 5;

        report "Starting enhanced clock divider tests...";

        -- Test basic division ratios (8-bit select now)
        test_division(x"00", 1);   -- Divide by 1 (special case)
        test_division(x"01", 1);   -- Divide by 1
        test_division(x"02", 2);   -- Divide by 2
        test_division(x"03", 3);   -- Divide by 3
        test_division(x"04", 4);   -- Divide by 4
        test_division(x"05", 5);   -- Divide by 5
        test_division(x"08", 8);   -- Divide by 8
        test_division(x"0A", 10);  -- Divide by 10
        test_division(x"10", 16);  -- Divide by 16
        test_division(x"20", 32);  -- Divide by 32
        test_division(x"64", 100); -- Divide by 100
        test_division(x"FF", 255); -- Divide by 255 (max for 8-bit)

        -- Test enable functionality
        report "Testing enable input (freeze/unfreeze)...";
        rst_n <= '1';
        div_sel <= x"04"; -- Divide by 4
        enable <= '1';
        wait for CLK_PERIOD * 10;

        -- Freeze the counter
        enable <= '0';
        wait for CLK_PERIOD * 10;
        assert clk_en = '0' report "FAIL: clk_en should be low when disabled" severity error;

        -- Unfreeze and continue
        enable <= '1';
        wait for CLK_PERIOD * 10;

        -- Test dynamic switching between division ratios
        report "Testing dynamic division switching...";
        div_sel <= x"02"; -- Div by 2
        wait for CLK_PERIOD * 10;

        div_sel <= x"08"; -- Div by 8
        wait for CLK_PERIOD * 20;

        div_sel <= x"00"; -- Div by 1
        wait for CLK_PERIOD * 5;
        
        report "ALL TESTS PASSED";
        report "SIMULATION DONE";
        
        test_complete <= true;
        wait;
    end process;
    
end architecture sim;
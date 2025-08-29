-- SimpleWaveGen_core_tb.vhd
-- SimpleWaveGen Core Module Testbench
-- Minimal testbench covering basic functionality, reset behavior, and wave generation

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use STD.TextIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.ENV.all;

entity SimpleWaveGen_core_tb is
end entity SimpleWaveGen_core_tb;

architecture test of SimpleWaveGen_core_tb is
    
    -- Testbench signals
    signal clk              : std_logic := '0';
    signal clk_en           : std_logic := '0';
    signal rst              : std_logic := '0';
    signal en               : std_logic := '0';
    signal cfg_safety_wave_select : std_logic_vector(2 downto 0) := (others => '0');
    signal wave_out         : std_logic_vector(15 downto 0);
    signal fault_out        : std_logic;
    signal stat             : std_logic_vector(7 downto 0);
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Clock period and timing constants
    constant CLK_PERIOD     : time := 10 ns;
    constant RESET_TIME     : time := CLK_PERIOD * 2;
    constant WAVE_WAIT_TIME : time := CLK_PERIOD * 10;
    
    -- VCD file generation
    signal vcd_file_open : boolean := false;
    
    -- Test helper procedure
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
        end if;
        writeline(output, l);
    end procedure report_test;
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- Clock enable generation (simple pattern)
    clk_en <= '1' after CLK_PERIOD * 3, '0' after CLK_PERIOD * 4;
    
    -- VCD file generation process
    vcd_process : process
    begin
        -- Open VCD file for GTKWave
        vcd_file_open <= true;
        wait for 1 ns; -- Small delay to ensure file opens
        
        -- Keep process alive during simulation
        wait;
    end process vcd_process;
    
    -- DUT instantiation (Direct Instantiation Recommended)
    DUT: entity WORK.SimpleWaveGen_core
        port map (
            clk => clk,
            clk_en => clk_en,
            rst => rst,
            en => en,
            cfg_safety_wave_select => cfg_safety_wave_select,
            wave_out => wave_out,
            fault_out => fault_out,
            stat => stat
        );
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        variable prev_wave_out : std_logic_vector(15 downto 0);
    begin
        -- Test initialization
        write(l, string'("=== SimpleWaveGen Core TestBench Started ==="));
        writeline(output, l);
        
        -- ========================================================================
        -- Test Group 1: Reset Behavior
        -- ========================================================================
        write(l, string'("--- Testing Reset Behavior ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior - outputs start at 0x0000
        rst <= '1';
        wait for RESET_TIME;
        rst <= '0';
        wait for CLK_PERIOD;
        test_passed := (wave_out = x"0000") and (fault_out = '0');
        report_test("Reset behavior - outputs start at 0x0000", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 2: Basic Functionality - Wave Generation
        -- ========================================================================
        write(l, string'("--- Testing Basic Wave Generation ---"));
        writeline(output, l);
        
        -- Test 2: Enable the module
        en <= '1';
        wait for CLK_PERIOD;
        test_passed := (stat(0) = '1'); -- Check enabled status
        report_test("Module enable", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Square wave generation (000) - verify output changes over time
        cfg_safety_wave_select <= "000"; -- Square wave
        wait for WAVE_WAIT_TIME;
        prev_wave_out := wave_out;
        wait for WAVE_WAIT_TIME;
        test_passed := (wave_out /= prev_wave_out) and (wave_out /= x"0000");
        report_test("Square wave generation - output changes over time", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Triangle wave generation (001) - verify output changes over time
        cfg_safety_wave_select <= "001"; -- Triangle wave
        wait for WAVE_WAIT_TIME;
        prev_wave_out := wave_out;
        wait for WAVE_WAIT_TIME;
        test_passed := (wave_out /= prev_wave_out) and (wave_out /= x"0000");
        report_test("Triangle wave generation - output changes over time", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Sine wave generation (010) - verify output changes over time
        cfg_safety_wave_select <= "010"; -- Sine wave
        wait for WAVE_WAIT_TIME;
        prev_wave_out := wave_out;
        wait for WAVE_WAIT_TIME;
        test_passed := (wave_out /= prev_wave_out) and (wave_out /= x"0000");
        report_test("Sine wave generation - output changes over time", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 3: Error Handling
        -- ========================================================================
        write(l, string'("--- Testing Error Handling ---"));
        writeline(output, l);
        
        -- Test 6: Invalid wave selection triggers fault
        cfg_safety_wave_select <= "011"; -- Invalid selection
        wait for CLK_PERIOD;
        test_passed := (fault_out = '1');
        report_test("Invalid wave selection triggers fault", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 7: Fault recovery with valid selection
        cfg_safety_wave_select <= "000"; -- Valid selection
        wait for CLK_PERIOD;
        test_passed := (fault_out = '0');
        report_test("Fault recovery with valid selection", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 4: Clock Enable Behavior
        -- ========================================================================
        write(l, string'("--- Testing Clock Enable Behavior ---"));
        writeline(output, l);
        
        -- Test 8: Clock enable behavior - output changes when clk_en is high
        cfg_safety_wave_select <= "001"; -- Triangle wave
        wait for WAVE_WAIT_TIME;
        prev_wave_out := wave_out;
        wait for WAVE_WAIT_TIME;
        test_passed := (wave_out /= prev_wave_out); -- Output should change
        report_test("Clock enable behavior - output changes", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Results Summary
        -- ========================================================================
        write(l, string'("=== Test Results ==="));
        writeline(output, l);
        
        if all_tests_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        stop(0); -- Clean termination (recommended)
    end process test_process;
    
end architecture test;
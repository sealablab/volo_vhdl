-- Base Module Core Testbench
-- Tests the 4-state FSM and alarm functionality
-- Follows enhanced rules system testbench requirements

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import the package under test
library WORK;
use WORK.volo_common_pkg.ALL;

entity base_module_core_tb is
end entity base_module_core_tb;

architecture test of base_module_core_tb is
    
    -- Component declaration
    component base_module_core is
        port (
            clk                     : in  std_logic;
            rst_n                   : in  std_logic;
            enable                  : in  std_logic;
            clk_en                  : in  std_logic;
            counter_in              : in  std_logic_vector(15 downto 0);
            stat_status_out         : out std_logic_vector(7 downto 0)
        );
    end component base_module_core;
    
    -- Test signals
    signal clk                      : std_logic := '0';
    signal rst_n                    : std_logic := '0';
    signal enable                   : std_logic := '0';
    signal clk_en                   : std_logic := '1';
    signal counter_in               : std_logic_vector(15 downto 0) := (others => '0');
    signal stat_status_out          : std_logic_vector(7 downto 0);
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Helper procedure for consistent test reporting
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
            all_tests_passed <= false;
        end if;
        writeline(output, l);
    end procedure report_test;
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- DUT instantiation
    DUT: base_module_core
        port map (
            clk                     => clk,
            rst_n                   => rst_n,
            enable                  => enable,
            clk_en                  => clk_en,
            counter_in              => counter_in,
            stat_status_out         => stat_status_out
        );
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
    begin
        -- Test initialization
        write(l, string'("=== Base Module Core TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- GROUP 1: RESET STATE TESTS
        -- ============================================================================
        write(l, string'("--- Group 1: Reset State Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset state initialization
        rst_n <= '0';
        enable <= '0';
        counter_in <= x"0000";
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1'); -- Should be in RESET state (IDLE bit set)
        report_test("Reset state initialization", test_passed, test_number);
        
        -- Test 2: Invalid counter input (should go to FAULT)
        rst_n <= '1';
        enable <= '1';
        counter_in <= x"0000"; -- Invalid (0)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1');
        report_test("Invalid counter input (0) - FAULT state", test_passed, test_number);
        
        -- Test 3: Valid counter input (should go to READY then IDLE)
        counter_in <= x"0005"; -- Valid (5)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_READY_BIT) = '1');
        report_test("Valid counter input - READY state", test_passed, test_number);
        
        wait for CLK_PERIOD; -- Should transition to IDLE
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and stat_status_out(STATUS_ACTIVE_BIT) = '1');
        report_test("Automatic transition to IDLE state", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 2: COUNTER FUNCTIONALITY TESTS
        -- ============================================================================
        write(l, string'("--- Group 2: Counter Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 4: Counter countdown
        counter_in <= x"0003"; -- Set counter to 3
        wait for CLK_PERIOD; -- Should load counter and start counting
        
        wait for CLK_PERIOD; -- Count 3->2
        wait for CLK_PERIOD; -- Count 2->1
        wait for CLK_PERIOD; -- Count 1->0
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1'); -- Should still be in IDLE
        report_test("Counter countdown completion", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 3: ALARM FUNCTIONALITY TESTS
        -- ============================================================================
        write(l, string'("--- Group 3: Alarm Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 5: Alarm trigger (counter = 3)
        counter_in <= x"0005"; -- Set counter to 5
        wait for CLK_PERIOD; -- Load counter
        
        wait for CLK_PERIOD; -- Count 5->4
        wait for CLK_PERIOD; -- Count 4->3 (alarm should trigger)
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm trigger at count 3", test_passed, test_number);
        
        -- Test 6: Alarm continues at count 2
        wait for CLK_PERIOD; -- Count 3->2
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm continues at count 2", test_passed, test_number);
        
        -- Test 7: Alarm continues at count 1
        wait for CLK_PERIOD; -- Count 2->1
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm continues at count 1", test_passed, test_number);
        
        -- Test 8: Alarm clears at count 0
        wait for CLK_PERIOD; -- Count 1->0
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Alarm clears at count 0", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 4: ENABLE/DISABLE TESTS
        -- ============================================================================
        write(l, string'("--- Group 4: Enable/Disable Tests ---"));
        writeline(output, l);
        
        -- Test 9: Disable module (should return to RESET)
        enable <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and stat_status_out(STATUS_ACTIVE_BIT) = '0');
        report_test("Module disable - return to RESET", test_passed, test_number);
        
        -- Test 10: Re-enable module
        enable <= '1';
        counter_in <= x"0002"; -- Valid counter
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_READY_BIT) = '1');
        report_test("Module re-enable - READY state", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 5: EDGE CASE TESTS
        -- ============================================================================
        write(l, string'("--- Group 5: Edge Case Tests ---"));
        writeline(output, l);
        
        -- Test 11: Counter = 1 (no alarm)
        counter_in <= x"0001";
        wait for CLK_PERIOD; -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Counter = 1 - no alarm", test_passed, test_number);
        
        -- Test 12: Counter = 2 (no alarm)
        counter_in <= x"0002";
        wait for CLK_PERIOD; -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Counter = 2 - no alarm", test_passed, test_number);
        
        -- Test 13: Counter = 3 (alarm)
        counter_in <= x"0003";
        wait for CLK_PERIOD; -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Counter = 3 - alarm", test_passed, test_number);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
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
        
        wait; -- End simulation
    end process test_process;
    
end architecture test;
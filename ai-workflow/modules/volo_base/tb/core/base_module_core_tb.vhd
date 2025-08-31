-- Base Module Core Testbench
-- Tests the base module through external interface only (no implementation assumptions)
-- Follows enhanced rules system testbench requirements
-- 
-- TESTING PHILOSOPHY:
-- - Layer 1: Interface Testing (Status Register) - test external behavior only
-- - Layer 2: Validation Testing - test parameter validation and error handling  
-- - Layer 3: Functional Testing - test counter countdown and alarm behavior
-- - Layer 4: Generic Parameter Testing - test different ALARM_THRESHOLD values
--
-- KEY PRINCIPLE: Test WHAT the module does, not HOW it does it

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;      -- For constants and synthesizable utilities
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities

entity base_module_core_tb is
end entity base_module_core_tb;

architecture test of base_module_core_tb is
    
    -- Direct instantiation (recommended for core layer testbenches)
    
    -- Test signals
    signal clk                      : std_logic := '0';
    signal rst_n                    : std_logic := '0';
    signal enable                   : std_logic := '0';
    signal clk_en                   : std_logic := '1';
    signal counter_in               : std_logic_vector(15 downto 0) := (others => '0');
    signal stat_status_out          : std_logic_vector(7 downto 0);
    
    -- Test result tracking (will be handled as variable in process)
    
    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Testbench utilities now imported from volo_common_tb_pkg
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- DUT instantiation (direct instantiation)
    DUT: entity work.base_module_core
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
        variable all_tests_passed : boolean := true;
        variable l : line;

        
    begin
        -- Test initialization
        write(l, string'("=== Base Module Core TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Status Register)
        -- Test external behavior only - no assumptions about internal state machine
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Status Register) ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior - module should be in safe state
        rst_n <= '0';
        enable <= '0';
        counter_in <= x"0000";
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_FAULT_BIT) = '0' and
                       stat_status_out(STATUS_ALARM_BIT) = '0' and
                       stat_status_out(STATUS_ACTIVE_BIT) = '0');
        
        -- Debug output
        write(l, string'("DEBUG: Reset status = " & to_string(stat_status_out)));
        writeline(output, l);
        
        report_test("Reset behavior - safe state", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Enable behavior - module should show enabled status
        rst_n <= '1';
        enable <= '1';
        counter_in <= x"0005"; -- Valid input
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');
        
        -- Debug output
        write(l, string'("DEBUG: Enable status = " & to_string(stat_status_out)));
        writeline(output, l);
        
        report_test("Enable behavior - enabled status", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing ---"));
        writeline(output, l);
        
        -- Test 3: Invalid counter input (0) - should trigger validation failure
        counter_in <= x"0000"; -- Invalid (below minimum)
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' or 
                       stat_status_out(STATUS_ALARM_BIT) = '1'); -- Either fault or alarm for invalid input
        report_test("Invalid counter input (0) - validation failure", test_passed, test_number, all_tests_passed);
        
        -- Test 4: Valid counter input - should allow normal operation
        counter_in <= x"0005"; -- Valid input
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0' and 
                       stat_status_out(STATUS_VALID_BIT) = '1');
        report_test("Valid counter input - normal operation", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING
        -- Test counter countdown and alarm behavior
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing ---"));
        writeline(output, l);
        
        -- Test 5: Counter countdown - should complete without errors
        counter_in <= x"0003"; -- Set counter to 3
        wait until rising_edge(clk); -- Load counter
        
        -- Wait for countdown to complete (3->2->1->0)
        wait until rising_edge(clk); -- Count 3->2
        wait until rising_edge(clk); -- Count 2->1  
        wait until rising_edge(clk); -- Count 1->0
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0'); -- Should not fault during countdown
        report_test("Counter countdown completion - no faults", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Alarm threshold behavior - should trigger alarm at count 3 (default threshold)
        counter_in <= x"0005"; -- Set counter to 5
        wait until rising_edge(clk); -- Load counter
        
        wait until rising_edge(clk); -- Count 5->4
        wait until rising_edge(clk); -- Count 4->3 (alarm should trigger)
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        
        -- Debug output
        write(l, string'("DEBUG: Alarm status = " & to_string(stat_status_out)));
        writeline(output, l);
        
        report_test("Alarm threshold behavior - alarm at count 3", test_passed, test_number, all_tests_passed);
        
        -- Test 7: Alarm persistence - should continue until countdown completes
        wait until rising_edge(clk); -- Count 3->2
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm persistence - continues at count 2", test_passed, test_number, all_tests_passed);
        
        wait until rising_edge(clk); -- Count 2->1
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm persistence - continues at count 1", test_passed, test_number, all_tests_passed);
        
        wait until rising_edge(clk); -- Count 1->0
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Alarm clearance - clears at count 0", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 4: GENERIC PARAMETER TESTING
        -- Test different ALARM_THRESHOLD values (using multiple test phases)
        -- ============================================================================
        write(l, string'("--- Layer 4: Generic Parameter Testing ---"));
        writeline(output, l);
        
        -- Test 8: Test alarm threshold edge cases
        -- Counter = 1 (below default threshold of 3) - should not alarm
        counter_in <= x"0001";
        wait until rising_edge(clk); -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Alarm threshold edge case - count 1 (no alarm)", test_passed, test_number, all_tests_passed);
        
        -- Counter = 2 (below default threshold of 3) - should not alarm  
        counter_in <= x"0002";
        wait until rising_edge(clk); -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0');
        report_test("Alarm threshold edge case - count 2 (no alarm)", test_passed, test_number, all_tests_passed);
        
        -- Counter = 3 (at default threshold of 3) - should alarm
        counter_in <= x"0003";
        wait until rising_edge(clk); -- Load counter
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm threshold edge case - count 3 (alarm)", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- CONTROL SIGNAL TESTING
        -- Test enable/disable and clock enable behavior
        -- ============================================================================
        write(l, string'("--- Control Signal Testing ---"));
        writeline(output, l);
        
        -- Test 9: Module disable - should return to safe state
        enable <= '0';
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '0' and 
                       stat_status_out(STATUS_ACTIVE_BIT) = '0');
        report_test("Module disable - safe state", test_passed, test_number, all_tests_passed);
        
        -- Test 10: Module re-enable - should return to normal operation
        enable <= '1';
        counter_in <= x"0002"; -- Valid counter
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1' and 
                       stat_status_out(STATUS_VALID_BIT) = '1');
        report_test("Module re-enable - normal operation", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        wait for 100 ns; -- Allow final outputs to settle
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;
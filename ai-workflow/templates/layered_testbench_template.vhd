-- Layered Testbench Template
-- Standard template for all VOLO VHDL module testbenches
-- Follows the 4-layer testing architecture for comprehensive coverage
--
-- TESTING PHILOSOPHY:
-- - Layer 1: Interface Testing (Status Register) - test external behavior only
-- - Layer 2: Validation Testing - test parameter validation and error handling  
-- - Layer 3: Functional Testing - test core functionality and behavior
-- - Layer 4: Generic Parameter Testing - test different generic values
--
-- KEY PRINCIPLE: Test WHAT the module does, not HOW it does it
-- This ensures tests remain valid even if internal implementation changes

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;      -- For constants and synthesizable utilities
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities

entity <module_name>_core_tb is
end entity <module_name>_core_tb;

architecture test of <module_name>_core_tb is
    
    -- Test signals (customize for your module)
    signal clk                      : std_logic := '0';
    signal rst_n                    : std_logic := '0';
    signal enable                   : std_logic := '0';
    signal clk_en                   : std_logic := '1';
    -- Add your module-specific signals here
    signal stat_status_out          : std_logic_vector(7 downto 0);
    
    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- DUT instantiation (direct instantiation recommended for core layer)
    DUT: entity work.<module_name>_core
        port map (
            clk                     => clk,
            rst_n                   => rst_n,
            enable                  => enable,
            clk_en                  => clk_en,
            -- Add your module-specific port mappings here
            stat_status_out         => stat_status_out
        );
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable all_tests_passed : boolean := true;
        variable l : line;

        
    begin
        -- Test initialization
        write(l, string'("=== <Module Name> Core TestBench Started ==="));
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
        -- Set invalid inputs to test reset behavior
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_FAULT_BIT) = '0' and
                       stat_status_out(STATUS_ALARM_BIT) = '0' and
                       stat_status_out(STATUS_ACTIVE_BIT) = '0');
        report_test("Reset behavior - safe state", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Enable behavior - module should show enabled status
        rst_n <= '1';
        enable <= '1';
        -- Set valid inputs to test enable behavior
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');
        report_test("Enable behavior - enabled status", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing ---"));
        writeline(output, l);
        
        -- Test 3: Invalid input - should trigger validation failure
        -- Set invalid parameters that should fail validation
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' or 
                       stat_status_out(STATUS_ALARM_BIT) = '1'); -- Either fault or alarm for invalid input
        report_test("Invalid input - validation failure", test_passed, test_number, all_tests_passed);
        
        -- Test 4: Valid input - should allow normal operation
        -- Set valid parameters that should pass validation
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0' and 
                       stat_status_out(STATUS_VALID_BIT) = '1');
        report_test("Valid input - normal operation", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING
        -- Test core functionality and behavior
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing ---"));
        writeline(output, l);
        
        -- Test 5: Core functionality - should complete without errors
        -- Test the main functional behavior of your module
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '0'); -- Should not fault during operation
        report_test("Core functionality - no faults", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Specific functional behavior
        -- Test specific behaviors like alarms, thresholds, etc.
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1'); -- Example: alarm should trigger
        report_test("Specific functional behavior", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 4: GENERIC PARAMETER TESTING
        -- Test different generic values (using multiple test phases)
        -- ============================================================================
        write(l, string'("--- Layer 4: Generic Parameter Testing ---"));
        writeline(output, l);
        
        -- Test 7: Generic parameter edge cases
        -- Test edge cases around generic parameter values
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0'); -- Example: no alarm at edge case
        report_test("Generic parameter edge case", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- CONTROL SIGNAL TESTING
        -- Test enable/disable and clock enable behavior
        -- ============================================================================
        write(l, string'("--- Control Signal Testing ---"));
        writeline(output, l);
        
        -- Test 8: Module disable - should return to safe state
        enable <= '0';
        wait until rising_edge(clk);
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '0' and 
                       stat_status_out(STATUS_ACTIVE_BIT) = '0');
        report_test("Module disable - safe state", test_passed, test_number, all_tests_passed);
        
        -- Test 9: Module re-enable - should return to normal operation
        enable <= '1';
        -- Set valid inputs for re-enable
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
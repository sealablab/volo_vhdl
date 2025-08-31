-- Base Module Core TestBench
-- Tests essential functionality: state transitions and alarm bit verification
-- Uses direct instantiation and observes behavior through status register

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities

entity base_module_core_tb is
end entity base_module_core_tb;

architecture test of base_module_core_tb is
    
    -- Test signals
    signal clk                      : std_logic := '0';
    signal rst_n                    : std_logic := '0';
    signal enable                   : std_logic := '0';
    signal clk_en                   : std_logic := '1';
    signal counter_in               : std_logic_vector(15 downto 0) := (others => '0');
    signal stat_status_out          : std_logic_vector(7 downto 0);
    
    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;
    
begin
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
        -- TEST 1: Invalid input parameter should cause FAULT state
        -- ============================================================================
        write(l, string'("--- Test 1: Invalid Input -> FAULT State ---"));
        writeline(output, l);
        
        -- Reset with invalid counter input (0 is below minimum of 1)
        counter_in <= x"0000"; -- Invalid input
        enable <= '1';
        rst_n <= '0';
        wait until rising_edge(clk);
        rst_n <= '1'; -- Release reset with invalid input
        wait until rising_edge(clk); -- Allow state machine to process
        
        -- Check that module enters FAULT state (or shows invalid status)
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' or 
                       stat_status_out(STATUS_VALID_BIT) = '0');
        report_test("Invalid input causes FAULT state", test_passed, test_number, all_tests_passed);
        
        write(l, string'("Status with invalid input: " & to_string(stat_status_out)));
        writeline(output, l);
        
        -- ============================================================================
        -- TEST 2: Valid input should allow normal state transitions
        -- ============================================================================
        write(l, string'("--- Test 2: Valid Input -> Normal State Transitions ---"));
        writeline(output, l);
        
        -- Reset with valid counter input
        counter_in <= x"0005"; -- Valid input (5)
        rst_n <= '0';
        wait until rising_edge(clk);
        rst_n <= '1'; -- Release reset with valid input
        wait until rising_edge(clk); -- Transition to READY_STATE
        wait until rising_edge(clk); -- Transition to IDLE_STATE
        
        -- Check that module reaches IDLE state (IDLE bit should be set, no FAULT)
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and
                       stat_status_out(STATUS_FAULT_BIT) = '0');
        report_test("Valid input allows normal state transitions", test_passed, test_number, all_tests_passed);
        
        write(l, string'("Status in IDLE state: " & to_string(stat_status_out)));
        writeline(output, l);
        
        -- ============================================================================
        -- TEST 3: Alarm bit should go high when counter gets low
        -- ============================================================================
        write(l, string'("--- Test 3: Alarm Bit Verification ---"));
        writeline(output, l);
        
        -- Count down until alarm should trigger (counter <= 3)
        wait until rising_edge(clk); -- Count 5->4
        write(l, string'("Status after count 5->4: " & to_string(stat_status_out)));
        writeline(output, l);
        
        wait until rising_edge(clk); -- Count 4->3
        write(l, string'("Status after count 4->3: " & to_string(stat_status_out)));
        writeline(output, l);
        
        wait until rising_edge(clk); -- Count 3->2 (alarm should trigger)
        write(l, string'("Status after count 3->2: " & to_string(stat_status_out)));
        writeline(output, l);
        
        -- Check that alarm bit goes high
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1');
        report_test("Alarm bit goes high when counter gets low", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        wait for 100 ns; -- Allow final outputs to settle
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;
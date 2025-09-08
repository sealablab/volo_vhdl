-- Base Module Top Testbench
-- Tests integration and signal routing
-- Follows enhanced rules system testbench requirements

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import the package under test
library WORK;
use WORK.volo_common_pkg.ALL;

entity base_module_top_tb is
end entity base_module_top_tb;

architecture test of base_module_top_tb is
    
    -- Direct instantiation (required for top layer testbenches)
    
    -- Test signals
    signal clk                      : std_logic := '0';
    signal rst_n                    : std_logic := '0';
    signal ctrl_enable              : std_logic := '0';
    signal ctrl_clk_en              : std_logic := '1';
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
    
    -- DUT instantiation (direct instantiation required for top layer)
    DUT: entity work.base_module_top
        port map (
            clk                     => clk,
            rst_n                   => rst_n,
            ctrl_enable             => ctrl_enable,
            ctrl_clk_en             => ctrl_clk_en,
            counter_in              => counter_in,
            stat_status_out         => stat_status_out
        );
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
    begin
        -- Test initialization
        write(l, string'("=== Base Module Top TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- GROUP 1: SIGNAL ROUTING TESTS
        -- ============================================================================
        write(l, string'("--- Group 1: Signal Routing Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset state
        rst_n <= '0';
        ctrl_enable <= '0';
        counter_in <= x"0000";
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_FAULT_BIT) = '0' and 
                       stat_status_out(STATUS_ALARM_BIT) = '0' and 
                       stat_status_out(STATUS_READY_BIT) = '0');
        report_test("Reset state - signal routing", test_passed, test_number);
        
        -- Test 2: Invalid counter (FAULT state)
        rst_n <= '1';
        ctrl_enable <= '1';
        counter_in <= x"0000"; -- Invalid
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1' and 
                       stat_status_out(STATUS_ALARM_BIT) = '0' and 
                       stat_status_out(STATUS_READY_BIT) = '0');
        report_test("Fault state - signal routing", test_passed, test_number);
        
        -- Test 3: Valid counter (READY state)
        counter_in <= x"0005"; -- Valid
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_READY_BIT) = '1' and 
                       stat_fault_out = '0' and 
                       stat_alarm_out = '0' and 
                       stat_ready_out = '1');
        report_test("Ready state - signal routing", test_passed, test_number);
        
        -- Test 4: IDLE state (ACTIVE)
        wait for CLK_PERIOD; -- Should transition to IDLE
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_ACTIVE_BIT) = '1' and
                       stat_fault_out = '0' and 
                       stat_alarm_out = '0' and 
                       stat_ready_out = '0');
        report_test("Idle state - signal routing", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 2: ALARM SIGNAL ROUTING TESTS
        -- ============================================================================
        write(l, string'("--- Group 2: Alarm Signal Routing Tests ---"));
        writeline(output, l);
        
        -- Test 5: Alarm trigger
        counter_in <= x"0005"; -- Set counter to 5
        wait for CLK_PERIOD; -- Load counter
        
        wait for CLK_PERIOD; -- Count 5->4
        wait for CLK_PERIOD; -- Count 4->3 (alarm should trigger)
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1' and 
                       stat_alarm_out = '1');
        report_test("Alarm trigger - signal routing", test_passed, test_number);
        
        -- Test 6: Alarm continues
        wait for CLK_PERIOD; -- Count 3->2
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '1' and 
                       stat_alarm_out = '1');
        report_test("Alarm continues - signal routing", test_passed, test_number);
        
        -- Test 7: Alarm clears
        wait for CLK_PERIOD; -- Count 2->1
        wait for CLK_PERIOD; -- Count 1->0
        
        test_passed := (stat_status_out(STATUS_ALARM_BIT) = '0' and 
                       stat_alarm_out = '0');
        report_test("Alarm clears - signal routing", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 3: CONTROL SIGNAL TESTS
        -- ============================================================================
        write(l, string'("--- Group 3: Control Signal Tests ---"));
        writeline(output, l);
        
        -- Test 8: Clock enable functionality
        ctrl_clk_en <= '0';
        counter_in <= x"0003";
        wait for CLK_PERIOD; -- Should not advance
        
        test_passed := (stat_status_out(STATUS_READY_BIT) = '1'); -- Should stay in READY
        report_test("Clock enable disable - no advancement", test_passed, test_number);
        
        -- Test 9: Re-enable clock
        ctrl_clk_en <= '1';
        wait for CLK_PERIOD; -- Should advance to IDLE
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1');
        report_test("Clock enable re-enable - advancement", test_passed, test_number);
        
        -- Test 10: Module disable
        ctrl_enable <= '0';
        wait for CLK_PERIOD; -- Should return to RESET
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_ACTIVE_BIT) = '0');
        report_test("Module disable - return to RESET", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 4: INTEGRATION TESTS
        -- ============================================================================
        write(l, string'("--- Group 4: Integration Tests ---"));
        writeline(output, l);
        
        -- Test 11: Full cycle test
        ctrl_enable <= '1';
        counter_in <= x"0004"; -- Set counter to 4
        wait for CLK_PERIOD; -- Load counter
        
        wait for CLK_PERIOD; -- Count 4->3 (alarm)
        wait for CLK_PERIOD; -- Count 3->2 (alarm)
        wait for CLK_PERIOD; -- Count 2->1 (alarm)
        wait for CLK_PERIOD; -- Count 1->0 (no alarm)
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1' and 
                       stat_status_out(STATUS_ACTIVE_BIT) = '1' and
                       stat_alarm_out = '0');
        report_test("Full cycle integration test", test_passed, test_number);
        
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
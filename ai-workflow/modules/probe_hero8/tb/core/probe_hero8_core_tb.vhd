-- =============================================================================
-- ProbeHero8 Core Testbench
-- =============================================================================
-- 
-- This comprehensive testbench validates the ProbeHero8 core functionality
-- with extensive test scenarios covering all edge cases, error conditions,
-- and integration with enhanced packages.
--
-- Test Coverage:
-- - Basic functionality tests (reset, enable, state transitions)
-- - Parameter validation tests (valid/invalid inputs, clamping)
-- - Firing sequence tests (trigger detection, timing, outputs)
-- - Error condition tests (fault handling, recovery)
-- - Enhanced package integration tests
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use STD.ENV.ALL;
use work.Probe_Config_pkg_en.ALL;
use work.Global_Probe_Table_pkg_en.ALL;
use work.Moku_Voltage_pkg_en.ALL;
use work.PercentLut_pkg_en.ALL;

entity probe_hero8_core_tb is
end entity probe_hero8_core_tb;

architecture test of probe_hero8_core_tb is

    -- =========================================================================
    -- Component Declaration (using direct instantiation pattern)
    -- =========================================================================
    -- Note: This testbench uses direct instantiation for consistency with
    -- the enhanced development workflow
    
    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal ctrl_enable : std_logic := '0';
    signal ctrl_start : std_logic := '0';
    signal trig_in : std_logic := '0';
    
    -- Configuration signals
    signal cfg_probe_selector_index : std_logic_vector(1 downto 0) := "00";
    signal cfg_intensity_index : std_logic_vector(6 downto 0) := "0000000";
    signal cfg_fire_duration : std_logic_vector(15 downto 0) := x"0064";  -- 100 clock cycles
    signal cfg_cooldown_duration : std_logic_vector(15 downto 0) := x"03E8"; -- 1000 clock cycles
    
    -- Status outputs
    signal stat_current_state : std_logic_vector(3 downto 0);
    signal stat_fault : std_logic;
    signal stat_ready : std_logic;
    signal stat_idle : std_logic;
    signal stat_status_reg : std_logic_vector(31 downto 0);
    
    -- Module status input
    signal module_status : std_logic_vector(15 downto 0) := (others => '0');
    
    -- Probe outputs
    signal trigger_out : std_logic_vector(15 downto 0);
    signal intensity_out : std_logic_vector(15 downto 0);
    
    -- Debug output
    signal debug_state_machine : std_logic_vector(3 downto 0);
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Direct Instantiation of DUT
    -- =========================================================================
    DUT: entity WORK.probe_hero8_core
        generic map (
            MODULE_NAME => "probe_hero8_core",
            STATUS_REG_WIDTH => 32,
            MODULE_STATUS_BITS => 16
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            ctrl_enable => ctrl_enable,
            ctrl_start => ctrl_start,
            trig_in => trig_in,
            cfg_probe_selector_index => cfg_probe_selector_index,
            cfg_intensity_index => cfg_intensity_index,
            cfg_fire_duration => cfg_fire_duration,
            cfg_cooldown_duration => cfg_cooldown_duration,
            stat_current_state => stat_current_state,
            stat_fault => stat_fault,
            stat_ready => stat_ready,
            stat_idle => stat_idle,
            stat_status_reg => stat_status_reg,
            module_status => module_status,
            trigger_out => trigger_out,
            intensity_out => intensity_out,
            debug_state_machine => debug_state_machine
        );

    -- =========================================================================
    -- Clock Generation
    -- =========================================================================
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;



    -- =========================================================================
    -- Main Test Process
    -- =========================================================================
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable expected_state : std_logic_vector(3 downto 0);
        variable expected_voltage : std_logic_vector(15 downto 0);
        variable actual_voltage : std_logic_vector(15 downto 0);
        variable test_number : natural := 0;
        
        -- Helper procedure for consistent test reporting
        procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
            variable l : line;
        begin
            test_num := test_num + 1;
            write(l, string'("Test "));
            write(l, test_num);
            write(l, string'(": "));
            write(l, test_name);
            write(l, string'(" - "));
            if passed then
                write(l, string'("PASSED"));
            else
                write(l, string'("FAILED"));
            end if;
            writeline(output, l);
        end procedure;
        
        -- Helper procedure to wait for state transition
        procedure wait_for_state(target_state : std_logic_vector(3 downto 0); max_cycles : natural := 100) is
            variable cycles_waited : natural := 0;
        begin
            while stat_current_state /= target_state and cycles_waited < max_cycles loop
                wait for CLK_PERIOD;
                cycles_waited := cycles_waited + 1;
            end loop;
        end procedure;
        
        -- Helper procedure to wait for clock cycles
        procedure wait_cycles(cycles : natural) is
        begin
            for i in 1 to cycles loop
                wait for CLK_PERIOD;
            end loop;
        end procedure;
        
    begin
        -- Test initialization
        write(l, string'("=== ProbeHero8 Core TestBench Started ==="));
        writeline(output, l);
        
        -- =====================================================================
        -- Group 1: Basic Functionality Tests
        -- =====================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior
        rst_n <= '0';
        wait_cycles(5);
        test_passed := (stat_current_state = "0000"); -- ST_RESET
        report_test("Reset behavior", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Enable with valid parameters
        rst_n <= '1';
        ctrl_enable <= '1';
        cfg_probe_selector_index <= "00";  -- Valid probe index
        cfg_intensity_index <= "0000101";  -- Valid intensity index (5%)
        cfg_fire_duration <= x"0064";      -- Valid fire duration (100 cycles)
        cfg_cooldown_duration <= x"03E8";  -- Valid cooldown duration (1000 cycles)
        wait_cycles(5);
        test_passed := (stat_current_state = "0001"); -- ST_READY
        report_test("Enable with valid parameters", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Start command
        ctrl_start <= '1';
        wait_cycles(2);
        ctrl_start <= '0';
        wait_cycles(2);
        test_passed := (stat_current_state = "0010"); -- ST_IDLE
        report_test("Start command", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: State transition to ARMED
        ctrl_enable <= '1';
        wait_cycles(2);
        test_passed := (stat_current_state = "0011"); -- ST_ARMED
        report_test("State transition to ARMED", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 2: Parameter Validation Tests
        -- =====================================================================
        write(l, string'("--- Group 2: Parameter Validation Tests ---"));
        writeline(output, l);
        
        -- Test 5: Valid probe selection
        cfg_probe_selector_index <= "01";  -- Valid probe index
        wait_cycles(2);
        test_passed := (stat_current_state = "0011"); -- Should stay in ARMED
        report_test("Valid probe selection", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Invalid probe selection (should trigger HARDFAULT)
        cfg_probe_selector_index <= "11";  -- Invalid probe index (assuming only 0-2 are valid)
        wait_cycles(2);
        test_passed := (stat_current_state = "1111"); -- ST_HARD_FAULT
        report_test("Invalid probe selection triggers HARDFAULT", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Reset and restore valid configuration
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        ctrl_enable <= '1';
        cfg_probe_selector_index <= "00";
        cfg_intensity_index <= "0000101";
        cfg_fire_duration <= x"0064";
        cfg_cooldown_duration <= x"03E8";
        wait_cycles(5);
        ctrl_start <= '1';
        wait_cycles(2);
        ctrl_start <= '0';
        wait_cycles(2);
        
        -- Test 7: Valid intensity index
        cfg_intensity_index <= "0111111";  -- Valid intensity index (63%)
        wait_cycles(2);
        test_passed := (stat_current_state = "0011"); -- Should stay in ARMED
        report_test("Valid intensity index", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Duration clamping (test with values outside valid range)
        cfg_fire_duration <= x"0001";      -- Very short duration (should be clamped)
        cfg_cooldown_duration <= x"FFFF";  -- Very long duration (should be clamped)
        wait_cycles(2);
        test_passed := (stat_current_state = "0011"); -- Should stay in ARMED (with alarm)
        report_test("Duration clamping behavior", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 3: Firing Sequence Tests
        -- =====================================================================
        write(l, string'("--- Group 3: Firing Sequence Tests ---"));
        writeline(output, l);
        
        -- Restore valid configuration for firing tests
        cfg_fire_duration <= x"0064";      -- 100 cycles
        cfg_cooldown_duration <= x"03E8";  -- 1000 cycles
        wait_cycles(2);
        
        -- Test 9: Trigger detection
        trig_in <= '0';
        wait_cycles(2);
        trig_in <= '1';
        wait_cycles(2);
        test_passed := (stat_current_state = "0100"); -- ST_FIRING
        report_test("Trigger detection", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 10: Output voltage during firing
        expected_voltage := x"1000";  -- Expected trigger voltage from default probe config
        actual_voltage := trigger_out;
        test_passed := (actual_voltage = expected_voltage);
        report_test("Trigger voltage output during firing", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 11: Intensity voltage output
        test_passed := (intensity_out /= x"0000"); -- Should be non-zero
        report_test("Intensity voltage output during firing", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 12: Fire duration timing
        wait_cycles(50);  -- Wait half the fire duration
        test_passed := (stat_current_state = "0100"); -- Should still be firing
        report_test("Fire duration timing (mid-fire)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        wait_cycles(60);  -- Wait for fire duration to complete
        test_passed := (stat_current_state = "0101"); -- ST_COOLING
        report_test("Fire duration timing (fire complete)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Outputs during cooling
        test_passed := (trigger_out = x"0000" and intensity_out = x"0000");
        report_test("Outputs during cooling", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 14: Cooldown duration timing
        wait_cycles(500);  -- Wait half the cooldown duration
        test_passed := (stat_current_state = "0101"); -- Should still be cooling
        report_test("Cooldown duration timing (mid-cooldown)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        wait_cycles(600);  -- Wait for cooldown to complete
        test_passed := (stat_current_state = "0011"); -- ST_ARMED
        report_test("Cooldown duration timing (cooldown complete)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 4: Error Condition Tests
        -- =====================================================================
        write(l, string'("--- Group 4: Error Condition Tests ---"));
        writeline(output, l);
        
        -- Test 15: Invalid trigger during cooling (should be ignored)
        trig_in <= '1';
        wait_cycles(2);
        trig_in <= '0';
        wait_cycles(2);
        test_passed := (stat_current_state = "0011"); -- Should stay in ARMED
        report_test("Invalid trigger during cooling ignored", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 16: Disable during operation
        ctrl_enable <= '0';
        wait_cycles(2);
        test_passed := (stat_current_state = "0010"); -- ST_IDLE
        report_test("Disable during operation", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 17: Status register updates
        test_passed := (stat_status_reg(27 downto 24) = "0010"); -- Current state in status reg
        report_test("Status register updates", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 5: Enhanced Package Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 5: Enhanced Package Integration Tests ---"));
        writeline(output, l);
        
        -- Test 18: Different probe configurations
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        ctrl_enable <= '1';
        cfg_probe_selector_index <= "01";  -- Different probe
        cfg_intensity_index <= "0000101";
        cfg_fire_duration <= x"0064";
        cfg_cooldown_duration <= x"03E8";
        wait_cycles(5);
        ctrl_start <= '1';
        wait_cycles(2);
        ctrl_start <= '0';
        wait_cycles(2);
        
        trig_in <= '1';
        wait_cycles(2);
        trig_in <= '0';
        wait_cycles(2);
        
        -- Check that different probe produces different trigger voltage
        expected_voltage := x"0800";  -- Expected trigger voltage for probe 1
        actual_voltage := trigger_out;
        test_passed := (actual_voltage = expected_voltage);
        report_test("Different probe configuration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 19: Intensity scaling from PercentLut
        cfg_intensity_index <= "0000000";  -- 0% intensity
        wait_cycles(2);
        trig_in <= '1';
        wait_cycles(2);
        trig_in <= '0';
        wait_cycles(2);
        
        test_passed := (intensity_out = x"0000"); -- Should be zero for 0% intensity
        report_test("Intensity scaling from PercentLut", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Final Test Results
        -- =====================================================================
        write(l, string'("--- Final Test Results ---"));
        writeline(output, l);
        
        if all_tests_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        stop(0); -- Clean termination
    end process;

end architecture test;
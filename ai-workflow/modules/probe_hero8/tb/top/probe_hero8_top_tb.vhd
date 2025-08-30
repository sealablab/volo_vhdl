-- =============================================================================
-- ProbeHero8 Top-Level Testbench
-- =============================================================================
-- 
-- This top-level testbench validates the complete ProbeHero8 system integration
-- with comprehensive end-to-end testing. It tests the full system from external
-- interface through core functionality to output validation.
--
-- Test Coverage:
-- - External interface validation
-- - System integration testing
-- - End-to-end functionality validation
-- - Register interface testing
-- - Platform control system simulation
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

entity probe_hero8_top_tb is
end entity probe_hero8_top_tb;

architecture test of probe_hero8_top_tb is

    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    -- External control interface
    signal ext_enable : std_logic := '0';
    signal ext_start : std_logic := '0';
    signal ext_trigger : std_logic := '0';
    
    -- External configuration interface
    signal ext_probe_selector : std_logic_vector(1 downto 0) := "00";
    signal ext_intensity_index : std_logic_vector(6 downto 0) := "0000000";
    signal ext_fire_duration : std_logic_vector(15 downto 0) := x"0064";  -- 100 clock cycles
    signal ext_cooldown_duration : std_logic_vector(15 downto 0) := x"03E8"; -- 1000 clock cycles
    
    -- External status interface
    signal ext_status_register : std_logic_vector(31 downto 0);
    signal ext_fault_status : std_logic;
    signal ext_ready_status : std_logic;
    signal ext_idle_status : std_logic;
    
    -- External probe output interface
    signal ext_trigger_output : std_logic_vector(15 downto 0);
    signal ext_intensity_output : std_logic_vector(15 downto 0);
    
    -- External debug interface
    signal ext_debug_state : std_logic_vector(3 downto 0);
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Direct Instantiation of DUT (REQUIRED for top layer testbenches)
    -- =========================================================================
    DUT: entity WORK.probe_hero8_top
        generic map (
            MODULE_NAME => "probe_hero8_top",
            STATUS_REG_WIDTH => 32,
            MODULE_STATUS_BITS => 16
        )
        port map (
            -- Clock and reset
            clk => clk,
            rst_n => rst_n,
            
            -- External control interface
            ext_enable => ext_enable,
            ext_start => ext_start,
            ext_trigger => ext_trigger,
            
            -- External configuration interface
            ext_probe_selector => ext_probe_selector,
            ext_intensity_index => ext_intensity_index,
            ext_fire_duration => ext_fire_duration,
            ext_cooldown_duration => ext_cooldown_duration,
            
            -- External status interface
            ext_status_register => ext_status_register,
            ext_fault_status => ext_fault_status,
            ext_ready_status => ext_ready_status,
            ext_idle_status => ext_idle_status,
            
            -- External probe output interface
            ext_trigger_output => ext_trigger_output,
            ext_intensity_output => ext_intensity_output,
            
            -- External debug interface
            ext_debug_state => ext_debug_state
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
            while ext_debug_state /= target_state and cycles_waited < max_cycles loop
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
        
        -- Helper procedure to validate status register
        procedure validate_status_register(expected_state : std_logic_vector(3 downto 0); 
                                         expected_fault : std_logic;
                                         expected_ready : std_logic;
                                         expected_idle : std_logic;
                                         test_name : string;
                                         test_num : inout natural) is
            variable test_passed : boolean;
        begin
            test_passed := (ext_status_register(27 downto 24) = expected_state) and
                          (ext_fault_status = expected_fault) and
                          (ext_ready_status = expected_ready) and
                          (ext_idle_status = expected_idle);
            report_test(test_name, test_passed, test_num);
        end procedure;
        
    begin
        -- Test initialization
        write(l, string'("=== ProbeHero8 Top-Level TestBench Started ==="));
        writeline(output, l);
        
        -- =====================================================================
        -- Group 1: External Interface Tests
        -- =====================================================================
        write(l, string'("--- Group 1: External Interface Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior
        rst_n <= '0';
        wait_cycles(5);
        test_passed := (ext_debug_state = "0000"); -- ST_RESET
        report_test("Reset behavior", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: External enable with valid parameters
        rst_n <= '1';
        ext_enable <= '1';
        ext_probe_selector <= "00";  -- Valid probe index
        ext_intensity_index <= "0000101";  -- Valid intensity index (5%)
        ext_fire_duration <= x"0064";      -- Valid fire duration (100 cycles)
        ext_cooldown_duration <= x"03E8";  -- Valid cooldown duration (1000 cycles)
        wait_cycles(5);
        test_passed := (ext_debug_state = "0001"); -- ST_READY
        report_test("External enable with valid parameters", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: External start command
        ext_start <= '1';
        wait_cycles(2);
        ext_start <= '0';
        wait_cycles(2);
        test_passed := (ext_debug_state = "0010"); -- ST_IDLE
        report_test("External start command", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: External trigger detection
        ext_trigger <= '0';
        wait_cycles(2);
        ext_trigger <= '1';
        wait_cycles(2);
        test_passed := (ext_debug_state = "0100"); -- ST_FIRING
        report_test("External trigger detection", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 2: System Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 2: System Integration Tests ---"));
        writeline(output, l);
        
        -- Test 5: Status register integration
        validate_status_register("0100", '0', '0', '0', "Status register integration", test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Output voltage integration
        expected_voltage := x"1000";  -- Expected trigger voltage from default probe config
        actual_voltage := ext_trigger_output;
        test_passed := (actual_voltage = expected_voltage);
        report_test("Output voltage integration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 7: Intensity output integration
        test_passed := (ext_intensity_output /= x"0000"); -- Should be non-zero
        report_test("Intensity output integration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for firing to complete
        wait_cycles(110);  -- Wait for fire duration + some margin
        test_passed := (ext_debug_state = "0101"); -- ST_COOLING
        report_test("Firing sequence completion", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Outputs during cooling
        test_passed := (ext_trigger_output = x"0000" and ext_intensity_output = x"0000");
        report_test("Outputs during cooling", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for cooldown to complete
        wait_cycles(1100);  -- Wait for cooldown duration + some margin
        test_passed := (ext_debug_state = "0011"); -- ST_ARMED
        report_test("Cooldown sequence completion", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 3: Configuration Interface Tests
        -- =====================================================================
        write(l, string'("--- Group 3: Configuration Interface Tests ---"));
        writeline(output, l);
        
        -- Test 9: Different probe configuration
        ext_probe_selector <= "01";  -- Different probe
        wait_cycles(2);
        ext_trigger <= '1';
        wait_cycles(2);
        ext_trigger <= '0';
        wait_cycles(2);
        
        -- Check that different probe produces different trigger voltage
        expected_voltage := x"0800";  -- Expected trigger voltage for probe 1
        actual_voltage := ext_trigger_output;
        test_passed := (actual_voltage = expected_voltage);
        report_test("Different probe configuration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for firing to complete
        wait_cycles(110);
        
        -- Test 10: Intensity configuration
        ext_intensity_index <= "0000000";  -- 0% intensity
        wait_cycles(2);
        ext_trigger <= '1';
        wait_cycles(2);
        ext_trigger <= '0';
        wait_cycles(2);
        
        test_passed := (ext_intensity_output = x"0000"); -- Should be zero for 0% intensity
        report_test("Intensity configuration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for firing to complete
        wait_cycles(110);
        
        -- Test 11: Duration configuration
        ext_fire_duration <= x"0032";      -- Shorter fire duration (50 cycles)
        ext_cooldown_duration <= x"01F4";  -- Shorter cooldown duration (500 cycles)
        wait_cycles(2);
        ext_trigger <= '1';
        wait_cycles(2);
        ext_trigger <= '0';
        wait_cycles(2);
        
        -- Wait for shorter firing to complete
        wait_cycles(60);  -- Wait for shorter fire duration + margin
        test_passed := (ext_debug_state = "0101"); -- ST_COOLING
        report_test("Duration configuration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for shorter cooldown to complete
        wait_cycles(600);  -- Wait for shorter cooldown duration + margin
        test_passed := (ext_debug_state = "0011"); -- ST_ARMED
        report_test("Cooldown duration configuration", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 4: Error Handling Tests
        -- =====================================================================
        write(l, string'("--- Group 4: Error Handling Tests ---"));
        writeline(output, l);
        
        -- Test 12: Invalid probe selection
        ext_probe_selector <= "11";  -- Invalid probe index
        wait_cycles(2);
        test_passed := (ext_debug_state = "1111"); -- ST_HARD_FAULT
        report_test("Invalid probe selection", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Fault status reporting
        test_passed := (ext_fault_status = '1');
        report_test("Fault status reporting", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Reset and restore valid configuration
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        ext_enable <= '1';
        ext_probe_selector <= "00";
        ext_intensity_index <= "0000101";
        ext_fire_duration <= x"0064";
        ext_cooldown_duration <= x"03E8";
        wait_cycles(5);
        ext_start <= '1';
        wait_cycles(2);
        ext_start <= '0';
        wait_cycles(2);
        
        -- Test 14: External disable
        ext_enable <= '0';
        wait_cycles(2);
        test_passed := (ext_debug_state = "0010"); -- ST_IDLE
        report_test("External disable", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Group 5: End-to-End Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 5: End-to-End Integration Tests ---"));
        writeline(output, l);
        
        -- Test 15: Complete firing sequence
        ext_enable <= '1';
        wait_cycles(2);
        ext_trigger <= '1';
        wait_cycles(2);
        ext_trigger <= '0';
        wait_cycles(2);
        
        -- Verify firing state
        test_passed := (ext_debug_state = "0100"); -- ST_FIRING
        report_test("Complete firing sequence - firing state", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Verify outputs during firing
        test_passed := (ext_trigger_output /= x"0000" and ext_intensity_output /= x"0000");
        report_test("Complete firing sequence - outputs", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Wait for complete sequence
        wait_cycles(110);  -- Fire duration
        wait_cycles(1100); -- Cooldown duration
        
        -- Verify return to armed state
        test_passed := (ext_debug_state = "0011"); -- ST_ARMED
        report_test("Complete firing sequence - return to armed", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 16: Status register consistency
        test_passed := (ext_status_register(27 downto 24) = ext_debug_state);
        report_test("Status register consistency", test_passed, test_number);
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
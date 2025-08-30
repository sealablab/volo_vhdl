-- =============================================================================
-- ProbeHero8 Core Testbench
-- =============================================================================
-- 
-- Comprehensive testbench for ProbeHero8 core entity with test coverage for:
-- - Reset and enable/disable sequences
-- - State transitions (IDLE → ARMED → FIRING → COOLING)
-- - Parameter validation (valid/invalid probe selection)
-- - Firing sequence (trigger detection, timing, voltage)
-- - Error handling (invalid parameters → HARDFAULT)
-- - ALARM bit behavior
--
-- Test Structure:
-- - Group 1: Basic functionality tests
-- - Group 2: State transition tests
-- - Group 3: Parameter validation tests
-- - Group 4: Error handling tests
-- - Group 5: Integration tests
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.ENV.ALL;

-- Import ProbeHero8 packages
library WORK;
use WORK.probe_config_pkg.ALL;
use WORK.probe_status_pkg.ALL;

entity probe_hero8_core_tb is
end entity probe_hero8_core_tb;

architecture test of probe_hero8_core_tb is

    -- =========================================================================
    -- Component Declaration (using direct instantiation for consistency)
    -- =========================================================================
    -- Note: Using direct instantiation as recommended for core layer testbenches
    
    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    
    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    -- Control signals
    signal ctrl_enable : std_logic := '0';
    signal ctrl_arm : std_logic := '0';
    signal ctrl_trigger : std_logic := '0';
    
    -- Configuration parameters
    signal cfg_safety_probe_selection : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0) := (others => '0');
    signal cfg_safety_firing_voltage : std_logic_vector(VOLTAGE_WIDTH-1 downto 0) := (others => '0');
    signal cfg_safety_firing_duration : std_logic_vector(TIMING_WIDTH-1 downto 0) := (others => '0');
    signal cfg_safety_cooling_duration : std_logic_vector(TIMING_WIDTH-1 downto 0) := (others => '0');
    signal cfg_safety_enable_auto_arm : std_logic := '0';
    signal cfg_safety_enable_safety_mode : std_logic := '1';
    
    -- Status outputs
    signal stat_current_state : std_logic_vector(3 downto 0);
    signal stat_fault : std_logic;
    signal stat_ready : std_logic;
    signal stat_idle : std_logic;
    signal stat_armed : std_logic;
    signal stat_firing : std_logic;
    signal stat_cooling : std_logic;
    signal stat_status_reg : std_logic_vector(31 downto 0);
    signal stat_alarm_reg : std_logic_vector(ALARM_WIDTH-1 downto 0);
    signal stat_error_code : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0);
    
    -- Probe control outputs
    signal probe_voltage_out : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
    signal probe_enable_out : std_logic;
    signal probe_select_out : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
    
    -- Module status input
    signal module_status : std_logic_vector(15 downto 0) := (others => '0');
    
    -- Debug output
    signal debug_state_machine : std_logic_vector(3 downto 0);
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Device Under Test (DUT) - Direct Instantiation
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
            ctrl_arm => ctrl_arm,
            ctrl_trigger => ctrl_trigger,
            cfg_safety_probe_selection => cfg_safety_probe_selection,
            cfg_safety_firing_voltage => cfg_safety_firing_voltage,
            cfg_safety_firing_duration => cfg_safety_firing_duration,
            cfg_safety_cooling_duration => cfg_safety_cooling_duration,
            cfg_safety_enable_auto_arm => cfg_safety_enable_auto_arm,
            cfg_safety_enable_safety_mode => cfg_safety_enable_safety_mode,
            stat_current_state => stat_current_state,
            stat_fault => stat_fault,
            stat_ready => stat_ready,
            stat_idle => stat_idle,
            stat_armed => stat_armed,
            stat_firing => stat_firing,
            stat_cooling => stat_cooling,
            stat_status_reg => stat_status_reg,
            stat_alarm_reg => stat_alarm_reg,
            stat_error_code => stat_error_code,
            probe_voltage_out => probe_voltage_out,
            probe_enable_out => probe_enable_out,
            probe_select_out => probe_select_out,
            module_status => module_status,
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
    -- Test Helper Procedures (declared within process)
    -- =========================================================================

    -- =========================================================================
    -- Main Test Process
    -- =========================================================================
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        
        -- Test Helper Procedures (declared within process)
        procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
            variable l : line;
        begin
            test_num := test_num + 1;
            write(l, string'("Test "));
            write(l, test_num);
            write(l, string'(": "));
            write(l, test_name);
            if passed then
                write(l, string'(" - PASSED"));
            else
                write(l, string'(" - FAILED"));
            end if;
            writeline(output, l);
        end procedure;
        
        -- Wait for clock cycles
        procedure wait_cycles(cycles : natural) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
        
        -- Check state
        procedure check_state(expected_state : std_logic_vector; test_name : string; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            test_passed := (stat_current_state = expected_state);
            report_test(test_name, test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
        end procedure;
        
        -- Check signal value
        procedure check_signal(signal_name : string; actual : std_logic; expected : std_logic; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            test_passed := (actual = expected);
            report_test(signal_name & " = " & std_logic'image(expected), test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
        end procedure;
        
    begin
        -- Test initialization
        write(l, string'("=== ProbeHero8 Core TestBench Started ==="));
        writeline(output, l);
        
        -- Initialize test environment
        rst_n <= '0';
        ctrl_enable <= '0';
        ctrl_arm <= '0';
        ctrl_trigger <= '0';
        cfg_safety_probe_selection <= std_logic_vector(to_unsigned(0, PROBE_SEL_WIDTH));
        cfg_safety_firing_voltage <= std_logic_vector(to_unsigned(VOLTAGE_DEFAULT, VOLTAGE_WIDTH));
        cfg_safety_firing_duration <= std_logic_vector(to_unsigned(100, TIMING_WIDTH));
        cfg_safety_cooling_duration <= std_logic_vector(to_unsigned(1000, TIMING_WIDTH));
        cfg_safety_enable_auto_arm <= '0';
        cfg_safety_enable_safety_mode <= '1';
        module_status <= (others => '0');
        
        wait_cycles(5);
        
        -- =====================================================================
        -- Group 1: Basic Functionality Tests
        -- =====================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior
        check_state("0010", "Reset to IDLE state", test_number);
        check_signal("stat_fault", stat_fault, '0', test_number);
        check_signal("stat_ready", stat_ready, '0', test_number);
        check_signal("stat_idle", stat_idle, '1', test_number);
        
        -- Test 2: Enable behavior
        rst_n <= '1';
        wait_cycles(2);
        check_state("0010", "Stay in IDLE after reset release", test_number);
        check_signal("stat_ready", stat_ready, '1', test_number);
        
        -- =====================================================================
        -- Group 2: State Transition Tests
        -- =====================================================================
        write(l, string'("--- Group 2: State Transition Tests ---"));
        writeline(output, l);
        
        -- Test 3: IDLE to ARMED transition
        ctrl_enable <= '1';
        ctrl_arm <= '1';
        wait_cycles(2);
        check_state("0011", "IDLE to ARMED transition", test_number);
        check_signal("stat_armed", stat_armed, '1', test_number);
        check_signal("stat_idle", stat_idle, '0', test_number);
        
        -- Test 4: ARMED to FIRING transition
        ctrl_trigger <= '1';
        wait_cycles(2);
        check_state("0100", "ARMED to FIRING transition", test_number);
        check_signal("stat_firing", stat_firing, '1', test_number);
        check_signal("stat_armed", stat_armed, '0', test_number);
        
        -- Test 5: FIRING to COOLING transition (after firing duration)
        ctrl_trigger <= '0';
        wait_cycles(102);  -- Wait for firing duration + 2 cycles
        check_state("0101", "FIRING to COOLING transition", test_number);
        check_signal("stat_cooling", stat_cooling, '1', test_number);
        check_signal("stat_firing", stat_firing, '0', test_number);
        
        -- Test 6: COOLING to IDLE transition (after cooling duration)
        wait_cycles(1002);  -- Wait for cooling duration + 2 cycles
        check_state("0010", "COOLING to IDLE transition", test_number);
        check_signal("stat_idle", stat_idle, '1', test_number);
        check_signal("stat_cooling", stat_cooling, '0', test_number);
        
        -- =====================================================================
        -- Group 3: Parameter Validation Tests
        -- =====================================================================
        write(l, string'("--- Group 3: Parameter Validation Tests ---"));
        writeline(output, l);
        
        -- Test 7: Valid probe selection
        cfg_safety_probe_selection <= std_logic_vector(to_unsigned(3, PROBE_SEL_WIDTH));
        wait_cycles(2);
        check_state("0010", "Valid probe selection - stay in IDLE", test_number);
        check_signal("stat_ready", stat_ready, '1', test_number);
        
        -- Test 8: Invalid probe selection (out of range)
        cfg_safety_probe_selection <= std_logic_vector(to_unsigned(15, PROBE_SEL_WIDTH));  -- > MAX_PROBE_COUNT
        wait_cycles(2);
        check_state("1111", "Invalid probe selection - go to HARDFAULT", test_number);
        check_signal("stat_fault", stat_fault, '1', test_number);
        
        -- Test 9: Invalid voltage (out of range)
        cfg_safety_probe_selection <= std_logic_vector(to_unsigned(0, PROBE_SEL_WIDTH));  -- Reset to valid
        cfg_safety_firing_voltage <= std_logic_vector(to_unsigned(5000, VOLTAGE_WIDTH));  -- > VOLTAGE_MAX
        wait_cycles(2);
        check_state("1111", "Invalid voltage - go to HARDFAULT", test_number);
        check_signal("stat_fault", stat_fault, '1', test_number);
        
        -- =====================================================================
        -- Group 4: Error Handling Tests
        -- =====================================================================
        write(l, string'("--- Group 4: Error Handling Tests ---"));
        writeline(output, l);
        
        -- Test 10: Reset from HARDFAULT
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        cfg_safety_firing_voltage <= std_logic_vector(to_unsigned(VOLTAGE_DEFAULT, VOLTAGE_WIDTH));  -- Reset to valid
        wait_cycles(2);
        check_state("0010", "Reset from HARDFAULT to IDLE", test_number);
        check_signal("stat_fault", stat_fault, '0', test_number);
        
        -- Test 11: Trigger timeout in ARMED state
        ctrl_enable <= '1';
        ctrl_arm <= '1';
        wait_cycles(2);
        check_state("0011", "ARMED state", test_number);
        wait_cycles(10002);  -- Wait for trigger timeout
        check_state("1111", "Trigger timeout - go to HARDFAULT", test_number);
        check_signal("stat_fault", stat_fault, '1', test_number);
        
        -- =====================================================================
        -- Group 5: Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 5: Integration Tests ---"));
        writeline(output, l);
        
        -- Test 12: Complete firing sequence with valid parameters
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        cfg_safety_probe_selection <= std_logic_vector(to_unsigned(2, PROBE_SEL_WIDTH));
        cfg_safety_firing_voltage <= std_logic_vector(to_unsigned(2000, VOLTAGE_WIDTH));
        cfg_safety_firing_duration <= std_logic_vector(to_unsigned(50, TIMING_WIDTH));
        cfg_safety_cooling_duration <= std_logic_vector(to_unsigned(500, TIMING_WIDTH));
        wait_cycles(2);
        
        -- Enable and arm
        ctrl_enable <= '1';
        ctrl_arm <= '1';
        wait_cycles(2);
        check_state("0011", "ARMED with valid config", test_number);
        
        -- Fire
        ctrl_trigger <= '1';
        wait_cycles(2);
        check_state("0100", "FIRING with valid config", test_number);
        check_signal("probe_enable_out", probe_enable_out, '1', test_number);
        test_passed := (probe_voltage_out = std_logic_vector(to_unsigned(2000, VOLTAGE_WIDTH)));
        report_test("Probe voltage output correct", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        test_passed := (probe_select_out = std_logic_vector(to_unsigned(2, PROBE_SEL_WIDTH)));
        report_test("Probe selection output correct", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Complete sequence
        ctrl_trigger <= '0';
        wait_cycles(52);  -- Wait for firing duration + 2 cycles
        check_state("0101", "COOLING after firing", test_number);
        check_signal("probe_enable_out", probe_enable_out, '0', test_number);
        
        wait_cycles(502);  -- Wait for cooling duration + 2 cycles
        check_state("0010", "IDLE after cooling", test_number);
        
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
-- =============================================================================
-- ProbeHero9 Core Testbench
-- =============================================================================
-- 
-- Generated from: PH9-interface-reqs-v1.md
-- Date: 2025-01-27
-- Purpose: Core testbench for ProbeHero9 module validation
-- 
-- This testbench validates the core functionality of ProbeHero9 including
-- reset behavior, input validation, state machine operation, and output control.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

-- Import VOLO packages
use work.probe_hero9_constants_pkg.ALL;
use work.Probe_Config_pkg_PH9.ALL;
use work.Global_Probe_Table_pkg_PH9.ALL;
use work.Moku_Voltage_pkg_PH9.ALL;
use work.PercentLut_pkg_PH9.ALL;

entity probe_hero9_core_tb is
end entity probe_hero9_core_tb;

-- =============================================================================
-- Testbench Architecture
-- =============================================================================

architecture testbench of probe_hero9_core_tb is

    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    
    -- Clock and Reset
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal enable : std_logic := '0';
    signal clk_en : std_logic := '1';
    
    -- Control Signals
    signal trig_in : std_logic := '0';
    
    -- Configuration Inputs
    signal probe_selector_index_in : std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0) := DEFAULT_PROBE_SELECTOR;
    signal intensity_index_in : std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0) := DEFAULT_INTENSITY_INDEX;
    signal fire_duration_in : unsigned(DURATION_WIDTH-1 downto 0) := DEFAULT_FIRE_DURATION;
    signal cooldown_duration_in : unsigned(DURATION_WIDTH-1 downto 0) := DEFAULT_COOLDOWN_DURATION;
    
    -- Outputs
    signal trigger_out : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    signal intensity_out : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    signal probe_status_out : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0);
    
    -- Test Control
    signal test_complete : boolean := false;
    signal test_passed : boolean := true;
    
    -- Clock Period
    constant CLK_PERIOD : time := 10 ns;  -- Units: time (100 MHz clock)

begin

    -- =========================================================================
    -- Device Under Test Instantiation
    -- =========================================================================
    
    dut : entity work.probe_hero9_core
        port map (
            clk => clk,
            reset_n => reset_n,
            enable => enable,
            clk_en => clk_en,
            trig_in => trig_in,
            probe_selector_index_in => probe_selector_index_in,
            intensity_index_in => intensity_index_in,
            fire_duration_in => fire_duration_in,
            cooldown_duration_in => cooldown_duration_in,
            trigger_out => trigger_out,
            intensity_out => intensity_out,
            probe_status_out => probe_status_out
        );
    
    -- =========================================================================
    -- Clock Generation
    -- =========================================================================
    
    clk_gen : process
    begin
        while not test_complete loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;
    
    -- =========================================================================
    -- Test Stimulus Process
    -- =========================================================================
    
    stimulus : process
        variable test_count : natural := 0;
        variable error_count : natural := 0;
        
        -- Helper procedure to check status bits
        procedure check_status_bit(bit_pos : natural; expected : std_logic; test_name : string) is
        begin
            test_count := test_count + 1;
            if probe_status_out(bit_pos) /= expected then
                error_count := error_count + 1;
                report "FAIL: " & test_name & " - Expected bit " & integer'image(bit_pos) & 
                       " = " & std_logic'image(expected) & ", got " & std_logic'image(probe_status_out(bit_pos))
                       severity error;
            else
                report "PASS: " & test_name severity note;
            end if;
        end procedure;
        
        -- Helper procedure to check output values
        procedure check_output(expected_trigger : signed; expected_intensity : signed; test_name : string) is
        begin
            test_count := test_count + 1;
            if trigger_out /= expected_trigger or intensity_out /= expected_intensity then
                error_count := error_count + 1;
                report "FAIL: " & test_name & " - Expected trigger=" & integer'image(to_integer(expected_trigger)) & 
                       ", intensity=" & integer'image(to_integer(expected_intensity)) &
                       ", got trigger=" & integer'image(to_integer(trigger_out)) & 
                       ", intensity=" & integer'image(to_integer(intensity_out))
                       severity error;
            else
                report "PASS: " & test_name severity note;
            end if;
        end procedure;
        
        -- Helper procedure to wait for clock cycles
        procedure wait_cycles(cycles : natural) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
        
    begin
        report "Starting ProbeHero9 Core Testbench" severity note;
        report "=====================================" severity note;
        
        -- =====================================================================
        -- Test 1: Reset Behavior
        -- =====================================================================
        report "Test 1: Reset Behavior" severity note;
        
        -- Apply reset
        reset_n <= '0';
        wait_cycles(5);
        
        -- Check reset behavior
        check_status_bit(STATUS_ARMED_BIT, '0', "Reset - ARMED bit should be 0");
        check_status_bit(STATUS_FIRING_BIT, '0', "Reset - FIRING bit should be 0");
        check_status_bit(STATUS_FIRED_BIT, '0', "Reset - FIRED bit should be 0");
        check_status_bit(STATUS_COOL_BIT, '0', "Reset - COOL bit should be 0");
        check_status_bit(STATUS_FAULT_BIT, '0', "Reset - FAULT bit should be 0");
        check_status_bit(STATUS_ALARM_BIT, '0', "Reset - ALARM bit should be 0");
        
        -- Check outputs are safe
        check_output(SAFE_VOLTAGE_OUTPUT, SAFE_VOLTAGE_OUTPUT, "Reset - Outputs should be safe");
        
        -- Release reset
        reset_n <= '1';
        wait_cycles(2);
        
        -- =====================================================================
        -- Test 2: Input Validation
        -- =====================================================================
        report "Test 2: Input Validation" severity note;
        
        -- Test valid inputs
        probe_selector_index_in <= "00";  -- Valid probe selector
        intensity_index_in <= "0000101";  -- Valid intensity index (5%)
        fire_duration_in <= to_unsigned(100, DURATION_WIDTH);  -- Valid fire duration
        cooldown_duration_in <= to_unsigned(500, DURATION_WIDTH);  -- Valid cooldown duration
        wait_cycles(2);
        
        -- Enable module
        enable <= '1';
        wait_cycles(2);
        
        -- Check ARMED status
        check_status_bit(STATUS_ARMED_BIT, '1', "Valid inputs - Should be ARMED");
        check_status_bit(STATUS_ALARM_BIT, '0', "Valid inputs - No alarm should be set");
        
        -- Test invalid probe selector
        probe_selector_index_in <= "11";  -- Invalid probe selector (out of range)
        wait_cycles(2);
        
        -- Check alarm status
        check_status_bit(STATUS_ALARM_BIT, '1', "Invalid probe selector - Alarm should be set");
        
        -- Restore valid inputs
        probe_selector_index_in <= "00";
        wait_cycles(2);
        
        -- Test invalid intensity index
        intensity_index_in <= "1111111";  -- Invalid intensity index (out of range)
        wait_cycles(2);
        
        -- Check alarm status
        check_status_bit(STATUS_ALARM_BIT, '1', "Invalid intensity index - Alarm should be set");
        
        -- Restore valid inputs
        intensity_index_in <= "0000101";
        wait_cycles(2);
        
        -- =====================================================================
        -- Test 3: Trigger Behavior
        -- =====================================================================
        report "Test 3: Trigger Behavior" severity note;
        
        -- Ensure module is armed
        enable <= '1';
        probe_selector_index_in <= "00";
        intensity_index_in <= "0000101";
        fire_duration_in <= to_unsigned(10, DURATION_WIDTH);  -- Short duration for testing
        cooldown_duration_in <= to_unsigned(5, DURATION_WIDTH);  -- Short cooldown for testing
        wait_cycles(2);
        
        -- Check ARMED status
        check_status_bit(STATUS_ARMED_BIT, '1', "Before trigger - Should be ARMED");
        check_status_bit(STATUS_FIRING_BIT, '0', "Before trigger - Should not be FIRING");
        
        -- Apply trigger
        trig_in <= '1';
        wait_cycles(1);
        trig_in <= '0';
        wait_cycles(1);
        
        -- Check FIRING status
        check_status_bit(STATUS_FIRING_BIT, '1', "After trigger - Should be FIRING");
        check_status_bit(STATUS_FIRED_BIT, '1', "After trigger - FIRED bit should be set");
        
        -- Wait for firing to complete
        wait_cycles(12);  -- Wait longer than fire duration
        
        -- Check COOLING status
        check_status_bit(STATUS_COOL_BIT, '1', "After firing - Should be COOLING");
        check_status_bit(STATUS_FIRING_BIT, '0', "After firing - Should not be FIRING");
        
        -- Wait for cooldown to complete
        wait_cycles(7);  -- Wait longer than cooldown duration
        
        -- Check return to IDLE
        check_status_bit(STATUS_ARMED_BIT, '0', "After cooldown - Should not be ARMED");
        check_status_bit(STATUS_COOL_BIT, '0', "After cooldown - Should not be COOLING");
        check_status_bit(STATUS_FIRED_BIT, '0', "After cooldown - FIRED bit should be cleared");
        
        -- =====================================================================
        -- Test 4: Output Control
        -- =====================================================================
        report "Test 4: Output Control" severity note;
        
        -- Reset and configure for output test
        reset_n <= '0';
        wait_cycles(2);
        reset_n <= '1';
        
        enable <= '1';
        probe_selector_index_in <= "00";
        intensity_index_in <= "0000101";
        fire_duration_in <= to_unsigned(5, DURATION_WIDTH);
        cooldown_duration_in <= to_unsigned(3, DURATION_WIDTH);
        wait_cycles(2);
        
        -- Check outputs are safe before firing
        check_output(SAFE_VOLTAGE_OUTPUT, SAFE_VOLTAGE_OUTPUT, "Before firing - Outputs should be safe");
        
        -- Trigger firing
        trig_in <= '1';
        wait_cycles(1);
        trig_in <= '0';
        wait_cycles(1);
        
        -- Check outputs are active during firing
        -- Note: Actual voltage values depend on probe config and PercentLut
        if trigger_out /= SAFE_VOLTAGE_OUTPUT or intensity_out /= SAFE_VOLTAGE_OUTPUT then
            report "PASS: During firing - Outputs should be active" severity note;
        else
            report "FAIL: During firing - Outputs should be active" severity error;
            error_count := error_count + 1;
        end if;
        
        -- Wait for firing to complete
        wait_cycles(7);
        
        -- Check outputs return to safe levels
        check_output(SAFE_VOLTAGE_OUTPUT, SAFE_VOLTAGE_OUTPUT, "After firing - Outputs should be safe");
        
        -- =====================================================================
        -- Test 5: Disable Behavior
        -- =====================================================================
        report "Test 5: Disable Behavior" severity note;
        
        -- Ensure module is armed
        enable <= '1';
        wait_cycles(2);
        check_status_bit(STATUS_ARMED_BIT, '1', "Before disable - Should be ARMED");
        
        -- Disable module
        enable <= '0';
        wait_cycles(2);
        
        -- Check ARMED status is cleared
        check_status_bit(STATUS_ARMED_BIT, '0', "After disable - Should not be ARMED");
        
        -- =====================================================================
        -- Test Summary
        -- =====================================================================
        
        report "=====================================" severity note;
        report "Test Summary:" severity note;
        report "Total Tests: " & integer'image(test_count) severity note;
        report "Errors: " & integer'image(error_count) severity note;
        
        if error_count = 0 then
            report "ALL TESTS PASSED" severity note;
            test_passed <= true;
        else
            report "TEST FAILED" severity error;
            test_passed <= false;
        end if;
        
        report "SIMULATION DONE" severity note;
        test_complete <= true;
        wait;
        
    end process;

end architecture testbench;
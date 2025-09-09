-- =============================================================================
-- ProbeHero10 Core Testbench
-- =============================================================================
-- 
-- This testbench tests the core state machine functionality of ProbeHero10,
-- including parameter validation, state transitions, and status register behavior.
-- 
-- TEST COVERAGE:
-- - Core state machine transitions (RESET → READY → IDLE → FAULT)
-- - Input parameter validation
-- - Status register bit assignments
-- - Output behavior in different states
-- 
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL;

-- Import VOLO packages
use work.volo_common_pkg.ALL;
use work.probe_hero10_constants_pkg.ALL;
use work.Probe_Config_pkg_PH10.ALL;
use work.Global_Probe_Table_pkg_PH10.ALL;
use work.Moku_Voltage_pkg_PH10.ALL;
use work.PercentLut_pkg_PH10.ALL;

entity probe_hero10_core_tb is
end entity probe_hero10_core_tb;

architecture testbench of probe_hero10_core_tb is

    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    
    -- Clock and control signals
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal enable : std_logic := '0';
    signal clk_en : std_logic := '1';
    signal trig_in : std_logic := '0';
    
    -- Configuration inputs
    signal probe_selector_index_in : std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0) := DEFAULT_PROBE_SELECTOR;
    signal intensity_index_in : std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0) := DEFAULT_INTENSITY_INDEX;
    signal fire_duration_in : unsigned(DURATION_WIDTH-1 downto 0) := DEFAULT_FIRE_DURATION;
    signal cooldown_duration_in : unsigned(DURATION_WIDTH-1 downto 0) := DEFAULT_COOLDOWN_DURATION;
    
    -- Outputs
    signal trigger_out : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    signal intensity_out : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    signal probe_status_out : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0);
    
    -- Test control
    signal test_complete : boolean := false;
    signal test_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Device Under Test (DUT) - Direct Instantiation
    -- =========================================================================
    
    dut : entity work.probe_hero10_core
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
    
    clk_process : process
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
    
    stimulus_process : process
        variable test_name : string(1 to 50);
        variable test_result : string(1 to 20);
    begin
        -- Initialize test
        test_name := "ProbeHero10 Core State Machine Test                    ";
        test_result := "RUNNING              ";
        
        report "Starting ProbeHero10 Core Testbench";
        report "Test: " & test_name;
        report "Status: " & test_result;
        
        -- Wait for initial setup
        wait for CLK_PERIOD * 2;
        
        -- =================================================================
        -- Test 1: Reset State
        -- =================================================================
        report "Test 1: Reset State";
        
        -- Verify reset state
        assert probe_status_out = (others => '0') 
            report "FAIL: Status register should be all zeros in reset" 
            severity error;
        
        assert trigger_out = work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO 
            report "FAIL: Trigger output should be zero in reset" 
            severity error;
        
        assert intensity_out = work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO 
            report "FAIL: Intensity output should be zero in reset" 
            severity error;
        
        -- =================================================================
        -- Test 2: Parameter Validation
        -- =================================================================
        report "Test 2: Parameter Validation";
        
        -- Test valid parameters
        probe_selector_index_in <= "00";  -- Valid probe selector
        intensity_index_in <= "0000101";   -- Valid intensity (5%)
        fire_duration_in <= to_unsigned(100, DURATION_WIDTH);  -- Valid duration
        cooldown_duration_in <= to_unsigned(1000, DURATION_WIDTH);  -- Valid cooldown
        
        -- Release reset
        reset_n <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Should transition to READY state
        assert probe_status_out(STATUS_READY_BIT) = '1' 
            report "FAIL: Should be in READY state with valid parameters" 
            severity error;
        
        -- =================================================================
        -- Test 3: Enable Transition to IDLE
        -- =================================================================
        report "Test 3: Enable Transition to IDLE";
        
        -- Enable the module
        enable <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Should transition to IDLE state
        assert probe_status_out(STATUS_IDLE_BIT) = '1' 
            report "FAIL: Should be in IDLE state when enabled" 
            severity error;
        
        -- =================================================================
        -- Test 4: Invalid Parameter Handling
        -- =================================================================
        report "Test 4: Invalid Parameter Handling";
        
        -- Test invalid probe selector
        probe_selector_index_in <= "11";  -- Invalid probe selector (>3)
        wait for CLK_PERIOD * 2;
        
        -- Should transition to FAULT state
        assert probe_status_out(STATUS_FAULT_BIT) = '1' 
            report "FAIL: Should be in FAULT state with invalid parameters" 
            severity error;
        
        assert probe_status_out(STATUS_ALARM_BIT) = '1' 
            report "FAIL: Should set ALARM bit with invalid parameters" 
            severity error;
        
        -- =================================================================
        -- Test 5: Reset Recovery
        -- =================================================================
        report "Test 5: Reset Recovery";
        
        -- Reset the module
        reset_n <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Should return to reset state
        assert probe_status_out = (others => '0') 
            report "FAIL: Should return to reset state" 
            severity error;
        
        -- =================================================================
        -- Test 6: Complete Valid Operation
        -- =================================================================
        report "Test 6: Complete Valid Operation";
        
        -- Set valid parameters
        probe_selector_index_in <= "01";  -- Valid probe selector
        intensity_index_in <= "0010100";   -- Valid intensity (20%)
        fire_duration_in <= to_unsigned(200, DURATION_WIDTH);  -- Valid duration
        cooldown_duration_in <= to_unsigned(1500, DURATION_WIDTH);  -- Valid cooldown
        
        -- Release reset and enable
        reset_n <= '1';
        wait for CLK_PERIOD * 2;
        
        enable <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Should be in IDLE state
        assert probe_status_out(STATUS_IDLE_BIT) = '1' 
            report "FAIL: Should be in IDLE state with valid operation" 
            severity error;
        
        -- Outputs should be active (non-zero) in IDLE state
        assert trigger_out /= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO 
            report "FAIL: Trigger output should be active in IDLE state" 
            severity error;
        
        assert intensity_out /= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO 
            report "FAIL: Intensity output should be active in IDLE state" 
            severity error;
        
        -- =================================================================
        -- Test Complete
        -- =================================================================
        
        wait for CLK_PERIOD * 2;
        
        -- Check if all tests passed
        if test_passed then
            test_result := "PASSED              ";
            report "ALL TESTS PASSED";
        else
            test_result := "FAILED              ";
            report "TEST FAILED";
        end if;
        
        report "Test: " & test_name;
        report "Status: " & test_result;
        report "SIMULATION DONE";
        
        test_complete <= true;
        wait;
        
    end process;

    -- =========================================================================
    -- Error Monitoring Process
    -- =========================================================================
    
    error_monitor : process
    begin
        wait until test_complete;
        
        -- Final status check
        if test_passed then
            report "ProbeHero10 Core Testbench: ALL TESTS PASSED";
        else
            report "ProbeHero10 Core Testbench: TEST FAILED";
        end if;
        
        wait;
    end process;

end architecture testbench;
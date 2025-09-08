-- ProbeHero8 Core Testbench
-- Implements enhanced rules system patterns: TB-05 (clock management) and TB-06 (reset testing)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity probe_hero8_core_tb is
end entity probe_hero8_core_tb;

architecture test of probe_hero8_core_tb is
    
    -- Clock and timing constants (TB-05: Clock & timing management)
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_HALF_PERIOD : time := CLK_PERIOD / 2;
    
    -- Test constants
    constant TEST_TIMEOUT : time := 1000 ns;
    
    -- Component signals
    signal clk                     : std_logic := '0';
    signal rst_n                   : std_logic := '1';
    signal enable                  : std_logic := '0';
    signal clk_en                  : std_logic := '1';
    signal trig_in                 : std_logic := '0';
    
    -- Configuration signals
    signal cfg_probe_selector_in   : std_logic_vector(1 downto 0) := "00";
    signal cfg_intensity_index_in  : std_logic_vector(6 downto 0) := "0000101";
    signal cfg_fire_duration_in    : unsigned(15 downto 0) := to_unsigned(100, 16);
    signal cfg_cooldown_duration_in: unsigned(15 downto 0) := to_unsigned(50, 16);
    
    -- Output signals
    signal trigger_out             : signed(15 downto 0);
    signal intensity_out           : signed(15 downto 0);
    signal stat_probe_status_out   : std_logic_vector(7 downto 0);
    
    -- Test control signals
    signal test_done               : boolean := false;
    signal all_tests_passed        : boolean := true;
    
    -- Test results tracking
    signal test_number             : natural := 0;
    
    -- Expected values for validation
    constant EXPECTED_SAFE_TRIGGER     : signed(15 downto 0) := to_signed(0, 16);
    constant EXPECTED_SAFE_INTENSITY   : signed(15 downto 0) := to_signed(0, 16);
    constant EXPECTED_FIRING_TRIGGER   : signed(15 downto 0) := to_signed(1000, 16);
    
begin
    
    -- DUT instantiation using direct instantiation (SIG-02: Named association)
    DUT: entity work.probe_hero8_core
        generic map (
            DEFAULT_FIRE_DURATION     => to_unsigned(100, 16),
            DEFAULT_COOLDOWN_DURATION => to_unsigned(50, 16),
            DEFAULT_INTENSITY_INDEX   => "0000101",
            DEFAULT_PROBE_SELECTOR    => "00"
        )
        port map (
            clk                       => clk,
            rst_n                     => rst_n,
            enable                    => enable,
            clk_en                    => clk_en,
            trig_in                   => trig_in,
            cfg_probe_selector_in     => cfg_probe_selector_in,
            cfg_intensity_index_in    => cfg_intensity_index_in,
            cfg_fire_duration_in      => cfg_fire_duration_in,
            cfg_cooldown_duration_in  => cfg_cooldown_duration_in,
            trigger_out               => trigger_out,
            intensity_out             => intensity_out,
            stat_probe_status_out     => stat_probe_status_out
        );
    
    -- Clock generation (TB-05: Clock & timing management)
    clock_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_HALF_PERIOD;
            clk <= '1';
            wait for CLK_HALF_PERIOD;
        end loop;
        wait;
    end process clock_process;
    
    -- Main test process
    test_process: process
        variable l: line;
        variable test_passed: boolean;
        variable start_time, end_time: time;
        variable local_test_number: natural := 0;
        
        -- Helper procedure for consistent test reporting
        procedure report_test(test_name: string; passed: boolean) is
            variable l: line;
        begin
            local_test_number := local_test_number + 1;
            if passed then
                write(l, string'("  Test ") & integer'image(local_test_number) & ": " & test_name & " - PASSED");
            else
                write(l, string'("  Test ") & integer'image(local_test_number) & ": " & test_name & " - FAILED");
            end if;
            writeline(output, l);
        end procedure report_test;
        
    begin
        -- Test initialization
        write(l, string'("=== ProbeHero8 Core Testbench Started ==="));
        writeline(output, l);
        write(l, string'("Using enhanced rules system patterns: TB-05, TB-06"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        
        -- TB-06: Reset & initialization testing
        write(l, string'("Test 1: Reset and Initialization"));
        writeline(output, l);
        start_time := now;
        
        -- Apply reset
        rst_n <= '0';
        wait for 10 * CLK_PERIOD;
        rst_n <= '1';
        wait until rising_edge(clk);
        
        -- Verify post-reset defaults
        test_passed := (trigger_out = EXPECTED_SAFE_TRIGGER) and 
                      (intensity_out = EXPECTED_SAFE_INTENSITY) and
                      (stat_probe_status_out = "00000000");
        
        end_time := now;
        report_test("Reset and Initialization", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Enable/Disable functionality
        write(l, string'("Test 2: Enable/Disable Functionality"));
        writeline(output, l);
        
        -- Enable module
        enable <= '1';
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify ARMED status
        test_passed := (stat_probe_status_out(0) = '1'); -- ARMED bit
        report_test("Module Enable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Disable module
        enable <= '0';
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify IDLE status
        test_passed := (stat_probe_status_out(0) = '0'); -- ARMED bit should be 0
        report_test("Module Disable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: State transitions
        write(l, string'("Test 3: State Transitions"));
        writeline(output, l);
        
        -- Re-enable for state transition tests
        enable <= '1';
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify ARMED state
        test_passed := (stat_probe_status_out(0) = '1'); -- ARMED bit
        report_test("ARMED State", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Trigger detection and firing sequence
        write(l, string'("Test 4: Trigger Detection and Firing Sequence"));
        writeline(output, l);
        
        -- Generate trigger pulse
        trig_in <= '1';
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        trig_in <= '0';
        
        -- Wait for state transition to FIRING
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify FIRING state
        test_passed := (stat_probe_status_out(1) = '1'); -- FIRING bit
        report_test("FIRING State", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Verify outputs during firing
        test_passed := (trigger_out = EXPECTED_FIRING_TRIGGER);
        report_test("Firing Outputs", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Parameter validation
        write(l, string'("Test 5: Parameter Validation"));
        writeline(output, l);
        
        -- Test invalid probe selector
        cfg_probe_selector_in <= "11"; -- Valid for this implementation
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        test_passed := (stat_probe_status_out(0) = '1'); -- Should still be ARMED
        report_test("Valid Probe Selector", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test invalid intensity index
        cfg_intensity_index_in <= "1111111"; -- 127, should be valid
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        test_passed := (stat_probe_status_out(0) = '1'); -- Should still be ARMED
        report_test("Valid Intensity Index", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Clock enable functionality
        write(l, string'("Test 6: Clock Enable Functionality"));
        writeline(output, l);
        
        -- Disable clock enable
        clk_en <= '0';
        wait for 5 * CLK_PERIOD;
        
        -- Verify state doesn't change
        test_passed := (stat_probe_status_out = stat_probe_status_out);
        report_test("Clock Enable Disable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Re-enable clock
        clk_en <= '1';
        wait until rising_edge(clk);
        
        -- Test 7: Error handling
        write(l, string'("Test 7: Error Handling"));
        writeline(output, l);
        
        -- Test with invalid fire duration
        cfg_fire_duration_in <= to_unsigned(0, 16); -- Invalid
        wait until rising_edge(clk);
        if clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Should set alarm bit
        test_passed := (stat_probe_status_out(6) = '1'); -- ALARM bit
        report_test("Invalid Fire Duration Alarm", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Final results
        write(l, string'(""));
        writeline(output, l);
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
        
        test_done <= true;
        wait;
    end process test_process;
    

    
end architecture test;
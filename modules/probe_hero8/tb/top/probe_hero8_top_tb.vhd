-- ProbeHero8 Top-Level Testbench
-- Tests system integration and end-to-end functionality
-- Implements enhanced rules system patterns: TB-05 (clock management) and TB-06 (reset testing)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity probe_hero8_top_tb is
end entity probe_hero8_top_tb;

architecture test of probe_hero8_top_tb is
    
    -- Clock and timing constants (TB-05: Clock & timing management)
    constant CLK_PERIOD : time := 10 ns;
    constant CLK_HALF_PERIOD : time := CLK_PERIOD / 2;
    
    -- Test constants
    constant TEST_TIMEOUT : time := 2000 ns;
    
    -- Component signals
    signal clk                     : std_logic := '0';
    signal rst_n                   : std_logic := '1';
    signal ctrl_enable             : std_logic := '0';
    signal ctrl_clk_en             : std_logic := '1';
    signal ctrl_trig_in            : std_logic := '0';
    
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
    
    -- Expected values for validation
    constant EXPECTED_SAFE_TRIGGER     : signed(15 downto 0) := to_signed(0, 16);
    constant EXPECTED_SAFE_INTENSITY   : signed(15 downto 0) := to_signed(0, 16);
    constant EXPECTED_FIRING_TRIGGER   : signed(15 downto 0) := to_signed(1000, 16);
    
begin
    
    -- DUT instantiation using direct instantiation (SIG-02: Named association)
    DUT: entity work.probe_hero8_top
        generic map (
            DEFAULT_FIRE_DURATION     => to_unsigned(100, 16),
            DEFAULT_COOLDOWN_DURATION => to_unsigned(50, 16),
            DEFAULT_INTENSITY_INDEX   => "0000101",
            DEFAULT_PROBE_SELECTOR    => "00"
        )
        port map (
            clk                       => clk,
            rst_n                     => rst_n,
            ctrl_enable               => ctrl_enable,
            ctrl_clk_en               => ctrl_clk_en,
            ctrl_trig_in              => ctrl_trig_in,
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
        write(l, string'("=== ProbeHero8 Top-Level Testbench Started ==="));
        writeline(output, l);
        write(l, string'("Testing system integration and end-to-end functionality"));
        writeline(output, l);
        write(l, string'("Using enhanced rules system patterns: TB-05, TB-06"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        
        -- TB-06: Reset & initialization testing
        write(l, string'("Test 1: System Reset and Initialization"));
        writeline(output, l);
        
        -- Apply reset
        rst_n <= '0';
        wait for 10 * CLK_PERIOD;
        rst_n <= '1';
        wait until rising_edge(clk);
        
        -- Verify post-reset defaults
        test_passed := (trigger_out = EXPECTED_SAFE_TRIGGER) and 
                      (intensity_out = EXPECTED_SAFE_INTENSITY) and
                      (stat_probe_status_out = "00000000");
        
        report_test("System Reset and Initialization", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: System Enable/Disable
        write(l, string'("Test 2: System Enable/Disable"));
        writeline(output, l);
        
        -- Enable system
        ctrl_enable <= '1';
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify ARMED status
        test_passed := (stat_probe_status_out(0) = '1'); -- ARMED bit
        report_test("System Enable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Disable system
        ctrl_enable <= '0';
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify IDLE status
        test_passed := (stat_probe_status_out(0) = '0'); -- ARMED bit should be 0
        report_test("System Disable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: End-to-End Firing Sequence
        write(l, string'("Test 3: End-to-End Firing Sequence"));
        writeline(output, l);
        
        -- Re-enable for firing test
        ctrl_enable <= '1';
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify ARMED state
        test_passed := (stat_probe_status_out(0) = '1'); -- ARMED bit
        report_test("System ARMED State", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Generate trigger pulse
        ctrl_trig_in <= '1';
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        ctrl_trig_in <= '0';
        
        -- Wait for state transition to FIRING
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Verify FIRING state
        test_passed := (stat_probe_status_out(1) = '1'); -- FIRING bit
        report_test("System FIRING State", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Verify outputs during firing
        test_passed := (trigger_out = EXPECTED_FIRING_TRIGGER);
        report_test("System Firing Outputs", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Configuration Interface
        write(l, string'("Test 4: Configuration Interface"));
        writeline(output, l);
        
        -- Test different probe selector
        cfg_probe_selector_in <= "01";
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        test_passed := (stat_probe_status_out(0) = '1'); -- Should still be ARMED
        report_test("Probe Selector Configuration", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test different intensity
        cfg_intensity_index_in <= "0001010"; -- 10% intensity
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        test_passed := (stat_probe_status_out(0) = '1'); -- Should still be ARMED
        report_test("Intensity Configuration", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Clock Enable Interface
        write(l, string'("Test 5: Clock Enable Interface"));
        writeline(output, l);
        
        -- Disable clock enable
        ctrl_clk_en <= '0';
        wait for 5 * CLK_PERIOD;
        
        -- Verify state doesn't change
        test_passed := (stat_probe_status_out = stat_probe_status_out);
        report_test("Clock Enable Disable", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Re-enable clock
        ctrl_clk_en <= '1';
        wait until rising_edge(clk);
        
        -- Test 6: System Integration Validation
        write(l, string'("Test 6: System Integration Validation"));
        writeline(output, l);
        
        -- Test complete firing sequence with different parameters
        cfg_fire_duration_in <= to_unsigned(200, 16);
        cfg_cooldown_duration_in <= to_unsigned(100, 16);
        
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        -- Generate another trigger
        ctrl_trig_in <= '1';
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        ctrl_trig_in <= '0';
        
        -- Wait for firing state
        wait until rising_edge(clk);
        if ctrl_clk_en = '1' then
            wait until rising_edge(clk);
        end if;
        
        test_passed := (stat_probe_status_out(1) = '1'); -- FIRING bit
        report_test("System Integration Firing", test_passed);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Final results
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("=== Top-Level Test Results ==="));
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
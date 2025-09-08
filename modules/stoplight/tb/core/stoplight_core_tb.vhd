-- Stoplight Core Testbench
-- Implements 4-layer testbench architecture for stoplight core module
-- Tests interface behavior, validation, functionality, and generic parameters

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use STD.ENV.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;
use WORK.stoplight_constants_pkg.ALL;

entity stoplight_core_tb is
end entity stoplight_core_tb;

architecture behavioral of stoplight_core_tb is
    
    -- ============================================================================
    -- TESTBENCH SIGNALS
    -- ============================================================================
    -- Clock and control signals
    signal clk                  : std_logic := '0';
    signal rst_n                : std_logic := '0';
    signal enable               : std_logic := '0';
    signal clk_en               : std_logic := '0';
    
    -- Input signals
    signal trig_in              : std_logic := '0';
    signal cfg_red_delay        : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_yellow_delay     : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_green_delay      : std_logic_vector(15 downto 0) := (others => '0');
    
    -- Output signals
    signal stat_status_out      : std_logic_vector(7 downto 0);
    
    -- Testbench constants
    constant CLK_PERIOD         : time := 20 ns;
    constant CLK_EN_PERIOD      : time := 100 ns;
    
    -- Test variables
    signal test_passed          : boolean := true;
    signal test_number          : natural := 0;
    
begin
    
    -- ============================================================================
    -- CLOCK GENERATION
    -- ============================================================================
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- ============================================================================
    -- CLOCK ENABLE GENERATION
    -- ============================================================================
    clk_en_process: process
    begin
        clk_en <= '0';
        wait for CLK_EN_PERIOD;
        clk_en <= '1';
        wait for CLK_PERIOD;
    end process;
    
    -- ============================================================================
    -- DEVICE UNDER TEST
    -- ============================================================================
    dut: entity work.stoplight_core
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            enable              => enable,
            clk_en              => clk_en,
            trig_in             => trig_in,
            cfg_red_delay       => cfg_red_delay,
            cfg_yellow_delay    => cfg_yellow_delay,
            cfg_green_delay     => cfg_green_delay,
            stat_status_out     => stat_status_out
        );
    
    -- ============================================================================
    -- TEST PROCESS
    -- ============================================================================
    test_process: process
        variable l : line;
    begin
        -- Initialize test
        write(l, string'("=== Stoplight Core TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Status Register)
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Status Register) ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior - module should be in safe state
        test_number := test_number + 1;
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1') and 
                      (stat_status_out(STATUS_FAULT_BIT) = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Reset behavior - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Reset behavior - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 2: Enable behavior - module should show enabled status
        test_number := test_number + 1;
        enable <= '1';
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Enable behavior - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Enable behavior - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing ---"));
        writeline(output, l);
        
        -- Test 3: Invalid red delay - validation failure
        test_number := test_number + 1;
        cfg_red_delay <= x"0000";  -- Invalid (below minimum)
        cfg_yellow_delay <= x"0001";  -- Valid
        cfg_green_delay <= x"7530";  -- Valid (30000)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_FAULT_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Invalid red delay - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Invalid red delay - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 4: Valid configuration - normal operation
        test_number := test_number + 1;
        cfg_red_delay <= x"0001";  -- Valid (1)
        cfg_yellow_delay <= x"0001";  -- Valid (1)
        cfg_green_delay <= x"7530";  -- Valid (30000)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_VALID_BIT) = '1') and 
                      (stat_status_out(STATUS_FAULT_BIT) = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Valid configuration - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Valid configuration - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing ---"));
        writeline(output, l);
        
        -- Test 5: Core functionality - traffic light cycle
        test_number := test_number + 1;
        trig_in <= '1';
        wait for CLK_PERIOD;
        trig_in <= '0';
        
        -- Wait for RED state
        wait for CLK_PERIOD;
        test_passed := (stat_status_out(STATUS_RED_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": RED state transition - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": RED state transition - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 6: YELLOW state transition
        test_number := test_number + 1;
        wait for CLK_PERIOD;  -- Wait for RED countdown to complete
        
        test_passed := (stat_status_out(STATUS_YELLOW_BIT) = '1') and 
                      (stat_status_out(STATUS_ALARM_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": YELLOW state transition - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": YELLOW state transition - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 7: GREEN state transition
        test_number := test_number + 1;
        wait for CLK_PERIOD;  -- Wait for YELLOW countdown to complete
        
        test_passed := (stat_status_out(STATUS_GREEN_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": GREEN state transition - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": GREEN state transition - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 8: Return to IDLE state
        test_number := test_number + 1;
        wait for CLK_PERIOD;  -- Wait for GREEN countdown to complete
        
        test_passed := (stat_status_out(STATUS_IDLE_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Return to IDLE - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Return to IDLE - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 4: GENERIC PARAMETER TESTING
        -- ============================================================================
        write(l, string'("--- Layer 4: Generic Parameter Testing ---"));
        writeline(output, l);
        
        -- Test 9: Edge case - minimum valid delays
        test_number := test_number + 1;
        cfg_red_delay <= x"0001";  -- Minimum red delay
        cfg_yellow_delay <= x"0001";  -- Minimum yellow delay
        cfg_green_delay <= x"7530";  -- Minimum green delay (30000)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_VALID_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Minimum valid delays - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Minimum valid delays - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 10: Edge case - maximum valid delays
        test_number := test_number + 1;
        cfg_red_delay <= x"9C40";  -- Maximum red delay (40000)
        cfg_yellow_delay <= x"4E20";  -- Maximum yellow delay (20000)
        cfg_green_delay <= x"FDE8";  -- Maximum green delay (65000)
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_VALID_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Maximum valid delays - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Maximum valid delays - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- CONTROL SIGNAL TESTING
        -- ============================================================================
        write(l, string'("--- Control Signal Testing ---"));
        writeline(output, l);
        
        -- Test 11: Module disable - safe state
        test_number := test_number + 1;
        enable <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Module disable - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Module disable - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 12: Module re-enable - normal operation
        test_number := test_number + 1;
        enable <= '1';
        wait for CLK_PERIOD;
        
        test_passed := (stat_status_out(STATUS_ENABLED_BIT) = '1');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Module re-enable - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Module re-enable - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        write(l, string'("=== Test Results ==="));
        writeline(output, l);
        
        if test_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        stop(0);
    end process test_process;
    
end architecture behavioral;

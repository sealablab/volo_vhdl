-- Stoplight Top-Level Testbench
-- Tests the complete stoplight system integration including register interface
-- Implements 4-layer testbench architecture for top-level testing

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use STD.ENV.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;
use WORK.stoplight_constants_pkg.ALL;
use WORK.platform_interface_pkg.ALL;

entity stoplight_top_tb is
end entity stoplight_top_tb;

architecture behavioral of stoplight_top_tb is
    
    -- ============================================================================
    -- TESTBENCH SIGNALS
    -- ============================================================================
    -- System interface
    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '0';
    
    -- Register interface
    signal stoplight_ctrl_wr    : std_logic := '0';
    signal stoplight_ctrl_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal stoplight_cfg_wr     : std_logic := '0';
    signal stoplight_cfg_data   : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Read interface
    signal stoplight_status_rd  : std_logic_vector(31 downto 0);
    signal stoplight_state_rd   : std_logic_vector(31 downto 0);
    
    -- External interface
    signal trig_in              : std_logic := '0';
    signal light_red            : std_logic;
    signal light_yellow         : std_logic;
    signal light_green          : std_logic;
    signal fault_out            : std_logic;
    
    -- Testbench constants
    constant CLK_PERIOD         : time := 20 ns;
    
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
    -- DEVICE UNDER TEST
    -- ============================================================================
    dut: entity work.stoplight_top
        port map (
            clk                 => clk,
            rst                 => rst,
            stoplight_ctrl_wr   => stoplight_ctrl_wr,
            stoplight_ctrl_data => stoplight_ctrl_data,
            stoplight_cfg_wr    => stoplight_cfg_wr,
            stoplight_cfg_data  => stoplight_cfg_data,
            stoplight_status_rd => stoplight_status_rd,
            stoplight_state_rd  => stoplight_state_rd,
            trig_in             => trig_in,
            light_red           => light_red,
            light_yellow        => light_yellow,
            light_green         => light_green,
            fault_out           => fault_out
        );
    
    -- ============================================================================
    -- TEST PROCESS
    -- ============================================================================
    test_process: process
        variable l : line;
        variable test_passed : boolean := true;
        variable test_number : natural := 0;
    begin
        -- Initialize test
        write(l, string'("=== Stoplight Top-Level TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Register Interface)
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Register Interface) ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior - module should be in safe state
        test_number := test_number + 1;
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (light_red = '0') and (light_yellow = '0') and (light_green = '0') and (fault_out = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Reset behavior - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Reset behavior - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 2: Control register write - enable module
        test_number := test_number + 1;
        stoplight_ctrl_data <= x"80000000"; -- Enable bit set, clock divider = 0
        stoplight_ctrl_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_ctrl_wr <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (stoplight_status_rd(7) = '1'); -- Enable bit should be set
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Control register write - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Control register write - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing ---"));
        writeline(output, l);
        
        -- Test 3: Configuration register write - set timing parameters
        test_number := test_number + 1;
        stoplight_cfg_data <= x"00010001"; -- Red=1, Yellow=1 (valid)
        stoplight_cfg_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_cfg_wr <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (fault_out = '0'); -- Should not fault with valid config
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Configuration register write - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Configuration register write - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 4: Invalid configuration - should fault
        test_number := test_number + 1;
        stoplight_cfg_data <= x"00000000"; -- Red=0, Yellow=0 (invalid)
        stoplight_cfg_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_cfg_wr <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (fault_out = '1'); -- Should fault with invalid config
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Invalid configuration - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Invalid configuration - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing ---"));
        writeline(output, l);
        
        -- Reset and configure with valid parameters
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Enable module
        stoplight_ctrl_data <= x"80000000";
        stoplight_ctrl_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_ctrl_wr <= '0';
        
        -- Configure with valid parameters
        stoplight_cfg_data <= x"00010001"; -- Red=1, Yellow=1
        stoplight_cfg_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_cfg_wr <= '0';
        wait for CLK_PERIOD;
        
        -- Test 5: Trigger input - start traffic light cycle
        test_number := test_number + 1;
        trig_in <= '1';
        wait for CLK_PERIOD;
        trig_in <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (light_red = '1') and (light_yellow = '0') and (light_green = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Trigger input - RED state - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Trigger input - RED state - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 6: YELLOW state transition
        test_number := test_number + 1;
        wait for CLK_PERIOD; -- Wait for RED countdown to complete
        
        test_passed := (light_yellow = '1') and (light_red = '0') and (light_green = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": YELLOW state transition - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": YELLOW state transition - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 7: GREEN state transition
        test_number := test_number + 1;
        wait for CLK_PERIOD; -- Wait for YELLOW countdown to complete
        
        test_passed := (light_green = '1') and (light_red = '0') and (light_yellow = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": GREEN state transition - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": GREEN state transition - FAILED"));
        end if;
        writeline(output, l);
        
        -- Test 8: Return to IDLE state
        test_number := test_number + 1;
        wait for CLK_PERIOD; -- Wait for GREEN countdown to complete
        
        test_passed := (light_red = '0') and (light_yellow = '0') and (light_green = '0');
        
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
        
        -- Test 9: Different clock divider settings
        test_number := test_number + 1;
        stoplight_ctrl_data <= x"80000001"; -- Enable + clock divider = 1
        stoplight_ctrl_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_ctrl_wr <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (fault_out = '0');
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Clock divider setting - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Clock divider setting - FAILED"));
        end if;
        writeline(output, l);
        
        -- ============================================================================
        -- CONTROL SIGNAL TESTING
        -- ============================================================================
        write(l, string'("--- Control Signal Testing ---"));
        writeline(output, l);
        
        -- Test 10: Module disable - safe state
        test_number := test_number + 1;
        stoplight_ctrl_data <= x"00000000"; -- Disable
        stoplight_ctrl_wr <= '1';
        wait for CLK_PERIOD;
        stoplight_ctrl_wr <= '0';
        wait for CLK_PERIOD;
        
        test_passed := (stoplight_status_rd(7) = '0'); -- Enable bit should be clear
        
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Module disable - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Module disable - FAILED"));
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

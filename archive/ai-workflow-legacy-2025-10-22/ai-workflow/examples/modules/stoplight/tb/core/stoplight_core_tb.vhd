-- =============================================================================
-- File: stoplight_core_tb.vhd
-- Entity: stoplight_core_tb
-- Description: Testbench for the Stoplight core module
-- Author: AI Generated
-- Date: Generated from stoplight-interface-requirements-r1.md
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import constants package
library work;
use work.stoplight_constants_pkg.all;

entity stoplight_core_tb is
end entity stoplight_core_tb;

-- =============================================================================
-- Architecture
-- =============================================================================

architecture tb of stoplight_core_tb is

    -- Component declaration
    component stoplight_core is
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            enable      : in  std_logic;
            clk_en      : in  std_logic;
            trig_in     : in  std_logic;
            cfg_red_delay    : in  std_logic_vector(15 downto 0);
            cfg_yellow_delay : in  std_logic_vector(15 downto 0);
            cfg_green_delay  : in  std_logic_vector(15 downto 0);
            stat_status_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Test signals
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal enable      : std_logic := '0';
    signal clk_en      : std_logic := '1';
    signal trig_in     : std_logic := '0';
    signal cfg_red_delay    : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_yellow_delay : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_green_delay  : std_logic_vector(15 downto 0) := (others => '0');
    signal stat_status_out : std_logic_vector(7 downto 0);

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Test counters
    signal test_count : integer := 0;
    signal error_count : integer := 0;

begin

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
    -- DUT Instantiation
    -- =========================================================================
    
    dut : stoplight_core
        port map (
            clk         => clk,
            rst_n       => rst_n,
            enable      => enable,
            clk_en      => clk_en,
            trig_in     => trig_in,
            cfg_red_delay    => cfg_red_delay,
            cfg_yellow_delay => cfg_yellow_delay,
            cfg_green_delay  => cfg_green_delay,
            stat_status_out => stat_status_out
        );

    -- =========================================================================
    -- Test Stimulus
    -- =========================================================================
    
    stimulus : process
    begin
        -- Initialize test
        test_count <= 0;
        error_count <= 0;
        
        -- Test 1: Reset behavior
        test_count <= test_count + 1;
        report "Test " & integer'image(test_count) & ": Reset behavior";
        
        rst_n <= '0';
        enable <= '0';
        cfg_red_delay <= std_logic_vector(to_unsigned(5, 16));
        cfg_yellow_delay <= std_logic_vector(to_unsigned(3, 16));
        cfg_green_delay <= std_logic_vector(to_unsigned(35000, 16));
        
        wait for 5 * CLK_PERIOD;
        
        -- Check reset state
        if stat_status_out(STAT_IDLE_BIT) = '1' then
            report "PASS: Reset state correctly set IDLE bit";
        else
            report "FAIL: Reset state did not set IDLE bit";
            error_count <= error_count + 1;
        end if;
        
        -- Test 2: Valid configuration and enable
        test_count <= test_count + 1;
        report "Test " & integer'image(test_count) & ": Valid configuration and enable";
        
        rst_n <= '1';
        enable <= '1';
        
        wait for 2 * CLK_PERIOD;
        
        -- Check that we transition to RED state
        if stat_status_out(STAT_RED_BIT) = '1' and stat_status_out(STAT_VALID_BIT) = '1' then
            report "PASS: Valid configuration transitioned to RED state";
        else
            report "FAIL: Valid configuration did not transition to RED state";
            error_count <= error_count + 1;
        end if;
        
        -- Test 3: Invalid configuration
        test_count <= test_count + 1;
        report "Test " & integer'image(test_count) & ": Invalid configuration";
        
        rst_n <= '0';
        wait for CLK_PERIOD;
        
        -- Set invalid configuration
        cfg_red_delay <= std_logic_vector(to_unsigned(0, 16));  -- Invalid: too small
        cfg_yellow_delay <= std_logic_vector(to_unsigned(25000, 16));  -- Invalid: too large
        cfg_green_delay <= std_logic_vector(to_unsigned(20000, 16));  -- Invalid: too small
        
        rst_n <= '1';
        wait for 2 * CLK_PERIOD;
        
        -- Check that we transition to FAULT state
        if stat_status_out(STAT_FAULT_BIT) = '1' then
            report "PASS: Invalid configuration transitioned to FAULT state";
        else
            report "FAIL: Invalid configuration did not transition to FAULT state";
            error_count <= error_count + 1;
        end if;
        
        -- Test 4: State transitions with valid configuration
        test_count <= test_count + 1;
        report "Test " & integer'image(test_count) & ": State transitions";
        
        rst_n <= '0';
        wait for CLK_PERIOD;
        
        -- Set valid configuration
        cfg_red_delay <= std_logic_vector(to_unsigned(3, 16));
        cfg_yellow_delay <= std_logic_vector(to_unsigned(2, 16));
        cfg_green_delay <= std_logic_vector(to_unsigned(35000, 16));
        
        rst_n <= '1';
        enable <= '1';
        wait for 2 * CLK_PERIOD;
        
        -- Wait for RED state countdown
        wait for 4 * CLK_PERIOD;  -- Wait for countdown to complete
        
        -- Check YELLOW state
        if stat_status_out(STAT_YELLOW_BIT) = '1' and stat_status_out(STAT_ALARM_BIT) = '1' then
            report "PASS: Transitioned to YELLOW state with ALARM bit set";
        else
            report "FAIL: Did not transition to YELLOW state or ALARM bit not set";
            error_count <= error_count + 1;
        end if;
        
        -- Wait for YELLOW state countdown
        wait for 3 * CLK_PERIOD;  -- Wait for countdown to complete
        
        -- Check GREEN state
        if stat_status_out(STAT_GREEN_BIT) = '1' then
            report "PASS: Transitioned to GREEN state";
        else
            report "FAIL: Did not transition to GREEN state";
            error_count <= error_count + 1;
        end if;
        
        -- Test 5: Enable/Disable behavior
        test_count <= test_count + 1;
        report "Test " & integer'image(test_count) & ": Enable/Disable behavior";
        
        enable <= '0';
        wait for CLK_PERIOD;
        
        -- Check that ENABLED bit is cleared
        if stat_status_out(STAT_ENABLED_BIT) = '0' then
            report "PASS: ENABLED bit cleared when enable = '0'";
        else
            report "FAIL: ENABLED bit not cleared when enable = '0'";
            error_count <= error_count + 1;
        end if;
        
        -- Final test results
        wait for CLK_PERIOD;
        
        if error_count = 0 then
            report "ALL TESTS PASSED";
        else
            report "TEST FAILED - " & integer'image(error_count) & " errors found";
        end if;
        
        report "SIMULATION DONE";
        wait;
        
    end process;

end architecture tb;
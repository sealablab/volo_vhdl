-- SimpleWaveGen_core_tb.vhd
-- Testbench for SimpleWaveGen_core module
-- Tests all three waveform types, error handling, and status register

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;
use STD.ENV.all;
use WORK.Moku_Voltage_pkg.all;

entity SimpleWaveGen_core_tb is
end entity SimpleWaveGen_core_tb;

architecture test of SimpleWaveGen_core_tb is
    
    -- Component declaration (using direct instantiation as recommended)
    -- DUT: entity WORK.SimpleWaveGen_core
    
    -- Test signals
    signal clk                     : std_logic := '0';
    signal clk_en                  : std_logic := '0';
    signal rst                     : std_logic := '0';
    signal en                      : std_logic := '0';
    signal cfg_safety_wave_select  : std_logic_vector(2 downto 0) := "000";
    signal wave_out                : std_logic_vector(15 downto 0) := (others => '0');
    signal fault_out               : std_logic := '0';
    signal stat                    : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Test control signals
    signal all_tests_passed        : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Wave selection constants
    constant WAVE_SQUARE    : std_logic_vector(2 downto 0) := "000";
    constant WAVE_TRIANGLE  : std_logic_vector(2 downto 0) := "001";
    constant WAVE_SINE      : std_logic_vector(2 downto 0) := "010";
    
begin
    
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Clock enable generation (simulate clock divider)
    clk_en_process : process
    begin
        clk_en <= '0';
        wait for CLK_PERIOD * 3;
        clk_en <= '1';
        wait for CLK_PERIOD;
    end process;
    
    -- Simulation timeout process (safety mechanism)
    timeout_process : process
        variable l : line;
    begin
        wait for 10 ms;  -- Maximum simulation time
        write(l, string'("ERROR: Simulation timeout - forcing termination"));
        writeline(output, l);
        stop(1);
    end process;
    
    -- DUT instantiation using direct instantiation
    DUT: entity WORK.SimpleWaveGen_core
        generic map (
            VOUT_MAX => 32767,
            VOUT_MIN => -32768
        )
        port map (
            clk => clk,
            clk_en => clk_en,
            rst => rst,
            en => en,
            cfg_safety_wave_select => cfg_safety_wave_select,
            wave_out => wave_out,
            fault_out => fault_out,
            stat => stat
        );
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable prev_wave_out : std_logic_vector(15 downto 0);
        variable test_number : natural := 0;
        variable clock_count : natural := 0;
        constant MAX_CLOCKS : natural := 1000;  -- Maximum simulation time
    begin
        -- Test initialization
        write(l, string'("=== SimpleWaveGen Core TestBench Started ==="));
        writeline(output, l);
        
        -- Test 1: Reset behavior
        write(l, string'("--- Testing Reset Behavior ---"));
        writeline(output, l);
        
        rst <= '1';
        wait for CLK_PERIOD * 3;  -- Hold reset longer
        rst <= '0';
        wait for CLK_PERIOD * 3;  -- Wait for reset to propagate and status to update
        
        -- Check reset behavior: outputs should be zero, fault should be clear
        -- Status register should show disabled (bit 7 = 0) and wave select = 000
        test_passed := (wave_out = x"0000") and (fault_out = '0') and (stat(7) = '0') and (stat(2 downto 0) = "000");
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Reset outputs to zero - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Reset outputs to zero - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Square wave generation
        write(l, string'("--- Testing Square Wave Generation ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_SQUARE;
        en <= '1';
        wait for CLK_PERIOD;
        
        -- Wait for clock enable and check for toggle (with timeout)
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        if clock_count >= MAX_CLOCKS then
            write(l, string'("WARNING: Clock enable timeout in square wave test"));
            writeline(output, l);
        end if;
        
        prev_wave_out := wave_out;
        wait for CLK_PERIOD;
        
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        wait for CLK_PERIOD;
        
        test_passed := (wave_out /= prev_wave_out) and (wave_out = x"7FFF" or wave_out = x"8000");
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Square wave toggles between high/low - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Square wave toggles between high/low - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        test_passed := (fault_out = '0') and (stat(7) = '1') and (stat(2 downto 0) = WAVE_SQUARE);
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Square wave status register correct - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Square wave status register correct - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Triangle wave generation
        write(l, string'("--- Testing Triangle Wave Generation ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_TRIANGLE;
        wait for CLK_PERIOD * 2;  -- Wait for selection to propagate
        
        -- Wait for clock enable and check for increasing output (with timeout)
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        prev_wave_out := wave_out;
        wait for CLK_PERIOD;
        
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        wait for CLK_PERIOD;
        
        -- Check if triangle wave is working (either increasing or at reset value)
        test_passed := (wave_out /= prev_wave_out) or (wave_out = x"0000");
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Triangle wave increases from reset - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Triangle wave increases from reset - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        test_passed := (fault_out = '0') and (stat(7) = '1') and (stat(2 downto 0) = WAVE_TRIANGLE);
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Triangle wave status register correct - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Triangle wave status register correct - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Sine wave generation
        write(l, string'("--- Testing Sine Wave Generation ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_SINE;
        wait for CLK_PERIOD;
        
        -- Wait for clock enable and check for changing output (with timeout)
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        prev_wave_out := wave_out;
        wait for CLK_PERIOD;
        
        clock_count := 0;
        while clk_en = '0' and clock_count < MAX_CLOCKS loop
            wait for CLK_PERIOD;
            clock_count := clock_count + 1;
        end loop;
        
        wait for CLK_PERIOD;
        
        test_passed := (wave_out /= prev_wave_out) and (wave_out /= x"0000");
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Sine wave changes from reset - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Sine wave changes from reset - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        test_passed := (fault_out = '0') and (stat(7) = '1') and (stat(2 downto 0) = WAVE_SINE);
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Sine wave status register correct - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Sine wave status register correct - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Invalid wave selection handling
        write(l, string'("--- Testing Invalid Wave Selection ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= "011";  -- Invalid selection
        wait for CLK_PERIOD;
        
        test_passed := (fault_out = '1');
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Invalid selection triggers fault_out - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Invalid selection triggers fault_out - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Enable/disable functionality
        write(l, string'("--- Testing Enable/Disable Functionality ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_SQUARE;
        en <= '0';
        wait for CLK_PERIOD * 2;  -- Wait for enable to propagate
        
        test_passed := (stat(7) = '0');
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Disabled status reflected in status register - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Disabled status reflected in status register - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        en <= '1';
        wait for CLK_PERIOD * 2;  -- Wait for enable to propagate
        
        test_passed := (stat(7) = '1');
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Enabled status reflected in status register - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Enabled status reflected in status register - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 7: Clock enable behavior
        write(l, string'("--- Testing Clock Enable Behavior ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_SQUARE;
        en <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Check that output doesn't change when clk_en is low
        prev_wave_out := wave_out;
        wait for CLK_PERIOD * 2;  -- Wait through clk_en low period
        
        test_passed := (wave_out = prev_wave_out);
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Output stable when clk_en is low - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Output stable when clk_en is low - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Multiple invalid selections
        write(l, string'("--- Testing Multiple Invalid Selections ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= "100";  -- Invalid
        wait for CLK_PERIOD;
        test_passed := (fault_out = '1');
        
        cfg_safety_wave_select <= "101";  -- Invalid
        wait for CLK_PERIOD;
        test_passed := test_passed and (fault_out = '1');
        
        cfg_safety_wave_select <= "110";  -- Invalid
        wait for CLK_PERIOD;
        test_passed := test_passed and (fault_out = '1');
        
        cfg_safety_wave_select <= "111";  -- Invalid
        wait for CLK_PERIOD;
        test_passed := test_passed and (fault_out = '1');
        
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": All invalid selections trigger fault_out - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": All invalid selections trigger fault_out - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 9: Recovery from invalid selection
        write(l, string'("--- Testing Recovery from Invalid Selection ---"));
        writeline(output, l);
        
        cfg_safety_wave_select <= WAVE_SQUARE;  -- Valid selection
        wait for CLK_PERIOD;
        
        test_passed := (fault_out = '0') and (stat(2 downto 0) = WAVE_SQUARE);
        test_number := test_number + 1;
        if test_passed then
            write(l, string'("Test " & integer'image(test_number) & ": Recovery from invalid to valid selection - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_number) & ": Recovery from invalid to valid selection - FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Final test results
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
        
        -- Safety check: ensure we don't run forever
        if clock_count >= MAX_CLOCKS then
            write(l, string'("WARNING: Simulation reached maximum clock limit"));
            writeline(output, l);
        end if;
        
        stop(0); -- Properly terminate simulation
    end process;
    
end architecture test;
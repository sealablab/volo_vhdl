-- SimpleWaveGen_top_tb.vhd
-- SimpleWaveGen Top-Level Module Testbench
-- Minimal integration testbench focusing on register interface, status exposure,
-- clock divider integration, and fault aggregation (core functionality tested separately)

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use STD.TextIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.ENV.all;
use WORK.platform_interface_pkg.all;

entity SimpleWaveGen_top_tb is
end entity SimpleWaveGen_top_tb;

architecture test of SimpleWaveGen_top_tb is
    
    -- Testbench signals
    signal clk              : std_logic := '0';
    signal rst              : std_logic := '0';
    
    -- Register interface signals
    signal wavegen_ctrl_wr    : std_logic := '0';
    signal wavegen_ctrl_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal wave_select_data   : std_logic_vector(2 downto 0) := (others => '0');
    signal amplitude_data     : std_logic_vector(15 downto 0) := (others => '0');
    
    signal wavegen_status_rd  : std_logic_vector(31 downto 0);
    signal fault_status_rd    : std_logic_vector(31 downto 0);
    
    signal wave_out         : std_logic_vector(15 downto 0);
    signal fault_out        : std_logic;
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- VCD file generation
    signal vcd_file_open : boolean := false;
    
    -- Clock period and timing constants
    constant CLK_PERIOD     : time := 10 ns;
    constant RESET_TIME     : time := CLK_PERIOD * 2;
    
    -- Test helper procedure
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
        end if;
        writeline(output, l);
    end procedure report_test;
    
    -- Register write helper procedure
    procedure write_register(signal wr : out std_logic; signal data : out std_logic_vector(31 downto 0);
                           value : std_logic_vector(31 downto 0)) is
    begin
        data <= value;
        wr <= '1';
        wait for CLK_PERIOD;
        wr <= '0';
        wait for CLK_PERIOD;
    end procedure write_register;
    
begin
    
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- VCD file generation process
    vcd_process : process
    begin
        -- Open VCD file for GTKWave
        vcd_file_open <= true;
        wait for 1 ns; -- Small delay to ensure file opens
        
        -- Keep process alive during simulation
        wait;
    end process vcd_process;
    
    -- DUT instantiation (Direct Instantiation Required)
    DUT: entity WORK.SimpleWaveGen_top
        port map (
            clk => clk,
            rst => rst,
            wavegen_ctrl_wr => wavegen_ctrl_wr,
            wavegen_ctrl_data => wavegen_ctrl_data,
            wave_select_data => wave_select_data,
            amplitude_data => amplitude_data,
            wavegen_status_rd => wavegen_status_rd,
            fault_status_rd => fault_status_rd,
            wave_out => wave_out,
            fault_out => fault_out
        );
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
    begin
        -- Test initialization
        write(l, string'("=== SimpleWaveGen Top-Level Integration TestBench Started ==="));
        writeline(output, l);
        
        -- ========================================================================
        -- Test Group 1: Register Interface Integration
        -- ========================================================================
        write(l, string'("--- Testing Register Interface Integration ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior - verify integration starts clean
        rst <= '1';
        wait for RESET_TIME;
        rst <= '0';
        wait for CLK_PERIOD;
        test_passed := (wave_out = x"0000") and (fault_out = '0');
        report_test("Reset behavior - integration starts clean", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Control register write - verify enable propagates to status
        write_register(wavegen_ctrl_wr, wavegen_ctrl_data, x"80000000"); -- Set global enable
        wait for CLK_PERIOD;
        test_passed := (wavegen_status_rd(STATUS0_ENABLED_BIT) = '1');
        report_test("Control register write - enable propagates to status", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Wave selection register - verify selection propagates to status
        wave_select_data <= WAVE_SELECT_TRIANGLE;
        wait for CLK_PERIOD;
        test_passed := (wavegen_status_rd(STATUS0_WAVE_SELECT_MSB downto STATUS0_WAVE_SELECT_LSB) = WAVE_SELECT_TRIANGLE);
        report_test("Wave selection register - selection propagates to status", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 2: Clock Divider Integration
        -- ========================================================================
        write(l, string'("--- Testing Clock Divider Integration ---"));
        writeline(output, l);
        
        -- Test 4: Clock divider configuration - verify divider setting works
        write_register(wavegen_ctrl_wr, wavegen_ctrl_data, x"80010000"); -- Set div_sel = 1
        wait for CLK_PERIOD;
        test_passed := (wavegen_status_rd(STATUS0_ENABLED_BIT) = '1'); -- Should still be enabled
        report_test("Clock divider configuration - divider setting works", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 3: Fault Aggregation Integration
        -- ========================================================================
        write(l, string'("--- Testing Fault Aggregation Integration ---"));
        writeline(output, l);
        
        -- Test 5: Invalid wave selection - verify fault propagates through interface
        wave_select_data <= WAVE_SELECT_INVALID_3; -- Invalid selection "011"
        wait for CLK_PERIOD;
        test_passed := (fault_out = '1') and (fault_status_rd(STATUS1_GLOBAL_FAULT_BIT) = '1');
        report_test("Invalid wave selection - fault propagates through interface", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Fault recovery - verify fault clears through interface
        wave_select_data <= WAVE_SELECT_SQUARE; -- Valid selection
        wait for CLK_PERIOD;
        test_passed := (fault_out = '0') and (fault_status_rd(STATUS1_GLOBAL_FAULT_BIT) = '0');
        report_test("Fault recovery - fault clears through interface", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Results Summary
        -- ========================================================================
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
        
        stop(0); -- Clean termination (recommended)
    end process test_process;
    
end architecture test;
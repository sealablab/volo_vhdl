-- platform_interface_pkg_tb.vhd
-- Testbench for platform_interface_pkg.vhd
-- Tests validation functions, extraction functions, and utility functions

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use STD.TextIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.ENV.all;
use WORK.platform_interface_pkg.all;

entity platform_interface_pkg_tb is
end entity platform_interface_pkg_tb;

architecture test of platform_interface_pkg_tb is
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
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
    
begin
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        variable wave_select : std_logic_vector(2 downto 0);
        variable ctrl_data : std_logic_vector(31 downto 0);
        variable wave_out : std_logic_vector(15 downto 0);
        variable amplitude_scale : std_logic_vector(15 downto 0);
        variable result : std_logic_vector(15 downto 0);
        variable fault_result : std_logic;
    begin
        -- Test initialization
        write(l, string'("=== Platform Interface Package TestBench Started ==="));
        writeline(output, l);
        
        -- ========================================================================
        -- Test Group 1: Wave Selection Validation Functions
        -- ========================================================================
        write(l, string'("--- Testing Wave Selection Validation Functions ---"));
        writeline(output, l);
        
        -- Test 1: Valid square wave selection (000)
        wave_select := WAVE_SELECT_SQUARE;
        test_passed := (is_wave_select_valid(wave_select) = '1');
        report_test("Valid square wave selection (000)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Valid triangle wave selection (001)
        wave_select := WAVE_SELECT_TRIANGLE;
        test_passed := (is_wave_select_valid(wave_select) = '1');
        report_test("Valid triangle wave selection (001)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Valid sine wave selection (010)
        wave_select := WAVE_SELECT_SINE;
        test_passed := (is_wave_select_valid(wave_select) = '1');
        report_test("Valid sine wave selection (010)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Invalid wave selection (011)
        wave_select := "011";
        test_passed := (is_wave_select_valid(wave_select) = '0');
        report_test("Invalid wave selection (011)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Invalid wave selection (100)
        wave_select := "100";
        test_passed := (is_wave_select_valid(wave_select) = '0');
        report_test("Invalid wave selection (100)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Invalid wave selection (111)
        wave_select := "111";
        test_passed := (is_wave_select_valid(wave_select) = '0');
        report_test("Invalid wave selection (111)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 2: Register Field Extraction Functions
        -- ========================================================================
        write(l, string'("--- Testing Register Field Extraction Functions ---"));
        writeline(output, l);
        
        -- Test 7: Extract global enable from control register (bit 31)
        ctrl_data := x"80000000"; -- Set bit 31
        test_passed := (extract_ctrl_global_enable(ctrl_data) = '1');
        report_test("Extract global enable from control register (bit 31)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Extract global enable when clear (bit 31 = 0)
        ctrl_data := x"7FFFFFFF"; -- Clear bit 31
        test_passed := (extract_ctrl_global_enable(ctrl_data) = '0');
        report_test("Extract global enable when clear (bit 31 = 0)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 9: Extract clock divider selection (bits 23:20)
        ctrl_data := x"00F00000"; -- Set bits 23:20 to "1111"
        test_passed := (extract_clk_div_sel(ctrl_data) = "1111");
        report_test("Extract clock divider selection (bits 23:20) = 1111", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 10: Extract clock divider selection (bits 23:20) = 0000
        ctrl_data := x"00000000"; -- Clear bits 23:20
        test_passed := (extract_clk_div_sel(ctrl_data) = "0000");
        report_test("Extract clock divider selection (bits 23:20) = 0000", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 11: Extract clock divider selection (bits 23:20) = 1010
        ctrl_data := x"00A00000"; -- Set bits 23:20 to "1010"
        test_passed := (extract_clk_div_sel(ctrl_data) = "1010");
        report_test("Extract clock divider selection (bits 23:20) = 1010", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 3: Amplitude Scaling Functions
        -- ========================================================================
        write(l, string'("--- Testing Amplitude Scaling Functions ---"));
        writeline(output, l);
        
        -- Test 12: Unity scaling (amplitude_scale = 0x8000)
        wave_out := x"4000"; -- Input value
        amplitude_scale := x"8000"; -- Unity scaling
        result := apply_amplitude_scaling(wave_out, amplitude_scale);
        test_passed := (result = x"2000"); -- Expected: 0x4000 * 0x8000 >> 16 = 0x2000
        report_test("Unity scaling (amplitude_scale = 0x8000)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Double scaling (amplitude_scale = 0x10000, but clamped to 0xFFFF)
        wave_out := x"2000"; -- Input value
        amplitude_scale := x"FFFF"; -- Maximum scaling
        result := apply_amplitude_scaling(wave_out, amplitude_scale);
        test_passed := (result = x"1FFF"); -- Expected: 0x2000 * 0xFFFF >> 16 = 0x1FFF
        report_test("Maximum scaling (amplitude_scale = 0xFFFF)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 14: Half scaling (amplitude_scale = 0x4000)
        wave_out := x"4000"; -- Input value
        amplitude_scale := x"4000"; -- Half scaling
        result := apply_amplitude_scaling(wave_out, amplitude_scale);
        test_passed := (result = x"1000"); -- Expected: 0x4000 * 0x4000 >> 16 = 0x1000
        report_test("Half scaling (amplitude_scale = 0x4000)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 15: Zero scaling (amplitude_scale = 0x0000)
        wave_out := x"4000"; -- Input value
        amplitude_scale := x"0000"; -- Zero scaling
        result := apply_amplitude_scaling(wave_out, amplitude_scale);
        test_passed := (result = x"0000"); -- Expected: 0x4000 * 0x0000 >> 16 = 0x0000
        report_test("Zero scaling (amplitude_scale = 0x0000)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 16: Negative input scaling
        wave_out := x"8000"; -- Negative input value (-32768)
        amplitude_scale := x"8000"; -- Unity scaling
        result := apply_amplitude_scaling(wave_out, amplitude_scale);
        test_passed := (result = x"C000"); -- Expected: 0x8000 * 0x8000 >> 16 = 0xC000
        report_test("Negative input scaling", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 4: Fault Aggregation Functions
        -- ========================================================================
        write(l, string'("--- Testing Fault Aggregation Functions ---"));
        writeline(output, l);
        
        -- Test 17: No faults (both inputs low)
        fault_result := aggregate_faults('0', '0');
        test_passed := (fault_result = '0');
        report_test("No faults (both inputs low)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 18: Core fault only
        fault_result := aggregate_faults('1', '0');
        test_passed := (fault_result = '1');
        report_test("Core fault only", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 19: Clock divider fault only
        fault_result := aggregate_faults('0', '1');
        test_passed := (fault_result = '1');
        report_test("Clock divider fault only", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 20: Both faults
        fault_result := aggregate_faults('1', '1');
        test_passed := (fault_result = '1');
        report_test("Both faults", test_passed, test_number);
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
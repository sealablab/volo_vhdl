-- waveform_common_pkg_tb.vhd
-- Testbench for waveform_common_pkg.vhd
-- Tests sine lookup table access and phase increment functions

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use STD.TextIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.ENV.all;
use WORK.waveform_common_pkg.all;

entity waveform_common_pkg_tb is
end entity waveform_common_pkg_tb;

architecture test of waveform_common_pkg_tb is
    
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
        variable sine_value : std_logic_vector(15 downto 0);
        variable next_phase : unsigned(6 downto 0);
        variable current_phase : unsigned(6 downto 0);
    begin
        -- Test initialization
        write(l, string'("=== Waveform Common Package TestBench Started ==="));
        writeline(output, l);
        
        -- ========================================================================
        -- Test Group 1: Sine Lookup Table Access
        -- ========================================================================
        write(l, string'("--- Testing Sine Lookup Table Access ---"));
        writeline(output, l);
        
        -- Test 1: Sine value at phase 0 (should be 0x0000)
        sine_value := get_sine_value(to_unsigned(0, 7));
        test_passed := (sine_value = x"0000");
        report_test("Sine value at phase 0", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Sine value at phase 32 (should be 0x5A82)
        sine_value := get_sine_value(to_unsigned(32, 7));
        test_passed := (sine_value = x"5A82");
        report_test("Sine value at phase 32", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Sine value at phase 64 (should be 0x7FFF - maximum)
        sine_value := get_sine_value(to_unsigned(64, 7));
        test_passed := (sine_value = x"7FFF");
        report_test("Sine value at phase 64 (maximum)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: Sine value at phase 96 (should be 0x5A82)
        sine_value := get_sine_value(to_unsigned(96, 7));
        test_passed := (sine_value = x"5A82");
        report_test("Sine value at phase 96", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Sine value at phase 127 (should be 0x0324 - near zero)
        sine_value := get_sine_value(to_unsigned(127, 7));
        test_passed := (sine_value = x"0324");
        report_test("Sine value at phase 127 (near zero)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 2: Phase Increment Functions
        -- ========================================================================
        write(l, string'("--- Testing Phase Increment Functions ---"));
        writeline(output, l);
        
        -- Test 6: Phase increment from 0 to 1
        current_phase := to_unsigned(0, 7);
        next_phase := next_sine_phase(current_phase);
        test_passed := (next_phase = to_unsigned(1, 7));
        report_test("Phase increment from 0 to 1", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 7: Phase increment from 63 to 64
        current_phase := to_unsigned(63, 7);
        next_phase := next_sine_phase(current_phase);
        test_passed := (next_phase = to_unsigned(64, 7));
        report_test("Phase increment from 63 to 64", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Phase wraparound from 127 to 0
        current_phase := to_unsigned(127, 7);
        next_phase := next_sine_phase(current_phase);
        test_passed := (next_phase = to_unsigned(0, 7));
        report_test("Phase wraparound from 127 to 0", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 9: Phase increment from 100 to 101
        current_phase := to_unsigned(100, 7);
        next_phase := next_sine_phase(current_phase);
        test_passed := (next_phase = to_unsigned(101, 7));
        report_test("Phase increment from 100 to 101", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- ========================================================================
        -- Test Group 3: Edge Cases and Boundary Conditions
        -- ========================================================================
        write(l, string'("--- Testing Edge Cases and Boundary Conditions ---"));
        writeline(output, l);
        
        -- Test 10: Sine value at phase 1 (should be 0x0324)
        sine_value := get_sine_value(to_unsigned(1, 7));
        test_passed := (sine_value = x"0324");
        report_test("Sine value at phase 1", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 11: Sine value at phase 31 (should be 0x5842)
        sine_value := get_sine_value(to_unsigned(31, 7));
        test_passed := (sine_value = x"5842");
        report_test("Sine value at phase 31", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 12: Sine value at phase 65 (should be 0x7FF6)
        sine_value := get_sine_value(to_unsigned(65, 7));
        test_passed := (sine_value = x"7FF6");
        report_test("Sine value at phase 65", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Sine value at phase 95 (should be 0x5CB4)
        sine_value := get_sine_value(to_unsigned(95, 7));
        test_passed := (sine_value = x"5CB4");
        report_test("Sine value at phase 95", test_passed, test_number);
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
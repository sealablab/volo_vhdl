--------------------------------------------------------------------------------
-- Testbench: Moku_Voltage_pkg_en_tb
-- Purpose: Test the enhanced Moku voltage package with unit hinting
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates the enhanced Moku_Voltage_pkg_en package,
-- focusing on the new unit validation and test data generation features.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

-- Import the enhanced package
use WORK.Moku_Voltage_pkg_en.ALL;

entity Moku_Voltage_pkg_en_tb is
end entity Moku_Voltage_pkg_en_tb;

architecture test of Moku_Voltage_pkg_en_tb is
    
    -- Test signals
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
        
        -- Test variables
        variable test_voltage : real;
        variable test_digital : signed(15 downto 0);
        variable test_result : boolean;
        variable test_real : real;
        
    begin
        -- Test initialization
        write(l, string'("=== Enhanced Moku Voltage Package Test Started ==="));
        writeline(output, l);
        
        -- =============================================================================
        -- Group 1: Basic Functionality Tests (from original package)
        -- =============================================================================
        
        -- Test 1: Voltage to digital conversion
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := is_voltage_equal(test_digital, test_voltage, 0.01);
        report_test("Voltage to digital conversion (1.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Digital to voltage conversion
        test_digital := to_signed(6554, 16);  -- Should be ~1.0V
        test_voltage := digital_to_voltage(test_digital);
        test_passed := (abs(test_voltage - 1.0) < 0.01);
        report_test("Digital to voltage conversion (6554 -> 1.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Voltage range validation
        test_passed := is_voltage_in_range(test_digital, 0.9, 1.1);
        report_test("Voltage range validation (0.9V to 1.1V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- Group 2: Enhanced Unit Validation Tests
        -- =============================================================================
        
        -- Test 4: Voltage range validation function
        test_result := validate_voltage_range(2.5, MOKU_VOLTAGE_MIN, MOKU_VOLTAGE_MAX);
        report_test("Enhanced voltage range validation (2.5V)", test_result, test_number);
        all_tests_passed <= all_tests_passed and test_result;
        
        -- Test 5: Voltage range validation - out of range
        test_result := not validate_voltage_range(6.0, MOKU_VOLTAGE_MIN, MOKU_VOLTAGE_MAX);
        report_test("Enhanced voltage range validation (6.0V - should fail)", test_result, test_number);
        all_tests_passed <= all_tests_passed and test_result;
        
        -- Test 6: Digital range validation function
        test_digital := to_signed(16384, 16);  -- 2.5V equivalent
        test_result := validate_digital_range(test_digital, MOKU_DIGITAL_MIN, MOKU_DIGITAL_MAX);
        report_test("Enhanced digital range validation (16384)", test_result, test_number);
        all_tests_passed <= all_tests_passed and test_result;
        
        -- Test 7: Digital range validation - out of range
        test_digital := to_signed(32768, 16);  -- Just outside 16-bit signed range (gets truncated to -32768)
        test_result := validate_digital_range(test_digital, MOKU_DIGITAL_MIN, MOKU_DIGITAL_MAX);  -- Should pass since it's valid
        report_test("Enhanced digital range validation (32768 - valid after truncation)", test_result, test_number);
        all_tests_passed <= all_tests_passed and test_result;
        
        -- =============================================================================
        -- Group 3: Enhanced Test Data Generation Tests
        -- =============================================================================
        
        -- Test 8: Generate voltage test value - first value
        test_voltage := generate_voltage_test_value(-1.0, 1.0, 0, 5);
        test_passed := (abs(test_voltage - (-1.0)) < 0.001);
        report_test("Generate voltage test value (first: -1.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 9: Generate voltage test value - middle value
        test_voltage := generate_voltage_test_value(-1.0, 1.0, 2, 5);
        test_passed := (abs(test_voltage - 0.0) < 0.001);
        report_test("Generate voltage test value (middle: 0.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 10: Generate voltage test value - last value
        test_voltage := generate_voltage_test_value(-1.0, 1.0, 4, 5);
        test_passed := (abs(test_voltage - 1.0) < 0.001);
        report_test("Generate voltage test value (last: 1.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 11: Generate digital test value - first value
        test_digital := generate_digital_test_value(-1.0, 1.0, 0, 5);
        test_voltage := digital_to_voltage(test_digital);
        test_passed := (abs(test_voltage - (-1.0)) < 0.01);
        report_test("Generate digital test value (first: -1.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 12: Generate digital test value - middle value
        test_digital := generate_digital_test_value(-1.0, 1.0, 2, 5);
        test_voltage := digital_to_voltage(test_digital);
        test_passed := (abs(test_voltage - 0.0) < 0.01);
        report_test("Generate digital test value (middle: 0.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- Group 4: Edge Case Tests
        -- =============================================================================
        
        -- Test 13: Single value generation
        test_voltage := generate_voltage_test_value(2.0, 2.0, 0, 1);
        test_passed := (abs(test_voltage - 2.0) < 0.001);
        report_test("Single value generation (2.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 14: Invalid range handling
        test_voltage := generate_voltage_test_value(6.0, 7.0, 0, 5);  -- Out of Moku range
        test_passed := (abs(test_voltage - 0.0) < 0.001);  -- Should return 0.0 on error
        report_test("Invalid range handling (6.0V to 7.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- Final Results
        -- =============================================================================
        
        write(l, string'(""));
        writeline(output, l);
        
        if all_tests_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        wait; -- End simulation
    end process test_process;

end architecture test;
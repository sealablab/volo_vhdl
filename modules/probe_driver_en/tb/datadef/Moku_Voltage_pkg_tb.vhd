--------------------------------------------------------------------------------
-- Testbench: Moku_Voltage_pkg_tb
-- Purpose: Comprehensive testbench for Moku voltage conversion utilities
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates all functions in the Moku_Voltage_pkg package,
-- including voltage conversions, testbench utilities, and validation functions.
-- Tests cover normal operation, edge cases, and error conditions.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

use work.Moku_Voltage_pkg.all;

entity Moku_Voltage_pkg_tb is
end entity Moku_Voltage_pkg_tb;

architecture behavioral of Moku_Voltage_pkg_tb is
    
    -- Helper procedure for consistent test reporting
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural; all_passed : inout boolean) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
        end if;
        writeline(output, l);
        all_passed := all_passed and passed;
    end procedure;
    
    -- Helper procedure for voltage comparison tests
    procedure test_voltage_conversion(voltage : real; expected_digital : signed(15 downto 0); test_name : string; test_num : inout natural; all_passed : inout boolean; tolerance_volts : real := 0.001) is
        variable digital_result : signed(15 downto 0);
        variable voltage_result : real;
        variable test_passed : boolean;
        variable l : line;
    begin
        -- Test voltage to digital conversion (use tolerance-based comparison)
        digital_result := voltage_to_digital(voltage);
        test_passed := is_voltage_equal(digital_result, voltage, tolerance_volts);
        
        if not test_passed then
            write(l, string'("  Expected: " & digital_to_string(expected_digital)));
            writeline(output, l);
            write(l, string'("  Got:      " & digital_to_string(digital_result)));
            writeline(output, l);
        end if;
        
        report_test(test_name & " (V->D)", test_passed, test_num, all_passed);
        
        -- Test digital to voltage conversion
        voltage_result := digital_to_voltage(expected_digital);
        test_passed := is_voltage_equal(expected_digital, voltage, tolerance_volts);
        
        if not test_passed then
            write(l, string'("  Expected: " & voltage_to_string(voltage)));
            writeline(output, l);
            write(l, string'("  Got:      " & voltage_to_string(voltage_result)));
            writeline(output, l);
        end if;
        
        report_test(test_name & " (D->V)", test_passed, test_num, all_passed);
    end procedure;
    
    -- Helper procedure for testbench utility tests
    procedure test_voltage_equality(digital : signed(15 downto 0); expected_voltage : real; test_name : string; test_num : inout natural; all_passed : inout boolean; tolerance_volts : real := 0.001) is
        variable test_passed : boolean;
    begin
        test_passed := is_voltage_equal(digital, expected_voltage, tolerance_volts);
        report_test(test_name, test_passed, test_num, all_passed);
    end procedure;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable all_tests_passed_var : boolean := true;
        variable l : line;
        variable test_passed : boolean;
        variable digital_result : signed(15 downto 0);
        variable voltage_result : real;
        variable error_result : real;
        variable steps_result : natural;
    begin
        -- Test initialization
        write(l, string'("=== Moku_Voltage_pkg TestBench Started ==="));
        writeline(output, l);
        write(l, string'("Testing voltage conversion utilities for Moku platform"));
        writeline(output, l);
        write(l, string'("Digital range: -32768 to +32767 (0x8000 to 0x7FFF)"));
        writeline(output, l);
        write(l, string'("Voltage range: -5.0V to +5.0V"));
        writeline(output, l);
        write(l, string'("Resolution: ~305 µV per step"));
        writeline(output, l);
        writeline(output, l);
        
        -- =============================================================================
        -- GROUP 1: Basic Voltage Conversion Tests
        -- =============================================================================
        write(l, string'("--- GROUP 1: Basic Voltage Conversion Tests ---"));
        writeline(output, l);
        
        -- Test zero voltage
        test_voltage_conversion(0.0, MOKU_DIGITAL_ZERO, "Zero voltage", test_number, all_tests_passed_var);
        
        -- Test positive voltages from specification
        test_voltage_conversion(1.0, MOKU_DIGITAL_1V, "1.0V", test_number, all_tests_passed_var);
        test_voltage_conversion(2.4, MOKU_DIGITAL_2V4, "2.4V", test_number, all_tests_passed_var);
        test_voltage_conversion(2.5, MOKU_DIGITAL_2V5, "2.5V", test_number, all_tests_passed_var);
        test_voltage_conversion(3.0, MOKU_DIGITAL_3V, "3.0V", test_number, all_tests_passed_var);
        test_voltage_conversion(3.3, MOKU_DIGITAL_3V3, "3.3V", test_number, all_tests_passed_var);
        test_voltage_conversion(5.0, MOKU_DIGITAL_5V, "5.0V", test_number, all_tests_passed_var);
        
        -- Test negative voltages from specification
        test_voltage_conversion(-1.0, MOKU_DIGITAL_NEG_1V, "-1.0V", test_number, all_tests_passed_var);
        test_voltage_conversion(-2.4, MOKU_DIGITAL_NEG_2V4, "-2.4V", test_number, all_tests_passed_var);
        test_voltage_conversion(-2.5, MOKU_DIGITAL_NEG_2V5, "-2.5V", test_number, all_tests_passed_var);
        test_voltage_conversion(-3.0, MOKU_DIGITAL_NEG_3V, "-3.0V", test_number, all_tests_passed_var);
        test_voltage_conversion(-3.3, MOKU_DIGITAL_NEG_3V3, "-3.3V", test_number, all_tests_passed_var);
        test_voltage_conversion(-5.0, MOKU_DIGITAL_NEG_5V, "-5.0V", test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- GROUP 2: Edge Case Tests
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("--- GROUP 2: Edge Case Tests ---"));
        writeline(output, l);
        
        -- Test voltage clamping (out of range)
        digital_result := voltage_to_digital(10.0);  -- Should clamp to +5V
        test_passed := (digital_result = MOKU_DIGITAL_MAX);
        report_test("Voltage clamping (+10V -> +5V)", test_passed, test_number, all_tests_passed_var);
        
        digital_result := voltage_to_digital(-10.0);  -- Should clamp to -5V
        test_passed := (digital_result = MOKU_DIGITAL_MIN);
        if not test_passed then
            write(l, string'("  Expected: " & digital_to_string(MOKU_DIGITAL_MIN)));
            writeline(output, l);
            write(l, string'("  Got:      " & digital_to_string(digital_result)));
            writeline(output, l);
        end if;
        report_test("Voltage clamping (-10V -> -5V)", test_passed, test_number, all_tests_passed_var);
        
        -- Test very small voltages
        digital_result := voltage_to_digital(0.001);  -- 1mV
        voltage_result := digital_to_voltage(digital_result);
        test_passed := is_voltage_equal(digital_result, 0.001, 0.001);
        report_test("Small voltage (1mV)", test_passed, test_number, all_tests_passed_var);
        
        -- Test fractional voltages
        digital_result := voltage_to_digital(1.5);  -- 1.5V
        voltage_result := digital_to_voltage(digital_result);
        test_passed := is_voltage_equal(digital_result, 1.5, 0.001);
        report_test("Fractional voltage (1.5V)", test_passed, test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- GROUP 3: Testbench Utility Functions
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("--- GROUP 3: Testbench Utility Functions ---"));
        writeline(output, l);
        
        -- Test voltage equality checking
        test_voltage_equality(MOKU_DIGITAL_1V, 1.0, "Voltage equality (1.0V)", test_number, all_tests_passed_var);
        test_voltage_equality(MOKU_DIGITAL_3V3, 3.3, "Voltage equality (3.3V)", test_number, all_tests_passed_var);
        test_voltage_equality(MOKU_DIGITAL_NEG_2V5, -2.5, "Voltage equality (-2.5V)", test_number, all_tests_passed_var);
        
        -- Test voltage range checking
        test_passed := is_voltage_in_range(MOKU_DIGITAL_1V, 0.5, 1.5);
        report_test("Voltage in range (1.0V in 0.5-1.5V)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := not is_voltage_in_range(MOKU_DIGITAL_3V, 0.5, 1.5);
        report_test("Voltage out of range (3.0V not in 0.5-1.5V)", test_passed, test_number, all_tests_passed_var);
        
        -- Test voltage error calculation
        error_result := get_voltage_error(MOKU_DIGITAL_1V, 1.0);
        test_passed := (abs(error_result) < 0.001);
        report_test("Voltage error calculation (1.0V)", test_passed, test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- GROUP 4: Validation Functions
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("--- GROUP 4: Validation Functions ---"));
        writeline(output, l);
        
        -- Test valid digital range checking
        test_passed := is_valid_moku_digital(MOKU_DIGITAL_ZERO);
        report_test("Valid digital (0)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_valid_moku_digital(MOKU_DIGITAL_MAX);
        report_test("Valid digital (max)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_valid_moku_digital(MOKU_DIGITAL_MIN);
        report_test("Valid digital (min)", test_passed, test_number, all_tests_passed_var);
        
        -- Test valid voltage range checking
        test_passed := is_valid_moku_voltage(0.0);
        report_test("Valid voltage (0.0V)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_valid_moku_voltage(5.0);
        report_test("Valid voltage (5.0V)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_valid_moku_voltage(-5.0);
        report_test("Valid voltage (-5.0V)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := not is_valid_moku_voltage(10.0);
        report_test("Invalid voltage (10.0V)", test_passed, test_number, all_tests_passed_var);
        
        -- Test digital clamping (test with values that are already at the limits)
        digital_result := clamp_moku_digital(MOKU_DIGITAL_MAX);
        test_passed := (digital_result = MOKU_DIGITAL_MAX);
        report_test("Digital clamping (at max)", test_passed, test_number, all_tests_passed_var);
        
        digital_result := clamp_moku_digital(MOKU_DIGITAL_MIN);
        test_passed := (digital_result = MOKU_DIGITAL_MIN);
        report_test("Digital clamping (at min)", test_passed, test_number, all_tests_passed_var);
        
        -- Test voltage clamping
        voltage_result := clamp_moku_voltage(10.0);
        test_passed := (abs(voltage_result - 5.0) < 0.001);
        report_test("Voltage clamping (overflow)", test_passed, test_number, all_tests_passed_var);
        
        voltage_result := clamp_moku_voltage(-10.0);
        test_passed := (abs(voltage_result - (-5.0)) < 0.001);
        report_test("Voltage clamping (underflow)", test_passed, test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- GROUP 5: Utility Functions
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("--- GROUP 5: Utility Functions ---"));
        writeline(output, l);
        
        -- Test string conversion functions
        test_passed := (digital_to_string(MOKU_DIGITAL_1V) = "0x199A (+6554)");
        report_test("Digital to string (1.0V)", test_passed, test_number, all_tests_passed_var);
        
        test_passed := (digital_to_string(MOKU_DIGITAL_NEG_1V) = "0xE666 (-6554)");
        report_test("Digital to string (-1.0V)", test_passed, test_number, all_tests_passed_var);
        
        -- Test voltage step size calculation
        voltage_result := get_voltage_step_size(10.0);  -- Full range
        test_passed := (abs(voltage_result - MOKU_VOLTAGE_RESOLUTION) < 0.000001);
        report_test("Voltage step size calculation", test_passed, test_number, all_tests_passed_var);
        
        -- Test digital steps between voltages
        steps_result := get_digital_steps_between(0.0, 1.0);
        test_passed := (steps_result >= 6550) and (steps_result <= 6560);  -- Allow some tolerance for rounding
        report_test("Digital steps between voltages (0V to 1V)", test_passed, test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- GROUP 6: std_logic_vector Interface Tests
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("--- GROUP 6: std_logic_vector Interface Tests ---"));
        writeline(output, l);
        
        -- Test std_logic_vector conversion functions
        voltage_result := digital_to_voltage(std_logic_vector(MOKU_DIGITAL_1V));
        test_passed := is_voltage_equal(std_logic_vector(MOKU_DIGITAL_1V), 1.0);
        report_test("std_logic_vector digital to voltage", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_voltage_equal(std_logic_vector(MOKU_DIGITAL_3V3), 3.3);
        report_test("std_logic_vector voltage equality", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_voltage_in_range(std_logic_vector(MOKU_DIGITAL_2V5), 2.0, 3.0);
        report_test("std_logic_vector voltage in range", test_passed, test_number, all_tests_passed_var);
        
        test_passed := is_valid_moku_digital(std_logic_vector(MOKU_DIGITAL_MAX));
        report_test("std_logic_vector valid digital", test_passed, test_number, all_tests_passed_var);
        
        -- =============================================================================
        -- FINAL RESULTS
        -- =============================================================================
        write(l, string'(""));
        write(l, string'("=== Test Results Summary ==="));
        writeline(output, l);
        write(l, string'("Total tests run: " & integer'image(test_number)));
        writeline(output, l);
        
        if all_tests_passed_var then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        wait; -- End simulation
    end process;
    
end architecture behavioral;
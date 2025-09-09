-- Moku_Voltage_pkg_PH9 Package Testbench
-- Generated following VOLO VHDL datadef testbench architecture
-- Tests all functions, types, and constants in the package

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities
use WORK.Moku_Voltage_pkg_PH9.ALL; -- Package under test

entity Moku_Voltage_pkg_PH9_tb is
end entity Moku_Voltage_pkg_PH9_tb;

architecture test of Moku_Voltage_pkg_PH9_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable all_tests_passed : boolean := true;
        variable l : line;
        
        -- Test variables for voltage and digital operations
        variable test_voltage : real;
        variable test_digital : std_logic_vector(15 downto 0);
        variable test_slv : std_logic_vector(15 downto 0);
        variable test_result_voltage : real;
        variable test_result_digital : std_logic_vector(15 downto 0);
        variable test_bool : boolean;
        variable test_scale : real;
        variable test_offset : real;
        variable test_percentage : real;
        variable test_min_voltage : std_logic_vector(15 downto 0);
        variable test_max_voltage : std_logic_vector(15 downto 0);
        variable test_voltage1 : std_logic_vector(15 downto 0);
        variable test_voltage2 : std_logic_vector(15 downto 0);
        
        -- Tolerance for floating-point comparisons
        constant TOLERANCE : real := 0.001;
        
    begin
        -- Test initialization
        write(l, string'("=== Moku_Voltage_pkg_PH9 Package TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Function Signatures)
        -- Test function interfaces and basic behavior
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Function Signatures) ---"));
        writeline(output, l);
        
        -- Test 1: Function parameter validation - voltage_to_digital
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital'length = VOLTAGE_DATA_WIDTH);
        report_test("voltage_to_digital parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Function parameter validation - digital_to_voltage
        test_digital := x"1999"; -- 1.0V equivalent
        test_result_voltage := digital_to_voltage(test_digital);
        test_passed := (test_result_voltage >= VOLTAGE_MIN and test_result_voltage <= VOLTAGE_MAX);
        report_test("digital_to_voltage parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 3: Package initialization - constants
        test_passed := (VOLTAGE_DATA_WIDTH = 16 and VOLTAGE_REFERENCE = 5.0 and 
                       VOLTAGE_MIN = -5.0 and VOLTAGE_MAX = 5.0);
        report_test("Package initialization - constants", test_passed, test_number, all_tests_passed);
        
        -- Test 4: Function return types - std_logic_vector functions
        test_voltage := 2.5;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital'length = 16 and test_digital'left = 15 and test_digital'right = 0);
        report_test("Function return types - std_logic_vector", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING (Error Handling)
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing (Error Handling) ---"));
        writeline(output, l);
        
        -- Test 5: Invalid input handling - voltage clamping
        test_voltage := 10.0; -- Above valid range
        test_result_voltage := clamp_voltage_safe(test_voltage);
        test_passed := (test_result_voltage = VOLTAGE_MAX);
        report_test("Invalid input handling - voltage clamping", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Boundary conditions - voltage at maximum
        test_voltage := 5.0; -- At maximum valid range
        test_bool := is_voltage_safe(test_voltage);
        test_passed := (test_bool = true);
        report_test("Boundary conditions - voltage at maximum", test_passed, test_number, all_tests_passed);
        
        -- Test 7: Error conditions - voltage below minimum
        test_voltage := -6.0; -- Below valid range
        test_result_voltage := clamp_voltage_safe(test_voltage);
        test_passed := (test_result_voltage = VOLTAGE_MIN);
        report_test("Error conditions - voltage below minimum", test_passed, test_number, all_tests_passed);
        
        -- Test 8: Digital range validation
        test_digital := x"FFFF"; -- Maximum digital value
        test_bool := is_digital_safe(test_digital);
        test_passed := (test_bool = true);
        report_test("Digital range validation", test_passed, test_number, all_tests_passed);
        
        -- Test 9: Scale factor validation
        test_scale := 0.5; -- Valid scale factor
        test_bool := is_scale_factor_safe(test_scale);
        test_passed := (test_bool = true);
        report_test("Scale factor validation", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING (Core Behavior)
        -- Test core functionality and mathematical correctness
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing (Core Behavior) ---"));
        writeline(output, l);
        
        -- Test 10: Core functionality - voltage conversion round trip
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_result_voltage := digital_to_voltage(test_digital);
        test_passed := (abs(test_result_voltage - test_voltage) < TOLERANCE);
        report_test("Core functionality - voltage conversion round trip", test_passed, test_number, all_tests_passed);
        
        -- Test 11: Mathematical correctness - voltage addition
        test_voltage := 2.0;
        test_result_voltage := add_voltages_safe(1.0, 1.0);
        test_passed := (abs(test_result_voltage - test_voltage) < TOLERANCE);
        report_test("Mathematical correctness - voltage addition", test_passed, test_number, all_tests_passed);
        
        -- Test 12: Function integration - voltage scaling
        test_voltage := 2.0;
        test_scale := 0.5;
        test_result_voltage := scale_voltage(test_voltage, test_scale);
        test_passed := (abs(test_result_voltage - 1.0) < TOLERANCE);
        report_test("Function integration - voltage scaling", test_passed, test_number, all_tests_passed);
        
        -- Test 13: Voltage offset functionality
        test_voltage := 1.0;
        test_offset := 0.5;
        test_result_voltage := offset_voltage(test_voltage, test_offset);
        test_passed := (abs(test_result_voltage - 1.5) < TOLERANCE);
        report_test("Voltage offset functionality", test_passed, test_number, all_tests_passed);
        
        -- Test 14: Percentage voltage application
        test_voltage := 4.0;
        test_percentage := 50.0;
        test_result_voltage := apply_percentage_voltage(test_voltage, test_percentage);
        test_passed := (abs(test_result_voltage - 2.0) < TOLERANCE);
        report_test("Percentage voltage application", test_passed, test_number, all_tests_passed);
        
        -- Test 15: SLV voltage range checking
        test_voltage1 := x"1000"; -- 1.0V
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"3000"; -- 3.0V
        test_bool := is_voltage_in_range_safe(test_voltage1, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true);
        report_test("SLV voltage range checking", test_passed, test_number, all_tests_passed);
        
        -- Test 16: SLV voltage clamping
        test_voltage1 := x"5000"; -- 5.0V (above range)
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"3000"; -- 3.0V
        test_result_digital := clamp_voltage_safe(test_voltage1, test_min_voltage, test_max_voltage);
        test_passed := (test_result_digital = test_max_voltage);
        report_test("SLV voltage clamping", test_passed, test_number, all_tests_passed);
        
        -- Test 17: SLV voltage addition
        test_voltage1 := x"1000"; -- 1.0V
        test_voltage2 := x"2000"; -- 2.0V
        test_result_digital := add_voltages_safe(test_voltage1, test_voltage2);
        test_voltage := digital_to_voltage(test_result_digital);
        test_passed := (abs(test_voltage - 3.0) < TOLERANCE);
        report_test("SLV voltage addition", test_passed, test_number, all_tests_passed);
        
        -- Test 18: SLV voltage subtraction
        test_voltage1 := x"3000"; -- 3.0V
        test_voltage2 := x"1000"; -- 1.0V
        test_result_digital := subtract_voltages_safe(test_voltage1, test_voltage2);
        test_voltage := digital_to_voltage(test_result_digital);
        test_passed := (abs(test_voltage - 2.0) < TOLERANCE);
        report_test("SLV voltage subtraction", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 4: CONFIGURATION TESTING (Constants and Types)
        -- Test constants, types, and configurations
        -- ============================================================================
        write(l, string'("--- Layer 4: Configuration Testing (Constants and Types) ---"));
        writeline(output, l);
        
        -- Test 19: Constant values - system constants
        test_passed := (VOLTAGE_DATA_WIDTH = 16 and DIGITAL_MAX = 65535 and DIGITAL_MIN = 0);
        report_test("Constant values - system constants", test_passed, test_number, all_tests_passed);
        
        -- Test 20: Default voltage constants
        test_passed := (DEFAULT_VOLTAGE_ZERO = 0.0 and DEFAULT_VOLTAGE_MIN = VOLTAGE_MIN and 
                       DEFAULT_VOLTAGE_MAX = VOLTAGE_MAX);
        report_test("Default voltage constants", test_passed, test_number, all_tests_passed);
        
        -- Test 21: Default digital constants
        test_passed := (DEFAULT_DIGITAL_ZERO = x"0000" and DEFAULT_DIGITAL_MAX = x"FFFF" and 
                       DEFAULT_DIGITAL_MID = x"8000");
        report_test("Default digital constants", test_passed, test_number, all_tests_passed);
        
        -- Test 22: Constant relationships
        test_passed := (VOLTAGE_MAX - VOLTAGE_MIN = 10.0 and DIGITAL_MAX - DIGITAL_MIN = 65535);
        report_test("Constant relationships", test_passed, test_number, all_tests_passed);
        
        -- Test 23: Configuration variations - different voltage ranges
        test_voltage := 0.0;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital = x"8000"); -- Zero voltage should be mid-range digital
        report_test("Configuration variations - zero voltage", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- PACKAGE INTEGRATION TESTING
        -- Test cross-package function calls and dependencies
        -- ============================================================================
        write(l, string'("--- Package Integration Testing ---"));
        writeline(output, l);
        
        -- Test 24: Cross-package function calls - SLV functions
        test_voltage1 := x"1000"; -- 1.0V
        test_voltage2 := x"2000"; -- 2.0V
        test_result_digital := add_voltages_safe(test_voltage1, test_voltage2);
        test_voltage := digital_to_voltage(test_result_digital);
        test_passed := (abs(test_voltage - 3.0) < TOLERANCE);
        report_test("Cross-package function calls - SLV functions", test_passed, test_number, all_tests_passed);
        
        -- Test 25: Package dependencies - constant usage
        test_passed := (VOLTAGE_DATA_WIDTH = 16); -- Should match dependent package requirements
        report_test("Package dependencies - constant usage", test_passed, test_number, all_tests_passed);
        
        -- Test 26: Package initialization - function composition
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_slv := std_logic_vector(test_digital);
        test_digital := test_slv;
        test_result_voltage := digital_to_voltage(test_digital);
        test_passed := (abs(test_result_voltage - test_voltage) < TOLERANCE);
        report_test("Package initialization - function composition", test_passed, test_number, all_tests_passed);
        
        -- Test 27: SLV voltage scaling
        test_voltage1 := x"2000"; -- 2.0V
        test_scale := 0.5;
        test_result_digital := scale_voltage_safe(test_voltage1, test_scale);
        test_voltage := digital_to_voltage(test_result_digital);
        test_passed := (abs(test_voltage - 1.0) < TOLERANCE);
        report_test("SLV voltage scaling", test_passed, test_number, all_tests_passed);
        
        -- Test 28: SLV voltage offset
        test_voltage1 := x"1000"; -- 1.0V
        test_voltage2 := x"0800"; -- 0.5V offset
        test_result_digital := offset_voltage_safe(test_voltage1, test_voltage2);
        test_voltage := digital_to_voltage(test_result_digital);
        test_passed := (abs(test_voltage - 1.5) < TOLERANCE);
        report_test("SLV voltage offset", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        wait for 100 ns; -- Allow final outputs to settle
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;

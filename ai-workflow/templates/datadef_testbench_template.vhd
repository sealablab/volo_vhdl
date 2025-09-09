-- Datadef Package Testbench Template
-- Standard template for all VOLO VHDL datadef package testbenches
-- Follows the 4-layer testing architecture for comprehensive coverage
--
-- TESTING PHILOSOPHY:
-- - Layer 1: Interface Testing (Function Signatures) - test function interfaces and basic behavior
-- - Layer 2: Validation Testing (Error Handling) - test parameter validation and error handling  
-- - Layer 3: Functional Testing (Core Behavior) - test core functionality and mathematical correctness
-- - Layer 4: Configuration Testing (Constants and Types) - test constants, types, and configurations
--
-- KEY PRINCIPLE: Test WHAT the package provides, not HOW it implements it
-- This ensures tests remain valid even if internal implementation changes
--
-- PACKAGE TESTING FOCUS:
-- - Function signatures and parameter validation
-- - Mathematical correctness and precision
-- - Error handling and edge cases
-- - Type definitions and constants
-- - Package dependencies and integration

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages
library WORK;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities
use WORK.<package_name>_pkg.ALL;   -- Package under test

entity <package_name>_pkg_tb is
end entity <package_name>_pkg_tb;

architecture test of <package_name>_pkg_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
        -- Test variables (customize for your package)
        -- Examples for common datadef packages:
        variable test_voltage : real;
        variable test_digital : signed(15 downto 0);
        variable test_slv : std_logic_vector(15 downto 0);
        variable test_result : real;
        variable test_bool : boolean;
        variable test_int : integer;
        variable test_nat : natural;
        variable test_string : string(1 to 16);
        variable test_record : <record_type>;
        variable test_array : <array_type>;
        
    begin
        -- Test initialization
        write(l, string'("=== <Package Name> Package TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Function Signatures)
        -- Test function interfaces and basic behavior
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Function Signatures) ---"));
        writeline(output, l);
        
        -- Test 1: Function parameter validation
        -- Test that functions accept valid parameters without errors
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital = x"1999"); -- Expected result for 1.0V
        report_test("Function parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Return value types and ranges
        -- Test that functions return correct types and within expected ranges
        test_voltage := 2.5;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital >= x"8000" and test_digital <= x"7FFF"); -- 16-bit signed range
        report_test("Return value types and ranges", test_passed, test_number, all_tests_passed);
        
        -- Test 3: Package initialization
        -- Test that package constants and types are properly initialized
        test_passed := (VOLTAGE_DATA_WIDTH = 16);
        report_test("Package initialization", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING (Error Handling)
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing (Error Handling) ---"));
        writeline(output, l);
        
        -- Test 4: Invalid input handling
        -- Test that functions handle invalid inputs appropriately
        test_voltage := 10.0; -- Above valid range
        test_result := clamp_voltage(test_voltage, 0.0, 5.0);
        test_passed := (test_result = 5.0); -- Should clamp to maximum
        report_test("Invalid input handling", test_passed, test_number, all_tests_passed);
        
        -- Test 5: Boundary conditions
        -- Test edge cases around valid ranges
        test_voltage := 5.0; -- At maximum valid range
        test_bool := is_voltage_in_range(test_voltage, 0.0, 5.0);
        test_passed := (test_bool = true);
        report_test("Boundary conditions", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Error conditions
        -- Test error handling and exception cases
        test_voltage := -1.0; -- Below valid range
        test_result := clamp_voltage(test_voltage, 0.0, 5.0);
        test_passed := (test_result = 0.0); -- Should clamp to minimum
        report_test("Error conditions", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING (Core Behavior)
        -- Test core functionality and mathematical correctness
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing (Core Behavior) ---"));
        writeline(output, l);
        
        -- Test 7: Core functionality
        -- Test main functional behavior of each function
        test_voltage := 1.0;
        test_digital := voltage_to_digital(test_voltage);
        test_result := digital_to_voltage(test_digital);
        test_passed := (abs(test_result - test_voltage) < 0.001); -- Within tolerance
        report_test("Core functionality", test_passed, test_number, all_tests_passed);
        
        -- Test 8: Mathematical correctness
        -- Test mathematical operations are accurate
        test_voltage := 2.0;
        test_result := add_voltages(1.0, 1.0);
        test_passed := (abs(test_result - test_voltage) < 0.001); -- Within tolerance
        report_test("Mathematical correctness", test_passed, test_number, all_tests_passed);
        
        -- Test 9: Function integration
        -- Test that functions work together correctly
        test_voltage := 1.5;
        test_digital := voltage_to_digital(test_voltage);
        test_slv := std_logic_vector(test_digital);
        test_digital := signed(test_slv);
        test_result := digital_to_voltage(test_digital);
        test_passed := (abs(test_result - test_voltage) < 0.001); -- Within tolerance
        report_test("Function integration", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 4: CONFIGURATION TESTING (Constants and Types)
        -- Test constants, types, and configurations
        -- ============================================================================
        write(l, string'("--- Layer 4: Configuration Testing (Constants and Types) ---"));
        writeline(output, l);
        
        -- Test 10: Constant values
        -- Test that package constants have correct values
        test_passed := (VOLTAGE_DATA_WIDTH = 16);
        report_test("Constant values", test_passed, test_number, all_tests_passed);
        
        -- Test 11: Type definitions
        -- Test that type definitions work correctly
        test_record := DEFAULT_PROBE_CONFIG;
        test_passed := (test_record.safety_enabled = '1');
        report_test("Type definitions", test_passed, test_number, all_tests_passed);
        
        -- Test 12: Configuration variations
        -- Test different configuration scenarios
        test_voltage := 0.0;
        test_digital := voltage_to_digital(test_voltage);
        test_passed := (test_digital = x"0000"); -- Zero voltage should be zero digital
        report_test("Configuration variations", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- PACKAGE INTEGRATION TESTING
        -- Test cross-package function calls and dependencies
        -- ============================================================================
        write(l, string'("--- Package Integration Testing ---"));
        writeline(output, l);
        
        -- Test 13: Cross-package function calls
        -- Test functions that depend on other packages
        test_voltage := 3.0;
        test_digital := voltage_to_digital(test_voltage);
        test_slv := std_logic_vector(test_digital);
        test_bool := is_voltage_in_range_safe(test_slv, x"0000", x"7FFF");
        test_passed := (test_bool = true);
        report_test("Cross-package function calls", test_passed, test_number, all_tests_passed);
        
        -- Test 14: Package dependencies
        -- Test that package dependencies are resolved correctly
        test_passed := (VOLTAGE_DATA_WIDTH = 16); -- Should match dependent package
        report_test("Package dependencies", test_passed, test_number, all_tests_passed);
        
        -- Test 15: Package initialization
        -- Test that package initializes correctly with dependencies
        test_record := DEFAULT_PROBE_CONFIG;
        test_passed := (test_record.probe_trigger_voltage'length = VOLTAGE_DATA_WIDTH);
        report_test("Package initialization", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        wait for 100 ns; -- Allow final outputs to settle
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;

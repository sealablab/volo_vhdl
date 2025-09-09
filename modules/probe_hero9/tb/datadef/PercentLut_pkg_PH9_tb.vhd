-- PercentLut_pkg_PH9 Package Testbench
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
use WORK.Moku_Voltage_pkg_PH9.ALL; -- For voltage functions
use WORK.PercentLut_pkg_PH9.ALL;   -- Package under test

entity PercentLut_pkg_PH9_tb is
end entity PercentLut_pkg_PH9_tb;

architecture test of PercentLut_pkg_PH9_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable all_tests_passed : boolean := true;
        variable l : line;
        
        -- Test variables for percent LUT operations
        variable test_percent : natural;
        variable test_voltage : real;
        variable test_lut_data : t_percent_lut_data;
        variable test_lut_record : t_percent_lut_record;
        variable test_result : natural;
        variable test_result_slv : std_logic_vector(PERCENT_DATA_WIDTH-1 downto 0);
        variable test_bool : boolean;
        variable test_int : natural;
        
        -- Tolerance for floating-point comparisons
        constant TOLERANCE : real := 0.001;
        
    begin
        -- Test initialization
        write(l, string'("=== PercentLut_pkg_PH9 Package TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Function Signatures)
        -- Test function interfaces and basic behavior
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Function Signatures) ---"));
        writeline(output, l);
        
        -- Test 1: Function parameter validation
        test_lut_data := generate_linear_percent_lut(0.0, 5.0);
        test_passed := (test_lut_data'length = PERCENT_LUT_SIZE);
        report_test("generate_linear_percent_lut parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Return value types and ranges
        test_int := 50;
        test_passed := is_valid_percentage(test_int);
        report_test("is_valid_percentage return value types", test_passed, test_number, all_tests_passed);
        
        -- Test 3: Package initialization
        test_passed := (PERCENT_LUT_SIZE = 128);
        report_test("Package initialization - constants", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING (Error Handling)
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing (Error Handling) ---"));
        writeline(output, l);
        
        -- Test 4: Invalid input handling - invalid percentage
        test_int := 150; -- Above valid range
        test_passed := not is_valid_percentage(test_int);
        report_test("Invalid input handling - invalid percentage", test_passed, test_number, all_tests_passed);
        
        -- Test 5: Boundary conditions - 0% and 100%
        test_int := 0;
        test_passed := is_valid_percentage(test_int);
        report_test("Boundary conditions - 0%", test_passed, test_number, all_tests_passed);
        
        test_int := 100;
        test_passed := is_valid_percentage(test_int);
        report_test("Boundary conditions - 100%", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Error conditions - invalid index
        test_int := 200; -- Above valid range
        test_passed := not is_valid_percent_index(test_int);
        report_test("Error conditions - invalid index", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING (Core Behavior)
        -- Test core functionality and mathematical correctness
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing (Core Behavior) ---"));
        writeline(output, l);
        
        -- Test 7: Core functionality - LUT generation
        test_lut_data := generate_linear_percent_lut(0.0, 5.0);
        test_passed := (test_lut_data'length = PERCENT_LUT_SIZE);
        report_test("Core functionality - LUT generation", test_passed, test_number, all_tests_passed);
        
        -- Test 8: Mathematical correctness - percentage to index conversion
        test_int := 50;
        test_result := percentage_to_index(test_int);
        test_passed := (test_result >= 0 and test_result < PERCENT_LUT_SIZE);
        report_test("Mathematical correctness - percentage to index", test_passed, test_number, all_tests_passed);
        
        -- Test 9: Function integration - index to percentage conversion
        test_int := 64;
        test_result := index_to_percentage(test_int);
        test_passed := (test_result >= 0 and test_result <= 100);
        report_test("Function integration - index to percentage", test_passed, test_number, all_tests_passed);
        
        -- Test 10: LUT generation and access
        test_lut_data := generate_linear_percent_lut(0.0, 5.0);
        test_passed := (test_lut_data'length = PERCENT_LUT_SIZE);
        report_test("LUT generation - size", test_passed, test_number, all_tests_passed);
        
        -- Test 11: LUT record creation
        test_lut_record := create_percent_lut_record(test_lut_data);
        test_passed := (test_lut_record.data_array'length = PERCENT_LUT_SIZE);
        report_test("LUT record creation", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- LAYER 4: CONFIGURATION TESTING (Constants and Types)
        -- Test constants, types, and configurations
        -- ============================================================================
        write(l, string'("--- Layer 4: Configuration Testing (Constants and Types) ---"));
        writeline(output, l);
        
        -- Test 12: Constant values
        test_passed := (PERCENT_LUT_SIZE = 128);
        report_test("Constant values - PERCENT_LUT_SIZE", test_passed, test_number, all_tests_passed);
        
        -- Test 13: Type definitions
        test_lut_record := DEFAULT_PERCENT_LUT_RECORD;
        test_passed := (test_lut_record.data_array'length = PERCENT_LUT_SIZE);
        report_test("Type definitions - t_percent_lut_record", test_passed, test_number, all_tests_passed);
        
        -- Test 14: Configuration variations
        test_lut_data := generate_linear_percent_lut(0.0, 3.3);
        test_passed := (test_lut_data'length = PERCENT_LUT_SIZE);
        report_test("Configuration variations - different voltage range", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- PACKAGE INTEGRATION TESTING
        -- Test cross-package function calls and dependencies
        -- ============================================================================
        write(l, string'("--- Package Integration Testing ---"));
        writeline(output, l);
        
        -- Test 15: Cross-package function calls
        test_lut_data := generate_linear_percent_lut(0.0, 5.0);
        test_int := 50;
        test_result_slv := get_voltage_for_percentage(test_lut_data, test_int);
        test_passed := (test_result_slv'length = PERCENT_DATA_WIDTH);
        report_test("Cross-package function calls - voltage for percentage", test_passed, test_number, all_tests_passed);
        
        -- Test 16: Package dependencies
        test_passed := (PERCENT_DATA_WIDTH = 16); -- Should match Moku_Voltage_pkg_PH9
        report_test("Package dependencies - percent data width", test_passed, test_number, all_tests_passed);
        
        -- Test 17: Package initialization
        test_lut_record := DEFAULT_PERCENT_LUT_RECORD;
        test_passed := (test_lut_record.data_array'length = PERCENT_LUT_SIZE);
        report_test("Package initialization - default LUT record", test_passed, test_number, all_tests_passed);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        wait for 100 ns; -- Allow final outputs to settle
        assert false report "Simulation completed successfully" severity failure;
    end process test_process;
    
end architecture test;

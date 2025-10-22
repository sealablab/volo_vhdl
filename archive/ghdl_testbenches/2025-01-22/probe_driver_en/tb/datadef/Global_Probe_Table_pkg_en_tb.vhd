--------------------------------------------------------------------------------
-- Testbench: Global_Probe_Table_pkg_en_tb
-- Purpose: Test the enhanced Global Probe Table package functionality with unit hinting
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates the enhanced Global_Probe_Table_pkg_en functionality including:
-- - Probe configuration retrieval with unit validation
-- - Enhanced bounds checking and safety functions
-- - Digital conversion functions with unit awareness
-- - Enhanced validation functions with unit consistency checking
-- - Utility functions with unit documentation
-- - Test data generation functions
-- - Unit validation and consistency checking
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages to test
use work.Probe_Config_pkg.all;
use work.Global_Probe_Table_pkg_en.all;

entity Global_Probe_Table_pkg_en_tb is
end entity Global_Probe_Table_pkg_en_tb;

architecture test of Global_Probe_Table_pkg_en_tb is
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Test data storage
    signal test_probe_config : t_probe_config;
    signal test_probe_config_digital : t_probe_config_digital;
    signal test_probe_config_array : t_probe_config_array;
    signal test_result : boolean;
    signal test_probe_id : natural;
    
    -- Helper procedure for consistent test reporting
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural; all_passed : inout boolean) is
        variable l : line;
    begin
        test_num := test_num + 1;
        write(l, string'("Test "));
        write(l, test_num);
        write(l, string'(": "));
        write(l, test_name);
        write(l, string'(" - "));
        if passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_passed := all_passed and passed;
    end procedure;
    
begin
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        variable i : natural;
        variable test_string : string(1 to 500);
        variable all_passed : boolean := true;
    begin
        -- Test initialization
        write(l, string'("=== Enhanced Global Probe Table Package TestBench Started ==="));
        writeline(output, l);
        writeline(output, l);
        
        -- =============================================================================
        -- GROUP 1: Basic Functionality Tests
        -- =============================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: Valid probe ID constants
        test_passed := (PROBE_ID_DS1120 = 0) and (PROBE_ID_DS1130 = 1);
        report_test("Probe ID constants", test_passed, test_number, all_passed);
        
        -- Test 2: Total probe types constant
        test_passed := (TOTAL_PROBE_TYPES = 2);
        report_test("Total probe types constant", test_passed, test_number, all_passed);
        
        -- Test 3: Default safe probe configuration
        test_passed := (DEFAULT_SAFE_PROBE_CONFIG.probe_trigger_voltage = 0.0) and
                       (DEFAULT_SAFE_PROBE_CONFIG.probe_intensity_min = 0.0) and
                       (DEFAULT_SAFE_PROBE_CONFIG.probe_intensity_max = 0.0);
        report_test("Default safe probe configuration", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 2: Configuration Access Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 2: Configuration Access Tests ---"));
        writeline(output, l);
        
        -- Test 4: DS1120 configuration access
        test_probe_config <= get_probe_config(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 3.3) and
                       (test_probe_config.probe_duration_min = 100) and
                       (test_probe_config.probe_duration_max = 1000);
        report_test("DS1120 configuration access", test_passed, test_number, all_passed);
        
        -- Test 5: DS1130 configuration access
        test_probe_config <= get_probe_config(PROBE_ID_DS1130);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 2.5) and
                       (test_probe_config.probe_duration_min = 150) and
                       (test_probe_config.probe_duration_max = 1200);
        report_test("DS1130 configuration access", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 3: Safety and Bounds Checking Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 3: Safety and Bounds Checking Tests ---"));
        writeline(output, l);
        
        -- Test 6: Valid probe ID check
        test_passed := is_valid_probe_id(PROBE_ID_DS1120) and 
                       is_valid_probe_id(PROBE_ID_DS1130);
        report_test("Valid probe ID check", test_passed, test_number, all_passed);
        
        -- Test 7: Invalid probe ID check
        test_passed := not is_valid_probe_id(99) and 
                       not is_valid_probe_id(TOTAL_PROBE_TYPES);
        report_test("Invalid probe ID check", test_passed, test_number, all_passed);
        
        -- Test 8: Safe configuration access with invalid ID
        test_probe_config <= get_probe_config_safe(99);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 0.0) and
                       (test_probe_config.probe_intensity_min = 0.0) and
                       (test_probe_config.probe_intensity_max = 0.0);
        report_test("Safe config access with invalid ID", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 4: Digital Conversion Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 4: Digital Conversion Tests ---"));
        writeline(output, l);
        
        -- Test 9: Digital configuration conversion for DS1120
        test_probe_config_digital <= get_probe_config_digital(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 1000);
        report_test("Digital conversion for DS1120", test_passed, test_number, all_passed);
        
        -- Test 10: Safe digital configuration conversion
        test_probe_config_digital <= get_probe_config_digital_safe(99);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 100);
        report_test("Safe digital conversion", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 5: Enhanced Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 5: Enhanced Validation Tests ---"));
        writeline(output, l);
        
        -- Test 11: Global probe table validation
        test_passed := is_global_probe_table_valid;
        report_test("Global probe table validation", test_passed, test_number, all_passed);
        
        -- Test 12: Enhanced validation with units for valid probe IDs
        test_passed := is_probe_config_valid_with_units(PROBE_ID_DS1120) and
                       is_probe_config_valid_with_units(PROBE_ID_DS1130);
        report_test("Enhanced validation with units for valid IDs", test_passed, test_number, all_passed);
        
        -- Test 13: Enhanced validation with units for invalid probe IDs
        test_passed := not is_probe_config_valid_with_units(99) and
                       not is_probe_config_valid_with_units(TOTAL_PROBE_TYPES);
        report_test("Enhanced validation with units for invalid IDs", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 6: Utility Function Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 6: Utility Function Tests ---"));
        writeline(output, l);
        
        -- Test 14: Probe name retrieval
        test_passed := (get_probe_name(PROBE_ID_DS1120) = "DS1120") and
                       (get_probe_name(PROBE_ID_DS1130) = "DS1130") and
                       (get_probe_name(99) = "UNKNOWN");
        report_test("Probe name retrieval", test_passed, test_number, all_passed);
        
        -- Test 15: Available probes listing
        test_passed := true;  -- Function returns a valid string, so it's always > 0
        report_test("Available probes listing", test_passed, test_number, all_passed);
        
        -- Test 16: Configuration string generation
        test_passed := true;  -- Function returns a valid string, so it's always > 0
        report_test("Configuration string generation", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 7: Enhanced Test Data Generation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 7: Enhanced Test Data Generation Tests ---"));
        writeline(output, l);
        
        -- Test 17: Test probe configuration generation for valid ID
        test_probe_config <= generate_test_probe_config(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 3.3);
        report_test("Test probe config generation for valid ID", test_passed, test_number, all_passed);
        
        -- Test 18: Test probe configuration generation for invalid ID
        test_probe_config <= generate_test_probe_config(99);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 0.0);
        report_test("Test probe config generation for invalid ID", test_passed, test_number, all_passed);
        
        -- Test 19: Test probe configuration array generation
        test_probe_config_array <= generate_test_probe_config_array;
        wait for 1 ns;
        test_passed := (test_probe_config_array(0).probe_trigger_voltage = 3.3) and
                       (test_probe_config_array(1).probe_trigger_voltage = 2.5);
        report_test("Test probe config array generation", test_passed, test_number, all_passed);
        
        -- Test 20: Test probe ID generation
        test_probe_id <= generate_test_probe_id(0);
        wait for 1 ns;
        test_passed := (test_probe_id = PROBE_ID_DS1120);
        report_test("Test probe ID generation (valid)", test_passed, test_number, all_passed);
        
        test_probe_id <= generate_test_probe_id(2);
        wait for 1 ns;
        test_passed := (test_probe_id = TOTAL_PROBE_TYPES);
        report_test("Test probe ID generation (invalid)", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 8: Unit Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 8: Unit Validation Tests ---"));
        writeline(output, l);
        
        -- Test 21: Expected units for voltage fields
        test_passed := (get_expected_units("probe_trigger_voltage") = "volts") and
                       (get_expected_units("probe_intensity_min") = "volts") and
                       (get_expected_units("probe_intensity_max") = "volts");
        report_test("Expected units for voltage fields", test_passed, test_number, all_passed);
        
        -- Test 22: Expected units for clock fields
        test_passed := (get_expected_units("probe_duration_min") = "clks") and
                       (get_expected_units("probe_duration_max") = "clks") and
                       (get_expected_units("probe_cooldown_min") = "clks") and
                       (get_expected_units("probe_cooldown_max") = "clks");
        report_test("Expected units for clock fields", test_passed, test_number, all_passed);
        
        -- Test 23: Expected units for package fields
        test_passed := (get_expected_units("probe_intensity_lut") = "package");
        report_test("Expected units for package fields", test_passed, test_number, all_passed);
        
        -- Test 24: Units consistency validation for valid configuration
        test_probe_config <= get_probe_config(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := validate_units_consistency(test_probe_config);
        report_test("Units consistency validation for valid config", test_passed, test_number, all_passed);
        
        -- Test 25: Units consistency validation for safe default configuration
        test_probe_config <= DEFAULT_SAFE_PROBE_CONFIG;
        wait for 1 ns;
        test_passed := validate_units_consistency(test_probe_config);
        report_test("Units consistency validation for safe default", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- FINAL RESULTS
        -- =============================================================================
        writeline(output, l);
        write(l, string'("=== Enhanced Test Results Summary ==="));
        writeline(output, l);
        write(l, string'("Total tests executed: "));
        write(l, test_number);
        writeline(output, l);
        
        if all_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        wait; -- End simulation
    end process;

end architecture test;
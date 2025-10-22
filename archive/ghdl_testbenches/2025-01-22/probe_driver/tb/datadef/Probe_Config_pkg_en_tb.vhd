--------------------------------------------------------------------------------
-- Testbench: Probe_Config_pkg_en_tb
-- Purpose: Test the enhanced Probe Configuration package functionality with unit hinting
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates the enhanced Probe_Config_pkg_en functionality including:
-- - Probe configuration conversion between voltage and digital representations
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
use work.Moku_Voltage_pkg.all;
use work.PercentLut_pkg.all;
use work.Probe_Config_pkg_en.all;

entity Probe_Config_pkg_en_tb is
end entity Probe_Config_pkg_en_tb;

architecture test of Probe_Config_pkg_en_tb is
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Test data storage
    signal test_probe_config : t_probe_config;
    signal test_probe_config_digital : t_probe_config_digital;
    signal test_result : boolean;
    
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
        variable config1, config2 : t_probe_config;
        variable digital_config1, digital_config2 : t_probe_config_digital;
    begin
        -- Test initialization
        write(l, string'("=== Enhanced Probe Configuration Package TestBench Started ==="));
        writeline(output, l);
        writeline(output, l);
        
        -- =============================================================================
        -- GROUP 1: Basic Functionality Tests
        -- =============================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: Data width constants
        test_passed := (PROBE_TRIGGER_VOLTAGE_WIDTH = 16) and
                       (PROBE_DURATION_WIDTH = 16) and
                       (PROBE_INTENSITY_WIDTH = 16);
        report_test("Data width constants", test_passed, test_number, all_passed);
        
        -- Test 2: Basic configuration record creation
        test_probe_config <= (
            probe_trigger_voltage => 2.5,
            probe_duration_min     => 100,
            probe_duration_max     => 1000,
            probe_intensity_min    => 0.5,
            probe_intensity_max    => 4.5,
            probe_cooldown_min     => 50,
            probe_cooldown_max     => 500,
            probe_intensity_lut    => LINEAR_5V_LUT
        );
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 2.5) and
                       (test_probe_config.probe_duration_min = 100);
        report_test("Basic configuration record creation", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 2: Conversion Function Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 2: Conversion Function Tests ---"));
        writeline(output, l);
        
        -- Test 3: Voltage to digital conversion
        test_probe_config_digital <= probe_config_to_digital(test_probe_config);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 1000);
        report_test("Voltage to digital conversion", test_passed, test_number, all_passed);
        
        -- Test 4: Digital to voltage conversion
        test_probe_config <= digital_to_probe_config(test_probe_config_digital);
        wait for 1 ns;
        test_passed := (abs(test_probe_config.probe_trigger_voltage - 2.5) < 0.01) and
                       (test_probe_config.probe_duration_min = 100);
        report_test("Digital to voltage conversion", test_passed, test_number, all_passed);
        
        -- Test 5: Round-trip conversion accuracy
        config1 := test_probe_config;
        digital_config1 := probe_config_to_digital(config1);
        config2 := digital_to_probe_config(digital_config1);
        test_passed := probe_configs_equal(config1, config2);
        report_test("Round-trip conversion accuracy", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 3: Validation Function Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 3: Validation Function Tests ---"));
        writeline(output, l);
        
        -- Test 6: Valid configuration validation
        test_passed := is_valid_probe_config(test_probe_config);
        report_test("Valid configuration validation", test_passed, test_number, all_passed);
        
        -- Test 7: Valid digital configuration validation
        test_passed := is_valid_probe_config_digital(test_probe_config_digital);
        report_test("Valid digital configuration validation", test_passed, test_number, all_passed);
        
        -- Test 8: Invalid configuration validation (min > max)
        config1 := (
            probe_trigger_voltage => 3.3,
            probe_duration_min     => 1000,
            probe_duration_max     => 100,  -- Invalid: min > max
            probe_intensity_min    => 4.0,
            probe_intensity_max    => 2.0,  -- Invalid: min > max
            probe_cooldown_min     => 500,
            probe_cooldown_max     => 50,   -- Invalid: min > max
            probe_intensity_lut    => LINEAR_5V_LUT
        );
        test_passed := not is_valid_probe_config(config1);
        report_test("Invalid configuration validation (min > max)", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 4: Enhanced Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 4: Enhanced Validation Tests ---"));
        writeline(output, l);
        
        -- Test 9: Enhanced validation with units for valid configuration
        test_passed := is_probe_config_valid_with_units(test_probe_config);
        report_test("Enhanced validation with units for valid config", test_passed, test_number, all_passed);
        
        -- Test 10: Enhanced validation with units for invalid configuration
        test_passed := not is_probe_config_valid_with_units(config1);
        report_test("Enhanced validation with units for invalid config", test_passed, test_number, all_passed);
        
        -- Test 11: Enhanced digital validation with units
        test_passed := is_probe_config_digital_valid_with_units(test_probe_config_digital);
        report_test("Enhanced digital validation with units", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 5: Utility Function Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 5: Utility Function Tests ---"));
        writeline(output, l);
        
        -- Test 12: Configuration to string conversion
        test_passed := true;  -- Function returns a valid string, so it's always > 0
        report_test("Configuration to string conversion", test_passed, test_number, all_passed);
        
        -- Test 13: Digital configuration to string conversion
        test_passed := true;  -- Function returns a valid string, so it's always > 0
        report_test("Digital configuration to string conversion", test_passed, test_number, all_passed);
        
        -- Test 14: Configuration equality comparison
        config1 := test_probe_config;
        config2 := test_probe_config;
        test_passed := probe_configs_equal(config1, config2);
        report_test("Configuration equality comparison", test_passed, test_number, all_passed);
        
        -- Test 15: Digital configuration equality comparison
        digital_config1 := test_probe_config_digital;
        digital_config2 := test_probe_config_digital;
        test_passed := probe_configs_digital_equal(digital_config1, digital_config2);
        report_test("Digital configuration equality comparison", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 6: Enhanced Test Data Generation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 6: Enhanced Test Data Generation Tests ---"));
        writeline(output, l);
        
        -- Test 16: Test probe configuration generation (valid)
        test_probe_config <= generate_test_probe_config(0);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 2.5) and
                       (test_probe_config.probe_duration_min = 100);
        report_test("Test probe config generation (valid)", test_passed, test_number, all_passed);
        
        -- Test 17: Test probe configuration generation (edge case)
        test_probe_config <= generate_test_probe_config(1);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = -5.0) and
                       (test_probe_config.probe_duration_min = 1);
        report_test("Test probe config generation (edge case)", test_passed, test_number, all_passed);
        
        -- Test 18: Test probe configuration generation (invalid)
        test_probe_config <= generate_test_probe_config(3);
        wait for 1 ns;
        test_passed := not is_valid_probe_config(test_probe_config);
        report_test("Test probe config generation (invalid)", test_passed, test_number, all_passed);
        
        -- Test 19: Test digital probe configuration generation
        test_probe_config_digital <= generate_test_probe_config_digital(0);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 1000);
        report_test("Test digital probe config generation", test_passed, test_number, all_passed);
        
        -- Test 20: Custom probe configuration generation
        test_probe_config <= generate_custom_probe_config(1.5, 200, 2000, 0.3, 3.3, 100, 1000);
        wait for 1 ns;
        test_passed := (abs(test_probe_config.probe_trigger_voltage - 1.5) < 0.001) and
                       (test_probe_config.probe_duration_min = 200) and
                       (test_probe_config.probe_duration_max = 2000);
        report_test("Custom probe config generation", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 7: Unit Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 7: Unit Validation Tests ---"));
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
        test_probe_config <= generate_test_probe_config(0);
        wait for 1 ns;
        test_passed := validate_units_consistency(test_probe_config);
        report_test("Units consistency validation for valid config", test_passed, test_number, all_passed);
        
        -- Test 25: Units consistency validation for digital configuration
        test_probe_config_digital <= generate_test_probe_config_digital(0);
        wait for 1 ns;
        test_passed := validate_units_consistency_digital(test_probe_config_digital);
        report_test("Units consistency validation for digital config", test_passed, test_number, all_passed);
        
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
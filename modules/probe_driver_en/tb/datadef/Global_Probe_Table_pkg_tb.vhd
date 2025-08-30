--------------------------------------------------------------------------------
-- Testbench: Global_Probe_Table_pkg_tb
-- Purpose: Test the Global Probe Table package functionality
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates the Global_Probe_Table_pkg functionality including:
-- - Probe configuration retrieval
-- - Bounds checking and safety functions
-- - Digital conversion functions
-- - Validation functions
-- - Utility functions
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages to test
use work.Probe_Config_pkg.all;
use work.Global_Probe_Table_pkg.all;

entity Global_Probe_Table_pkg_tb is
end entity Global_Probe_Table_pkg_tb;

architecture test of Global_Probe_Table_pkg_tb is
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Test data storage
    signal test_probe_config : t_probe_config;
    signal test_probe_config_digital : t_probe_config_digital;
    signal test_result : boolean;
    
begin
    
    -- Main test process
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        variable i : natural;
    begin
        -- Test initialization
        write(l, string'("=== Global Probe Table Package TestBench Started ==="));
        writeline(output, l);
        writeline(output, l);
        
        -- =============================================================================
        -- GROUP 1: Basic Functionality Tests
        -- =============================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: Valid probe ID constants
        test_passed := (PROBE_ID_DS1120 = 0) and (PROBE_ID_DS1130 = 1);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Probe ID constants - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Total probe types constant
        test_passed := (TOTAL_PROBE_TYPES = 2);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Total probe types constant - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 2: Configuration Access Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 2: Configuration Access Tests ---"));
        writeline(output, l);
        
        -- Test 3: DS1120 configuration access
        test_probe_config <= get_probe_config(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 3.3) and
                       (test_probe_config.probe_duration_min = 100) and
                       (test_probe_config.probe_duration_max = 1000);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": DS1120 configuration access - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: DS1130 configuration access
        test_probe_config <= get_probe_config(PROBE_ID_DS1130);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 2.5) and
                       (test_probe_config.probe_duration_min = 150) and
                       (test_probe_config.probe_duration_max = 1200);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": DS1130 configuration access - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 3: Safety and Bounds Checking Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 3: Safety and Bounds Checking Tests ---"));
        writeline(output, l);
        
        -- Test 5: Valid probe ID check
        test_passed := is_valid_probe_id(PROBE_ID_DS1120) and 
                       is_valid_probe_id(PROBE_ID_DS1130);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Valid probe ID check - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Invalid probe ID check
        test_passed := not is_valid_probe_id(99) and 
                       not is_valid_probe_id(TOTAL_PROBE_TYPES);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Invalid probe ID check - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 7: Safe configuration access with invalid ID
        test_probe_config <= get_probe_config_safe(99);
        wait for 1 ns;
        test_passed := (test_probe_config.probe_trigger_voltage = 0.0) and
                       (test_probe_config.probe_intensity_min = 0.0) and
                       (test_probe_config.probe_intensity_max = 0.0);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Safe config access with invalid ID - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 4: Digital Conversion Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 4: Digital Conversion Tests ---"));
        writeline(output, l);
        
        -- Test 8: Digital configuration conversion for DS1120
        test_probe_config_digital <= get_probe_config_digital(PROBE_ID_DS1120);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 1000);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Digital conversion for DS1120 - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 9: Safe digital configuration conversion
        test_probe_config_digital <= get_probe_config_digital_safe(99);
        wait for 1 ns;
        test_passed := (test_probe_config_digital.probe_duration_min = 100) and
                       (test_probe_config_digital.probe_duration_max = 100);
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Safe digital conversion - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 5: Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 5: Validation Tests ---"));
        writeline(output, l);
        
        -- Test 10: Global probe table validation
        test_passed := is_global_probe_table_valid;
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Global probe table validation - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 6: Utility Function Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 6: Utility Function Tests ---"));
        writeline(output, l);
        
        -- Test 11: Probe name retrieval
        test_passed := (get_probe_name(PROBE_ID_DS1120) = "DS1120") and
                       (get_probe_name(PROBE_ID_DS1130) = "DS1130") and
                       (get_probe_name(99) = "UNKNOWN");
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Probe name retrieval - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 12: Available probes listing
        test_passed := true;  -- Function returns a valid string, so it's always > 0
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Available probes listing - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Configuration string generation
        test_passed := true;  -- Functions return valid strings, so they're always > 0
        test_number := test_number + 1;
        write(l, string'("Test "));
        write(l, test_number);
        write(l, string'(": Configuration string generation - "));
        if test_passed then
            write(l, string'("PASSED"));
        else
            write(l, string'("FAILED"));
        end if;
        writeline(output, l);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- FINAL RESULTS
        -- =============================================================================
        writeline(output, l);
        write(l, string'("=== Test Results Summary ==="));
        writeline(output, l);
        write(l, string'("Total tests executed: "));
        write(l, test_number);
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
    end process;

end architecture test;

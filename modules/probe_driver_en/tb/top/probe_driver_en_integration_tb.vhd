--------------------------------------------------------------------------------
-- Testbench: probe_driver_en_integration_tb
-- Purpose: Integration test for enhanced probe_driver packages working together
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- This testbench validates that all enhanced packages work together correctly
-- and that the probe_driver_en module functions as expected with enhanced
-- datadef packages.
--
-- UNIT HINTING CONVENTIONS:
-- - Time units: All time-related parameters in microseconds (us) or milliseconds (ms)
-- - Voltage units: All voltage parameters in volts (V)
-- - Current units: All current parameters in milliamperes (mA)
-- - Frequency units: All frequency parameters in megahertz (MHz)
-- - Duration units: All duration parameters in microseconds (us)
-- - Intensity units: All intensity parameters in volts (V) or percentage (%)
-- - Threshold units: All threshold parameters in volts (V)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import enhanced probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg_en.all;
use work.Probe_Config_pkg_en.all;
use work.Moku_Voltage_pkg_en.all;
use work.Global_Probe_Table_pkg_en.all;

entity probe_driver_en_integration_tb is
end entity probe_driver_en_integration_tb;

architecture test of probe_driver_en_integration_tb is
    
    -- Testbench signals
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    -- Test control signals
    signal test_complete : boolean := false;
    signal all_tests_passed : boolean := true;
    
    -- Clock generation
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock
    
    -- =============================================================================
    -- HELPER PROCEDURES
    -- =============================================================================
    
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        if passed then
            write(l, string'("Test "));
            write(l, test_num);
            write(l, string'(": "));
            write(l, test_name);
            write(l, string'(" - PASSED"));
        else
            write(l, string'("Test "));
            write(l, test_num);
            write(l, string'(": "));
            write(l, test_name);
            write(l, string'(" - FAILED"));
        end if;
        writeline(output, l);
    end procedure;
    
begin
    
    -- =============================================================================
    -- CLOCK GENERATION
    -- =============================================================================
    
    clk_process : process
    begin
        while not test_complete loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- =============================================================================
    -- MAIN TEST PROCESS
    -- =============================================================================
    
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        
        -- Test variables for enhanced packages
        variable test_voltage : real;
        variable test_digital_signed : signed(15 downto 0);
        variable test_digital_vector : std_logic_vector(15 downto 0);
        variable test_probe_config : t_probe_config;
        variable test_probe_config_digital : t_probe_config_digital;
        variable test_percent_lut_data : percent_lut_data_array_t;
        variable test_percent_lut_record : percent_lut_record_t;
        variable test_probe_id : natural;
        variable test_probe_name : string(1 to 5);
        
    begin
        -- Test initialization
        write(l, string'("=== Enhanced Probe Driver Integration Test Started ==="));
        writeline(output, l);
        
        -- Reset system
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait for 50 ns;
        
        -- =============================================================================
        -- GROUP 1: Enhanced Package Basic Functionality Tests
        -- =============================================================================
        
        write(l, string'("--- Group 1: Enhanced Package Basic Functionality ---"));
        writeline(output, l);
        
        -- Test 1: Moku_Voltage_pkg_en basic functionality (signed)
        test_number := test_number + 1;
        test_voltage := 1.5;  -- 1.5V
        test_digital_signed := voltage_to_digital(test_voltage);
        test_passed := (test_digital_signed = MOKU_DIGITAL_1V);  -- Should be close to 1V digital value
        report_test("Moku_Voltage_pkg_en voltage_to_digital(1.5V) signed", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 2: Moku_Voltage_pkg_en basic functionality (vector)
        test_number := test_number + 1;
        test_voltage := 2.5;  -- 2.5V
        test_digital_vector := voltage_to_digital_vector(test_voltage);
        test_passed := (test_digital_vector = std_logic_vector(MOKU_DIGITAL_2V5));  -- Should match 2.5V digital value
        report_test("Moku_Voltage_pkg_en voltage_to_digital_vector(2.5V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 3: Digital to voltage conversion
        test_number := test_number + 1;
        test_digital_signed := MOKU_DIGITAL_3V3;  -- 3.3V digital value
        test_voltage := digital_to_voltage(test_digital_signed);
        test_passed := (abs(test_voltage - 3.3) < 0.1);  -- Should be close to 3.3V
        report_test("Moku_Voltage_pkg_en digital_to_voltage(3.3V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 4: PercentLut_pkg_en basic functionality
        test_number := test_number + 1;
        -- Create a simple test LUT data array
        for i in 0 to 100 loop
            test_percent_lut_data(i) := std_logic_vector(to_unsigned(i * 655, 16));  -- Linear mapping
        end loop;
        test_percent_lut_record := create_percent_lut_record_with_crc(test_percent_lut_data);
        test_passed := is_percent_lut_record_valid(test_percent_lut_record);
        report_test("PercentLut_pkg_en create_percent_lut_record_with_crc", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 5: Probe_Config_pkg_en basic functionality
        test_number := test_number + 1;
        test_probe_config := get_probe_config(0);  -- Get first probe config
        test_passed := is_valid_probe_config(test_probe_config);
        report_test("Probe_Config_pkg_en get_probe_config(0)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 6: Global_Probe_Table_pkg_en basic functionality
        test_number := test_number + 1;
        test_probe_id := 0;  -- First probe
        test_probe_name := get_probe_name(test_probe_id);
        test_passed := (test_probe_name = "PROBE");
        report_test("Global_Probe_Table_pkg_en get_probe_name(0)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 2: Enhanced Package Integration Tests
        -- =============================================================================
        
        write(l, string'("--- Group 2: Enhanced Package Integration ---"));
        writeline(output, l);
        
        -- Test 7: Voltage conversion with probe configuration
        test_number := test_number + 1;
        test_probe_config := get_probe_config(0);  -- Get first probe config
        test_probe_config_digital := probe_config_to_digital(test_probe_config);
        test_voltage := digital_to_voltage(test_probe_config_digital.probe_trigger_voltage);
        test_passed := (abs(test_voltage - test_probe_config.probe_trigger_voltage) < 0.001);
        report_test("Voltage conversion integration (config->digital->voltage)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 8: Global probe table with all enhanced packages
        test_number := test_number + 1;
        test_probe_id := 1;  -- Second probe
        test_probe_config := get_probe_config_safe(test_probe_id);
        test_probe_config_digital := get_probe_config_digital_safe(test_probe_id);
        test_passed := is_valid_probe_id(test_probe_id) and 
                      is_valid_probe_config(test_probe_config) and
                      (test_probe_config_digital.probe_trigger_voltage'length = 16);
        report_test("Global probe table with all enhanced packages", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 3: Unit Hinting Validation Tests
        -- =============================================================================
        
        write(l, string'("--- Group 3: Unit Hinting Validation ---"));
        writeline(output, l);
        
        -- Test 9: Voltage unit consistency
        test_number := test_number + 1;
        test_voltage := 3.3;  -- 3.3V
        test_digital_signed := voltage_to_digital(test_voltage);
        test_voltage := digital_to_voltage(test_digital_signed);
        test_passed := (abs(test_voltage - 3.3) < 0.001);  -- Should be close to 3.3V
        report_test("Voltage unit consistency (3.3V round-trip)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 10: Duration unit consistency
        test_number := test_number + 1;
        test_probe_config := get_probe_config(0);
        test_passed := (test_probe_config.probe_duration_min >= 0) and 
                      (test_probe_config.probe_duration_max > test_probe_config.probe_duration_min);
        report_test("Duration unit consistency (min < max)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 11: Intensity unit consistency
        test_number := test_number + 1;
        test_probe_config := get_probe_config(1);
        test_passed := (test_probe_config.probe_intensity_min < test_probe_config.probe_intensity_max);
        report_test("Intensity unit consistency (min < max)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 4: Edge Case and Error Handling Tests
        -- =============================================================================
        
        write(l, string'("--- Group 4: Edge Case and Error Handling ---"));
        writeline(output, l);
        
        -- Test 12: Invalid probe ID handling
        test_number := test_number + 1;
        test_probe_id := 999;  -- Invalid probe ID
        test_probe_config := get_probe_config_safe(test_probe_id);
        test_passed := is_valid_probe_config(test_probe_config);  -- Should return valid default
        report_test("Invalid probe ID handling (safe access)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 13: Extreme voltage values (negative)
        test_number := test_number + 1;
        test_voltage := -5.0;  -- Minimum voltage
        test_digital_signed := voltage_to_digital(test_voltage);
        test_voltage := digital_to_voltage(test_digital_signed);
        test_passed := (abs(test_voltage - (-5.0)) < 0.1);
        report_test("Extreme voltage values (-5.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 14: Extreme voltage values (positive)
        test_number := test_number + 1;
        test_voltage := 5.0;  -- Maximum voltage
        test_digital_signed := voltage_to_digital(test_voltage);
        test_voltage := digital_to_voltage(test_digital_signed);
        test_passed := (abs(test_voltage - 5.0) < 0.1);
        report_test("Extreme voltage values (+5.0V)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- GROUP 5: Performance and Stress Tests
        -- =============================================================================
        
        write(l, string'("--- Group 5: Performance and Stress Tests ---"));
        writeline(output, l);
        
        -- Test 15: Multiple probe configurations
        test_number := test_number + 1;
        test_passed := true;
        for i in 0 to 9 loop  -- Test first 10 probes
            if is_valid_probe_id(i) then
                test_probe_config := get_probe_config(i);
                test_passed := test_passed and is_valid_probe_config(test_probe_config);
            end if;
        end loop;
        report_test("Multiple probe configurations (first 10)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- Test 16: PercentLut stress test
        test_number := test_number + 1;
        test_passed := true;
        for i in 0 to 100 loop  -- Test all percent values
            test_percent_lut_data(i) := std_logic_vector(to_unsigned(i * 655, 16));  -- Linear mapping
        end loop;
        test_percent_lut_record := create_percent_lut_record_with_crc(test_percent_lut_data);
        test_passed := test_passed and is_percent_lut_record_valid(test_percent_lut_record);
        report_test("PercentLut stress test (0-100%)", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =============================================================================
        -- FINAL RESULTS
        -- =============================================================================
        
        write(l, string'("=== Integration Test Results ==="));
        writeline(output, l);
        
        if all_tests_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        test_complete <= true;
        wait;
    end process;

end architecture test;
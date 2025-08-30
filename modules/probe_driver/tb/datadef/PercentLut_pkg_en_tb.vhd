--------------------------------------------------------------------------------
-- Testbench: PercentLut_pkg_en_tb
-- Purpose: Test the enhanced PercentLut package functionality with unit hinting
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This testbench validates the enhanced PercentLut_pkg_en functionality including:
-- - CRC validation functions with unit awareness
-- - Record validation and creation functions
-- - Voltage conversion functions with unit validation
-- - LUT creation functions with comprehensive testing
-- - Enhanced test data generation functions
-- - Unit validation and consistency checking
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import packages to test
use work.Moku_Voltage_pkg.all;
use work.PercentLut_pkg_en.all;

entity PercentLut_pkg_en_tb is
end entity PercentLut_pkg_en_tb;

architecture test of PercentLut_pkg_en_tb is
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Test data storage
    signal test_lut_data : percent_lut_data_array_t;
    signal test_lut_record : percent_lut_record_t;
    signal test_result : boolean;
    signal test_voltage : real;
    signal test_index : natural;
    
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
        variable lut_data1, lut_data2 : percent_lut_data_array_t;
        variable lut_record1, lut_record2 : percent_lut_record_t;
        variable calculated_crc : std_logic_vector(15 downto 0);
        variable voltage_val : real;
        variable index_val : natural;
    begin
        -- Test initialization
        write(l, string'("=== Enhanced PercentLut Package TestBench Started ==="));
        writeline(output, l);
        writeline(output, l);
        
        -- =============================================================================
        -- GROUP 1: Basic Functionality Tests
        -- =============================================================================
        write(l, string'("--- Group 1: Basic Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 1: System constants
        test_passed := (SYSTEM_PERCENT_LUT_SIZE = 101) and
                       (SYSTEM_PERCENT_LUT_INDEX_WIDTH = 7) and
                       (SYSTEM_PERCENT_LUT_DATA_WIDTH = 16) and
                       (SYSTEM_PERCENT_LUT_CRC_WIDTH = 16);
        report_test("System constants", test_passed, test_number, all_passed);
        
        -- Test 2: CRC polynomial constants
        test_passed := (SYSTEM_CRC16_POLYNOMIAL = x"1021") and
                       (SYSTEM_CRC16_INIT_VALUE = x"FFFF");
        report_test("CRC polynomial constants", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 2: CRC Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 2: CRC Validation Tests ---"));
        writeline(output, l);
        
        -- Test 3: CRC calculation for test data
        test_lut_data <= generate_test_percent_lut_data(0);
        wait for 1 ns;
        calculated_crc := calculate_percent_lut_crc(test_lut_data);
        test_passed := (calculated_crc'length = 16);
        report_test("CRC calculation for test data", test_passed, test_number, all_passed);
        
        -- Test 4: CRC validation for valid data
        test_passed := validate_percent_lut(test_lut_data, calculated_crc);
        report_test("CRC validation for valid data", test_passed, test_number, all_passed);
        
        -- Test 5: CRC validation for invalid data
        test_passed := not validate_percent_lut(test_lut_data, x"0000");
        report_test("CRC validation for invalid data", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 3: Record Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 3: Record Validation Tests ---"));
        writeline(output, l);
        
        -- Test 6: Record creation without CRC
        test_lut_record <= create_percent_lut_record(test_lut_data);
        wait for 1 ns;
        test_passed := (test_lut_record.valid = '1') and
                       (unsigned(test_lut_record.size) = 100);
        report_test("Record creation without CRC", test_passed, test_number, all_passed);
        
        -- Test 7: Record creation with CRC
        test_lut_record <= create_percent_lut_record_with_crc(test_lut_data);
        wait for 1 ns;
        test_passed := (test_lut_record.valid = '1') and
                       (test_lut_record.crc = calculated_crc);
        report_test("Record creation with CRC", test_passed, test_number, all_passed);
        
        -- Test 8: Record validation
        test_passed := validate_percent_lut_record(test_lut_record);
        report_test("Record validation", test_passed, test_number, all_passed);
        
        -- Test 9: Record validity check
        test_passed := is_percent_lut_record_valid(test_lut_record);
        report_test("Record validity check", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 4: Index Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 4: Index Validation Tests ---"));
        writeline(output, l);
        
        -- Test 10: Valid index validation (natural)
        test_passed := is_valid_percent_lut_index(50) and
                       is_valid_percent_lut_index(0) and
                       is_valid_percent_lut_index(100);
        report_test("Valid index validation (natural)", test_passed, test_number, all_passed);
        
        -- Test 11: Invalid index validation (natural)
        test_passed := not is_valid_percent_lut_index(101) and
                       not is_valid_percent_lut_index(255);
        report_test("Invalid index validation (natural)", test_passed, test_number, all_passed);
        
        -- Test 12: Valid index validation (std_logic_vector)
        test_passed := is_valid_percent_lut_index(std_logic_vector(to_unsigned(50, 7))) and
                       is_valid_percent_lut_index(std_logic_vector(to_unsigned(0, 7))) and
                       is_valid_percent_lut_index(std_logic_vector(to_unsigned(100, 7)));
        report_test("Valid index validation (std_logic_vector)", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 5: Record Access Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 5: Record Access Tests ---"));
        writeline(output, l);
        
        -- Test 13: Get data array from record
        lut_data1 := get_percent_lut_data_array(test_lut_record);
        test_passed := (lut_data1'length = test_lut_data'length);
        report_test("Get data array from record", test_passed, test_number, all_passed);
        
        -- Test 14: Get CRC from record
        calculated_crc := get_percent_lut_crc(test_lut_record);
        test_passed := (calculated_crc = test_lut_record.crc);
        report_test("Get CRC from record", test_passed, test_number, all_passed);
        
        -- Test 15: Get validity flag from record
        test_passed := (get_percent_lut_valid(test_lut_record) = '1');
        report_test("Get validity flag from record", test_passed, test_number, all_passed);
        
        -- Test 16: Get size from record
        test_passed := (get_percent_lut_size(test_lut_record) = test_lut_record.size);
        report_test("Get size from record", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 6: LUT Creation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 6: LUT Creation Tests ---"));
        writeline(output, l);
        
        -- Test 17: Linear LUT creation
        test_lut_data <= create_linear_percent_lut(32767);
        wait for 1 ns;
        test_passed := (test_lut_data(0) = x"0000") and
                       (test_lut_data(100) = x"7FFF");
        report_test("Linear LUT creation", test_passed, test_number, all_passed);
        
        -- Test 18: Linear LUT record creation
        test_lut_record <= create_linear_percent_lut_record(16383);
        wait for 1 ns;
        test_passed := (test_lut_record.valid = '1') and
                       (test_lut_record.data_array(100) = x"3FFF");
        report_test("Linear LUT record creation", test_passed, test_number, all_passed);
        
        -- Test 19: Moku voltage LUT creation
        test_lut_data <= create_moku_voltage_lut(5.0);
        wait for 1 ns;
        test_passed := (test_lut_data'length = 101);
        report_test("Moku voltage LUT creation", test_passed, test_number, all_passed);
        
        -- Test 20: Moku voltage LUT record creation
        test_lut_record <= create_moku_voltage_lut_record(3.3);
        wait for 1 ns;
        test_passed := (test_lut_record.valid = '1') and
                       (test_lut_record.data_array'length = 101);
        report_test("Moku voltage LUT record creation", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 7: Voltage Conversion Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 7: Voltage Conversion Tests ---"));
        writeline(output, l);
        
        -- Test 21: Voltage to percent index conversion
        test_index <= moku_voltage_to_percent_index(-5.0);
        wait for 1 ns;
        test_passed := (test_index = 0);
        report_test("Voltage to percent index (-5V)", test_passed, test_number, all_passed);
        
        test_index <= moku_voltage_to_percent_index(0.0);
        wait for 1 ns;
        test_passed := (test_index = 50);
        report_test("Voltage to percent index (0V)", test_passed, test_number, all_passed);
        
        test_index <= moku_voltage_to_percent_index(5.0);
        wait for 1 ns;
        test_passed := (test_index = 100);
        report_test("Voltage to percent index (5V)", test_passed, test_number, all_passed);
        
        -- Test 22: Percent index to voltage conversion
        test_voltage <= percent_index_to_moku_voltage(0);
        wait for 1 ns;
        test_passed := (abs(test_voltage - (-5.0)) < 0.001);
        report_test("Percent index to voltage (0)", test_passed, test_number, all_passed);
        
        test_voltage <= percent_index_to_moku_voltage(50);
        wait for 1 ns;
        test_passed := (abs(test_voltage - 0.0) < 0.001);
        report_test("Percent index to voltage (50)", test_passed, test_number, all_passed);
        
        test_voltage <= percent_index_to_moku_voltage(100);
        wait for 1 ns;
        test_passed := (abs(test_voltage - 5.0) < 0.001);
        report_test("Percent index to voltage (100)", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 8: Enhanced Test Data Generation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 8: Enhanced Test Data Generation Tests ---"));
        writeline(output, l);
        
        -- Test 23: Test LUT data generation
        test_lut_data <= generate_test_percent_lut_data(0);
        wait for 1 ns;
        test_passed := (test_lut_data'length = 101);
        report_test("Test LUT data generation", test_passed, test_number, all_passed);
        
        -- Test 24: Test LUT record generation
        test_lut_record <= generate_test_percent_lut_record(1);
        wait for 1 ns;
        test_passed := (test_lut_record.valid = '1');
        report_test("Test LUT record generation", test_passed, test_number, all_passed);
        
        -- Test 25: Test voltage generation
        test_voltage <= generate_test_voltage(0);
        wait for 1 ns;
        test_passed := (abs(test_voltage - (-5.0)) < 0.001);
        report_test("Test voltage generation", test_passed, test_number, all_passed);
        
        -- Test 26: Test percent index generation
        test_index <= generate_test_percent_index(0);
        wait for 1 ns;
        test_passed := (test_index = 0);
        report_test("Test percent index generation", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 9: Unit Validation Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 9: Unit Validation Tests ---"));
        writeline(output, l);
        
        -- Test 27: Expected units for record fields
        test_passed := (get_expected_units("data_array") = "package") and
                       (get_expected_units("crc") = "crc") and
                       (get_expected_units("valid") = "signal") and
                       (get_expected_units("size") = "index");
        report_test("Expected units for record fields", test_passed, test_number, all_passed);
        
        -- Test 28: Units consistency validation for record
        test_passed := validate_units_consistency(test_lut_record);
        report_test("Units consistency validation for record", test_passed, test_number, all_passed);
        
        -- Test 29: Units consistency validation for data array
        test_passed := validate_units_consistency_data(test_lut_data);
        report_test("Units consistency validation for data array", test_passed, test_number, all_passed);
        
        -- =============================================================================
        -- GROUP 10: Predefined LUT Constants Tests
        -- =============================================================================
        writeline(output, l);
        write(l, string'("--- Group 10: Predefined LUT Constants Tests ---"));
        writeline(output, l);
        
        -- Test 30: Predefined LUT data arrays
        test_passed := (LINEAR_5V_LUT_DATA'length = 101) and
                       (LINEAR_3V3_LUT_DATA'length = 101) and
                       (MOKU_5V_LUT_DATA'length = 101) and
                       (MOKU_3V3_LUT_DATA'length = 101) and
                       (MOKU_BIPOLAR_LUT_DATA'length = 101);
        report_test("Predefined LUT data arrays", test_passed, test_number, all_passed);
        
        -- Test 31: Predefined LUT records
        test_passed := (LINEAR_5V_LUT.valid = '1') and
                       (LINEAR_3V3_LUT.valid = '1') and
                       (MOKU_5V_LUT.valid = '1') and
                       (MOKU_3V3_LUT.valid = '1') and
                       (MOKU_BIPOLAR_LUT.valid = '1');
        report_test("Predefined LUT records", test_passed, test_number, all_passed);
        
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
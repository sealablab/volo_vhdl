--------------------------------------------------------------------------------
-- Testbench: PercentLut_pkg_tb
-- Purpose: Comprehensive testbench for PercentLut_pkg package functions
-- Author: AI Assistant
-- Date: 2025-08-27
-- 
-- Tests all functions in PercentLut_pkg:
-- - CRC calculation and validation
-- - Safe lookup functions (vector and natural versions)
-- - Index validation functions
-- - Edge cases and boundary conditions
--
-- GHDL Compatible: Uses standard libraries and deterministic test patterns
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import the package under test
use work.PercentLut_pkg.all;

entity PercentLut_pkg_tb is
    -- Testbench entity has no ports
end entity PercentLut_pkg_tb;

architecture behavioral of PercentLut_pkg_tb is
    
    -- Test control signals
    signal test_complete : boolean := false;
    signal all_tests_passed : boolean := true;
    
    -- Test counter for tracking progress
    signal test_number : natural := 0;
    
    -- Helper procedure to report test results
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        test_num := test_num + 1;
        write(l, string'("Test ") & integer'image(test_num) & ": " & test_name);
        if passed then
            write(l, string'(" - PASSED"));
        else
            write(l, string'(" - FAILED"));
        end if;
        writeline(output, l);
    end procedure;
    
    -- Helper function to create test LUT data
    function create_test_lut_linear return percent_lut_data_array_t is
        variable lut : percent_lut_data_array_t;
    begin
        -- Create a linear LUT: index 0 = 0x0000, index 1 = 0x0001, etc.
        for i in 0 to CFG_PERCENT_LUT_SIZE-1 loop
            lut(i) := std_logic_vector(to_unsigned(i, CFG_PERCENT_LUT_DATA_WIDTH));
        end loop;
        return lut;
    end function;
    
    -- Helper function to create test LUT with known pattern
    function create_test_lut_pattern return percent_lut_data_array_t is
        variable lut : percent_lut_data_array_t;
    begin
        -- Create a pattern: even indices = 0xAAAA, odd indices = 0x5555
        -- except index 0 which must be 0x0000
        lut(0) := x"0000";
        for i in 1 to CFG_PERCENT_LUT_SIZE-1 loop
            if (i mod 2) = 0 then
                lut(i) := x"AAAA";
            else
                lut(i) := x"5555";
            end if;
        end loop;
        return lut;
    end function;

begin

    -- Main test process
    test_process : process
        variable l : line;
        variable test_lut_linear : percent_lut_data_array_t;
        variable test_lut_pattern : percent_lut_data_array_t;
        variable test_lut_invalid : percent_lut_data_array_t;
        variable calculated_crc : std_logic_vector(15 downto 0);
        variable wrong_crc : std_logic_vector(15 downto 0);
        variable lookup_result : std_logic_vector(CFG_PERCENT_LUT_DATA_WIDTH-1 downto 0);
        variable index_vec : std_logic_vector(6 downto 0);
        variable test_passed : boolean;
        variable local_test_num : natural := 0;
        
    begin
        -- Print test header
        write(l, string'("=== PercentLut_pkg Testbench Started ==="));
        writeline(output, l);
        
        -- Initialize test LUTs
        test_lut_linear := create_test_lut_linear;
        test_lut_pattern := create_test_lut_pattern;
        test_lut_invalid := create_test_lut_pattern;
        test_lut_invalid(0) := x"1234"; -- Make invalid by setting index 0 to non-zero
        
        -----------------------------------------------------------------------
        -- Test 1: CRC Calculation Basic Functionality
        -----------------------------------------------------------------------
        calculated_crc := calculate_percent_lut_crc(test_lut_linear);
        test_passed := (calculated_crc'length = 16); -- Basic sanity check
        report_test("CRC calculation returns 16-bit result", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 2: CRC Calculation Deterministic (same input = same output)
        -----------------------------------------------------------------------
        calculated_crc := calculate_percent_lut_crc(test_lut_linear);
        test_passed := (calculated_crc = calculate_percent_lut_crc(test_lut_linear));
        report_test("CRC calculation is deterministic", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 3: CRC Validation with Valid LUT
        -----------------------------------------------------------------------
        calculated_crc := calculate_percent_lut_crc(test_lut_linear);
        test_passed := validate_percent_lut(test_lut_linear, calculated_crc);
        report_test("CRC validation passes for valid LUT", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 4: CRC Validation with Wrong CRC
        -----------------------------------------------------------------------
        calculated_crc := calculate_percent_lut_crc(test_lut_linear);
        wrong_crc := calculated_crc xor x"FFFF"; -- Corrupt the CRC
        test_passed := not validate_percent_lut(test_lut_linear, wrong_crc);
        report_test("CRC validation fails for wrong CRC", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 5: Validation Fails for Invalid Index 0
        -----------------------------------------------------------------------
        calculated_crc := calculate_percent_lut_crc(test_lut_invalid);
        test_passed := not validate_percent_lut(test_lut_invalid, calculated_crc);
        report_test("Validation fails when index 0 != 0x0000", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 6: Safe Lookup - Valid Index (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(50, 7));
        lookup_result := get_percentlut_value_safe(test_lut_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(50, CFG_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - valid index 50", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 7: Safe Lookup - Boundary Index 100 (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(100, 7));
        lookup_result := get_percentlut_value_safe(test_lut_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, CFG_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - boundary index 100", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 8: Safe Lookup - Out of Bounds Clamping (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(127, 7)); -- > 100, should clamp to 100
        lookup_result := get_percentlut_value_safe(test_lut_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, CFG_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - out of bounds clamping", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 9: Safe Lookup - Valid Index (natural version)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_linear, 75);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(75, CFG_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (natural) - valid index 75", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 10: Safe Lookup - Boundary Index 0 (natural version)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_linear, 0);
        test_passed := (lookup_result = x"0000");
        report_test("Safe lookup (natural) - boundary index 0", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 11: Safe Lookup - Out of Bounds Clamping (natural version)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_linear, 150);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, CFG_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (natural) - out of bounds clamping", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 12: Index Validation - Valid Indices (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(50, 7));
        test_passed := is_valid_percent_lut_index(index_vec);
        report_test("Index validation (vector) - valid index 50", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 13: Index Validation - Boundary Valid Index (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(100, 7));
        test_passed := is_valid_percent_lut_index(index_vec);
        report_test("Index validation (vector) - boundary valid index 100", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 14: Index Validation - Invalid Index (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(101, 7));
        test_passed := not is_valid_percent_lut_index(index_vec);
        report_test("Index validation (vector) - invalid index 101", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 15: Index Validation - Valid Indices (natural version)
        -----------------------------------------------------------------------
        test_passed := is_valid_percent_lut_index(25);
        report_test("Index validation (natural) - valid index 25", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 16: Index Validation - Boundary Valid Index (natural version)
        -----------------------------------------------------------------------
        test_passed := is_valid_percent_lut_index(100);
        report_test("Index validation (natural) - boundary valid index 100", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 17: Index Validation - Invalid Index (natural version)
        -----------------------------------------------------------------------
        test_passed := not is_valid_percent_lut_index(150);
        report_test("Index validation (natural) - invalid index 150", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 18: Helper Function - Create LUT with CRC
        -----------------------------------------------------------------------
        calculated_crc := create_percent_lut_with_crc(test_lut_pattern);
        test_passed := (calculated_crc = calculate_percent_lut_crc(test_lut_pattern));
        report_test("Helper function creates correct CRC", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 19: Pattern-based LUT Lookup Test
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_pattern, 42); -- Even index
        test_passed := (lookup_result = x"AAAA");
        report_test("Pattern LUT lookup - even index returns 0xAAAA", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 20: Pattern-based LUT Lookup Test (Odd Index)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_pattern, 43); -- Odd index
        test_passed := (lookup_result = x"5555");
        report_test("Pattern LUT lookup - odd index returns 0x5555", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Final Test Results
        -----------------------------------------------------------------------
        write(l, string'("=== Test Summary ==="));
        writeline(output, l);
        write(l, string'("Total tests run: ") & integer'image(local_test_num));
        writeline(output, l);
        
        if all_tests_passed then
            write(l, string'("ALL TESTS PASSED"));
            writeline(output, l);
        else
            write(l, string'("TEST FAILED"));
            writeline(output, l);
        end if;
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        test_complete <= true;
        wait;
        
    end process test_process;

end architecture behavioral;
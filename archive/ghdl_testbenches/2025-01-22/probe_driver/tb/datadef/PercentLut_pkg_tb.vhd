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

-- Import the packages under test
use work.PercentLut_pkg.all;
use work.Moku_Voltage_pkg.all;

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
        for i in 0 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            lut(i) := std_logic_vector(to_unsigned(i, SYSTEM_PERCENT_LUT_DATA_WIDTH));
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
        for i in 1 to SYSTEM_PERCENT_LUT_SIZE-1 loop
            if (i mod 2) = 0 then
                lut(i) := x"AAAA";
            else
                lut(i) := x"5555";
            end if;
        end loop;
        return lut;
    end function;
    
    -- Helper function to create test LUT record
    function create_test_lut_record(lut_data : percent_lut_data_array_t) return percent_lut_record_t is
    begin
        return create_percent_lut_record(lut_data);
    end function;

begin

    -- Main test process
    test_process : process
        variable l : line;
        variable test_lut_linear : percent_lut_data_array_t;
        variable test_lut_pattern : percent_lut_data_array_t;
        variable test_lut_invalid : percent_lut_data_array_t;
        variable test_lut_rec_linear : percent_lut_record_t;
        variable test_lut_rec_pattern : percent_lut_record_t;
        variable test_lut_rec_invalid : percent_lut_record_t;
        variable calculated_crc : std_logic_vector(15 downto 0);
        variable wrong_crc : std_logic_vector(15 downto 0);
        variable lookup_result : std_logic_vector(SYSTEM_PERCENT_LUT_DATA_WIDTH-1 downto 0);
        variable index_vec : std_logic_vector(6 downto 0);
        variable test_passed : boolean;
        variable local_test_num : natural := 0;
        
        -- Variables for voltage integration tests
        variable voltage_lut : percent_lut_data_array_t;
        variable voltage_lut_rec : percent_lut_record_t;
        variable moku_lut : percent_lut_data_array_t;
        variable moku_lut_rec : percent_lut_record_t;
        variable bipolar_lut : percent_lut_data_array_t;
        variable bipolar_lut_rec : percent_lut_record_t;
        variable test_voltage : real;
        variable lut_index : natural;
        variable back_to_voltage : real;
        
    begin
        -- Print test header
        write(l, string'("=== PercentLut_pkg Testbench Started ==="));
        writeline(output, l);
        
        -- Initialize test LUTs
        test_lut_linear := create_test_lut_linear;
        test_lut_pattern := create_test_lut_pattern;
        test_lut_invalid := create_test_lut_pattern;
        test_lut_invalid(0) := x"1234"; -- Make invalid by setting index 0 to non-zero
        
        -- Initialize test LUT records
        test_lut_rec_linear := create_test_lut_record(test_lut_linear);
        test_lut_rec_pattern := create_test_lut_record(test_lut_pattern);
        test_lut_rec_invalid := create_test_lut_record(test_lut_invalid);
        
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
        test_passed := (lookup_result = std_logic_vector(to_unsigned(50, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - valid index 50", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 7: Safe Lookup - Boundary Index 100 (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(100, 7));
        lookup_result := get_percentlut_value_safe(test_lut_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - boundary index 100", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 8: Safe Lookup - Out of Bounds Clamping (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(127, 7)); -- > 100, should clamp to 100
        lookup_result := get_percentlut_value_safe(test_lut_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
        report_test("Safe lookup (vector) - out of bounds clamping", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 9: Safe Lookup - Valid Index (natural version)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_linear, 75);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(75, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
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
        test_passed := (lookup_result = std_logic_vector(to_unsigned(100, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
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
        -- Test 21: Record-based LUT Creation and Validation
        -----------------------------------------------------------------------
        test_passed := validate_percent_lut_record(test_lut_rec_linear);
        report_test("Record-based LUT validation - valid record", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 22: Record-based LUT Validation - Invalid Record
        -----------------------------------------------------------------------
        test_passed := not validate_percent_lut_record(test_lut_rec_invalid);
        report_test("Record-based LUT validation - invalid record", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 23: Record-based LUT Validity Check
        -----------------------------------------------------------------------
        test_passed := is_percent_lut_record_valid(test_lut_rec_linear);
        report_test("Record-based LUT validity check - valid record", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 24: Record-based LUT Validity Check - Invalid Record
        -----------------------------------------------------------------------
        test_passed := not is_percent_lut_record_valid(test_lut_rec_invalid);
        report_test("Record-based LUT validity check - invalid record", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 25: Record-based Safe Lookup - Valid Index (std_logic_vector version)
        -----------------------------------------------------------------------
        index_vec := std_logic_vector(to_unsigned(30, 7));
        lookup_result := get_percentlut_value_safe(test_lut_rec_linear, index_vec);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(30, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
        report_test("Record-based safe lookup (vector) - valid index 30", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 26: Record-based Safe Lookup - Valid Index (natural version)
        -----------------------------------------------------------------------
        lookup_result := get_percentlut_value_safe(test_lut_rec_linear, 60);
        test_passed := (lookup_result = std_logic_vector(to_unsigned(60, SYSTEM_PERCENT_LUT_DATA_WIDTH)));
        report_test("Record-based safe lookup (natural) - valid index 60", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 27: Record-based Safe Lookup - Invalid Record Returns Zero
        -----------------------------------------------------------------------
        test_lut_rec_invalid.valid := '0'; -- Make record invalid
        lookup_result := get_percentlut_value_safe(test_lut_rec_invalid, 50);
        test_passed := (lookup_result = x"0000");
        report_test("Record-based safe lookup - invalid record returns zero", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 28: Record Field Access Helper Functions
        -----------------------------------------------------------------------
        test_passed := (get_percent_lut_data_array(test_lut_rec_linear) = test_lut_linear);
        report_test("Record field access - data array", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 29: Record Field Access Helper Functions - CRC
        -----------------------------------------------------------------------
        test_passed := (get_percent_lut_crc(test_lut_rec_linear) = calculate_percent_lut_crc(test_lut_linear));
        report_test("Record field access - CRC", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 30: Record Field Access Helper Functions - Valid Flag
        -----------------------------------------------------------------------
        test_passed := (get_percent_lut_valid(test_lut_rec_linear) = '1');
        report_test("Record field access - valid flag", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 31: Record Field Access Helper Functions - Size
        -----------------------------------------------------------------------
        test_passed := (get_percent_lut_size(test_lut_rec_linear) = std_logic_vector(to_unsigned(100, 7)));
        report_test("Record field access - size", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 32: Record Update Functions - Update Data
        -----------------------------------------------------------------------
        test_lut_rec_linear := update_percent_lut_record_data(test_lut_rec_linear, test_lut_pattern);
        test_passed := (test_lut_rec_linear.data_array = test_lut_pattern);
        report_test("Record update - data update", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 33: Record Update Functions - Update Size
        -----------------------------------------------------------------------
        test_lut_rec_linear := update_percent_lut_record_size(test_lut_rec_linear, 50);
        test_passed := (get_percent_lut_size(test_lut_rec_linear) = std_logic_vector(to_unsigned(50, 7)));
        report_test("Record update - size update", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- MOKU VOLTAGE INTEGRATION TESTS
        -----------------------------------------------------------------------
        
        -----------------------------------------------------------------------
        -- Test 34: Voltage to LUT Index Conversion - Valid Range
        -----------------------------------------------------------------------
        test_passed := (voltage_to_lut_index(2.5, 0.0, 5.0) = 50);
        report_test("Voltage to LUT index - 2.5V in 0-5V range = index 50", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 35: Voltage to LUT Index Conversion - Boundary Values
        -----------------------------------------------------------------------
        test_passed := (voltage_to_lut_index(0.0, 0.0, 5.0) = 0) and 
                       (voltage_to_lut_index(5.0, 0.0, 5.0) = 100);
        report_test("Voltage to LUT index - boundary values (0V=0, 5V=100)", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 36: Voltage to LUT Index Conversion - Out of Range Clamping
        -----------------------------------------------------------------------
        test_passed := (voltage_to_lut_index(-1.0, 0.0, 5.0) = 0) and 
                       (voltage_to_lut_index(6.0, 0.0, 5.0) = 100);
        report_test("Voltage to LUT index - out of range clamping", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 37: LUT Index to Voltage Conversion - Valid Range
        -----------------------------------------------------------------------
        test_passed := (abs(lut_index_to_voltage(50, 0.0, 5.0) - 2.5) < 0.01);
        report_test("LUT index to voltage - index 50 in 0-5V range = 2.5V", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 38: LUT Index to Voltage Conversion - Boundary Values
        -----------------------------------------------------------------------
        test_passed := (lut_index_to_voltage(0, 0.0, 5.0) = 0.0) and 
                       (lut_index_to_voltage(100, 0.0, 5.0) = 5.0);
        report_test("LUT index to voltage - boundary values (0=0V, 100=5V)", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 39: Moku Voltage to Percent Index - Unipolar Range
        -----------------------------------------------------------------------
        test_passed := (moku_voltage_to_percent_index(2.5) = 50);
        report_test("Moku voltage to percent index - 2.5V = index 50", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 40: Percent Index to Moku Voltage - Unipolar Range
        -----------------------------------------------------------------------
        test_passed := (abs(percent_index_to_moku_voltage(50) - 2.5) < 0.01);
        report_test("Percent index to Moku voltage - index 50 = 2.5V", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 41: Moku Bipolar Voltage to Percent Index - Bipolar Range
        -----------------------------------------------------------------------
        test_passed := (moku_bipolar_voltage_to_percent_index(0.0) = 50) and
                       (moku_bipolar_voltage_to_percent_index(-2.5) = 25) and
                       (moku_bipolar_voltage_to_percent_index(2.5) = 75);
        report_test("Moku bipolar voltage to percent index - 0V=50, -2.5V=25, +2.5V=75", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 42: Percent Index to Moku Bipolar Voltage - Bipolar Range
        -----------------------------------------------------------------------
        test_passed := (abs(percent_index_to_moku_bipolar_voltage(50) - 0.0) < 0.01) and
                       (abs(percent_index_to_moku_bipolar_voltage(25) - (-2.5)) < 0.01) and
                       (abs(percent_index_to_moku_bipolar_voltage(75) - 2.5) < 0.01);
        report_test("Percent index to Moku bipolar voltage - 50=0V, 25=-2.5V, 75=+2.5V", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 43: Create Voltage Percent LUT - Basic Functionality
        -----------------------------------------------------------------------
        voltage_lut := create_voltage_percent_lut(0.0, 5.0);
        test_passed := (voltage_lut(0) = x"0000") and (voltage_lut(100) /= x"0000");
        report_test("Create voltage percent LUT - basic functionality", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 44: Create Voltage Percent LUT Record - Basic Functionality
        -----------------------------------------------------------------------
        voltage_lut_rec := create_voltage_percent_lut_record(0.0, 5.0);
        test_passed := (voltage_lut_rec.valid = '1') and validate_percent_lut_record(voltage_lut_rec);
        report_test("Create voltage percent LUT record - basic functionality", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 45: Create Moku Voltage LUT - Unipolar Range
        -----------------------------------------------------------------------
        moku_lut := create_moku_voltage_lut(5.0);
        test_passed := (moku_lut(0) = x"0000") and (moku_lut(100) /= x"0000");
        report_test("Create Moku voltage LUT - unipolar 0-5V range", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 46: Create Moku Voltage LUT Record - Unipolar Range
        -----------------------------------------------------------------------
        moku_lut_rec := create_moku_voltage_lut_record(3.3);
        test_passed := (moku_lut_rec.valid = '1') and validate_percent_lut_record(moku_lut_rec);
        report_test("Create Moku voltage LUT record - unipolar 0-3.3V range", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 47: Create Moku Bipolar Voltage LUT - Bipolar Range
        -----------------------------------------------------------------------
        bipolar_lut := create_moku_bipolar_voltage_lut;
        test_passed := (bipolar_lut(0) /= x"0000") and (bipolar_lut(100) /= x"0000");
        report_test("Create Moku bipolar voltage LUT - bipolar -5V to +5V range", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 48: Create Moku Bipolar Voltage LUT Record - Bipolar Range
        -----------------------------------------------------------------------
        bipolar_lut_rec := create_moku_bipolar_voltage_lut_record;
        test_passed := (bipolar_lut_rec.valid = '1') and validate_percent_lut_record(bipolar_lut_rec);
        report_test("Create Moku bipolar voltage LUT record - bipolar -5V to +5V range", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 49: Predefined Moku LUT Constants - MOKU_5V_LUT
        -----------------------------------------------------------------------
        test_passed := (MOKU_5V_LUT.valid = '1') and validate_percent_lut_record(MOKU_5V_LUT);
        report_test("Predefined MOKU_5V_LUT constant - valid and properly formed", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 50: Predefined Moku LUT Constants - MOKU_3V3_LUT
        -----------------------------------------------------------------------
        test_passed := (MOKU_3V3_LUT.valid = '1') and validate_percent_lut_record(MOKU_3V3_LUT);
        report_test("Predefined MOKU_3V3_LUT constant - valid and properly formed", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 51: Predefined Moku LUT Constants - MOKU_BIPOLAR_LUT
        -----------------------------------------------------------------------
        test_passed := (MOKU_BIPOLAR_LUT.valid = '1') and validate_percent_lut_record(MOKU_BIPOLAR_LUT);
        report_test("Predefined MOKU_BIPOLAR_LUT constant - valid and properly formed", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 52: Voltage Integration Round-trip Test - Unipolar
        -----------------------------------------------------------------------
        test_voltage := 3.7;
        lut_index := moku_voltage_to_percent_index(test_voltage);
        back_to_voltage := percent_index_to_moku_voltage(lut_index);
        test_passed := (abs(back_to_voltage - test_voltage) < 0.1); -- Allow some rounding error
        report_test("Voltage integration round-trip - unipolar 3.7V", test_passed, local_test_num);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -----------------------------------------------------------------------
        -- Test 53: Voltage Integration Round-trip Test - Bipolar
        -----------------------------------------------------------------------
        test_voltage := -1.8;
        lut_index := moku_bipolar_voltage_to_percent_index(test_voltage);
        back_to_voltage := percent_index_to_moku_bipolar_voltage(lut_index);
        test_passed := (abs(back_to_voltage - test_voltage) < 0.1); -- Allow some rounding error
        report_test("Voltage integration round-trip - bipolar -1.8V", test_passed, local_test_num);
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
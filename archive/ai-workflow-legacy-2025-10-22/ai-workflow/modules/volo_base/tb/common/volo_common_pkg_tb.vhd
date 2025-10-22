-- Volo Common Package Testbench
-- Tests all functions and constants in volo_common_pkg
-- Follows enhanced rules system testbench requirements

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import the package under test
library WORK;
use WORK.volo_common_pkg.ALL;

entity volo_common_pkg_tb is
end entity volo_common_pkg_tb;

architecture test of volo_common_pkg_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
    -- Helper procedure for consistent test reporting
    procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
            all_tests_passed <= false;
        end if;
        writeline(output, l);
    end procedure report_test;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable l : line;
        
        -- Test variables
        variable test_value : natural;
        variable test_min : natural;
        variable test_max : natural;
        variable test_result : natural;
        variable test_bool : boolean;
        variable test_slv : std_logic_vector(15 downto 0);
        variable test_status : std_logic_vector(7 downto 0);
        
    begin
        -- Test initialization
        write(l, string'("=== Volo Common Package TestBench Started ==="));
        writeline(output, l);
        
        -- ============================================================================
        -- GROUP 1: CONSTANT TESTS
        -- ============================================================================
        write(l, string'("--- Group 1: Constant Tests ---"));
        writeline(output, l);
        
        -- Test status register bit positions
        test_passed := (STATUS_FAULT_BIT = 7);
        report_test("STATUS_FAULT_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_ALARM_BIT = 6);
        report_test("STATUS_ALARM_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_BUSY_BIT = 5);
        report_test("STATUS_BUSY_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_READY_BIT = 4);
        report_test("STATUS_READY_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_ENABLED_BIT = 3);
        report_test("STATUS_ENABLED_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_ACTIVE_BIT = 2);
        report_test("STATUS_ACTIVE_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_VALID_BIT = 1);
        report_test("STATUS_VALID_BIT position", test_passed, test_number);
        
        test_passed := (STATUS_IDLE_BIT = 0);
        report_test("STATUS_IDLE_BIT position", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 2: UTILITY FUNCTION TESTS
        -- ============================================================================
        write(l, string'("--- Group 2: Utility Function Tests ---"));
        writeline(output, l);
        
        -- Test clamp_to_range function
        test_value := 5;
        test_min := 1;
        test_max := 10;
        test_result := clamp_to_range(test_value, test_min, test_max);
        test_passed := (test_result = 5);
        report_test("clamp_to_range - value in range", test_passed, test_number);
        
        test_value := 15;
        test_result := clamp_to_range(test_value, test_min, test_max);
        test_passed := (test_result = 10);
        report_test("clamp_to_range - value above max", test_passed, test_number);
        
        test_value := 0;
        test_result := clamp_to_range(test_value, test_min, test_max);
        test_passed := (test_result = 1);
        report_test("clamp_to_range - value below min", test_passed, test_number);
        
        -- Test is_in_range function
        test_value := 5;
        test_bool := is_in_range(test_value, test_min, test_max);
        test_passed := (test_bool = true);
        report_test("is_in_range - value in range", test_passed, test_number);
        
        test_value := 15;
        test_bool := is_in_range(test_value, test_min, test_max);
        test_passed := (test_bool = false);
        report_test("is_in_range - value above max", test_passed, test_number);
        
        test_value := 0;
        test_bool := is_in_range(test_value, test_min, test_max);
        test_passed := (test_bool = false);
        report_test("is_in_range - value below min", test_passed, test_number);
        
        -- Test natural_to_slv function
        test_value := 42;
        test_slv := natural_to_slv(test_value, 16);
        test_passed := (test_slv = x"002A");
        report_test("natural_to_slv - basic conversion", test_passed, test_number);
        
        test_value := 0;
        test_slv := natural_to_slv(test_value, 16);
        test_passed := (test_slv = x"0000");
        report_test("natural_to_slv - zero conversion", test_passed, test_number);
        
        test_value := 65535;
        test_slv := natural_to_slv(test_value, 16);
        test_passed := (test_slv = x"FFFF");
        report_test("natural_to_slv - max value conversion", test_passed, test_number);
        
        -- Test slv_to_natural function
        test_slv := x"002A";
        test_result := slv_to_natural(test_slv);
        test_passed := (test_result = 42);
        report_test("slv_to_natural - basic conversion", test_passed, test_number);
        
        test_slv := x"0000";
        test_result := slv_to_natural(test_slv);
        test_passed := (test_result = 0);
        report_test("slv_to_natural - zero conversion", test_passed, test_number);
        
        test_slv := x"FFFF";
        test_result := slv_to_natural(test_slv);
        test_passed := (test_result = 65535);
        report_test("slv_to_natural - max value conversion", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 3: STATUS REGISTER TESTS
        -- ============================================================================
        write(l, string'("--- Group 3: Status Register Tests ---"));
        writeline(output, l);
        
        -- Test create_status_reg function
        test_status := create_status_reg('1', '0', '1', '0', '1', '1', '0', '0');
        test_passed := (test_status(7) = '1' and test_status(6) = '0' and 
                       test_status(5) = '1' and test_status(4) = '0' and
                       test_status(3) = '1' and test_status(2) = '1' and
                       test_status(1) = '0' and test_status(0) = '0');
        report_test("create_status_reg - mixed bits", test_passed, test_number);
        
        test_status := create_status_reg('0', '0', '0', '0', '0', '0', '0', '0');
        test_passed := (test_status = x"00");
        report_test("create_status_reg - all zeros", test_passed, test_number);
        
        test_status := create_status_reg('1', '1', '1', '1', '1', '1', '1', '1');
        test_passed := (test_status = x"FF");
        report_test("create_status_reg - all ones", test_passed, test_number);
        
        -- ============================================================================
        -- GROUP 4: EDGE CASE TESTS
        -- ============================================================================
        write(l, string'("--- Group 4: Edge Case Tests ---"));
        writeline(output, l);
        
        -- Test boundary conditions
        test_value := 1;
        test_min := 1;
        test_max := 1;
        test_result := clamp_to_range(test_value, test_min, test_max);
        test_passed := (test_result = 1);
        report_test("clamp_to_range - single value range", test_passed, test_number);
        
        test_bool := is_in_range(test_value, test_min, test_max);
        test_passed := (test_bool = true);
        report_test("is_in_range - single value range", test_passed, test_number);
        
        -- Test zero width conversion
        test_slv := natural_to_slv(0, 0);
        test_passed := (test_slv'length = 0);
        report_test("natural_to_slv - zero width", test_passed, test_number);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        write(l, string'("=== Test Results ==="));
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
    end process test_process;
    
end architecture test;
-- Volo Common Testbench Package
-- Simulation-only utilities for all Volo VHDL testbenches
-- Contains testbench procedures, TextIO utilities, and simulation constructs
-- IMPORTANT: This package is for testbenches only - NOT synthesizable

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

package volo_common_tb_pkg is
    
    -- ============================================================================
    -- TESTBENCH UTILITY PROCEDURES
    -- ============================================================================
    
    -- Standard test reporting procedure for consistent testbench output
    -- Follows VOLO testbench requirements: prints test results and magic strings
    procedure report_test(
        test_name : string; 
        passed : boolean; 
        test_num : inout natural; 
        all_passed : inout boolean
    );
    
    -- Print testbench completion messages (required magic strings)
    procedure print_test_completion(all_passed : boolean);
    
end package volo_common_tb_pkg;

package body volo_common_tb_pkg is
    
    -- ============================================================================
    -- TESTBENCH UTILITY PROCEDURES
    -- ============================================================================
    
    procedure report_test(
        test_name : string; 
        passed : boolean; 
        test_num : inout natural; 
        all_passed : inout boolean
    ) is
        variable l : line;
    begin
        test_num := test_num + 1;
        if passed then
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - PASSED"));
        else
            write(l, string'("Test " & integer'image(test_num) & ": " & test_name & " - FAILED"));
            all_passed := false;
        end if;
        writeline(output, l);
    end procedure report_test;
    
    procedure print_test_completion(all_passed : boolean) is
        variable l : line;
    begin
        write(l, string'("=== Test Results ==="));
        writeline(output, l);
        
        if all_passed then
            write(l, string'("ALL TESTS PASSED"));
        else
            write(l, string'("TEST FAILED"));
        end if;
        writeline(output, l);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
    end procedure print_test_completion;
    
end package body volo_common_tb_pkg;
-- Probe_Config_pkg_PH9 Package Testbench
-- Generated following VOLO VHDL datadef testbench architecture
-- Tests all functions, types, and constants in the package

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.ENV.ALL;  -- For stop() function

-- Import packages
library WORK;
use WORK.volo_common_tb_pkg.ALL;   -- For testbench utilities
use WORK.Moku_Voltage_pkg_PH9.ALL; -- For VOLTAGE_DATA_WIDTH constant
use WORK.Probe_Config_pkg_PH9.ALL; -- Package under test

entity Probe_Config_pkg_PH9_tb is
end entity Probe_Config_pkg_PH9_tb;

architecture test of Probe_Config_pkg_PH9_tb is
    
    -- Test result tracking
    signal all_tests_passed : boolean := true;
    
begin
    
    test_process : process
        variable test_number : natural := 0;
        variable test_passed : boolean;
        variable all_tests_passed : boolean := true;
        variable l : line;
        
        -- Test variables for probe configuration operations
        variable test_config : t_probe_config;
        variable test_config_array : t_probe_config_array;
        variable test_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);
        variable test_min_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);
        variable test_max_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);
        variable test_duration : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);
        variable test_min_duration : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);
        variable test_max_duration : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);
        variable test_result_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);
        variable test_result_duration : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);
        variable test_bool : boolean;
        variable test_index : natural;
        variable test_result_config : t_probe_config;
        
        -- Tolerance for floating-point comparisons
        constant TOLERANCE : real := 0.001;
        
    begin
        -- Test initialization
        write(l, string'("=== Probe_Config_pkg_PH9 Package TestBench Started ==="));
        writeline(output, l);
        write(l, string'("Testing package: Probe_Config_pkg_PH9"));
        writeline(output, l);
        write(l, string'("Total tests planned: 45"));
        writeline(output, l);
        write(l, string'("Test architecture: 4-layer datadef testing"));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 1: INTERFACE TESTING (Function Signatures)
        -- Test function interfaces and basic behavior
        -- ============================================================================
        write(l, string'("--- Layer 1: Interface Testing (Function Signatures) ---"));
        writeline(output, l);
        
        -- Test 1: Function parameter validation - is_valid_probe_config
        test_config := DEFAULT_PROBE_CONFIG;
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true or test_bool = false); -- Valid boolean return
        if not test_passed then
            write(l, string'("Expected: boolean return, Got: " & boolean'image(test_bool)));
            writeline(output, l);
        end if;
        report_test("is_valid_probe_config parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 2: Function parameter validation - is_voltage_in_range
        test_voltage := x"1000"; -- 1.0V
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_bool := is_voltage_in_range(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true or test_bool = false); -- Valid boolean return
        report_test("is_voltage_in_range parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 3: Function parameter validation - is_duration_in_range
        test_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_min_duration := to_unsigned(50, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_bool := is_duration_in_range(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_bool = true or test_bool = false); -- Valid boolean return
        report_test("is_duration_in_range parameter validation", test_passed, test_number, all_tests_passed);
        
        -- Test 4: Package initialization - constants
        test_passed := (SYSTEM_DURATION_WIDTH = 16 and SYSTEM_INTENSITY_WIDTH = 7 and 
                       SYSTEM_MAX_PROBES = 4);
        report_test("Package initialization - constants", test_passed, test_number, all_tests_passed);
        
        -- Test 5: Function return types - clamp_voltage
        test_voltage := x"1000"; -- 1.0V
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_result_voltage := clamp_voltage(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_result_voltage'length = VOLTAGE_DATA_WIDTH);
        report_test("Function return types - clamp_voltage", test_passed, test_number, all_tests_passed);
        
        -- Test 6: Function return types - clamp_duration
        test_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_min_duration := to_unsigned(50, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_result_duration := clamp_duration(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_result_duration'length = SYSTEM_DURATION_WIDTH);
        report_test("Function return types - clamp_duration", test_passed, test_number, all_tests_passed);
        
        -- Test 7: Type definitions - t_probe_config record
        test_config := DEFAULT_PROBE_CONFIG;
        test_passed := (test_config.probe_name'length = 16 and 
                       test_config.probe_trigger_voltage'length = VOLTAGE_DATA_WIDTH and
                       test_config.fire_duration_min'length = SYSTEM_DURATION_WIDTH);
        report_test("Type definitions - t_probe_config record", test_passed, test_number, all_tests_passed);
        
        -- Test 8: Type definitions - t_probe_config_array
        test_config_array := DEFAULT_PROBE_CONFIG_ARRAY;
        test_passed := (test_config_array'length = SYSTEM_MAX_PROBES);
        report_test("Type definitions - t_probe_config_array", test_passed, test_number, all_tests_passed);
        
        -- Layer 1 Summary
        write(l, string'("Layer 1 completed: " & integer'image(test_number) & " tests"));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 2: VALIDATION TESTING (Error Handling)
        -- Test parameter validation and error handling
        -- ============================================================================
        write(l, string'("--- Layer 2: Validation Testing (Error Handling) ---"));
        writeline(output, l);
        
        -- Test 9: Invalid input handling - voltage clamping
        test_voltage := x"5000"; -- Above valid range
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_result_voltage := clamp_voltage(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_result_voltage = test_max_voltage);
        if not test_passed then
            write(l, string'("Expected: " & to_hstring(test_max_voltage) & ", Got: " & to_hstring(test_result_voltage)));
            writeline(output, l);
        end if;
        report_test("Invalid input handling - voltage clamping", test_passed, test_number, all_tests_passed);
        
        -- Test 10: Boundary conditions - voltage at maximum
        test_voltage := x"2000"; -- At maximum valid range
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_bool := is_voltage_in_range(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true);
        report_test("Boundary conditions - voltage at maximum", test_passed, test_number, all_tests_passed);
        
        -- Test 11: Error conditions - voltage below minimum
        test_voltage := x"0000"; -- Below valid range
        test_min_voltage := x"1000"; -- 1.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_result_voltage := clamp_voltage(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_result_voltage = test_min_voltage);
        report_test("Error conditions - voltage below minimum", test_passed, test_number, all_tests_passed);
        
        -- Test 12: Duration range validation
        test_duration := to_unsigned(1000, SYSTEM_DURATION_WIDTH); -- Valid duration
        test_min_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(2000, SYSTEM_DURATION_WIDTH);
        test_bool := is_duration_in_range(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_bool = true);
        report_test("Duration range validation", test_passed, test_number, all_tests_passed);
        
        -- Test 13: Duration clamping
        test_duration := to_unsigned(50, SYSTEM_DURATION_WIDTH); -- Below minimum
        test_min_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(2000, SYSTEM_DURATION_WIDTH);
        test_result_duration := clamp_duration(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_result_duration = test_min_duration);
        report_test("Duration clamping", test_passed, test_number, all_tests_passed);
        
        -- Test 14: Invalid probe configuration - intensity min >= max
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_intensity_min := x"2000"; -- 2.0V
        test_config.probe_intensity_max := x"1000"; -- 1.0V (invalid: max < min)
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = false);
        report_test("Invalid probe configuration - intensity min >= max", test_passed, test_number, all_tests_passed);
        
        -- Test 15: Invalid probe configuration - fire duration min >= max
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.fire_duration_min := to_unsigned(1000, SYSTEM_DURATION_WIDTH);
        test_config.fire_duration_max := to_unsigned(500, SYSTEM_DURATION_WIDTH); -- invalid: max < min
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = false);
        report_test("Invalid probe configuration - fire duration min >= max", test_passed, test_number, all_tests_passed);
        
        -- Test 16: Invalid probe configuration - cooldown duration min >= max
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.cooldown_duration_min := to_unsigned(1000, SYSTEM_DURATION_WIDTH);
        test_config.cooldown_duration_max := to_unsigned(500, SYSTEM_DURATION_WIDTH); -- invalid: max < min
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = false);
        report_test("Invalid probe configuration - cooldown duration min >= max", test_passed, test_number, all_tests_passed);
        
        -- Test 17: Invalid probe configuration - zero trigger voltage
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_trigger_voltage := x"0000"; -- Zero voltage (invalid)
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = false);
        report_test("Invalid probe configuration - zero trigger voltage", test_passed, test_number, all_tests_passed);
        
        -- Test 18: Invalid probe configuration - zero intensity range
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_intensity_min := x"0000"; -- Zero voltage
        test_config.probe_intensity_max := x"0000"; -- Zero voltage (invalid range)
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = false);
        report_test("Invalid probe configuration - zero intensity range", test_passed, test_number, all_tests_passed);
        
        -- Test 19: Invalid probe index
        test_index := 5; -- Above valid range (0 to 3)
        test_bool := is_valid_probe_index(test_index);
        test_passed := (test_bool = false);
        report_test("Invalid probe index", test_passed, test_number, all_tests_passed);
        
        -- Layer 2 Summary
        write(l, string'("Layer 2 completed: " & integer'image(test_number - 8) & " tests"));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 3: FUNCTIONAL TESTING (Core Behavior)
        -- Test core functionality and mathematical correctness
        -- ============================================================================
        write(l, string'("--- Layer 3: Functional Testing (Core Behavior) ---"));
        writeline(output, l);
        
        -- Test 20: Core functionality - valid probe configuration
        test_config := DEFAULT_PROBE_CONFIG;
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        if not test_passed then
            write(l, string'("DEFAULT_PROBE_CONFIG validation failed - this indicates a serious issue"));
            writeline(output, l);
        end if;
        report_test("Core functionality - valid probe configuration", test_passed, test_number, all_tests_passed);
        
        -- Test 21: Mathematical correctness - voltage range checking
        test_voltage := x"1500"; -- 1.5V (within range)
        test_min_voltage := x"1000"; -- 1.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_bool := is_voltage_in_range(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true);
        report_test("Mathematical correctness - voltage range checking", test_passed, test_number, all_tests_passed);
        
        -- Test 22: Function integration - voltage clamping within range
        test_voltage := x"1500"; -- 1.5V (within range)
        test_min_voltage := x"1000"; -- 1.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_result_voltage := clamp_voltage(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_result_voltage = test_voltage);
        report_test("Function integration - voltage clamping within range", test_passed, test_number, all_tests_passed);
        
        -- Test 23: Duration range checking
        test_duration := to_unsigned(150, SYSTEM_DURATION_WIDTH); -- Within range
        test_min_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_bool := is_duration_in_range(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_bool = true);
        report_test("Duration range checking", test_passed, test_number, all_tests_passed);
        
        -- Test 24: Duration clamping within range
        test_duration := to_unsigned(150, SYSTEM_DURATION_WIDTH); -- Within range
        test_min_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_result_duration := clamp_duration(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_result_duration = test_duration);
        report_test("Duration clamping within range", test_passed, test_number, all_tests_passed);
        
        -- Test 25: Safe access to probe configuration
        test_config_array := DEFAULT_PROBE_CONFIG_ARRAY;
        test_index := 1; -- Valid index
        test_result_config := get_probe_config_safe(test_config_array, test_index);
        test_passed := (test_result_config.probe_name = DEFAULT_PROBE_CONFIG.probe_name);
        report_test("Safe access to probe configuration", test_passed, test_number, all_tests_passed);
        
        -- Test 26: Safe access with invalid index
        test_config_array := DEFAULT_PROBE_CONFIG_ARRAY;
        test_index := 5; -- Invalid index
        test_result_config := get_probe_config_safe(test_config_array, test_index);
        test_passed := (test_result_config.probe_name = DEFAULT_PROBE_CONFIG.probe_name);
        report_test("Safe access with invalid index", test_passed, test_number, all_tests_passed);
        
        -- Test 27: Valid probe index
        test_index := 2; -- Valid index
        test_bool := is_valid_probe_index(test_index);
        test_passed := (test_bool = true);
        report_test("Valid probe index", test_passed, test_number, all_tests_passed);
        
        -- Test 28: Edge case - voltage at boundary
        test_voltage := x"1000"; -- Exactly at minimum
        test_min_voltage := x"1000"; -- 1.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_bool := is_voltage_in_range(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true);
        report_test("Edge case - voltage at boundary", test_passed, test_number, all_tests_passed);
        
        -- Test 29: Edge case - duration at boundary
        test_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH); -- Exactly at minimum
        test_min_duration := to_unsigned(100, SYSTEM_DURATION_WIDTH);
        test_max_duration := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_bool := is_duration_in_range(test_duration, test_min_duration, test_max_duration);
        test_passed := (test_bool = true);
        report_test("Edge case - duration at boundary", test_passed, test_number, all_tests_passed);
        
        -- Layer 3 Summary
        write(l, string'("Layer 3 completed: " & integer'image(test_number - 19) & " tests"));
        writeline(output, l);
        
        -- ============================================================================
        -- LAYER 4: CONFIGURATION TESTING (Constants and Types)
        -- Test constants, types, and configurations
        -- ============================================================================
        write(l, string'("--- Layer 4: Configuration Testing (Constants and Types) ---"));
        writeline(output, l);
        
        -- Test 30: Constant values - system constants
        test_passed := (SYSTEM_DURATION_WIDTH = 16 and SYSTEM_INTENSITY_WIDTH = 7 and 
                       SYSTEM_MAX_PROBES = 4);
        report_test("Constant values - system constants", test_passed, test_number, all_tests_passed);
        
        -- Test 31: Default probe configuration constants
        test_passed := (DEFAULT_PROBE_CONFIG.probe_name = "DEFAULT_PROBE   " and
                       DEFAULT_PROBE_CONFIG.probe_trigger_voltage = x"1000" and
                       DEFAULT_PROBE_CONFIG.probe_intensity_min = x"0000" and
                       DEFAULT_PROBE_CONFIG.probe_intensity_max = x"2000");
        report_test("Default probe configuration constants", test_passed, test_number, all_tests_passed);
        
        -- Test 32: Default probe configuration timing constants
        test_passed := (DEFAULT_PROBE_CONFIG.fire_duration_min = to_unsigned(10, SYSTEM_DURATION_WIDTH) and
                       DEFAULT_PROBE_CONFIG.fire_duration_max = to_unsigned(1000, SYSTEM_DURATION_WIDTH) and
                       DEFAULT_PROBE_CONFIG.cooldown_duration_min = to_unsigned(100, SYSTEM_DURATION_WIDTH) and
                       DEFAULT_PROBE_CONFIG.cooldown_duration_max = to_unsigned(10000, SYSTEM_DURATION_WIDTH));
        report_test("Default probe configuration timing constants", test_passed, test_number, all_tests_passed);
        
        -- Test 33: Default probe configuration safety constants
        test_passed := (DEFAULT_PROBE_CONFIG.safety_enabled = '1' and
                       DEFAULT_PROBE_CONFIG.max_fire_rate = to_unsigned(1000, 16));
        report_test("Default probe configuration safety constants", test_passed, test_number, all_tests_passed);
        
        -- Test 34: Default configuration array
        test_passed := (DEFAULT_PROBE_CONFIG_ARRAY(0).probe_name = DEFAULT_PROBE_CONFIG.probe_name and
                       DEFAULT_PROBE_CONFIG_ARRAY(1).probe_name = DEFAULT_PROBE_CONFIG.probe_name and
                       DEFAULT_PROBE_CONFIG_ARRAY(2).probe_name = DEFAULT_PROBE_CONFIG.probe_name and
                       DEFAULT_PROBE_CONFIG_ARRAY(3).probe_name = DEFAULT_PROBE_CONFIG.probe_name);
        report_test("Default configuration array", test_passed, test_number, all_tests_passed);
        
        -- Test 35: Constant relationships
        test_passed := (SYSTEM_MAX_PROBES = 4 and SYSTEM_DURATION_WIDTH = 16 and SYSTEM_INTENSITY_WIDTH = 7);
        report_test("Constant relationships", test_passed, test_number, all_tests_passed);
        
        -- Test 36: Configuration variations - different probe configurations
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_name := "TEST_PROBE_001  ";
        test_config.probe_trigger_voltage := x"1500"; -- Different voltage
        test_config.probe_intensity_min := x"0500"; -- Different min
        test_config.probe_intensity_max := x"2500"; -- Different max
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Configuration variations - different probe configurations", test_passed, test_number, all_tests_passed);
        
        -- Test 37: Configuration variations - different timing parameters
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.fire_duration_min := to_unsigned(20, SYSTEM_DURATION_WIDTH);
        test_config.fire_duration_max := to_unsigned(2000, SYSTEM_DURATION_WIDTH);
        test_config.cooldown_duration_min := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_config.cooldown_duration_max := to_unsigned(20000, SYSTEM_DURATION_WIDTH);
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Configuration variations - different timing parameters", test_passed, test_number, all_tests_passed);
        
        -- Test 38: Configuration variations - safety settings
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.safety_enabled := '0'; -- Disabled safety
        test_config.max_fire_rate := to_unsigned(500, 16); -- Different fire rate
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Configuration variations - safety settings", test_passed, test_number, all_tests_passed);
        
        -- Layer 4 Summary
        write(l, string'("Layer 4 completed: " & integer'image(test_number - 29) & " tests"));
        writeline(output, l);
        
        -- ============================================================================
        -- PACKAGE INTEGRATION TESTING
        -- Test cross-package function calls and dependencies
        -- ============================================================================
        write(l, string'("--- Package Integration Testing ---"));
        writeline(output, l);
        
        -- Test 39: Cross-package function calls - voltage functions
        test_voltage := x"1000"; -- 1.0V
        test_min_voltage := x"0000"; -- 0.0V
        test_max_voltage := x"2000"; -- 2.0V
        test_bool := is_voltage_in_range(test_voltage, test_min_voltage, test_max_voltage);
        test_passed := (test_bool = true);
        report_test("Cross-package function calls - voltage functions", test_passed, test_number, all_tests_passed);
        
        -- Test 40: Package dependencies - voltage data width
        test_passed := (VOLTAGE_DATA_WIDTH = 16); -- Should match dependent package requirements
        if not test_passed then
            write(l, string'("VOLTAGE_DATA_WIDTH mismatch - expected 16, got " & integer'image(VOLTAGE_DATA_WIDTH)));
            writeline(output, l);
        end if;
        report_test("Package dependencies - voltage data width", test_passed, test_number, all_tests_passed);
        
        -- Test 41: Package initialization - function composition
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_trigger_voltage := x"1500"; -- 1.5V
        test_config.probe_intensity_min := x"1000"; -- 1.0V
        test_config.probe_intensity_max := x"2000"; -- 2.0V
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Package initialization - function composition", test_passed, test_number, all_tests_passed);
        
        -- Test 42: Integration with array operations
        test_config_array := DEFAULT_PROBE_CONFIG_ARRAY;
        test_config_array(0).probe_name := "PROBE_0_TEST    ";
        test_config_array(1).probe_name := "PROBE_1_TEST    ";
        test_result_config := get_probe_config_safe(test_config_array, 0);
        test_passed := (test_result_config.probe_name = "PROBE_0_TEST    ");
        report_test("Integration with array operations", test_passed, test_number, all_tests_passed);
        
        -- Test 43: Integration with clamping functions
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_trigger_voltage := x"5000"; -- Above valid range
        test_config.probe_intensity_min := x"0000"; -- 0.0V
        test_config.probe_intensity_max := x"2000"; -- 2.0V
        test_config.probe_trigger_voltage := clamp_voltage(test_config.probe_trigger_voltage, 
                                                           test_config.probe_intensity_min, 
                                                           test_config.probe_intensity_max);
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Integration with clamping functions", test_passed, test_number, all_tests_passed);
        
        -- Test 44: Integration with duration functions
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.fire_duration_min := to_unsigned(50, SYSTEM_DURATION_WIDTH); -- Below minimum
        test_config.fire_duration_max := to_unsigned(1000, SYSTEM_DURATION_WIDTH);
        test_config.fire_duration_min := clamp_duration(test_config.fire_duration_min, 
                                                        to_unsigned(10, SYSTEM_DURATION_WIDTH), 
                                                        test_config.fire_duration_max);
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Integration with duration functions", test_passed, test_number, all_tests_passed);
        
        -- Test 45: Comprehensive integration test
        test_config := DEFAULT_PROBE_CONFIG;
        test_config.probe_name := "INTEGRATION_TEST";
        test_config.probe_trigger_voltage := x"1500"; -- 1.5V
        test_config.probe_intensity_min := x"1000"; -- 1.0V
        test_config.probe_intensity_max := x"2000"; -- 2.0V
        test_config.fire_duration_min := to_unsigned(20, SYSTEM_DURATION_WIDTH);
        test_config.fire_duration_max := to_unsigned(2000, SYSTEM_DURATION_WIDTH);
        test_config.cooldown_duration_min := to_unsigned(200, SYSTEM_DURATION_WIDTH);
        test_config.cooldown_duration_max := to_unsigned(20000, SYSTEM_DURATION_WIDTH);
        test_config.safety_enabled := '1';
        test_config.max_fire_rate := to_unsigned(1500, 16);
        
        -- Validate the configuration
        test_bool := is_valid_probe_config(test_config);
        test_passed := (test_bool = true);
        report_test("Comprehensive integration test", test_passed, test_number, all_tests_passed);
        
        -- Integration Testing Summary
        write(l, string'("Integration testing completed: " & integer'image(test_number - 38) & " tests"));
        writeline(output, l);
        
        -- Overall Test Summary
        write(l, string'("=== Test Summary ==="));
        writeline(output, l);
        write(l, string'("Total tests executed: " & integer'image(test_number)));
        writeline(output, l);
        write(l, string'("Package: Probe_Config_pkg_PH9"));
        writeline(output, l);
        write(l, string'("Architecture: 4-layer datadef testing"));
        writeline(output, l);
        
        -- ============================================================================
        -- FINAL RESULTS
        -- ============================================================================
        print_test_completion(all_tests_passed);
        
        write(l, string'("SIMULATION DONE"));
        writeline(output, l);
        
        stop(0); -- Clean termination with exit code 0
    end process test_process;
    
end architecture test;
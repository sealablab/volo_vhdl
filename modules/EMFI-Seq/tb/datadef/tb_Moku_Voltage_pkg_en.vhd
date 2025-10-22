-- =============================================================================
-- Testbench for Moku_Voltage_pkg_en
-- =============================================================================
-- Purpose: Verify voltage conversion, scaling, and validation functions
-- Tier: 3 (Full VHDL-2008 - all features allowed)
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;

-- Package under test
use work.Moku_Voltage_pkg_en.all;

entity tb_Moku_Voltage_pkg_en is
end entity tb_Moku_Voltage_pkg_en;

architecture sim of tb_Moku_Voltage_pkg_en is
    -- Test signals
    signal test_voltage : real;
    signal test_digital : std_logic_vector(15 downto 0);
    signal test_result_voltage : real;
    signal test_result_digital : std_logic_vector(15 downto 0);

    -- Tolerance for real comparisons (0.01V = 10mV)
    constant VOLTAGE_TOLERANCE : real := 0.01;

    -- Helper function for real comparison with tolerance
    function real_equal(a, b : real; tolerance : real := VOLTAGE_TOLERANCE) return boolean is
    begin
        return abs(a - b) < tolerance;
    end function;

begin

    test_process : process
        variable v_result : real;
        variable d_result : std_logic_vector(15 downto 0);
        variable b_result : boolean;
        variable test_count : natural := 0;
        variable pass_count : natural := 0;
        variable fail_count : natural := 0;

        -- Helper procedure for test reporting
        procedure check_test(
            test_name : string;
            condition : boolean
        ) is
        begin
            test_count := test_count + 1;
            if condition then
                pass_count := pass_count + 1;
                report "PASS: " & test_name severity note;
            else
                fail_count := fail_count + 1;
                report "FAIL: " & test_name severity error;
            end if;
        end procedure;
    begin
        report "========================================" severity note;
        report "Starting Moku_Voltage_pkg_en tests" severity note;
        report "========================================" severity note;

        -- =====================================================================
        -- Test 1: Voltage to Digital Conversion
        -- =====================================================================
        report "Test Group 1: Voltage to Digital Conversion" severity note;

        -- Test boundary values
        d_result := voltage_to_digital(-5.0);
        check_test("voltage_to_digital(-5.0V) = 0x0000", d_result = x"0000");

        d_result := voltage_to_digital(0.0);
        check_test("voltage_to_digital(0.0V) = 0x8000", d_result = x"8000");

        d_result := voltage_to_digital(5.0);
        check_test("voltage_to_digital(5.0V) = 0xFFFF", d_result = x"FFFF");

        -- Test specific voltages used in EMFI-Seq
        d_result := voltage_to_digital(1.1);
        check_test("voltage_to_digital(1.1V) = 0x9C28", d_result = x"9C28");

        d_result := voltage_to_digital(1.2);
        check_test("voltage_to_digital(1.2V) = 0x9EB7", d_result = x"9EB7");

        d_result := voltage_to_digital(1.3);
        check_test("voltage_to_digital(1.3V) = 0xA147", d_result = x"A147");

        d_result := voltage_to_digital(1.4);
        check_test("voltage_to_digital(1.4V) = 0xA3D6", d_result = x"A3D6");

        -- Test clamping (out of range values)
        d_result := voltage_to_digital(10.0);  -- Above max
        check_test("voltage_to_digital(10.0V) clamped to 0xFFFF", d_result = x"FFFF");

        d_result := voltage_to_digital(-10.0);  -- Below min
        check_test("voltage_to_digital(-10.0V) clamped to 0x0000", d_result = x"0000");

        -- =====================================================================
        -- Test 2: Digital to Voltage Conversion
        -- =====================================================================
        report "Test Group 2: Digital to Voltage Conversion" severity note;

        v_result := digital_to_voltage(x"0000");
        check_test("digital_to_voltage(0x0000) = -5.0V", real_equal(v_result, -5.0));

        v_result := digital_to_voltage(x"8000");
        check_test("digital_to_voltage(0x8000) = 0.0V", real_equal(v_result, 0.0));

        v_result := digital_to_voltage(x"FFFF");
        check_test("digital_to_voltage(0xFFFF) = 5.0V", real_equal(v_result, 5.0));

        -- Test round-trip conversion
        d_result := voltage_to_digital(2.5);
        v_result := digital_to_voltage(d_result);
        check_test("Round-trip 2.5V", real_equal(v_result, 2.5));

        -- =====================================================================
        -- Test 3: Voltage Clamping
        -- =====================================================================
        report "Test Group 3: Voltage Clamping" severity note;

        v_result := clamp_voltage_safe(3.0);
        check_test("clamp_voltage_safe(3.0V) = 3.0V", real_equal(v_result, 3.0));

        v_result := clamp_voltage_safe(7.0);
        check_test("clamp_voltage_safe(7.0V) = 5.0V", real_equal(v_result, 5.0));

        v_result := clamp_voltage_safe(-7.0);
        check_test("clamp_voltage_safe(-7.0V) = -5.0V", real_equal(v_result, -5.0));

        -- =====================================================================
        -- Test 4: Voltage Scaling
        -- =====================================================================
        report "Test Group 4: Voltage Scaling" severity note;

        v_result := scale_voltage(2.0, 2.0);
        check_test("scale_voltage(2.0V, 2.0) = 4.0V", real_equal(v_result, 4.0));

        v_result := scale_voltage(2.0, 0.5);
        check_test("scale_voltage(2.0V, 0.5) = 1.0V", real_equal(v_result, 1.0));

        -- Test clamping in scaling
        v_result := scale_voltage(4.0, 2.0);
        check_test("scale_voltage(4.0V, 2.0) clamped to 5.0V", real_equal(v_result, 5.0));

        -- Test invalid scale factor (should return original)
        v_result := scale_voltage(2.0, 100.0);  -- Too large
        check_test("scale_voltage(2.0V, 100.0) invalid -> 2.0V", real_equal(v_result, 2.0));

        -- =====================================================================
        -- Test 5: Voltage Offset
        -- =====================================================================
        report "Test Group 5: Voltage Offset" severity note;

        v_result := offset_voltage(1.0, 0.5);
        check_test("offset_voltage(1.0V, 0.5V) = 1.5V", real_equal(v_result, 1.5));

        v_result := offset_voltage(4.0, 2.0);
        check_test("offset_voltage(4.0V, 2.0V) clamped to 5.0V", real_equal(v_result, 5.0));

        v_result := offset_voltage(-4.0, -2.0);
        check_test("offset_voltage(-4.0V, -2.0V) clamped to -5.0V", real_equal(v_result, -5.0));

        -- =====================================================================
        -- Test 6: Validation Functions
        -- =====================================================================
        report "Test Group 6: Validation Functions" severity note;

        b_result := is_voltage_safe(3.0);
        check_test("is_voltage_safe(3.0V) = true", b_result = true);

        b_result := is_voltage_safe(6.0);
        check_test("is_voltage_safe(6.0V) = false", b_result = false);

        b_result := is_voltage_safe(-6.0);
        check_test("is_voltage_safe(-6.0V) = false", b_result = false);

        b_result := is_scale_factor_safe(1.0);
        check_test("is_scale_factor_safe(1.0) = true", b_result = true);

        b_result := is_scale_factor_safe(0.5);
        check_test("is_scale_factor_safe(0.5) = true", b_result = true);

        b_result := is_scale_factor_safe(100.0);
        check_test("is_scale_factor_safe(100.0) = false", b_result = false);

        b_result := is_scale_factor_safe(0.05);
        check_test("is_scale_factor_safe(0.05) = false", b_result = false);

        -- =====================================================================
        -- Test 7: Safe Arithmetic
        -- =====================================================================
        report "Test Group 7: Safe Arithmetic" severity note;

        v_result := add_voltages_safe(2.0, 1.5);
        check_test("add_voltages_safe(2.0V, 1.5V) = 3.5V", real_equal(v_result, 3.5));

        v_result := add_voltages_safe(4.0, 4.0);
        check_test("add_voltages_safe(4.0V, 4.0V) clamped to 5.0V", real_equal(v_result, 5.0));

        v_result := subtract_voltages_safe(2.0, 1.0);
        check_test("subtract_voltages_safe(2.0V, 1.0V) = 1.0V", real_equal(v_result, 1.0));

        v_result := subtract_voltages_safe(-4.0, 4.0);
        check_test("subtract_voltages_safe(-4.0V, 4.0V) clamped to -5.0V", real_equal(v_result, -5.0));

        -- =====================================================================
        -- Test 8: Percentage Application
        -- =====================================================================
        report "Test Group 8: Percentage Application" severity note;

        v_result := apply_percentage_voltage(2.0, 50.0);
        check_test("apply_percentage_voltage(2.0V, 50%) = 1.0V", real_equal(v_result, 1.0));

        v_result := apply_percentage_voltage(4.0, 100.0);
        check_test("apply_percentage_voltage(4.0V, 100%) = 4.0V", real_equal(v_result, 4.0));

        v_result := apply_percentage_voltage(2.0, 0.0);
        check_test("apply_percentage_voltage(2.0V, 0%) = 0.0V", real_equal(v_result, 0.0));

        -- =====================================================================
        -- Test 9: Default Constants
        -- =====================================================================
        report "Test Group 9: Default Constants" severity note;

        check_test("DEFAULT_VOLTAGE_ZERO = 0.0", real_equal(DEFAULT_VOLTAGE_ZERO, 0.0));
        check_test("DEFAULT_VOLTAGE_MIN = -5.0", real_equal(DEFAULT_VOLTAGE_MIN, -5.0));
        check_test("DEFAULT_VOLTAGE_MAX = 5.0", real_equal(DEFAULT_VOLTAGE_MAX, 5.0));
        check_test("DEFAULT_DIGITAL_ZERO = 0x0000", DEFAULT_DIGITAL_ZERO = x"0000");
        check_test("DEFAULT_DIGITAL_MID = 0x8000", DEFAULT_DIGITAL_MID = x"8000");
        check_test("DEFAULT_DIGITAL_MAX = 0xFFFF", DEFAULT_DIGITAL_MAX = x"FFFF");

        -- =====================================================================
        -- Test Summary
        -- =====================================================================
        report "========================================" severity note;
        report "Test Summary:" severity note;
        report "  Total tests: " & integer'image(test_count) severity note;
        report "  Passed:      " & integer'image(pass_count) severity note;
        report "  Failed:      " & integer'image(fail_count) severity note;
        report "========================================" severity note;

        if fail_count = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TEST FAILED" severity error;
        end if;

        report "SIMULATION DONE" severity note;
        std.env.stop(0);
    end process;

end architecture sim;

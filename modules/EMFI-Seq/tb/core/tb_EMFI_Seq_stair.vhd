-- =============================================================================
-- Testbench for EMFI_Seq_stair (OneHot Analog Monitor)
-- =============================================================================
-- Purpose: Verify one-hot state to voltage code mapping
-- Tier: 3 (Full VHDL-2008 - all features allowed)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- Use voltage package to verify expected codes
use work.Moku_Voltage_pkg_en.all;

entity tb_EMFI_Seq_stair is
end entity tb_EMFI_Seq_stair;

architecture sim of tb_EMFI_Seq_stair is
    -- DUT signals
    signal state_oh : std_logic_vector(3 downto 0) := "0000";
    signal dac_out_s16 : signed(15 downto 0);
    signal monitor_u16 : unsigned(15 downto 0);

    -- Expected voltage codes (from voltage package)
    constant EXPECTED_V_1_1 : signed(15 downto 0) := signed(voltage_to_digital(1.1));
    constant EXPECTED_V_1_2 : signed(15 downto 0) := signed(voltage_to_digital(1.2));
    constant EXPECTED_V_1_3 : signed(15 downto 0) := signed(voltage_to_digital(1.3));
    constant EXPECTED_V_1_4 : signed(15 downto 0) := signed(voltage_to_digital(1.4));
    constant EXPECTED_V_0_0 : signed(15 downto 0) := signed(voltage_to_digital(0.0));


begin

    -- Instantiate DUT
    DUT: entity work.onehot_analog_monitor
        port map (
            state_oh    => state_oh,
            dac_out_s16 => dac_out_s16,
            monitor_u16 => monitor_u16
        );

    -- Test process
    test_process: process
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
        report "Starting EMFI_Seq_stair tests" severity note;
        report "========================================" severity note;

        -- =====================================================================
        -- Test 1: State S1 (one-hot "0001")
        -- =====================================================================
        report "Test 1: State S1 -> 1.1V" severity note;
        state_oh <= "0001";
        wait for 10 ns;

        report "Expected: 0x" & to_hstring(EXPECTED_V_1_1) &
               " (" & integer'image(to_integer(EXPECTED_V_1_1)) & ")" severity note;
        report "Got:      0x" & to_hstring(dac_out_s16) &
               " (" & integer'image(to_integer(dac_out_s16)) & ")" severity note;

        check_test("S1: dac_out_s16 = 0x9C28 (1.1V)", dac_out_s16 = EXPECTED_V_1_1);
        check_test("S1: monitor_u16 matches dac_out_s16", monitor_u16 = unsigned(dac_out_s16));

        -- =====================================================================
        -- Test 2: State S2 (one-hot "0010")
        -- =====================================================================
        report "Test 2: State S2 -> 1.2V" severity note;
        state_oh <= "0010";
        wait for 10 ns;

        report "Expected: 0x" & to_hstring(EXPECTED_V_1_2) &
               " (" & integer'image(to_integer(EXPECTED_V_1_2)) & ")" severity note;
        report "Got:      0x" & to_hstring(dac_out_s16) &
               " (" & integer'image(to_integer(dac_out_s16)) & ")" severity note;

        check_test("S2: dac_out_s16 = 0x9EB7 (1.2V)", dac_out_s16 = EXPECTED_V_1_2);
        check_test("S2: monitor_u16 matches dac_out_s16", monitor_u16 = unsigned(dac_out_s16));

        -- =====================================================================
        -- Test 3: State S3 (one-hot "0100")
        -- =====================================================================
        report "Test 3: State S3 -> 1.3V" severity note;
        state_oh <= "0100";
        wait for 10 ns;

        report "Expected: 0x" & to_hstring(EXPECTED_V_1_3) &
               " (" & integer'image(to_integer(EXPECTED_V_1_3)) & ")" severity note;
        report "Got:      0x" & to_hstring(dac_out_s16) &
               " (" & integer'image(to_integer(dac_out_s16)) & ")" severity note;

        check_test("S3: dac_out_s16 = 0xA147 (1.3V)", dac_out_s16 = EXPECTED_V_1_3);
        check_test("S3: monitor_u16 matches dac_out_s16", monitor_u16 = unsigned(dac_out_s16));

        -- =====================================================================
        -- Test 4: State S4 (one-hot "1000")
        -- =====================================================================
        report "Test 4: State S4 -> 1.4V" severity note;
        state_oh <= "1000";
        wait for 10 ns;

        report "Expected: 0x" & to_hstring(EXPECTED_V_1_4) &
               " (" & integer'image(to_integer(EXPECTED_V_1_4)) & ")" severity note;
        report "Got:      0x" & to_hstring(dac_out_s16) &
               " (" & integer'image(to_integer(dac_out_s16)) & ")" severity note;

        check_test("S4: dac_out_s16 = 0xA3D6 (1.4V)", dac_out_s16 = EXPECTED_V_1_4);
        check_test("S4: monitor_u16 matches dac_out_s16", monitor_u16 = unsigned(dac_out_s16));

        -- =====================================================================
        -- Test 5: Invalid state (all zeros) -> Failsafe 0.0V
        -- =====================================================================
        report "Test 5: Invalid state (0000) -> 0.0V failsafe" severity note;
        state_oh <= "0000";
        wait for 10 ns;

        report "Expected: 0x" & to_hstring(EXPECTED_V_0_0) &
               " (" & integer'image(to_integer(EXPECTED_V_0_0)) & ")" severity note;
        report "Got:      0x" & to_hstring(dac_out_s16) &
               " (" & integer'image(to_integer(dac_out_s16)) & ")" severity note;

        check_test("Invalid (0000): dac_out_s16 = 0x8000 (0.0V)", dac_out_s16 = EXPECTED_V_0_0);

        -- =====================================================================
        -- Test 6: Invalid state (multi-hot "0011") -> Failsafe 0.0V
        -- =====================================================================
        report "Test 6: Invalid state (multi-hot 0011) -> 0.0V failsafe" severity note;
        state_oh <= "0011";
        wait for 10 ns;

        check_test("Invalid (0011): dac_out_s16 = 0x8000 (0.0V)", dac_out_s16 = EXPECTED_V_0_0);

        -- =====================================================================
        -- Test 7: Invalid state (all ones "1111") -> Failsafe 0.0V
        -- =====================================================================
        report "Test 7: Invalid state (1111) -> 0.0V failsafe" severity note;
        state_oh <= "1111";
        wait for 10 ns;

        check_test("Invalid (1111): dac_out_s16 = 0x8000 (0.0V)", dac_out_s16 = EXPECTED_V_0_0);

        -- =====================================================================
        -- Test 8: Verify stair-step ordering (S1 < S2 < S3 < S4)
        -- =====================================================================
        report "Test 8: Verify stair-step ordering" severity note;

        check_test("Ordering: V_1_1 < V_1_2", EXPECTED_V_1_1 < EXPECTED_V_1_2);
        check_test("Ordering: V_1_2 < V_1_3", EXPECTED_V_1_2 < EXPECTED_V_1_3);
        check_test("Ordering: V_1_3 < V_1_4", EXPECTED_V_1_3 < EXPECTED_V_1_4);
        check_test("Ordering: All voltages > 0V", EXPECTED_V_1_1 > EXPECTED_V_0_0);

        -- =====================================================================
        -- Test 9: Combinational response (no clock delay)
        -- =====================================================================
        report "Test 9: Verify combinational response" severity note;

        state_oh <= "0001";
        wait for 1 ns;  -- Minimal delay
        check_test("Combinational: S1 responds immediately", dac_out_s16 = EXPECTED_V_1_1);

        state_oh <= "0010";
        wait for 1 ns;
        check_test("Combinational: S2 responds immediately", dac_out_s16 = EXPECTED_V_1_2);

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

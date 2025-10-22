-- =============================================================================
-- State Machine Base Testbench
-- =============================================================================
--
-- Comprehensive testbench for the state machine base template.
-- Tests all state transitions, status register updates, and edge cases.
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.ENV.ALL;

entity state_machine_base_tb is
end entity state_machine_base_tb;

architecture test of state_machine_base_tb is

    -- Component declaration
    component state_machine_base is
        generic (
            MODULE_NAME : string := "state_machine_base";
            STATUS_REG_WIDTH : integer := 32;
            MODULE_STATUS_BITS : integer := 16
        );
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            ctrl_enable : in std_logic;
            ctrl_start : in std_logic;
            cfg_param1 : in std_logic_vector(15 downto 0);
            cfg_param2 : in std_logic_vector(7 downto 0);
            cfg_param3 : in std_logic;
            stat_current_state : out std_logic_vector(3 downto 0);
            stat_fault : out std_logic;
            stat_ready : out std_logic;
            stat_idle : out std_logic;
            stat_status_reg : out std_logic_vector(31 downto 0);
            module_status : in std_logic_vector(15 downto 0);
            debug_state_machine : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Test signals
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal ctrl_enable : std_logic := '0';
    signal ctrl_start : std_logic := '0';
    signal cfg_param1 : std_logic_vector(15 downto 0) := (others => '0');
    signal cfg_param2 : std_logic_vector(7 downto 0) := (others => '0');
    signal cfg_param3 : std_logic := '0';
    signal module_status : std_logic_vector(15 downto 0) := (others => '0');
    
    signal stat_current_state : std_logic_vector(3 downto 0);
    signal stat_fault : std_logic;
    signal stat_ready : std_logic;
    signal stat_idle : std_logic;
    signal stat_status_reg : std_logic_vector(31 downto 0);
    signal debug_state_machine : std_logic_vector(3 downto 0);
    
    -- Test control
    signal all_tests_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Clock Generation
    -- =========================================================================
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- =========================================================================
    -- Device Under Test
    -- =========================================================================
    DUT: state_machine_base
        generic map (
            MODULE_NAME => "test_module",
            STATUS_REG_WIDTH => 32,
            MODULE_STATUS_BITS => 16
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            ctrl_enable => ctrl_enable,
            ctrl_start => ctrl_start,
            cfg_param1 => cfg_param1,
            cfg_param2 => cfg_param2,
            cfg_param3 => cfg_param3,
            stat_current_state => stat_current_state,
            stat_fault => stat_fault,
            stat_ready => stat_ready,
            stat_idle => stat_idle,
            stat_status_reg => stat_status_reg,
            module_status => module_status,
            debug_state_machine => debug_state_machine
        );

    -- =========================================================================
    -- Test Process
    -- =========================================================================
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        
        -- Helper procedure for test reporting
        procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
        begin
            test_num := test_num + 1;
            if passed then
                write(l, string'("TEST " & integer'image(test_num) & ": " & test_name & " - PASSED"));
            else
                write(l, string'("TEST " & integer'image(test_num) & ": " & test_name & " - FAILED"));
                all_tests_passed <= false;
            end if;
            writeline(output, l);
        end procedure;
        
        -- Helper procedure to wait for clock edge
        procedure wait_clk(n : natural := 1) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
        
        -- Helper procedure to check state
        procedure check_state(expected_state : std_logic_vector(3 downto 0); test_name : string) is
        begin
            test_passed := (stat_current_state = expected_state);
            report_test(test_name, test_passed, test_number);
        end procedure;
        
        -- Helper procedure to check status register bit
        procedure check_status_bit(bit_pos : natural; expected_value : std_logic; test_name : string) is
        begin
            test_passed := (stat_status_reg(bit_pos) = expected_value);
            report_test(test_name, test_passed, test_number);
        end procedure;

    begin
        -- Test initialization
        write(l, string'("=== State Machine Base TestBench Started ==="));
        writeline(output, l);
        
        -- =====================================================================
        -- Group 1: Reset and Initialization Tests
        -- =====================================================================
        write(l, string'("--- Group 1: Reset and Initialization Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset state (wait for clock edge to ensure state machine is running)
        wait_clk(1);
        check_state("0000", "Reset state initialization");
        
        -- Test 2: Status register reset (wait for clock edge)
        wait_clk(1);
        check_status_bit(31, '0', "FAULT bit reset to 0");
        check_status_bit(27, '0', "State bits [27:24] reset to 0");
        
        -- Test 3: Status outputs reset
        test_passed := (stat_fault = '0' and stat_ready = '0' and stat_idle = '0');
        report_test("Status outputs reset", test_passed, test_number);
        
        -- =====================================================================
        -- Group 2: State Transition Tests
        -- =====================================================================
        write(l, string'("--- Group 2: State Transition Tests ---"));
        writeline(output, l);
        
        -- Release reset
        rst_n <= '1';
        wait_clk(2);
        
        -- Test 4: Stay in RESET when disabled
        check_state("0000", "Stay in RESET when disabled");
        
        -- Test 5: Stay in RESET when enabled but params invalid
        ctrl_enable <= '1';
        wait_clk(2);
        check_state("0000", "Stay in RESET when params invalid");
        
        -- Test 6: Transition to READY when enabled and params valid
        cfg_param1 <= x"1234";  -- Valid non-zero value
        cfg_param2 <= x"AB";    -- Valid non-zero value
        cfg_param3 <= '1';      -- Valid value
        wait_clk(2);
        check_state("0001", "Transition to READY");
        
        -- Test 7: Status outputs in READY state
        test_passed := (stat_ready = '1' and stat_fault = '0' and stat_idle = '0');
        report_test("Status outputs in READY state", test_passed, test_number);
        
        -- Test 8: Status register state bits in READY (wait for clock edge)
        wait_clk(1);
        check_status_bit(27, '0', "State bit [27] in READY");
        check_status_bit(26, '0', "State bit [26] in READY");
        check_status_bit(25, '0', "State bit [25] in READY");
        check_status_bit(24, '1', "State bit [24] in READY");
        
        -- Test 9: Transition to IDLE when start asserted
        ctrl_start <= '1';
        wait_clk(2);
        check_state("0010", "Transition to IDLE");
        
        -- Test 10: Status outputs in IDLE state
        test_passed := (stat_idle = '1' and stat_ready = '0' and stat_fault = '0');
        report_test("Status outputs in IDLE state", test_passed, test_number);
        
        -- Test 11: Status register state bits in IDLE (wait for clock edge)
        wait_clk(1);
        check_status_bit(27, '0', "State bit [27] in IDLE");
        check_status_bit(26, '0', "State bit [26] in IDLE");
        check_status_bit(25, '1', "State bit [25] in IDLE");
        check_status_bit(24, '0', "State bit [24] in IDLE");
        
        -- =====================================================================
        -- Group 3: Module Status Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 3: Module Status Integration Tests ---"));
        writeline(output, l);
        
        -- Test 12: Module status register integration
        module_status <= x"ABCD";
        wait_clk(2);
        test_passed := (stat_status_reg(15 downto 0) = x"ABCD");
        report_test("Module status register integration", test_passed, test_number);
        
        -- Test 13: Module status bits preserved during state changes
        ctrl_start <= '0';
        wait_clk(2);
        test_passed := (stat_status_reg(15 downto 0) = x"ABCD");
        report_test("Module status preserved during state changes", test_passed, test_number);
        
        -- =====================================================================
        -- Group 4: HARD_FAULT State Tests
        -- =====================================================================
        write(l, string'("--- Group 4: HARD_FAULT State Tests ---"));
        writeline(output, l);
        
        -- Test 14: Transition to HARD_FAULT when params become invalid
        cfg_param1 <= x"0000";  -- Invalid zero value
        wait_clk(2);
        check_state("1111", "Transition to HARD_FAULT on invalid params");
        
        -- Test 15: Status outputs in HARD_FAULT state
        test_passed := (stat_fault = '1' and stat_ready = '0' and stat_idle = '0');
        report_test("Status outputs in HARD_FAULT state", test_passed, test_number);
        
        -- Test 16: FAULT bit in status register (wait for clock edge)
        wait_clk(1);
        check_status_bit(31, '1', "FAULT bit set in HARD_FAULT state");
        
        -- Test 17: State bits in status register for HARD_FAULT
        test_passed := (stat_status_reg(27 downto 24) = "1111");
        report_test("State bits [27:24] show HARD_FAULT", test_passed, test_number);
        
        -- Test 18: Cannot exit HARD_FAULT without reset
        cfg_param1 <= x"1234";  -- Try to make params valid again
        cfg_param2 <= x"AB";
        cfg_param3 <= '1';
        ctrl_enable <= '1';
        ctrl_start <= '1';
        wait_clk(5);
        check_state("1111", "Cannot exit HARD_FAULT without reset");
        
        -- Test 19: Reset exits HARD_FAULT
        rst_n <= '0';
        wait_clk(2);
        check_state("0000", "Reset exits HARD_FAULT");
        
        -- =====================================================================
        -- Group 5: Debug Output Tests
        -- =====================================================================
        write(l, string'("--- Group 5: Debug Output Tests ---"));
        writeline(output, l);
        
        -- Test 20: Debug output matches current state
        rst_n <= '1';
        ctrl_enable <= '1';
        cfg_param1 <= x"1234";
        cfg_param2 <= x"AB";
        cfg_param3 <= '1';
        wait_clk(2);
        test_passed := (debug_state_machine = stat_current_state);
        report_test("Debug output matches current state", test_passed, test_number);
        
        -- =====================================================================
        -- Group 6: Edge Case Tests
        -- =====================================================================
        write(l, string'("--- Group 6: Edge Case Tests ---"));
        writeline(output, l);
        
        -- Test 21: Rapid state transitions
        ctrl_start <= '1';
        wait_clk(1);
        ctrl_start <= '0';
        wait_clk(1);
        ctrl_start <= '1';
        wait_clk(1);
        check_state("0010", "Rapid state transitions handled correctly");
        
        -- Test 22: All control signals high
        ctrl_enable <= '1';
        ctrl_start <= '1';
        cfg_param1 <= x"1234";
        cfg_param2 <= x"AB";
        cfg_param3 <= '1';
        wait_clk(2);
        check_state("0010", "All control signals high - stays in IDLE");
        
        -- =====================================================================
        -- Final Results
        -- =====================================================================
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
        
        stop(0); -- Clean termination
    end process;

end architecture test;
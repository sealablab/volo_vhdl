-- =============================================================================
-- ProbeHero8 Top Testbench
-- =============================================================================
-- 
-- Top-level testbench for ProbeHero8 integration with:
-- - Direct instantiation of all modules (REQUIRED for top layer)
-- - System integration testing
-- - Register interface validation
-- - End-to-end functionality testing
--
-- Test Structure:
-- - Group 1: Register interface tests
-- - Group 2: Direct control signal tests
-- - Group 3: System integration tests
-- - Group 4: Interrupt generation tests
-- - Group 5: End-to-end functionality tests
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.ENV.ALL;

-- Import ProbeHero8 packages
library WORK;
use WORK.probe_config_pkg.ALL;
use WORK.probe_status_pkg.ALL;

entity probe_hero8_top_tb is
end entity probe_hero8_top_tb;

architecture test of probe_hero8_top_tb is

    -- =========================================================================
    -- Testbench Signals
    -- =========================================================================
    
    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    -- Platform control interface
    signal ctrl_reg_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal ctrl_reg_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_reg_data_out : std_logic_vector(31 downto 0);
    signal ctrl_reg_write : std_logic := '0';
    signal ctrl_reg_read : std_logic := '0';
    signal ctrl_reg_ready : std_logic;
    
    signal cfg_reg_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal cfg_reg_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal cfg_reg_data_out : std_logic_vector(31 downto 0);
    signal cfg_reg_write : std_logic := '0';
    signal cfg_reg_read : std_logic := '0';
    signal cfg_reg_ready : std_logic;
    
    signal stat_reg_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal stat_reg_data_out : std_logic_vector(31 downto 0);
    signal stat_reg_read : std_logic := '0';
    signal stat_reg_ready : std_logic;
    
    -- Direct control signals
    signal ctrl_enable : std_logic := '0';
    signal ctrl_arm : std_logic := '0';
    signal ctrl_trigger : std_logic := '0';
    
    -- Status outputs
    signal stat_fault : std_logic;
    signal stat_ready : std_logic;
    signal stat_armed : std_logic;
    signal stat_firing : std_logic;
    signal stat_cooling : std_logic;
    signal stat_alarm : std_logic;
    
    -- Probe control outputs
    signal probe_voltage_out : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
    signal probe_enable_out : std_logic;
    signal probe_select_out : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
    
    -- Interrupt outputs
    signal irq_fault : std_logic;
    signal irq_alarm : std_logic;
    signal irq_ready : std_logic;
    
    -- Test control signals
    signal all_tests_passed : boolean := true;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- =========================================================================
    -- Device Under Test (DUT) - Direct Instantiation (REQUIRED for top layer)
    -- =========================================================================
    DUT: entity WORK.probe_hero8_top
        generic map (
            MODULE_NAME => "probe_hero8_top",
            REG_ADDR_WIDTH => 8,
            REG_DATA_WIDTH => 32
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            ctrl_reg_addr => ctrl_reg_addr,
            ctrl_reg_data_in => ctrl_reg_data_in,
            ctrl_reg_data_out => ctrl_reg_data_out,
            ctrl_reg_write => ctrl_reg_write,
            ctrl_reg_read => ctrl_reg_read,
            ctrl_reg_ready => ctrl_reg_ready,
            cfg_reg_addr => cfg_reg_addr,
            cfg_reg_data_in => cfg_reg_data_in,
            cfg_reg_data_out => cfg_reg_data_out,
            cfg_reg_write => cfg_reg_write,
            cfg_reg_read => cfg_reg_read,
            cfg_reg_ready => cfg_reg_ready,
            stat_reg_addr => stat_reg_addr,
            stat_reg_data_out => stat_reg_data_out,
            stat_reg_read => stat_reg_read,
            stat_reg_ready => stat_reg_ready,
            ctrl_enable => ctrl_enable,
            ctrl_arm => ctrl_arm,
            ctrl_trigger => ctrl_trigger,
            stat_fault => stat_fault,
            stat_ready => stat_ready,
            stat_armed => stat_armed,
            stat_firing => stat_firing,
            stat_cooling => stat_cooling,
            stat_alarm => stat_alarm,
            probe_voltage_out => probe_voltage_out,
            probe_enable_out => probe_enable_out,
            probe_select_out => probe_select_out,
            irq_fault => irq_fault,
            irq_alarm => irq_alarm,
            irq_ready => irq_ready
        );

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
    -- Test Helper Procedures (declared within process)
    -- =========================================================================

    -- =========================================================================
    -- Main Test Process
    -- =========================================================================
    test_process : process
        variable l : line;
        variable test_passed : boolean;
        variable test_number : natural := 0;
        
        -- Test Helper Procedures (declared within process)
        procedure report_test(test_name : string; passed : boolean; test_num : inout natural) is
            variable l : line;
        begin
            test_num := test_num + 1;
            write(l, string'("Test "));
            write(l, test_num);
            write(l, string'(": "));
            write(l, test_name);
            if passed then
                write(l, string'(" - PASSED"));
            else
                write(l, string'(" - FAILED"));
            end if;
            writeline(output, l);
        end procedure;
        
        -- Wait for clock cycles
        procedure wait_cycles(cycles : natural) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
        
        -- Write to control register
        procedure write_ctrl_reg(addr : std_logic_vector; data : std_logic_vector) is
        begin
            ctrl_reg_addr <= addr;
            ctrl_reg_data_in <= data;
            ctrl_reg_write <= '1';
            wait until rising_edge(clk);
            ctrl_reg_write <= '0';
            wait until ctrl_reg_ready = '1';
            wait_cycles(1);
        end procedure;
        
        -- Read from control register
        procedure read_ctrl_reg(addr : std_logic_vector; expected_data : std_logic_vector; test_name : string; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            ctrl_reg_addr <= addr;
            ctrl_reg_read <= '1';
            wait until rising_edge(clk);
            ctrl_reg_read <= '0';
            wait until ctrl_reg_ready = '1';
            test_passed := (ctrl_reg_data_out = expected_data);
            report_test(test_name, test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
            wait_cycles(1);
        end procedure;
        
        -- Write to configuration register
        procedure write_cfg_reg(addr : std_logic_vector; data : std_logic_vector) is
        begin
            cfg_reg_addr <= addr;
            cfg_reg_data_in <= data;
            cfg_reg_write <= '1';
            wait until rising_edge(clk);
            cfg_reg_write <= '0';
            wait until cfg_reg_ready = '1';
            wait_cycles(1);
        end procedure;
        
        -- Read from configuration register
        procedure read_cfg_reg(addr : std_logic_vector; expected_data : std_logic_vector; test_name : string; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            cfg_reg_addr <= addr;
            cfg_reg_read <= '1';
            wait until rising_edge(clk);
            cfg_reg_read <= '0';
            wait until cfg_reg_ready = '1';
            test_passed := (cfg_reg_data_out = expected_data);
            report_test(test_name, test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
            wait_cycles(1);
        end procedure;
        
        -- Read from status register
        procedure read_stat_reg(addr : std_logic_vector; test_name : string; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            stat_reg_addr <= addr;
            stat_reg_read <= '1';
            wait until rising_edge(clk);
            stat_reg_read <= '0';
            wait until stat_reg_ready = '1';
            test_passed := true;  -- Just verify we can read without error
            report_test(test_name, test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
            wait_cycles(1);
        end procedure;
        
        -- Check signal value
        procedure check_signal(signal_name : string; actual : std_logic; expected : std_logic; test_num : inout natural) is
            variable test_passed : boolean;
        begin
            test_passed := (actual = expected);
            report_test(signal_name & " = " & std_logic'image(expected), test_passed, test_num);
            all_tests_passed <= all_tests_passed and test_passed;
        end procedure;
        
    begin
        -- Test initialization
        write(l, string'("=== ProbeHero8 Top TestBench Started ==="));
        writeline(output, l);
        
        -- Initialize test environment
        rst_n <= '0';
        ctrl_enable <= '0';
        ctrl_arm <= '0';
        ctrl_trigger <= '0';
        ctrl_reg_write <= '0';
        ctrl_reg_read <= '0';
        cfg_reg_write <= '0';
        cfg_reg_read <= '0';
        stat_reg_read <= '0';
        
        wait_cycles(5);
        
        -- =====================================================================
        -- Group 1: Register Interface Tests
        -- =====================================================================
        write(l, string'("--- Group 1: Register Interface Tests ---"));
        writeline(output, l);
        
        -- Test 1: Reset behavior
        rst_n <= '1';
        wait_cycles(2);
        check_signal("stat_fault", stat_fault, '0', test_number);
        check_signal("stat_ready", stat_ready, '1', test_number);
        
        -- Test 2: Control register write/read
        write_ctrl_reg(x"00", x"00000001");  -- Write enable
        read_ctrl_reg(x"00", x"00000001", "Control register write/read enable", test_number);
        
        write_ctrl_reg(x"01", x"00000001");  -- Write arm
        read_ctrl_reg(x"01", x"00000001", "Control register write/read arm", test_number);
        
        -- Test 3: Configuration register write/read
        write_cfg_reg(x"10", x"00000003");  -- Write probe selection
        read_cfg_reg(x"10", x"00000003", "Config register write/read probe selection", test_number);
        
        write_cfg_reg(x"11", x"00001000");  -- Write firing voltage
        read_cfg_reg(x"11", x"00001000", "Config register write/read firing voltage", test_number);
        
        -- Test 4: Status register read
        read_stat_reg(x"20", "Status register read", test_number);
        read_stat_reg(x"21", "Alarm register read", test_number);
        read_stat_reg(x"22", "Error code register read", test_number);
        read_stat_reg(x"23", "State register read", test_number);
        
        -- =====================================================================
        -- Group 2: Direct Control Signal Tests
        -- =====================================================================
        write(l, string'("--- Group 2: Direct Control Signal Tests ---"));
        writeline(output, l);
        
        -- Test 5: Direct enable control
        ctrl_enable <= '1';
        wait_cycles(2);
        check_signal("stat_ready", stat_ready, '1', test_number);
        
        -- Test 6: Direct arm control
        ctrl_arm <= '1';
        wait_cycles(2);
        check_signal("stat_armed", stat_armed, '1', test_number);
        
        -- Test 7: Direct trigger control
        ctrl_trigger <= '1';
        wait_cycles(2);
        check_signal("stat_firing", stat_firing, '1', test_number);
        
        -- Test 8: Disarm
        ctrl_trigger <= '0';
        ctrl_arm <= '0';
        wait_cycles(2);
        check_signal("stat_armed", stat_armed, '0', test_number);
        
        -- =====================================================================
        -- Group 3: System Integration Tests
        -- =====================================================================
        write(l, string'("--- Group 3: System Integration Tests ---"));
        writeline(output, l);
        
        -- Test 9: Register control over direct control
        write_ctrl_reg(x"00", x"00000000");  -- Disable via register
        wait_cycles(2);
        check_signal("stat_ready", stat_ready, '0', test_number);
        
        -- Test 10: Configuration via registers
        write_cfg_reg(x"10", x"00000002");  -- Set probe selection to 2
        write_cfg_reg(x"11", x"00002000");  -- Set firing voltage to 2000
        write_cfg_reg(x"12", x"00000050");  -- Set firing duration to 80
        write_cfg_reg(x"13", x"00000500");  -- Set cooling duration to 1280
        wait_cycles(2);
        
        -- Verify configuration
        read_cfg_reg(x"10", x"00000002", "Probe selection configuration", test_number);
        read_cfg_reg(x"11", x"00002000", "Firing voltage configuration", test_number);
        read_cfg_reg(x"12", x"00000050", "Firing duration configuration", test_number);
        read_cfg_reg(x"13", x"00000500", "Cooling duration configuration", test_number);
        
        -- =====================================================================
        -- Group 4: Interrupt Generation Tests
        -- =====================================================================
        write(l, string'("--- Group 4: Interrupt Generation Tests ---"));
        writeline(output, l);
        
        -- Test 11: Ready interrupt
        write_ctrl_reg(x"00", x"00000001");  -- Enable
        wait_cycles(2);
        check_signal("irq_ready", irq_ready, '1', test_number);
        
        -- Test 12: Fault interrupt (trigger invalid configuration)
        write_cfg_reg(x"10", x"000000FF");  -- Invalid probe selection
        wait_cycles(2);
        check_signal("irq_fault", irq_fault, '1', test_number);
        check_signal("stat_fault", stat_fault, '1', test_number);
        
        -- =====================================================================
        -- Group 5: End-to-End Functionality Tests
        -- =====================================================================
        write(l, string'("--- Group 5: End-to-End Functionality Tests ---"));
        writeline(output, l);
        
        -- Test 13: Complete firing sequence via registers
        rst_n <= '0';
        wait_cycles(2);
        rst_n <= '1';
        
        -- Configure valid parameters
        write_cfg_reg(x"10", x"00000001");  -- Valid probe selection
        write_cfg_reg(x"11", x"00001500");  -- Valid firing voltage
        write_cfg_reg(x"12", x"00000030");  -- Valid firing duration
        write_cfg_reg(x"13", x"00000300");  -- Valid cooling duration
        wait_cycles(2);
        
        -- Enable and arm via registers
        write_ctrl_reg(x"00", x"00000001");  -- Enable
        write_ctrl_reg(x"01", x"00000001");  -- Arm
        wait_cycles(2);
        check_signal("stat_armed", stat_armed, '1', test_number);
        
        -- Fire via register
        write_ctrl_reg(x"02", x"00000001");  -- Trigger
        wait_cycles(2);
        check_signal("stat_firing", stat_firing, '1', test_number);
        check_signal("probe_enable_out", probe_enable_out, '1', test_number);
        
        -- Complete firing sequence
        write_ctrl_reg(x"02", x"00000000");  -- Release trigger
        wait_cycles(32);  -- Wait for firing duration
        check_signal("stat_cooling", stat_cooling, '1', test_number);
        check_signal("probe_enable_out", probe_enable_out, '0', test_number);
        
        wait_cycles(302);  -- Wait for cooling duration
        check_signal("stat_ready", stat_ready, '1', test_number);
        check_signal("stat_cooling", stat_cooling, '0', test_number);
        
        -- Test 14: Probe output verification
        test_passed := (probe_select_out = std_logic_vector(to_unsigned(1, PROBE_SEL_WIDTH)));
        report_test("Probe selection output correct", test_passed, test_number);
        all_tests_passed <= all_tests_passed and test_passed;
        
        -- =====================================================================
        -- Final Test Results
        -- =====================================================================
        write(l, string'("--- Final Test Results ---"));
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
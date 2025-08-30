-- =============================================================================
-- ProbeHero8 Top Integration
-- =============================================================================
-- 
-- Top-level integration for ProbeHero8 module with:
-- - External interface for platform control
-- - Register exposure (control, config, status)
-- - Direct instantiation of core module (REQUIRED for top layer)
-- - NO CustomWrapper entity body
--
-- Features:
-- - Platform control interface
-- - Register-based configuration and status
-- - Direct instantiation of probe_hero8_core
-- - Verilog-portable VHDL-2008 implementation
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import ProbeHero8 packages
library WORK;
use WORK.probe_config_pkg.ALL;
use WORK.probe_status_pkg.ALL;

entity probe_hero8_top is
    generic (
        -- Module identification
        MODULE_NAME : string := "probe_hero8_top";
        
        -- Register interface configuration
        REG_ADDR_WIDTH : integer := 8;
        REG_DATA_WIDTH : integer := 32
    );
    port (
        -- Clock and reset
        clk : in std_logic;
        rst_n : in std_logic;
        
        -- Platform control interface
        -- Control register interface
        ctrl_reg_addr : in std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        ctrl_reg_data_in : in std_logic_vector(REG_DATA_WIDTH-1 downto 0);
        ctrl_reg_data_out : out std_logic_vector(REG_DATA_WIDTH-1 downto 0);
        ctrl_reg_write : in std_logic;
        ctrl_reg_read : in std_logic;
        ctrl_reg_ready : out std_logic;
        
        -- Configuration register interface
        cfg_reg_addr : in std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        cfg_reg_data_in : in std_logic_vector(REG_DATA_WIDTH-1 downto 0);
        cfg_reg_data_out : out std_logic_vector(REG_DATA_WIDTH-1 downto 0);
        cfg_reg_write : in std_logic;
        cfg_reg_read : in std_logic;
        cfg_reg_ready : out std_logic;
        
        -- Status register interface
        stat_reg_addr : in std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        stat_reg_data_out : out std_logic_vector(REG_DATA_WIDTH-1 downto 0);
        stat_reg_read : in std_logic;
        stat_reg_ready : out std_logic;
        
        -- Direct control signals (for platform integration)
        ctrl_enable : in std_logic;
        ctrl_arm : in std_logic;
        ctrl_trigger : in std_logic;
        
        -- Status outputs
        stat_fault : out std_logic;
        stat_ready : out std_logic;
        stat_armed : out std_logic;
        stat_firing : out std_logic;
        stat_cooling : out std_logic;
        stat_alarm : out std_logic;
        
        -- Probe control outputs
        probe_voltage_out : out std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
        probe_enable_out : out std_logic;
        probe_select_out : out std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
        
        -- Interrupt outputs
        irq_fault : out std_logic;
        irq_alarm : out std_logic;
        irq_ready : out std_logic
    );
end entity probe_hero8_top;

architecture behavioral of probe_hero8_top is

    -- =========================================================================
    -- Register Address Definitions
    -- =========================================================================
    
    -- Control register addresses
    constant CTRL_ENABLE_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"00";
    constant CTRL_ARM_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"01";
    constant CTRL_TRIGGER_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"02";
    constant CTRL_RESET_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"03";
    
    -- Configuration register addresses
    constant CFG_PROBE_SEL_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"10";
    constant CFG_FIRING_VOLTAGE_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"11";
    constant CFG_FIRING_DURATION_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"12";
    constant CFG_COOLING_DURATION_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"13";
    constant CFG_AUTO_ARM_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"14";
    constant CFG_SAFETY_MODE_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"15";
    
    -- Status register addresses
    constant STAT_STATUS_REG_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"20";
    constant STAT_ALARM_REG_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"21";
    constant STAT_ERROR_CODE_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"22";
    constant STAT_STATE_ADDR : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := x"23";

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================
    
    -- Control signals
    signal ctrl_enable_internal : std_logic;
    signal ctrl_arm_internal : std_logic;
    signal ctrl_trigger_internal : std_logic;
    
    -- Configuration signals
    signal cfg_probe_selection : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
    signal cfg_firing_voltage : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
    signal cfg_firing_duration : std_logic_vector(TIMING_WIDTH-1 downto 0);
    signal cfg_cooling_duration : std_logic_vector(TIMING_WIDTH-1 downto 0);
    signal cfg_enable_auto_arm : std_logic;
    signal cfg_enable_safety_mode : std_logic;
    
    -- Status signals from core
    signal stat_current_state : std_logic_vector(3 downto 0);
    signal stat_fault_internal : std_logic;
    signal stat_ready_internal : std_logic;
    signal stat_idle_internal : std_logic;
    signal stat_armed_internal : std_logic;
    signal stat_firing_internal : std_logic;
    signal stat_cooling_internal : std_logic;
    signal stat_status_reg_internal : std_logic_vector(31 downto 0);
    signal stat_alarm_reg_internal : std_logic_vector(ALARM_WIDTH-1 downto 0);
    signal stat_error_code_internal : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0);
    
    -- Probe control signals from core
    signal probe_voltage_internal : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
    signal probe_enable_internal : std_logic;
    signal probe_select_internal : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
    
    -- Module status
    signal module_status : std_logic_vector(15 downto 0) := (others => '0');
    
    -- Register interface signals
    signal ctrl_reg_ready_internal : std_logic;
    signal cfg_reg_ready_internal : std_logic;
    signal stat_reg_ready_internal : std_logic;
    
    -- Interrupt signals
    signal irq_fault_internal : std_logic;
    signal irq_alarm_internal : std_logic;
    signal irq_ready_internal : std_logic;

begin

    -- =========================================================================
    -- Core Module Instantiation (REQUIRED: Direct Instantiation)
    -- =========================================================================
    U1: entity WORK.probe_hero8_core
        generic map (
            MODULE_NAME => "probe_hero8_core",
            STATUS_REG_WIDTH => 32,
            MODULE_STATUS_BITS => 16
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            ctrl_enable => ctrl_enable_internal,
            ctrl_arm => ctrl_arm_internal,
            ctrl_trigger => ctrl_trigger_internal,
            cfg_safety_probe_selection => cfg_probe_selection,
            cfg_safety_firing_voltage => cfg_firing_voltage,
            cfg_safety_firing_duration => cfg_firing_duration,
            cfg_safety_cooling_duration => cfg_cooling_duration,
            cfg_safety_enable_auto_arm => cfg_enable_auto_arm,
            cfg_safety_enable_safety_mode => cfg_enable_safety_mode,
            stat_current_state => stat_current_state,
            stat_fault => stat_fault_internal,
            stat_ready => stat_ready_internal,
            stat_idle => stat_idle_internal,
            stat_armed => stat_armed_internal,
            stat_firing => stat_firing_internal,
            stat_cooling => stat_cooling_internal,
            stat_status_reg => stat_status_reg_internal,
            stat_alarm_reg => stat_alarm_reg_internal,
            stat_error_code => stat_error_code_internal,
            probe_voltage_out => probe_voltage_internal,
            probe_enable_out => probe_enable_internal,
            probe_select_out => probe_select_internal,
            module_status => module_status,
            debug_state_machine => open
        );

    -- =========================================================================
    -- Control Signal Multiplexing
    -- =========================================================================
    control_mux : process(ctrl_enable, ctrl_arm, ctrl_trigger, ctrl_reg_write, ctrl_reg_addr, ctrl_reg_data_in)
    begin
        -- Default to direct control signals
        ctrl_enable_internal <= ctrl_enable;
        ctrl_arm_internal <= ctrl_arm;
        ctrl_trigger_internal <= ctrl_trigger;
        
        -- Override with register control if register write is active
        if ctrl_reg_write = '1' then
            case ctrl_reg_addr is
                when x"00" =>  -- CTRL_ENABLE_ADDR
                    ctrl_enable_internal <= ctrl_reg_data_in(0);
                when x"01" =>  -- CTRL_ARM_ADDR
                    ctrl_arm_internal <= ctrl_reg_data_in(0);
                when x"02" =>  -- CTRL_TRIGGER_ADDR
                    ctrl_trigger_internal <= ctrl_reg_data_in(0);
                when others =>
                    -- No action for other addresses
                    null;
            end case;
        end if;
    end process;

    -- =========================================================================
    -- Control Register Interface
    -- =========================================================================
    control_reg_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            ctrl_reg_data_out <= (others => '0');
            ctrl_reg_ready_internal <= '0';
        elsif rising_edge(clk) then
            ctrl_reg_ready_internal <= '0';
            
            if ctrl_reg_read = '1' then
                case ctrl_reg_addr is
                    when x"00" =>  -- CTRL_ENABLE_ADDR
                        ctrl_reg_data_out <= (0 => ctrl_enable_internal, others => '0');
                    when x"01" =>  -- CTRL_ARM_ADDR
                        ctrl_reg_data_out <= (0 => ctrl_arm_internal, others => '0');
                    when x"02" =>  -- CTRL_TRIGGER_ADDR
                        ctrl_reg_data_out <= (0 => ctrl_trigger_internal, others => '0');
                    when others =>
                        ctrl_reg_data_out <= (others => '0');
                end case;
                ctrl_reg_ready_internal <= '1';
            elsif ctrl_reg_write = '1' then
                ctrl_reg_ready_internal <= '1';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Configuration Register Interface
    -- =========================================================================
    config_reg_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            cfg_reg_data_out <= (others => '0');
            cfg_reg_ready_internal <= '0';
            -- Initialize configuration to default values
            cfg_probe_selection <= DEFAULT_PROBE_CONFIG.probe_selection;
            cfg_firing_voltage <= DEFAULT_PROBE_CONFIG.firing_voltage;
            cfg_firing_duration <= DEFAULT_PROBE_CONFIG.firing_duration;
            cfg_cooling_duration <= DEFAULT_PROBE_CONFIG.cooling_duration;
            cfg_enable_auto_arm <= DEFAULT_PROBE_CONFIG.enable_auto_arm;
            cfg_enable_safety_mode <= DEFAULT_PROBE_CONFIG.enable_safety_mode;
        elsif rising_edge(clk) then
            cfg_reg_ready_internal <= '0';
            
            if cfg_reg_read = '1' then
                case cfg_reg_addr is
                    when x"10" =>  -- CFG_PROBE_SEL_ADDR
                        cfg_reg_data_out <= (PROBE_SEL_WIDTH-1 downto 0 => cfg_probe_selection, others => '0');
                    when x"11" =>  -- CFG_FIRING_VOLTAGE_ADDR
                        cfg_reg_data_out <= (VOLTAGE_WIDTH-1 downto 0 => cfg_firing_voltage, others => '0');
                    when x"12" =>  -- CFG_FIRING_DURATION_ADDR
                        cfg_reg_data_out <= (TIMING_WIDTH-1 downto 0 => cfg_firing_duration, others => '0');
                    when x"13" =>  -- CFG_COOLING_DURATION_ADDR
                        cfg_reg_data_out <= (TIMING_WIDTH-1 downto 0 => cfg_cooling_duration, others => '0');
                    when x"14" =>  -- CFG_AUTO_ARM_ADDR
                        cfg_reg_data_out <= (0 => cfg_enable_auto_arm, others => '0');
                    when x"15" =>  -- CFG_SAFETY_MODE_ADDR
                        cfg_reg_data_out <= (0 => cfg_enable_safety_mode, others => '0');
                    when others =>
                        cfg_reg_data_out <= (others => '0');
                end case;
                cfg_reg_ready_internal <= '1';
            elsif cfg_reg_write = '1' then
                case cfg_reg_addr is
                    when x"10" =>  -- CFG_PROBE_SEL_ADDR
                        cfg_probe_selection <= cfg_reg_data_in(PROBE_SEL_WIDTH-1 downto 0);
                    when x"11" =>  -- CFG_FIRING_VOLTAGE_ADDR
                        cfg_firing_voltage <= cfg_reg_data_in(VOLTAGE_WIDTH-1 downto 0);
                    when x"12" =>  -- CFG_FIRING_DURATION_ADDR
                        cfg_firing_duration <= cfg_reg_data_in(TIMING_WIDTH-1 downto 0);
                    when x"13" =>  -- CFG_COOLING_DURATION_ADDR
                        cfg_cooling_duration <= cfg_reg_data_in(TIMING_WIDTH-1 downto 0);
                    when x"14" =>  -- CFG_AUTO_ARM_ADDR
                        cfg_enable_auto_arm <= cfg_reg_data_in(0);
                    when x"15" =>  -- CFG_SAFETY_MODE_ADDR
                        cfg_enable_safety_mode <= cfg_reg_data_in(0);
                    when others =>
                        -- No action for other addresses
                        null;
                end case;
                cfg_reg_ready_internal <= '1';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Status Register Interface
    -- =========================================================================
    status_reg_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            stat_reg_data_out <= (others => '0');
            stat_reg_ready_internal <= '0';
        elsif rising_edge(clk) then
            stat_reg_ready_internal <= '0';
            
            if stat_reg_read = '1' then
                case stat_reg_addr is
                    when x"20" =>  -- STAT_STATUS_REG_ADDR
                        stat_reg_data_out <= stat_status_reg_internal;
                    when x"21" =>  -- STAT_ALARM_REG_ADDR
                        stat_reg_data_out <= (ALARM_WIDTH-1 downto 0 => stat_alarm_reg_internal, others => '0');
                    when x"22" =>  -- STAT_ERROR_CODE_ADDR
                        stat_reg_data_out <= (ERROR_CODE_WIDTH-1 downto 0 => stat_error_code_internal, others => '0');
                    when x"23" =>  -- STAT_STATE_ADDR
                        stat_reg_data_out <= (3 downto 0 => stat_current_state, others => '0');
                    when others =>
                        stat_reg_data_out <= (others => '0');
                end case;
                stat_reg_ready_internal <= '1';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Interrupt Generation
    -- =========================================================================
    interrupt_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            irq_fault_internal <= '0';
            irq_alarm_internal <= '0';
            irq_ready_internal <= '0';
        elsif rising_edge(clk) then
            -- Fault interrupt (edge-triggered)
            irq_fault_internal <= stat_fault_internal;
            
            -- Alarm interrupt (edge-triggered)
            irq_alarm_internal <= '1' when stat_alarm_reg_internal /= x"00" else '0';
            
            -- Ready interrupt (edge-triggered)
            irq_ready_internal <= stat_ready_internal;
        end if;
    end process;

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================
    
    -- Status outputs
    stat_fault <= stat_fault_internal;
    stat_ready <= stat_ready_internal;
    stat_armed <= stat_armed_internal;
    stat_firing <= stat_firing_internal;
    stat_cooling <= stat_cooling_internal;
    stat_alarm <= '1' when stat_alarm_reg_internal /= x"00" else '0';
    
    -- Probe control outputs
    probe_voltage_out <= probe_voltage_internal;
    probe_enable_out <= probe_enable_internal;
    probe_select_out <= probe_select_internal;
    
    -- Register interface outputs
    ctrl_reg_ready <= ctrl_reg_ready_internal;
    cfg_reg_ready <= cfg_reg_ready_internal;
    stat_reg_ready <= stat_reg_ready_internal;
    
    -- Interrupt outputs
    irq_fault <= irq_fault_internal;
    irq_alarm <= irq_alarm_internal;
    irq_ready <= irq_ready_internal;

end architecture behavioral;
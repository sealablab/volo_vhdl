-----------------------------------------------------
--
-- Implementation of a probe driver interface
-- Provides control, configuration, and status register exposure
-- for the ProbeDriver system. Designed for platform control
-- system integration with minimal functionality.
-- 
-- Functional interface for probe driver control and monitoring
------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg.all;
use work.Probe_Config_pkg.all;
use work.Moku_Voltage_pkg.all;

entity probe_driver_interface is
    port (
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Control signals
        ctrl_enable          : in  std_logic;
        ctrl_arm             : in  std_logic;
        ctrl_fire            : in  std_logic;
        ctrl_reset           : in  std_logic;
        
        -- Configuration signals
        cfg_intensity_index  : in  std_logic_vector(SYSTEM_INTENSITY_INDEX_WIDTH-1 downto 0);
        cfg_duration         : in  std_logic_vector(SYSTEM_DURATION_WIDTH-1 downto 0);
        cfg_cooldown         : in  std_logic_vector(SYSTEM_COOLDOWN_WIDTH-1 downto 0);
        cfg_trigger_threshold : in  std_logic_vector(15 downto 0);
        
        -- Data signals
        data_trigger_in      : in  std_logic_vector(15 downto 0);
        
        -- Status and output signals
        stat_probe_state     : out std_logic_vector(1 downto 0);
        stat_status_reg      : out std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0);
        stat_armed           : out std_logic;
        stat_firing          : out std_logic;
        stat_cooldown        : out std_logic;
        stat_error           : out std_logic;
        stat_ready           : out std_logic;
        data_intensity_out   : out std_logic_vector(15 downto 0)
    );
end entity;

architecture behavioural of probe_driver_interface is
begin
    -- Probe driver core instantiation
    PROBE_DRIVER: entity work.probe_driver_core
        generic map (
            CLK_FREQ_MHZ => 100,
            ENABLE_DEBUG => false
        )
        port map (
            ctrl_clk => Clk,
            ctrl_rst_n => not Reset,
            ctrl_enable => ctrl_enable,
            ctrl_arm => ctrl_arm,
            ctrl_fire => ctrl_fire,
            ctrl_reset => ctrl_reset,
            cfg_intensity_index => cfg_intensity_index,
            cfg_duration => cfg_duration,
            cfg_cooldown => cfg_cooldown,
            cfg_trigger_threshold => cfg_trigger_threshold,
            stat_probe_state => stat_probe_state,
            stat_status_reg => stat_status_reg,
            stat_armed => stat_armed,
            stat_firing => stat_firing,
            stat_cooldown => stat_cooldown,
            stat_error => stat_error,
            stat_ready => stat_ready,
            data_trigger_in => data_trigger_in,
            data_intensity_out => data_intensity_out
        );

end architecture;

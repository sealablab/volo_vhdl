-----------------------------------------------------
--
-- Top-level integration module for probe_driver system
-- Integrates probe_driver_interface with clk_divider_core
-- Provides external interface for platform control system integration
-- 
-- This module demonstrates proper top-level integration using direct
-- instantiation as required by the Volo VHDL coding standards.
------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg.all;
use work.Trigger_Config_pkg.all;
use work.Moku_Voltage_pkg.all;

entity probe_driver_top is
    port (
        -- System clock and reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Clock divider configuration
        cfg_clk_div_sel : in  std_logic_vector(3 downto 0);
        
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
        data_intensity_out   : out std_logic_vector(15 downto 0);
        
        -- Clock divider status
        stat_clk_div_status  : out std_logic_vector(7 downto 0);
        stat_clk_en          : out std_logic
    );
end entity;

architecture behavioral of probe_driver_top is
    
    -- Internal signals
    signal clk_en_internal : std_logic;
    signal clk_div_status : std_logic_vector(7 downto 0);
    
begin
    
    -- =============================================================================
    -- CLOCK DIVIDER INSTANTIATION
    -- =============================================================================
    
    -- Direct instantiation of clk_divider_core (required for top layer)
    CLK_DIVIDER: entity work.clk_divider_core
        port map (
            clk => Clk,
            rst_n => not Reset,
            div_sel => cfg_clk_div_sel,
            clk_en => clk_en_internal,
            stat_reg => clk_div_status
        );
    
    -- =============================================================================
    -- PROBE DRIVER INTERFACE INSTANTIATION
    -- =============================================================================
    
    -- Direct instantiation of probe_driver_interface (required for top layer)
    PROBE_DRIVER: entity work.probe_driver_interface
        port map (
            Clk => Clk,
            Reset => Reset,
            ctrl_enable => ctrl_enable,
            ctrl_arm => ctrl_arm,
            ctrl_fire => ctrl_fire,
            ctrl_reset => ctrl_reset,
            cfg_intensity_index => cfg_intensity_index,
            cfg_duration => cfg_duration,
            cfg_cooldown => cfg_cooldown,
            cfg_trigger_threshold => cfg_trigger_threshold,
            data_trigger_in => data_trigger_in,
            stat_probe_state => stat_probe_state,
            stat_status_reg => stat_status_reg,
            stat_armed => stat_armed,
            stat_firing => stat_firing,
            stat_cooldown => stat_cooldown,
            stat_error => stat_error,
            stat_ready => stat_ready,
            data_intensity_out => data_intensity_out
        );
    
    -- =============================================================================
    -- OUTPUT ASSIGNMENTS
    -- =============================================================================
    
    -- Clock divider status outputs
    stat_clk_div_status <= clk_div_status;
    stat_clk_en <= clk_en_internal;

end architecture;
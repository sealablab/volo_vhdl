--------------------------------------------------------------------------------
-- Example: CustomWrapper Implementation
-- Purpose: Shows how the vendor's CustomWrapper would instantiate probe_driver_interface
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- NOTE: This is an EXAMPLE file showing how the vendor's CustomWrapper entity
-- would instantiate our probe_driver_interface module. This file should NOT
-- be compiled with the vendor's tools as they provide their own CustomWrapper.
-- 
-- This file is for reference only and demonstrates the proper integration pattern.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg.all;
use work.Probe_Config_pkg.all;
use work.Moku_Voltage_pkg.all;

architecture behavioural of CustomWrapper is
    -- Internal signals for probe driver interface
    signal ctrl_enable          : std_logic;
    signal ctrl_arm             : std_logic;
    signal ctrl_fire            : std_logic;
    signal ctrl_reset           : std_logic;
    
    signal cfg_intensity_index  : std_logic_vector(SYSTEM_INTENSITY_INDEX_WIDTH-1 downto 0);
    signal cfg_duration         : std_logic_vector(SYSTEM_DURATION_WIDTH-1 downto 0);
    signal cfg_cooldown         : std_logic_vector(SYSTEM_COOLDOWN_WIDTH-1 downto 0);
    signal cfg_trigger_threshold : std_logic_vector(15 downto 0);
    
    signal stat_probe_state     : std_logic_vector(1 downto 0);
    signal stat_status_reg      : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0);
    signal stat_armed           : std_logic;
    signal stat_firing          : std_logic;
    signal stat_cooldown        : std_logic;
    signal stat_error           : std_logic;
    signal stat_ready           : std_logic;
    
    signal data_trigger_in      : std_logic_vector(15 downto 0);
    signal data_intensity_out   : std_logic_vector(15 downto 0);
    
    -- Register decoding constants
    constant GLOBAL_ENABLE_BIT     : natural := 31;
    constant SOFT_TRIG_BIT         : natural := 23;
    constant INTENSITY_INDEX_START : natural := 16;
    constant INTENSITY_INDEX_END   : natural := 22;
    constant DURATION_START        : natural := 16;
    constant DURATION_END          : natural := 31;
    
    -- Default values
    constant DEFAULT_COOLDOWN      : std_logic_vector(15 downto 0) := x"03E8";
    constant DEFAULT_TRIGGER_THRESHOLD : std_logic_vector(15 downto 0) := x"4000";
    
    -- Soft trigger handling
    signal soft_trig_prev         : std_logic;
    signal soft_trig_active       : std_logic;
    
begin
    -- Register decoding logic
    ctrl_enable <= not Control0(GLOBAL_ENABLE_BIT);
    soft_trig_active <= Control0(SOFT_TRIG_BIT);
    cfg_intensity_index <= Control0(INTENSITY_INDEX_END downto INTENSITY_INDEX_START);
    cfg_duration <= Control1(DURATION_END downto DURATION_START);
    
    cfg_cooldown <= DEFAULT_COOLDOWN;
    cfg_trigger_threshold <= DEFAULT_TRIGGER_THRESHOLD;
    
    ctrl_reset <= Reset;
    ctrl_arm <= '0';
    ctrl_fire <= '0';
    
    data_trigger_in <= std_logic_vector(InputA);
    
    -- Soft trigger logic
    SOFT_TRIG: process(Clk) is
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                soft_trig_prev <= '0';
            else
                soft_trig_prev <= soft_trig_active;
            end if;
        end if;
    end process;
    
    -- Output mapping
    OutputA <= signed(data_intensity_out);
    OutputB <= signed(stat_status_reg);
    OutputC <= signed("00000000000000" & stat_probe_state);
    
    -- Probe driver interface instantiation
    PROBE_DRIVER: entity work.probe_driver_interface
        port map (
            Clk     => Clk,
            Reset   => Reset,
            
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
end architecture;
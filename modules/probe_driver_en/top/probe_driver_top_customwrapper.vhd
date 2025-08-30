--------------------------------------------------------------------------------
-- CustomWrapper Implementation for probe_driver_top
-- Purpose: Lightweight CustomWrapper that maps platform signals to probe_driver_top
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- This CustomWrapper provides a minimal interface mapping between the platform
-- control system and the probe_driver_top module, including clock divider support.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg_en.all;
use work.Probe_Config_pkg_en.all;
use work.Moku_Voltage_pkg_en.all;
use work.platform_interface_pkg.all;

architecture behavioural of CustomWrapper is
    -- Soft trigger handling
    signal soft_trig_prev         : std_logic;
    signal soft_trig_active       : std_logic;
    signal ctrl_fire              : std_logic;
    
    -- Output signals (only the ones actually used)
    signal stat_status_reg        : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0);
    signal data_intensity_out     : std_logic_vector(15 downto 0);
    signal stat_clk_div_status    : std_logic_vector(7 downto 0);
    
begin
    -- =============================================================================
    -- REGISTER DECODING LOGIC
    -- =============================================================================
    
    -- Soft trigger handling
    soft_trig_active <= Control0(SOFT_TRIG_BIT);
    
    -- =============================================================================
    -- SOFT TRIGGER LOGIC
    -- =============================================================================
    
    SOFT_TRIG: process(Clk) is
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                soft_trig_prev <= '0';
            else
                soft_trig_prev <= soft_trig_active;
                -- Generate fire pulse on rising edge of soft trigger
                if soft_trig_active = '1' and soft_trig_prev = '0' then
                    ctrl_fire <= '1';
                else
                    ctrl_fire <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- =============================================================================
    -- OUTPUT MAPPING
    -- =============================================================================
    
    -- Primary outputs
    OutputA <= signed(data_intensity_out);
    OutputB <= signed(stat_status_reg);
    OutputC <= signed(x"00" & stat_clk_div_status);
    
    -- =============================================================================
    -- PROBE DRIVER TOP INSTANTIATION
    -- =============================================================================
    
    -- Direct instantiation of probe_driver_top (required for top layer)
    PROBE_DRIVER_TOP: entity work.probe_driver_top
        port map (
            Clk => Clk,
            Reset => Reset,
            cfg_clk_div_sel => Control0(CLK_DIV_SEL_END downto CLK_DIV_SEL_START),
            ctrl_enable => not Control0(GLOBAL_ENABLE_BIT),
            ctrl_arm => '0',  -- Not used in this lightweight implementation
            ctrl_fire => ctrl_fire,
            ctrl_reset => Reset,
            cfg_intensity_index => Control0(INTENSITY_INDEX_END downto INTENSITY_INDEX_START),
            cfg_duration => Control1(DURATION_END downto DURATION_START),
            cfg_cooldown => DEFAULT_COOLDOWN,
            cfg_trigger_threshold => DEFAULT_TRIGGER_THRESHOLD,
            data_trigger_in => std_logic_vector(InputA),
            stat_probe_state => open,  -- Not used in outputs
            stat_status_reg => stat_status_reg,
            stat_armed => open,        -- Not used in outputs
            stat_firing => open,       -- Not used in outputs
            stat_cooldown => open,     -- Not used in outputs
            stat_error => open,        -- Not used in outputs
            stat_ready => open,        -- Not used in outputs
            data_intensity_out => data_intensity_out,
            stat_clk_div_status => stat_clk_div_status,
            stat_clk_en => open        -- Not used in outputs
        );

end architecture;
--------------------------------------------------------------------------------
-- Entity: probe_driver_interface
-- Purpose: Top-level interface module for ProbeDriver system
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- TOP LAYER: This module provides the interface that CustomWrapper would instantiate
-- for the ProbeDriver system, exposing control, configuration, and status registers
-- to the platform control system. Designed for minimal functionality with proper
-- register exposure following VHDL-2008 and Verilog portability standards.
-- 
-- FEATURES:
-- - Interface module for platform control system integration
-- - Control, configuration, and status register exposure
-- - Default status register implementation
-- - Flat port structure for Verilog compatibility
-- - Synchronous operation with proper reset handling
-- 
-- REGISTER LAYOUT:
-- Control0: Bit-31: global nEnable, Bit-23: soft_trig_in, Bits 22-16: intensity index
-- Control1: Bits 31-16: 16-bit unsigned duration
-- 
-- NOTE: This module is designed to be instantiated by CustomWrapper, not to define it.
-- The CustomWrapper entity is provided by the vendor's compiler package.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg.all;
use work.Trigger_Config_pkg.all;
use work.Moku_Voltage_pkg.all;

entity probe_driver_interface is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Input signals (mapped to probe driver inputs)
        InputA  : in  signed(15 downto 0);  -- Trigger input data
        InputB  : in  signed(15 downto 0);  -- Reserved for future use
        InputC  : in  signed(15 downto 0);  -- Reserved for future use
        
        -- Output signals (mapped to probe driver outputs)
        OutputA : out signed(15 downto 0);  -- Intensity output
        OutputB : out signed(15 downto 0);  -- Status register
        OutputC : out signed(15 downto 0);  -- Probe state
        
        -- Control registers
        Control0  : in  std_logic_vector(31 downto 0);
        Control1  : in  std_logic_vector(31 downto 0);
        Control2  : in  std_logic_vector(31 downto 0);
        Control3  : in  std_logic_vector(31 downto 0);
        Control4  : in  std_logic_vector(31 downto 0);
        Control5  : in  std_logic_vector(31 downto 0);
        Control6  : in  std_logic_vector(31 downto 0);
        Control7  : in  std_logic_vector(31 downto 0);
        Control8  : in  std_logic_vector(31 downto 0);
        Control9  : in  std_logic_vector(31 downto 0);
        Control10 : in  std_logic_vector(31 downto 0);
        Control11 : in  std_logic_vector(31 downto 0);
        Control12 : in  std_logic_vector(31 downto 0);
        Control13 : in  std_logic_vector(31 downto 0);
        Control14 : in  std_logic_vector(31 downto 0);
        Control15 : in  std_logic_vector(31 downto 0)
    );
end entity probe_driver_interface;

architecture behavioral of probe_driver_interface is
    -- Internal signals for probe driver core
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
    constant DEFAULT_COOLDOWN      : std_logic_vector(15 downto 0) := x"03E8"; -- 1000 cycles
    constant DEFAULT_TRIGGER_THRESHOLD : std_logic_vector(15 downto 0) := x"4000"; -- Mid-scale
    
    -- Soft trigger handling
    signal soft_trig_prev         : std_logic;
    signal soft_trig_active       : std_logic;
    
    -- Output signal extensions
    signal output_c_extended      : std_logic_vector(15 downto 0);
    
begin
    -- =============================================================================
    -- REGISTER DECODING LOGIC
    -- =============================================================================
    
    -- Global enable from Control0 bit 31 (inverted for nEnable)
    ctrl_enable <= not Control0(GLOBAL_ENABLE_BIT);
    
    -- Soft trigger from Control0 bit 23
    soft_trig_active <= Control0(SOFT_TRIG_BIT);
    
    -- Intensity index from Control0 bits 22-16
    cfg_intensity_index <= Control0(INTENSITY_INDEX_END downto INTENSITY_INDEX_START);
    
    -- Duration from Control1 bits 31-16
    cfg_duration <= Control1(DURATION_END downto DURATION_START);
    
    -- Use default values for other configuration
    cfg_cooldown <= DEFAULT_COOLDOWN;
    cfg_trigger_threshold <= DEFAULT_TRIGGER_THRESHOLD;
    
    -- Control logic
    ctrl_reset <= Reset;
    ctrl_arm <= '0';  -- Not implemented in current register layout
    ctrl_fire <= '0'; -- Not implemented in current register layout
    
    -- Trigger input mapping
    data_trigger_in <= std_logic_vector(InputA);
    
    -- =============================================================================
    -- SOFT TRIGGER LOGIC
    -- =============================================================================
    
    -- Detect rising edge of soft trigger and auto-clear when entering IDLE state
    process(Clk, Reset)
    begin
        if Reset = '1' then
            soft_trig_prev <= '0';
        elsif rising_edge(Clk) then
            soft_trig_prev <= soft_trig_active;
            
            -- Auto-clear soft trigger when entering IDLE state
            if stat_probe_state = IDLE_STATE then
                -- Note: In CustomWrapper, we can't directly modify Control0
                -- The platform will need to handle this auto-clear
            end if;
        end if;
    end process;
    
    -- =============================================================================
    -- OUTPUT MAPPING
    -- =============================================================================
    
    -- Extend probe state to 16-bit
    output_c_extended <= "00000000000000" & stat_probe_state;
    
    -- Map probe driver outputs to CustomWrapper outputs
    OutputA <= signed(data_intensity_out);
    OutputB <= signed(stat_status_reg);  -- Already 16-bit
    OutputC <= signed(output_c_extended);
    
    -- =============================================================================
    -- PROBE DRIVER CORE INSTANTIATION
    -- =============================================================================
    
    -- Instantiate probe_driver_core
    probe_driver_core_inst : entity work.probe_driver_core
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

end architecture behavioral;

--------------------------------------------------------------------------------
-- Entity: probe_driver_core
-- Purpose: Core logic implementation for ProbeDriver module
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- CORE LAYER: This module implements the core logic for the ProbeDriver system.
-- Currently a placeholder implementation that provides the interface structure
-- for future development.
-- 
-- FEATURES:
-- - Placeholder implementation with proper interface
-- - Default status register implementation
-- - Flat port structure for Verilog compatibility
-- - Synchronous operation with proper reset handling
-- - Ready for future core logic implementation
--
-- UNIT HINTING CONVENTIONS:
-- - Time units: All time-related parameters in microseconds (us) or milliseconds (ms)
-- - Voltage units: All voltage parameters in volts (V)
-- - Current units: All current parameters in milliamperes (mA)
-- - Frequency units: All frequency parameters in megahertz (MHz)
-- - Duration units: All duration parameters in microseconds (us)
-- - Intensity units: All intensity parameters in volts (V) or percentage (%)
-- - Threshold units: All threshold parameters in volts (V)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import probe_driver packages (enhanced versions)
use work.probe_driver_pkg.all;
use work.PercentLut_pkg_en.all;
use work.Probe_Config_pkg_en.all;
use work.Moku_Voltage_pkg_en.all;

entity probe_driver_core is
    generic (
        CLK_FREQ_MHZ : natural := 100;  -- Clock frequency in MHz
        ENABLE_DEBUG : boolean := false -- Debug mode enable flag
    );
    port (
        -- Clock and Reset
        ctrl_clk     : in  std_logic;  -- System clock
        ctrl_rst_n   : in  std_logic;  -- Active-low reset
        
        -- Control signals
        ctrl_enable  : in  std_logic;  -- Enable probe driver operation
        ctrl_arm     : in  std_logic;  -- Arm probe for firing
        ctrl_fire    : in  std_logic;  -- Fire probe immediately
        ctrl_reset   : in  std_logic;  -- Reset probe state
        
        -- Configuration signals (with unit hints)
        cfg_intensity_index  : in  std_logic_vector(SYSTEM_INTENSITY_INDEX_WIDTH-1 downto 0);  -- Intensity index (0-100%)
        cfg_duration         : in  std_logic_vector(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Pulse duration in us
        cfg_cooldown         : in  std_logic_vector(SYSTEM_COOLDOWN_WIDTH-1 downto 0);         -- Cooldown period in us
        cfg_trigger_threshold : in  std_logic_vector(15 downto 0);                             -- Trigger threshold in V
        
        -- Status signals
        stat_probe_state     : out std_logic_vector(1 downto 0);                               -- Current probe state
        stat_status_reg      : out std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0);           -- Status register
        stat_armed           : out std_logic;  -- Probe is armed
        stat_firing          : out std_logic;  -- Probe is firing
        stat_cooldown        : out std_logic;  -- Probe is in cooldown
        stat_error           : out std_logic;  -- Error condition detected
        stat_ready           : out std_logic;  -- Probe is ready for operation
        
        -- Data signals (with unit hints)
        data_trigger_in      : in  std_logic_vector(15 downto 0);  -- Trigger input voltage in V
        data_intensity_out   : out std_logic_vector(15 downto 0)   -- Output intensity voltage in V
    );
end entity probe_driver_core;

architecture behavioral of probe_driver_core is
    -- Internal state signals
    signal current_state : std_logic_vector(1 downto 0);
    signal status_register : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0);
    
    -- State constants (using package definitions)
    -- IDLE_STATE, ARMED_STATE, FIRING_STATE, COOL_DOWN_STATE are defined in probe_driver_pkg
    
begin
    -- =============================================================================
    -- MAIN STATE MACHINE
    -- =============================================================================
    
    state_machine : process(ctrl_clk, ctrl_rst_n)
    begin
        if ctrl_rst_n = '0' then
            -- Reset state
            current_state <= IDLE_STATE;
            status_register <= (others => '0');
            
        elsif rising_edge(ctrl_clk) then
            -- Default status register values
            status_register <= (others => '0');
            status_register(0) <= '1';  -- Ready bit
            
            -- Simple state machine logic (placeholder implementation)
            case current_state is
                when IDLE_STATE =>
                    if ctrl_enable = '1' and ctrl_arm = '1' then
                        current_state <= ARMED_STATE;
                    end if;
                    
                when ARMED_STATE =>
                    if ctrl_fire = '1' or (data_trigger_in >= cfg_trigger_threshold) then
                        current_state <= FIRING_STATE;
                    elsif ctrl_enable = '0' then
                        current_state <= IDLE_STATE;
                    end if;
                    
                when FIRING_STATE =>
                    -- Placeholder: transition to cooldown after duration
                    current_state <= COOL_DOWN_STATE;
                    
                when COOL_DOWN_STATE =>
                    -- Placeholder: transition to idle after cooldown
                    current_state <= IDLE_STATE;
                    
                when others =>
                    current_state <= IDLE_STATE;
            end case;
        end if;
    end process;
    
    -- =============================================================================
    -- OUTPUT ASSIGNMENTS
    -- =============================================================================
    
    -- State outputs
    stat_probe_state <= current_state;
    stat_status_reg <= status_register;
    
    -- Status flags based on current state
    stat_armed <= '1' when current_state = ARMED_STATE else '0';
    stat_firing <= '1' when current_state = FIRING_STATE else '0';
    stat_cooldown <= '1' when current_state = COOL_DOWN_STATE else '0';
    stat_error <= '0';  -- No errors in placeholder implementation
    stat_ready <= '1' when current_state = IDLE_STATE else '0';
    
    -- Data outputs (placeholder implementation)
    data_intensity_out <= (others => '0');  -- Placeholder: no intensity output yet

end architecture behavioral;
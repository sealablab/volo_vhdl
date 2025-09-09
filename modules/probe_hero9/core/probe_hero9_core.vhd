-- =============================================================================
-- ProbeHero9 Core Entity
-- =============================================================================
-- 
-- Generated from: PH9-interface-reqs-v1.md
-- Date: 2025-01-27
-- Purpose: Core entity for ProbeHero9 module with reset handler
-- 
-- This entity implements the core functionality of ProbeHero9 including
-- state machine, output control, and input validation following VOLO standards.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import VOLO packages
use work.volo_common_pkg.ALL;
use work.probe_hero9_constants_pkg.ALL;
use work.Probe_Config_pkg_PH9.ALL;
use work.Global_Probe_Table_pkg_PH9.ALL;
use work.Moku_Voltage_pkg_PH9.ALL;
use work.PercentLut_pkg_PH9.ALL;

entity probe_hero9_core is
    port (
        -- Standard Control Signals
        clk : in std_logic;                    -- Units: signal (primary clock)
        reset_n : in std_logic;                -- Units: signal (active low reset)
        enable : in std_logic;                 -- Units: signal (module enable)
        clk_en : in std_logic;                 -- Units: signal (clock enable)
        
        -- Custom Control Signals
        trig_in : in std_logic;                -- Units: signal (trigger input)
        
        -- Configuration Parameters
        probe_selector_index_in : in std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0);  -- Units: index (probe selector)
        intensity_index_in : in std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0);       -- Units: index (intensity index)
        fire_duration_in : in unsigned(DURATION_WIDTH-1 downto 0);                       -- Units: clks (fire duration)
        cooldown_duration_in : in unsigned(DURATION_WIDTH-1 downto 0);                    -- Units: clks (cooldown duration)
        
        -- Output Interface
        trigger_out : out signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);  -- Units: volts (trigger voltage output)
        intensity_out : out signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0); -- Units: volts (intensity voltage output)
        probe_status_out : out std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0)        -- Units: bits (status register)
    );
end entity probe_hero9_core;

-- =============================================================================
-- Architecture Implementation
-- =============================================================================

architecture rtl of probe_hero9_core is

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================
    
    -- Core State Machine Signals (using volo_common_pkg constants)
    signal current_state : std_logic_vector(1 downto 0) := work.volo_common_pkg.STATE_RESET;  -- Units: state (current state)
    
    -- User provided signals begin
    -- Configuration Signals
    signal current_probe_config : t_probe_config;  -- Units: record (current probe config)
    signal current_intensity_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);     -- Units: volts (current intensity voltage)
    signal current_trigger_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);       -- Units: volts (current trigger voltage)
    
    -- User provided validation signals
    signal probe_selector_valid : boolean := false;  -- Units: boolean (probe selector validity)
    signal intensity_index_valid : boolean := false; -- Units: boolean (intensity index validity)
    signal fire_duration_valid : boolean := false;    -- Units: boolean (fire duration validity)
    signal cooldown_duration_valid : boolean := false; -- Units: boolean (cooldown duration validity)
    
    -- Status Signals (standard VOLO infrastructure)
    signal status_register : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (others => '0');  -- Units: bits (status register)
    
    -- Constants for record initialization
    constant DEFAULT_PROBE_NAME : string(1 to 16) := "DEFAULT         ";

begin

    -- =========================================================================
    -- Core Reset Handler Process
    -- =========================================================================
    -- Implements: RESET -> READY (validation) -> IDLE (user pickup point) -> FAULT (validation failure)
    
    core_reset_handler_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                -- Reset all signals to safe state
                current_state <= work.volo_common_pkg.STATE_RESET;
                probe_selector_valid <= false;
                intensity_index_valid <= false;
                fire_duration_valid <= false;
                cooldown_duration_valid <= false;
                current_probe_config <= (probe_name => DEFAULT_PROBE_NAME,
                                        probe_trigger_voltage => x"0000",
                                        probe_intensity_min => x"0000",
                                        probe_intensity_max => x"FFFF",
                                        fire_duration_min => to_unsigned(0, DURATION_WIDTH),
                                        fire_duration_max => to_unsigned(1000, DURATION_WIDTH),
                                        cooldown_duration_min => to_unsigned(100, DURATION_WIDTH),
                                        cooldown_duration_max => to_unsigned(10000, DURATION_WIDTH),
                                        safety_enabled => '1',
                                        max_fire_rate => to_unsigned(1000, 16));
                current_intensity_voltage <= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
                current_trigger_voltage <= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
            elsif clk_en = '1' then
                -- Input validation (always check)
                probe_selector_valid <= is_valid_probe_selector(probe_selector_index_in);
                intensity_index_valid <= is_valid_intensity_index(intensity_index_in);
                fire_duration_valid <= is_valid_duration(fire_duration_in);
                cooldown_duration_valid <= is_valid_duration(cooldown_duration_in);
                
                -- State machine transitions
                case current_state is
                    when work.volo_common_pkg.STATE_RESET =>
                        -- Check if all parameters are valid
                        if probe_selector_valid and intensity_index_valid and 
                           fire_duration_valid and cooldown_duration_valid then
                            current_state <= work.volo_common_pkg.STATE_READY;
                        end if;
                        
                    when work.volo_common_pkg.STATE_READY =>
                        -- Load configuration when parameters are valid
                        if probe_selector_valid then
                            -- Use a simple default configuration for now
                            current_probe_config <= (probe_name => "PROBE_0         ",
                                                    probe_trigger_voltage => x"8000",
                                                    probe_intensity_min => x"0000",
                                                    probe_intensity_max => x"FFFF",
                                                    fire_duration_min => to_unsigned(0, DURATION_WIDTH),
                                                    fire_duration_max => to_unsigned(1000, DURATION_WIDTH),
                                                    cooldown_duration_min => to_unsigned(100, DURATION_WIDTH),
                                                    cooldown_duration_max => to_unsigned(10000, DURATION_WIDTH),
                                                    safety_enabled => '1',
                                                    max_fire_rate => to_unsigned(1000, 16));
                            
                            if intensity_index_valid then
                                current_intensity_voltage <= to_signed(to_integer(unsigned(intensity_index_in)) * 100, VOLTAGE_OUTPUT_WIDTH);
                            end if;
                            
                            current_trigger_voltage <= to_signed(32767, VOLTAGE_OUTPUT_WIDTH);  -- 5V equivalent
                        end if;
                        
                        -- Transition to IDLE when enable is asserted (user pickup point)
                        if enable = '1' then
                            current_state <= work.volo_common_pkg.STATE_IDLE;
                        end if;
                        
                    when work.volo_common_pkg.STATE_IDLE =>
                        -- User implementation pickup point - no automatic transitions
                        -- User logic should handle state transitions from here
                        null;
                        
                    when work.volo_common_pkg.STATE_FAULT =>
                        -- FAULT state - only reset can exit
                        null;
                        
                    when others =>
                        -- Invalid state - go to FAULT
                        current_state <= work.volo_common_pkg.STATE_FAULT;
                end case;
                
                -- Check for validation failures (any state can go to FAULT)
                if not (probe_selector_valid and intensity_index_valid and 
                       fire_duration_valid and cooldown_duration_valid) then
                    current_state <= work.volo_common_pkg.STATE_FAULT;
                end if;
            end if;
        end if;
    end process;
    
    
    -- =========================================================================
    -- Status Register Process
    -- =========================================================================
    
    status_register_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                status_register <= (others => '0');
            elsif clk_en = '1' then
                -- Clear all status bits
                status_register <= (others => '0');
                
                -- Set status bits based on current state
                case current_state is
                    when work.volo_common_pkg.STATE_RESET =>
                        -- No status bits set in reset
                        null;
                        
                    when work.volo_common_pkg.STATE_READY =>
                        status_register(work.volo_common_pkg.STATUS_READY_BIT) <= '1';
                        
                    when work.volo_common_pkg.STATE_IDLE =>
                        status_register(work.volo_common_pkg.STATUS_IDLE_BIT) <= '1';
                        -- User implementation can set additional status bits here
                        
                    when work.volo_common_pkg.STATE_FAULT =>
                        status_register(work.volo_common_pkg.STATUS_FAULT_BIT) <= '1';
                        
                    when others =>
                        status_register(work.volo_common_pkg.STATUS_FAULT_BIT) <= '1';
                end case;
                
                -- Set alarm bit for validation failures
                if not (probe_selector_valid and intensity_index_valid and 
                       fire_duration_valid and cooldown_duration_valid) then
                    status_register(work.volo_common_pkg.STATUS_ALARM_BIT) <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Output Assignment
    -- =========================================================================
    
    -- Output voltage assignment using global constants
    -- User implementation should control when outputs are active
    trigger_out <= current_trigger_voltage when (current_state = work.volo_common_pkg.STATE_IDLE) else work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
    intensity_out <= current_intensity_voltage when (current_state = work.volo_common_pkg.STATE_IDLE) else work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
    
    -- Status register output
    probe_status_out <= status_register;

end architecture rtl;
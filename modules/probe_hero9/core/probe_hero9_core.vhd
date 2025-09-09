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
    
    -- State Machine Signals
    signal current_state : std_logic_vector(STATE_WIDTH-1 downto 0) := STATE_IDLE;  -- Units: state (current state)
    signal next_state : std_logic_vector(STATE_WIDTH-1 downto 0) := STATE_IDLE;     -- Units: state (next state)
    
    -- Timer Signals
    signal fire_timer : unsigned(DURATION_WIDTH-1 downto 0) := (others => '0');     -- Units: clks (fire timer)
    signal cooldown_timer : unsigned(DURATION_WIDTH-1 downto 0) := (others => '0'); -- Units: clks (cooldown timer)
    
    -- Configuration Signals
    signal current_probe_config : t_probe_config;  -- Units: record (current probe config)
    signal current_intensity_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);     -- Units: volts (current intensity voltage)
    signal current_trigger_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);       -- Units: volts (current trigger voltage)
    
    -- Status Signals
    signal status_register : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (others => '0');  -- Units: bits (status register)
    
    -- Validation Signals
    signal probe_selector_valid : boolean := false;  -- Units: boolean (probe selector validity)
    signal intensity_index_valid : boolean := false; -- Units: boolean (intensity index validity)
    signal fire_duration_valid : boolean := false;    -- Units: boolean (fire duration validity)
    signal cooldown_duration_valid : boolean := false; -- Units: boolean (cooldown duration validity)
    
    -- Trigger Detection
    signal trig_in_prev : std_logic := '0';  -- Units: signal (previous trigger state)
    signal trig_rising_edge : boolean := false;  -- Units: boolean (trigger rising edge detected)

begin

    -- =========================================================================
    -- Input Validation Process
    -- =========================================================================
    
    input_validation_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                probe_selector_valid <= false;
                intensity_index_valid <= false;
                fire_duration_valid <= false;
                cooldown_duration_valid <= false;
            elsif clk_en = '1' then
                -- Validate probe selector index
                probe_selector_valid <= is_valid_probe_selector(probe_selector_index_in);
                
                -- Validate intensity index
                intensity_index_valid <= is_valid_intensity_index(intensity_index_in);
                
                -- Validate durations (basic range check, will be clamped to probe limits)
                fire_duration_valid <= is_valid_duration(fire_duration_in);
                cooldown_duration_valid <= is_valid_duration(cooldown_duration_in);
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Configuration Loading Process
    -- =========================================================================
    
    config_loading_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                current_probe_config <= get_default_probe_config;
                current_intensity_voltage <= SAFE_VOLTAGE_OUTPUT;
                current_trigger_voltage <= SAFE_VOLTAGE_OUTPUT;
            elsif clk_en = '1' and probe_selector_valid then
                -- Load probe configuration from global table
                current_probe_config <= get_probe_config_from_table(to_integer(unsigned(probe_selector_index_in)));
                
                -- Load intensity voltage from PercentLut
                if intensity_index_valid then
                    current_intensity_voltage <= signed(get_percent_lut_value(to_integer(unsigned(intensity_index_in))));
                end if;
                
                -- Set trigger voltage from probe config
                current_trigger_voltage <= signed(voltage_to_digital(current_probe_config.probe_trigger_voltage));
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Trigger Detection Process
    -- =========================================================================
    
    trigger_detection_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                trig_in_prev <= '0';
                trig_rising_edge <= false;
            elsif clk_en = '1' then
                trig_in_prev <= trig_in;
                trig_rising_edge <= (trig_in = '1') and (trig_in_prev = '0');
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- State Machine Process
    -- =========================================================================
    
    state_machine_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                current_state <= STATE_IDLE;
                fire_timer <= (others => '0');
                cooldown_timer <= (others => '0');
            elsif clk_en = '1' then
                current_state <= next_state;
                
                -- Timer management
                case current_state is
                    when STATE_FIRING =>
                        if fire_timer > 0 then
                            fire_timer <= fire_timer - 1;
                        end if;
                    when STATE_COOLING =>
                        if cooldown_timer > 0 then
                            cooldown_timer <= cooldown_timer - 1;
                        end if;
                    when others =>
                        -- Reset timers when not in timing states
                        fire_timer <= (others => '0');
                        cooldown_timer <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Next State Logic
    -- =========================================================================
    
    next_state_logic_proc : process(current_state, enable, trig_rising_edge, fire_timer, cooldown_timer, 
                                   probe_selector_valid, intensity_index_valid, fire_duration_valid, cooldown_duration_valid)
    begin
        next_state <= current_state;  -- Default: stay in current state
        
        case current_state is
            when STATE_IDLE =>
                if enable = '1' and probe_selector_valid and intensity_index_valid and 
                   fire_duration_valid and cooldown_duration_valid then
                    next_state <= STATE_ARMED;
                elsif not (probe_selector_valid and intensity_index_valid and 
                          fire_duration_valid and cooldown_duration_valid) then
                    next_state <= STATE_HARDFAULT;
                end if;
                
            when STATE_ARMED =>
                if enable = '0' then
                    next_state <= STATE_IDLE;
                elsif trig_rising_edge then
                    next_state <= STATE_FIRING;
                end if;
                
            when STATE_FIRING =>
                if fire_timer = 0 then
                    next_state <= STATE_COOLING;
                end if;
                
            when STATE_COOLING =>
                if cooldown_timer = 0 then
                    next_state <= STATE_IDLE;
                end if;
                
            when STATE_HARDFAULT =>
                -- Stay in hardfault until reset
                next_state <= STATE_HARDFAULT;
                
            when others =>
                next_state <= STATE_IDLE;
        end case;
    end process;
    
    -- =========================================================================
    -- Timer Initialization Logic
    -- =========================================================================
    
    timer_init_proc : process(current_state, next_state, fire_duration_in, cooldown_duration_in, current_probe_config)
    begin
        -- Initialize timers when entering timing states
        if current_state /= STATE_FIRING and next_state = STATE_FIRING then
            -- Clamp fire duration to probe limits
            if fire_duration_in < current_probe_config.fire_duration_min then
                fire_timer <= current_probe_config.fire_duration_min;
            elsif fire_duration_in > current_probe_config.fire_duration_max then
                fire_timer <= current_probe_config.fire_duration_max;
            else
                fire_timer <= fire_duration_in;
            end if;
        end if;
        
        if current_state /= STATE_COOLING and next_state = STATE_COOLING then
            -- Clamp cooldown duration to probe limits
            if cooldown_duration_in < current_probe_config.cooldown_duration_min then
                cooldown_timer <= current_probe_config.cooldown_duration_min;
            elsif cooldown_duration_in > current_probe_config.cooldown_duration_max then
                cooldown_timer <= current_probe_config.cooldown_duration_max;
            else
                cooldown_timer <= cooldown_duration_in;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Status Register Update Process
    -- =========================================================================
    
    status_update_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                status_register <= (others => '0');
            elsif clk_en = '1' then
                -- Clear all status bits
                status_register <= (others => '0');
                
                -- Set status bits based on current state and conditions
                case current_state is
                    when STATE_IDLE =>
                        -- No status bits set in idle
                        null;
                        
                    when STATE_ARMED =>
                        status_register(STATUS_ARMED_BIT) <= '1';
                        
                    when STATE_FIRING =>
                        status_register(STATUS_ARMED_BIT) <= '1';
                        status_register(STATUS_FIRING_BIT) <= '1';
                        status_register(STATUS_FIRED_BIT) <= '1';  -- Sticky bit
                        
                    when STATE_COOLING =>
                        status_register(STATUS_COOL_BIT) <= '1';
                        status_register(STATUS_FIRED_BIT) <= '1';  -- Sticky bit
                        
                    when STATE_HARDFAULT =>
                        status_register(STATUS_FAULT_BIT) <= '1';
                        
                    when others =>
                        null;
                end case;
                
                -- Set alarm bit for validation failures or clamping
                if not (probe_selector_valid and intensity_index_valid and 
                       fire_duration_valid and cooldown_duration_valid) then
                    status_register(STATUS_ALARM_BIT) <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Output Assignment
    -- =========================================================================
    
    -- Output voltage assignment based on state
    trigger_out <= current_trigger_voltage when current_state = STATE_FIRING else SAFE_VOLTAGE_OUTPUT;
    intensity_out <= current_intensity_voltage when current_state = STATE_FIRING else SAFE_VOLTAGE_OUTPUT;
    
    -- Status register output
    probe_status_out <= status_register;

end architecture rtl;
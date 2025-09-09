-- =============================================================================
-- ProbeHero10 Core Entity
-- =============================================================================
-- 
-- This core entity implements the standard VOLO state machine for the ProbeHero10
-- voltage-controlled probe firing system. It provides parameter validation,
-- safe state management, and user implementation pickup point at IDLE state.
-- 
-- CORE STATE MACHINE: RESET → READY → IDLE → FAULT
-- USER IMPLEMENTATION: Begins at IDLE state
-- 
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import VOLO packages
use work.volo_common_pkg.ALL;
use work.probe_hero10_constants_pkg.ALL;
use work.Probe_Config_pkg_PH10.ALL;
use work.Global_Probe_Table_pkg_PH10.ALL;
use work.Moku_Voltage_pkg_PH10.ALL;
use work.PercentLut_pkg_PH10.ALL;

entity probe_hero10_core is
    port (
        -- Standard Control Signals
        clk : in std_logic;                    -- Units: signal (primary clock)
        reset_n : in std_logic;                -- Units: signal (active low reset)
        enable : in std_logic;                 -- Units: signal (module enable)
        clk_en : in std_logic;                 -- Units: signal (clock enable)
        
        -- Custom Control Signals
        trig_in : in std_logic;                -- Units: signal (trigger input for probe firing)
        
        -- Configuration Parameters
        probe_selector_index_in : in std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0);  -- Units: index (probe selection)
        intensity_index_in : in std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0);     -- Units: index (intensity control)
        fire_duration_in : in unsigned(DURATION_WIDTH-1 downto 0);                       -- Units: clks (fire duration)
        cooldown_duration_in : in unsigned(DURATION_WIDTH-1 downto 0);                    -- Units: clks (cooldown duration)
        
        -- Primary Outputs
        trigger_out : out signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);                      -- Units: volts (trigger voltage output)
        intensity_out : out signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);                      -- Units: volts (intensity voltage output)
        
        -- Status Outputs
        probe_status_out : out std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0)       -- Units: signal (status register)
    );
end entity probe_hero10_core;

architecture rtl of probe_hero10_core is

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================
    
    -- Core State Machine Signals (using volo_common_pkg constants)
    signal current_state : std_logic_vector(1 downto 0) := work.volo_common_pkg.STATE_RESET;
    
    -- User provided signals begin
    signal current_probe_config : t_probe_config;
    signal current_intensity_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    signal current_trigger_voltage : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0);
    
    -- User provided validation signals
    signal probe_selector_valid : boolean := false;
    signal intensity_index_valid : boolean := false;
    signal fire_duration_valid : boolean := false;
    signal cooldown_duration_valid : boolean := false;
    signal all_parameters_valid : boolean := false;
    
    -- Status Signals (standard VOLO infrastructure)
    signal status_register : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (others => '0');

begin

    -- =========================================================================
    -- Core Reset Handler Process
    -- =========================================================================
    -- Implements: RESET → READY (validation) → IDLE (user pickup point) → FAULT (validation failure)
    
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
                all_parameters_valid <= false;
                current_probe_config <= DEFAULT_PROBE_CONFIG;
                current_intensity_voltage <= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
                current_trigger_voltage <= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
            elsif clk_en = '1' then
                -- Input validation (always check)
                probe_selector_valid <= is_valid_probe_selector(probe_selector_index_in);
                intensity_index_valid <= is_valid_intensity_index(intensity_index_in);
                fire_duration_valid <= is_valid_duration(fire_duration_in);
                cooldown_duration_valid <= is_valid_duration(cooldown_duration_in);
                
                -- Combined validation
                all_parameters_valid <= probe_selector_valid and intensity_index_valid and 
                                       fire_duration_valid and cooldown_duration_valid;
                
                -- State machine transitions
                case current_state is
                    when work.volo_common_pkg.STATE_RESET =>
                        -- Check if all parameters are valid
                        if all_parameters_valid then
                            current_state <= work.volo_common_pkg.STATE_READY;
                        end if;
                        
                    when work.volo_common_pkg.STATE_READY =>
                        -- Load configuration when parameters are valid
                        if all_parameters_valid then
                            -- Get probe configuration from global table
                            current_probe_config <= get_probe_from_table_safe(DEFAULT_GLOBAL_PROBE_TABLE, 
                                                                              to_integer(unsigned(probe_selector_index_in)));
                            
                            -- Calculate intensity voltage from lookup table
                            current_intensity_voltage <= signed(get_voltage_for_percentage(DEFAULT_LINEAR_PERCENT_LUT, 
                                                                                          to_integer(unsigned(intensity_index_in))));
                            
                            -- Set trigger voltage from probe configuration
                            current_trigger_voltage <= signed(current_probe_config.probe_trigger_voltage);
                        end if;
                        
                        -- Transition to IDLE when enable is asserted (user pickup point)
                        if enable = '1' then
                            current_state <= work.volo_common_pkg.STATE_IDLE;
                        end if;
                        
                    when work.volo_common_pkg.STATE_IDLE =>
                        -- USER IMPLEMENTATION PICKUP POINT
                        -- Add your module-specific state machine logic here
                        -- This is where your custom behavior begins
                        -- Example:
                        -- if trig_in = '1' then
                        --     -- Your custom firing logic here
                        -- end if;
                        null;
                        
                    when work.volo_common_pkg.STATE_FAULT =>
                        -- FAULT state - only reset can exit
                        null;
                        
                    when others =>
                        -- Invalid state - go to FAULT
                        current_state <= work.volo_common_pkg.STATE_FAULT;
                end case;
                
                -- Check for validation failures (any state can go to FAULT)
                if not all_parameters_valid then
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
                if not all_parameters_valid then
                    status_register(work.volo_common_pkg.STATUS_ALARM_BIT) <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Output Assignment
    -- =========================================================================
    
    -- Output assignment using global constants
    -- User implementation should control when outputs are active
    trigger_out <= current_trigger_voltage when (current_state = work.volo_common_pkg.STATE_IDLE) else work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
    intensity_out <= current_intensity_voltage when (current_state = work.volo_common_pkg.STATE_IDLE) else work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
    
    -- Status register output
    probe_status_out <= status_register;

end architecture rtl;
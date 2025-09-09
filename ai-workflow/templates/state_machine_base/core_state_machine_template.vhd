-- =============================================================================
-- Core State Machine Template
-- =============================================================================
-- 
-- This template provides the standard core state machine implementation
-- that all VOLO modules must include. It implements the standard
-- RESET → READY → IDLE → FAULT state machine with parameter validation.
-- 
-- USAGE:
-- 1. Copy this template to your core entity
-- 2. Replace [MODULE_NAME] with your module name
-- 3. Add your specific validation functions
-- 4. Add your specific configuration loading logic
-- 5. The IDLE state serves as your user implementation pickup point
-- 
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import VOLO packages
use work.volo_common_pkg.ALL;
use work.[MODULE_NAME]_constants_pkg.ALL;

entity [MODULE_NAME]_core is
    port (
        -- Standard Control Signals
        clk : in std_logic;                    -- Units: signal (primary clock)
        reset_n : in std_logic;                -- Units: signal (active low reset)
        enable : in std_logic;                 -- Units: signal (module enable)
        clk_en : in std_logic;                 -- Units: signal (clock enable)
        
        -- [ADD YOUR SPECIFIC INPUTS HERE]
        -- Example:
        -- config_param_in : in std_logic_vector(CONFIG_WIDTH-1 downto 0);
        
        -- [ADD YOUR SPECIFIC OUTPUTS HERE]
        -- Example:
        -- output_signal_out : out signed(OUTPUT_WIDTH-1 downto 0);
        -- module_status_out : out std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0)
    );
end entity [MODULE_NAME]_core;

architecture rtl of [MODULE_NAME]_core is

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================
    
    -- Core State Machine Signals (using volo_common_pkg constants)
    signal current_state : std_logic_vector(1 downto 0) := work.volo_common_pkg.STATE_RESET;
    
    -- User provided signals begin
    -- [ADD YOUR MODULE-SPECIFIC SIGNALS HERE]
    -- Example:
    -- signal current_config : t_config_type;
    -- signal output_value : signed(OUTPUT_WIDTH-1 downto 0);
    
    -- User provided validation signals
    -- [ADD YOUR VALIDATION SIGNALS HERE]
    -- Example:
    -- signal config_valid : boolean := false;
    -- signal param_valid : boolean := false;
    
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
                -- [RESET YOUR MODULE-SPECIFIC SIGNALS HERE]
                -- Example:
                -- config_valid <= false;
                -- param_valid <= false;
                -- current_config <= get_default_config;
                -- output_value <= work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
            elsif clk_en = '1' then
                -- Input validation (always check)
                -- [ADD YOUR VALIDATION LOGIC HERE]
                -- Example:
                -- config_valid <= is_valid_config(config_param_in);
                -- param_valid <= is_valid_parameter(param_in);
                
                -- State machine transitions
                case current_state is
                    when work.volo_common_pkg.STATE_RESET =>
                        -- Check if all parameters are valid
                        -- [REPLACE WITH YOUR VALIDATION CONDITIONS]
                        if true then -- config_valid and param_valid then
                            current_state <= work.volo_common_pkg.STATE_READY;
                        end if;
                        
                    when work.volo_common_pkg.STATE_READY =>
                        -- Load configuration when parameters are valid
                        -- [ADD YOUR CONFIGURATION LOADING LOGIC HERE]
                        -- Example:
                        -- if config_valid then
                        --     current_config <= load_config_from_inputs;
                        --     output_value <= calculate_output_value;
                        -- end if;
                        
                        -- Transition to IDLE when enable is asserted (user pickup point)
                        if enable = '1' then
                            current_state <= work.volo_common_pkg.STATE_IDLE;
                        end if;
                        
                    when work.volo_common_pkg.STATE_IDLE =>
                        -- USER IMPLEMENTATION PICKUP POINT
                        -- Add your module-specific state machine logic here
                        -- This is where your custom behavior begins
                        -- Example:
                        -- if user_trigger = '1' then
                        --     -- Your custom logic here
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
                -- [REPLACE WITH YOUR VALIDATION FAILURE CONDITIONS]
                if false then -- not (config_valid and param_valid) then
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
                -- [REPLACE WITH YOUR VALIDATION FAILURE CONDITIONS]
                if false then -- not (config_valid and param_valid) then
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
    -- [REPLACE WITH YOUR OUTPUT ASSIGNMENTS]
    -- Example:
    -- output_signal_out <= output_value when (current_state = work.volo_common_pkg.STATE_IDLE) else work.volo_common_pkg.GLOBAL_VOLTAGE_ZERO;
    
    -- Status register output
    -- module_status_out <= status_register;

end architecture rtl;

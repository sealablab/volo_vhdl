-- Volo Base Module Core Entity
-- Implements main algorithmic/logic functionality with FSM
-- Follows enhanced rules system patterns for Verilog portability

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;

entity base_module_core is
    generic (
        -- Configuration parameters
        DATA_WIDTH        : natural := BASE_DEFAULT_DATA_WIDTH;
        COUNTER_WIDTH     : natural := BASE_DEFAULT_COUNTER_WIDTH;
        TIMEOUT_VALUE     : unsigned(15 downto 0) := BASE_DEFAULT_TIMEOUT_VALUE
    );
    port (
        -- Standard control signals (SIG-03: signal priority hierarchy)
        clk                     : in  std_logic;  -- Primary clock
        rst_n                   : in  std_logic;  -- Active low reset (highest priority)
        enable                  : in  std_logic;  -- Module enable (second priority)
        clk_en                  : in  std_logic;  -- Clock enable (third priority)
        
        -- Input interface
        data_in                 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        trigger_in              : in  std_logic;  -- Trigger input (rising edge)
        
        -- Configuration interface (cfg_ prefix for configuration signals)
        cfg_data_width_in       : in  natural;
        cfg_counter_width_in    : in  natural;
        cfg_timeout_value_in    : in  unsigned(15 downto 0);
        cfg_enable_feature_a_in : in  std_logic;
        cfg_enable_feature_b_in : in  std_logic;
        cfg_threshold_value_in  : in  std_logic_vector(15 downto 0);
        
        -- Output interface
        data_out                : out std_logic_vector(DATA_WIDTH-1 downto 0);
        result_out              : out std_logic_vector(15 downto 0);
        stat_status_out         : out std_logic_vector(7 downto 0)
    );
end entity base_module_core;

architecture behavioral of base_module_core is
    
    -- ============================================================================
    -- BASE MODULE SPECIFIC CONSTANTS
    -- ============================================================================
    -- Base module configuration parameter limits
    constant BASE_MAX_DATA_WIDTH        : natural := 32;
    constant BASE_MIN_DATA_WIDTH        : natural := 1;
    constant BASE_MAX_COUNTER_WIDTH     : natural := 16;
    constant BASE_MIN_COUNTER_WIDTH     : natural := 4;
    
    -- Base module default configuration values
    constant BASE_DEFAULT_DATA_WIDTH    : natural := 16;
    constant BASE_DEFAULT_COUNTER_WIDTH : natural := 8;
    constant BASE_DEFAULT_TIMEOUT_VALUE : unsigned(15 downto 0) := to_unsigned(1000, 16);
    
    -- State machine constants (std_logic_vector encoding for Verilog compatibility)
    constant IDLE_STATE      : std_logic_vector(2 downto 0) := "000";
    constant CONFIG_STATE    : std_logic_vector(2 downto 0) := "001";
    constant READY_STATE     : std_logic_vector(2 downto 0) := "010";
    constant PROCESSING_STATE: std_logic_vector(2 downto 0) := "011";
    constant COMPLETE_STATE  : std_logic_vector(2 downto 0) := "100";
    constant FAULT_STATE     : std_logic_vector(2 downto 0) := "101";
    
    -- Internal signals
    signal current_state         : std_logic_vector(2 downto 0);
    signal next_state            : std_logic_vector(2 downto 0);
    signal trigger_in_prev       : std_logic;
    signal trigger_edge_detected : std_logic;
    
    -- Configuration validation signals
    signal cfg_data_width_valid      : std_logic;
    signal cfg_counter_width_valid   : std_logic;
    signal cfg_timeout_value_valid   : std_logic;
    signal cfg_all_valid             : std_logic;
    
    -- Clamped configuration values
    signal cfg_data_width_clamped    : natural;
    signal cfg_counter_width_clamped : natural;
    signal cfg_timeout_value_clamped : unsigned(15 downto 0);
    
    -- Processing signals
    signal processing_counter        : unsigned(COUNTER_WIDTH-1 downto 0);
    signal timeout_counter           : unsigned(15 downto 0);
    signal result_register           : std_logic_vector(15 downto 0);
    signal data_register             : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Status signals
    signal status_reg                : std_logic_vector(7 downto 0);
    signal fault_detected            : std_logic;
    signal alarm_active              : std_logic;
    signal operation_busy            : std_logic;
    signal module_ready              : std_logic;
    signal feature_enabled           : std_logic;
    signal operation_active          : std_logic;
    signal data_valid                : std_logic;
    signal module_idle               : std_logic;
    
    -- Feature enable signals
    signal feature_a_enabled         : std_logic;
    signal feature_b_enabled         : std_logic;
    
begin
    
    -- SIG-03: Signal priority and truth table implementation
    -- Priority: reset > enable > clk_en > normal operation
    main_process: process(clk, rst_n)
    begin
        -- Highest priority: Reset
        if rst_n = '0' then
            current_state <= IDLE_STATE;
            processing_counter <= (others => '0');
            timeout_counter <= (others => '0');
            trigger_in_prev <= '0';
            result_register <= (others => '0');
            data_register <= (others => '0');
            status_reg <= (others => '0');
            data_out <= (others => '0');
            result_out <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Second priority: Clock enable
            if clk_en = '1' then
                -- Third priority: Module enable
                if enable = '1' then
                    -- Normal operation
                    current_state <= next_state;
                    trigger_in_prev <= trigger_in;
                    
                    -- Counter logic
                    if current_state = PROCESSING_STATE then
                        if processing_counter > 0 then
                            processing_counter <= processing_counter - 1;
                        end if;
                        if timeout_counter > 0 then
                            timeout_counter <= timeout_counter - 1;
                        end if;
                    end if;
                    
                    -- Data processing logic
                    case current_state is
                        when PROCESSING_STATE =>
                            -- Simple processing: accumulate input data
                            if feature_a_enabled = '1' then
                                result_register <= std_logic_vector(unsigned(result_register) + unsigned(data_in(15 downto 0)));
                            end if;
                            if feature_b_enabled = '1' then
                                data_register <= data_in;
                            end if;
                            
                        when COMPLETE_STATE =>
                            -- Output results
                            data_out <= data_register;
                            result_out <= result_register;
                            
                        when others =>
                            -- Maintain outputs
                            null;
                    end case;
                    
                else
                    -- Module disabled - maintain safe state
                    data_out <= (others => '0');
                    result_out <= (others => '0');
                end if;
            end if;
        end if;
    end process main_process;
    
    -- State machine logic
    state_machine: process(current_state, enable, trigger_edge_detected, processing_counter, 
                          timeout_counter, cfg_all_valid, feature_a_enabled, feature_b_enabled)
    begin
        next_state <= current_state; -- Default: stay in current state
        
        case current_state is
            when IDLE_STATE =>
                if enable = '1' and cfg_all_valid = '1' then
                    next_state <= CONFIG_STATE;
                elsif cfg_all_valid = '0' then
                    next_state <= FAULT_STATE;
                end if;
                
            when CONFIG_STATE =>
                if enable = '0' then
                    next_state <= IDLE_STATE;
                else
                    next_state <= READY_STATE;
                end if;
                
            when READY_STATE =>
                if enable = '0' then
                    next_state <= IDLE_STATE;
                elsif trigger_edge_detected = '1' then
                    next_state <= PROCESSING_STATE;
                elsif cfg_all_valid = '0' then
                    next_state <= FAULT_STATE;
                end if;
                
            when PROCESSING_STATE =>
                if processing_counter = 0 or timeout_counter = 0 then
                    next_state <= COMPLETE_STATE;
                elsif enable = '0' then
                    next_state <= IDLE_STATE;
                end if;
                
            when COMPLETE_STATE =>
                if enable = '0' then
                    next_state <= IDLE_STATE;
                else
                    next_state <= READY_STATE;
                end if;
                
            when FAULT_STATE =>
                -- Stay in fault state until reset
                next_state <= FAULT_STATE;
                
            when others =>
                next_state <= FAULT_STATE;
        end case;
    end process state_machine;
    
    -- Trigger edge detection
    trigger_edge_detected <= trigger_in and not trigger_in_prev;
    
    -- Configuration validation
    cfg_data_width_valid <= '1' when is_in_range(cfg_data_width_in, BASE_MIN_DATA_WIDTH, BASE_MAX_DATA_WIDTH) else '0';
    cfg_counter_width_valid <= '1' when is_in_range(cfg_counter_width_in, BASE_MIN_COUNTER_WIDTH, BASE_MAX_COUNTER_WIDTH) else '0';
    cfg_timeout_value_valid <= '1' when (cfg_timeout_value_in > 0 and cfg_timeout_value_in <= 65535) else '0';
    cfg_all_valid <= cfg_data_width_valid and cfg_counter_width_valid and cfg_timeout_value_valid;
    
    -- Configuration clamping
    cfg_data_width_clamped <= clamp_to_range(cfg_data_width_in, BASE_MIN_DATA_WIDTH, BASE_MAX_DATA_WIDTH);
    cfg_counter_width_clamped <= clamp_to_range(cfg_counter_width_in, BASE_MIN_COUNTER_WIDTH, BASE_MAX_COUNTER_WIDTH);
    cfg_timeout_value_clamped <= cfg_timeout_value_in when cfg_timeout_value_valid = '1' else TIMEOUT_VALUE;
    
    -- Feature enable signals
    feature_a_enabled <= cfg_enable_feature_a_in and enable;
    feature_b_enabled <= cfg_enable_feature_b_in and enable;
    
    -- Timer initialization
    timer_init: process(current_state, next_state, cfg_timeout_value_clamped)
    begin
        if current_state /= PROCESSING_STATE and next_state = PROCESSING_STATE then
            processing_counter <= to_unsigned(10, COUNTER_WIDTH); -- Fixed processing time
            timeout_counter <= cfg_timeout_value_clamped;
        end if;
    end process timer_init;
    
    -- Status register update process
    status_update: process(current_state, enable, cfg_all_valid, feature_a_enabled, feature_b_enabled)
        variable status: std_logic_vector(7 downto 0);
    begin
        status := (others => '0');
        
        -- FAULT bit
        if current_state = FAULT_STATE then
            status(STATUS_FAULT_BIT) := '1';
        end if;
        
        -- ALARM bit
        if cfg_all_valid = '0' then
            status(STATUS_ALARM_BIT) := '1';
        end if;
        
        -- BUSY bit
        if current_state = PROCESSING_STATE then
            status(STATUS_BUSY_BIT) := '1';
        end if;
        
        -- READY bit
        if current_state = READY_STATE then
            status(STATUS_READY_BIT) := '1';
        end if;
        
        -- ENABLED bit
        if enable = '1' then
            status(STATUS_ENABLED_BIT) := '1';
        end if;
        
        -- ACTIVE bit
        if current_state = PROCESSING_STATE or current_state = COMPLETE_STATE then
            status(STATUS_ACTIVE_BIT) := '1';
        end if;
        
        -- VALID bit
        if cfg_all_valid = '1' then
            status(STATUS_VALID_BIT) := '1';
        end if;
        
        -- IDLE bit
        if current_state = IDLE_STATE then
            status(STATUS_IDLE_BIT) := '1';
        end if;
        
        status_reg <= status;
    end process status_update;
    
    -- Output assignments
    stat_status_out <= status_reg;
    
end architecture behavioral;
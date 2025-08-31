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
        ALARM_THRESHOLD         : natural := 3  -- Number of clocks from bottom to trigger alarm
    );
    port (
        -- Standard control signals (SIG-03: signal priority hierarchy)
        clk                     : in  std_logic;  -- Primary clock
        rst_n                   : in  std_logic;  -- Active low reset (highest priority)
        enable                  : in  std_logic;  -- Module enable (second priority)
        clk_en                  : in  std_logic;  -- Clock enable (third priority)
        
        -- Input interface
        counter_in              : in  std_logic_vector(15 downto 0);  -- Counter to count down from
        
        -- Output interface
        stat_status_out         : out std_logic_vector(7 downto 0)
    );
end entity base_module_core;

architecture behavioral of base_module_core is
    
    -- ============================================================================
    -- BASE MODULE SPECIFIC CONSTANTS
    -- ============================================================================
    -- Base module counter validation limits
    constant BASE_COUNTER_MIN           : natural := 1;
    constant BASE_COUNTER_MAX           : natural := 65535;
    
    -- Base module alarm threshold validation limits
    constant BASE_ALARM_THRESHOLD_MIN   : natural := 1;
    constant BASE_ALARM_THRESHOLD_MAX   : natural := 10;
    
    -- State machine constants (std_logic_vector encoding for Verilog compatibility)
    constant RESET_STATE     : std_logic_vector(1 downto 0) := "00";
    constant READY_STATE     : std_logic_vector(1 downto 0) := "01";
    constant IDLE_STATE      : std_logic_vector(1 downto 0) := "10";
    constant FAULT_STATE     : std_logic_vector(1 downto 0) := "11";
    
    -- Internal signals
    signal current_state         : std_logic_vector(1 downto 0);
    
    -- Counter validation signals
    signal counter_valid             : std_logic;
    signal alarm_threshold_valid     : std_logic;
    
    -- Processing signals (simplified for base module)
    signal counter_register          : unsigned(15 downto 0) := (others => '0');
    
    -- Status signals
    signal status_reg                : std_logic_vector(7 downto 0);
    signal alarm_active              : std_logic;
    
begin
    
    -- SIG-03: Signal priority and truth table implementation
    -- Priority: reset > enable > clk_en > normal operation
    main_process: process(clk, rst_n)
    begin
        -- Highest priority: Reset
        if rst_n = '0' then
            current_state <= RESET_STATE;
            counter_register <= (others => '0');
            status_reg <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Second priority: Clock enable
            if clk_en = '1' then
                -- Third priority: Module enable
                if enable = '1' then
                    -- State machine logic (simplified - no next_state)
                    case current_state is
                        when RESET_STATE =>
                            if counter_valid = '1' and alarm_threshold_valid = '1' then
                                current_state <= READY_STATE;
                            elsif counter_valid = '0' or alarm_threshold_valid = '0' then
                                current_state <= FAULT_STATE;
                            end if;
                            
                        when READY_STATE =>
                            current_state <= IDLE_STATE; -- Automatic transition (inviolate)
                            counter_register <= unsigned(counter_in); -- Load counter when entering READY
                            
                        when IDLE_STATE =>
                            -- Count down from counter_in
                            if counter_register > 0 then
                                counter_register <= counter_register - 1;
                            end if;
                            -- Stay in IDLE_STATE for normal operation (user custom logic hook)
                            
                        when FAULT_STATE =>
                            -- Stay in fault state until reset
                            current_state <= FAULT_STATE;
                            
                        when others =>
                            current_state <= FAULT_STATE;
                    end case;
                    
                else
                    -- Module disabled - return to RESET
                    current_state <= RESET_STATE;
                end if;
            end if;
        end if;
    end process main_process;
    

    
    -- Counter validation
    counter_valid <= '1' when is_in_range(slv_to_natural(counter_in), BASE_COUNTER_MIN, BASE_COUNTER_MAX) else '0';
    
    -- Alarm threshold validation
    alarm_threshold_valid <= '1' when is_in_range(ALARM_THRESHOLD, BASE_ALARM_THRESHOLD_MIN, BASE_ALARM_THRESHOLD_MAX) else '0';
    
    -- Alarm logic: Set alarm when counter is ALARM_THRESHOLD clocks away from bottom
    alarm_active <= '1' when (current_state = IDLE_STATE and counter_register <= ALARM_THRESHOLD and counter_register > 0) else '0';
    
    -- Counter loading now handled in main clocked process
    
    -- Status register update process (4-state FSM)
    status_update: process(current_state, enable, counter_valid, alarm_threshold_valid, alarm_active)
        variable status: std_logic_vector(7 downto 0);
    begin
        status := (others => '0');
        
        -- FAULT bit
        if current_state = FAULT_STATE then
            status(STATUS_FAULT_BIT) := '1';
        end if;
        
        -- ALARM bit (counter near bottom OR invalid parameters)
        if alarm_active = '1' or counter_valid = '0' or alarm_threshold_valid = '0' then
            status(STATUS_ALARM_BIT) := '1';
        end if;
        
        -- READY bit
        if current_state = READY_STATE then
            status(STATUS_READY_BIT) := '1';
        end if;
        
        -- ENABLED bit
        if enable = '1' then
            status(STATUS_ENABLED_BIT) := '1';
        end if;
        
        -- ACTIVE bit (IDLE state is the active processing state)
        if current_state = IDLE_STATE then
            status(STATUS_ACTIVE_BIT) := '1';
        end if;
        
        -- VALID bit
        if counter_valid = '1' and alarm_threshold_valid = '1' then
            status(STATUS_VALID_BIT) := '1';
        end if;
        
        -- IDLE bit (RESET state is "armed/idle", IDLE state is "active/idle")
        if current_state = RESET_STATE or current_state = IDLE_STATE then
            status(STATUS_IDLE_BIT) := '1';
        end if;
        
        status_reg <= status;
    end process status_update;
    
    -- Output assignments
    stat_status_out <= status_reg;
    
end architecture behavioral;
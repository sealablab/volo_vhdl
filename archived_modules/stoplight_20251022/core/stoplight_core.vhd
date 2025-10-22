-- Stoplight Module Core Entity
-- Implements traffic light countdown timer with configurable delays
-- Follows VOLO base module patterns with custom stoplight functionality

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;
use WORK.stoplight_constants_pkg.ALL;

entity stoplight_core is
    port (
        -- Standard control signals (SIG-03: signal priority hierarchy)
        clk                     : in  std_logic;  -- Primary clock
        rst_n                   : in  std_logic;  -- Active low reset (highest priority)
        enable                  : in  std_logic;  -- Module enable (second priority)
        clk_en                  : in  std_logic;  -- Clock enable (third priority)
        
        -- User specified trigger
        trig_in                 : in  std_logic;  -- Trigger in, starts the timers
        
        -- Configuration parameters
        cfg_red_delay           : in  std_logic_vector(15 downto 0);  -- Red duration (clks)
        cfg_yellow_delay        : in  std_logic_vector(15 downto 0);  -- Yellow duration (clks)
        cfg_green_delay         : in  std_logic_vector(15 downto 0);  -- Green duration (clks)
        
        -- Output interface
        stat_status_out         : out std_logic_vector(7 downto 0)  -- 8-bit status register
    );
end entity stoplight_core;

architecture behavioral of stoplight_core is
    
    -- ============================================================================
    -- INTERNAL SIGNALS
    -- ============================================================================
    -- State machine
    signal current_state        : std_logic_vector(2 downto 0) := RESET_STATE;
    
    -- Configuration validation signals
    signal red_delay_valid      : std_logic := '0';
    signal yellow_delay_valid   : std_logic := '0';
    signal green_delay_valid    : std_logic := '0';
    signal config_valid         : std_logic := '0';
    
    -- Timer signals
    signal timer_register       : unsigned(15 downto 0) := (others => '0');
    signal timer_done           : std_logic := '0';
    
    -- Status register
    signal status_reg           : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Internal configuration registers
    signal red_delay_reg        : unsigned(15 downto 0) := (others => '0');
    signal yellow_delay_reg     : unsigned(15 downto 0) := (others => '0');
    signal green_delay_reg      : unsigned(15 downto 0) := (others => '0');
    
begin
    
    -- ============================================================================
    -- CONFIGURATION VALIDATION
    -- ============================================================================
    red_delay_valid <= '1' when is_valid_red_delay(to_integer(unsigned(cfg_red_delay))) else '0';
    yellow_delay_valid <= '1' when is_valid_yellow_delay(to_integer(unsigned(cfg_yellow_delay))) else '0';
    green_delay_valid <= '1' when is_valid_green_delay(to_integer(unsigned(cfg_green_delay))) else '0';
    config_valid <= red_delay_valid and yellow_delay_valid and green_delay_valid;
    
    -- ============================================================================
    -- MAIN STATE MACHINE PROCESS
    -- ============================================================================
    -- SIG-03: Signal priority and truth table implementation
    -- Priority: reset > enable > clk_en > normal operation
    main_process: process(clk, rst_n)
    begin
        -- Highest priority: Reset
        if rst_n = '0' then
            current_state <= RESET_STATE;
            timer_register <= (others => '0');
            status_reg <= (others => '0');
            red_delay_reg <= (others => '0');
            yellow_delay_reg <= (others => '0');
            green_delay_reg <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Second priority: Clock enable
            if clk_en = '1' then
                -- Third priority: Module enable
                if enable = '1' then
                    -- State machine logic
                    case current_state is
                        when RESET_STATE =>
                            -- Capture configuration values during reset
                            red_delay_reg <= unsigned(cfg_red_delay);
                            yellow_delay_reg <= unsigned(cfg_yellow_delay);
                            green_delay_reg <= unsigned(cfg_green_delay);
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_IDLE_BIT) <= '1';
                            status_reg(STATUS_VALID_BIT) <= config_valid;
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                            -- Validate configuration and transition
                            if config_valid = '1' then
                                current_state <= READY_STATE;
                            else
                                current_state <= FAULT_STATE;
                            end if;
                            
                        when READY_STATE =>
                            -- Automatic transition to IDLE (VOLO standard)
                            current_state <= IDLE_STATE;
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_IDLE_BIT) <= '1';
                            status_reg(STATUS_VALID_BIT) <= '1';
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                        when IDLE_STATE =>
                            -- Wait for trigger to start traffic light cycle
                            if trig_in = '1' then
                                current_state <= RED_STATE;
                                timer_register <= red_delay_reg;
                            end if;
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_IDLE_BIT) <= '1';
                            status_reg(STATUS_VALID_BIT) <= '1';
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                        when RED_STATE =>
                            -- Red light countdown
                            if timer_register > 0 then
                                timer_register <= timer_register - 1;
                            else
                                current_state <= YELLOW_STATE;
                                timer_register <= yellow_delay_reg;
                            end if;
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_RED_BIT) <= '1';
                            status_reg(STATUS_VALID_BIT) <= '1';
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                        when YELLOW_STATE =>
                            -- Yellow light countdown
                            if timer_register > 0 then
                                timer_register <= timer_register - 1;
                            else
                                current_state <= GREEN_STATE;
                                timer_register <= green_delay_reg;
                            end if;
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_YELLOW_BIT) <= '1';
                            status_reg(STATUS_ALARM_BIT) <= '1';  -- Yellow is alarm state
                            status_reg(STATUS_VALID_BIT) <= '1';
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                        when GREEN_STATE =>
                            -- Green light countdown
                            if timer_register > 0 then
                                timer_register <= timer_register - 1;
                            else
                                current_state <= IDLE_STATE;
                                timer_register <= (others => '0');
                            end if;
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_GREEN_BIT) <= '1';
                            status_reg(STATUS_VALID_BIT) <= '1';
                            status_reg(STATUS_ENABLED_BIT) <= enable;
                            
                        when FAULT_STATE =>
                            -- Stay in fault state until reset
                            current_state <= FAULT_STATE;
                            timer_register <= (others => '0');
                            
                            -- Update status register
                            status_reg <= (others => '0');
                            status_reg(STATUS_FAULT_BIT) <= '1';
                            
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
    
    -- ============================================================================
    -- OUTPUT ASSIGNMENTS
    -- ============================================================================
    stat_status_out <= status_reg;
    
end architecture behavioral;

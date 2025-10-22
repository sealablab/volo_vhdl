-- =============================================================================
-- File: stoplight_core.vhd
-- Entity: stoplight_core
-- Description: Core implementation of the Stoplight traffic light controller
-- Author: AI Generated
-- Date: Generated from stoplight-interface-requirements-r1.md
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import constants package
library work;
use work.stoplight_constants_pkg.all;

entity stoplight_core is
    port (
        -- Clock and Reset
        clk         : in  std_logic;                    -- System clock
        rst_n       : in  std_logic;                    -- Active low reset
        
        -- Control Signals
        enable      : in  std_logic;                    -- Module enable
        clk_en      : in  std_logic;                    -- Clock enable
        
        -- User Input
        trig_in     : in  std_logic;                    -- Trigger in
        
        -- Configuration Parameters
        cfg_red_delay    : in  std_logic_vector(15 downto 0);  -- Red duration (clks)
        cfg_yellow_delay : in  std_logic_vector(15 downto 0);  -- Yellow duration (clks)
        cfg_green_delay  : in  std_logic_vector(15 downto 0);  -- Green duration (clks)
        
        -- Output Signals
        stat_status_out : out std_logic_vector(7 downto 0)  -- 8-bit status register (bits)
    );
end entity stoplight_core;

-- =============================================================================
-- Architecture
-- =============================================================================

architecture rtl of stoplight_core is

    -- Internal signals
    signal current_state : std_logic_vector(2 downto 0) := RESET_STATE;
    signal next_state    : std_logic_vector(2 downto 0) := RESET_STATE;
    signal countdown     : std_logic_vector(15 downto 0) := (others => '0');
    signal status_reg    : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Configuration validation signals
    signal config_valid  : std_logic := '0';
    
    -- State transition signals
    signal state_changed : std_logic := '0';

begin

    -- =========================================================================
    -- Configuration Validation Process
    -- =========================================================================
    
    config_validation : process(cfg_red_delay, cfg_yellow_delay, cfg_green_delay)
    begin
        config_valid <= '0';
        if are_all_delays_valid(cfg_red_delay, cfg_yellow_delay, cfg_green_delay) then
            config_valid <= '1';
        end if;
    end process;
    
    -- =========================================================================
    -- State Machine Process
    -- =========================================================================
    
    state_machine : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                -- Reset state
                current_state <= RESET_STATE;
                countdown <= (others => '0');
                status_reg <= (others => '0');
            elsif enable = '1' and clk_en = '1' then
                -- Update current state
                current_state <= next_state;
                
                -- Handle state transitions
                case current_state is
                    when RESET_STATE =>
                        if config_valid = '1' then
                            next_state <= RED_STATE;
                            countdown <= cfg_red_delay;
                        else
                            next_state <= FAULT_STATE;
                            countdown <= (others => '0');
                        end if;
                        
                    when RED_STATE =>
                        if countdown = std_logic_vector(to_unsigned(0, 16)) then
                            next_state <= YELLOW_STATE;
                            countdown <= cfg_yellow_delay;
                        else
                            countdown <= std_logic_vector(unsigned(countdown) - 1);
                        end if;
                        
                    when YELLOW_STATE =>
                        if countdown = std_logic_vector(to_unsigned(0, 16)) then
                            next_state <= GREEN_STATE;
                            countdown <= cfg_green_delay;
                        else
                            countdown <= std_logic_vector(unsigned(countdown) - 1);
                        end if;
                        
                    when GREEN_STATE =>
                        if countdown = std_logic_vector(to_unsigned(0, 16)) then
                            next_state <= RED_STATE;
                            countdown <= cfg_red_delay;
                        else
                            countdown <= std_logic_vector(unsigned(countdown) - 1);
                        end if;
                        
                    when FAULT_STATE =>
                        next_state <= FAULT_STATE;
                        countdown <= (others => '0');
                        
                    when others =>
                        next_state <= FAULT_STATE;
                        countdown <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- =========================================================================
    -- Status Register Update Process
    -- =========================================================================
    
    status_update : process(current_state, enable, config_valid)
    begin
        -- Initialize status register
        status_reg <= (others => '0');
        
        -- Set status bits based on current state and conditions
        case current_state is
            when RESET_STATE =>
                status_reg(STAT_IDLE_BIT) <= '1';
                
            when RED_STATE =>
                status_reg(STAT_RED_BIT) <= '1';
                status_reg(STAT_ENABLED_BIT) <= enable;
                status_reg(STAT_VALID_BIT) <= config_valid;
                
            when YELLOW_STATE =>
                status_reg(STAT_YELLOW_BIT) <= '1';
                status_reg(STAT_ALARM_BIT) <= '1';  -- Yellow state triggers alarm
                status_reg(STAT_ENABLED_BIT) <= enable;
                status_reg(STAT_VALID_BIT) <= config_valid;
                
            when GREEN_STATE =>
                status_reg(STAT_GREEN_BIT) <= '1';
                status_reg(STAT_ENABLED_BIT) <= enable;
                status_reg(STAT_VALID_BIT) <= config_valid;
                
            when FAULT_STATE =>
                status_reg(STAT_FAULT_BIT) <= '1';
                
            when others =>
                status_reg(STAT_FAULT_BIT) <= '1';
        end case;
    end process;
    
    -- =========================================================================
    -- Output Assignment
    -- =========================================================================
    
    stat_status_out <= status_reg;

end architecture rtl;
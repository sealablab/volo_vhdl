--------------------------------------------------------------------------------
-- Module: probe_config_example
-- Purpose: Example module demonstrating Global Probe Table usage
-- Author: johnnyc
-- Date: 2025-01-27
-- 
-- This module shows practical examples of how to use the Global_Probe_Table_pkg
-- for accessing probe configurations in real RTL code.
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

-- Import probe configuration packages (enhanced versions)
use work.Probe_Config_pkg_en.all;
use work.Global_Probe_Table_pkg_en.all;

entity probe_config_example is
    generic (
        CLK_FREQ_MHZ : natural := 100  -- Clock frequency in MHz
    );
    port (
        clk         : in  std_logic;  -- System clock
        rst_n       : in  std_logic;  -- Active-low reset
        
        -- Probe selection interface
        ctrl_probe_select : in  std_logic_vector(7 downto 0);  -- Probe ID selection (0-255)
        ctrl_probe_enable : in  std_logic;                     -- Enable probe operation
        
        -- Probe configuration outputs (with unit hints)
        cfg_trigger_voltage : out std_logic_vector(15 downto 0);  -- Trigger voltage threshold in V
        cfg_duration_min    : out std_logic_vector(15 downto 0);  -- Minimum pulse duration in us
        cfg_duration_max    : out std_logic_vector(15 downto 0);  -- Maximum pulse duration in us
        cfg_intensity_min   : out std_logic_vector(15 downto 0);  -- Minimum intensity voltage in V
        cfg_intensity_max   : out std_logic_vector(15 downto 0);  -- Maximum intensity voltage in V
        cfg_cooldown_min    : out std_logic_vector(15 downto 0);  -- Minimum cooldown period in us
        cfg_cooldown_max    : out std_logic_vector(15 downto 0);  -- Maximum cooldown period in us
        
        -- Status outputs
        stat_probe_valid    : out std_logic;  -- Selected probe is valid
        stat_probe_name     : out std_logic_vector(39 downto 0);  -- Probe name (5 chars * 8 bits)
        stat_config_error   : out std_logic   -- Configuration error detected
    );
end entity probe_config_example;

architecture behavioral of probe_config_example is
    
    -- Internal signals for probe configuration
    signal current_probe_config : t_probe_config;
    signal current_probe_config_digital : t_probe_config_digital;
    
    -- Probe ID from input
    signal probe_id : natural;
    
    -- Configuration validation
    signal config_valid : boolean;
    
begin
    
    -- Convert input probe selection to natural
    probe_id <= to_integer(unsigned(ctrl_probe_select));
    
    -- =============================================================================
    -- PROBE CONFIGURATION ACCESS
    -- =============================================================================
    
    -- Example 1: Direct access to probe configuration
    -- Use this when you're confident the probe ID is valid
    current_probe_config <= get_probe_config(probe_id) when is_valid_probe_id(probe_id) else
                           get_probe_config_safe(probe_id);
    
    -- Example 2: Safe access with bounds checking
    -- Always returns a valid configuration (default if probe ID invalid)
    current_probe_config_digital <= get_probe_config_digital_safe(probe_id);
    
    -- =============================================================================
    -- CONFIGURATION VALIDATION
    -- =============================================================================
    
    -- Validate the current probe configuration
    config_valid <= is_valid_probe_config(current_probe_config);
    
    -- =============================================================================
    -- OUTPUT ASSIGNMENT
    -- =============================================================================
    
    -- Convert probe configuration to output signals
    cfg_trigger_voltage <= current_probe_config_digital.probe_trigger_voltage;
    cfg_duration_min    <= std_logic_vector(to_unsigned(current_probe_config_digital.probe_duration_min, 16));
    cfg_duration_max    <= std_logic_vector(to_unsigned(current_probe_config_digital.probe_duration_max, 16));
    cfg_intensity_min   <= current_probe_config_digital.probe_intensity_min;
    cfg_intensity_max   <= current_probe_config_digital.probe_intensity_max;
    cfg_cooldown_min    <= std_logic_vector(to_unsigned(current_probe_config_digital.probe_cooldown_min, 16));
    cfg_cooldown_max    <= std_logic_vector(to_unsigned(current_probe_config_digital.probe_cooldown_max, 16));
    
    -- Status outputs
    stat_probe_valid  <= '1' when is_valid_probe_id(probe_id) and config_valid else '0';
    stat_config_error <= '1' when not config_valid else '0';
    
    -- Convert probe name to output (5 characters, 8 bits each)
    process(clk)
        variable probe_name : string(1 to 5);
        variable name_vector : std_logic_vector(39 downto 0);
        variable char_idx : natural;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                stat_probe_name <= (others => '0');
            else
                -- Get probe name and convert to vector
                probe_name := get_probe_name(probe_id);
                name_vector := (others => '0');
                
                -- Convert each character to ASCII and pack into vector
                for char_idx in 1 to 5 loop
                    if char_idx <= probe_name'length then
                        name_vector((char_idx*8-1) downto ((char_idx-1)*8)) := 
                            std_logic_vector(to_unsigned(character'pos(probe_name(char_idx)), 8));
                    end if;
                end loop;
                
                stat_probe_name <= name_vector;
            end if;
        end if;
    end process;
    
    -- =============================================================================
    -- CONFIGURATION MONITORING (Example of advanced usage)
    -- =============================================================================
    
    -- Example 3: Runtime configuration validation
    -- This process monitors configuration changes and validates them
    config_monitor : process(clk)
        variable prev_probe_id : natural;
        variable config_change_detected : boolean;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                prev_probe_id := 0;
                config_change_detected := false;
            else
                -- Detect probe configuration changes
                if probe_id /= prev_probe_id then
                    config_change_detected := true;
                    prev_probe_id := probe_id;
                    
                    -- Log configuration change (in real implementation, this could
                    -- trigger status updates, logging, or other monitoring functions)
                    if is_valid_probe_id(probe_id) then
                        -- Valid probe selected - could log this event
                        null;  -- Placeholder for logging logic
                    else
                        -- Invalid probe selected - could log error
                        null;  -- Placeholder for error logging
                    end if;
                end if;
                
                -- Reset change detection flag
                if config_change_detected then
                    config_change_detected := false;
                end if;
            end if;
        end if;
    end process;
    
    -- =============================================================================
    -- SAFETY FEATURES (Example of defensive programming)
    -- =============================================================================
    
    -- Example 4: Safety checks for critical parameters
    -- This could be expanded to include more sophisticated safety logic
    safety_monitor : process(clk)
        variable safety_check_passed : boolean;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                safety_check_passed := true;
            else
                -- Perform safety checks on current configuration
                if is_valid_probe_id(probe_id) then
                    -- Check if probe configuration meets safety requirements
                    safety_check_passed := 
                        (current_probe_config.probe_trigger_voltage >= -5.0) and
                        (current_probe_config.probe_trigger_voltage <= 5.0) and
                        (current_probe_config.probe_intensity_min >= -5.0) and
                        (current_probe_config.probe_intensity_max <= 5.0);
                else
                    safety_check_passed := false;
                end if;
                
                -- If safety check fails, could trigger additional safety measures
                if not safety_check_passed then
                    -- Placeholder for safety response logic
                    null;
                end if;
            end if;
        end if;
    end process;

end architecture behavioral;

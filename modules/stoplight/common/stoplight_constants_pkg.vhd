-- Stoplight Module Constants Package
-- Defines all constants for the stoplight module including status register bits,
-- configuration limits, validation ranges, and units constants

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package stoplight_constants_pkg is

    -- ============================================================================
    -- STATUS REGISTER BIT DEFINITIONS
    -- ============================================================================
    -- 8-bit status register bit positions (following VOLO standard)
    constant STATUS_FAULT_BIT     : natural := 7;  -- FAULT active (module in error state)
    constant STATUS_ALARM_BIT     : natural := 6;  -- ALARM
    constant STATUS_ENABLED_BIT   : natural := 5;  -- Enabled
    constant STATUS_VALID_BIT     : natural := 4;  -- VALID (configuration parameters are valid)
    constant STATUS_RED_BIT       : natural := 3;  -- RED-Stat
    constant STATUS_YELLOW_BIT    : natural := 2;  -- YELLOW-Stat
    constant STATUS_GREEN_BIT     : natural := 1;  -- GREEN-Stat
    constant STATUS_IDLE_BIT      : natural := 0;  -- IDLE

    -- Status register bit masks
    constant STATUS_FAULT_MASK    : std_logic_vector(7 downto 0) := "10000000";
    constant STATUS_ALARM_MASK    : std_logic_vector(7 downto 0) := "01000000";
    constant STATUS_ENABLED_MASK  : std_logic_vector(7 downto 0) := "00100000";
    constant STATUS_VALID_MASK    : std_logic_vector(7 downto 0) := "00010000";
    constant STATUS_RED_MASK      : std_logic_vector(7 downto 0) := "00001000";
    constant STATUS_YELLOW_MASK   : std_logic_vector(7 downto 0) := "00000100";
    constant STATUS_GREEN_MASK    : std_logic_vector(7 downto 0) := "00000010";
    constant STATUS_IDLE_MASK     : std_logic_vector(7 downto 0) := "00000001";

    -- ============================================================================
    -- CONFIGURATION LIMITS AND VALIDATION RANGES
    -- ============================================================================
    -- Red delay configuration limits
    constant RED_DELAY_MIN        : natural := 1;
    constant RED_DELAY_MAX        : natural := 40000;
    
    -- Yellow delay configuration limits
    constant YELLOW_DELAY_MIN     : natural := 1;
    constant YELLOW_DELAY_MAX     : natural := 20000;
    
    -- Green delay configuration limits
    constant GREEN_DELAY_MIN      : natural := 30000;
    constant GREEN_DELAY_MAX      : natural := 65000;
    
    -- General counter limits
    constant COUNTER_MIN          : natural := 1;
    constant COUNTER_MAX          : natural := 65535;

    -- ============================================================================
    -- STATE MACHINE CONSTANTS
    -- ============================================================================
    -- Standard VOLO Base Module States (inherited)
    constant RESET_STATE          : std_logic_vector(2 downto 0) := "000";
    constant READY_STATE          : std_logic_vector(2 downto 0) := "001";
    constant IDLE_STATE           : std_logic_vector(2 downto 0) := "010";
    constant FAULT_STATE          : std_logic_vector(2 downto 0) := "011";
    
    -- Stoplight-specific states (extending base module)
    constant RED_STATE            : std_logic_vector(2 downto 0) := "100";
    constant YELLOW_STATE         : std_logic_vector(2 downto 0) := "101";
    constant GREEN_STATE          : std_logic_vector(2 downto 0) := "110";

    -- ============================================================================
    -- UNITS CONSTANTS
    -- ============================================================================
    -- Units for configuration parameters
    constant UNITS_CLOCKS         : string := "clks";
    constant UNITS_SECONDS        : string := "sec";
    constant UNITS_MILLISECONDS   : string := "ms";
    
    -- ============================================================================
    -- HELPER FUNCTIONS
    -- ============================================================================
    -- Function to check if a delay value is within valid range
    function is_valid_red_delay(delay : natural) return boolean;
    function is_valid_yellow_delay(delay : natural) return boolean;
    function is_valid_green_delay(delay : natural) return boolean;
    
    -- Function to check if configuration is valid
    function is_config_valid(red_delay, yellow_delay, green_delay : natural) return boolean;

end package stoplight_constants_pkg;

package body stoplight_constants_pkg is

    -- Check if red delay is within valid range
    function is_valid_red_delay(delay : natural) return boolean is
    begin
        return delay >= RED_DELAY_MIN and delay <= RED_DELAY_MAX;
    end function;

    -- Check if yellow delay is within valid range
    function is_valid_yellow_delay(delay : natural) return boolean is
    begin
        return delay >= YELLOW_DELAY_MIN and delay <= YELLOW_DELAY_MAX;
    end function;

    -- Check if green delay is within valid range
    function is_valid_green_delay(delay : natural) return boolean is
    begin
        return delay >= GREEN_DELAY_MIN and delay <= GREEN_DELAY_MAX;
    end function;

    -- Check if entire configuration is valid
    function is_config_valid(red_delay, yellow_delay, green_delay : natural) return boolean is
    begin
        return is_valid_red_delay(red_delay) and 
               is_valid_yellow_delay(yellow_delay) and 
               is_valid_green_delay(green_delay);
    end function;

end package body stoplight_constants_pkg;

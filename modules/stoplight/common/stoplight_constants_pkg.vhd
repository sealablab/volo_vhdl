-- Stoplight Module Constants Package
-- Defines all constants for the stoplight module including status register bits,
-- configuration limits, validation ranges, and units constants

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package stoplight_constants_pkg is

    -- ============================================================================
    -- STOPLIGHT-SPECIFIC CONSTANTS
    -- ============================================================================
    -- Note: Standard status register bits are inherited from volo_common_pkg
    -- This package only defines stoplight-specific constants
    
    -- Custom status register bits for stoplight states
    constant STATUS_RED_BIT       : natural := 3;  -- RED-Stat (custom)
    constant STATUS_YELLOW_BIT    : natural := 2;  -- YELLOW-Stat (custom) 
    constant STATUS_GREEN_BIT     : natural := 1;  -- GREEN-Stat (custom)

    -- Status register bit masks (custom bits only)
    constant STATUS_RED_MASK      : std_logic_vector(7 downto 0) := "00001000";
    constant STATUS_YELLOW_MASK   : std_logic_vector(7 downto 0) := "00000100";
    constant STATUS_GREEN_MASK    : std_logic_vector(7 downto 0) := "00000010";
    -- Standard bit masks are inherited from volo_common_pkg

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

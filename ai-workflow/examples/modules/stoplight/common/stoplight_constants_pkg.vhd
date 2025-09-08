-- =============================================================================
-- File: stoplight_constants_pkg.vhd
-- Package: Stoplight Constants Package
-- Description: Constants and definitions for the Stoplight module
-- Author: AI Generated
-- Date: Generated from stoplight-interface-requirements-r1.md
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package stoplight_constants_pkg is

    -- =========================================================================
    -- State Machine Constants
    -- =========================================================================
    
    -- State definitions (3-bit encoding for 5 states)
    constant RESET_STATE  : std_logic_vector(2 downto 0) := "000";
    constant RED_STATE    : std_logic_vector(2 downto 0) := "001";
    constant YELLOW_STATE : std_logic_vector(2 downto 0) := "010";
    constant GREEN_STATE  : std_logic_vector(2 downto 0) := "011";
    constant FAULT_STATE  : std_logic_vector(2 downto 0) := "100";
    
    -- =========================================================================
    -- Status Register Bit Definitions
    -- =========================================================================
    
    -- Status register bit positions (bits)
    constant STAT_FAULT_BIT   : integer := 7;  -- FAULT active (module in error state)
    constant STAT_ALARM_BIT   : integer := 6;   -- ALARM
    constant STAT_ENABLED_BIT : integer := 5;   -- Enabled
    constant STAT_VALID_BIT   : integer := 4;   -- VALID (configuration parameters are valid)
    constant STAT_RED_BIT     : integer := 3;   -- RED-Stat
    constant STAT_YELLOW_BIT  : integer := 2;   -- YELLOW-Stat
    constant STAT_GREEN_BIT   : integer := 1;   -- GREEN-Stat
    constant STAT_IDLE_BIT    : integer := 0;   -- IDLE
    
    -- Status register bit masks
    constant STAT_FAULT_MASK   : std_logic_vector(7 downto 0) := "10000000";
    constant STAT_ALARM_MASK   : std_logic_vector(7 downto 0) := "01000000";
    constant STAT_ENABLED_MASK : std_logic_vector(7 downto 0) := "00100000";
    constant STAT_VALID_MASK  : std_logic_vector(7 downto 0) := "00010000";
    constant STAT_RED_MASK     : std_logic_vector(7 downto 0) := "00001000";
    constant STAT_YELLOW_MASK  : std_logic_vector(7 downto 0) := "00000100";
    constant STAT_GREEN_MASK   : std_logic_vector(7 downto 0) := "00000010";
    constant STAT_IDLE_MASK    : std_logic_vector(7 downto 0) := "00000001";
    
    -- =========================================================================
    -- Configuration Parameter Limits
    -- =========================================================================
    
    -- Red delay limits (clks)
    constant RED_DELAY_MIN : integer := 1;
    constant RED_DELAY_MAX : integer := 40000;
    
    -- Yellow delay limits (clks)
    constant YELLOW_DELAY_MIN : integer := 1;
    constant YELLOW_DELAY_MAX : integer := 20000;
    
    -- Green delay limits (clks)
    constant GREEN_DELAY_MIN : integer := 30000;
    constant GREEN_DELAY_MAX : integer := 65000;
    
    -- =========================================================================
    -- Units Constants
    -- =========================================================================
    
    -- Physical units
    constant UNIT_CLKS : string := "clks";  -- Clock cycles
    constant UNIT_BITS : string := "bits";  -- Status register bits
    
    -- =========================================================================
    -- Helper Functions
    -- =========================================================================
    
    -- Function to check if red delay is valid
    function is_red_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean;
    
    -- Function to check if yellow delay is valid
    function is_yellow_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean;
    
    -- Function to check if green delay is valid
    function is_green_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean;
    
    -- Function to check if all delays are valid
    function are_all_delays_valid(red_delay, yellow_delay, green_delay : std_logic_vector(15 downto 0)) return boolean;

end package stoplight_constants_pkg;

-- =============================================================================
-- Package Body
-- =============================================================================

package body stoplight_constants_pkg is

    -- Function to check if red delay is valid
    function is_red_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean is
    begin
        return (to_integer(unsigned(delay)) >= RED_DELAY_MIN and 
                to_integer(unsigned(delay)) <= RED_DELAY_MAX);
    end function;
    
    -- Function to check if yellow delay is valid
    function is_yellow_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean is
    begin
        return (to_integer(unsigned(delay)) >= YELLOW_DELAY_MIN and 
                to_integer(unsigned(delay)) <= YELLOW_DELAY_MAX);
    end function;
    
    -- Function to check if green delay is valid
    function is_green_delay_valid(delay : std_logic_vector(15 downto 0)) return boolean is
    begin
        return (to_integer(unsigned(delay)) >= GREEN_DELAY_MIN and 
                to_integer(unsigned(delay)) <= GREEN_DELAY_MAX);
    end function;
    
    -- Function to check if all delays are valid
    function are_all_delays_valid(red_delay, yellow_delay, green_delay : std_logic_vector(15 downto 0)) return boolean is
    begin
        return (is_red_delay_valid(red_delay) and 
                is_yellow_delay_valid(yellow_delay) and 
                is_green_delay_valid(green_delay));
    end function;

end package body stoplight_constants_pkg;
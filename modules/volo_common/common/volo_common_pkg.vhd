-- Volo Common Package
-- Minimal shared utilities and constants for all Volo VHDL modules
-- Contains ONLY truly universal items that apply across all modules

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package volo_common_pkg is
    
    -- ============================================================================
    -- STATUS REGISTER BIT POSITIONS
    -- ============================================================================
    -- Standard status register bit positions used consistently across modules
    constant STATUS_FAULT_BIT      : natural := 7;
    constant STATUS_ALARM_BIT      : natural := 6;
    constant STATUS_BUSY_BIT       : natural := 5;
    constant STATUS_READY_BIT      : natural := 4;
    constant STATUS_ENABLED_BIT    : natural := 3;
    constant STATUS_ACTIVE_BIT     : natural := 2;
    constant STATUS_VALID_BIT      : natural := 1;
    constant STATUS_IDLE_BIT       : natural := 0;
    
    -- ============================================================================
    -- STANDARD STATE MACHINE STATES
    -- ============================================================================
    -- Standard state machine states for all VOLO modules (2-bit encoding for Verilog compatibility)
    constant STATE_RESET : std_logic_vector(1 downto 0) := "00";  -- Units: state (reset/initialization)
    constant STATE_READY : std_logic_vector(1 downto 0) := "01";  -- Units: state (parameters validated, ready)
    constant STATE_IDLE  : std_logic_vector(1 downto 0) := "10";  -- Units: state (user implementation pickup point)
    constant STATE_FAULT : std_logic_vector(1 downto 0) := "11";  -- Units: state (validation failure)
    
    -- ============================================================================
    -- GLOBAL OUTPUT CONSTANTS
    -- ============================================================================
    -- Global output constants for consistent behavior across all modules
    constant GLOBAL_VOLTAGE_ZERO : signed(15 downto 0) := x"0000";  -- Units: volts (0V output)
    constant GLOBAL_SAFE_OUTPUT : signed(15 downto 0) := x"0000";   -- Units: volts (safe state output)
    

    
    -- ============================================================================
    -- UNIVERSAL UTILITY FUNCTIONS
    -- ============================================================================
    
    -- Clamp a natural value to a specified range
    function clamp_to_range(
        value : natural;
        min_val : natural;
        max_val : natural
    ) return natural;
    
    -- Check if a natural value is within a specified range
    function is_in_range(
        value : natural;
        min_val : natural;
        max_val : natural
    ) return boolean;
    
    -- Convert natural to std_logic_vector with specified width
    function natural_to_slv(value : natural; width : natural) return std_logic_vector;
    
    -- Convert std_logic_vector to natural (with bounds checking)
    function slv_to_natural(value : std_logic_vector) return natural;
    

    
    -- ============================================================================
    -- STATUS REGISTER UTILITIES
    -- ============================================================================
    
    -- Create status register from individual status bits
    function create_status_reg(
        fault : std_logic;
        alarm : std_logic;
        busy : std_logic;
        ready : std_logic;
        enabled : std_logic;
        active : std_logic;
        valid : std_logic;
        idle : std_logic
    ) return std_logic_vector;
    
end package volo_common_pkg;

package body volo_common_pkg is
    
    -- ============================================================================
    -- UNIVERSAL UTILITY FUNCTIONS
    -- ============================================================================
    
    function clamp_to_range(
        value : natural;
        min_val : natural;
        max_val : natural
    ) return natural is
    begin
        if value < min_val then
            return min_val;
        elsif value > max_val then
            return max_val;
        else
            return value;
        end if;
    end function clamp_to_range;
    
    function is_in_range(
        value : natural;
        min_val : natural;
        max_val : natural
    ) return boolean is
    begin
        return (value >= min_val and value <= max_val);
    end function is_in_range;
    
    function natural_to_slv(value : natural; width : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(value, width));
    end function natural_to_slv;
    
    function slv_to_natural(value : std_logic_vector) return natural is
    begin
        return to_integer(unsigned(value));
    end function slv_to_natural;
    
    -- ============================================================================
    -- STATUS REGISTER UTILITIES
    -- ============================================================================
    
    function create_status_reg(
        fault : std_logic;
        alarm : std_logic;
        busy : std_logic;
        ready : std_logic;
        enabled : std_logic;
        active : std_logic;
        valid : std_logic;
        idle : std_logic
    ) return std_logic_vector is
        variable status : std_logic_vector(7 downto 0);
    begin
        status(STATUS_FAULT_BIT) := fault;
        status(STATUS_ALARM_BIT) := alarm;
        status(STATUS_BUSY_BIT) := busy;
        status(STATUS_READY_BIT) := ready;
        status(STATUS_ENABLED_BIT) := enabled;
        status(STATUS_ACTIVE_BIT) := active;
        status(STATUS_VALID_BIT) := valid;
        status(STATUS_IDLE_BIT) := idle;
        return status;
    end function create_status_reg;
    
end package body volo_common_pkg;
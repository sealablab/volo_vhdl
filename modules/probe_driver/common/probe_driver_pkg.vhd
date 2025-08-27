-- probe_driver_pkg.vhd
-- Shared package for ProbeDriver components
-- Contains types, constants, and utility functions
-- Follows VHDL-2008 standards and industry best practices
-- REFACTORED: Aligned with new architecture requirements

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
-- TODO: Create intensity_lut_pkg.vhd in datadef/ directory
-- use work.intensity_lut_pkg.all;

package probe_driver_pkg is
    -- =============================================================================
    -- CONSTANTS
    -- =============================================================================
    -- Probe Configuration Constants (cfg_* prefix for configuration parameters)
    constant CFG_INTENSITY_MAX : integer := 100;
    constant CFG_PULSE_MIN_DURATION : unsigned(15 downto 0) := to_unsigned(100, 16);  -- 100 clock cycles minimum
    constant CFG_COOLDOWN_MIN : unsigned(15 downto 0) := to_unsigned(1000, 16);       -- 1000 clock cycles minimum
    
    -- Trigger Threshold
    constant CFG_TRIGGER_THRESHOLD : signed(15 downto 0) := to_signed(16384, 16);  -- Mid-scale for 16-bit signed
    
    -- =============================================================================
    -- STATE ENCODING (std_logic_vector for Verilog portability)
    -- =============================================================================
    -- State machine states (REFACTORED: Using std_logic_vector constants instead of enumeration)
    constant IDLE_STATE      : std_logic_vector(1 downto 0) := "00";
    constant ARMED_STATE     : std_logic_vector(1 downto 0) := "01";
    constant FIRING_STATE    : std_logic_vector(1 downto 0) := "10";
    constant COOL_DOWN_STATE : std_logic_vector(1 downto 0) := "11";
    
    -- =============================================================================
    -- DATA WIDTH CONSTANTS (replacing subtypes for Verilog portability)
    -- =============================================================================
    -- Status register width (16 bits for future expansion)
    constant STAT_REGISTER_WIDTH : integer := 16;
    
    -- Configuration data widths
    constant CFG_INTENSITY_INDEX_WIDTH : integer := 7;   -- 7 bits for 0-100 range
    constant CFG_DURATION_WIDTH : integer := 16;         -- 16 bits for consistency
    constant CFG_COOLDOWN_WIDTH : integer := 16;         -- 16 bits for consistency
    
    -- =============================================================================
    -- FUNCTIONS
    -- =============================================================================
    -- Convert probe state to string for debugging
    function probe_state_to_string(state : std_logic_vector(1 downto 0)) return string;
    
    -- Check if status register indicates specific state
    function is_probe_armed(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean;
    function is_probe_firing(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean;
    function is_probe_cooldown(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean;
    function is_probe_error(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean;
    
    -- Utility functions for status register manipulation
    function set_probe_status_bit(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0); bit_position : natural; value : std_logic) return std_logic_vector;
    function get_probe_status_bit(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0); bit_position : natural) return std_logic;
    
    -- Safe default value functions
    function get_safe_intensity_index(intensity_in : std_logic_vector(CFG_INTENSITY_INDEX_WIDTH-1 downto 0)) return std_logic_vector;
    function get_safe_duration(duration_in : std_logic_vector(CFG_DURATION_WIDTH-1 downto 0)) return std_logic_vector;
    function get_safe_cooldown(cooldown_in : std_logic_vector(CFG_COOLDOWN_WIDTH-1 downto 0)) return std_logic_vector;
    
    -- Intensity lookup functions
    function get_intensity_output(index : std_logic_vector(CFG_INTENSITY_INDEX_WIDTH-1 downto 0)) return signed;
    
end package probe_driver_pkg;

package body probe_driver_pkg is
    function probe_state_to_string(state : std_logic_vector(1 downto 0)) return string is
    begin
        case state is
            when IDLE_STATE => return "IDLE";
            when ARMED_STATE => return "ARMED";
            when FIRING_STATE => return "FIRING";
            when COOL_DOWN_STATE => return "COOL_DOWN";
            when others => return "UNKNOWN";
        end case;
    end function;
    
    function is_probe_armed(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean is
    begin
        return status(0) = '1';
    end function;
    
    function is_probe_firing(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean is
    begin
        return status(1) = '1';
    end function;
    
    function is_probe_cooldown(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean is
    begin
        return status(3) = '1';
    end function;
    
    function is_probe_error(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0)) return boolean is
    begin
        return status(4) = '1';
    end function;
    
    function set_probe_status_bit(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0); bit_position : natural; value : std_logic) return std_logic_vector is
        variable result : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0) := status;
    begin
        if bit_position < STAT_REGISTER_WIDTH then
            result(bit_position) := value;
        end if;
        return result;
    end function;
    
    function get_probe_status_bit(status : std_logic_vector(STAT_REGISTER_WIDTH-1 downto 0); bit_position : natural) return std_logic is
    begin
        if bit_position < STAT_REGISTER_WIDTH then
            return status(bit_position);
        else
            return '0';
        end if;
    end function;
    
    -- Safe default value functions
    function get_safe_intensity_index(intensity_in : std_logic_vector(CFG_INTENSITY_INDEX_WIDTH-1 downto 0)) return std_logic_vector is
    begin
        if intensity_in = "0000000" then
            return "0000001";  -- Safe minimum intensity (IntensityLut[1] = smallest observable output)
        else
            return intensity_in;
        end if;
    end function;
    
    function get_safe_duration(duration_in : std_logic_vector(CFG_DURATION_WIDTH-1 downto 0)) return std_logic_vector is
    begin
        if duration_in = x"0000" then
            return std_logic_vector(CFG_PULSE_MIN_DURATION);  -- Safe minimum duration
        else
            return duration_in;
        end if;
    end function;
    
    function get_safe_cooldown(cooldown_in : std_logic_vector(CFG_COOLDOWN_WIDTH-1 downto 0)) return std_logic_vector is
    begin
        if cooldown_in = x"0000" then
            return std_logic_vector(CFG_COOLDOWN_MIN);  -- Safe minimum cooldown
        else
            return cooldown_in;
        end if;
    end function;
    
    -- Intensity lookup function using the lookup table
    -- TODO: Implement when intensity_lut_pkg.vhd is created in datadef/
    function get_intensity_output(index : std_logic_vector(CFG_INTENSITY_INDEX_WIDTH-1 downto 0)) return signed is
    begin
        -- Placeholder return - replace when intensity_lut_pkg is available
        return to_signed(0, 16);  -- Return zero for now
        -- return get_intensity_value_safe(index);
    end function;
    
end package body;


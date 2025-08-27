--------------------------------------------------------------------------------
-- Package: ProbeLimits_pkg
-- Purpose: Simple datatype for SCA/FI Probe limits - easily portable to Verilog
-- Author: johnnyc
-- Date: 2025-08-26
-- 
-- This package defines a simple record type containing probe operating limits.
-- The structure maps directly to a Pydantic model and can be easily ported
-- to Verilog using packed structs or parameter arrays.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package ProbeLimits_pkg is
    
    -- Constants for data widths
    constant PROBE_DURATION_WIDTH : natural := 16;  -- 16-bit unsigned for durations
    constant PROBE_INTENSITY_WIDTH : natural := 16; -- 16-bit signed for intensities
    constant PROBE_LIMITS_TOTAL_WIDTH : natural := 64; -- Total packed width (4 × 16 bits)
    
    -- Default values (matching Pydantic model defaults)
    constant DEFAULT_DURATION_MIN : natural := 2;
    constant DEFAULT_DURATION_MAX : natural := 30;
    constant DEFAULT_INTENSITY_MIN : integer := 16#0000#;  -- 0x0000
    constant DEFAULT_INTENSITY_MAX : integer := 16#7FFF#;  -- 0x7FFF
    
    -- ProbeLimits data structure using flat signals for Verilog portability
    -- Bit field definitions for packed representation
    constant DURATION_MIN_HIGH : natural := 63;
    constant DURATION_MIN_LOW  : natural := 48;
    constant DURATION_MAX_HIGH : natural := 47;
    constant DURATION_MAX_LOW  : natural := 32;
    constant INTENSITY_MIN_HIGH : natural := 31;
    constant INTENSITY_MIN_LOW  : natural := 16;
    constant INTENSITY_MAX_HIGH : natural := 15;
    constant INTENSITY_MAX_LOW  : natural := 0;
    
    -- Default probe limits as packed std_logic_vector
    constant DEFAULT_PROBE_LIMITS_PACKED : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0) := (
        DURATION_MIN_HIGH downto DURATION_MIN_LOW   => std_logic_vector(to_unsigned(DEFAULT_DURATION_MIN, PROBE_DURATION_WIDTH)),
        DURATION_MAX_HIGH downto DURATION_MAX_LOW   => std_logic_vector(to_unsigned(DEFAULT_DURATION_MAX, PROBE_DURATION_WIDTH)),
        INTENSITY_MIN_HIGH downto INTENSITY_MIN_LOW => std_logic_vector(to_signed(DEFAULT_INTENSITY_MIN, PROBE_INTENSITY_WIDTH)),
        INTENSITY_MAX_HIGH downto INTENSITY_MAX_LOW => std_logic_vector(to_signed(DEFAULT_INTENSITY_MAX, PROBE_INTENSITY_WIDTH))
    );
    
    -- Function declarations
    
    -- Create probe limits from individual values
    function create_probe_limits(duration_min : natural;
                                duration_max : natural;
                                intensity_min_v : integer;
                                intensity_max_v : integer) 
                                return std_logic_vector;
    
    -- Pack probe limits into a single std_logic_vector (for easy register/memory interface)
    function pack_probe_limits(duration_min : unsigned(PROBE_DURATION_WIDTH-1 downto 0);
                              duration_max : unsigned(PROBE_DURATION_WIDTH-1 downto 0);
                              intensity_min_v : signed(PROBE_INTENSITY_WIDTH-1 downto 0);
                              intensity_max_v : signed(PROBE_INTENSITY_WIDTH-1 downto 0)) 
                              return std_logic_vector;
    
    -- Extract individual fields from packed std_logic_vector
    function get_duration_min(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                             return unsigned;
    function get_duration_max(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                             return unsigned;
    function get_intensity_min_v(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return signed;
    function get_intensity_max_v(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return signed;
    
    -- Validation functions
    function is_valid_probe_limits(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                  return boolean;
    function is_duration_valid(duration_min, duration_max : unsigned) return boolean;
    function is_intensity_valid(intensity_min_v, intensity_max_v : signed) return boolean;
    
    -- Convert individual fields to std_logic_vector (useful for port mapping)
    function duration_min_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return std_logic_vector;
    function duration_max_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return std_logic_vector;
    function intensity_min_v_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                   return std_logic_vector;
    function intensity_max_v_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                   return std_logic_vector;

end package ProbeLimits_pkg;

package body ProbeLimits_pkg is
    
    -- Create probe limits from individual values
    function create_probe_limits(duration_min : natural;
                                duration_max : natural;
                                intensity_min_v : integer;
                                intensity_max_v : integer) 
                                return std_logic_vector is
        variable packed : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0);
    begin
        packed(DURATION_MIN_HIGH downto DURATION_MIN_LOW) := std_logic_vector(to_unsigned(duration_min, PROBE_DURATION_WIDTH));
        packed(DURATION_MAX_HIGH downto DURATION_MAX_LOW) := std_logic_vector(to_unsigned(duration_max, PROBE_DURATION_WIDTH));
        packed(INTENSITY_MIN_HIGH downto INTENSITY_MIN_LOW) := std_logic_vector(to_signed(intensity_min_v, PROBE_INTENSITY_WIDTH));
        packed(INTENSITY_MAX_HIGH downto INTENSITY_MAX_LOW) := std_logic_vector(to_signed(intensity_max_v, PROBE_INTENSITY_WIDTH));
        return packed;
    end function;
    
    -- Pack probe limits into a single 64-bit std_logic_vector
    -- Format: [duration_min(15:0), duration_max(15:0), intensity_min_v(15:0), intensity_max_v(15:0)]
    function pack_probe_limits(duration_min : unsigned(PROBE_DURATION_WIDTH-1 downto 0);
                              duration_max : unsigned(PROBE_DURATION_WIDTH-1 downto 0);
                              intensity_min_v : signed(PROBE_INTENSITY_WIDTH-1 downto 0);
                              intensity_max_v : signed(PROBE_INTENSITY_WIDTH-1 downto 0)) 
                              return std_logic_vector is
        variable packed : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0);
    begin
        packed(DURATION_MIN_HIGH downto DURATION_MIN_LOW) := std_logic_vector(duration_min);
        packed(DURATION_MAX_HIGH downto DURATION_MAX_LOW) := std_logic_vector(duration_max);
        packed(INTENSITY_MIN_HIGH downto INTENSITY_MIN_LOW) := std_logic_vector(intensity_min_v);
        packed(INTENSITY_MAX_HIGH downto INTENSITY_MAX_LOW) := std_logic_vector(intensity_max_v);
        return packed;
    end function;
    
    -- Extract duration_min from packed data
    function get_duration_min(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                             return unsigned is
    begin
        return unsigned(packed_data(DURATION_MIN_HIGH downto DURATION_MIN_LOW));
    end function;
    
    -- Extract duration_max from packed data
    function get_duration_max(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                             return unsigned is
    begin
        return unsigned(packed_data(DURATION_MAX_HIGH downto DURATION_MAX_LOW));
    end function;
    
    -- Extract intensity_min_v from packed data
    function get_intensity_min_v(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return signed is
    begin
        return signed(packed_data(INTENSITY_MIN_HIGH downto INTENSITY_MIN_LOW));
    end function;
    
    -- Extract intensity_max_v from packed data
    function get_intensity_max_v(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return signed is
    begin
        return signed(packed_data(INTENSITY_MAX_HIGH downto INTENSITY_MAX_LOW));
    end function;
    
    -- Check if duration values are valid (min <= max)
    function is_duration_valid(duration_min, duration_max : unsigned) return boolean is
    begin
        return (duration_min <= duration_max) and (duration_min > 0);
    end function;
    
    -- Check if intensity values are valid (min <= max)
    function is_intensity_valid(intensity_min_v, intensity_max_v : signed) return boolean is
    begin
        return (intensity_min_v <= intensity_max_v);
    end function;
    
    -- Validate entire probe limits structure
    function is_valid_probe_limits(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                  return boolean is
    begin
        return is_duration_valid(get_duration_min(packed_data), get_duration_max(packed_data)) and
               is_intensity_valid(get_intensity_min_v(packed_data), get_intensity_max_v(packed_data));
    end function;
    
    -- Convert individual fields to std_logic_vector (useful for port mapping)
    function duration_min_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return std_logic_vector is
    begin
        return std_logic_vector(get_duration_min(packed_data));
    end function;
    
    function duration_max_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                return std_logic_vector is
    begin
        return std_logic_vector(get_duration_max(packed_data));
    end function;
    
    function intensity_min_v_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                   return std_logic_vector is
    begin
        return std_logic_vector(get_intensity_min_v(packed_data));
    end function;
    
    function intensity_max_v_to_slv(packed_data : std_logic_vector(PROBE_LIMITS_TOTAL_WIDTH-1 downto 0)) 
                                   return std_logic_vector is
    begin
        return std_logic_vector(get_intensity_max_v(packed_data));
    end function;

end package body ProbeLimits_pkg;
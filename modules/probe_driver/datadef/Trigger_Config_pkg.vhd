--------------------------------------------------------------------------------
-- Package: Trigger_Config_pkg
-- Purpose: Trigger configuration datatype for SCA/FI Probe triggers - easily portable to Verilog
-- Author: johnnyc
-- Date: 2025-08-26
-- 
-- This package defines a simple record type containing trigger configuration parameters.
-- The structure maps directly to a Pydantic model and can be easily ported
-- to Verilog using packed structs or parameter arrays.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Trigger_Config_pkg is
    
    -- Constants for data widths
    constant TRIGGER_THRESHOLD_WIDTH : natural := 16;  -- 16-bit unsigned for threshold
    constant TRIGGER_DURATION_WIDTH : natural := 16;   -- 16-bit unsigned for duration
    constant TRIGGER_INTENSITY_WIDTH : natural := 16;  -- 16-bit unsigned for intensity
    
    -- Trigger configuration data structure
    type t_trigger_config is record
        trigger_in_threshold    : std_logic_vector(TRIGGER_THRESHOLD_WIDTH-1 downto 0);
        trigger_in_duration_min : natural;  -- clk cycles
        trigger_in_duration_max : natural;  -- clk cycles
        intensity_in_min        : std_logic_vector(TRIGGER_INTENSITY_WIDTH-1 downto 0);
        intensity_in_max        : std_logic_vector(TRIGGER_INTENSITY_WIDTH-1 downto 0);
    end record;

    -- DS1120 = TriggerConfig(0x20, 2, 31, 0x00, 0x7F00)
    constant DS1120_CONFIG : t_trigger_config := (
        trigger_in_threshold    => x"0020",
        trigger_in_duration_min => 2,
        trigger_in_duration_max => 31,
        intensity_in_min        => x"0000",
        intensity_in_max        => x"7F00"
    );

    -- DS1130 = TriggerConfig(0x30, 2, 31, 0x00, 0x7F00)
    constant DS1130_CONFIG : t_trigger_config := (
        trigger_in_threshold    => x"0030",
        trigger_in_duration_min => 2,
        trigger_in_duration_max => 31,
        intensity_in_min        => x"0000",
        intensity_in_max        => x"7F00"
    );

end package Trigger_Config_pkg;

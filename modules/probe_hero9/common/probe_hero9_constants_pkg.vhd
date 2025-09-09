-- =============================================================================
-- ProbeHero9 Constants Package
-- =============================================================================
-- 
-- Generated from: PH9-interface-reqs-v1.md
-- Date: 2025-01-27
-- Purpose: Constants and bit definitions for ProbeHero9 module
-- 
-- This package provides all constants, bit definitions, and validation ranges
-- for the ProbeHero9 module, following VOLO coding standards.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package probe_hero9_constants_pkg is

    -- =========================================================================
    -- System Constants with Unit Documentation
    -- =========================================================================
    
    -- Signal Width Constants
    constant PROBE_SELECTOR_WIDTH : natural := 2;    -- Units: bits (probe selector width)
    constant INTENSITY_INDEX_WIDTH : natural := 7;   -- Units: bits (intensity index width)
    constant DURATION_WIDTH : natural := 16;         -- Units: bits (duration data width)
    constant VOLTAGE_OUTPUT_WIDTH : natural := 16;   -- Units: bits (voltage output width)
    constant STATUS_REGISTER_WIDTH : natural := 8;   -- Units: bits (status register width)
    
    -- Default Values
    constant DEFAULT_PROBE_SELECTOR : std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0) := "00";  -- Units: index (first probe)
    constant DEFAULT_INTENSITY_INDEX : std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0) := "0000101";  -- Units: index (5% intensity)
    constant DEFAULT_FIRE_DURATION : unsigned(DURATION_WIDTH-1 downto 0) := to_unsigned(0, DURATION_WIDTH);  -- Units: clks (no duration)
    constant DEFAULT_COOLDOWN_DURATION : unsigned(DURATION_WIDTH-1 downto 0) := to_unsigned(1000, DURATION_WIDTH);  -- Units: clks (1000 cycles)
    
    -- Safe Output Values
    constant SAFE_VOLTAGE_OUTPUT : signed(VOLTAGE_OUTPUT_WIDTH-1 downto 0) := to_signed(0, VOLTAGE_OUTPUT_WIDTH);  -- Units: volts (zero voltage)
    
    -- =========================================================================
    -- Status Register Bit Definitions
    -- =========================================================================
    
    -- Status Register Bit Positions
    constant STATUS_FAULT_BIT : natural := 7;    -- Units: bits (fault condition bit)
    constant STATUS_ALARM_BIT : natural := 6;    -- Units: bits (alarm/warning bit)
    constant STATUS_RESERVED5_BIT : natural := 5; -- Units: bits (reserved bit 5)
    constant STATUS_RESERVED4_BIT : natural := 4; -- Units: bits (reserved bit 4)
    constant STATUS_COOL_BIT : natural := 3;      -- Units: bits (cooling status bit)
    constant STATUS_FIRED_BIT : natural := 2;     -- Units: bits (fired status bit)
    constant STATUS_FIRING_BIT : natural := 1;    -- Units: bits (firing status bit)
    constant STATUS_ARMED_BIT : natural := 0;     -- Units: bits (armed status bit)
    
    -- Status Register Bit Masks
    constant STATUS_FAULT_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "10000000";  -- Units: bits (fault mask)
    constant STATUS_ALARM_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "01000000";  -- Units: bits (alarm mask)
    constant STATUS_RESERVED5_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00100000";  -- Units: bits (reserved5 mask)
    constant STATUS_RESERVED4_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00010000";  -- Units: bits (reserved4 mask)
    constant STATUS_COOL_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00001000";  -- Units: bits (cool mask)
    constant STATUS_FIRED_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00000100";  -- Units: bits (fired mask)
    constant STATUS_FIRING_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00000010";  -- Units: bits (firing mask)
    constant STATUS_ARMED_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := "00000001";  -- Units: bits (armed mask)
    
    -- =========================================================================
    -- State Machine Constants
    -- =========================================================================
    
    -- State Encoding (std_logic_vector for Verilog compatibility)
    constant STATE_IDLE : std_logic_vector(2 downto 0) := "000";      -- Units: state (idle state)
    constant STATE_ARMED : std_logic_vector(2 downto 0) := "001";    -- Units: state (armed state)
    constant STATE_FIRING : std_logic_vector(2 downto 0) := "010";   -- Units: state (firing state)
    constant STATE_COOLING : std_logic_vector(2 downto 0) := "011";  -- Units: state (cooling state)
    constant STATE_HARDFAULT : std_logic_vector(2 downto 0) := "100"; -- Units: state (hardfault state)
    
    -- State Width
    constant STATE_WIDTH : natural := 3;  -- Units: bits (state encoding width)
    
    -- =========================================================================
    -- Validation Constants
    -- =========================================================================
    
    -- Probe Selector Validation
    constant PROBE_SELECTOR_MIN : natural := 0;  -- Units: index (minimum probe index)
    constant PROBE_SELECTOR_MAX : natural := 3;  -- Units: index (maximum probe index)
    
    -- Intensity Index Validation
    constant INTENSITY_INDEX_MIN : natural := 0;   -- Units: index (minimum intensity index)
    constant INTENSITY_INDEX_MAX : natural := 127; -- Units: index (maximum intensity index)
    
    -- Duration Validation (will be clamped to probe config limits)
    constant DURATION_MIN : natural := 0;        -- Units: clks (minimum duration)
    constant DURATION_MAX : natural := 65535;    -- Units: clks (maximum duration)
    
    -- =========================================================================
    -- Units Constants for Documentation
    -- =========================================================================
    
    -- Physical Units
    constant UNITS_CLKS : string := "clks";      -- Units: string (clock cycles)
    constant UNITS_VOLTS : string := "volts";    -- Units: string (voltage)
    constant UNITS_INDEX : string := "index";    -- Units: string (table indices)
    constant UNITS_BITS : string := "bits";      -- Units: string (status register)
    constant UNITS_SIGNAL : string := "signal";  -- Units: string (control signals)
    constant UNITS_STATE : string := "state";    -- Units: string (state machine states)
    constant UNITS_COUNT : string := "count";    -- Units: string (quantities)
    constant UNITS_RATIO : string := "ratio";    -- Units: string (percentage/intensity)
    
    -- =========================================================================
    -- Helper Functions
    -- =========================================================================
    
    -- Units: input: probe_selector (index) -> output: boolean (validity)
    -- Purpose: Validates probe selector index is within valid range
    function is_valid_probe_selector(probe_selector : std_logic_vector) return boolean;
    
    -- Units: input: intensity_index (index) -> output: boolean (validity)
    -- Purpose: Validates intensity index is within valid range
    function is_valid_intensity_index(intensity_index : std_logic_vector) return boolean;
    
    -- Units: input: duration (clks) -> output: boolean (validity)
    -- Purpose: Validates duration is within valid range
    function is_valid_duration(duration : unsigned) return boolean;

end package probe_hero9_constants_pkg;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body probe_hero9_constants_pkg is

    -- Units: input: probe_selector (index) -> output: boolean (validity)
    function is_valid_probe_selector(probe_selector : std_logic_vector) return boolean is
    begin
        return (to_integer(unsigned(probe_selector)) >= PROBE_SELECTOR_MIN) and 
               (to_integer(unsigned(probe_selector)) <= PROBE_SELECTOR_MAX);
    end function;
    
    -- Units: input: intensity_index (index) -> output: boolean (validity)
    function is_valid_intensity_index(intensity_index : std_logic_vector) return boolean is
    begin
        return (to_integer(unsigned(intensity_index)) >= INTENSITY_INDEX_MIN) and 
               (to_integer(unsigned(intensity_index)) <= INTENSITY_INDEX_MAX);
    end function;
    
    -- Units: input: duration (clks) -> output: boolean (validity)
    function is_valid_duration(duration : unsigned) return boolean is
    begin
        return (duration >= DURATION_MIN) and (duration <= DURATION_MAX);
    end function;

end package body probe_hero9_constants_pkg;
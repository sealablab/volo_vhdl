-- =============================================================================
-- ProbeHero10 Constants Package
-- =============================================================================
-- 
-- This package provides all constants, bit definitions, and validation ranges
-- for the ProbeHero10 voltage-controlled probe firing system.
-- 
-- UNIT CONVENTIONS:
-- - voltage values: volts (voltage output levels)
-- - duration values: clks (clock cycles for timing)
-- - intensity values: index (table/array indices)
-- - signal values: signal (control and status signals)
-- - count values: count (quantities and sizes)
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package probe_hero10_constants_pkg is

    -- =========================================================================
    -- Status Register Bit Definitions
    -- =========================================================================
    -- Standard VOLO status register bit positions
    constant STATUS_FAULT_BIT      : natural := 7;  -- Units: bit (fault condition)
    constant STATUS_ALARM_BIT      : natural := 6;  -- Units: bit (alarm/warning condition)
    constant STATUS_BUSY_BIT       : natural := 5;  -- Units: bit (busy state)
    constant STATUS_READY_BIT     : natural := 4;  -- Units: bit (ready state)
    constant STATUS_ENABLED_BIT   : natural := 3;  -- Units: bit (enabled state)
    constant STATUS_ACTIVE_BIT    : natural := 2;  -- Units: bit (active state)
    constant STATUS_VALID_BIT     : natural := 1;  -- Units: bit (valid state)
    constant STATUS_IDLE_BIT      : natural := 0;   -- Units: bit (idle state)
    
    -- Status register width
    constant STATUS_REGISTER_WIDTH : natural := 8;  -- Units: bits (status register width)
    
    -- =========================================================================
    -- Configuration Parameter Widths
    -- =========================================================================
    constant PROBE_SELECTOR_WIDTH : natural := 2;   -- Units: bits (probe selector width)
    constant INTENSITY_INDEX_WIDTH : natural := 7;  -- Units: bits (intensity index width)
    constant DURATION_WIDTH : natural := 16;        -- Units: bits (duration width)
    constant VOLTAGE_OUTPUT_WIDTH : natural := 16;   -- Units: bits (voltage output width)
    
    -- =========================================================================
    -- Configuration Limits and Validation Ranges
    -- =========================================================================
    
    -- Probe selector validation (Units: index)
    constant PROBE_SELECTOR_MIN : natural := 0;     -- Units: index (minimum probe index)
    constant PROBE_SELECTOR_MAX : natural := 3;      -- Units: index (maximum probe index)
    
    -- Intensity index validation (Units: index)
    constant INTENSITY_INDEX_MIN : natural := 0;   -- Units: index (minimum intensity index)
    constant INTENSITY_INDEX_MAX : natural := 100; -- Units: index (maximum intensity index)
    
    -- Duration validation (Units: clks)
    constant DURATION_MIN : natural := 1;          -- Units: clks (minimum duration)
    constant DURATION_MAX : natural := 65535;      -- Units: clks (maximum duration)
    
    -- Voltage validation (Units: volts)
    constant VOLTAGE_MIN : natural := 0;           -- Units: volts (minimum voltage)
    constant VOLTAGE_MAX : natural := 65535;       -- Units: volts (maximum voltage)
    
    -- =========================================================================
    -- Default Configuration Values
    -- =========================================================================
    
    -- Default probe selector (Units: index)
    constant DEFAULT_PROBE_SELECTOR : std_logic_vector(PROBE_SELECTOR_WIDTH-1 downto 0) := "00";  -- Units: index (first probe)
    
    -- Default intensity index (Units: index)
    constant DEFAULT_INTENSITY_INDEX : std_logic_vector(INTENSITY_INDEX_WIDTH-1 downto 0) := "0000101";  -- Units: index (5% intensity)
    
    -- Default fire duration (Units: clks)
    constant DEFAULT_FIRE_DURATION : unsigned(DURATION_WIDTH-1 downto 0) := to_unsigned(0, DURATION_WIDTH);  -- Units: clks (no duration)
    
    -- Default cooldown duration (Units: clks)
    constant DEFAULT_COOLDOWN_DURATION : unsigned(DURATION_WIDTH-1 downto 0) := to_unsigned(1000, DURATION_WIDTH);  -- Units: clks (1000 cycles)
    
    -- =========================================================================
    -- Status Register Masks
    -- =========================================================================
    
    -- Status register bit masks for easy testing
    constant STATUS_FAULT_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_FAULT_BIT => '1', others => '0');
    constant STATUS_ALARM_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_ALARM_BIT => '1', others => '0');
    constant STATUS_BUSY_MASK  : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_BUSY_BIT => '1', others => '0');
    constant STATUS_READY_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_READY_BIT => '1', others => '0');
    constant STATUS_ENABLED_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_ENABLED_BIT => '1', others => '0');
    constant STATUS_ACTIVE_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_ACTIVE_BIT => '1', others => '0');
    constant STATUS_VALID_MASK : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_VALID_BIT => '1', others => '0');
    constant STATUS_IDLE_MASK  : std_logic_vector(STATUS_REGISTER_WIDTH-1 downto 0) := (STATUS_IDLE_BIT => '1', others => '0');
    
    -- =========================================================================
    -- Validation Functions
    -- =========================================================================
    
    -- Units: input: probe_selector (index) -> output: boolean (validity)
    -- Purpose: Validates that probe selector is within valid range
    function is_valid_probe_selector(probe_selector : std_logic_vector) return boolean;
    
    -- Units: input: intensity_index (index) -> output: boolean (validity)
    -- Purpose: Validates that intensity index is within valid range
    function is_valid_intensity_index(intensity_index : std_logic_vector) return boolean;
    
    -- Units: input: duration (clks) -> output: boolean (validity)
    -- Purpose: Validates that duration is within valid range
    function is_valid_duration(duration : unsigned) return boolean;
    
    -- =========================================================================
    -- Units Constants for Documentation
    -- =========================================================================
    
    -- Signal units
    constant UNITS_SIGNAL : string := "signal";      -- Units: signal (control and status signals)
    constant UNITS_CLKS : string := "clks";          -- Units: clks (clock cycles for timing)
    constant UNITS_VOLTS : string := "volts";       -- Units: volts (voltage output levels)
    constant UNITS_INDEX : string := "index";        -- Units: index (table/array indices)
    constant UNITS_BITS : string := "bits";          -- Units: bits (data width)
    constant UNITS_COUNT : string := "count";        -- Units: count (quantities and sizes)
    constant UNITS_RATIO : string := "ratio";        -- Units: ratio (percentage/intensity scaling)

end package probe_hero10_constants_pkg;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body probe_hero10_constants_pkg is

    -- =========================================================================
    -- Validation Function Implementations
    -- =========================================================================
    
    function is_valid_probe_selector(probe_selector : std_logic_vector) return boolean is
        variable selector_value : natural;
    begin
        selector_value := to_integer(unsigned(probe_selector));
        return (selector_value >= PROBE_SELECTOR_MIN) and (selector_value <= PROBE_SELECTOR_MAX);
    end function;
    
    function is_valid_intensity_index(intensity_index : std_logic_vector) return boolean is
        variable intensity_value : natural;
    begin
        intensity_value := to_integer(unsigned(intensity_index));
        return (intensity_value >= INTENSITY_INDEX_MIN) and (intensity_value <= INTENSITY_INDEX_MAX);
    end function;
    
    function is_valid_duration(duration : unsigned) return boolean is
        variable duration_value : natural;
    begin
        duration_value := to_integer(duration);
        return (duration_value >= DURATION_MIN) and (duration_value <= DURATION_MAX);
    end function;

end package body probe_hero10_constants_pkg;
-- =============================================================================
-- Probe Configuration Package
-- =============================================================================
-- 
-- This package defines probe configuration types, validation functions, and
-- ALARM bit definitions for the ProbeHero8 module.
--
-- Features:
-- - Probe selection and voltage level configuration
-- - Timing parameter definitions
-- - Parameter validation functions
-- - ALARM bit definitions for safety monitoring
-- - Verilog-portable record types for data organization
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package probe_config_pkg is

    -- =========================================================================
    -- Configuration Constants
    -- =========================================================================
    
    -- Probe selection constants (4-bit encoding for up to 16 probes)
    constant PROBE_SEL_WIDTH : integer := 4;
    constant MAX_PROBE_COUNT : integer := 8;  -- Maximum number of probes supported
    
    -- Voltage level constants (12-bit for 0-4095 mV range)
    constant VOLTAGE_WIDTH : integer := 12;
    constant VOLTAGE_MIN : integer := 0;      -- 0 mV
    constant VOLTAGE_MAX : integer := 4095;   -- 4095 mV (4.095V)
    constant VOLTAGE_DEFAULT : integer := 1000; -- 1.0V default
    
    -- Timing constants (16-bit for timing parameters)
    constant TIMING_WIDTH : integer := 16;
    constant FIRING_DURATION_MIN : integer := 1;    -- 1 clock cycle minimum
    constant FIRING_DURATION_MAX : integer := 65535; -- 65535 clock cycles maximum
    constant COOLING_DURATION_MIN : integer := 100; -- 100 clock cycles minimum
    constant COOLING_DURATION_MAX : integer := 65535; -- 65535 clock cycles maximum
    
    -- ALARM bit definitions (8-bit ALARM register)
    constant ALARM_WIDTH : integer := 8;
    constant ALARM_INVALID_PROBE_SEL : integer := 0;  -- Bit 0: Invalid probe selection
    constant ALARM_VOLTAGE_OUT_OF_RANGE : integer := 1; -- Bit 1: Voltage out of range
    constant ALARM_FIRING_TIMEOUT : integer := 2;     -- Bit 2: Firing sequence timeout
    constant ALARM_COOLING_TIMEOUT : integer := 3;    -- Bit 3: Cooling timeout
    constant ALARM_PARAM_VALIDATION : integer := 4;   -- Bit 4: Parameter validation failure
    constant ALARM_SAFETY_FAULT : integer := 5;       -- Bit 5: Safety-critical fault
    constant ALARM_RESERVED_6 : integer := 6;         -- Bit 6: Reserved
    constant ALARM_RESERVED_7 : integer := 7;         -- Bit 7: Reserved

    -- =========================================================================
    -- Configuration Record Types (Verilog-portable)
    -- =========================================================================
    
    -- Probe configuration record
    type t_probe_config is record
        probe_selection    : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
        firing_voltage     : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
        firing_duration    : std_logic_vector(TIMING_WIDTH-1 downto 0);
        cooling_duration   : std_logic_vector(TIMING_WIDTH-1 downto 0);
        enable_auto_arm    : std_logic;
        enable_safety_mode : std_logic;
    end record;
    
    -- Default configuration constant
    constant DEFAULT_PROBE_CONFIG : t_probe_config := (
        probe_selection    => std_logic_vector(to_unsigned(0, PROBE_SEL_WIDTH)),
        firing_voltage     => std_logic_vector(to_unsigned(VOLTAGE_DEFAULT, VOLTAGE_WIDTH)),
        firing_duration    => std_logic_vector(to_unsigned(100, TIMING_WIDTH)),
        cooling_duration   => std_logic_vector(to_unsigned(1000, TIMING_WIDTH)),
        enable_auto_arm    => '0',
        enable_safety_mode => '1'
    );

    -- =========================================================================
    -- Validation Functions
    -- =========================================================================
    
    -- Validate probe selection
    function is_valid_probe_selection(probe_sel : std_logic_vector) return boolean;
    
    -- Validate voltage level
    function is_valid_voltage(voltage : std_logic_vector) return boolean;
    
    -- Validate firing duration
    function is_valid_firing_duration(duration : std_logic_vector) return boolean;
    
    -- Validate cooling duration
    function is_valid_cooling_duration(duration : std_logic_vector) return boolean;
    
    -- Validate complete probe configuration
    function is_valid_probe_config(config : t_probe_config) return boolean;
    
    -- Generate ALARM bits for configuration validation
    function generate_config_alarms(config : t_probe_config) return std_logic_vector;

    -- =========================================================================
    -- Conversion Functions (for Verilog compatibility)
    -- =========================================================================
    
    -- Convert probe config to packed std_logic_vector
    function probe_config_to_packed(config : t_probe_config) return std_logic_vector;
    
    -- Convert packed std_logic_vector to probe config
    function packed_to_probe_config(packed_data : std_logic_vector) return t_probe_config;

end package probe_config_pkg;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body probe_config_pkg is

    -- Validate probe selection
    function is_valid_probe_selection(probe_sel : std_logic_vector) return boolean is
        variable sel_unsigned : unsigned(PROBE_SEL_WIDTH-1 downto 0);
    begin
        if probe_sel'length /= PROBE_SEL_WIDTH then
            return false;
        end if;
        
        sel_unsigned := unsigned(probe_sel);
        return (sel_unsigned < MAX_PROBE_COUNT);
    end function;

    -- Validate voltage level
    function is_valid_voltage(voltage : std_logic_vector) return boolean is
        variable volt_unsigned : unsigned(VOLTAGE_WIDTH-1 downto 0);
    begin
        if voltage'length /= VOLTAGE_WIDTH then
            return false;
        end if;
        
        volt_unsigned := unsigned(voltage);
        return (volt_unsigned >= VOLTAGE_MIN and volt_unsigned <= VOLTAGE_MAX);
    end function;

    -- Validate firing duration
    function is_valid_firing_duration(duration : std_logic_vector) return boolean is
        variable dur_unsigned : unsigned(TIMING_WIDTH-1 downto 0);
    begin
        if duration'length /= TIMING_WIDTH then
            return false;
        end if;
        
        dur_unsigned := unsigned(duration);
        return (dur_unsigned >= FIRING_DURATION_MIN and dur_unsigned <= FIRING_DURATION_MAX);
    end function;

    -- Validate cooling duration
    function is_valid_cooling_duration(duration : std_logic_vector) return boolean is
        variable dur_unsigned : unsigned(TIMING_WIDTH-1 downto 0);
    begin
        if duration'length /= TIMING_WIDTH then
            return false;
        end if;
        
        dur_unsigned := unsigned(duration);
        return (dur_unsigned >= COOLING_DURATION_MIN and dur_unsigned <= COOLING_DURATION_MAX);
    end function;

    -- Validate complete probe configuration
    function is_valid_probe_config(config : t_probe_config) return boolean is
    begin
        return is_valid_probe_selection(config.probe_selection) and
               is_valid_voltage(config.firing_voltage) and
               is_valid_firing_duration(config.firing_duration) and
               is_valid_cooling_duration(config.cooling_duration);
    end function;

    -- Generate ALARM bits for configuration validation
    function generate_config_alarms(config : t_probe_config) return std_logic_vector is
        variable alarms : std_logic_vector(ALARM_WIDTH-1 downto 0) := (others => '0');
    begin
        -- Check probe selection
        if not is_valid_probe_selection(config.probe_selection) then
            alarms(ALARM_INVALID_PROBE_SEL) := '1';
        end if;
        
        -- Check voltage range
        if not is_valid_voltage(config.firing_voltage) then
            alarms(ALARM_VOLTAGE_OUT_OF_RANGE) := '1';
        end if;
        
        -- Check firing duration
        if not is_valid_firing_duration(config.firing_duration) then
            alarms(ALARM_FIRING_TIMEOUT) := '1';
        end if;
        
        -- Check cooling duration
        if not is_valid_cooling_duration(config.cooling_duration) then
            alarms(ALARM_COOLING_TIMEOUT) := '1';
        end if;
        
        -- Overall parameter validation
        if not is_valid_probe_config(config) then
            alarms(ALARM_PARAM_VALIDATION) := '1';
        end if;
        
        return alarms;
    end function;

    -- Convert probe config to packed std_logic_vector
    function probe_config_to_packed(config : t_probe_config) return std_logic_vector is
        variable packed : std_logic_vector(47 downto 0);
    begin
        packed(47 downto 44) := config.probe_selection;                    -- 4 bits
        packed(43 downto 32) := config.firing_voltage;                     -- 12 bits
        packed(31 downto 16) := config.firing_duration;                    -- 16 bits
        packed(15 downto 0)  := config.cooling_duration;                   -- 16 bits
        -- Note: enable_auto_arm and enable_safety_mode are not packed for simplicity
        return packed;
    end function;

    -- Convert packed std_logic_vector to probe config
    function packed_to_probe_config(packed_data : std_logic_vector) return t_probe_config is
        variable config : t_probe_config;
    begin
        if packed_data'length < 48 then
            return DEFAULT_PROBE_CONFIG;  -- Return default if insufficient data
        end if;
        
        config.probe_selection  := packed_data(47 downto 44);
        config.firing_voltage   := packed_data(43 downto 32);
        config.firing_duration  := packed_data(31 downto 16);
        config.cooling_duration := packed_data(15 downto 0);
        config.enable_auto_arm  := '0';  -- Default values
        config.enable_safety_mode := '1';
        
        return config;
    end function;

end package body probe_config_pkg;
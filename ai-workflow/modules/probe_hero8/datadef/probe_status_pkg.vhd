-- =============================================================================
-- Probe Status Package
-- =============================================================================
-- 
-- This package defines status register layout, error code definitions, and
-- health monitoring types for the ProbeHero8 module.
--
-- Features:
-- - Status register layout with clear bit field definitions
-- - Error code definitions for fault reporting
-- - Health monitoring types and constants
-- - Verilog-portable record types for status organization
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package probe_status_pkg is

    -- =========================================================================
    -- Status Register Constants
    -- =========================================================================
    
    -- Status register width
    constant STATUS_REG_WIDTH : integer := 32;
    
    -- Status register bit field definitions
    constant STAT_FAULT_BIT : integer := 31;           -- Bit 31: FAULT bit
    constant STAT_ALARM_BIT : integer := 30;           -- Bit 30: ALARM bit
    constant STAT_READY_BIT : integer := 29;           -- Bit 29: READY bit
    constant STAT_ARMED_BIT : integer := 28;           -- Bit 28: ARMED bit
    constant STAT_FIRING_BIT : integer := 27;          -- Bit 27: FIRING bit
    constant STAT_COOLING_BIT : integer := 26;         -- Bit 26: COOLING bit
    
    -- State field (4 bits)
    constant STAT_STATE_MSB : integer := 25;
    constant STAT_STATE_LSB : integer := 22;
    
    -- Current probe selection (4 bits)
    constant STAT_PROBE_SEL_MSB : integer := 21;
    constant STAT_PROBE_SEL_LSB : integer := 18;
    
    -- Firing counter (8 bits)
    constant STAT_FIRING_CNT_MSB : integer := 17;
    constant STAT_FIRING_CNT_LSB : integer := 10;
    
    -- Cooling counter (8 bits)
    constant STAT_COOLING_CNT_MSB : integer := 9;
    constant STAT_COOLING_CNT_LSB : integer := 2;
    
    -- Reserved bits
    constant STAT_RESERVED_MSB : integer := 1;
    constant STAT_RESERVED_LSB : integer := 0;

    -- =========================================================================
    -- Error Code Definitions
    -- =========================================================================
    
    -- Error code width
    constant ERROR_CODE_WIDTH : integer := 8;
    
    -- Error codes (8-bit encoding)
    constant ERROR_NONE : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"00";
    constant ERROR_INVALID_PROBE_SEL : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"01";
    constant ERROR_VOLTAGE_OUT_OF_RANGE : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"02";
    constant ERROR_FIRING_TIMEOUT : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"03";
    constant ERROR_COOLING_TIMEOUT : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"04";
    constant ERROR_PARAM_VALIDATION : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"05";
    constant ERROR_SAFETY_FAULT : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"06";
    constant ERROR_TRIGGER_TIMEOUT : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"07";
    constant ERROR_UNKNOWN_STATE : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := x"FF";

    -- =========================================================================
    -- Health Monitoring Constants
    -- =========================================================================
    
    -- Health check intervals (in clock cycles)
    constant HEALTH_CHECK_INTERVAL : integer := 1000;  -- Check every 1000 cycles
    constant MAX_FIRING_COUNT : integer := 10000;      -- Maximum firing count before maintenance
    constant MAX_COOLING_COUNT : integer := 50000;     -- Maximum cooling count before maintenance
    
    -- Health status indicators
    constant HEALTH_GOOD : std_logic_vector(3 downto 0) := "0000";
    constant HEALTH_WARNING : std_logic_vector(3 downto 0) := "0001";
    constant HEALTH_CRITICAL : std_logic_vector(3 downto 0) := "0010";
    constant HEALTH_FAULT : std_logic_vector(3 downto 0) := "1111";

    -- =========================================================================
    -- Status Record Types (Verilog-portable)
    -- =========================================================================
    
    -- Probe status record
    type t_probe_status is record
        fault_bit        : std_logic;
        alarm_bit        : std_logic;
        ready_bit        : std_logic;
        armed_bit        : std_logic;
        firing_bit       : std_logic;
        cooling_bit      : std_logic;
        current_state    : std_logic_vector(3 downto 0);
        current_probe    : std_logic_vector(3 downto 0);
        firing_counter   : std_logic_vector(7 downto 0);
        cooling_counter  : std_logic_vector(7 downto 0);
        error_code       : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0);
        health_status    : std_logic_vector(3 downto 0);
    end record;
    
    -- Default status constant
    constant DEFAULT_PROBE_STATUS : t_probe_status := (
        fault_bit        => '0',
        alarm_bit        => '0',
        ready_bit        => '0',
        armed_bit        => '0',
        firing_bit       => '0',
        cooling_bit      => '0',
        current_state    => "0000",  -- ST_RESET
        current_probe    => "0000",
        firing_counter   => x"00",
        cooling_counter  => x"00",
        error_code       => ERROR_NONE,
        health_status    => HEALTH_GOOD
    );

    -- =========================================================================
    -- Status Register Functions
    -- =========================================================================
    
    -- Convert status record to 32-bit status register
    function status_to_register(status : t_probe_status) return std_logic_vector;
    
    -- Convert 32-bit status register to status record
    function register_to_status(status_reg : std_logic_vector) return t_probe_status;
    
    -- Update status register with new state
    function update_status_with_state(current_status : t_probe_status; 
                                    new_state : std_logic_vector) return t_probe_status;
    
    -- Update status register with error
    function update_status_with_error(current_status : t_probe_status; 
                                    error_code : std_logic_vector) return t_probe_status;
    
    -- Check if status indicates fault condition
    function is_fault_status(status : t_probe_status) return boolean;
    
    -- Check if status indicates alarm condition
    function is_alarm_status(status : t_probe_status) return boolean;

    -- =========================================================================
    -- Health Monitoring Functions
    -- =========================================================================
    
    -- Calculate health status based on counters and conditions
    function calculate_health_status(firing_count : unsigned; 
                                   cooling_count : unsigned;
                                   has_faults : boolean) return std_logic_vector;
    
    -- Check if maintenance is required
    function maintenance_required(status : t_probe_status) return boolean;

end package probe_status_pkg;

-- =============================================================================
-- Package Body Implementation
-- =============================================================================

package body probe_status_pkg is

    -- Convert status record to 32-bit status register
    function status_to_register(status : t_probe_status) return std_logic_vector is
        variable reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
    begin
        reg(STAT_FAULT_BIT) := status.fault_bit;
        reg(STAT_ALARM_BIT) := status.alarm_bit;
        reg(STAT_READY_BIT) := status.ready_bit;
        reg(STAT_ARMED_BIT) := status.armed_bit;
        reg(STAT_FIRING_BIT) := status.firing_bit;
        reg(STAT_COOLING_BIT) := status.cooling_bit;
        reg(STAT_STATE_MSB downto STAT_STATE_LSB) := status.current_state;
        reg(STAT_PROBE_SEL_MSB downto STAT_PROBE_SEL_LSB) := status.current_probe;
        reg(STAT_FIRING_CNT_MSB downto STAT_FIRING_CNT_LSB) := status.firing_counter;
        reg(STAT_COOLING_CNT_MSB downto STAT_COOLING_CNT_LSB) := status.cooling_counter;
        -- Reserved bits remain '0'
        return reg;
    end function;

    -- Convert 32-bit status register to status record
    function register_to_status(status_reg : std_logic_vector) return t_probe_status is
        variable status : t_probe_status;
    begin
        if status_reg'length < STATUS_REG_WIDTH then
            return DEFAULT_PROBE_STATUS;  -- Return default if insufficient data
        end if;
        
        status.fault_bit := status_reg(STAT_FAULT_BIT);
        status.alarm_bit := status_reg(STAT_ALARM_BIT);
        status.ready_bit := status_reg(STAT_READY_BIT);
        status.armed_bit := status_reg(STAT_ARMED_BIT);
        status.firing_bit := status_reg(STAT_FIRING_BIT);
        status.cooling_bit := status_reg(STAT_COOLING_BIT);
        status.current_state := status_reg(STAT_STATE_MSB downto STAT_STATE_LSB);
        status.current_probe := status_reg(STAT_PROBE_SEL_MSB downto STAT_PROBE_SEL_LSB);
        status.firing_counter := status_reg(STAT_FIRING_CNT_MSB downto STAT_FIRING_CNT_LSB);
        status.cooling_counter := status_reg(STAT_COOLING_CNT_MSB downto STAT_COOLING_CNT_LSB);
        status.error_code := ERROR_NONE;  -- Error code not stored in register
        status.health_status := HEALTH_GOOD;  -- Health status not stored in register
        
        return status;
    end function;

    -- Update status register with new state
    function update_status_with_state(current_status : t_probe_status; 
                                    new_state : std_logic_vector) return t_probe_status is
        variable updated_status : t_probe_status := current_status;
    begin
        updated_status.current_state := new_state;
        
        -- Update state-specific bits
        case new_state is
            when "0010" =>  -- ST_IDLE
                updated_status.ready_bit := '1';
                updated_status.armed_bit := '0';
                updated_status.firing_bit := '0';
                updated_status.cooling_bit := '0';
            when "0011" =>  -- ST_ARMED
                updated_status.ready_bit := '1';
                updated_status.armed_bit := '1';
                updated_status.firing_bit := '0';
                updated_status.cooling_bit := '0';
            when "0100" =>  -- ST_FIRING
                updated_status.ready_bit := '0';
                updated_status.armed_bit := '0';
                updated_status.firing_bit := '1';
                updated_status.cooling_bit := '0';
            when "0101" =>  -- ST_COOLING
                updated_status.ready_bit := '0';
                updated_status.armed_bit := '0';
                updated_status.firing_bit := '0';
                updated_status.cooling_bit := '1';
            when "1111" =>  -- ST_HARD_FAULT
                updated_status.fault_bit := '1';
                updated_status.ready_bit := '0';
                updated_status.armed_bit := '0';
                updated_status.firing_bit := '0';
                updated_status.cooling_bit := '0';
            when others =>
                -- Unknown state - set fault
                updated_status.fault_bit := '1';
                updated_status.error_code := ERROR_UNKNOWN_STATE;
        end case;
        
        return updated_status;
    end function;

    -- Update status register with error
    function update_status_with_error(current_status : t_probe_status; 
                                    error_code : std_logic_vector) return t_probe_status is
        variable updated_status : t_probe_status := current_status;
    begin
        updated_status.error_code := error_code;
        updated_status.alarm_bit := '1';
        
        -- Set fault bit for critical errors
        if error_code = ERROR_SAFETY_FAULT or 
           error_code = ERROR_UNKNOWN_STATE then
            updated_status.fault_bit := '1';
        end if;
        
        return updated_status;
    end function;

    -- Check if status indicates fault condition
    function is_fault_status(status : t_probe_status) return boolean is
    begin
        return (status.fault_bit = '1' or 
                status.error_code = ERROR_SAFETY_FAULT or
                status.error_code = ERROR_UNKNOWN_STATE);
    end function;

    -- Check if status indicates alarm condition
    function is_alarm_status(status : t_probe_status) return boolean is
    begin
        return (status.alarm_bit = '1' or
                status.error_code /= ERROR_NONE);
    end function;

    -- Calculate health status based on counters and conditions
    function calculate_health_status(firing_count : unsigned; 
                                   cooling_count : unsigned;
                                   has_faults : boolean) return std_logic_vector is
    begin
        if has_faults then
            return HEALTH_FAULT;
        elsif firing_count > MAX_FIRING_COUNT or cooling_count > MAX_COOLING_COUNT then
            return HEALTH_CRITICAL;
        elsif firing_count > (MAX_FIRING_COUNT / 2) or cooling_count > (MAX_COOLING_COUNT / 2) then
            return HEALTH_WARNING;
        else
            return HEALTH_GOOD;
        end if;
    end function;

    -- Check if maintenance is required
    function maintenance_required(status : t_probe_status) return boolean is
        variable firing_count : unsigned(7 downto 0);
        variable cooling_count : unsigned(7 downto 0);
    begin
        firing_count := unsigned(status.firing_counter);
        cooling_count := unsigned(status.cooling_counter);
        
        return (firing_count > MAX_FIRING_COUNT or 
                cooling_count > MAX_COOLING_COUNT or
                status.health_status = HEALTH_CRITICAL or
                status.health_status = HEALTH_FAULT);
    end function;

end package body probe_status_pkg;
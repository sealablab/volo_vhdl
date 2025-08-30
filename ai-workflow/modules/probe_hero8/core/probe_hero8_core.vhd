-- =============================================================================
-- ProbeHero8 Core Entity
-- =============================================================================
-- 
-- Enhanced probe driver with FSM states and safety features:
-- - FSM States: IDLE → ARMED → FIRING → COOLING → HARDFAULT
-- - Safety Features: Parameter validation, ALARM signaling, fault detection
-- - Enhanced Packages: Validation functions, error handling, status registers
-- - Verilog Portability: VHDL-2008 that converts cleanly to Verilog
--
-- State Encoding (4-bit):
--   0x2: ST_IDLE       - Default operational state
--   0x3: ST_ARMED      - Ready to fire, waiting for trigger
--   0x4: ST_FIRING     - Actively firing probe
--   0x5: ST_COOLING    - Post-fire cooling period
--   0xF: ST_HARD_FAULT - Safety-critical error state
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import ProbeHero8 packages
library WORK;
use WORK.probe_config_pkg.ALL;
use WORK.probe_status_pkg.ALL;

entity probe_hero8_core is
    generic (
        -- Module identification
        MODULE_NAME : string := "probe_hero8_core";
        
        -- Status register customization
        STATUS_REG_WIDTH : integer := 32;
        MODULE_STATUS_BITS : integer := 16
    );
    port (
        -- Clock and reset
        clk : in std_logic;
        rst_n : in std_logic;
        
        -- Control signals
        ctrl_enable : in std_logic;
        ctrl_arm : in std_logic;
        ctrl_trigger : in std_logic;
        
        -- Configuration parameters (safety-critical)
        cfg_safety_probe_selection : in std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
        cfg_safety_firing_voltage : in std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
        cfg_safety_firing_duration : in std_logic_vector(TIMING_WIDTH-1 downto 0);
        cfg_safety_cooling_duration : in std_logic_vector(TIMING_WIDTH-1 downto 0);
        cfg_safety_enable_auto_arm : in std_logic;
        cfg_safety_enable_safety_mode : in std_logic;
        
        -- Status outputs
        stat_current_state : out std_logic_vector(3 downto 0);
        stat_fault : out std_logic;
        stat_ready : out std_logic;
        stat_idle : out std_logic;
        stat_armed : out std_logic;
        stat_firing : out std_logic;
        stat_cooling : out std_logic;
        stat_status_reg : out std_logic_vector(STATUS_REG_WIDTH-1 downto 0);
        stat_alarm_reg : out std_logic_vector(ALARM_WIDTH-1 downto 0);
        stat_error_code : out std_logic_vector(ERROR_CODE_WIDTH-1 downto 0);
        
        -- Probe control outputs
        probe_voltage_out : out std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
        probe_enable_out : out std_logic;
        probe_select_out : out std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);
        
        -- Module-specific status input (connects to bits [15:0] of status register)
        module_status : in std_logic_vector(MODULE_STATUS_BITS-1 downto 0);
        
        -- Optional: Direct state machine output for debugging
        debug_state_machine : out std_logic_vector(3 downto 0)
    );
end entity probe_hero8_core;

architecture behavioral of probe_hero8_core is

    -- =========================================================================
    -- State Definitions (4-bit encoding)
    -- =========================================================================
    constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
    constant ST_ARMED      : std_logic_vector(3 downto 0) := "0011";  -- 0x3
    constant ST_FIRING     : std_logic_vector(3 downto 0) := "0100";  -- 0x4
    constant ST_COOLING    : std_logic_vector(3 downto 0) := "0101";  -- 0x5
    constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
    
    -- State machine signals
    signal current_state : std_logic_vector(3 downto 0) := ST_IDLE;
    signal next_state : std_logic_vector(3 downto 0);
    
    -- Status register and alarm register
    signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
    signal alarm_reg : std_logic_vector(ALARM_WIDTH-1 downto 0) := (others => '0');
    signal error_code_reg : std_logic_vector(ERROR_CODE_WIDTH-1 downto 0) := ERROR_NONE;
    
    -- Internal status signals
    signal fault_bit : std_logic;
    signal ready_bit : std_logic;
    signal idle_bit : std_logic;
    signal armed_bit : std_logic;
    signal firing_bit : std_logic;
    signal cooling_bit : std_logic;
    
    -- Configuration validation
    signal cfg_params_valid : std_logic;
    signal probe_config : t_probe_config;
    
    -- Timing counters
    signal firing_counter : unsigned(TIMING_WIDTH-1 downto 0) := (others => '0');
    signal cooling_counter : unsigned(TIMING_WIDTH-1 downto 0) := (others => '0');
    signal trigger_timeout_counter : unsigned(15 downto 0) := (others => '0');
    
    -- Timing constants
    constant TRIGGER_TIMEOUT : unsigned(15 downto 0) := to_unsigned(10000, 16);  -- 10k cycles timeout
    
    -- Probe control signals
    signal probe_voltage_internal : std_logic_vector(VOLTAGE_WIDTH-1 downto 0);
    signal probe_enable_internal : std_logic;
    signal probe_select_internal : std_logic_vector(PROBE_SEL_WIDTH-1 downto 0);

begin

    -- =========================================================================
    -- Configuration Record Assembly
    -- =========================================================================
    probe_config <= (
        probe_selection    => cfg_safety_probe_selection,
        firing_voltage     => cfg_safety_firing_voltage,
        firing_duration    => cfg_safety_firing_duration,
        cooling_duration   => cfg_safety_cooling_duration,
        enable_auto_arm    => cfg_safety_enable_auto_arm,
        enable_safety_mode => cfg_safety_enable_safety_mode
    );

    -- =========================================================================
    -- Parameter Validation Process
    -- =========================================================================
    parameter_validation : process(probe_config)
    begin
        -- Validate all safety-critical parameters
        if is_valid_probe_config(probe_config) then
            cfg_params_valid <= '1';
        else
            cfg_params_valid <= '0';
        end if;
    end process;

    -- =========================================================================
    -- State Machine Process
    -- =========================================================================
    state_machine_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= ST_IDLE;
            firing_counter <= (others => '0');
            cooling_counter <= (others => '0');
            trigger_timeout_counter <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;
            
            -- Update counters based on current state
            case current_state is
                when ST_FIRING =>
                    if firing_counter < unsigned(probe_config.firing_duration) then
                        firing_counter <= firing_counter + 1;
                    end if;
                    
                when ST_COOLING =>
                    if cooling_counter < unsigned(probe_config.cooling_duration) then
                        cooling_counter <= cooling_counter + 1;
                    end if;
                    
                when ST_ARMED =>
                    if trigger_timeout_counter < TRIGGER_TIMEOUT then
                        trigger_timeout_counter <= trigger_timeout_counter + 1;
                    end if;
                    
                when others =>
                    firing_counter <= (others => '0');
                    cooling_counter <= (others => '0');
                    trigger_timeout_counter <= (others => '0');
            end case;
        end if;
    end process;

    -- =========================================================================
    -- Next State Logic
    -- =========================================================================
    next_state_logic : process(current_state, ctrl_enable, ctrl_arm, ctrl_trigger, 
                              cfg_params_valid, firing_counter, cooling_counter, 
                              trigger_timeout_counter, probe_config)
    begin
        -- Default: stay in current state
        next_state <= current_state;
        
        case current_state is
            when ST_IDLE =>
                -- Check for parameter validation failure
                if cfg_params_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                -- Transition to ARMED when enabled and armed
                elsif ctrl_enable = '1' and ctrl_arm = '1' then
                    next_state <= ST_ARMED;
                end if;
                
            when ST_ARMED =>
                -- Check for parameter validation failure
                if cfg_params_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                -- Check for trigger timeout
                elsif trigger_timeout_counter >= TRIGGER_TIMEOUT then
                    next_state <= ST_HARD_FAULT;
                -- Transition to FIRING when trigger is detected
                elsif ctrl_trigger = '1' then
                    next_state <= ST_FIRING;
                -- Return to IDLE if disarm requested
                elsif ctrl_arm = '0' then
                    next_state <= ST_IDLE;
                end if;
                
            when ST_FIRING =>
                -- Check for parameter validation failure
                if cfg_params_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                -- Check for firing timeout
                elsif firing_counter >= unsigned(probe_config.firing_duration) then
                    next_state <= ST_COOLING;
                end if;
                
            when ST_COOLING =>
                -- Check for parameter validation failure
                if cfg_params_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                -- Check for cooling timeout
                elsif cooling_counter >= unsigned(probe_config.cooling_duration) then
                    next_state <= ST_IDLE;
                end if;
                
            when ST_HARD_FAULT =>
                -- HARD_FAULT state: only exit via reset
                -- This state is entered when:
                -- 1. Configuration parameters fail validation
                -- 2. Trigger timeout occurs
                -- 3. Safety-critical errors occur
                null;
                
            when others =>
                -- Invalid state: transition to HARD_FAULT
                next_state <= ST_HARD_FAULT;
        end case;
    end process;

    -- =========================================================================
    -- Status Register Update Process (clocked)
    -- =========================================================================
    status_reg_proc : process(clk, rst_n)
        variable probe_status : t_probe_status;
    begin
        if rst_n = '0' then
            status_reg <= (others => '0');
            alarm_reg <= (others => '0');
            error_code_reg <= ERROR_NONE;
        elsif rising_edge(clk) then
            -- Update alarm register with configuration validation results
            alarm_reg <= generate_config_alarms(probe_config);
            
            -- Update error code based on current conditions
            if cfg_params_valid = '0' then
                error_code_reg <= ERROR_PARAM_VALIDATION;
            elsif trigger_timeout_counter >= TRIGGER_TIMEOUT and current_state = ST_ARMED then
                error_code_reg <= ERROR_TRIGGER_TIMEOUT;
            elsif current_state = ST_HARD_FAULT then
                error_code_reg <= ERROR_SAFETY_FAULT;
            else
                error_code_reg <= ERROR_NONE;
            end if;
            
            -- Update status register with current state and module status
            status_reg(31) <= fault_bit;                                    -- FAULT bit
            status_reg(30) <= alarm_reg(0) or alarm_reg(1) or alarm_reg(2) or alarm_reg(3) or alarm_reg(4) or alarm_reg(5); -- ALARM bit
            status_reg(29) <= ready_bit;                                    -- READY bit
            status_reg(28) <= armed_bit;                                    -- ARMED bit
            status_reg(27) <= firing_bit;                                   -- FIRING bit
            status_reg(26) <= cooling_bit;                                  -- COOLING bit
            status_reg(25 downto 22) <= current_state;                     -- Current state
            status_reg(21 downto 18) <= probe_config.probe_selection;      -- Current probe selection
            status_reg(17 downto 10) <= std_logic_vector(firing_counter(7 downto 0)); -- Firing counter (8 bits)
            status_reg(9 downto 2) <= std_logic_vector(cooling_counter(7 downto 0));  -- Cooling counter (8 bits)
            status_reg(1 downto 0) <= module_status(1 downto 0);           -- Module status (2 bits)
        end if;
    end process;

    -- =========================================================================
    -- Probe Control Process
    -- =========================================================================
    probe_control_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            probe_voltage_internal <= (others => '0');
            probe_enable_internal <= '0';
            probe_select_internal <= (others => '0');
        elsif rising_edge(clk) then
            case current_state is
                when ST_FIRING =>
                    -- Set probe voltage and enable during firing
                    probe_voltage_internal <= probe_config.firing_voltage;
                    probe_enable_internal <= '1';
                    probe_select_internal <= probe_config.probe_selection;
                    
                when others =>
                    -- Disable probe in all other states
                    probe_voltage_internal <= (others => '0');
                    probe_enable_internal <= '0';
                    probe_select_internal <= probe_config.probe_selection;
            end case;
        end if;
    end process;

    -- =========================================================================
    -- Status Signal Generation
    -- =========================================================================
    fault_bit <= '1' when current_state = ST_HARD_FAULT else '0';
    ready_bit <= '1' when current_state = ST_IDLE and cfg_params_valid = '1' else '0';
    idle_bit <= '1' when current_state = ST_IDLE else '0';
    armed_bit <= '1' when current_state = ST_ARMED else '0';
    firing_bit <= '1' when current_state = ST_FIRING else '0';
    cooling_bit <= '1' when current_state = ST_COOLING else '0';

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================
    stat_current_state <= current_state;
    stat_fault <= fault_bit;
    stat_ready <= ready_bit;
    stat_idle <= idle_bit;
    stat_armed <= armed_bit;
    stat_firing <= firing_bit;
    stat_cooling <= cooling_bit;
    stat_status_reg <= status_reg;
    stat_alarm_reg <= alarm_reg;
    stat_error_code <= error_code_reg;
    
    -- Probe control outputs
    probe_voltage_out <= probe_voltage_internal;
    probe_enable_out <= probe_enable_internal;
    probe_select_out <= probe_select_internal;
    
    debug_state_machine <= current_state;

end architecture behavioral;
-- =============================================================================
-- ProbeHero8 Core Entity
-- =============================================================================
-- 
-- This is the main ProbeHero8 core implementation using enhanced packages and
-- the state machine template. It provides probe driving functionality with
-- comprehensive validation, error handling, and safety features.
--
-- Features:
-- - Enhanced package integration (Probe_Config_pkg_en, Global_Probe_Table_pkg_en, etc.)
-- - State machine with proper status register handling
-- - Comprehensive parameter validation and error handling
-- - Safe voltage output with clamping
-- - Direct instantiation ready for top-level integration
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Probe_Config_pkg_en.ALL;
use work.Global_Probe_Table_pkg_en.ALL;
use work.Moku_Voltage_pkg_en.ALL;
use work.PercentLut_pkg_en.ALL;

entity probe_hero8_core is
    generic (
        -- Module identification
        MODULE_NAME : string := "probe_hero8_core";
        
        -- Status register customization
        STATUS_REG_WIDTH : integer := 32;
        MODULE_STATUS_BITS : integer := 16  -- Bits [15:0] for module-specific status
    );
    port (
        -- Clock and reset
        clk : in std_logic;
        rst_n : in std_logic;
        
        -- Control signals
        ctrl_enable : in std_logic;
        ctrl_start : in std_logic;
        trig_in : in std_logic;  -- Trigger input signal
        
        -- Configuration parameters
        cfg_probe_selector_index : in std_logic_vector(1 downto 0);  -- Probe selection (0-3)
        cfg_intensity_index : in std_logic_vector(6 downto 0);       -- Intensity index (0-127)
        cfg_fire_duration : in std_logic_vector(15 downto 0);        -- Fire duration in clock cycles
        cfg_cooldown_duration : in std_logic_vector(15 downto 0);    -- Cooldown duration in clock cycles
        
        -- Status outputs
        stat_current_state : out std_logic_vector(3 downto 0);
        stat_fault : out std_logic;
        stat_ready : out std_logic;
        stat_idle : out std_logic;
        stat_status_reg : out std_logic_vector(STATUS_REG_WIDTH-1 downto 0);
        
        -- Module-specific status input (connects to bits [15:0] of status register)
        module_status : in std_logic_vector(MODULE_STATUS_BITS-1 downto 0);
        
        -- Probe outputs
        trigger_out : out std_logic_vector(15 downto 0);  -- Trigger voltage output
        intensity_out : out std_logic_vector(15 downto 0); -- Intensity voltage output
        
        -- Optional: Direct state machine output for debugging
        debug_state_machine : out std_logic_vector(3 downto 0)
    );
end entity probe_hero8_core;

architecture behavioral of probe_hero8_core is

    -- =========================================================================
    -- State Definitions (4-bit encoding)
    -- =========================================================================
    constant ST_RESET      : std_logic_vector(3 downto 0) := "0000";  -- 0x0
    constant ST_READY      : std_logic_vector(3 downto 0) := "0001";  -- 0x1
    constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
    constant ST_ARMED      : std_logic_vector(3 downto 0) := "0011";  -- 0x3
    constant ST_FIRING     : std_logic_vector(3 downto 0) := "0100";  -- 0x4
    constant ST_COOLING    : std_logic_vector(3 downto 0) := "0101";  -- 0x5
    constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
    
    -- State machine signals
    signal current_state : std_logic_vector(3 downto 0) := ST_RESET;
    signal next_state : std_logic_vector(3 downto 0);
    
    -- Status register
    signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
    
    -- Internal status signals
    signal fault_bit : std_logic;
    signal ready_bit : std_logic;
    signal idle_bit : std_logic;
    signal cfg_param_valid : std_logic;
    signal alarm_bit : std_logic;
    
    -- Probe configuration signals
    signal current_probe_config : t_probe_config;
    signal probe_config_valid : std_logic;
    
    -- Timing signals
    signal fire_timer : unsigned(15 downto 0);
    signal cooldown_timer : unsigned(15 downto 0);
    signal fire_duration_clamped : unsigned(15 downto 0);
    signal cooldown_duration_clamped : unsigned(15 downto 0);
    
    -- Voltage output signals
    signal trigger_voltage_out : std_logic_vector(15 downto 0);
    signal intensity_voltage_out : std_logic_vector(15 downto 0);
    
    -- Trigger detection
    signal trig_in_prev : std_logic;
    signal trig_rising_edge : std_logic;
    
    -- Global probe table
    signal global_probe_table : t_global_probe_table;
    signal percent_lut_data : t_percent_lut_data;

begin

    -- =========================================================================
    -- Global Probe Table and PercentLut Initialization
    -- =========================================================================
    global_probe_table <= DEFAULT_GLOBAL_PROBE_TABLE;
    percent_lut_data <= DEFAULT_LINEAR_PERCENT_LUT;

    -- =========================================================================
    -- Parameter Validation Process
    -- =========================================================================
    parameter_validation : process(cfg_probe_selector_index, cfg_intensity_index, 
                                  cfg_fire_duration, cfg_cooldown_duration,
                                  current_probe_config, probe_config_valid)
        variable probe_index : natural;
        variable intensity_index : natural;
        variable fire_duration_unsigned : unsigned(15 downto 0);
        variable cooldown_duration_unsigned : unsigned(15 downto 0);
        variable validation_passed : boolean := true;
        variable alarm_condition : boolean := false;
    begin
        -- Initialize validation
        validation_passed := true;
        alarm_condition := false;
        
        -- Validate probe selector index
        probe_index := to_integer(unsigned(cfg_probe_selector_index));
        if not is_valid_probe_table_index(global_probe_table, probe_index) then
            validation_passed := false;
        end if;
        
        -- Validate intensity index
        intensity_index := to_integer(unsigned(cfg_intensity_index));
        if not is_valid_percent_index(intensity_index) then
            validation_passed := false;
        end if;
        
        -- Validate and clamp durations if probe config is valid
        if probe_config_valid = '1' then
            fire_duration_unsigned := unsigned(cfg_fire_duration);
            cooldown_duration_unsigned := unsigned(cfg_cooldown_duration);
            
            -- Clamp fire duration
            fire_duration_clamped <= clamp_duration(fire_duration_unsigned, 
                                                   current_probe_config.fire_duration_min,
                                                   current_probe_config.fire_duration_max);
            
            -- Clamp cooldown duration
            cooldown_duration_clamped <= clamp_duration(cooldown_duration_unsigned,
                                                       current_probe_config.cooldown_duration_min,
                                                       current_probe_config.cooldown_duration_max);
            
            -- Check if clamping occurred (alarm condition)
            if fire_duration_unsigned /= fire_duration_clamped or 
               cooldown_duration_unsigned /= cooldown_duration_clamped then
                alarm_condition := true;
            end if;
        else
            -- Use default values if probe config is invalid
            fire_duration_clamped <= to_unsigned(100, 16);
            cooldown_duration_clamped <= to_unsigned(1000, 16);
        end if;
        
        -- Set validation and alarm signals
        cfg_param_valid <= '1' when validation_passed else '0';
        alarm_bit <= '1' when alarm_condition else '0';
    end process;

    -- =========================================================================
    -- Probe Configuration Selection Process
    -- =========================================================================
    probe_config_selection : process(cfg_probe_selector_index, global_probe_table)
        variable probe_index : natural;
    begin
        probe_index := to_integer(unsigned(cfg_probe_selector_index));
        current_probe_config <= get_probe_from_table_safe(global_probe_table, probe_index);
        probe_config_valid <= '1' when is_valid_probe_table_index(global_probe_table, probe_index) else '0';
    end process;

    -- =========================================================================
    -- Trigger Detection Process
    -- =========================================================================
    trigger_detection : process(clk, rst_n)
    begin
        if rst_n = '0' then
            trig_in_prev <= '0';
            trig_rising_edge <= '0';
        elsif rising_edge(clk) then
            trig_in_prev <= trig_in;
            trig_rising_edge <= trig_in and not trig_in_prev;
        end if;
    end process;

    -- =========================================================================
    -- State Machine Process
    -- =========================================================================
    state_machine_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= ST_RESET;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- =========================================================================
    -- Next State Logic
    -- =========================================================================
    next_state_logic : process(current_state, ctrl_enable, cfg_param_valid, ctrl_start, 
                               trig_rising_edge, fire_timer, cooldown_timer)
    begin
        -- Default: stay in current state
        next_state <= current_state;
        
        case current_state is
            when ST_RESET =>
                -- Transition to READY when enabled and parameters are valid
                if ctrl_enable = '1' and cfg_param_valid = '1' then
                    next_state <= ST_READY;
                end if;
                
            when ST_READY =>
                -- Transition to IDLE when start is asserted
                if ctrl_start = '1' then
                    next_state <= ST_IDLE;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_IDLE =>
                -- Transition to ARMED when enabled
                if ctrl_enable = '1' then
                    next_state <= ST_ARMED;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_ARMED =>
                -- Transition to FIRING on trigger
                if trig_rising_edge = '1' then
                    next_state <= ST_FIRING;
                -- Transition to IDLE if disabled
                elsif ctrl_enable = '0' then
                    next_state <= ST_IDLE;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_FIRING =>
                -- Transition to COOLING when fire timer expires
                if fire_timer = 0 then
                    next_state <= ST_COOLING;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_COOLING =>
                -- Transition to ARMED when cooldown timer expires
                if cooldown_timer = 0 then
                    next_state <= ST_ARMED;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_HARD_FAULT =>
                -- HARD_FAULT state: only exit via reset
                null;
                
            when others =>
                -- Invalid state: transition to HARD_FAULT
                next_state <= ST_HARD_FAULT;
        end case;
    end process;

    -- =========================================================================
    -- Timer Management Process
    -- =========================================================================
    timer_management : process(clk, rst_n)
    begin
        if rst_n = '0' then
            fire_timer <= (others => '0');
            cooldown_timer <= (others => '0');
        elsif rising_edge(clk) then
            case current_state is
                when ST_FIRING =>
                    if fire_timer > 0 then
                        fire_timer <= fire_timer - 1;
                    end if;
                    -- Initialize cooldown timer when entering COOLING state
                    if next_state = ST_COOLING then
                        cooldown_timer <= cooldown_duration_clamped;
                    end if;
                    
                when ST_COOLING =>
                    if cooldown_timer > 0 then
                        cooldown_timer <= cooldown_timer - 1;
                    end if;
                    
                when ST_ARMED =>
                    -- Initialize fire timer when entering FIRING state
                    if next_state = ST_FIRING then
                        fire_timer <= fire_duration_clamped;
                    end if;
                    
                when others =>
                    -- Reset timers in other states
                    fire_timer <= (others => '0');
                    cooldown_timer <= (others => '0');
            end case;
        end if;
    end process;

    -- =========================================================================
    -- Voltage Output Generation Process
    -- =========================================================================
    voltage_output_generation : process(current_state, current_probe_config, cfg_intensity_index, 
                                       percent_lut_data, probe_config_valid)
        variable intensity_index : natural;
        variable intensity_voltage : std_logic_vector(15 downto 0);
    begin
        if current_state = ST_FIRING and probe_config_valid = '1' then
            -- Set trigger voltage
            trigger_voltage_out <= current_probe_config.probe_trigger_voltage;
            
            -- Calculate intensity voltage from lookup table
            intensity_index := to_integer(unsigned(cfg_intensity_index));
            intensity_voltage := get_percent_lut_value_safe(percent_lut_data, intensity_index);
            
            -- Clamp intensity voltage to probe limits
            intensity_voltage_out <= clamp_voltage(intensity_voltage,
                                                  current_probe_config.probe_intensity_min,
                                                  current_probe_config.probe_intensity_max);
        else
            -- Safe outputs when not firing
            trigger_voltage_out <= (others => '0');
            intensity_voltage_out <= (others => '0');
        end if;
    end process;

    -- =========================================================================
    -- Status Register Update Process (clocked)
    -- =========================================================================
    status_reg_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            status_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Update status register with current state and module status
            status_reg(31) <= fault_bit;                                    -- FAULT bit
            status_reg(30) <= alarm_bit;                                    -- ALARM bit
            status_reg(29 downto 28) <= (others => '0');                   -- Reserved
            status_reg(27 downto 24) <= current_state;                     -- Current state
            status_reg(23 downto 16) <= (others => '0');                   -- Reserved
            status_reg(MODULE_STATUS_BITS-1 downto 0) <= module_status;    -- Module status
        end if;
    end process;

    -- =========================================================================
    -- Status Signal Generation
    -- =========================================================================
    fault_bit <= '1' when current_state = ST_HARD_FAULT else '0';
    ready_bit <= '1' when current_state = ST_READY else '0';
    idle_bit <= '1' when current_state = ST_IDLE else '0';

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================
    stat_current_state <= current_state;
    stat_fault <= fault_bit;
    stat_ready <= ready_bit;
    stat_idle <= idle_bit;
    stat_status_reg <= status_reg;
    debug_state_machine <= current_state;
    
    -- Probe outputs
    trigger_out <= trigger_voltage_out;
    intensity_out <= intensity_voltage_out;

end architecture behavioral;
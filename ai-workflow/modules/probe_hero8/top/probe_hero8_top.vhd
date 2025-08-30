-- =============================================================================
-- ProbeHero8 Top-Level Integration Module
-- =============================================================================
-- 
-- This top-level module integrates the ProbeHero8 core with the platform
-- control system. It provides the external interface for platform control
-- and exposes appropriate control, configuration, and status registers.
--
-- Features:
-- - Direct instantiation of core module (required for top layer)
-- - External interface for platform control system
-- - Register exposure for control, configuration, and status
-- - System-level integration and validation
-- - Clean separation from MCC CustomWrapper entity body
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Probe_Config_pkg_en.ALL;
use work.Global_Probe_Table_pkg_en.ALL;
use work.Moku_Voltage_pkg_en.ALL;
use work.PercentLut_pkg_en.ALL;

entity probe_hero8_top is
    generic (
        -- Module identification
        MODULE_NAME : string := "probe_hero8_top";
        
        -- Status register customization
        STATUS_REG_WIDTH : integer := 32;
        MODULE_STATUS_BITS : integer := 16
    );
    port (
        -- Clock and reset
        clk : in std_logic;
        rst_n : in std_logic;
        
        -- External control interface (platform control system)
        ext_enable : in std_logic;                    -- External enable signal
        ext_start : in std_logic;                     -- External start signal
        ext_trigger : in std_logic;                   -- External trigger signal
        
        -- External configuration interface
        ext_probe_selector : in std_logic_vector(1 downto 0);    -- External probe selection
        ext_intensity_index : in std_logic_vector(6 downto 0);   -- External intensity index
        ext_fire_duration : in std_logic_vector(15 downto 0);    -- External fire duration
        ext_cooldown_duration : in std_logic_vector(15 downto 0); -- External cooldown duration
        
        -- External status interface
        ext_status_register : out std_logic_vector(31 downto 0); -- External status register
        ext_fault_status : out std_logic;                        -- External fault status
        ext_ready_status : out std_logic;                        -- External ready status
        ext_idle_status : out std_logic;                         -- External idle status
        
        -- External probe output interface
        ext_trigger_output : out std_logic_vector(15 downto 0);  -- External trigger output
        ext_intensity_output : out std_logic_vector(15 downto 0); -- External intensity output
        
        -- Optional: External debug interface
        ext_debug_state : out std_logic_vector(3 downto 0)       -- External debug state
    );
end entity probe_hero8_top;

architecture behavioral of probe_hero8_top is

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================
    
    -- Core module control signals
    signal ctrl_enable : std_logic;
    signal ctrl_start : std_logic;
    signal trig_in : std_logic;
    
    -- Core module configuration signals
    signal cfg_probe_selector_index : std_logic_vector(1 downto 0);
    signal cfg_intensity_index : std_logic_vector(6 downto 0);
    signal cfg_fire_duration : std_logic_vector(15 downto 0);
    signal cfg_cooldown_duration : std_logic_vector(15 downto 0);
    
    -- Core module status signals
    signal stat_current_state : std_logic_vector(3 downto 0);
    signal stat_fault : std_logic;
    signal stat_ready : std_logic;
    signal stat_idle : std_logic;
    signal stat_status_reg : std_logic_vector(31 downto 0);
    
    -- Core module output signals
    signal trigger_out : std_logic_vector(15 downto 0);
    signal intensity_out : std_logic_vector(15 downto 0);
    
    -- Core module debug signals
    signal debug_state_machine : std_logic_vector(3 downto 0);
    
    -- Internal module status
    signal module_status : std_logic_vector(15 downto 0);
    
    -- =========================================================================
    -- Configuration Validation Signals
    -- =========================================================================
    signal config_valid : std_logic;
    signal config_alarm : std_logic;
    
    -- =========================================================================
    -- System Integration Signals
    -- =========================================================================
    signal system_ready : std_logic;
    signal system_fault : std_logic;

begin

    -- =========================================================================
    -- Direct Instantiation of Core Module (REQUIRED for top layer)
    -- =========================================================================
    -- This MUST use direct instantiation according to VOLO standards
    probe_hero8_core_inst: entity WORK.probe_hero8_core
        generic map (
            MODULE_NAME => "probe_hero8_core",
            STATUS_REG_WIDTH => STATUS_REG_WIDTH,
            MODULE_STATUS_BITS => MODULE_STATUS_BITS
        )
        port map (
            -- Clock and reset
            clk => clk,
            rst_n => rst_n,
            
            -- Control signals
            ctrl_enable => ctrl_enable,
            ctrl_start => ctrl_start,
            trig_in => trig_in,
            
            -- Configuration parameters
            cfg_probe_selector_index => cfg_probe_selector_index,
            cfg_intensity_index => cfg_intensity_index,
            cfg_fire_duration => cfg_fire_duration,
            cfg_cooldown_duration => cfg_cooldown_duration,
            
            -- Status outputs
            stat_current_state => stat_current_state,
            stat_fault => stat_fault,
            stat_ready => stat_ready,
            stat_idle => stat_idle,
            stat_status_reg => stat_status_reg,
            
            -- Module status input
            module_status => module_status,
            
            -- Probe outputs
            trigger_out => trigger_out,
            intensity_out => intensity_out,
            
            -- Debug output
            debug_state_machine => debug_state_machine
        );

    -- =========================================================================
    -- External Interface Mapping
    -- =========================================================================
    
    -- Control signal mapping
    ctrl_enable <= ext_enable;
    ctrl_start <= ext_start;
    trig_in <= ext_trigger;
    
    -- Configuration signal mapping with validation
    cfg_probe_selector_index <= ext_probe_selector;
    cfg_intensity_index <= ext_intensity_index;
    cfg_fire_duration <= ext_fire_duration;
    cfg_cooldown_duration <= ext_cooldown_duration;
    
    -- Status signal mapping
    ext_status_register <= stat_status_reg;
    ext_fault_status <= stat_fault;
    ext_ready_status <= stat_ready;
    ext_idle_status <= stat_idle;
    
    -- Output signal mapping
    ext_trigger_output <= trigger_out;
    ext_intensity_output <= intensity_out;
    
    -- Debug signal mapping
    ext_debug_state <= debug_state_machine;

    -- =========================================================================
    -- Configuration Validation Process
    -- =========================================================================
    -- This process validates external configuration parameters and sets
    -- appropriate alarm conditions for the platform control system
    config_validation : process(ext_probe_selector, ext_intensity_index, 
                               ext_fire_duration, ext_cooldown_duration)
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
        probe_index := to_integer(unsigned(ext_probe_selector));
        if not is_valid_probe_table_index(DEFAULT_GLOBAL_PROBE_TABLE, probe_index) then
            validation_passed := false;
        end if;
        
        -- Validate intensity index
        intensity_index := to_integer(unsigned(ext_intensity_index));
        if not is_valid_percent_index(intensity_index) then
            validation_passed := false;
        end if;
        
        -- Validate duration ranges (basic sanity checks)
        fire_duration_unsigned := unsigned(ext_fire_duration);
        cooldown_duration_unsigned := unsigned(ext_cooldown_duration);
        
        -- Check for reasonable duration ranges
        if fire_duration_unsigned = 0 or fire_duration_unsigned > 10000 then
            alarm_condition := true;
        end if;
        
        if cooldown_duration_unsigned = 0 or cooldown_duration_unsigned > 50000 then
            alarm_condition := true;
        end if;
        
        -- Set validation and alarm signals
        config_valid <= '1' when validation_passed else '0';
        config_alarm <= '1' when alarm_condition else '0';
    end process;

    -- =========================================================================
    -- System Integration Process
    -- =========================================================================
    -- This process manages system-level status and integration
    system_integration : process(clk, rst_n)
    begin
        if rst_n = '0' then
            system_ready <= '0';
            system_fault <= '0';
            module_status <= (others => '0');
        elsif rising_edge(clk) then
            -- Update system ready status
            system_ready <= stat_ready and config_valid;
            
            -- Update system fault status
            system_fault <= stat_fault or not config_valid;
            
            -- Update module status register
            module_status(15) <= system_fault;           -- System fault bit
            module_status(14) <= config_alarm;           -- Configuration alarm bit
            module_status(13) <= system_ready;           -- System ready bit
            module_status(12) <= config_valid;           -- Configuration valid bit
            module_status(11 downto 8) <= stat_current_state; -- Current state
            module_status(7 downto 0) <= (others => '0'); -- Reserved
        end if;
    end process;

    -- =========================================================================
    -- Output Signal Assignments
    -- =========================================================================
    -- Additional output assignments for system integration
    
    -- Enhanced status outputs with system-level information
    -- (These are already mapped above, but can be enhanced here if needed)

end architecture behavioral;
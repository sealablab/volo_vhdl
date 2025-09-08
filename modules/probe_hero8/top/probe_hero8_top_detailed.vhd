-- ProbeHero8 Top-Level Integration - Detailed Approach
-- Comprehensive system integration with all enhanced rules system patterns
-- Implements: SIG-01, SIG-02, SIG-03, STD-01

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity probe_hero8_top_detailed is
    generic (
        -- Configuration parameters with comprehensive defaults
        DEFAULT_FIRE_DURATION     : unsigned(15 downto 0) := to_unsigned(1000, 16);
        DEFAULT_COOLDOWN_DURATION : unsigned(15 downto 0) := to_unsigned(1000, 16);
        DEFAULT_INTENSITY_INDEX   : std_logic_vector(6 downto 0) := "0000101";
        DEFAULT_PROBE_SELECTOR    : std_logic_vector(1 downto 0) := "00";
        
        -- Timing constraints (comprehensive timing support)
        MAX_FIRE_DURATION         : unsigned(15 downto 0) := to_unsigned(65535, 16);
        MIN_FIRE_DURATION         : unsigned(15 downto 0) := to_unsigned(1, 16);
        MAX_COOLDOWN_DURATION     : unsigned(15 downto 0) := to_unsigned(65535, 16);
        MIN_COOLDOWN_DURATION     : unsigned(15 downto 0) := to_unsigned(1, 16)
    );
    port (
        -- System interface (comprehensive system integration)
        clk                     : in  std_logic;
        rst_n                   : in  std_logic;
        
        -- Control interface (ctrl_ prefix for control signals)
        ctrl_enable             : in  std_logic;
        ctrl_clk_en             : in  std_logic;
        ctrl_trig_in            : in  std_logic;
        
        -- Configuration interface (cfg_ prefix for configuration signals)
        cfg_probe_selector_in   : in  std_logic_vector(1 downto 0);
        cfg_intensity_index_in  : in  std_logic_vector(6 downto 0);
        cfg_fire_duration_in    : in  unsigned(15 downto 0);
        cfg_cooldown_duration_in: in  unsigned(15 downto 0);
        
        -- Output interface (comprehensive output support)
        trigger_out             : out signed(15 downto 0);
        intensity_out           : out signed(15 downto 0);
        
        -- Status interface (stat_ prefix for status signals)
        stat_probe_status_out   : out std_logic_vector(7 downto 0);
        
        -- Additional status outputs (comprehensive status reporting)
        stat_system_ready       : out std_logic;
        stat_config_valid       : out std_logic;
        stat_operational_mode   : out std_logic_vector(1 downto 0)
    );
end entity probe_hero8_top_detailed;

architecture comprehensive_integration of probe_hero8_top_detailed is
    
    -- Internal signals (SIG-01: Single-writer for signals)
    signal core_enable                  : std_logic;
    signal core_clk_en                  : std_logic;
    signal core_trig_in                 : std_logic;
    signal core_cfg_probe_selector_in   : std_logic_vector(1 downto 0);
    signal core_cfg_intensity_index_in  : std_logic_vector(6 downto 0);
    signal core_cfg_fire_duration_in    : unsigned(15 downto 0);
    signal core_cfg_cooldown_duration_in: unsigned(15 downto 0);
    signal core_trigger_out             : signed(15 downto 0);
    signal core_intensity_out           : signed(15 downto 0);
    signal core_stat_probe_status_out   : std_logic_vector(7 downto 0);
    
    -- Configuration validation signals (comprehensive validation)
    signal cfg_probe_valid              : std_logic;
    signal cfg_intensity_valid          : std_logic;
    signal cfg_fire_duration_valid      : std_logic;
    signal cfg_cooldown_duration_valid  : std_logic;
    signal all_config_valid             : std_logic;
    
    -- System status signals (comprehensive status tracking)
    signal system_ready                 : std_logic;
    signal operational_mode             : std_logic_vector(1 downto 0);
    
    -- Constants for operational modes (STD-01: Use portable subset for Verilog)
    constant MODE_IDLE      : std_logic_vector(1 downto 0) := "00";
    constant MODE_ARMED     : std_logic_vector(1 downto 0) := "01";
    constant MODE_FIRING    : std_logic_vector(1 downto 0) := "10";
    constant MODE_FAULT     : std_logic_vector(1 downto 0) := "11";
    
begin
    
    -- SIG-02: Named association for all port mappings
    -- Direct instantiation of core module (required for top layer)
    core_inst: entity work.probe_hero8_core_detailed
        generic map (
            DEFAULT_FIRE_DURATION      => DEFAULT_FIRE_DURATION,
            DEFAULT_COOLDOWN_DURATION  => DEFAULT_COOLDOWN_DURATION,
            DEFAULT_INTENSITY_INDEX    => DEFAULT_INTENSITY_INDEX,
            DEFAULT_PROBE_SELECTOR     => DEFAULT_PROBE_SELECTOR,
            MAX_FIRE_DURATION          => MAX_FIRE_DURATION,
            MIN_FIRE_DURATION          => MIN_FIRE_DURATION,
            MAX_COOLDOWN_DURATION      => MAX_COOLDOWN_DURATION,
            MIN_COOLDOWN_DURATION      => MIN_COOLDOWN_DURATION
        )
        port map (
            -- Clock and reset
            clk                        => clk,
            rst_n                      => rst_n,
            
            -- Control signals
            enable                     => core_enable,
            clk_en                     => core_clk_en,
            trig_in                    => core_trig_in,
            
            -- Configuration signals
            cfg_probe_selector_in      => core_cfg_probe_selector_in,
            cfg_intensity_index_in     => core_cfg_intensity_index_in,
            cfg_fire_duration_in       => core_cfg_fire_duration_in,
            cfg_cooldown_duration_in   => core_cfg_cooldown_duration_in,
            
            -- Output signals
            trigger_out                => core_trigger_out,
            intensity_out              => core_intensity_out,
            stat_probe_status_out      => core_stat_probe_status_out
        );
    
    -- Configuration validation (comprehensive validation logic)
    cfg_probe_valid <= '1' when cfg_probe_selector_in = "00" or cfg_probe_selector_in = "01" or 
                               cfg_probe_selector_in = "10" or cfg_probe_selector_in = "11" else '0';
    
    cfg_intensity_valid <= '1' when unsigned(cfg_intensity_index_in) < 128 else '0';
    
    cfg_fire_duration_valid <= '1' when cfg_fire_duration_in >= MIN_FIRE_DURATION and 
                                        cfg_fire_duration_in <= MAX_FIRE_DURATION else '0';
    
    cfg_cooldown_duration_valid <= '1' when cfg_cooldown_duration_in >= MIN_COOLDOWN_DURATION and 
                                            cfg_cooldown_duration_in <= MAX_COOLDOWN_DURATION else '0';
    
    all_config_valid <= cfg_probe_valid and cfg_intensity_valid and 
                       cfg_fire_duration_valid and cfg_cooldown_duration_valid;
    
    -- Signal routing and buffering (SIG-01: Single-writer for signals)
    -- Control signal routing
    core_enable <= ctrl_enable;
    core_clk_en <= ctrl_clk_en;
    core_trig_in <= ctrl_trig_in;
    
    -- Configuration signal routing
    core_cfg_probe_selector_in <= cfg_probe_selector_in;
    core_cfg_intensity_index_in <= cfg_intensity_index_in;
    core_cfg_fire_duration_in <= cfg_fire_duration_in;
    core_cfg_cooldown_duration_in <= cfg_cooldown_duration_in;
    
    -- Output signal routing
    trigger_out <= core_trigger_out;
    intensity_out <= core_intensity_out;
    stat_probe_status_out <= core_stat_probe_status_out;
    
    -- System status generation (comprehensive status reporting)
    system_ready <= all_config_valid and (not core_stat_probe_status_out(7)); -- Not in fault state
    stat_system_ready <= system_ready;
    stat_config_valid <= all_config_valid;
    
    -- Operational mode determination (comprehensive mode tracking)
    operational_mode <= MODE_FAULT when core_stat_probe_status_out(7) = '1' else  -- FAULT bit
                       MODE_FIRING when core_stat_probe_status_out(1) = '1' else  -- FIRING bit
                       MODE_ARMED when core_stat_probe_status_out(0) = '1' else   -- ARMED bit
                       MODE_IDLE;                                                 -- Default
    stat_operational_mode <= operational_mode;
    
end architecture comprehensive_integration;
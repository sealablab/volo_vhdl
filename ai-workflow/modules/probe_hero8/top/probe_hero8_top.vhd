-- ProbeHero8 Top-Level Integration
-- Integrates core module with system-level interface
-- Implements enhanced rules system pattern: SIG-02 (named association)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity probe_hero8_top is
    generic (
        -- Configuration parameters
        DEFAULT_FIRE_DURATION     : unsigned(15 downto 0) := to_unsigned(1000, 16);
        DEFAULT_COOLDOWN_DURATION : unsigned(15 downto 0) := to_unsigned(1000, 16);
        DEFAULT_INTENSITY_INDEX   : std_logic_vector(6 downto 0) := "0000101";
        DEFAULT_PROBE_SELECTOR    : std_logic_vector(1 downto 0) := "00"
    );
    port (
        -- System interface
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
        
        -- Output interface
        trigger_out             : out signed(15 downto 0);
        intensity_out           : out signed(15 downto 0);
        
        -- Status interface (stat_ prefix for status signals)
        stat_probe_status_out   : out std_logic_vector(7 downto 0)
    );
end entity probe_hero8_top;

architecture behavioral of probe_hero8_top is
    
    -- Internal signals for core module connection
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
    
begin
    
    -- SIG-02: Named association for all port mappings
    -- Direct instantiation of core module (required for top layer)
    core_inst: entity work.probe_hero8_core
        generic map (
            DEFAULT_FIRE_DURATION      => DEFAULT_FIRE_DURATION,
            DEFAULT_COOLDOWN_DURATION  => DEFAULT_COOLDOWN_DURATION,
            DEFAULT_INTENSITY_INDEX    => DEFAULT_INTENSITY_INDEX,
            DEFAULT_PROBE_SELECTOR     => DEFAULT_PROBE_SELECTOR
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
    
    -- Signal routing and buffering
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
    
end architecture behavioral;
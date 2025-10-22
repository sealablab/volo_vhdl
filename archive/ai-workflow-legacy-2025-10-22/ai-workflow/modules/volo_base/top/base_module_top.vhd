-- Volo Base Module Top-Level Integration
-- Integrates core module with system-level interface
-- Implements enhanced rules system pattern: SIG-02 (named association)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;

entity base_module_top is
    generic (
        -- Configuration parameters
        ALARM_THRESHOLD         : natural := 3  -- Number of clocks from bottom to trigger alarm
    );
    port (
        -- System interface
        clk                     : in  std_logic;
        rst_n                   : in  std_logic;
        
        -- Control interface (ctrl_ prefix for control signals)
        ctrl_enable             : in  std_logic;
        ctrl_clk_en             : in  std_logic;
        
        -- Input interface
        counter_in              : in  std_logic_vector(15 downto 0);
        
        -- Status interface (stat_ prefix for status signals)
        stat_status_out         : out std_logic_vector(7 downto 0)
    );
end entity base_module_top;

architecture behavioral of base_module_top is
    
    -- Internal signals for core module connection
    signal core_enable                  : std_logic;
    signal core_clk_en                  : std_logic;
    signal core_counter_in              : std_logic_vector(15 downto 0);
    signal core_stat_status_out         : std_logic_vector(7 downto 0);
    
begin
    
    -- SIG-02: Named association for all port mappings
    -- Direct instantiation of core module (required for top layer)
    core_inst: entity work.base_module_core
        generic map (
            ALARM_THRESHOLD            => ALARM_THRESHOLD
        )
        port map (
            -- Clock and reset
            clk                        => clk,
            rst_n                      => rst_n,
            
            -- Control signals
            enable                     => core_enable,
            clk_en                     => core_clk_en,
            
            -- Input interface
            counter_in                 => core_counter_in,
            
            -- Output signals
            stat_status_out            => core_stat_status_out
        );
    
    -- Signal routing and buffering
    -- Control signal routing
    core_enable <= ctrl_enable;
    core_clk_en <= ctrl_clk_en;
    
    -- Input signal routing
    core_counter_in <= counter_in;
    
    -- Output signal routing
    stat_status_out <= core_stat_status_out;
    
end architecture behavioral;
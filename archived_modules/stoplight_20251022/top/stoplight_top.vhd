-- Stoplight Top-Level Module
-- Integrates stoplight_core with clock divider and provides register-based interface
-- Implements register interface per platform_interface_pkg.vhd specification
-- Provides external interface for platform control system integration

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import packages
library WORK;
use WORK.volo_common_pkg.ALL;
use WORK.stoplight_constants_pkg.ALL;
use WORK.platform_interface_pkg.ALL;

entity stoplight_top is
    port (
        -- System Interface
        clk         : in  std_logic;                    -- System clock input
        rst         : in  std_logic;                    -- Synchronous reset (active high)
        
        -- Register Interface (32-bit registers)
        stoplight_ctrl_wr     : in  std_logic;                    -- Stoplight control register write enable
        stoplight_ctrl_data   : in  std_logic_vector(31 downto 0); -- Stoplight control register data (enable + clock divider)
        stoplight_cfg_wr      : in  std_logic;                    -- Stoplight configuration register write enable
        stoplight_cfg_data    : in  std_logic_vector(31 downto 0); -- Stoplight configuration data (timing parameters)
        
        -- Register Read Interface
        stoplight_status_rd   : out std_logic_vector(31 downto 0); -- Stoplight status register
        stoplight_state_rd    : out std_logic_vector(31 downto 0); -- Current state and countdown
        
        -- External Interface
        trig_in     : in  std_logic;                    -- External trigger input
        light_red   : out std_logic;                    -- Red light output
        light_yellow: out std_logic;                    -- Yellow light output
        light_green : out std_logic;                    -- Green light output
        fault_out   : out std_logic                     -- Global fault output
    );
end entity stoplight_top;

architecture rtl of stoplight_top is
    
    -- ============================================================================
    -- INTERNAL SIGNALS
    -- ============================================================================
    
    -- Register interface signals
    signal ctrl_global_enable    : std_logic;
    signal cfg_clk_div_sel       : std_logic_vector(3 downto 0);
    signal cfg_red_delay         : std_logic_vector(15 downto 0);
    signal cfg_yellow_delay      : std_logic_vector(15 downto 0);
    signal cfg_green_delay       : std_logic_vector(15 downto 0);
    
    -- Clock divider interface
    signal clk_en                : std_logic;
    signal clk_div_stat          : std_logic_vector(7 downto 0);
    
    -- Stoplight core interface
    signal core_stat_status_out  : std_logic_vector(7 downto 0);
    signal core_trig_in          : std_logic;
    
    -- State and countdown signals
    signal current_state         : std_logic_vector(2 downto 0);
    signal countdown_value       : std_logic_vector(15 downto 0);
    
    -- Light outputs
    signal light_red_int         : std_logic;
    signal light_yellow_int      : std_logic;
    signal light_green_int       : std_logic;
    
    -- Fault detection
    signal fault_condition       : std_logic;
    
begin
    
    -- ============================================================================
    -- REGISTER INTERFACE
    -- ============================================================================
    
    -- Control register (32-bit)
    -- Bit 31: Global enable
    -- Bits 30-27: Clock divider selection (4 bits)
    -- Bits 26-0: Reserved
    process(clk, rst)
    begin
        if rst = '1' then
            ctrl_global_enable <= '0';
            cfg_clk_div_sel <= (others => '0');
        elsif rising_edge(clk) then
            if stoplight_ctrl_wr = '1' then
                ctrl_global_enable <= stoplight_ctrl_data(31);
                cfg_clk_div_sel <= stoplight_ctrl_data(30 downto 27);
            end if;
        end if;
    end process;
    
    -- Configuration register (32-bit)
    -- Bits 31-16: Red delay (16 bits)
    -- Bits 15-0: Yellow delay (16 bits)
    -- Note: Green delay uses separate register (extended interface)
    process(clk, rst)
    begin
        if rst = '1' then
            cfg_red_delay <= (others => '0');
            cfg_yellow_delay <= (others => '0');
            cfg_green_delay <= x"7530"; -- Default 30000
        elsif rising_edge(clk) then
            if stoplight_cfg_wr = '1' then
                cfg_red_delay <= stoplight_cfg_data(31 downto 16);
                cfg_yellow_delay <= stoplight_cfg_data(15 downto 0);
                -- Green delay fixed at 30000 for now (can be extended)
                cfg_green_delay <= x"7530";
            end if;
        end if;
    end process;
    
    -- ============================================================================
    -- CLOCK DIVIDER INSTANTIATION
    -- ============================================================================
    
    -- Direct instantiation of clk_divider_core (required by VOLO standards)
    u_clk_divider: entity work.clk_divider_core
        generic map (
            MAX_DIV => 256
        )
        port map (
            clk         => clk,
            rst_n       => not rst,
            enable      => ctrl_global_enable,  -- Use global enable to control divider
            div_sel     => x"0" & cfg_clk_div_sel,  -- Extend 4-bit to 8-bit
            clk_en      => clk_en,
            stat_reg    => clk_div_stat
        );
    
    -- Clock enable comes directly from clock divider
    -- No additional processing needed
    
    -- ============================================================================
    -- STOPLIGHT CORE INSTANTIATION
    -- ============================================================================
    
    -- Direct instantiation of stoplight_core (required by VOLO standards)
    u_stoplight_core: entity work.stoplight_core
        port map (
            clk                 => clk,
            rst_n               => not rst,
            enable              => ctrl_global_enable,
            clk_en              => clk_en,
            trig_in             => core_trig_in,
            cfg_red_delay       => cfg_red_delay,
            cfg_yellow_delay    => cfg_yellow_delay,
            cfg_green_delay     => cfg_green_delay,
            stat_status_out     => core_stat_status_out
        );
    
    -- ============================================================================
    -- EXTERNAL INTERFACE
    -- ============================================================================
    
    -- External trigger input
    core_trig_in <= trig_in;
    
    -- Light outputs based on status register
    light_red_int <= core_stat_status_out(STATUS_RED_BIT);
    light_yellow_int <= core_stat_status_out(STATUS_YELLOW_BIT);
    light_green_int <= core_stat_status_out(STATUS_GREEN_BIT);
    
    -- Light outputs (registered for clean timing)
    process(clk, rst)
    begin
        if rst = '1' then
            light_red <= '0';
            light_yellow <= '0';
            light_green <= '0';
        elsif rising_edge(clk) then
            if clk_en = '1' then
                light_red <= light_red_int;
                light_yellow <= light_yellow_int;
                light_green <= light_green_int;
            end if;
        end if;
    end process;
    
    -- ============================================================================
    -- STATE AND COUNTDOWN EXTRACTION
    -- ============================================================================
    
    -- Extract current state from status register
    process(core_stat_status_out)
    begin
        current_state <= (others => '0');
        if core_stat_status_out(STATUS_RED_BIT) = '1' then
            current_state <= RED_STATE;
        elsif core_stat_status_out(STATUS_YELLOW_BIT) = '1' then
            current_state <= YELLOW_STATE;
        elsif core_stat_status_out(STATUS_GREEN_BIT) = '1' then
            current_state <= GREEN_STATE;
        elsif core_stat_status_out(STATUS_IDLE_BIT) = '1' then
            current_state <= IDLE_STATE;
        elsif core_stat_status_out(STATUS_FAULT_BIT) = '1' then
            current_state <= FAULT_STATE;
        end if;
    end process;
    
    -- Countdown value (simplified - would need internal counter access for real implementation)
    countdown_value <= (others => '0'); -- Placeholder - would need core modification for real countdown
    
    -- ============================================================================
    -- FAULT DETECTION
    -- ============================================================================
    
    -- Fault condition detection
    fault_condition <= core_stat_status_out(STATUS_FAULT_BIT) or 
                      (not clk_div_stat(STATUS_VALID_BIT));
    
    -- Global fault output
    fault_out <= fault_condition;
    
    -- ============================================================================
    -- READ INTERFACE
    -- ============================================================================
    
    -- Status register readback (32-bit)
    -- Bits 31-24: Core status register (8 bits)
    -- Bits 23-16: Clock divider status (8 bits)
    -- Bits 15-8: Reserved
    -- Bits 7-0: Control status
    stoplight_status_rd <= core_stat_status_out & clk_div_stat & x"00" & 
                          (ctrl_global_enable & "0000000");
    
    -- State register readback (32-bit)
    -- Bits 31-16: Countdown value (16 bits)
    -- Bits 15-3: Reserved
    -- Bits 2-0: Current state (3 bits)
    stoplight_state_rd <= countdown_value & "0000000000000" & current_state;
    
end architecture rtl;

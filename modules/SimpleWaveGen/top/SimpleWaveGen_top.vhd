-- SimpleWaveGen_top.vhd
-- SimpleWaveGen Top-Level Module
-- Integrates SimpleWaveGen core with clock divider and provides minimal register-based interface
-- Implements register interface per platform_interface_pkg.vhd specification
-- Option 3: Minimal status readback (enabled + fault only)

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use WORK.Moku_Voltage_pkg.all;
use WORK.platform_interface_pkg.all;

entity SimpleWaveGen_top is
    port (
        -- System Interface
        clk         : in  std_logic;                    -- System clock input
        rst         : in  std_logic;                    -- Synchronous reset (active high)
        
        -- Register Interface (32-bit registers)
        wavegen_ctrl_wr    : in  std_logic;                    -- WaveGen control register write enable
        wavegen_ctrl_data  : in  std_logic_vector(31 downto 0); -- WaveGen control register data (enable + clock divider)
        wave_select_data   : in  std_logic_vector(2 downto 0);  -- Wave selection data (safety critical, 3 bits)
        amplitude_data     : in  std_logic_vector(15 downto 0); -- Amplitude scale data (16 bits)
        
        -- Register Read Interface (Minimal - Option 3)
        wavegen_status_rd  : out std_logic_vector(31 downto 0); -- WaveGen status: enabled bit only
        fault_status_rd    : out std_logic_vector(31 downto 0); -- Fault status: fault bit only
        
        -- External Interface
        wave_out    : out std_logic_vector(15 downto 0); -- Direct waveform output
        fault_out   : out std_logic                      -- Global fault output
    );
end entity SimpleWaveGen_top;

architecture rtl of SimpleWaveGen_top is
    
    -- Internal register signals
    signal ctrl_global_enable    : std_logic;
    signal cfg_clk_div_sel       : std_logic_vector(3 downto 0);
    signal cfg_safety_wave_select: std_logic_vector(2 downto 0);
    signal cfg_amplitude_scale   : std_logic_vector(15 downto 0);
    
    -- Clock divider interface
    signal clk_en                : std_logic;
    signal clk_div_stat          : std_logic_vector(7 downto 0);
    
    -- SimpleWaveGen core interface
    signal core_wave_out         : std_logic_vector(15 downto 0);
    signal core_fault            : std_logic;
    signal core_stat             : std_logic_vector(7 downto 0);
    
    -- Amplitude scaling signals
    signal scaled_wave_out       : std_logic_vector(15 downto 0);
    
    -- Fault aggregation
    signal global_fault          : std_logic;
    
    -- Status register signals (Minimal - Option 3)
    signal wavegen_status_reg    : std_logic_vector(31 downto 0);
    signal fault_status_reg      : std_logic_vector(31 downto 0);
    
    -- Safety-critical parameter validation
    signal wave_select_valid     : std_logic;
    
begin
    
    -- Safety-critical parameter validation using platform interface package
    wave_select_valid <= is_wave_select_valid(cfg_safety_wave_select);
    
    -- Amplitude scaling using platform interface package
    scaled_wave_out <= apply_amplitude_scaling(core_wave_out, cfg_amplitude_scale);
    
    -- Fault aggregation using platform interface package
    global_fault <= aggregate_faults(core_fault, '0'); -- Clock divider doesn't have fault output
    
    -- Status register assignments (Minimal - Option 3)
    -- wavegen_status: just enabled bit, fault_status: just fault bit
    wavegen_status_reg <= (0 => ctrl_global_enable, others => '0');
    fault_status_reg <= (0 => global_fault, others => '0');
    
    -- Main synchronous process for register interface
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all registers to default values
            ctrl_global_enable <= DEFAULT_CTRL_GLOBAL_ENABLE;
            cfg_clk_div_sel <= DEFAULT_CLK_DIV_SEL;
            cfg_safety_wave_select <= DEFAULT_WAVE_SELECT;
            cfg_amplitude_scale <= DEFAULT_AMPLITUDE_SCALE;
            
        elsif rising_edge(clk) then
            -- WaveGen control register write
            if wavegen_ctrl_wr = '1' then
                -- Extract and validate fields using platform interface package
                ctrl_global_enable <= extract_ctrl_global_enable(wavegen_ctrl_data);
                
                -- Extract clock divider selection
                cfg_clk_div_sel <= extract_clk_div_sel(wavegen_ctrl_data);
            end if;
            
            -- Wave selection and amplitude are directly connected (no write enables needed)
            -- Safety-critical parameter validation happens continuously
            if is_wave_select_valid(wave_select_data) = '1' then
                cfg_safety_wave_select <= wave_select_data;
            end if;
            -- Invalid selections are ignored (maintain last valid selection)
            
            -- Amplitude scale is directly connected
            cfg_amplitude_scale <= amplitude_data;
        end if;
    end process;
    
    -- Clock Divider Instance (Direct Instantiation Required)
    U_clk_divider: entity WORK.clk_divider_core
        port map (
            clk => clk,
            rst_n => not rst, -- Convert active high reset to active low
            div_sel => cfg_clk_div_sel,
            clk_en => clk_en,
            stat_reg => clk_div_stat
        );
    
    -- SimpleWaveGen Core Instance (Direct Instantiation Required)
    U_wavegen_core: entity WORK.SimpleWaveGen_core
        port map (
            clk => clk,
            clk_en => clk_en,
            rst => rst,
            en => ctrl_global_enable,
            cfg_safety_wave_select => cfg_safety_wave_select,
            wave_out => core_wave_out,
            fault_out => core_fault,
            stat => core_stat
        );
    
    -- Output assignments
    wavegen_status_rd <= wavegen_status_reg;
    fault_status_rd <= fault_status_reg;
    wave_out <= scaled_wave_out;
    fault_out <= global_fault;
    
end architecture rtl;
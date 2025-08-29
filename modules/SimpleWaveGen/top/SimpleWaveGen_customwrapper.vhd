--------------------------------------------------------------------------------
-- CustomWrapper Implementation for SimpleWaveGen_top
-- Purpose: Lightweight CustomWrapper that maps platform signals to SimpleWaveGen_top
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- This CustomWrapper provides a minimal interface mapping between the platform
-- control system and the SimpleWaveGen_top module, including clock divider support.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- Import SimpleWaveGen packages
use work.platform_interface_pkg.all;

architecture behavioural of CustomWrapper is
    -- Internal signals for SimpleWaveGen_top
    signal wavegen_ctrl_data_internal    : std_logic_vector(31 downto 0);
    signal wave_select_data_internal     : std_logic_vector(2 downto 0);   -- 3 bits for wave selection
    signal amplitude_data_internal       : std_logic_vector(15 downto 0);  -- 16 bits for amplitude scale
    
    -- Status readback signals
    signal wavegen_status_rd_internal   : std_logic_vector(31 downto 0);
    signal fault_status_rd_internal     : std_logic_vector(31 downto 0);
    
    -- Waveform output
    signal wave_out_internal      : std_logic_vector(15 downto 0);
    signal fault_out_internal     : std_logic;
    
begin
    -- =============================================================================
    -- REGISTER MAPPING LOGIC
    -- =============================================================================
    
    -- Map platform Control registers to internal signals
    wavegen_ctrl_data_internal <= Control0;    -- Control0: enable + clock divider
    wave_select_data_internal <= Control1(2 downto 0);     -- Control1[2:0]: wave selection (3 bits)
    amplitude_data_internal <= Control2(15 downto 0);      -- Control2[15:0]: amplitude scale (16 bits)
    
    -- =============================================================================
    -- OUTPUT MAPPING
    -- =============================================================================
    
    -- Primary outputs: waveform and status
    OutputA <= signed(wave_out_internal);
    OutputB <= signed(wavegen_status_rd_internal(15 downto 0));  -- WaveGen status (enabled)
    OutputC <= signed(fault_status_rd_internal(15 downto 0));    -- Fault status
    
    -- =============================================================================
    -- SIMPLEWAVEGEN TOP INSTANTIATION
    -- =============================================================================
    
    -- Direct instantiation of SimpleWaveGen_top (required for top layer)
    SIMPLEWAVEGEN_TOP: entity work.SimpleWaveGen_top
        port map (
            clk => Clk,
            rst => Reset,
            wavegen_ctrl_wr => '1',  -- Always write (no write detection needed)
            wavegen_ctrl_data => wavegen_ctrl_data_internal,
            wave_select_data => wave_select_data_internal,
            amplitude_data => amplitude_data_internal,
            wavegen_status_rd => wavegen_status_rd_internal,
            fault_status_rd => fault_status_rd_internal,
            wave_out => wave_out_internal,
            fault_out => fault_out_internal
        );

end architecture;

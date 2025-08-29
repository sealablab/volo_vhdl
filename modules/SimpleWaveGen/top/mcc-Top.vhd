-- mcc-Top.vhd
-- MCC CustomWrapper for SimpleWaveGen Module
-- Maps MCC platform Control registers to SimpleWaveGen_top interface
-- Implements the CustomWrapper entity as specified in SimpleWaveGen-Platform-Mapping.md

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use WORK.platform_interface_pkg.all;

entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Input signals (unused for SimpleWaveGen)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        
        -- Output signals
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        
        -- Control registers (32-bit each)
        Control0  : in  std_logic_vector(31 downto 0);
        Control1  : in  std_logic_vector(31 downto 0);
        Control2  : in  std_logic_vector(31 downto 0);
        Control3  : in  std_logic_vector(31 downto 0);
        Control4  : in  std_logic_vector(31 downto 0);
        Control5  : in  std_logic_vector(31 downto 0);
        Control6  : in  std_logic_vector(31 downto 0);
        Control7  : in  std_logic_vector(31 downto 0);
        Control8  : in  std_logic_vector(31 downto 0);
        Control9  : in  std_logic_vector(31 downto 0);
        Control10 : in  std_logic_vector(31 downto 0);
        Control11 : in  std_logic_vector(31 downto 0);
        Control12 : in  std_logic_vector(31 downto 0);
        Control13 : in  std_logic_vector(31 downto 0);
        Control14 : in  std_logic_vector(31 downto 0);
        Control15 : in  std_logic_vector(31 downto 0)
    );
end entity CustomWrapper;

architecture rtl of CustomWrapper is
    
    -- Internal signals for SimpleWaveGen_top interface
    signal wavegen_ctrl_wr    : std_logic;
    signal wavegen_ctrl_data  : std_logic_vector(31 downto 0);
    signal wave_select_data   : std_logic_vector(2 downto 0);
    signal amplitude_data     : std_logic_vector(15 downto 0);
    
    signal wavegen_status_rd  : std_logic_vector(31 downto 0);
    signal fault_status_rd    : std_logic_vector(31 downto 0);
    
    signal wave_out           : std_logic_vector(15 downto 0);
    signal fault_out          : std_logic;
    
    -- Internal reset signal (convert active high to active high)
    signal rst                : std_logic;
    
begin
    
    -- Reset signal mapping
    rst <= Reset;
    
    -- Control register mapping per SimpleWaveGen-Platform-Mapping.md
    
    -- Control0 → WaveGen Control Register
    -- Bit [31]: Global Enable
    -- Bits [23:20]: Clock Divider Selection
    -- Bits [19:0]: Reserved
    wavegen_ctrl_data <= Control0;
    wavegen_ctrl_wr <= '1'; -- Always write (direct connection as specified)
    
    -- Control1 → Wave Selection (Safety Critical)
    -- Bits [2:0]: Wave Type Selection
    -- Bits [31:3]: Reserved
    wave_select_data <= Control1(2 downto 0);
    
    -- Control2 → Amplitude Scale
    -- Bits [15:0]: Amplitude Scale
    -- Bits [31:16]: Reserved
    amplitude_data <= Control2(15 downto 0);
    
    -- SimpleWaveGen_top instance (Direct Instantiation Required)
    U_SimpleWaveGen_top: entity WORK.SimpleWaveGen_top
        port map (
            clk => Clk,
            rst => rst,
            wavegen_ctrl_wr => wavegen_ctrl_wr,
            wavegen_ctrl_data => wavegen_ctrl_data,
            wave_select_data => wave_select_data,
            amplitude_data => amplitude_data,
            wavegen_status_rd => wavegen_status_rd,
            fault_status_rd => fault_status_rd,
            wave_out => wave_out,
            fault_out => fault_out
        );
    
    -- Output mapping per SimpleWaveGen-Platform-Mapping.md
    
    -- OutputA → wave_out (16-bit signed waveform output)
    OutputA <= signed(wave_out);
    
    -- OutputB → wavegen_status_rd[15:0] (WaveGen status - enabled bit)
    OutputB <= signed(wavegen_status_rd(15 downto 0));
    
    -- OutputC → fault_status_rd[15:0] (Fault status - fault bit)
    OutputC <= signed(fault_status_rd(15 downto 0));
    
end architecture rtl;
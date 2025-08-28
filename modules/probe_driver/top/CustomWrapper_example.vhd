--------------------------------------------------------------------------------
-- Example: CustomWrapper Implementation
-- Purpose: Shows how the vendor's CustomWrapper would instantiate probe_driver_interface
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- NOTE: This is an EXAMPLE file showing how the vendor's CustomWrapper entity
-- would instantiate our probe_driver_interface module. This file should NOT
-- be compiled with the vendor's tools as they provide their own CustomWrapper.
-- 
-- This file is for reference only and demonstrates the proper integration pattern.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Import probe_driver packages
use work.probe_driver_pkg.all;
use work.PercentLut_pkg.all;
use work.Trigger_Config_pkg.all;
use work.Moku_Voltage_pkg.all;

-- NOTE: This entity would be provided by the vendor's compiler package
-- This is just an example of what it might look like
entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Input signals (mapped to probe driver inputs)
        InputA  : in  signed(15 downto 0);  -- Trigger input data
        InputB  : in  signed(15 downto 0);  -- Reserved for future use
        InputC  : in  signed(15 downto 0);  -- Reserved for future use
        
        -- Output signals (mapped to probe driver outputs)
        OutputA : out signed(15 downto 0);  -- Intensity output
        OutputB : out signed(15 downto 0);  -- Status register
        OutputC : out signed(15 downto 0);  -- Probe state
        
        -- Control registers
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

architecture behavioral of CustomWrapper is
    -- Internal signals for connecting to probe_driver_interface
    signal internal_output_a : signed(15 downto 0);
    signal internal_output_b : signed(15 downto 0);
    signal internal_output_c : signed(15 downto 0);
    
begin
    -- =============================================================================
    -- PROBE DRIVER INTERFACE INSTANTIATION
    -- =============================================================================
    
    -- Instantiate our probe_driver_interface module
    probe_driver_inst : entity work.probe_driver_interface
        port map (
            -- Clock and Reset
            Clk     => Clk,
            Reset   => Reset,
            
            -- Input signals
            InputA  => InputA,
            InputB  => InputB,
            InputC  => InputC,
            
            -- Output signals
            OutputA => internal_output_a,
            OutputB => internal_output_b,
            OutputC => internal_output_c,
            
            -- Control registers
            Control0  => Control0,
            Control1  => Control1,
            Control2  => Control2,
            Control3  => Control3,
            Control4  => Control4,
            Control5  => Control5,
            Control6  => Control6,
            Control7  => Control7,
            Control8  => Control8,
            Control9  => Control9,
            Control10 => Control10,
            Control11 => Control11,
            Control12 => Control12,
            Control13 => Control13,
            Control14 => Control14,
            Control15 => Control15
        );
    
    -- =============================================================================
    -- OUTPUT MAPPING
    -- =============================================================================
    
    -- Map internal signals to CustomWrapper outputs
    OutputA <= internal_output_a;
    OutputB <= internal_output_b;
    OutputC <= internal_output_c;

end architecture behavioral;
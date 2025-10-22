-- mcc-Top.vhd
-- Generic CustomWrapper Entity Template for Moku Custom Core (MCC)
-- This file provides ONLY the entity declaration for CustomWrapper.
-- Each module provides its own architecture in modules/<module>/top/Top.vhd
--
-- Pattern: architecture <ModuleName> of CustomWrapper is
--   Example: architecture EMFI_Seq of CustomWrapper is
--   Example: architecture SimpleWaveGen of CustomWrapper is
--
-- DO NOT add architecture here - modules provide their own!

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;

        -- Input signals (ADC data, signed 16-bit)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        InputD  : in  signed(15 downto 0);

        -- Output signals (DAC data, signed 16-bit)
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        OutputD : out signed(15 downto 0);

        -- Control registers (32-bit each, from Moku platform)
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

-- NO ARCHITECTURE HERE!
-- Each module provides architecture in modules/<module>/top/Top.vhd
-- Example: architecture EMFI_Seq of CustomWrapper is ... end architecture;

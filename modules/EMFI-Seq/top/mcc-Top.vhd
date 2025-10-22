--------------------------------------------------------------------------------
-- mcc-Top.vhd
-- CustomWrapper Entity Declaration for EMFI-Seq Module
-- Purpose: Defines MCC platform interface entity (architecture in MCC_EMFI_Top.vhd)
--
-- Note: This is the standard Moku CustomWrapper entity declaration.
--       The implementation (architecture) is in MCC_EMFI_Top.vhd
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;

        -- Input signals (unused for EMFI-Seq)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);

        -- Output signals
        OutputA : out signed(15 downto 0);  -- DAC stair-step output
        OutputB : out signed(15 downto 0);  -- FSM status (sticky)
        OutputC : out signed(15 downto 0);  -- Current state + monitor

        -- Control registers
        Control0  : in  std_logic_vector(31 downto 0);  -- Enable + clk_en
        Control1  : in  std_logic_vector(31 downto 0);  -- Reserved
        Control2  : in  std_logic_vector(31 downto 0);  -- S1 delay
        Control3  : in  std_logic_vector(31 downto 0);  -- S2 delay
        Control4  : in  std_logic_vector(31 downto 0);  -- S3 delay
        Control5  : in  std_logic_vector(31 downto 0);  -- S4 delay
        Control6  : in  std_logic_vector(31 downto 0);  -- Reserved
        Control7  : in  std_logic_vector(31 downto 0);  -- Reserved
        Control8  : in  std_logic_vector(31 downto 0);  -- Reserved
        Control9  : in  std_logic_vector(31 downto 0);  -- Reserved
        Control10 : in  std_logic_vector(31 downto 0);  -- Reserved
        Control11 : in  std_logic_vector(31 downto 0);  -- Reserved
        Control12 : in  std_logic_vector(31 downto 0);  -- Reserved
        Control13 : in  std_logic_vector(31 downto 0);  -- Reserved
        Control14 : in  std_logic_vector(31 downto 0);  -- Reserved
        Control15 : in  std_logic_vector(31 downto 0)   -- Reserved
    );
end entity CustomWrapper;

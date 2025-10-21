--------------------------------------------------------------------------------
-- CustomWrapper_Body_Template.vhd
--
-- Template for CustomWrapper architecture body in MCC
--
-- INSTRUCTIONS:
-- 1. In MCC web interface, find the CustomWrapper template editor
-- 2. Replace the architecture body with this template
-- 3. Upload: TPD_Top.vhd, emfi_fsm.vhd, tpd_med.vhd
--
-- NOTE: Do NOT upload a file named CustomWrapper.vhd! MCC reserves that name.
--       Only edit the CustomWrapper template through the MCC web interface.
--------------------------------------------------------------------------------

-- This goes INSIDE the architecture body of CustomWrapper:

begin

    -- Instantiate TPD Top-Level Module
    U_TPD: entity WORK.TPD_Top
        port map (
            -- Clock and Reset
            Clk       => Clk,
            Reset     => Reset,

            -- Input signals
            InputA    => InputA,
            InputB    => InputB,
            InputC    => InputC,

            -- Output signals
            OutputA   => OutputA,
            OutputB   => OutputB,
            OutputC   => OutputC,

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

end architecture;

--------------------------------------------------------------------------------
-- ALTERNATIVE: If MCC doesn't support template editing, use this approach:
--
-- Create a minimal wrapper file (NOT named CustomWrapper.vhd):
--------------------------------------------------------------------------------

-- File: TPD_CustomWrapper_Glue.vhd

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- This is a pass-through wrapper
-- Upload this along with TPD_Top, emfi_fsm, tpd_med
entity TPD_CustomWrapper_Glue is
    port (
        Clk       : in  std_logic;
        Reset     : in  std_logic;
        InputA    : in  signed(15 downto 0);
        InputB    : in  signed(15 downto 0);
        InputC    : in  signed(15 downto 0);
        OutputA   : out signed(15 downto 0);
        OutputB   : out signed(15 downto 0);
        OutputC   : out signed(15 downto 0);
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
end entity TPD_CustomWrapper_Glue;

architecture rtl of TPD_CustomWrapper_Glue is
begin
    U_TPD: entity WORK.TPD_Top
        port map (
            Clk => Clk, Reset => Reset,
            InputA => InputA, InputB => InputB, InputC => InputC,
            OutputA => OutputA, OutputB => OutputB, OutputC => OutputC,
            Control0 => Control0, Control1 => Control1, Control2 => Control2,
            Control3 => Control3, Control4 => Control4, Control5 => Control5,
            Control6 => Control6, Control7 => Control7, Control8 => Control8,
            Control9 => Control9, Control10 => Control10, Control11 => Control11,
            Control12 => Control12, Control13 => Control13, Control14 => Control14,
            Control15 => Control15
        );
end architecture rtl;

-- Then in MCC template CustomWrapper, instantiate TPD_CustomWrapper_Glue

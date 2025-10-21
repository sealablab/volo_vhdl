--------------------------------------------------------------------------------
-- Top.vhd
--
-- CustomWrapper Architecture for TPD Module
--
-- Description:
--   Defines the architecture body for MCC's CustomWrapper entity.
--   MCC provides the entity declaration; this file provides the implementation.
--
-- Pattern:
--   - MCC supplies: entity CustomWrapper declaration
--   - User uploads: architecture definition (this file)
--   - Architecture instantiates: TPD_Top entity
--
-- Author: Claude Code
-- Date: 2025-01-27
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture rtl of CustomWrapper is
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
end architecture rtl;

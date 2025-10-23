-- ###########################################################################
-- # Top.vhd
-- # CustomWrapper Architecture for EMFI_Seq
-- # Pattern: Matches DCSequencer style (architecture-only file)
-- #
-- # Register Map:
-- #   Control0[31]:    Enable (gates sequencer operation)
-- #   Control0[30]:    Clock enable
-- #   Control0[7:0]:   Clock divider select (0=÷1, 1=÷2, ..., 255=÷256)
-- #   Control1[6:0]:   State 1 delay (7-bit)
-- #   Control2[6:0]:   State 2 delay (7-bit)
-- #   Control3[6:0]:   State 3 delay (7-bit)
-- #   Control4[6:0]:   State 4 delay (7-bit)
-- #   Control5[15:0]:  State 1 DAC level (signed 16-bit, -5V to +5V)
-- #   Control6[15:0]:  State 2 DAC level (signed 16-bit, -5V to +5V)
-- #   Control7[15:0]:  State 3 DAC level (signed 16-bit, -5V to +5V)
-- #   Control8[15:0]:  State 4 DAC level (signed 16-bit, -5V to +5V)
-- #
-- # Output Map:
-- #   OutputA[15:0]:   DAC stair-step output (signed 16-bit)
-- #   OutputB[6:0]:    FSM sticky status (bits 0-3: S1-S4 entry markers)
-- #   OutputC[3:0]:    Current state (one-hot)
-- #   OutputC[15:4]:   Monitor value MSBs
-- #   OutputD[7:0]:    Clock divider counter status
-- ###########################################################################

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture EMFI_Seq of CustomWrapper is
    signal status_internal  : unsigned(6 downto 0);
    signal state_internal   : std_logic_vector(3 downto 0);
    signal monitor_internal : unsigned(15 downto 0);
    signal div_stat_internal: std_logic_vector(7 downto 0);
    signal outputc_temp     : std_logic_vector(15 downto 0);
begin
    EMFI_SEQUENCER: entity WORK.EMFI_Seq
	-- the `EMFI_Seq` instantiates the fsm / sequencer as well as the analog monitor, which we connect to OutputA below
        port map (
            Clk        => Clk,
            Reset      => Reset,
            Enable     => not Control0(31),
            ClkEn      => not Control0(30),
            DivSel     => std_logic_vector(Control0(7 downto 0)),
            DelayS1    => unsigned(Control1(6 downto 0)),
            DelayS2    => unsigned(Control2(6 downto 0)),
            DelayS3    => unsigned(Control3(6 downto 0)),
            DelayS4    => unsigned(Control4(6 downto 0)),
            LevelS1    => signed(Control5(15 downto 0)),
            LevelS2    => signed(Control6(15 downto 0)),
            LevelS3    => signed(Control7(15 downto 0)),
            LevelS4    => signed(Control8(15 downto 0)),
            DACOut     => OutputA,
            StatusOut  => status_internal,
            StateOut   => state_internal,
            MonitorOut => monitor_internal,
            DivStatOut => div_stat_internal
        );

    -- Pack status into OutputB (7 bits in lower portion)
    OutputB <= signed(resize(status_internal, 16));

    -- Pack state and monitor into OutputC
    -- Use intermediate signal to avoid concatenation type ambiguity
    outputc_temp <= std_logic_vector(monitor_internal(15 downto 4)) & state_internal;
    OutputC <= signed(outputc_temp);

    -- Pack divider status into OutputD
    OutputD <= signed(resize(unsigned(div_stat_internal), 16));

end architecture EMFI_Seq;

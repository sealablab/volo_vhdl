-- ###########################################################################
-- # Top.vhd
-- # CustomWrapper Architecture for EMFI_Seq
-- # Pattern: Matches DCSequencer style (architecture-only file)
-- #
-- # Register Map:
-- #   Control0[0]:     Enable (gates sequencer operation)
-- #   Control0[1]:     Clock enable
-- #   Control2[6:0]:   State 1 delay (7-bit)
-- #   Control3[6:0]:   State 2 delay (7-bit)
-- #   Control4[6:0]:   State 3 delay (7-bit)
-- #   Control5[6:0]:   State 4 delay (7-bit)
-- #
-- # Output Map:
-- #   OutputA[15:0]:   DAC stair-step output (signed 16-bit)
-- #   OutputB[6:0]:    FSM sticky status (bits 0-3: S1-S4 entry markers)
-- #   OutputC[3:0]:    Current state (one-hot)
-- #   OutputC[15:4]:   Monitor value MSBs
-- ###########################################################################

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture EMFI_Seq of CustomWrapper is
    signal status_internal : unsigned(6 downto 0);
    signal state_internal  : std_logic_vector(3 downto 0);
    signal monitor_internal: unsigned(15 downto 0);
begin
    EMFI_SEQUENCER: entity WORK.EMFI_Seq
        port map (
            Clk        => Clk,
            Reset      => Reset,
            Enable     => Control0(0),
            ClkEn      => Control0(1),
            DelayS1    => unsigned(Control2(6 downto 0)),
            DelayS2    => unsigned(Control3(6 downto 0)),
            DelayS3    => unsigned(Control4(6 downto 0)),
            DelayS4    => unsigned(Control5(6 downto 0)),
            DACOut     => OutputA,
            StatusOut  => status_internal,
            StateOut   => state_internal,
            MonitorOut => monitor_internal
        );

    -- Pack status into OutputB (7 bits in lower portion)
    OutputB <= signed(resize(status_internal, 16));

    -- Pack state and monitor into OutputC
    OutputC <= signed(std_logic_vector(monitor_internal(15 downto 4)) & state_internal);

end architecture EMFI_Seq;

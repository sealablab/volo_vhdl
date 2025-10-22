-- ###########################################################################
-- # EMFI_Seq.vhd
-- # EMFI Sequencer Module
-- # Integrates 4-state FSM sequencer with analog monitor (stair-step DAC)
-- # Pattern: Matches DCSequencer style (entity + architecture in one file)
-- ###########################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EMFI_Seq is
    port (
        -- System Interface
        Clk             : in  std_logic;
        Reset           : in  std_logic;

        -- Control Interface
        Enable          : in  std_logic;
        ClkEn           : in  std_logic;

        -- Configuration Interface (Per-State Delays)
        DelayS1         : in  unsigned(6 downto 0);
        DelayS2         : in  unsigned(6 downto 0);
        DelayS3         : in  unsigned(6 downto 0);
        DelayS4         : in  unsigned(6 downto 0);

        -- Output Interface
        DACOut          : out signed(15 downto 0);
        StatusOut       : out unsigned(6 downto 0);
        StateOut        : out std_logic_vector(3 downto 0);
        MonitorOut      : out unsigned(15 downto 0)
    );
end entity EMFI_Seq;

architecture rtl of EMFI_Seq is

    -- Internal signals connecting FSM to analog monitor
    signal state_oh_internal   : std_logic_vector(3 downto 0);
    signal status_internal     : unsigned(6 downto 0);
    signal dac_out_internal    : signed(15 downto 0);
    signal monitor_internal    : unsigned(15 downto 0);

begin

    -- ========================================================================
    -- FSM SEQUENCER CORE
    -- ========================================================================
    FSM_CORE: entity WORK.emfi_seq_core
        port map (
            clk          => Clk,
            rst          => Reset,
            clk_en       => ClkEn,
            en           => Enable,
            delay_s1     => DelayS1,
            delay_s2     => DelayS2,
            delay_s3     => DelayS3,
            delay_s4     => DelayS4,
            status_out   => status_internal,
            state_oh_out => state_oh_internal
        );

    -- ========================================================================
    -- ANALOG MONITOR (STAIR-STEP DAC)
    -- ========================================================================
    ANALOG_MONITOR: entity WORK.onehot_analog_monitor
        port map (
            state_oh    => state_oh_internal,
            dac_out_s16 => dac_out_internal,
            monitor_u16 => monitor_internal
        );

    -- ========================================================================
    -- OUTPUT ASSIGNMENTS
    -- ========================================================================
    DACOut     <= dac_out_internal;
    StatusOut  <= status_internal;
    StateOut   <= state_oh_internal;
    MonitorOut <= monitor_internal;

end architecture rtl;

-- ###########################################################################
-- # Top.vhd
-- # CustomWrapper Architecture for EMFI_Seq
-- # Pattern: Matches DCSequencer style (architecture-only file)
-- # Updated: 2025-10-25 - Migrated to fsm_observer pattern
-- #
-- # MCC_READY Convention:
-- #   Control0[31] = MCC_READY flag (ACTIVE-HIGH)
-- #     0 = Module disabled (safe during bitstream load / all-zero state)
-- #     1 = Module enabled and ready for operation
-- #
-- # Register Map:
-- #   Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
-- #   Control0[30]:    User Enable (1=enable sequencer, 0=disable)
-- #   Control0[7:0]:   Clock divider select (0=÷1, 1=÷2, ..., 255=÷256)
-- #   Control1[6:0]:   State 1 delay (7-bit)
-- #   Control2[6:0]:   State 2 delay (7-bit)
-- #   Control3[6:0]:   State 3 delay (7-bit)
-- #   Control4[6:0]:   State 4 delay (7-bit)
-- #
-- # Output Map:
-- #   OutputA[15:0]:   FSM observer voltage (oscilloscope debug)
-- #                    0.0V (S1) → 1.5V (S4) - linear stairstep
-- #   OutputB[6:0]:    FSM sticky status (bits 0-3: S1-S4 entry markers)
-- #   OutputC[5:0]:    Current state (6-bit binary encoding)
-- #   OutputD[7:0]:    Clock divider counter status
-- ###########################################################################

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture EMFI_Seq of CustomWrapper is
    -- MCC control signals
    signal mcc_ready         : std_logic;
    signal user_enable       : std_logic;
    signal global_enable     : std_logic;

    -- Internal signals
    signal fsm_voltage       : signed(15 downto 0);
    signal status_internal   : unsigned(6 downto 0);
    signal state_internal    : std_logic_vector(5 downto 0);  -- 6-bit binary
    signal div_stat_internal : std_logic_vector(7 downto 0);
begin
    -- ========================================================================
    -- MCC_READY LOGIC (Active-High Convention)
    -- ========================================================================
    -- Control0[31] = MCC_READY: Set by MCC after configuration loaded
    -- Control0[30] = User Enable: User-level enable bit
    -- Global enable gates both: module only operates when MCC is ready AND user enables
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    global_enable  <= mcc_ready and user_enable;

    -- ========================================================================
    -- EMFI SEQUENCER INSTANCE
    -- ========================================================================
    EMFI_SEQUENCER: entity WORK.EMFI_Seq
        port map (
            Clk           => Clk,
            Reset         => Reset,
            Enable        => global_enable,    -- Safe: disabled during all-zero state
            ClkEn         => '1',              -- Always enabled (can add Control0[29] if needed)
            DivSel        => std_logic_vector(Control0(7 downto 0)),
            DelayS1       => unsigned(Control1(6 downto 0)),
            DelayS2       => unsigned(Control2(6 downto 0)),
            DelayS3       => unsigned(Control3(6 downto 0)),
            DelayS4       => unsigned(Control4(6 downto 0)),
            FSMVoltageOut => fsm_voltage,      -- FSM observer output
            StatusOut     => status_internal,
            StateOut      => state_internal,   -- 6-bit binary state
            DivStatOut    => div_stat_internal
        );

    -- ========================================================================
    -- OUTPUT ASSIGNMENTS
    -- ========================================================================
    -- OutputA: FSM observer voltage for oscilloscope debugging
    OutputA <= fsm_voltage;

    -- OutputB: FSM sticky status (7 bits in lower portion)
    OutputB <= signed(resize(status_internal, 16));

    -- OutputC: Current FSM state (6-bit binary in lower portion)
    OutputC <= signed(resize(unsigned(state_internal), 16));

    -- OutputD: Clock divider status
    OutputD <= signed(resize(unsigned(div_stat_internal), 16));

end architecture EMFI_Seq;

-- ###########################################################################
-- # EMFI_Seq.vhd
-- # EMFI Sequencer Module
-- # Integrates 4-state FSM sequencer with fsm_observer pattern
-- # Pattern: Matches DCSequencer style (entity + architecture in one file)
-- # Updated: 2025-10-25 - Migrated to standardized fsm_observer pattern
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

        -- Clock Division Configuration
        DivSel          : in  std_logic_vector(7 downto 0);

        -- Configuration Interface (Per-State Delays)
        DelayS1         : in  unsigned(6 downto 0);
        DelayS2         : in  unsigned(6 downto 0);
        DelayS3         : in  unsigned(6 downto 0);
        DelayS4         : in  unsigned(6 downto 0);

        -- Output Interface
        FSMVoltageOut   : out signed(15 downto 0);    -- FSM observer output (oscilloscope debug)
        StatusOut       : out unsigned(6 downto 0);   -- FSM sticky status
        StateOut        : out std_logic_vector(5 downto 0);  -- FSM state (6-bit binary)
        DivStatOut      : out std_logic_vector(7 downto 0)   -- Clock divider status
    );
end entity EMFI_Seq;

architecture rtl of EMFI_Seq is

    -- Internal signals from FSM
    signal state_vector        : std_logic_vector(5 downto 0);  -- 6-bit binary state
    signal status_internal     : unsigned(6 downto 0);

    -- Internal signals for clock divider
    signal div_clk_en_internal : std_logic;
    signal div_stat_internal   : std_logic_vector(7 downto 0);
    signal fsm_clk_en          : std_logic;

    -- Internal signal from FSM observer
    signal fsm_voltage         : signed(15 downto 0);

begin

    -- ========================================================================
    -- CLOCK DIVIDER
    -- ========================================================================
    -- Provides configurable clock division for the FSM timing
    -- The divider's clk_en output is combined with the external ClkEn
    CLK_DIVIDER: entity WORK.volo_clk_divider
        generic map (
            MAX_DIV => 256
        )
        port map (
            clk      => Clk,
            rst_n    => not Reset,          -- clk_divider uses active-low reset
            enable   => Enable,             -- Freeze divider when EMFI_Seq disabled
            div_sel  => DivSel,
            clk_en   => div_clk_en_internal,
            stat_reg => div_stat_internal
        );

    -- Combine external ClkEn with divider output (AND gate)
    -- This allows external override while also using internal division
    fsm_clk_en <= ClkEn and div_clk_en_internal;

    -- ========================================================================
    -- FSM SEQUENCER CORE
    -- ========================================================================
    FSM_CORE: entity WORK.emfi_seq_core
        port map (
            clk        => Clk,
            rst        => Reset,
            clk_en     => fsm_clk_en,     -- Combined external + divider clock enable
            en         => Enable,
            delay_s1   => DelayS1,
            delay_s2   => DelayS2,
            delay_s3   => DelayS3,
            delay_s4   => DelayS4,
            status_out => status_internal,
            state_out  => state_vector    -- 6-bit binary state for observer
        );

    -- ========================================================================
    -- FSM OBSERVER (Oscilloscope Debug)
    -- ========================================================================
    -- Maps FSM state to voltage for oscilloscope visualization
    -- Voltage range: 0.0V (S1) → 1.5V (S4)
    -- No fault states (FAULT_STATE_THRESHOLD = NUM_STATES)
    FSM_OBS: entity WORK.fsm_observer
        generic map (
            NUM_STATES            => 4,     -- 4 states (S1-S4)
            V_MIN                 => 0.0,   -- S1 at ground
            V_MAX                 => 1.5,   -- S4 at 1.5V
            FAULT_STATE_THRESHOLD => 4,     -- No fault states (all normal)

            -- State names for documentation
            STATE_0_NAME => "S1",
            STATE_1_NAME => "S2",
            STATE_2_NAME => "S3",
            STATE_3_NAME => "S4"
        )
        port map (
            clk          => Clk,
            reset        => not Reset,      -- Observer uses active-low reset
            state_vector => state_vector,
            voltage_out  => fsm_voltage
        );

    -- ========================================================================
    -- OUTPUT ASSIGNMENTS
    -- ========================================================================
    FSMVoltageOut <= fsm_voltage;
    StatusOut     <= status_internal;
    StateOut      <= state_vector;
    DivStatOut    <= div_stat_internal;

end architecture rtl;

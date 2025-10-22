-- ###########################################################################
-- # EMFI_Seq_Top.vhd
-- # EMFI Sequencer Top-Level Module
-- # Integrates FSM sequencer core with analog monitor (stair-step DAC)
-- # Provides register-based control interface for MCC integration
-- ###########################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EMFI_Seq_Top is
    port (
        -- System Interface
        clk             : in  std_logic;                     -- System clock
        rst             : in  std_logic;                     -- Synchronous reset (active high)

        -- Control Interface
        ctrl_enable     : in  std_logic;                     -- Global enable (gates FSM operation)
        clk_en          : in  std_logic;                     -- Clock enable (optional timing control)

        -- Configuration Interface (Per-State Delays)
        cfg_delay_s1    : in  unsigned(6 downto 0);         -- S1 state delay (7-bit)
        cfg_delay_s2    : in  unsigned(6 downto 0);         -- S2 state delay (7-bit)
        cfg_delay_s3    : in  unsigned(6 downto 0);         -- S3 state delay (7-bit)
        cfg_delay_s4    : in  unsigned(6 downto 0);         -- S4 state delay (7-bit)

        -- Status Interface
        stat_fsm_status : out unsigned(6 downto 0);         -- FSM sticky status (bits 0-3 = S1-S4 entry markers)
        stat_state_oh   : out std_logic_vector(3 downto 0); -- Current state (one-hot encoding)
        stat_monitor    : out unsigned(15 downto 0);        -- Monitor value (unsigned DAC mirror)

        -- DAC Output
        dac_out         : out signed(15 downto 0)           -- Primary DAC output (signed 16-bit)
    );
end entity EMFI_Seq_Top;

architecture rtl of EMFI_Seq_Top is

    -- Internal signals connecting FSM to analog monitor
    signal state_oh_internal   : std_logic_vector(3 downto 0);
    signal status_internal     : unsigned(6 downto 0);
    signal dac_out_internal    : signed(15 downto 0);
    signal monitor_u16_internal: unsigned(15 downto 0);

begin

    -- ========================================================================
    -- FSM SEQUENCER CORE INSTANTIATION
    -- ========================================================================
    -- Direct instantiation (required for top layer per CLAUDE.md)
    -- Controls 4-state sequencer with configurable per-state delays

    U_FSM_CORE: entity WORK.emfi_seq_core
        port map (
            -- System interface
            clk          => clk,
            rst          => rst,
            clk_en       => clk_en,
            en           => ctrl_enable,  -- Auto-run when enabled

            -- Configuration: per-state delays
            delay_s1     => cfg_delay_s1,
            delay_s2     => cfg_delay_s2,
            delay_s3     => cfg_delay_s3,
            delay_s4     => cfg_delay_s4,

            -- Status outputs
            status_out   => status_internal,
            state_oh_out => state_oh_internal
        );

    -- ========================================================================
    -- ANALOG MONITOR (STAIR-STEP DAC) INSTANTIATION
    -- ========================================================================
    -- Direct instantiation (required for top layer per CLAUDE.md)
    -- Converts one-hot state to analog voltage levels for scope triggering

    U_ANALOG_MONITOR: entity WORK.onehot_analog_monitor
        port map (
            -- State input from FSM
            state_oh    => state_oh_internal,

            -- DAC outputs
            dac_out_s16 => dac_out_internal,
            monitor_u16 => monitor_u16_internal
        );

    -- ========================================================================
    -- OUTPUT ASSIGNMENTS
    -- ========================================================================

    stat_fsm_status <= status_internal;
    stat_state_oh   <= state_oh_internal;
    stat_monitor    <= monitor_u16_internal;
    dac_out         <= dac_out_internal;

end architecture rtl;

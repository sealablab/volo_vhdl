--------------------------------------------------------------------------------
-- MCC_EMFI_Top.vhd
-- CustomWrapper Architecture for EMFI_Seq_Top
-- Purpose: MCC platform interface for EMFI Sequencer module
-- Maps Moku CustomWrapper ports to EMFI_Seq_Top module
--
-- Register Map:
--   Control0[0]:     Global enable (gates sequencer operation)
--   Control0[1]:     Clock enable (timing control, typically '1')
--   Control0[31:2]:  Reserved
--   Control1[31:0]:  Reserved for future use
--   Control2[6:0]:   State 1 delay (7-bit)
--   Control3[6:0]:   State 2 delay (7-bit)
--   Control4[6:0]:   State 3 delay (7-bit)
--   Control5[6:0]:   State 4 delay (7-bit)
--
-- Output Map:
--   OutputA[15:0]:   DAC output (signed 16-bit, stair-step voltage levels)
--   OutputB[6:0]:    FSM sticky status (bits 0-3: S1-S4 entry markers)
--   OutputB[15:7]:   Reserved
--   OutputC[3:0]:    Current state (one-hot: S1/S2/S3/S4)
--   OutputC[15:4]:   Monitor value MSBs (unsigned DAC mirror bits [15:4])
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture behavioural of CustomWrapper is

    -- ========================================================================
    -- DEFAULT CONFIGURATION CONSTANTS
    -- ========================================================================

    -- Default per-state delays (applied on reset)
    constant DEFAULT_DELAY_S1 : unsigned(6 downto 0) := to_unsigned(1, 7);
    constant DEFAULT_DELAY_S2 : unsigned(6 downto 0) := to_unsigned(2, 7);
    constant DEFAULT_DELAY_S3 : unsigned(6 downto 0) := to_unsigned(3, 7);
    constant DEFAULT_DELAY_S4 : unsigned(6 downto 0) := to_unsigned(4, 7);

    -- Default control settings
    constant DEFAULT_ENABLE   : std_logic := '0';  -- Disabled on reset
    constant DEFAULT_CLK_EN   : std_logic := '1';  -- Clock always enabled

    -- ========================================================================
    -- INTERNAL SIGNALS
    -- ========================================================================

    -- Control signals (registered)
    signal ctrl_enable_internal    : std_logic;
    signal ctrl_clk_en_internal    : std_logic;

    -- Configuration signals (registered, per-state delays)
    signal cfg_delay_s1_internal   : unsigned(6 downto 0);
    signal cfg_delay_s2_internal   : unsigned(6 downto 0);
    signal cfg_delay_s3_internal   : unsigned(6 downto 0);
    signal cfg_delay_s4_internal   : unsigned(6 downto 0);

    -- Status readback signals
    signal stat_fsm_status_internal    : unsigned(6 downto 0);
    signal stat_state_oh_internal      : std_logic_vector(3 downto 0);
    signal stat_monitor_internal       : unsigned(15 downto 0);

    -- DAC output
    signal dac_out_internal            : signed(15 downto 0);

    -- Status register assembly
    signal status_reg0                 : std_logic_vector(15 downto 0);
    signal status_reg1                 : std_logic_vector(15 downto 0);

begin

    -- ========================================================================
    -- REGISTER MAPPING: MCC Control Registers -> Internal Signals
    -- ========================================================================
    -- Synchronous process captures control registers with reset defaults

    proc_register_interface: process(Clk)
    begin
        if rising_edge(Clk) then
            if Reset = '1' then
                -- Apply default values on reset
                ctrl_enable_internal   <= DEFAULT_ENABLE;
                ctrl_clk_en_internal   <= DEFAULT_CLK_EN;
                cfg_delay_s1_internal  <= DEFAULT_DELAY_S1;
                cfg_delay_s2_internal  <= DEFAULT_DELAY_S2;
                cfg_delay_s3_internal  <= DEFAULT_DELAY_S3;
                cfg_delay_s4_internal  <= DEFAULT_DELAY_S4;
            else
                -- Capture control registers
                ctrl_enable_internal   <= Control0(0);
                ctrl_clk_en_internal   <= Control0(1);
                cfg_delay_s1_internal  <= unsigned(Control2(6 downto 0));
                cfg_delay_s2_internal  <= unsigned(Control3(6 downto 0));
                cfg_delay_s3_internal  <= unsigned(Control4(6 downto 0));
                cfg_delay_s4_internal  <= unsigned(Control5(6 downto 0));
            end if;
        end if;
    end process proc_register_interface;

    -- ========================================================================
    -- STATUS REGISTER ASSEMBLY
    -- ========================================================================

    -- Status Register 0: FSM sticky status (bits 0-3 mark S1-S4 first entry)
    status_reg0 <= std_logic_vector(resize(stat_fsm_status_internal, 16));

    -- Status Register 1: Current state (bits 3:0) + Monitor MSBs (bits 15:4)
    status_reg1 <= std_logic_vector(stat_monitor_internal(15 downto 4)) & stat_state_oh_internal;

    -- ========================================================================
    -- OUTPUT MAPPING: Internal Signals -> MCC Outputs
    -- ========================================================================

    -- OutputA: Primary DAC output (signed 16-bit, stair-step levels)
    OutputA <= dac_out_internal;

    -- OutputB: Status register 0 (FSM sticky status)
    OutputB <= signed(status_reg0);

    -- OutputC: Status register 1 (current state + monitor)
    OutputC <= signed(status_reg1);

    -- ========================================================================
    -- EMFI_SEQ_TOP INSTANTIATION
    -- ========================================================================
    -- Direct instantiation (required for top layer per CLAUDE.md)
    -- Integrates FSM sequencer and analog monitor cores

    U_EMFI_SEQ_TOP: entity work.EMFI_Seq_Top
        port map (
            -- System interface
            clk             => Clk,
            rst             => Reset,

            -- Control interface
            ctrl_enable     => ctrl_enable_internal,
            clk_en          => ctrl_clk_en_internal,

            -- Configuration interface (per-state delays)
            cfg_delay_s1    => cfg_delay_s1_internal,
            cfg_delay_s2    => cfg_delay_s2_internal,
            cfg_delay_s3    => cfg_delay_s3_internal,
            cfg_delay_s4    => cfg_delay_s4_internal,

            -- Status interface
            stat_fsm_status => stat_fsm_status_internal,
            stat_state_oh   => stat_state_oh_internal,
            stat_monitor    => stat_monitor_internal,

            -- DAC output
            dac_out         => dac_out_internal
        );

end architecture behavioural;

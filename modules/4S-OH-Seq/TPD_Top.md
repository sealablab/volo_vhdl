``` vhdl
--------------------------------------------------------------------------------
-- TPD_Top.vhd
--
-- TPD (Trivial Probe Driver) - Moku Top-Level Module
--
-- Description:
--   Top-level module for Moku device integration
--   Maps Moku control registers to TPD-MED module
--   Implements register-based control interface
--
-- NOTE: This module should be instantiated by the Moku CustomWrapper template.
--       Do NOT name this entity "CustomWrapper" as MCC reserves that name.
--
-- Register Map:
--   Control0 [31:0]:
--     Bit 31      : gDisable (global disable, active high)
--     Bit 30-24   : Reserved
--     Bit 23      : SOFT-TRIGGER (software trigger, write 1 to trigger)
--     Bit 22-16   : IntensityLut-Index (7-bit, reserved for future use)
--     Bit 15-12   : Probe_cooldown (4-bit, cooldown cycles)
--     Bit 11-8    : Probe_fire (4-bit, firing cycles)
--     Bit 7-0     : Reserved
--
--   Control1 [31:0]:
--     Bit 31-16   : trig_out_level (signed 16-bit, trigger output level)
--     Bit 15-8    : Reserved
--     Bit 7-0     : delay_cnt (8-bit unsigned, delay cycles)
--
--   Control2-15  : Reserved for future use
--
-- Input Map:
--   InputA[0]    : External trigger input
--   InputA[15:1] : Reserved
--   InputB       : Reserved
--   InputC       : Reserved
--
-- Output Map:
--   OutputA      : trigger_out (signed 16-bit)
--   OutputB      : intensity_out (signed 16-bit)
--   OutputC      : status_reg (8-bit status extended to signed 16-bit)
--
-- Trigger Logic:
--   trig_in = InputA[0] OR Control0[23] (external OR software trigger)
--
-- Author: Claude Code
-- Date: 2025-01-27
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity TPD_Top is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;  -- Active high reset

        -- Input signals
        InputA  : in  signed(15 downto 0);  -- Bit 0: External trigger
        InputB  : in  signed(15 downto 0);  -- Reserved
        InputC  : in  signed(15 downto 0);  -- Reserved

        -- Output signals
        OutputA : out signed(15 downto 0);  -- trigger_out
        OutputB : out signed(15 downto 0);  -- intensity_out
        OutputC : out signed(15 downto 0);  -- status_reg (extended)

        -- Control registers
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
        Control13  : in  std_logic_vector(31 downto 0);
        Control14 : in  std_logic_vector(31 downto 0);
        Control15 : in  std_logic_vector(31 downto 0)
    );
end entity TPD_Top;

architecture rtl of TPD_Top is

    -- Internal reset signal (active low for tpd_med)
    signal n_reset : std_logic;

    -- Control0 field extraction
    signal ctrl_global_disable  : std_logic;
    signal ctrl_soft_trigger    : std_logic;
    signal ctrl_intensity_index : std_logic_vector(6 downto 0);
    signal cfg_cooldown_cnt     : unsigned(7 downto 0);  -- Extended to 8-bit
    signal cfg_firing_cnt       : unsigned(7 downto 0);  -- Extended to 8-bit

    -- Control1 field extraction
    signal cfg_trig_out_level   : signed(15 downto 0);
    signal cfg_intens_out_level : signed(15 downto 0);
    signal cfg_delay_cnt        : unsigned(7 downto 0);

    -- Trigger logic
    signal external_trigger     : std_logic;
    signal combined_trigger     : std_logic;
    signal trig_in              : std_logic;

    -- TPD-MED outputs
    signal tpd_trigger_out      : signed(15 downto 0);
    signal tpd_intensity_out    : signed(15 downto 0);
    signal tpd_status_reg       : std_logic_vector(7 downto 0);

    -- Global enable (inverse of disable)
    signal global_enable        : std_logic;

begin

    -- Convert active high reset to active low
    n_reset <= not Reset;

    -- Global enable (inverse of global disable)
    global_enable <= not ctrl_global_disable;

    -- =========================================================================
    -- Control Register Field Extraction
    -- =========================================================================

    -- Control0 field extraction
    ctrl_global_disable  <= Control0(31);
    ctrl_soft_trigger    <= Control0(23);
    ctrl_intensity_index <= Control0(22 downto 16);
    cfg_cooldown_cnt     <= resize(unsigned(Control0(15 downto 12)), 8);  -- 4-bit to 8-bit
    cfg_firing_cnt       <= resize(unsigned(Control0(11 downto 8)), 8);   -- 4-bit to 8-bit

    -- Control1 field extraction
    cfg_trig_out_level   <= signed(Control1(31 downto 16));  -- Upper 16 bits
    cfg_intens_out_level <= signed(Control1(31 downto 16));  -- Use same value for both
    cfg_delay_cnt        <= unsigned(Control1(7 downto 0));  -- Lower 8 bits

    -- =========================================================================
    -- Trigger Logic
    -- =========================================================================

    -- External trigger from InputA bit 0
    external_trigger <= InputA(0);

    -- Combined trigger: external OR software trigger
    combined_trigger <= external_trigger or ctrl_soft_trigger;

    -- Final trigger (gated by global enable)
    trig_in <= combined_trigger and global_enable;

    -- =========================================================================
    -- TPD-MED Module Instantiation
    -- =========================================================================

    U_tpd_med: entity WORK.tpd_med
        port map (
            -- Clock and reset
            clk              => Clk,
            n_reset          => n_reset,

            -- Control input
            trig_in          => trig_in,

            -- FSM configuration parameters
            delay_cnt_in     => cfg_delay_cnt,
            firing_cnt_in    => cfg_firing_cnt,
            cooldown_cnt_in  => cfg_cooldown_cnt,

            -- Output level control
            trig_out_level   => cfg_trig_out_level,
            intens_out_level => cfg_intens_out_level,

            -- Outputs
            trigger_out      => tpd_trigger_out,
            intensity_out    => tpd_intensity_out,
            state_reg_out    => tpd_status_reg
        );

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================

    -- OutputA: trigger_out (gated by global enable)
    OutputA <= tpd_trigger_out when global_enable = '1' else (others => '0');

    -- OutputB: intensity_out (gated by global enable)
    OutputB <= tpd_intensity_out when global_enable = '1' else (others => '0');

    -- OutputC: status_reg extended to 16-bit signed
    -- Upper byte: all zeros
    -- Lower byte: status register
    OutputC <= resize(signed('0' & tpd_status_reg), 16);

end architecture rtl;

```


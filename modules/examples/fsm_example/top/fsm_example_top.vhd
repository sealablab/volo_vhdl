--------------------------------------------------------------------------------
-- FSM Example Top (with FSM Observer)
--
-- Purpose: Integration module demonstrating fsm_observer pattern.
--          Instantiates fsm_example_core + fsm_observer for validation.
--
-- Tier: 1 (Strict RTL)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.volo_voltage_pkg.all;

entity fsm_example_top is
    port (
        -- Clock and reset
        clk        : in  std_logic;
        n_reset    : in  std_logic;

        -- Control inputs
        enable     : in  std_logic;
        start      : in  std_logic;

        -- Fault injection
        inject_error : in  std_logic;
        inject_fault : in  std_logic;

        -- Observer output (oscilloscope debug)
        voltage_out  : out signed(15 downto 0);

        -- Status outputs
        is_idle    : out std_logic;
        is_running : out std_logic;
        is_fault   : out std_logic
    );
end entity fsm_example_top;

architecture rtl of fsm_example_top is

    signal state_vector : std_logic_vector(5 downto 0);

begin

    -- ========================================================================
    -- FSM Core
    -- ========================================================================
    CORE: entity work.fsm_example_core
        port map (
            clk          => clk,
            n_reset      => n_reset,
            enable       => enable,
            start        => start,
            inject_error => inject_error,
            inject_fault => inject_fault,
            state_out    => state_vector,
            is_idle      => is_idle,
            is_running   => is_running,
            is_fault     => is_fault
        );

    -- ========================================================================
    -- FSM Observer (Manual integration - validates the pattern!)
    -- ========================================================================
    FSM_OBS: entity work.fsm_observer
        generic map (
            NUM_STATES            => 8,     -- 8 states total
            V_MIN                 => 0.0,   -- IDLE at ground
            V_MAX                 => 2.5,   -- RUNNING at 2.5V
            FAULT_STATE_THRESHOLD => 6,     -- ERROR/FAULT are states 6-7

            -- State names (copied from core constants)
            STATE_0_NAME => "IDLE",
            STATE_1_NAME => "REQUEST",
            STATE_2_NAME => "LOADING",
            STATE_3_NAME => "VALIDATING",
            STATE_4_NAME => "READY",
            STATE_5_NAME => "RUNNING",
            STATE_6_NAME => "ERROR",      -- ⚠️ Fault state
            STATE_7_NAME => "FAULT"       -- ⚠️ Fault state
        )
        port map (
            clk          => clk,
            reset        => n_reset,
            state_vector => state_vector,
            voltage_out  => voltage_out
        );

end architecture rtl;

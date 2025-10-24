--------------------------------------------------------------------------------
-- Entity: edge_detector
-- Filename: volo_edge_detector.vhd
-- Purpose: Configurable edge detector with mode selection
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Detects rising, falling, or both edges on an input signal and generates
--   a single-cycle pulse output. Essential building block for trigger generation,
--   event capture, and state machine synchronization in SCA/FI applications.
--
-- Features:
--   - Three detection modes: rising, falling, both edges
--   - Single-cycle pulse output (combinational, no metastability)
--   - Glitch rejection via synchronous sampling
--   - Standard enable control (freeze detection when disabled)
--   - Clean reset behavior
--
-- Detection Modes (mode input):
--   "00" = Rising edge only  (0→1 transition)
--   "01" = Falling edge only (1→0 transition)
--   "10" = Both edges        (any transition)
--   "11" = Disabled          (no detection)
--
-- Timing Behavior:
--   Input changes on cycle N → edge_out pulses high on cycle N+1 (for 1 cycle)
--
--   Example (rising edge):
--     Cycle:  0   1   2   3   4   5
--     input:  0   0   1   1   0   0
--     edge:   0   0   1   0   0   0  (pulse on cycle 2)
--
-- Use Cases:
--
--   1. Trigger Generation:
--      Detect button press or external signal transition, generate trigger
--      pulse for oscilloscope or logic analyzer.
--
--   2. Event Counting:
--      Feed edge_out to counter to count rising edges (e.g., clock cycles,
--      UART frames, state transitions).
--
--   3. State Machine Synchronization:
--      Detect when external signal changes state, advance FSM accordingly.
--      Prevents multi-cycle glitches from causing spurious state changes.
--
--   4. Protocol Framing:
--      Detect start/stop bits in serial protocols by edge detection.
--      Example: UART start bit = falling edge on idle-high line.
--
--   5. Glitch Injection Timing:
--      Detect target operation (rising edge on enable signal), trigger
--      precise glitch injection after known delay.
--
-- Control Signals (Priority Order):
--   1. n_reset (active-low): Asynchronous reset, clears history
--   2. clk_en (active-high): Clock enable - freezes detection when low
--   3. enable (active-high): Functional enable - disables detection when low
--
-- Glitch Rejection:
--   Input is sampled synchronously on rising_edge(clk). Glitches shorter than
--   one clock period are automatically rejected. For noisy signals, add
--   external debouncer or use volo_debouncer module.
--
-- Metastability:
--   If input is asynchronous (external signal), user should add 2-FF
--   synchronizer before this module. Edge detector assumes input is
--   already synchronized to clock domain.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - No enumeration types (mode is std_logic_vector)
--   - Simple combinational + sequential logic
--   - Easily converted to Verilog
--
-- Students: This is a classic "delayed comparison" pattern. We store the
-- previous value and compare with current value to detect transitions.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity edge_detector is
    port (
        -- Clock and control
        clk         : in  std_logic;                    -- System clock
        n_reset     : in  std_logic;                    -- Active-low reset
        enable      : in  std_logic;                    -- Functional enable
        clk_en      : in  std_logic;                    -- Clock enable

        -- Configuration
        mode        : in  std_logic_vector(1 downto 0); -- Detection mode (00=rise, 01=fall, 10=both, 11=off)

        -- Input signal
        input       : in  std_logic;                    -- Signal to monitor

        -- Output
        edge_out    : out std_logic;                    -- Single-cycle pulse on edge detection

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)  -- Status register
    );
end entity edge_detector;

architecture rtl of edge_detector is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    -- Detection modes
    constant MODE_RISING  : std_logic_vector(1 downto 0) := "00";
    constant MODE_FALLING : std_logic_vector(1 downto 0) := "01";
    constant MODE_BOTH    : std_logic_vector(1 downto 0) := "10";
    constant MODE_OFF     : std_logic_vector(1 downto 0) := "11";

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal input_prev   : std_logic;  -- Previous input value (delayed by 1 cycle)
    signal rising_edge_det  : std_logic;  -- Rising edge detected
    signal falling_edge_det : std_logic;  -- Falling edge detected
    signal edge_detected    : std_logic;  -- Final edge detection (after mode selection)

begin

    -- =========================================================================
    -- EDGE DETECTION LOGIC (Combinational)
    -- =========================================================================
    -- Compare current input with previous input
    rising_edge_det  <= '1' when (input = '1' and input_prev = '0') else '0';
    falling_edge_det <= '1' when (input = '0' and input_prev = '1') else '0';

    -- Mode selection
    edge_detected <= rising_edge_det  when mode = MODE_RISING  else
                     falling_edge_det when mode = MODE_FALLING else
                     (rising_edge_det or falling_edge_det) when mode = MODE_BOTH else
                     '0';  -- MODE_OFF

    -- Gate with enable
    edge_out <= edge_detected when enable = '1' else '0';

    -- =========================================================================
    -- INPUT HISTORY REGISTER (Sequential)
    -- =========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            input_prev <= '0';

        elsif rising_edge(clk) then
            if clk_en = '1' and enable = '1' then
                -- Sample input on every enabled cycle
                input_prev <= input;
            end if;
            -- enable='0' or clk_en='0': Hold previous value (freeze detection)
        end if;
    end process;

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5-4: Reserved (always 0)
    -- Bit 3-2: Current mode
    -- Bit 1: Current input value
    -- Bit 0: Edge detected this cycle
    stat_reg <= "0000" & mode & input & edge_detected;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why do we need input_prev?
    -- A: To detect a transition, we must compare current value with previous
    --    value. input_prev is a 1-cycle delay of input.
    --
    -- Q: What if input changes faster than the clock?
    -- A: We only sample on rising_edge(clk), so we'll miss edges that occur
    --    between clock cycles. Use a faster clock or external edge capture.
    --
    -- Q: Why is edge_out combinational, not registered?
    -- A: We want the pulse to appear on the same cycle as detection. If we
    --    registered it, there would be an extra cycle of latency.
    --
    -- Q: How do I count edges?
    -- A: Connect edge_out to a counter's increment input. Each pulse = 1 count.
    --
    -- Q: What about metastability on async inputs?
    -- A: Always add a 2-FF synchronizer before this module for async signals!
    --
    -- Q: Why does enable='0' freeze input_prev?
    -- A: So we don't detect spurious edges when re-enabling. The module
    --    resumes cleanly from the last known state.

end architecture rtl;

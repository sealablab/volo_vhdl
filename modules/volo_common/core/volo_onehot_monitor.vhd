--------------------------------------------------------------------------------
-- Entity: onehot_analog_monitor
-- Filename: volo_onehot_monitor.vhd
-- Purpose: One-hot state to analog voltage monitor (FSM visualization tool)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
-- Origin: Migrated from EMFI-Seq/core/EMFI_Seq_stair.vhd
--
-- Description:
--   Maps a one-hot encoded state vector to configurable analog voltage levels
--   for oscilloscope visualization of FSM state transitions. Pure combinational
--   logic - no clock, no registers, minimal resource usage.
--
-- Use Cases:
--   - Debug FSM state machines visually on oscilloscope
--   - Set voltage-based triggers for specific states
--   - Educational tool: students SEE state transitions as stair-steps
--   - Multi-instrument coordination (trigger on state changes)
--
-- One-Hot Encoding Primer:
--   Each state is represented by a single bit high in the state vector:
--     State 1: "0001"
--     State 2: "0010"
--     State 3: "0100"
--     State 4: "1000"
--   Invalid/multi-bit states → failsafe (0V output)
--
-- Typical Usage:
--   - S1 → 1.1V (lower threshold)
--   - S2 → 1.2V
--   - S3 → 1.3V
--   - S4 → 1.4V (upper threshold)
--   Oscilloscope shows clean stair-step pattern as FSM transitions!
--
-- Moku Platform Integration:
--   - Output: 16-bit signed DAC (-5V to +5V range)
--   - Uses Moku_Voltage_pkg for accurate voltage conversion
--   - Connects to OutputA/B/C/D via CustomWrapper
--   - Levels configurable via Control registers (runtime)
--
-- Verilog Portability:
--   - Pure combinational logic (easy to convert)
--   - No records, no complex types
--   - Standard signed/unsigned types only
--
-- Students: This is a "combinational MUX" - no state, no timing complexity.
-- It's like a lookup table: given a state (one-hot), output a voltage.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.Moku_Voltage_pkg.all;

entity onehot_analog_monitor is
    port (
        -- One-hot state input (4 states: S1..S4)
        -- Only ONE bit should be high at a time!
        -- Examples:
        --   "0001" = State 1
        --   "0010" = State 2
        --   "0100" = State 3
        --   "1000" = State 4
        --   "0000" or "0011" or others = Invalid (failsafe to 0V)
        state_oh      : in  std_logic_vector(3 downto 0);

        -- Configurable voltage levels for each state (16-bit signed DAC codes)
        -- These are runtime-configurable via Control registers
        -- Typical values (Moku voltage encoding):
        --   1.1V = 0x199A = 6554
        --   1.2V = 0x1EB8 = 7864
        --   1.3V = 0x23D7 = 9175
        --   1.4V = 0x28F5 = 10485
        level_s1      : in  signed(15 downto 0);  -- State 1 voltage
        level_s2      : in  signed(15 downto 0);  -- State 2 voltage
        level_s3      : in  signed(15 downto 0);  -- State 3 voltage
        level_s4      : in  signed(15 downto 0);  -- State 4 voltage

        -- DAC output (16-bit signed, Moku voltage mapping)
        -- Range: -5V (0x8000) to +5V (0x7FFF), 0V (0x0000)
        -- Connect to CustomWrapper OutputA/B/C/D
        dac_out_s16   : out signed(15 downto 0);

        -- Unsigned mirror for teaching/debugging (same bits, different interpretation)
        -- Useful for ILA probes, teaching two's complement vs unsigned
        monitor_u16   : out unsigned(15 downto 0)
    );
end entity onehot_analog_monitor;

architecture rtl of onehot_analog_monitor is

    -- Failsafe value for invalid one-hot states (0V)
    -- If multiple bits are high or all low, output safe default
    constant CODE_FAILSAFE : signed(15 downto 0) := voltage_to_digital(0.0);

begin

    -- =========================================================================
    -- COMBINATIONAL ONE-HOT DECODER
    -- =========================================================================
    -- Pure MUX: state_oh selects which level to output
    -- Students: This is synthesized as a 4:1 multiplexer (very fast, <1 LUT!)

    with state_oh select
        dac_out_s16 <= level_s1        when "0001",  -- State 1
                       level_s2        when "0010",  -- State 2
                       level_s3        when "0100",  -- State 3
                       level_s4        when "1000",  -- State 4
                       CODE_FAILSAFE  when others;   -- Invalid (failsafe)

    -- Unsigned mirror (no arithmetic, just reinterpret bits)
    -- Useful for debugging: compare signed vs unsigned views
    monitor_u16 <= unsigned(dac_out_s16);

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why one-hot instead of binary (00, 01, 10, 11)?
    -- A: Faster decoding in FPGAs! One-hot uses more flip-flops but fewer LUTs.
    --    Also easier to debug - just look at which bit is high.
    --
    -- Q: What if two bits are high at once?
    -- A: "others" case catches it → failsafe 0V output. Good defensive coding!
    --
    -- Q: Why signed for DAC output?
    -- A: Moku uses two's complement for bipolar signals (-5V to +5V).
    --    0x0000 = 0V, 0x7FFF = +5V, 0x8000 = -5V.
    --
    -- Q: Can I use this for 8 states? 16 states?
    -- A: Yes! Just expand state_oh to 8 or 16 bits and add more levels.
    --    Keep the one-hot encoding (only 1 bit high at a time).

end architecture rtl;

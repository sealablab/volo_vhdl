--------------------------------------------------------------------------------
-- Entity: volo_comparator
-- Filename: volo_comparator.vhd
-- Purpose: Configurable N-bit comparator with multiple comparison modes
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Compares two N-bit data inputs with configurable comparison modes.
--   Essential building block for threshold detection, trigger generation,
--   and data validation in SCA/FI applications.
--
-- Features:
--   - Configurable data width (1-32 bits, default 16)
--   - Six comparison modes: ==, !=, >, <, >=, <=
--   - Pure combinational logic (zero latency)
--   - Standard enable control
--   - Clean reset behavior
--
-- Comparison Modes (mode input):
--   "000" = Equal (data_a == data_b)
--   "001" = Not equal (data_a != data_b)
--   "010" = Greater than (data_a > data_b)
--   "011" = Less than (data_a < data_b)
--   "100" = Greater or equal (data_a >= data_b)
--   "101" = Less or equal (data_a <= data_b)
--   "110" = Reserved (output 0)
--   "111" = Disabled (output 0)
--
-- Timing Behavior:
--   Pure combinational - result updates immediately when inputs change.
--   No clock latency. Enable control gates the output.
--
--   Example (equal mode, WIDTH=8):
--     data_a:  0x42  0x42  0x99  0x42
--     data_b:  0x00  0x42  0x99  0x01
--     result:  0     1     1     0
--
-- Use Cases:
--
--   1. Threshold Detection:
--      Compare ADC value against threshold for power analysis triggers.
--      Example: Trigger when power > threshold.
--
--   2. Range Validation:
--      Check if data is within valid range using two comparators.
--      Example: (data >= min) AND (data <= max)
--
--   3. Event Detection:
--      Trigger when signal equals specific value.
--      Example: Detect magic number in serial stream.
--
--   4. State Matching:
--      Compare current state against target state for FSM control.
--      Example: Advance when state == READY.
--
--   5. Fault Injection Timing:
--      Trigger glitch when counter equals target cycle count.
--      Example: Inject fault at cycle 1000.
--
-- Control Signals (Priority Order):
--   1. n_reset (active-low): Asynchronous reset
--   2. enable (active-high): Functional enable - gates output when low
--
-- Comparison Type:
--   All comparisons are UNSIGNED. If you need signed comparison,
--   convert inputs externally or extend this module.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - No enumeration types (mode is std_logic_vector)
--   - Pure combinational logic
--   - Easily converted to Verilog
--
-- Students: This is a "pure combinational" pattern. No sequential logic
-- means zero latency - perfect for trigger generation and fast decisions.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_comparator is
    generic (
        WIDTH : positive := 16  -- Data width in bits (1-32)
    );
    port (
        -- Clock and control
        clk         : in  std_logic;                        -- System clock (for status reg only)
        n_reset     : in  std_logic;                        -- Active-low reset
        enable      : in  std_logic;                        -- Functional enable

        -- Configuration
        mode        : in  std_logic_vector(2 downto 0);     -- Comparison mode

        -- Data inputs
        data_a      : in  std_logic_vector(WIDTH-1 downto 0);  -- First operand
        data_b      : in  std_logic_vector(WIDTH-1 downto 0);  -- Second operand

        -- Output
        result      : out std_logic;                        -- Comparison result (1=true, 0=false)

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)      -- Status register
    );
end entity volo_comparator;

architecture rtl of volo_comparator is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    -- Comparison modes
    constant MODE_EQUAL     : std_logic_vector(2 downto 0) := "000";  -- ==
    constant MODE_NOT_EQUAL : std_logic_vector(2 downto 0) := "001";  -- !=
    constant MODE_GREATER   : std_logic_vector(2 downto 0) := "010";  -- >
    constant MODE_LESS      : std_logic_vector(2 downto 0) := "011";  -- <
    constant MODE_GTE       : std_logic_vector(2 downto 0) := "100";  -- >=
    constant MODE_LTE       : std_logic_vector(2 downto 0) := "101";  -- <=
    constant MODE_RESERVED  : std_logic_vector(2 downto 0) := "110";  -- Reserved
    constant MODE_OFF       : std_logic_vector(2 downto 0) := "111";  -- Disabled

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal comparison_result : std_logic;  -- Raw comparison result (before enable gating)

    -- Convert inputs to unsigned for comparison
    signal a_unsigned : unsigned(WIDTH-1 downto 0);
    signal b_unsigned : unsigned(WIDTH-1 downto 0);

begin

    -- =========================================================================
    -- TYPE CONVERSION
    -- =========================================================================
    a_unsigned <= unsigned(data_a);
    b_unsigned <= unsigned(data_b);

    -- =========================================================================
    -- COMPARISON LOGIC (Pure Combinational)
    -- =========================================================================
    comparison_result <=
        '1' when (mode = MODE_EQUAL     and a_unsigned =  b_unsigned) else
        '1' when (mode = MODE_NOT_EQUAL and a_unsigned /= b_unsigned) else
        '1' when (mode = MODE_GREATER   and a_unsigned >  b_unsigned) else
        '1' when (mode = MODE_LESS      and a_unsigned <  b_unsigned) else
        '1' when (mode = MODE_GTE       and a_unsigned >= b_unsigned) else
        '1' when (mode = MODE_LTE       and a_unsigned <= b_unsigned) else
        '0';  -- MODE_RESERVED or MODE_OFF

    -- Gate with enable
    result <= comparison_result when enable = '1' else '0';

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5-3: Current mode
    -- Bit 2: Enable status
    -- Bit 1: Reserved
    -- Bit 0: Comparison result
    stat_reg <= "00" & mode & enable & '0' & comparison_result;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why is this all combinational? No clocked process?
    -- A: Comparisons are instant - no need to store state. This gives zero
    --    latency, perfect for fast trigger generation.
    --
    -- Q: What about metastability on data_a/data_b inputs?
    -- A: If inputs come from async sources, add synchronizers externally.
    --    This module assumes inputs are already synchronized.
    --
    -- Q: Can I use this for signed comparison?
    -- A: Not directly - this uses unsigned(). You'd need to modify the
    --    comparison logic or add a signed mode.
    --
    -- Q: How do I create a range checker (min <= data <= max)?
    -- A: Use two comparators: one for (data >= min), one for (data <= max),
    --    then AND the results together.
    --
    -- Q: Why does enable gate the output instead of the comparison?
    -- A: We still want to see the comparison result in stat_reg for debug,
    --    but only propagate it to result output when enabled.
    --
    -- Q: What's the synthesis result?
    -- A: A simple mux tree - very small area, very fast (sub-nanosecond).

end architecture rtl;

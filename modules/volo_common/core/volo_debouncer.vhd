--------------------------------------------------------------------------------
-- Entity: volo_debouncer
-- Filename: volo_debouncer.vhd
-- Purpose: Configurable debouncer for noisy digital inputs
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Removes glitches and bounce from mechanical switches, buttons, and noisy
--   digital signals using a shift register with stability detection.
--
-- Features:
--   - Configurable debounce depth (2-16 samples, default 8)
--   - Shift register + "all bits equal" detection
--   - Standard enable control
--   - Configurable sample rate via clock divider
--   - Clean reset behavior
--
-- Debounce Depth (DEPTH generic):
--   2-4   = Fast debounce (0.2-0.4ms @ 10kHz sample)
--   8     = Standard debounce (0.8ms @ 10kHz sample) - DEFAULT
--   16    = Heavy debounce (1.6ms @ 10kHz sample)
--
-- Operation:
--   Input is sampled on each clock cycle into a shift register.
--   Output changes ONLY when all DEPTH samples are identical (stable).
--   This filters out transient glitches and mechanical bounce.
--
-- Timing Behavior:
--   Input must be stable for DEPTH+1 consecutive clocks before output changes.
--
--   Example (DEPTH=4, input changes from 0 to 1 with bounce):
--     Cycle:  0   1   2   3   4   5   6   7   8   9
--     input:  0   0   1   0   1   1   1   1   1   1  (bouncing)
--     shift:  00  00  01  10  01  11  11  11  11  11  (hex)
--     stable: Y   Y   N   N   N   N   N   N   Y   Y
--     output: 0   0   0   0   0   0   0   0   1   1  (changes at cycle 8)
--
-- Use Cases:
--
--   1. Mechanical Button Debouncing:
--      Remove bounce from tactile switches (typically 5-50ms bounce).
--      Use slow sample rate (1-10kHz) with DEPTH=8.
--
--   2. Rotary Encoder Debouncing:
--      Clean up quadrature signals from mechanical encoders.
--      Use moderate sample rate (10-100kHz) with DEPTH=4.
--
--   3. Noisy Digital Signal Filtering:
--      Remove glitches from marginally-driven logic signals.
--      Use fast sample rate (MHz) with DEPTH=2-4.
--
--   4. GPIO Input Conditioning:
--      First stage: Synchronizer (metastability protection)
--      Second stage: Debouncer (noise filtering)
--      Third stage: Edge detector (event capture)
--
--   5. Switch Matrix Scanning:
--      Debounce each switch in keyboard/keypad matrix.
--      Use array of debouncers with shared clock.
--
-- Sample Rate:
--   For mechanical switches: Use external clock divider to create 1-10kHz sample clock.
--   For digital signals: Can run at full system clock speed.
--
--   Example: 100MHz clock → 10kHz sample rate = divide by 10,000
--   Use volo_clk_divider or similar to generate debounce clock.
--
-- Debounce Time Calculation:
--   Debounce_time = (DEPTH + 1) × Sample_period
--   Example: DEPTH=8, Sample=10kHz → (8+1) × 100us = 0.9ms
--
-- Reset Behavior:
--   On reset, shift register cleared to 0, output forced to 0.
--   First stable state after reset will be output.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - Shift register + combinational comparison
--   - No complex logic
--   - Easily converted to Verilog
--
-- Students: This is how you debounce buttons! Shift register samples the input,
-- and we only trust the value when ALL samples agree. Simple but effective!
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_debouncer is
    generic (
        DEPTH : integer range 2 to 16 := 8  -- Debounce depth (samples)
    );
    port (
        -- Clock and control
        clk         : in  std_logic;        -- Sample clock (1-10kHz for switches)
        n_reset     : in  std_logic;        -- Active-low reset
        enable      : in  std_logic;        -- Enable debouncing

        -- Input (noisy signal)
        noisy_in    : in  std_logic;        -- Noisy/bouncing input

        -- Output (debounced signal)
        clean_out   : out std_logic;        -- Stable debounced output

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)  -- Status register
    );
end entity volo_debouncer;

architecture rtl of volo_debouncer is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    -- None needed for this simple module

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    -- Shift register for sampling input (fixed size, use first DEPTH elements)
    signal shift_reg : std_logic_vector(15 downto 0);

    -- Debounced output (registered)
    signal debounced : std_logic;

    -- Stability detection
    signal all_ones  : std_logic;  -- All DEPTH samples are '1'
    signal all_zeros : std_logic;  -- All DEPTH samples are '0'
    signal stable    : std_logic;  -- Signal is stable (all same)

begin

    -- =========================================================================
    -- SHIFT REGISTER (Sequential)
    -- =========================================================================
    -- Sample input into shift register on each clock
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Reset: Clear shift register
            shift_reg <= (others => '0');
            debounced <= '0';

        elsif rising_edge(clk) then
            if enable = '1' then
                -- Shift in new sample (shift all stages)
                shift_reg(0) <= noisy_in;
                for i in 1 to 15 loop
                    shift_reg(i) <= shift_reg(i-1);
                end loop;

                -- Update output based on stability
                if all_ones = '1' then
                    debounced <= '1';  -- All samples are 1, output goes high
                elsif all_zeros = '1' then
                    debounced <= '0';  -- All samples are 0, output goes low
                end if;
                -- else: hold previous value (unstable, keep debounced state)
            end if;
            -- enable='0': Hold shift register and output (freeze debouncer)
        end if;
    end process;

    -- =========================================================================
    -- STABILITY DETECTION (Combinational)
    -- =========================================================================
    -- Check if all DEPTH samples are equal (stable condition)
    -- Note: Only check first DEPTH bits of shift_reg

    -- All ones: Check if all DEPTH samples are '1'
    all_ones <= '1' when shift_reg(DEPTH-1 downto 0) = (DEPTH-1 downto 0 => '1') else '0';

    -- All zeros: Check if all DEPTH samples are '0'
    all_zeros <= '1' when shift_reg(DEPTH-1 downto 0) = (DEPTH-1 downto 0 => '0') else '0';

    -- Stable: Either all ones or all zeros
    stable <= all_ones or all_zeros;

    -- Output assignment
    clean_out <= debounced;

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5-4: Reserved
    -- Bit 3: Stable (1=all samples agree, 0=unstable)
    -- Bit 2: Current noisy input value (raw)
    -- Bit 1: First shift register sample
    -- Bit 0: Debounced output value
    stat_reg <= "0000" & stable & noisy_in & shift_reg(0) & debounced;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why do we need debouncing?
    -- A: Mechanical switches "bounce" when pressed - the contacts make/break
    --    multiple times over 5-50ms before settling. This creates false edges.
    --
    -- Q: How does the shift register help?
    -- A: We sample the input multiple times. Only when ALL samples agree do
    --    we trust the value. This filters out short glitches and bounce.
    --
    -- Q: What happens during bounce?
    -- A: The shift register contains a mix of 0s and 1s. The output holds its
    --    previous stable value until all samples agree on the new state.
    --
    -- Q: Why use a slow clock for mechanical switches?
    -- A: Switches bounce for milliseconds. Sampling at 10kHz (100us period)
    --    with DEPTH=8 gives 0.9ms debounce time - enough for most switches.
    --    Faster sampling wastes power and doesn't help.
    --
    -- Q: Can I use this for digital signals?
    -- A: Yes! For glitch filtering on fast digital signals, use system clock
    --    with DEPTH=2-4 to filter out short glitches (nanoseconds).
    --
    -- Q: What if I need faster response?
    -- A: Reduce DEPTH (faster but less noise immunity) or increase sample rate
    --    (but make sure DEPTH × sample_period still exceeds bounce time).
    --
    -- Q: Should I put synchronizer before debouncer?
    -- A: YES! For async inputs: Synchronizer (CDC) → Debouncer (noise) → Edge Detector

end architecture rtl;

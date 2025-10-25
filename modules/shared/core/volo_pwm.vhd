--------------------------------------------------------------------------------
-- Entity: volo_pwm
-- Filename: volo_pwm.vhd
-- Purpose: Simple 8-bit PWM generator with fixed 256-cycle period
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Pulse Width Modulation (PWM) generator with fixed 8-bit resolution.
--   Simple free-running counter with duty cycle comparison for reliable operation.
--
-- Features:
--   - Fixed 8-bit resolution (256 steps)
--   - Configurable duty cycle (0-255)
--   - Free-running counter (no load operation)
--   - Standard enable control
--   - Clean reset behavior
--   - Status register with counter value
--
-- PWM Resolution:
--   8-bit = 256 steps (0-255)
--   Duty cycle range: 0% (0) to 100% (255)
--   Period: 256 clock cycles (fixed)
--
-- Operation:
--   Counter increments every clock cycle (when enabled).
--   Output = '1' when counter < duty_cycle, else '0'.
--   Counter wraps automatically from 255 to 0.
--
-- Timing Behavior:
--   PWM period = 256 clock cycles
--   Duty cycle determines ON time (0-255 cycles)
--
--   Example (duty_cycle=64, freq=100MHz):
--     Period = 256 × 10ns = 2.56us (390kHz PWM)
--     ON time = 64 × 10ns = 640ns (25% duty cycle)
--
-- Use Cases:
--
--   1. LED Dimming:
--      Control LED brightness with duty cycle.
--      Example: duty_cycle=128 → 50% brightness.
--
--   2. Motor Speed Control:
--      Vary motor speed with PWM duty cycle.
--      Example: duty_cycle=192 → 75% speed.
--
--   3. DAC (Digital-to-Analog):
--      Low-pass filter PWM output for analog voltage.
--      Example: duty_cycle=200 → ~3.9V (from 5V, 78% duty).
--
--   4. Servo Control:
--      Generate servo pulses with varying duty cycle.
--      Use external divider for 50Hz base frequency.
--
--   5. Heating Element Control:
--      Control heater power with PWM (low frequency).
--      Use divider for slow PWM (Hz range).
--
-- Duty Cycle Calculation:
--   duty_percent = (duty_cycle / 256) × 100%
--   Examples:
--     duty_cycle=0   → 0% (always off)
--     duty_cycle=64  → 25%
--     duty_cycle=128 → 50%
--     duty_cycle=192 → 75%
--     duty_cycle=255 → 99.6% (almost always on)
--
-- Frequency Calculation:
--   PWM_freq = Clock_freq / 256
--   Examples:
--     100MHz clock → 390.6kHz PWM
--     10MHz clock  → 39.06kHz PWM
--     1MHz clock   → 3.906kHz PWM
--
-- For lower PWM frequencies, use external clock divider before this module.
--
-- Reset Behavior:
--   On reset, counter cleared to 0, output forced to 0.
--   PWM resumes from counter=0 on first enabled clock.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - Fixed-width counter (8-bit)
--   - Simple comparison logic
--   - No generic WIDTH (avoid GHDL issues)
--   - Easily converted to Verilog
--
-- Design Notes:
--   This module uses a FIXED 8-bit counter to avoid the generic WIDTH
--   issues and metavalue warnings seen in volo_pulse_generator and
--   volo_counter_nbit. Simplicity over flexibility for reliability!
--
-- Students: PWM is just a counter + comparison! Counter goes 0→255, output
-- is high when counter < duty_cycle. Simple but powerful for analog control!
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_pwm is
    port (
        -- Clock and control
        clk         : in  std_logic;                        -- System clock
        n_reset     : in  std_logic;                        -- Active-low reset
        enable      : in  std_logic;                        -- Enable PWM

        -- Configuration
        duty_cycle  : in  std_logic_vector(7 downto 0);     -- Duty cycle (0-255)

        -- Output
        pwm_out     : out std_logic;                        -- PWM output

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)      -- Status register
    );
end entity volo_pwm;

architecture rtl of volo_pwm is

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    -- 8-bit counter (FIXED width to avoid generic issues!)
    signal counter : unsigned(7 downto 0);

    -- PWM output (before enable gating)
    signal pwm_raw : std_logic;

begin

    -- =========================================================================
    -- COUNTER (Sequential)
    -- =========================================================================
    -- Simple free-running up-counter, wraps at 255
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Reset: Clear counter
            counter <= (others => '0');

        elsif rising_edge(clk) then
            if enable = '1' then
                -- Increment counter (wraps automatically at 255→0)
                counter <= counter + 1;
            end if;
            -- enable='0': Hold counter (freeze PWM)
        end if;
    end process;

    -- =========================================================================
    -- PWM GENERATION (Combinational)
    -- =========================================================================
    -- Output = '1' when counter < duty_cycle, else '0'
    pwm_raw <= '1' when counter < unsigned(duty_cycle) else '0';

    -- Gate with enable and reset
    pwm_out <= pwm_raw when (enable = '1' and n_reset = '1') else '0';

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7-0: Current counter value (for debug/sync)
    --
    -- Note: This allows external logic to read the current PWM phase.
    -- Useful for synchronizing multiple PWM generators or debugging.
    stat_reg <= std_logic_vector(counter);

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why fixed 8-bit instead of generic WIDTH?
    -- A: Generic WIDTH caused metavalue warnings in previous modules
    --    (volo_pulse_generator, volo_counter_nbit). Fixed width is more
    --    reliable in GHDL simulation. If you need higher resolution, use
    --    a slower clock or cascade multiple PWMs.
    --
    -- Q: How do I get 10-bit or 12-bit PWM?
    -- A: Use an external clock divider to slow down this module's clock.
    --    Example: Divide by 4 → effectively 10-bit PWM (1024 steps).
    --    Or create volo_pwm_10bit with explicit 10-bit signals (not generic).
    --
    -- Q: Can I change duty_cycle on the fly?
    -- A: Yes! duty_cycle can change at any time. The PWM output will reflect
    --    the new value on the next counter cycle. No glitches.
    --
    -- Q: What if duty_cycle=0?
    -- A: Output always 0 (counter is never < 0). 0% duty cycle.
    --
    -- Q: What if duty_cycle=255?
    -- A: Output high for 255 out of 256 cycles (99.6% duty). Almost always on.
    --
    -- Q: How do I make PWM frequency lower?
    -- A: Use a clock divider before this module. Example:
    --    100MHz → divide by 256 → 390kHz → this PWM → 1.5kHz PWM output.
    --
    -- Q: Can I synchronize multiple PWMs?
    -- A: Yes! Reset all PWMs together, they'll start in sync. Or read
    --    stat_reg to phase-align them.

end architecture rtl;

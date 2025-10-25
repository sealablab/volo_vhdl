--------------------------------------------------------------------------------
-- Entity: delay_line
-- Filename: volo_delay_line.vhd
-- Purpose: Configurable digital delay line (shift register)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Delays a digital signal by a configurable number of clock cycles using
--   a shift register. Essential for signal alignment, timing adjustments,
--   and synchronization in SCA/FI applications.
--
-- Features:
--   - Configurable delay: 1-256 cycles
--   - Single-bit input/output
--   - Standard enable control (freeze/resume)
--   - Clean reset behavior
--   - Zero overhead for delay=0 (bypass mode)
--
-- Delay Configuration (delay_cycles input):
--   0x00 = 0 cycles  (bypass - output = input)
--   0x01 = 1 cycle   (output delayed by 1 clock)
--   0x0F = 15 cycles
--   0xFF = 255 cycles (maximum delay)
--
-- Timing Behavior:
--   delay_cycles = 0: output = input (same cycle, bypass)
--   delay_cycles = 1: output follows input after 1 clock cycle
--   delay_cycles = N: output follows input after N clock cycles
--
--   Example (delay_cycles = 2):
--     Cycle:  0   1   2   3   4   5
--     input:  0   1   0   1   1   0
--     output: X   X   0   1   0   1  (2-cycle delay)
--
-- Use Cases:
--
--   1. Signal Alignment:
--      Align data signals with delayed control signals for proper timing.
--      Example: Align trigger with delayed ADC data capture.
--
--   2. Pipeline Balancing:
--      Match delays between parallel processing paths.
--      Example: Equalize path delays in multi-channel systems.
--
--   3. Timing Adjustments:
--      Fine-tune signal timing for protocol compliance.
--      Example: Delay chip-select relative to clock for SPI timing.
--
--   4. Glitch Injection Timing:
--      Delay trigger signal to inject glitch at precise offset.
--      Example: "Trigger + 10 cycles → inject glitch"
--
--   5. Synchronization:
--      Add programmable delay for cross-clock-domain synchronization.
--
-- Implementation:
--   - Uses shift register (255 FFs maximum)
--   - Delay is programmable but constant during operation
--   - Output muxed from shift register based on delay_cycles
--
-- Reset Behavior:
--   - Shift register cleared to all zeros
--   - Output will be 0 until valid data propagates through delay
--
-- Enable Behavior:
--   - enable='0': Shift register frozen (delay held constant)
--   - enable='1': Normal shifting operation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity delay_line is
    port (
        -- Clock and control
        clk          : in  std_logic;                       -- System clock
        n_reset      : in  std_logic;                       -- Active-low reset
        enable       : in  std_logic;                       -- Functional enable
        clk_en       : in  std_logic;                       -- Clock enable

        -- Configuration
        delay_cycles : in  std_logic_vector(7 downto 0);   -- Delay in cycles (0-255)

        -- Data path
        data_in      : in  std_logic;                       -- Input signal
        data_out     : out std_logic;                       -- Delayed output

        -- Status
        stat_reg     : out std_logic_vector(7 downto 0)    -- Status register
    );
end entity delay_line;

architecture rtl of delay_line is

    -- =========================================================================
    -- TYPES
    -- =========================================================================
    type shift_reg_t is array (0 to 255) of std_logic;

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal shift_reg : shift_reg_t;  -- 256-stage shift register

begin

    -- =========================================================================
    -- SHIFT REGISTER (Sequential)
    -- =========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Clear all stages
            shift_reg <= (others => '0');

        elsif rising_edge(clk) then
            if clk_en = '1' and enable = '1' then
                -- Shift data through register
                shift_reg(0) <= data_in;  -- New data enters at position 0
                for i in 1 to 255 loop
                    shift_reg(i) <= shift_reg(i-1);  -- Shift left
                end loop;
            end if;
            -- enable='0' or clk_en='0': Hold shift register (freeze delay)
        end if;
    end process;

    -- =========================================================================
    -- OUTPUT MUX (Combinational)
    -- =========================================================================
    -- Select delayed output based on delay_cycles
    -- delay=0: bypass (output = input directly)
    -- delay=1: output = shift_reg(0) (1 cycle delay)
    -- delay=N: output = shift_reg(N-1) (N cycles delay)
    process(delay_cycles, data_in, shift_reg)
        variable delay_val : integer;
    begin
        delay_val := to_integer(unsigned(delay_cycles));

        if delay_val = 0 then
            data_out <= data_in;  -- Bypass mode
        else
            data_out <= shift_reg(delay_val - 1);  -- Delayed output
        end if;
    end process;

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5-1: Reserved
    -- Bit 0: Current input value
    stat_reg <= "0000000" & data_in;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why 256 stages when max delay is 255?
    -- A: delay_cycles=0 means bypass (no delay), delay_cycles=1 means 1 cycle
    --    (output from shift_reg(0)), ..., delay_cycles=255 means 255 cycles
    --    (output from shift_reg(254)). We need 255 stages.
    --
    -- Q: Can I change delay_cycles during operation?
    -- A: Yes, but output will immediately reflect new delay tap point.
    --    For glitch-free delay changes, pause input or use separate module.
    --
    -- Q: What happens if delay_cycles > actual data width?
    -- A: Output will show older data from shift register. Ensure data rate
    --    and delay setting are appropriate for your application.
    --
    -- Q: How much logic does this use?
    -- A: 256 flip-flops + mux logic. For FPGA: ~256 LUTs + 256 FFs.
    --    Relatively cheap in modern FPGAs.
    --
    -- Q: Can I delay multi-bit signals?
    -- A: Yes, instantiate multiple delay_line instances (one per bit) OR
    --    modify this module to use std_logic_vector input/output.

end architecture rtl;

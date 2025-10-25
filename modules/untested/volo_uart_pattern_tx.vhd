--------------------------------------------------------------------------------
-- Entity: uart_pattern_tx
-- Filename: volo_uart_pattern_tx.vhd
-- Purpose: UART pattern generator - transmits repeating ASCII pattern
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
-- Origin: Migrated from PulseStar/core/uart_tx_core.vhd
--
-- Description:
--   Specialized UART transmitter that continuously sends a repeating ASCII
--   pattern. Perfect for calibration signals, digital test patterns, and
--   inter-instrument verification. Outputs 16-bit signed for DAC/analog use.
--
-- Features:
--   - Standard 8N1 UART format (8 data bits, no parity, 1 stop bit)
--   - Configurable baud rate via clock divider
--   - Repeating pattern: "VOLO" (0x56 0x4F 0x4C 0x4F)
--   - 16-bit signed output (0x7FFF=high, 0x8000=low) for analog visualization
--   - Automatic continuous transmission (just enable and it runs!)
--   - Integrated baud rate generator
--
-- UART Frame Format:
--   [START=0][D0][D1][D2][D3][D4][D5][D6][D7][STOP=1]
--   Data bits transmitted LSB first
--
-- Use Cases:
--
--   1. Digital Calibration Signal:
--      Generate known UART pattern for scope calibration and baud rate
--      verification. Connect to oscilloscope, measure bit timing.
--
--   2. Inter-Instrument Communication Test:
--      Verify MokuBench instrument synchronization by transmitting pattern
--      from one slot and decoding in another slot.
--
--   3. Signal Integrity Verification:
--      Output to DAC, observe analog UART waveform. Check rise/fall times,
--      overshoot, ringing. Useful for PCB/cable characterization.
--
--   4. UART Decoder Testing:
--      Feed known pattern to UART decoder logic or external devices.
--      Verify correct decoding under various conditions.
--
--   5. Trigger Pattern for Logic Analyzers:
--      Use predictable "VOLO" pattern as trigger event for capturing
--      timing relationships with other signals.
--
-- Output Format:
--   uart_out: signed(15 downto 0) for CustomWrapper DAC output
--     - UART high (logic '1'): 0x7FFF (max positive, +5V on Moku DAC)
--     - UART low  (logic '0'): 0x8000 (max negative, -5V on Moku DAC)
--   This creates a full-swing digital pattern visible on oscilloscope!
--
-- Control Signals (Priority Order):
--   1. n_reset (active-low): Asynchronous reset to idle state
--   2. clk_en (active-high): Clock enable - freezes FSM when low
--   3. enable (active-high): Functional enable - starts/stops transmission
--
-- Baud Rate Configuration:
--   baud_div = (clk_freq / baud_rate) - 1
--   Examples @ 125 MHz:
--     - 115200 baud: baud_div = 1084
--     -  38400 baud: baud_div = 3254
--     -   9600 baud: baud_div = 13019
--
-- Timing Example (115200 baud @ 125 MHz):
--   Each bit = 8.68 μs
--   Full "VOLO" = 4 chars × 10 bits = 40 bits = 347 μs
--   Pattern repeats continuously at ~2888 Hz
--
-- Integration Example:
--   PATTERN_UART: entity work.uart_pattern_tx
--       port map (
--           clk      => Clk,
--           n_reset  => n_Reset,
--           enable   => uart_enable,
--           clk_en   => '1',
--           baud_div => baud_divider,   -- From Control register
--           uart_out => uart_signal     -- To OutputC/D (DAC)
--       );
--
-- Customization:
--   To change pattern, edit PATTERN_ROM constant:
--     constant PATTERN_ROM : pattern_rom_t := (
--         X"48",  -- 'H'
--         X"45",  -- 'E'
--         X"4C",  -- 'L'
--         X"4C",  -- 'L'
--         X"4F"   -- 'O'
--     );
--   Update pattern_idx width if >4 characters!
--
-- Verilog Portability:
--   - All std_logic_vector encodings (easy conversion)
--   - Pattern ROM converts to Verilog array
--   - Single synchronous process
--
-- Students: This combines FSM + baud generator + pattern memory.
-- Notice how the FSM cycles through ROM addresses to send each character!
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_pattern_tx is
    port (
        -- Clock and control
        clk         : in  std_logic;                     -- System clock (e.g., 125 MHz)
        n_reset     : in  std_logic;                     -- Active-low reset
        enable      : in  std_logic;                     -- Functional enable (0=idle, 1=transmit)
        clk_en      : in  std_logic;                     -- Clock enable (0=frozen, 1=running)

        -- Configuration
        baud_div    : in  std_logic_vector(15 downto 0); -- Baud rate divider

        -- Output
        uart_out    : out signed(15 downto 0)            -- UART output (signed for DAC)
    );
end entity uart_pattern_tx;

architecture rtl of uart_pattern_tx is

    -- =========================================================================
    -- PATTERN ROM: "VOLO" ASCII CHARACTERS
    -- =========================================================================
    -- Customize this to change the transmitted pattern!
    type pattern_rom_t is array (0 to 3) of std_logic_vector(7 downto 0);
    constant PATTERN_ROM : pattern_rom_t := (
        X"56",  -- 'V' (ASCII 0x56 = 86 decimal)
        X"4F",  -- 'O' (ASCII 0x4F = 79 decimal)
        X"4C",  -- 'L' (ASCII 0x4C = 76 decimal)
        X"4F"   -- 'O' (ASCII 0x4F = 79 decimal)
    );

    -- =========================================================================
    -- FSM STATE ENCODING (std_logic_vector for Verilog portability)
    -- =========================================================================
    constant STATE_IDLE  : std_logic_vector(1 downto 0) := "00";
    constant STATE_START : std_logic_vector(1 downto 0) := "01";
    constant STATE_DATA  : std_logic_vector(1 downto 0) := "10";
    constant STATE_STOP  : std_logic_vector(1 downto 0) := "11";

    signal current_state : std_logic_vector(1 downto 0);

    -- =========================================================================
    -- BAUD RATE CLOCK ENABLE GENERATOR
    -- =========================================================================
    signal baud_counter : unsigned(15 downto 0);  -- Counts clocks per bit
    signal baud_tick    : std_logic;              -- Single-cycle pulse at baud rate

    -- =========================================================================
    -- PATTERN SEQUENCER
    -- =========================================================================
    signal pattern_idx : unsigned(1 downto 0);  -- Index into PATTERN_ROM (0-3)

    -- =========================================================================
    -- BIT-LEVEL SEQUENCER
    -- =========================================================================
    signal bit_idx : unsigned(2 downto 0);  -- Bit index within byte (0-7)

    -- =========================================================================
    -- DATA REGISTERS
    -- =========================================================================
    signal tx_data : std_logic_vector(7 downto 0);  -- Current byte being transmitted
    signal uart_bit : std_logic;                    -- Current UART output bit (internal)

begin

    -- =========================================================================
    -- BAUD RATE CLOCK ENABLE GENERATOR
    -- =========================================================================
    -- Generates single-cycle tick at configured baud rate
    -- baud_tick goes high for 1 clock cycle every (baud_div+1) clocks

    process(clk, n_reset)
    begin
        if n_reset = '0' then
            baud_counter <= (others => '0');
            baud_tick    <= '0';

        elsif rising_edge(clk) then
            if clk_en = '1' and enable = '1' then
                -- Enabled: count and generate ticks
                if baud_counter >= unsigned(baud_div) then
                    baud_counter <= (others => '0');
                    baud_tick    <= '1';  -- Pulse for 1 cycle
                else
                    baud_counter <= baud_counter + 1;
                    baud_tick    <= '0';
                end if;
            else
                -- Disabled or frozen: reset counter
                baud_counter <= (others => '0');
                baud_tick    <= '0';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- UART TRANSMIT STATE MACHINE
    -- =========================================================================
    -- FSM transitions on baud_tick pulses
    -- Cycles through IDLE → START → DATA(8 bits) → STOP → repeat

    process(clk, n_reset)
    begin
        if n_reset = '0' then
            current_state <= STATE_IDLE;
            pattern_idx   <= (others => '0');
            bit_idx       <= (others => '0');
            tx_data       <= (others => '0');
            uart_bit      <= '1';  -- UART idles high

        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then

                    -- Only transition on baud ticks (one state change per bit)
                    if baud_tick = '1' then

                        case current_state is

                            -- =================================================
                            -- IDLE: Load next character from pattern ROM
                            -- =================================================
                            when STATE_IDLE =>
                                tx_data       <= PATTERN_ROM(to_integer(pattern_idx));
                                current_state <= STATE_START;
                                uart_bit      <= '1';  -- Keep idle high

                            -- =================================================
                            -- START BIT: Send '0' for one bit period
                            -- =================================================
                            when STATE_START =>
                                uart_bit      <= '0';  -- Start bit always 0
                                bit_idx       <= (others => '0');
                                current_state <= STATE_DATA;

                            -- =================================================
                            -- DATA BITS: Send 8 bits LSB first
                            -- =================================================
                            when STATE_DATA =>
                                -- Output current bit from tx_data
                                uart_bit <= tx_data(to_integer(bit_idx));

                                if bit_idx = 7 then
                                    -- Last data bit transmitted, move to stop
                                    current_state <= STATE_STOP;
                                else
                                    -- More bits to send
                                    bit_idx <= bit_idx + 1;
                                end if;

                            -- =================================================
                            -- STOP BIT: Send '1' for one bit period
                            -- =================================================
                            when STATE_STOP =>
                                uart_bit <= '1';  -- Stop bit always 1

                                -- Advance to next character in pattern
                                if pattern_idx = 3 then
                                    pattern_idx <= (others => '0');  -- Wrap to 'V'
                                else
                                    pattern_idx <= pattern_idx + 1;
                                end if;

                                current_state <= STATE_IDLE;

                            -- =================================================
                            -- SAFETY: Return to idle on unknown state
                            -- =================================================
                            when others =>
                                current_state <= STATE_IDLE;
                                uart_bit      <= '1';

                        end case;
                    end if;  -- End if (baud_tick = '1')

                else
                    -- Disabled: reset to idle state
                    current_state <= STATE_IDLE;
                    pattern_idx   <= (others => '0');
                    uart_bit      <= '1';
                end if;  -- End if (enable = '1')

            end if;  -- End if (clk_en = '1')
            -- Note: clk_en='0' freezes all state (no updates)

        end if;  -- End if rising_edge(clk)
    end process;

    -- =========================================================================
    -- OUTPUT MAPPING: UART BIT TO SIGNED DAC OUTPUT
    -- =========================================================================
    -- Convert single-bit UART signal to 16-bit signed for CustomWrapper DAC
    -- UART high (1) → 0x7FFF (max positive, +5V on Moku)
    -- UART low  (0) → 0x8000 (max negative, -5V on Moku)
    -- This creates full-swing digital pattern visible on oscilloscope!

    uart_out <= X"7FFF" when uart_bit = '1' else X"8000";

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why does this output signed(15:0) instead of std_logic?
    -- A: For analog visualization! The Moku DAC expects 16-bit signed values.
    --    This lets you see the UART waveform on an oscilloscope (-5V to +5V).
    --
    -- Q: How do I change the transmitted pattern?
    -- A: Edit the PATTERN_ROM constant above. Can be any ASCII text!
    --    Remember to update pattern_idx width if you use >4 characters.
    --
    -- Q: Can I make it transmit just once instead of repeating?
    -- A: Yes! Add a flag that disables after pattern_idx wraps. Or add an
    --    external "repeat_enable" input and check it in STATE_STOP.
    --
    -- Q: Why is the pattern "VOLO"?
    -- A: Volo Engineering branding! But also a good test pattern:
    --    - V (0x56 = 0b01010110) - alternating bits
    --    - O (0x4F = 0b01001111) - mostly high bits
    --    - L (0x4C = 0b01001100) - mixed pattern
    --    Provides variety for signal integrity testing.
    --
    -- Q: How do I verify the output is correct?
    -- A: Connect to oscilloscope:
    --    1. Measure bit period (should match baud_div setting)
    --    2. Decode ASCII: Look for pattern 0x56 0x4F 0x4C 0x4F
    --    3. Check start/stop bits (start=low, stop=high)

end architecture rtl;

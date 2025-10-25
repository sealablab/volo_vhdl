--------------------------------------------------------------------------------
-- Entity: simpleserial_v1_tx
-- Filename: volo_simpleserial_v1_tx.vhd
-- Purpose: SimpleSerial V1 transmitter (ChipWhisperer protocol)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Implements SimpleSerial V1 protocol for ChipWhisperer/SCA applications.
--   Converts binary commands and payloads to hex-encoded ASCII with newline
--   termination. Manages multi-byte transmission sequences automatically.
--
-- SimpleSerial V1 Protocol:
--   - Baud rate: 38400 (ChipWhisperer standard)
--   - Format: 8N1 (8 data bits, no parity, 1 stop bit)
--   - Encoding: Hex ASCII (binary byte 0xAB → "AB" = 0x41 0x42)
--   - Terminator: '\n' (0x0A newline character)
--   - Frame format: <cmd><hex_payload><newline>
--
-- Example Frames:
--   Command only (trigger):    "t\n"          (2 bytes: 0x74 0x0A)
--   Command + 1 byte:          "p41\n"        (4 bytes: 0x70 0x34 0x31 0x0A)
--   Command + 4 bytes:         "k00112233\n"  (10 bytes: 0x6B ... 0x0A)
--
-- Interface:
--   clk           - System clock (125 MHz)
--   n_reset       - Active-low reset
--   enable        - Functional enable (0=idle, 1=active)
--   clk_en        - Clock enable (freeze FSM)
--   cmd_byte      - Command character (e.g., 't'=0x74, 'p'=0x70, 'k'=0x6B)
--   payload_len   - Number of payload bytes (0-16)
--   payload_data  - Payload bytes (up to 16 bytes)
--   send_pulse    - Pulse high for 1 cycle to start transmission
--   uart_tx       - UART TX output
--   tx_busy       - Transmission in progress
--   tx_done       - Transmission complete (1 cycle pulse)
--
-- Common Commands (ChipWhisperer standard):
--   't' (0x74) - Trigger (start capture)
--   'p' (0x70) - Text output (print/ping)
--   'k' (0x6B) - Key (set encryption key)
--   'x' (0x78) - Reset target
--   'r' (0x72) - Read data
--   'w' (0x77) - Write data
--
-- Payload Limits:
--   - Max payload: 16 bytes (32 hex ASCII characters)
--   - payload_len=0: Command only ("t\n")
--   - payload_len=1: Command + 2 hex chars ("p41\n")
--   - payload_len=16: Command + 32 hex chars (max)
--
-- Timing:
--   - Each character: ~260 μs @ 38400 baud
--   - "t\n" (2 chars): ~520 μs
--   - "k00112233\n" (10 chars): ~2.6 ms
--   - Max frame (1 + 32 + 1 = 34 chars): ~8.8 ms
--
-- FSM Operation:
--   1. IDLE: Wait for send_pulse
--   2. SEND_CMD: Send command byte
--   3. SEND_HEX_HIGH: Send high nibble hex ASCII (for each payload byte)
--   4. SEND_HEX_LOW: Send low nibble hex ASCII (for each payload byte)
--   5. SEND_NEWLINE: Send '\n' terminator
--   6. Return to IDLE
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.uart_pkg.all;  -- For nibble_to_hex_ascii function

entity simpleserial_v1_tx is
    port (
        -- Clock and control
        clk           : in  std_logic;                      -- System clock (125 MHz)
        n_reset       : in  std_logic;                      -- Active-low reset
        enable        : in  std_logic;                      -- Functional enable
        clk_en        : in  std_logic;                      -- Clock enable

        -- Command interface
        cmd_byte      : in  std_logic_vector(7 downto 0);   -- Command character
        payload_len   : in  unsigned(4 downto 0);           -- Payload length (0-16)
        payload_data  : in  std_logic_vector(127 downto 0); -- Payload bytes (16 × 8 bits)
        send_pulse    : in  std_logic;                      -- Start transmission

        -- UART output
        uart_tx       : out std_logic;                      -- UART TX line

        -- Status
        tx_busy       : out std_logic;                      -- Transmission in progress
        tx_done       : out std_logic                       -- Transmission complete
    );
end entity simpleserial_v1_tx;

architecture rtl of simpleserial_v1_tx is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    constant CLK_FREQ_HZ : natural := 125_000_000;
    constant BAUD_RATE   : natural := 38400;  -- SimpleSerial V1 standard
    constant NEWLINE     : std_logic_vector(7 downto 0) := x"0A";  -- '\n'

    -- FSM states (std_logic_vector for Verilog portability)
    constant STATE_IDLE          : std_logic_vector(3 downto 0) := "0000";
    constant STATE_SEND_CMD      : std_logic_vector(3 downto 0) := "0001";
    constant STATE_LOAD_BYTE     : std_logic_vector(3 downto 0) := "0010";
    constant STATE_SEND_HEX_HIGH : std_logic_vector(3 downto 0) := "0011";
    constant STATE_SEND_HEX_LOW  : std_logic_vector(3 downto 0) := "0100";
    constant STATE_SEND_NEWLINE  : std_logic_vector(3 downto 0) := "0101";

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal current_state : std_logic_vector(3 downto 0) := STATE_IDLE;

    -- Payload processing
    signal byte_idx      : unsigned(4 downto 0);  -- Index into payload (0-15)
    signal current_byte  : std_logic_vector(7 downto 0);  -- Current payload byte
    signal high_nibble   : std_logic_vector(3 downto 0);  -- High 4 bits
    signal low_nibble    : std_logic_vector(3 downto 0);  -- Low 4 bits

    -- UART TX interface
    signal uart_data     : std_logic_vector(7 downto 0);
    signal uart_send     : std_logic;
    signal uart_busy     : std_logic;
    signal uart_done     : std_logic;

    -- Latch inputs on send_pulse
    signal cmd_latch     : std_logic_vector(7 downto 0);
    signal len_latch     : unsigned(4 downto 0);
    signal payload_latch : std_logic_vector(127 downto 0);

begin

    -- =========================================================================
    -- UART TRANSMITTER CORE (38400 baud)
    -- =========================================================================
    U_UART_TX: entity WORK.uart_tx_core
        generic map (
            CLK_FREQ_HZ => CLK_FREQ_HZ,
            BAUD_RATE   => BAUD_RATE
        )
        port map (
            clk        => clk,
            rst_n      => n_reset,
            enable     => enable,
            data_in    => uart_data,
            send_valid => uart_send,
            tx         => uart_tx,
            tx_busy    => uart_busy,
            tx_done    => uart_done,
            stat_reg   => open
        );

    -- =========================================================================
    -- PAYLOAD BYTE EXTRACTION
    -- =========================================================================
    -- Extract current byte from payload_latch based on byte_idx
    -- payload_latch is 128 bits = 16 bytes (byte 0 at bits 7:0, byte 1 at 15:8, etc.)
    --
    -- CRITICAL: high_nibble and low_nibble read DIRECTLY from payload_latch to avoid
    -- delta-cycle race condition. If they depended on current_byte, they might read
    -- the old value before current_byte updates when byte_idx changes.
    current_byte <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8);
    high_nibble  <= payload_latch(to_integer(byte_idx) * 8 + 7 downto to_integer(byte_idx) * 8 + 4);
    low_nibble   <= payload_latch(to_integer(byte_idx) * 8 + 3 downto to_integer(byte_idx) * 8);

    -- =========================================================================
    -- FSM: SIMPLESERIAL V1 FRAME BUILDER
    -- =========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            current_state <= STATE_IDLE;
            byte_idx      <= (others => '0');
            uart_data     <= (others => '0');
            uart_send     <= '0';
            tx_busy       <= '0';
            tx_done       <= '0';
            cmd_latch     <= (others => '0');
            len_latch     <= (others => '0');
            payload_latch <= (others => '0');

        elsif rising_edge(clk) then
            -- Default: clear pulses
            uart_send <= '0';
            tx_done   <= '0';

            if clk_en = '1' and enable = '1' then

                case current_state is

                    -- =========================================================
                    -- IDLE: Wait for send_pulse, latch inputs
                    -- =========================================================
                    when STATE_IDLE =>
                        tx_busy <= '0';
                        byte_idx <= (others => '0');

                        -- Only accept new transmission if uart_tx_core is not busy
                        if send_pulse = '1' and uart_busy = '0' then
                            -- Latch command and payload
                            cmd_latch     <= cmd_byte;
                            len_latch     <= payload_len;
                            payload_latch <= payload_data;

                            -- Start transmission
                            tx_busy       <= '1';
                            uart_data     <= cmd_byte;  -- Send command first
                            uart_send     <= '1';
                            current_state <= STATE_SEND_CMD;
                        end if;

                    -- =========================================================
                    -- SEND_CMD: Wait for command byte to transmit
                    -- =========================================================
                    when STATE_SEND_CMD =>
                        if uart_done = '1' then
                            -- Command sent
                            if len_latch = 0 then
                                -- No payload, go straight to newline
                                uart_data     <= NEWLINE;
                                uart_send     <= '1';
                                current_state <= STATE_SEND_NEWLINE;
                            else
                                -- Load first payload byte (byte_idx already 0)
                                current_state <= STATE_LOAD_BYTE;
                            end if;
                        end if;

                    -- =========================================================
                    -- LOAD_BYTE: Wait for current_byte to settle after byte_idx change
                    -- =========================================================
                    when STATE_LOAD_BYTE =>
                        -- One cycle delay for combinational signals to settle
                        -- Now current_byte reflects the correct byte_idx value
                        uart_data     <= nibble_to_hex_ascii(high_nibble);
                        uart_send     <= '1';
                        current_state <= STATE_SEND_HEX_HIGH;

                    -- =========================================================
                    -- SEND_HEX_HIGH: High nibble sent, send low nibble
                    -- =========================================================
                    when STATE_SEND_HEX_HIGH =>
                        if uart_done = '1' then
                            uart_data     <= nibble_to_hex_ascii(low_nibble);
                            uart_send     <= '1';
                            current_state <= STATE_SEND_HEX_LOW;
                        end if;

                    -- =========================================================
                    -- SEND_HEX_LOW: Low nibble sent, advance to next byte or newline
                    -- =========================================================
                    when STATE_SEND_HEX_LOW =>
                        if uart_done = '1' then
                            if byte_idx = len_latch - 1 then
                                -- Last byte sent, send newline
                                uart_data     <= NEWLINE;
                                uart_send     <= '1';
                                current_state <= STATE_SEND_NEWLINE;
                            else
                                -- More bytes to send: increment byte_idx and wait for signals to settle
                                byte_idx      <= byte_idx + 1;
                                current_state <= STATE_LOAD_BYTE;
                            end if;
                        end if;

                    -- =========================================================
                    -- SEND_NEWLINE: Newline sent, return to idle
                    -- =========================================================
                    when STATE_SEND_NEWLINE =>
                        if uart_done = '1' then
                            tx_done       <= '1';  -- Pulse done
                            tx_busy       <= '0';
                            current_state <= STATE_IDLE;
                        end if;

                    -- =========================================================
                    -- SAFETY: Return to idle on unknown state
                    -- =========================================================
                    when others =>
                        current_state <= STATE_IDLE;
                        tx_busy       <= '0';

                end case;

            end if;
            -- enable='0': Hold all state (outputs parked, FSM frozen)
            -- clk_en='0': Hold all state (no updates)

        end if;  -- rising_edge(clk)
    end process;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why hex ASCII encoding instead of raw binary?
    -- A: ChipWhisperer uses ASCII for human readability and robustness.
    --    Easier to debug with serial terminal, less sensitive to line noise.
    --
    -- Q: How does payload_data packing work?
    -- A: 128 bits = 16 bytes. Byte 0 at bits [7:0], byte 1 at [15:8], etc.
    --    Example: payload_data = 0x...33221100 (LSB)
    --             byte_idx=0 → 0x00, byte_idx=1 → 0x11, etc.
    --
    -- Q: What's the max transmission time?
    -- A: Worst case: 1 cmd + 32 hex chars + 1 newline = 34 characters
    --    @ 38400 baud: 34 × 260μs ≈ 8.8ms
    --
    -- Q: Can I change the baud rate?
    -- A: Yes, but SimpleSerial V1 standard is 38400. SimpleSerial V2 uses
    --    230400 baud with binary COBS encoding (different protocol).
    --
    -- Q: Why one-hot FSM states?
    -- A: Verilog portability! std_logic_vector states convert easily.
    --    Also makes state decoding simpler in FPGAs.

end architecture rtl;

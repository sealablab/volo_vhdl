--------------------------------------------------------------------------------
-- Entity: simpleserial_v2_tx
-- Filename: volo_simpleserial_v2_tx.vhd
-- Purpose: SimpleSerial V2 transmitter (ChipWhisperer protocol)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Implements SimpleSerial V2 protocol for ChipWhisperer/SCA applications.
--   Uses binary encoding with COBS (Consistent Overhead Byte Stuffing) to
--   allow 0x00 as frame delimiter. 6× faster than V1 (230400 vs 38400 baud).
--
-- SimpleSerial V2 Protocol:
--   - Baud rate: 230400 (ChipWhisperer Nano/Husky standard)
--   - Format: 8N1 (8 data bits, no parity, 1 stop bit)
--   - Encoding: Binary with COBS (no 0x00 bytes in payload)
--   - Frame format: <0x00><len><cmd><payload><0x00>
--     * 0x00 = Start delimiter
--     * len  = COBS-encoded length byte
--     * cmd  = Command byte
--     * payload = Binary data (0-252 bytes, COBS-encoded)
--     * 0x00 = End delimiter
--   - CRC: Not implemented (optional in spec, often omitted)
--
-- COBS Encoding:
--   - Removes all 0x00 bytes from data, allowing 0x00 as delimiter
--   - Overhead: ~0.4% (1 byte per 254 bytes of data)
--   - Example: [0x00, 0x11, 0x00] → [0x01, 0x02, 0x11, 0x01]
--
-- Example Frames:
--   Command only (trigger):    <0x00><01><74><00>       (4 bytes)
--   Command + 1 byte:          <0x00><02 70 41><00>     (5 bytes, COBS-encoded)
--   Command + 4 bytes:         <0x00><...COBS...><00>   (7+ bytes)
--
-- Interface:
--   clk           - System clock (125 MHz)
--   n_reset       - Active-low reset
--   enable        - Functional enable (0=idle, 1=active)
--   clk_en        - Clock enable (freeze FSM)
--   cmd_byte      - Command byte (e.g., 't'=0x74, 'p'=0x70)
--   payload_len   - Number of payload bytes (0-252)
--   payload_data  - Payload bytes (up to 252 bytes = 2016 bits)
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
--   - Max payload: 252 bytes (COBS limit for 254-byte segments)
--   - payload_len=0: Command only (4 bytes total)
--   - payload_len=1: Command + 1 byte (5 bytes total)
--   - payload_len=252: Max frame (~260 bytes total with COBS overhead)
--
-- Timing:
--   - Each character: ~43 μs @ 230400 baud (6× faster than V1)
--   - Command only (4 bytes): ~172 μs
--   - Command + 4 bytes (~8 bytes): ~344 μs
--   - Max frame (~260 bytes): ~11.2 ms
--
-- FSM Operation:
--   1. IDLE: Wait for send_pulse, latch inputs
--   2. ENCODE: Apply COBS to (len + cmd + payload)
--   3. SEND_START_DELIM: Send 0x00 delimiter
--   4. SEND_ENCODED: Send COBS-encoded bytes
--   5. SEND_END_DELIM: Send 0x00 delimiter
--   6. Return to IDLE
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.uart_pkg.all;      -- UART constants
use work.volo_cobs_pkg.all; -- COBS encoding

entity simpleserial_v2_tx is
    port (
        -- Clock and control
        clk           : in  std_logic;                        -- System clock (125 MHz)
        n_reset       : in  std_logic;                        -- Active-low reset
        enable        : in  std_logic;                        -- Functional enable
        clk_en        : in  std_logic;                        -- Clock enable

        -- Command interface
        cmd_byte      : in  std_logic_vector(7 downto 0);     -- Command byte
        payload_len   : in  unsigned(7 downto 0);             -- Payload length (0-252)
        payload_data  : in  std_logic_vector(2015 downto 0);  -- Payload (252 × 8 bits)
        send_pulse    : in  std_logic;                        -- Start transmission

        -- UART output
        uart_tx       : out std_logic;                        -- UART TX line

        -- Status
        tx_busy       : out std_logic;                        -- Transmission in progress
        tx_done       : out std_logic                         -- Transmission complete
    );
end entity simpleserial_v2_tx;

architecture rtl of simpleserial_v2_tx is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    constant CLK_FREQ_HZ    : natural := 125_000_000;
    constant BAUD_RATE      : natural := 230400;  -- SimpleSerial V2 standard
    constant FRAME_DELIM    : std_logic_vector(7 downto 0) := x"00";  -- Delimiter

    -- FSM states (std_logic_vector for Verilog portability)
    constant STATE_IDLE           : std_logic_vector(3 downto 0) := "0000";
    constant STATE_ENCODE         : std_logic_vector(3 downto 0) := "0001";
    constant STATE_SEND_START_DELIM : std_logic_vector(3 downto 0) := "0010";
    constant STATE_SEND_ENCODED   : std_logic_vector(3 downto 0) := "0011";
    constant STATE_SEND_END_DELIM : std_logic_vector(3 downto 0) := "0100";

    -- =========================================================================
    -- TYPES
    -- =========================================================================
    -- Maximum frame size: 1 (len) + 1 (cmd) + 252 (payload) = 254 bytes
    -- COBS overhead: ~1 byte per 254 bytes → max 256 bytes encoded
    type byte_buffer_t is array (0 to 255) of std_logic_vector(7 downto 0);

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal current_state : std_logic_vector(3 downto 0) := STATE_IDLE;

    -- Input latches
    signal cmd_latch      : std_logic_vector(7 downto 0);
    signal len_latch      : unsigned(7 downto 0);
    signal payload_latch  : std_logic_vector(2015 downto 0);

    -- COBS encoding buffers
    signal raw_frame      : byte_buffer_t;    -- Pre-COBS: len + cmd + payload
    signal raw_frame_len  : integer range 0 to 254;
    signal encoded_frame  : byte_buffer_t;    -- Post-COBS
    signal encoded_len    : integer range 0 to 256;

    -- Transmission control
    signal byte_idx       : integer range 0 to 256;  -- Index into encoded_frame

    -- UART TX interface
    signal uart_data      : std_logic_vector(7 downto 0);
    signal uart_send      : std_logic;
    signal uart_busy      : std_logic;
    signal uart_done      : std_logic;

begin

    -- =========================================================================
    -- UART TRANSMITTER CORE (230400 baud)
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
    -- FSM: SIMPLESERIAL V2 FRAME BUILDER WITH COBS ENCODING
    -- =========================================================================
    process(clk, n_reset)
        -- COBS encoding variables (used in ENCODE state)
        variable data_in         : byte_array_t(0 to 253);
        variable data_len        : integer;
        variable encoded_out     : byte_array_t(0 to 255);
        variable encoded_len_var : integer;
        variable raw_len_var     : integer;
    begin
        if n_reset = '0' then
            current_state  <= STATE_IDLE;
            byte_idx       <= 0;
            uart_data      <= (others => '0');
            uart_send      <= '0';
            tx_busy        <= '0';
            tx_done        <= '0';
            cmd_latch      <= (others => '0');
            len_latch      <= (others => '0');
            payload_latch  <= (others => '0');
            raw_frame_len  <= 0;
            encoded_len    <= 0;

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
                        tx_busy  <= '0';
                        byte_idx <= 0;

                        -- Only accept new transmission if uart_tx_core is not busy
                        if send_pulse = '1' and uart_busy = '0' then
                            -- Latch inputs
                            cmd_latch     <= cmd_byte;
                            len_latch     <= payload_len;
                            payload_latch <= payload_data;

                            -- Start transmission
                            tx_busy       <= '1';
                            current_state <= STATE_ENCODE;
                        end if;

                    -- =========================================================
                    -- ENCODE: Build frame and apply COBS encoding
                    -- =========================================================
                    when STATE_ENCODE =>
                        -- Calculate raw frame length
                        raw_len_var := 2 + to_integer(len_latch);  -- len + cmd + payload

                        -- Build raw frame in variable: [len, cmd, payload...]
                        data_in(0) := std_logic_vector(len_latch);
                        data_in(1) := cmd_latch;

                        -- Copy payload bytes
                        for i in 0 to 251 loop
                            if i < to_integer(len_latch) then
                                data_in(2 + i) := payload_latch((i * 8) + 7 downto (i * 8));
                            end if;
                        end loop;

                        -- Apply COBS encoding (using variables throughout)
                        data_len := raw_len_var;
                        cobs_encode(
                            data_in     => data_in,
                            data_len    => data_len,
                            encoded     => encoded_out,
                            encoded_len => encoded_len_var
                        );

                        -- Store encoded frame length and data in signals
                        encoded_len <= encoded_len_var;
                        for i in 0 to 255 loop
                            if i < encoded_len_var then
                                encoded_frame(i) <= encoded_out(i);
                            end if;
                        end loop;

                        -- Send start delimiter
                        uart_data     <= FRAME_DELIM;
                        uart_send     <= '1';
                        byte_idx      <= 0;
                        current_state <= STATE_SEND_START_DELIM;

                    -- =========================================================
                    -- SEND_START_DELIM: Wait for start delimiter to transmit
                    -- =========================================================
                    when STATE_SEND_START_DELIM =>
                        if uart_done = '1' then
                            if encoded_len > 0 then
                                -- Send first encoded byte
                                uart_data     <= encoded_frame(0);
                                uart_send     <= '1';
                                byte_idx      <= 0;
                                current_state <= STATE_SEND_ENCODED;
                            else
                                -- Empty frame (shouldn't happen, but handle gracefully)
                                uart_data     <= FRAME_DELIM;
                                uart_send     <= '1';
                                current_state <= STATE_SEND_END_DELIM;
                            end if;
                        end if;

                    -- =========================================================
                    -- SEND_ENCODED: Send COBS-encoded bytes
                    -- =========================================================
                    when STATE_SEND_ENCODED =>
                        if uart_done = '1' then
                            if byte_idx = encoded_len - 1 then
                                -- Last byte sent, send end delimiter
                                uart_data     <= FRAME_DELIM;
                                uart_send     <= '1';
                                current_state <= STATE_SEND_END_DELIM;
                            else
                                -- More bytes to send
                                byte_idx  <= byte_idx + 1;
                                uart_data <= encoded_frame(byte_idx + 1);
                                uart_send <= '1';
                            end if;
                        end if;

                    -- =========================================================
                    -- SEND_END_DELIM: End delimiter sent, return to idle
                    -- =========================================================
                    when STATE_SEND_END_DELIM =>
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
    -- Q: Why COBS encoding instead of hex ASCII?
    -- A: Binary is 2× more bandwidth-efficient than hex ASCII. COBS removes
    --    0x00 bytes so we can use 0x00 as a frame delimiter (like newline in V1).
    --
    -- Q: How does COBS work?
    -- A: Replaces each 0x00 with a "code byte" indicating distance to next 0x00.
    --    Example: [0x00, 0x11, 0x00] → [0x01, 0x02, 0x11, 0x01]
    --    See volo_cobs_pkg.vhd for full algorithm.
    --
    -- Q: Why no CRC?
    -- A: CRC16 is optional in SimpleSerial V2 spec and often omitted for speed.
    --    Can be added later if needed for error detection.
    --
    -- Q: Max transmission time?
    -- A: Worst case: 2 delimiters + ~256 COBS bytes = ~258 bytes
    --    @ 230400 baud: 258 × 43μs ≈ 11.1ms
    --
    -- Q: Why byte_buffer_t array instead of std_logic_vector?
    -- A: COBS encoding operates on variable-length byte arrays. Arrays are
    --    easier to index and manipulate in VHDL. Verilog conversion: use
    --    packed arrays or memory blocks.

end architecture rtl;

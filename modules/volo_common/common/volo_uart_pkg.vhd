--------------------------------------------------------------------------------
-- Package: uart_pkg
-- Filename: volo_uart_pkg.vhd
-- Purpose: UART communication constants, types, and utilities for Volo VHDL
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- COMMON PACKAGE: This package provides UART/serial communication utilities
-- for building SimpleSerial and Pinata protocol interfaces. Designed for
-- maximum Verilog compatibility and reusability across projects.
--
-- UART SPECIFICATIONS SUPPORTED:
-- - Pinata protocol: 115200 baud, 8N1, raw binary
-- - SimpleSerial V1: 38400 baud, 8N1, hex-encoded ASCII
-- - SimpleSerial V2: 230400 baud, 8N1, binary with COBS
-- - Standard UART: Configurable baud rates from 9600 to 921600
--
-- TARGET PLATFORMS:
-- - Moku:Go: 125 MHz system clock, 16-ch DIO (3.3V logic)
-- - Moku:Lab: 500 MHz system clock
-- - Moku:Pro: 1.25 GHz system clock
-- - Moku:Delta: 5 GHz system clock
--
-- VERILOG CONVERSION STRATEGY:
-- - All constants are natural/integer types (Verilog parameters)
-- - Functions use standard types (std_logic_vector, natural)
-- - No records or complex types in function interfaces
-- - All calculations are compile-time computable
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package uart_pkg is

    -- =========================================================================
    -- UART FRAME PARAMETERS (8N1 Standard)
    -- =========================================================================

    -- Frame structure: 1 start bit + 8 data bits + 1 stop bit = 10 bits total
    constant UART_START_BIT       : std_logic := '0';  -- Start bit always low
    constant UART_STOP_BIT        : std_logic := '1';  -- Stop bit always high
    constant UART_IDLE_STATE      : std_logic := '1';  -- TX line idles high
    constant UART_DATA_BITS       : natural := 8;      -- Standard 8-bit data
    constant UART_FRAME_BITS      : natural := 10;     -- Total bits per frame
    constant UART_PARITY_BITS     : natural := 0;      -- No parity (N)

    -- =========================================================================
    -- CLOCK FREQUENCY CONSTANTS (Hz)
    -- =========================================================================

    -- Moku platform system clocks
    constant CLK_FREQ_MOKU_GO     : natural := 125_000_000;   -- 125 MHz
    constant CLK_FREQ_MOKU_LAB    : natural := 500_000_000;   -- 500 MHz
    constant CLK_FREQ_MOKU_PRO    : natural := 1_250_000_000; -- 1.25 GHz
    constant CLK_FREQ_MOKU_DELTA  : natural := 1_250_000_000; -- Use 1.25 GHz (conservative, Delta varies)

    -- Common test frequencies
    constant CLK_FREQ_100MHZ      : natural := 100_000_000;
    constant CLK_FREQ_50MHZ       : natural := 50_000_000;
    constant CLK_FREQ_25MHZ       : natural := 25_000_000;

    -- =========================================================================
    -- BAUD RATE CONSTANTS (bps)
    -- =========================================================================

    -- Standard baud rates
    constant UART_BAUD_9600       : natural := 9600;
    constant UART_BAUD_19200      : natural := 19200;
    constant UART_BAUD_38400      : natural := 38400;    -- SimpleSerial V1
    constant UART_BAUD_57600      : natural := 57600;
    constant UART_BAUD_115200     : natural := 115200;   -- Pinata standard ✓
    constant UART_BAUD_230400     : natural := 230400;   -- SimpleSerial V2
    constant UART_BAUD_460800     : natural := 460800;
    constant UART_BAUD_921600     : natural := 921600;

    -- Protocol-specific baud rates (for documentation)
    constant BAUD_PINATA          : natural := UART_BAUD_115200;
    constant BAUD_SIMPLESERIAL_V1 : natural := UART_BAUD_38400;
    constant BAUD_SIMPLESERIAL_V2 : natural := UART_BAUD_230400;

    -- =========================================================================
    -- PROTOCOL TYPE CONSTANTS
    -- =========================================================================

    -- Protocol identifiers (for mode selection)
    constant PROTOCOL_RAW         : std_logic_vector(2 downto 0) := "000";  -- Raw binary (Pinata)
    constant PROTOCOL_HEX_ASCII   : std_logic_vector(2 downto 0) := "001";  -- Hex ASCII (SimpleSerial V1)
    constant PROTOCOL_COBS        : std_logic_vector(2 downto 0) := "010";  -- COBS encoded (SimpleSerial V2)
    constant PROTOCOL_RESERVED_3  : std_logic_vector(2 downto 0) := "011";  -- Reserved
    constant PROTOCOL_RESERVED_4  : std_logic_vector(2 downto 0) := "100";  -- Reserved
    constant PROTOCOL_RESERVED_5  : std_logic_vector(2 downto 0) := "101";  -- Reserved
    constant PROTOCOL_RESERVED_6  : std_logic_vector(2 downto 0) := "110";  -- Reserved
    constant PROTOCOL_RESERVED_7  : std_logic_vector(2 downto 0) := "111";  -- Reserved

    -- =========================================================================
    -- SIMPLESERIAL / PINATA COMMAND CONSTANTS
    -- =========================================================================

    -- Common SimpleSerial/Pinata commands (ASCII values)
    constant CMD_TRIGGER          : std_logic_vector(7 downto 0) := x"74";  -- 't' (0x74)
    constant CMD_ENCRYPT          : std_logic_vector(7 downto 0) := x"65";  -- 'e' (0x65)
    constant CMD_DECRYPT          : std_logic_vector(7 downto 0) := x"64";  -- 'd' (0x64)
    constant CMD_PLAINTEXT        : std_logic_vector(7 downto 0) := x"70";  -- 'p' (0x70)
    constant CMD_KEY              : std_logic_vector(7 downto 0) := x"6B";  -- 'k' (0x6B)
    constant CMD_ACK_V1           : std_logic_vector(7 downto 0) := x"7A";  -- 'z' (0x7A) V1 ack
    constant CMD_ACK_V2           : std_logic_vector(7 downto 0) := x"65";  -- 'e' (0x65) V2 ack
    constant CMD_VERSION          : std_logic_vector(7 downto 0) := x"76";  -- 'v' (0x76)
    constant CMD_INFO             : std_logic_vector(7 downto 0) := x"77";  -- 'w' (0x77)

    -- Line terminators
    constant CHAR_NEWLINE         : std_logic_vector(7 downto 0) := x"0A";  -- '\n' (LF)
    constant CHAR_CARRIAGE_RETURN : std_logic_vector(7 downto 0) := x"0D";  -- '\r' (CR)

    -- =========================================================================
    -- BAUD RATE DIVIDER CALCULATION FUNCTIONS
    -- =========================================================================

    -- Calculate clock divider for given clock frequency and baud rate
    -- Returns: Number of clock cycles per UART bit period
    -- Example: calc_baud_divider(125_000_000, 115200) = 1085
    function calc_baud_divider(
        clk_freq_hz : natural;
        baud_rate   : natural
    ) return natural;

    -- Calculate actual achieved baud rate given clock frequency and divider
    -- Useful for verifying accuracy after divider calculation
    -- Returns: Actual baud rate in bps
    function calc_actual_baud(
        clk_freq_hz : natural;
        divider     : natural
    ) return natural;

    -- Calculate baud rate error as percentage
    -- Returns: Error percentage (0.0 to 100.0)
    function calc_baud_error_pct(
        target_baud : natural;
        actual_baud : natural
    ) return real;

    -- Check if baud rate error is acceptable (< 2% threshold)
    -- Returns: true if error is acceptable
    function is_baud_acceptable(
        target_baud : natural;
        actual_baud : natural
    ) return boolean;

    -- =========================================================================
    -- UART TIMING CALCULATION FUNCTIONS
    -- =========================================================================

    -- Calculate bit period in nanoseconds for given baud rate
    -- Returns: Bit period in ns
    function calc_bit_period_ns(baud_rate : natural) return real;

    -- Calculate frame period in nanoseconds (10 bits for 8N1)
    -- Returns: Frame period in ns
    function calc_frame_period_ns(baud_rate : natural) return real;

    -- Calculate maximum data throughput in bytes per second
    -- Accounts for 10-bit framing overhead (8N1)
    -- Returns: Bytes per second
    function calc_bytes_per_second(baud_rate : natural) return natural;

    -- =========================================================================
    -- HEX ASCII CONVERSION FUNCTIONS (For SimpleSerial V1)
    -- =========================================================================

    -- Convert 4-bit nibble to ASCII hex character
    -- Input: 0x0-0xF → Output: '0'-'9', 'A'-'F'
    function nibble_to_hex_ascii(nibble : std_logic_vector(3 downto 0)) return std_logic_vector;

    -- Convert ASCII hex character to 4-bit nibble
    -- Input: '0'-'9', 'A'-'F', 'a'-'f' → Output: 0x0-0xF
    function hex_ascii_to_nibble(ascii_char : std_logic_vector(7 downto 0)) return std_logic_vector;

    -- Convert byte to two ASCII hex characters
    -- Input: 0xFF → Output: "FF" (0x46 0x46)
    -- Returns 16-bit vector: [high_nibble][low_nibble]
    function byte_to_hex_ascii(data_byte : std_logic_vector(7 downto 0)) return std_logic_vector;

    -- Check if ASCII character is valid hex digit
    function is_hex_ascii(ascii_char : std_logic_vector(7 downto 0)) return boolean;

    -- =========================================================================
    -- FIFO SIZE CALCULATION FUNCTIONS
    -- =========================================================================

    -- Calculate recommended FIFO depth for given message size and protocol
    -- Returns: FIFO depth in bytes (power of 2)
    function calc_fifo_depth(
        max_message_bytes : natural;
        protocol_type     : std_logic_vector(2 downto 0)
    ) return natural;

    -- =========================================================================
    -- COMMON DIVIDER VALUES (Pre-calculated for convenience)
    -- =========================================================================

    -- Moku:Go @ 125 MHz
    constant DIV_MOKU_GO_115200   : natural := 1085;   -- 0.006% error
    constant DIV_MOKU_GO_38400    : natural := 3255;   -- 0.005% error
    constant DIV_MOKU_GO_230400   : natural := 542;    -- 0.099% error
    constant DIV_MOKU_GO_9600     : natural := 13021;  -- 0.002% error

    -- Moku:Lab @ 500 MHz
    constant DIV_MOKU_LAB_115200  : natural := 4340;
    constant DIV_MOKU_LAB_38400   : natural := 13021;
    constant DIV_MOKU_LAB_230400  : natural := 2170;

    -- Common 100 MHz clock
    constant DIV_100MHZ_115200    : natural := 868;
    constant DIV_100MHZ_38400     : natural := 2604;
    constant DIV_100MHZ_230400    : natural := 434;

end package uart_pkg;

-- =============================================================================
-- PACKAGE BODY (Function Implementations)
-- =============================================================================

package body uart_pkg is

    -- =========================================================================
    -- BAUD RATE DIVIDER CALCULATIONS
    -- =========================================================================

    function calc_baud_divider(
        clk_freq_hz : natural;
        baud_rate   : natural
    ) return natural is
        variable divider : natural;
    begin
        -- Simple division: clk_freq / baud_rate
        -- Round to nearest integer for best accuracy
        divider := (clk_freq_hz + (baud_rate / 2)) / baud_rate;

        -- Ensure minimum divider of 1
        if divider < 1 then
            divider := 1;
        end if;

        return divider;
    end function;

    function calc_actual_baud(
        clk_freq_hz : natural;
        divider     : natural
    ) return natural is
    begin
        if divider = 0 then
            return 0;  -- Avoid division by zero
        end if;

        return clk_freq_hz / divider;
    end function;

    function calc_baud_error_pct(
        target_baud : natural;
        actual_baud : natural
    ) return real is
        variable error_abs : real;
    begin
        if target_baud = 0 then
            return 100.0;  -- Invalid target
        end if;

        error_abs := abs(real(actual_baud) - real(target_baud));
        return (error_abs / real(target_baud)) * 100.0;
    end function;

    function is_baud_acceptable(
        target_baud : natural;
        actual_baud : natural
    ) return boolean is
        variable error_pct : real;
        constant MAX_ERROR_PCT : real := 2.0;  -- 2% threshold
    begin
        error_pct := calc_baud_error_pct(target_baud, actual_baud);
        return (error_pct < MAX_ERROR_PCT);
    end function;

    -- =========================================================================
    -- UART TIMING CALCULATIONS
    -- =========================================================================

    function calc_bit_period_ns(baud_rate : natural) return real is
    begin
        if baud_rate = 0 then
            return 0.0;
        end if;

        -- Period = 1 / frequency, convert to nanoseconds
        return (1.0e9 / real(baud_rate));
    end function;

    function calc_frame_period_ns(baud_rate : natural) return real is
    begin
        -- 10 bits per frame (8N1)
        return calc_bit_period_ns(baud_rate) * real(UART_FRAME_BITS);
    end function;

    function calc_bytes_per_second(baud_rate : natural) return natural is
    begin
        -- Bytes/sec = baud_rate / 10 (8N1 has 10 bits per byte)
        return baud_rate / UART_FRAME_BITS;
    end function;

    -- =========================================================================
    -- HEX ASCII CONVERSIONS
    -- =========================================================================

    function nibble_to_hex_ascii(nibble : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable ascii_char : std_logic_vector(7 downto 0);
        variable nibble_int : natural;
    begin
        nibble_int := to_integer(unsigned(nibble));

        if nibble_int <= 9 then
            -- '0' to '9' (0x30 to 0x39)
            ascii_char := std_logic_vector(to_unsigned(16#30# + nibble_int, 8));
        else
            -- 'A' to 'F' (0x41 to 0x46)
            ascii_char := std_logic_vector(to_unsigned(16#41# + (nibble_int - 10), 8));
        end if;

        return ascii_char;
    end function;

    function hex_ascii_to_nibble(ascii_char : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable char_int : natural;
        variable nibble : std_logic_vector(3 downto 0);
    begin
        char_int := to_integer(unsigned(ascii_char));

        if char_int >= 16#30# and char_int <= 16#39# then
            -- '0' to '9'
            nibble := std_logic_vector(to_unsigned(char_int - 16#30#, 4));
        elsif char_int >= 16#41# and char_int <= 16#46# then
            -- 'A' to 'F'
            nibble := std_logic_vector(to_unsigned(char_int - 16#41# + 10, 4));
        elsif char_int >= 16#61# and char_int <= 16#66# then
            -- 'a' to 'f'
            nibble := std_logic_vector(to_unsigned(char_int - 16#61# + 10, 4));
        else
            -- Invalid character, return 0
            nibble := x"0";
        end if;

        return nibble;
    end function;

    function byte_to_hex_ascii(data_byte : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable high_nibble : std_logic_vector(3 downto 0);
        variable low_nibble  : std_logic_vector(3 downto 0);
        variable result      : std_logic_vector(15 downto 0);
    begin
        high_nibble := data_byte(7 downto 4);
        low_nibble  := data_byte(3 downto 0);

        -- Return [high_ascii][low_ascii]
        result(15 downto 8) := nibble_to_hex_ascii(high_nibble);
        result(7 downto 0)  := nibble_to_hex_ascii(low_nibble);

        return result;
    end function;

    function is_hex_ascii(ascii_char : std_logic_vector(7 downto 0)) return boolean is
        variable char_int : natural;
    begin
        char_int := to_integer(unsigned(ascii_char));

        return (char_int >= 16#30# and char_int <= 16#39#) or  -- '0'-'9'
               (char_int >= 16#41# and char_int <= 16#46#) or  -- 'A'-'F'
               (char_int >= 16#61# and char_int <= 16#66#);    -- 'a'-'f'
    end function;

    -- =========================================================================
    -- FIFO SIZE CALCULATIONS
    -- =========================================================================

    function calc_fifo_depth(
        max_message_bytes : natural;
        protocol_type     : std_logic_vector(2 downto 0)
    ) return natural is
        variable required_depth : natural;
        variable fifo_depth : natural;
    begin
        -- Calculate required depth based on protocol overhead
        if protocol_type = PROTOCOL_RAW then
            -- Raw: 1 cmd + data
            required_depth := max_message_bytes + 1;
        elsif protocol_type = PROTOCOL_HEX_ASCII then
            -- Hex ASCII: 1 cmd + 2*data + 1 newline
            required_depth := 1 + (max_message_bytes * 2) + 1;
        elsif protocol_type = PROTOCOL_COBS then
            -- COBS: overhead ~1% + framing
            required_depth := max_message_bytes + (max_message_bytes / 100) + 4;
        else
            required_depth := max_message_bytes;
        end if;

        -- Round up to next power of 2 for FIFO efficiency
        -- Common depths: 16, 32, 64, 128, 256, 512, 1024
        if required_depth <= 16 then
            fifo_depth := 16;
        elsif required_depth <= 32 then
            fifo_depth := 32;
        elsif required_depth <= 64 then
            fifo_depth := 64;
        elsif required_depth <= 128 then
            fifo_depth := 128;
        elsif required_depth <= 256 then
            fifo_depth := 256;
        elsif required_depth <= 512 then
            fifo_depth := 512;
        else
            fifo_depth := 1024;
        end if;

        return fifo_depth;
    end function;

end package body uart_pkg;

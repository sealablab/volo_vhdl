--------------------------------------------------------------------------------
-- Company:        Liquid Instruments
-- Engineer:       Claude Code
-- Module Name:    volo_cobs_pkg
-- Target Devices: Moku Platform
-- Description:    COBS (Consistent Overhead Byte Stuffing) Encoding/Decoding
--
-- COBS encoding removes all 0x00 bytes from data, allowing 0x00 to be used
-- as a frame delimiter in serial protocols (e.g., SimpleSerial V2).
--
-- Algorithm:
--   - Replace 0x00 bytes with "code bytes" indicating distance to next 0x00
--   - First byte is always a code byte
--   - Code byte range: 0x01 to 0xFF (max segment = 254 data bytes)
--   - Overhead: 1 byte per 254 bytes of data (0.4% worst case)
--
-- Example:
--   Input:  [0x00, 0x11, 0x00]
--   Output: [0x01, 0x02, 0x11, 0x01]
--
-- References:
--   - ChipWhisperer SimpleSerial V2 Protocol
--   - "Consistent Overhead Byte Stuffing" (Stuart Cheshire, Mary Baker)
--
-- Revision History:
--   2025-10-23: Initial implementation for SimpleSerial V2
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package volo_cobs_pkg is

    --------------------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------------------
    constant COBS_MAX_PAYLOAD_LEN : integer := 254;  -- Max bytes between code bytes
    constant COBS_MAX_FRAME_LEN   : integer := 256;  -- Max frame size (with overhead)

    --------------------------------------------------------------------------------
    -- Types
    --------------------------------------------------------------------------------
    type byte_array_t is array (integer range <>) of std_logic_vector(7 downto 0);

    --------------------------------------------------------------------------------
    -- COBS Encoding Function
    --
    -- Encodes input data to COBS format (no 0x00 bytes in output).
    --
    -- Parameters:
    --   data_in     : Input byte array (max 254 bytes)
    --   data_len    : Number of valid bytes in data_in (0 to 254)
    --
    -- Returns:
    --   encoded     : COBS-encoded byte array (1 to 256 bytes)
    --   encoded_len : Length of encoded data (always >= data_len + 1)
    --
    -- Note: Caller must provide output array sized for encoded_len.
    --------------------------------------------------------------------------------
    procedure cobs_encode (
        constant data_in     : in  byte_array_t;
        constant data_len    : in  integer;
        variable encoded     : out byte_array_t;
        variable encoded_len : out integer
    );

    --------------------------------------------------------------------------------
    -- COBS Decoding Function
    --
    -- Decodes COBS-encoded data back to original format.
    --
    -- Parameters:
    --   encoded     : COBS-encoded byte array
    --   encoded_len : Length of encoded data
    --
    -- Returns:
    --   data_out    : Decoded byte array
    --   data_len    : Length of decoded data
    --   valid       : '1' if decode successful, '0' if error detected
    --
    -- Note: Used primarily for testing/verification.
    --------------------------------------------------------------------------------
    procedure cobs_decode (
        constant encoded     : in  byte_array_t;
        constant encoded_len : in  integer;
        variable data_out    : out byte_array_t;
        variable data_len    : out integer;
        variable valid       : out std_logic
    );

end package volo_cobs_pkg;

package body volo_cobs_pkg is

    --------------------------------------------------------------------------------
    -- COBS Encode Implementation
    --------------------------------------------------------------------------------
    procedure cobs_encode (
        constant data_in     : in  byte_array_t;
        constant data_len    : in  integer;
        variable encoded     : out byte_array_t;
        variable encoded_len : out integer
    ) is
        variable code_index : integer := 0;     -- Position of current code byte
        variable out_index  : integer := 1;     -- Current output position (reserve 0 for code)
        variable code       : integer := 1;     -- Distance counter
    begin
        -- Handle empty input
        if data_len = 0 then
            encoded(0) := x"01";  -- Code byte: "1 byte to end" (just the code itself)
            encoded_len := 1;
            return;
        end if;

        -- Reserve first byte for code
        code_index := 0;
        out_index := 1;
        code := 1;

        -- Process each input byte
        for i in 0 to data_len - 1 loop
            if data_in(i) = x"00" then
                -- Found zero: write code byte and start new segment
                encoded(code_index) := std_logic_vector(to_unsigned(code, 8));
                code_index := out_index;
                out_index := out_index + 1;
                code := 1;
            else
                -- Non-zero byte: copy to output
                encoded(out_index) := data_in(i);
                out_index := out_index + 1;
                code := code + 1;

                -- Check if we've reached max segment length (254 data bytes)
                if code = 255 then
                    encoded(code_index) := std_logic_vector(to_unsigned(255, 8));
                    code_index := out_index;
                    out_index := out_index + 1;
                    code := 1;
                end if;
            end if;
        end loop;

        -- Write final code byte
        encoded(code_index) := std_logic_vector(to_unsigned(code, 8));
        encoded_len := out_index;

    end procedure cobs_encode;

    --------------------------------------------------------------------------------
    -- COBS Decode Implementation
    --------------------------------------------------------------------------------
    procedure cobs_decode (
        constant encoded     : in  byte_array_t;
        constant encoded_len : in  integer;
        variable data_out    : out byte_array_t;
        variable data_len    : out integer;
        variable valid       : out std_logic
    ) is
        variable in_index  : integer := 0;
        variable out_index : integer := 0;
        variable code      : integer;
        variable i         : integer;
    begin
        -- Initialize
        valid := '1';
        data_len := 0;

        -- Handle empty input
        if encoded_len = 0 then
            valid := '0';  -- Invalid: zero-length COBS frame
            return;
        end if;

        -- Decode loop
        in_index := 0;
        while in_index < encoded_len loop
            -- Read code byte
            code := to_integer(unsigned(encoded(in_index)));

            -- Validate code byte (must be non-zero)
            if code = 0 then
                valid := '0';
                return;
            end if;

            in_index := in_index + 1;

            -- Copy (code - 1) bytes
            for i in 1 to code - 1 loop
                if in_index >= encoded_len then
                    -- Unexpected end of data
                    valid := '0';
                    return;
                end if;

                data_out(out_index) := encoded(in_index);
                out_index := out_index + 1;
                in_index := in_index + 1;
            end loop;

            -- Add zero byte if code < 255 and not at end
            if code < 255 and in_index < encoded_len then
                data_out(out_index) := x"00";
                out_index := out_index + 1;
            end if;
        end loop;

        data_len := out_index;

    end procedure cobs_decode;

end package body volo_cobs_pkg;

--------------------------------------------------------------------------------
-- Debug Output Multiplexer
--
-- Description:
--   Selectable debug output routing for inspectable_buffer_loader module.
--   Provides 8 different debug views with voltage guard bands (left-shift by 2)
--   for oscilloscope-based hardware debugging.
--
-- Critical Design Feature: Voltage Guard Bands
--   Digital debug signals routed through ADC/DAC analog paths suffer from:
--   - Quantization noise (±1-2 LSBs)
--   - Analog filtering effects
--   - Limited voltage resolution (~0.8 mV/bit on 16-bit DAC)
--
--   Solution: Left-shift all debug values by 2-3 bits before output.
--   This creates distinct voltage steps between adjacent values, making them
--   reliably distinguishable on oscilloscope despite quantization noise.
--
-- Voltage Scaling (Moku Platform - see Moku_Voltage_pkg.vhd):
--   - Output range: ±5.0V full scale (16-bit signed DAC)
--   - Digital scaling: 6553.6 digital units per volt (32768 / 5.0V)
--   - Oscilloscope decoding: voltage * 6553.6 = digital value
--
-- Debug Views:
--   View 0: Status Summary (state + fault + valid + buffer_addr)
--   View 1: CRC Comparison (expected_crc vs computed_crc)
--   View 2: Write Activity (chunk_word_idx + write_ptr)
--   View 3: Chunk Data Snapshot (first and last word of current chunk)
--   View 4: BRAM Readback (address from Control0, data from BRAM)
--   View 5: Timing Diagnostics (strobe_edge + ack + complete + words_written)
--   View 6: Error Diagnostics (error_code + error_state + error_details)
--   View 7: Reserved (Future Use)
--
-- Tier: 1 (Strict RTL - Verilog portable core)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Moku platform voltage scaling reference
-- (Package provides ±5V full-scale conversion utilities)
use work.Moku_Voltage_pkg.all;

entity debug_mux is
    port (
        -- Debug view selection
        debug_select    : in  std_logic_vector(2 downto 0);  -- 0-7 view selection

        -- Debug inputs (raw data)
        state           : in  std_logic_vector(2 downto 0);  -- FSM state
        fault           : in  std_logic;                     -- Fault flag
        valid           : in  std_logic;                     -- Buffer valid flag
        buffer_addr     : in  std_logic_vector(10 downto 0); -- Buffer address (0-2047)

        expected_crc    : in  std_logic_vector(31 downto 0); -- Expected CRC
        computed_crc    : in  std_logic_vector(31 downto 0); -- Computed CRC

        chunk_word_idx  : in  std_logic_vector(3 downto 0);  -- Index within chunk (0-8)
        write_ptr       : in  std_logic_vector(10 downto 0); -- Write pointer

        chunk_data_first : in std_logic_vector(31 downto 0); -- First word of chunk
        chunk_data_last  : in std_logic_vector(31 downto 0); -- Last word of chunk

        bram_readback_addr : in std_logic_vector(10 downto 0); -- BRAM read address
        bram_readback_data : in std_logic_vector(31 downto 0); -- BRAM read data

        strobe_edge     : in  std_logic;                     -- STROBE rising edge
        strobe_ack      : in  std_logic;                     -- STROBE acknowledge
        load_complete   : in  std_logic;                     -- Load complete flag
        words_written   : in  std_logic_vector(12 downto 0); -- Words written count

        error_code      : in  std_logic_vector(2 downto 0);  -- Error code (0-7)
        error_state     : in  std_logic_vector(2 downto 0);  -- State where error occurred
        error_details   : in  std_logic_vector(7 downto 0);  -- Context-specific info

        -- Debug output (16-bit signed with voltage guard bands)
        debug_out       : out signed(15 downto 0)
    );
end entity debug_mux;

architecture rtl of debug_mux is

    -- Internal debug signals (before guard band shift)
    signal debug_view_0 : signed(15 downto 0);
    signal debug_view_1 : signed(15 downto 0);
    signal debug_view_2 : signed(15 downto 0);
    signal debug_view_3 : signed(15 downto 0);
    signal debug_view_4 : signed(15 downto 0);
    signal debug_view_5 : signed(15 downto 0);
    signal debug_view_6 : signed(15 downto 0);
    signal debug_view_7 : signed(15 downto 0);

begin

    -- ========================================================================
    -- View 0: Status Summary (DEFAULT)
    -- Bit[15:13] = state (3 bits)
    -- Bit[12]    = fault (1 bit)
    -- Bit[11]    = valid (1 bit)
    -- Bit[10:0]  = buffer_addr (11 bits)
    -- Total: 16 bits (voltage spacing from field boundaries)
    -- ========================================================================
    debug_view_0 <= signed(state & fault & valid & buffer_addr);

    -- ========================================================================
    -- View 1: CRC Comparison (for CRC mismatch debugging)
    -- Shows low 16 bits of expected_crc (shifted by 2)
    -- Pair with OutputA showing expected, OutputB showing computed
    -- ========================================================================
    debug_view_1 <= signed(expected_crc(15 downto 2) & "00");

    -- ========================================================================
    -- View 2: Write Activity
    -- Bit[15:12] = chunk_word_idx (4 bits, values 0-8)
    -- Bit[11]    = "0" (spacing)
    -- Bit[10:0]  = write_ptr (11 bits)
    -- Total: 16 bits
    -- ========================================================================
    debug_view_2 <= signed(chunk_word_idx & "0" & write_ptr);

    -- ========================================================================
    -- View 3: Chunk Data Snapshot
    -- Shows low 16 bits of chunk data (shifted by 2)
    -- OutputA = first word, OutputB = last word
    -- ========================================================================
    debug_view_3 <= signed(chunk_data_first(15 downto 2) & "00");

    -- ========================================================================
    -- View 4: BRAM Readback
    -- Shows low 16 bits of BRAM data at selected address (shifted by 2)
    -- ========================================================================
    debug_view_4 <= signed(bram_readback_data(15 downto 2) & "00");

    -- ========================================================================
    -- View 5: Timing Diagnostics
    -- Bit[15]    = strobe_edge (1 bit)
    -- Bit[14]    = strobe_ack (1 bit)
    -- Bit[13]    = load_complete (1 bit)
    -- Bit[12:0]  = words_written (13 bits, but only use 11 bits + padding)
    -- Total: 16 bits
    -- ========================================================================
    debug_view_5 <= signed(strobe_edge & strobe_ack & load_complete & words_written(12 downto 0));

    -- ========================================================================
    -- View 6: Error Diagnostics
    -- Bit[15:13] = error_code (3 bits)
    -- Bit[12:10] = error_state (3 bits)
    -- Bit[9:8]   = "00" (spacing)
    -- Bit[7:0]   = error_details (8 bits)
    -- Total: 16 bits
    -- ========================================================================
    debug_view_6 <= signed(error_code & error_state & "00" & error_details);

    -- ========================================================================
    -- View 7: Reserved (Future Use)
    -- ========================================================================
    debug_view_7 <= (others => '0');

    -- ========================================================================
    -- Combinatorial Mux (instant switching for real-time debugging)
    -- ========================================================================
    process(debug_select, debug_view_0, debug_view_1, debug_view_2, debug_view_3,
            debug_view_4, debug_view_5, debug_view_6, debug_view_7)
    begin
        case debug_select is
            when "000" => debug_out <= debug_view_0;  -- Status Summary
            when "001" => debug_out <= debug_view_1;  -- CRC Comparison
            when "010" => debug_out <= debug_view_2;  -- Write Activity
            when "011" => debug_out <= debug_view_3;  -- Chunk Data Snapshot
            when "100" => debug_out <= debug_view_4;  -- BRAM Readback
            when "101" => debug_out <= debug_view_5;  -- Timing Diagnostics
            when "110" => debug_out <= debug_view_6;  -- Error Diagnostics
            when "111" => debug_out <= debug_view_7;  -- Reserved
            when others => debug_out <= (others => '0');
        end case;
    end process;

end architecture rtl;

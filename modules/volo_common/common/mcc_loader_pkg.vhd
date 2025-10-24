--------------------------------------------------------------------------------
-- MCC Buffer Loader Package
--
-- Description:
--   Reusable package for streaming arbitrary-sized data buffers via MCC Control
--   Registers during module initialization. Uses a fire-and-forget streaming
--   protocol with CRC32 validation.
--
-- Protocol Overview:
--   1. IDLE - Waiting for metadata (buffer length + expected CRC)
--   2. LOADING - Streaming data chunks (8 words at a time via Control3-10)
--   3. VALIDATING - Comparing computed CRC vs expected CRC
--   4. READY - Success! Buffer valid, ready for module enable
--   5. RUNNING - Normal operation with pre-loaded buffer accessible
--   6. ERROR - CRC mismatch, FAULT flag set
--
-- Key Design Principles:
--   - One-way communication (Python → FPGA, no readback)
--   - Atomic register updates (all regs update simultaneously)
--   - Network is SLOW (10-200ms), FPGA is FAST (nanoseconds)
--   - FPGA always finishes latching before next network write
--   - Length-prefixed protocol (metadata sent first)
--   - CRC32 validation (computed during streaming, checked at end)
--
-- Register Usage:
--   Control0[31] = MCC_READY (standard, set by MCC after deployment)
--   Control0[30] = User Enable (standard, user-controlled enable/disable)
--   Control0[29] = Clock Enable (standard, sequential logic freeze control)
--   Control0[28] = LOAD_COMPLETE (signals "Python done sending chunks")
--   Control0[27] = LOAD_STROBE (pulse per chunk to trigger latch)
--   Control0[26:0] = Module-specific configuration
--   Control1[31:16] = Buffer length (words to load, max 65535)
--   Control1[15:0] = Reserved (future: chunk count or flags)
--   Control2[31:0] = Expected CRC32 (computed by Python, validated by FPGA)
--   Control3-Control10 = Data payload (8 words × 32 bits = 256 bits per chunk)
--
-- Example Workflow (Python):
--   # Step 1: Send metadata (length + CRC)
--   buffer_data = [0x12345678, 0xABCDEF00, ...]  # Up to 4096 words
--   await mcc_load_buffer(dut, buffer_data=buffer_data)
--   # This helper:
--   #   a) Computes CRC32
--   #   b) Sends length + CRC via Control1/Control2
--   #   c) Streams chunks via Control3-10 with STROBE pulses
--   #   d) Sets LOAD_COMPLETE when done
--   #   e) Waits for FPGA to validate (comedically large delay)
--
--   # Step 2: FPGA auto-transitions LOADING → VALIDATING → READY (or ERROR)
--   # No action needed from Python!
--
--   # Step 3: Enable module for normal operation (READY → RUNNING)
--   await mcc_set_regs(dut, {
--       0: 0xE0F40000,  # MCC_READY + Enable + ClkEn + Div=244
--       1: 0x043C7D00,  # Module config (overwrites length, that's OK!)
--       2: 0x64000000   # Module config (overwrites CRC, that's OK!)
--   }, set_mcc_ready=True)
--
-- VHDL Integration:
--   use work.mcc_loader_pkg.all;
--
--   signal load_state : mcc_load_state_t;
--   signal buffer_data : mcc_buffer_t;  -- 29 × 32-bit words
--
--   U_LOADER: entity work.mcc_buffer_loader
--       port map (
--           clk => Clk,
--           n_reset => n_reset,
--           load_complete => load_complete,
--           global_enable => global_enable,
--           control_regs => control_regs,  -- Control3-Control31 inputs
--           buffer_data => buffer_data,
--           load_state => load_state
--       );
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mcc_loader_pkg is

    -- ========================================================================
    -- Constants
    -- ========================================================================

    -- Buffer configuration
    constant MCC_CHUNK_SIZE     : positive := 8;      -- Words per chunk (Control3-10)
    constant MCC_MAX_BUFFER_SIZE : positive := 4096;  -- Max words (4KB at 32-bit/word)

    -- Control0 bit positions (UPDATED for streaming protocol)
    constant MCC_READY_BIT      : natural := 31;  -- Standard MCC bit
    constant ENABLE_BIT         : natural := 30;  -- Standard MCC bit
    constant CLK_EN_BIT         : natural := 29;  -- Standard MCC bit
    constant LOAD_COMPLETE_BIT  : natural := 28;  -- Python signals "done sending"
    constant LOAD_STROBE_BIT    : natural := 27;  -- Python pulses per chunk

    -- ========================================================================
    -- Types
    -- ========================================================================

    -- Loading state machine (use std_logic_vector encoding for Verilog portability)
    constant LOAD_STATE_IDLE          : std_logic_vector(2 downto 0) := "000";
    constant LOAD_STATE_LOADING       : std_logic_vector(2 downto 0) := "001";
    constant LOAD_STATE_WRITING_CHUNK : std_logic_vector(2 downto 0) := "101";
    constant LOAD_STATE_VALIDATING    : std_logic_vector(2 downto 0) := "010";
    constant LOAD_STATE_READY         : std_logic_vector(2 downto 0) := "011";
    constant LOAD_STATE_RUNNING       : std_logic_vector(2 downto 0) := "100";
    constant LOAD_STATE_ERROR         : std_logic_vector(2 downto 0) := "111";

    subtype mcc_load_state_t is std_logic_vector(2 downto 0);

    -- Chunk data type (8 words per chunk for Control3-10)
    type mcc_chunk_t is array(0 to MCC_CHUNK_SIZE-1) of std_logic_vector(31 downto 0);

    -- ========================================================================
    -- Helper Functions
    -- ========================================================================

    -- Extract control bits from Control0
    function get_load_complete(control0 : std_logic_vector(31 downto 0)) return std_logic;
    function get_load_strobe(control0 : std_logic_vector(31 downto 0)) return std_logic;

    -- Extract metadata from Control1/Control2
    function get_buffer_length(control1 : std_logic_vector(31 downto 0)) return unsigned;
    function get_expected_crc(control2 : std_logic_vector(31 downto 0)) return std_logic_vector;

    -- State checks
    function is_idle(load_state : mcc_load_state_t) return boolean;
    function is_loading(load_state : mcc_load_state_t) return boolean;
    function is_validating(load_state : mcc_load_state_t) return boolean;
    function is_ready(load_state : mcc_load_state_t) return boolean;
    function is_running(load_state : mcc_load_state_t) return boolean;
    function is_error(load_state : mcc_load_state_t) return boolean;

end package mcc_loader_pkg;

package body mcc_loader_pkg is

    -- Extract control bits
    function get_load_complete(control0 : std_logic_vector(31 downto 0)) return std_logic is
    begin
        return control0(LOAD_COMPLETE_BIT);
    end function;

    function get_load_strobe(control0 : std_logic_vector(31 downto 0)) return std_logic is
    begin
        return control0(LOAD_STROBE_BIT);
    end function;

    -- Extract metadata
    function get_buffer_length(control1 : std_logic_vector(31 downto 0)) return unsigned is
    begin
        return unsigned(control1(31 downto 16));  -- Top 16 bits
    end function;

    function get_expected_crc(control2 : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return control2;  -- Full 32-bit CRC
    end function;

    -- State checks
    function is_idle(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_IDLE;
    end function;

    function is_loading(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_LOADING;
    end function;

    function is_validating(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_VALIDATING;
    end function;

    function is_ready(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_READY;
    end function;

    function is_running(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_RUNNING;
    end function;

    function is_error(load_state : mcc_load_state_t) return boolean is
    begin
        return load_state = LOAD_STATE_ERROR;
    end function;

end package body mcc_loader_pkg;

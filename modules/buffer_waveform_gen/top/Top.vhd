--------------------------------------------------------------------------------
-- Buffer Waveform Generator - CustomWrapper Top Level
--
-- Description:
--   Demonstration module for MCC buffer loading protocol. Pre-loads waveform
--   samples during initialization, then plays them back in a loop.
--
-- Control Register Map:
--   LOADING Phase (before module enable):
--     Control0[28] = LOAD_COMPLETE (Python sets when done sending chunks)
--     Control0[27] = LOAD_STROBE (Python pulses per chunk)
--     Control1[31:16] = Buffer length (words, max 1024)
--     Control2[31:0] = Expected CRC32
--     Control3-10 = Data chunk (8 words per transfer)
--
--   RUNNING Phase (normal operation):
--     Control0[31] = MCC_READY (set by MCC after deployment)
--     Control0[30] = User Enable (1=play waveform, 0=stop)
--     Control0[29] = Clock Enable (1=enabled, 0=frozen)
--     Control0[23:16] = Clock divider (0-255 for playback rate)
--     Control1/Control2 = (overwritten by module config, buffer metadata no longer needed)
--
-- Output Mapping:
--   OutputA: Waveform samples (16-bit signed, from buffer)
--   OutputB: 0 (unused)
--   OutputC: 0 (unused)
--   OutputD[15] = load_fault (CRC error flag)
--   OutputD[14] = buffer_valid (buffer data valid)
--   OutputD[13:11] = load_state (state machine)
--   OutputD[10:0] = read_addr[10:0] (current buffer address, for debugging)
--
-- Usage (Python):
--   # Step 1: Load buffer (LOADING phase)
--   samples = [int(32767 * math.sin(2*math.pi*i/256)) for i in range(256)]
--   await mcc_load_buffer(dut, buffer_data=samples)
--
--   # Step 2: Enable module (RUNNING phase)
--   await set_regs(dut, {
--       0: mcc_cr0() | (100 << 16)  # MCC_READY + Enable + ClkEn + Div=100
--   }, set_mcc_ready=True)
--
-- Tier: 1 (Strict RTL - Verilog portable top level)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.mcc_loader_pkg.all;

architecture buffer_waveform_gen of CustomWrapper is

    -- ========================================================================
    -- MCC Control Signals
    -- ========================================================================
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal user_clk_en    : std_logic;
    signal global_enable  : std_logic;

    -- ========================================================================
    -- Buffer Loading Control Signals
    -- ========================================================================
    signal load_complete  : std_logic;  -- Control0[28]
    signal load_strobe    : std_logic;  -- Control0[27]

    -- ========================================================================
    -- Buffer Loading Metadata (from Control1/Control2 during LOADING)
    -- ========================================================================
    signal buffer_length  : unsigned(15 downto 0);       -- Control1[31:16]
    signal expected_crc   : std_logic_vector(31 downto 0);  -- Control2[31:0]

    -- ========================================================================
    -- Data Chunk (Control3-10 bundled)
    -- ========================================================================
    signal chunk_data : mcc_chunk_t;  -- 8 words from Control3-10

    -- ========================================================================
    -- Buffer Loader Outputs
    -- ========================================================================
    signal load_state     : mcc_load_state_t;
    signal buffer_valid   : std_logic;
    signal load_fault     : std_logic;

    -- ========================================================================
    -- Buffer Read Interface
    -- ========================================================================
    signal buffer_addr    : unsigned(11 downto 0);
    signal buffer_data    : std_logic_vector(31 downto 0);

    -- ========================================================================
    -- Clock Divider
    -- ========================================================================
    signal clock_div      : unsigned(7 downto 0);  -- Control0[23:16] in RUNNING phase (8 bits)
    signal div_clk_en     : std_logic;  -- Divided clock enable

    -- ========================================================================
    -- Other Signals
    -- ========================================================================
    signal n_reset       : std_logic;
    signal waveform_out  : signed(15 downto 0);

begin

    -- ========================================================================
    -- MCC Control Signal Extraction
    -- ========================================================================
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    user_clk_en    <= Control0(29);
    load_complete  <= Control0(28);
    load_strobe    <= Control0(27);

    global_enable  <= mcc_ready and user_enable;

    n_reset <= not Reset;

    -- ========================================================================
    -- Extract Buffer Metadata (used during LOADING phase)
    -- ========================================================================
    buffer_length  <= unsigned(Control1(31 downto 16));
    expected_crc   <= Control2;

    -- ========================================================================
    -- Bundle Control3-10 into Chunk Array
    -- ========================================================================
    chunk_data(0) <= Control3;
    chunk_data(1) <= Control4;
    chunk_data(2) <= Control5;
    chunk_data(3) <= Control6;
    chunk_data(4) <= Control7;
    chunk_data(5) <= Control8;
    chunk_data(6) <= Control9;
    chunk_data(7) <= Control10;

    -- ========================================================================
    -- Extract Clock Divider (used during RUNNING phase, overwrites LOAD bits)
    -- ========================================================================
    clock_div <= unsigned(Control0(23 downto 16));  -- 8 bits = 0-255

    -- ========================================================================
    -- MCC Buffer Loader Instance
    -- ========================================================================
    U_BUFFER_LOADER: entity WORK.mcc_buffer_loader
        generic map (
            BUFFER_SIZE => 1024  -- 1024 words = 4KB
        )
        port map (
            clk            => Clk,
            n_reset        => n_reset,

            -- Control signals
            load_complete  => load_complete,
            load_strobe    => load_strobe,
            global_enable  => global_enable,

            -- Metadata
            buffer_length  => buffer_length,
            expected_crc   => expected_crc,

            -- Data input
            chunk_data     => chunk_data,

            -- Outputs
            load_state     => load_state,
            buffer_valid   => buffer_valid,
            load_fault     => load_fault,

            -- Buffer read interface
            buffer_addr    => buffer_addr,
            buffer_dout    => buffer_data
        );

    -- ========================================================================
    -- Clock Divider Instance
    -- ========================================================================
    U_CLK_DIV: entity WORK.clk_divider_core
        generic map (
            MAX_DIV => 8192  -- Maximum division ratio
        )
        port map (
            clk     => Clk,
            rst_n   => n_reset,
            enable  => global_enable and buffer_valid,  -- Only run when buffer valid
            div_sel => std_logic_vector(clock_div(7 downto 0)),  -- Only use lower 8 bits
            clk_en  => div_clk_en,
            stat_reg => open  -- Not used
        );

    -- ========================================================================
    -- Waveform Generator Core
    -- ========================================================================
    U_CORE: entity WORK.buffer_waveform_gen_core
        port map (
            clk           => Clk,
            n_reset       => n_reset,
            enable        => global_enable,
            clk_en        => div_clk_en,
            buffer_length => buffer_length,
            buffer_valid  => buffer_valid,
            buffer_addr   => buffer_addr,
            buffer_data   => buffer_data,
            waveform_out  => waveform_out
        );

    -- ========================================================================
    -- Output Mapping
    -- ========================================================================
    OutputA <= waveform_out;   -- Waveform samples

    -- Debug/status on OutputD
    OutputD(15) <= load_fault;
    OutputD(14) <= buffer_valid;
    OutputD(13 downto 11) <= signed(load_state);
    OutputD(10 downto 0) <= signed(std_logic_vector(buffer_addr(10 downto 0)));

    -- Debug/status on OutputB (for hardware debugging via oscilloscope)
    -- Same format as OutputD but on a routable channel
    OutputB(15) <= load_fault;
    OutputB(14) <= buffer_valid;
    OutputB(13 downto 11) <= signed(load_state);
    OutputB(10 downto 0) <= signed(std_logic_vector(buffer_addr(10 downto 0)));

    -- Unused output
    OutputC <= (others => '0');

end architecture buffer_waveform_gen;

--------------------------------------------------------------------------------
-- Inspectable Buffer Loader - CustomWrapper Architecture
--
-- Description:
--   Integration of inspectable_buffer_loader_core with Moku CustomWrapper.
--   Implements MCC control register mapping and debug output routing.
--
-- Register Map (Control0):
--   Bit[31]    = MCC_READY (auto-set by MCC after deployment)
--   Bit[30]    = User Enable (1=enable, 0=disable)
--   Bit[29]    = Clock Enable (1=run, 0=freeze) - MANDATORY!
--   Bit[28]    = LOAD_COMPLETE (signals "Python done sending chunks")
--   Bit[27]    = LOAD_STROBE (pulse per chunk to trigger latch)
--   Bit[26:24] = DEBUG_SELECT_A (OutputA debug view, 0-7)
--   Bit[23:21] = DEBUG_SELECT_B (OutputB debug view, 0-7)
--   Bit[20:16] = Playback Divider (clock division for waveform playback)
--   Bit[15:0]  = Reserved / Context (used by debug views)
--
-- Register Map (Control1):
--   Bit[31:16] = Buffer Length (words to load, max 65535)
--   Bit[15:0]  = Reserved
--
-- Register Map (Control2):
--   Bit[31:0]  = Expected CRC32 (IEEE 802.3)
--
-- Register Map (Control3-10):
--   8 × 32-bit words per chunk (standard MCC streaming protocol)
--
-- Debug Views (Selectable via Control0[26:24] and Control0[23:21]):
--   View 0: Status Summary (state, fault, valid, buffer_addr)
--   View 1: CRC Comparison (expected vs computed)
--   View 2: Write Activity (chunk_word_idx, write_ptr)
--   View 3: Chunk Data Snapshot (first and last word)
--   View 4: BRAM Readback (address from Control0[10:0])
--   View 5: Timing Diagnostics (strobe, ack, complete, words_written)
--   View 6: Error Diagnostics (error_code, error_state, error_details)
--   View 7: Reserved (Future Use)
--
-- Output Routing:
--   OutputA: Waveform playback (default) OR Debug View A
--   OutputB: Debug View B (always debug)
--
-- MCC 3-Bit Control Scheme:
--   Safe default: All-zero state keeps module disabled (bit 31=0)
--   Network-aware: MCC sets CR0[31]=1 only after config loaded
--   Clock gating: Bit 29 enables sequential logic (MANDATORY!)
--   User control: Bit 30 provides runtime enable/disable
--
-- Tier: 1 (Strict RTL - Direct instantiation pattern)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mcc_loader_pkg.all;

architecture inspectable_buffer_loader of CustomWrapper is

    -- ========================================================================
    -- Control Signal Extraction
    -- ========================================================================
    signal mcc_ready       : std_logic;
    signal user_enable     : std_logic;
    signal user_clk_en     : std_logic;
    signal global_enable   : std_logic;
    signal global_clk_en   : std_logic;

    -- Debug view selection
    signal debug_select_a  : std_logic_vector(2 downto 0);
    signal debug_select_b  : std_logic_vector(2 downto 0);

    -- Playback rate control
    signal playback_div    : std_logic_vector(7 downto 0);

    -- Chunk registers (Control3-10)
    signal chunk_regs      : mcc_chunk_t;

    -- ========================================================================
    -- Core Module Signals
    -- ========================================================================
    signal waveform_out    : signed(15 downto 0);
    signal debug_out_a     : signed(15 downto 0);
    signal debug_out_b     : signed(15 downto 0);

    signal load_state      : std_logic_vector(2 downto 0);
    signal fault           : std_logic;
    signal valid           : std_logic;

    -- ========================================================================
    -- Reset (Active-Low)
    -- ========================================================================
    signal n_reset         : std_logic;

begin

    -- ========================================================================
    -- Reset Inversion (MCC provides active-high Reset)
    -- ========================================================================
    n_reset <= not Reset;

    -- ========================================================================
    -- MCC 3-Bit Control Extraction (CRITICAL!)
    -- ========================================================================
    mcc_ready      <= Control0(31);  -- Auto-set by MCC
    user_enable    <= Control0(30);  -- User-controlled enable
    user_clk_en    <= Control0(29);  -- Clock enable (MANDATORY!)

    -- Combine all 3 bits for safe operation
    global_enable  <= mcc_ready and user_enable;
    global_clk_en  <= mcc_ready and user_clk_en;

    -- ========================================================================
    -- Debug View Selection
    -- ========================================================================
    debug_select_a <= Control0(26 downto 24);  -- OutputA debug view (0-7)
    debug_select_b <= Control0(23 downto 21);  -- OutputB debug view (0-7)

    -- ========================================================================
    -- Playback Rate Control
    -- ========================================================================
    playback_div   <= Control0(20 downto 16) & "000";  -- 5-bit divider → 8-bit (shift left 3)

    -- ========================================================================
    -- Chunk Register Mapping (Control3-10)
    -- ========================================================================
    chunk_regs(0) <= Control3;
    chunk_regs(1) <= Control4;
    chunk_regs(2) <= Control5;
    chunk_regs(3) <= Control6;
    chunk_regs(4) <= Control7;
    chunk_regs(5) <= Control8;
    chunk_regs(6) <= Control9;
    chunk_regs(7) <= Control10;

    -- ========================================================================
    -- Core Module Instantiation (Direct Instantiation Pattern)
    -- ========================================================================
    U_CORE: entity work.inspectable_buffer_loader_core
        generic map (
            BUFFER_SIZE => 1024  -- Max 1024 words
        )
        port map (
            -- Clock and Reset
            clk            => Clk,
            n_reset        => n_reset,

            -- Control Signals
            clk_en         => global_clk_en,
            enable         => global_enable,

            -- MCC Control Registers
            control0       => Control0,
            control1       => Control1,
            control2       => Control2,
            chunk_regs     => chunk_regs,

            -- Debug Output Control
            debug_select_a => debug_select_a,
            debug_select_b => debug_select_b,

            -- Playback Rate Control
            playback_div   => playback_div,

            -- Outputs
            waveform_out   => waveform_out,
            debug_out_a    => debug_out_a,
            debug_out_b    => debug_out_b,

            -- Status
            load_state     => load_state,
            fault          => fault,
            valid          => valid
        );

    -- ========================================================================
    -- Output Routing
    -- ========================================================================
    -- OutputA: Waveform playback (default) OR Debug View A (when view != 0)
    --          For now, always use debug_out_a to simplify initial testing
    OutputA <= debug_out_a;

    -- OutputB: Debug View B (always debug)
    OutputB <= debug_out_b;

    -- OutputC: Not used (tie to zero)
    OutputC <= (others => '0');

    -- OutputD: Not used (tie to zero)
    OutputD <= (others => '0');

end architecture inspectable_buffer_loader;

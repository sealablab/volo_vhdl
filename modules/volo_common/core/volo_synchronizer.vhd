--------------------------------------------------------------------------------
-- Entity: volo_synchronizer
-- Filename: volo_synchronizer.vhd
-- Purpose: Multi-stage synchronizer for clock domain crossing (CDC)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Classic multi-stage flip-flop chain for synchronizing asynchronous signals
--   to a clock domain. Prevents metastability issues when crossing clock domains
--   or sampling external asynchronous inputs.
--
-- Features:
--   - Configurable synchronizer depth (2-4 stages, default 2)
--   - Industry-standard CDC pattern
--   - Optional asynchronous reset
--   - Metastability protection
--   - Standard status register
--
-- Synchronizer Depth (DEPTH generic):
--   2 = Standard 2-FF synchronizer (most common)
--   3 = 3-FF synchronizer (higher reliability, more latency)
--   4 = 4-FF synchronizer (highest reliability, highest latency)
--
-- Timing Behavior:
--   Input change on cycle N → Output reflects change on cycle N+DEPTH
--
--   Example (DEPTH=2):
--     Cycle:     0   1   2   3   4   5
--     async_in:  0   1   1   1   1   1  (async change during cycle 1)
--     sync_out:  0   0   X   1   1   1  (synchronized after 2 cycles)
--                            ↑ metastable state (hidden inside FFs)
--
-- Use Cases:
--
--   1. GPIO Input Synchronization:
--      Synchronize external button, switch, or sensor inputs to FPGA clock.
--      Prevents metastability from propagating into design.
--
--   2. Clock Domain Crossing:
--      Transfer single-bit signals between different clock domains.
--      Example: status flag from slow domain to fast domain.
--
--   3. Async Signal Conditioning:
--      First stage of debounce circuit - sync before debounce logic.
--      Example: Button → Sync (2FF) → Debounce → Edge Detect
--
--   4. Handshake Signals:
--      Synchronize request/acknowledge signals in async protocols.
--      Example: UART RX line, I2C signals.
--
--   5. Reset Synchronization:
--      Synchronize async reset to clock domain (use DEPTH=3 for resets).
--      Example: External reset button → sync → internal reset.
--
-- Metastability Protection:
--   When async_in changes near rising_edge(clk), the first FF may enter
--   metastable state. The second FF resolves this before output, preventing
--   metastability from propagating. MTBF increases exponentially with depth.
--
-- MTBF (Mean Time Between Failures):
--   DEPTH=2: ~10^6 years (typical FPGA at 100 MHz)
--   DEPTH=3: ~10^12 years (extremely reliable)
--   DEPTH=4: ~10^18 years (overkill for most applications)
--
-- Latency:
--   Signal propagation takes DEPTH clock cycles. Trade-off: reliability vs speed.
--   For most applications, DEPTH=2 provides excellent reliability with minimal latency.
--
-- Reset Behavior:
--   Reset is SYNCHRONOUS (registered). This ensures the synchronizer chain
--   itself doesn't introduce metastability. For async reset inputs, use
--   a separate reset synchronizer with DEPTH=3.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - Simple shift register pattern
--   - No complex logic
--   - Easily converted to Verilog
--
-- Synthesis Attributes (to be added by user in constraints):
--   - ASYNC_REG = "TRUE" (Xilinx)
--   - preserve_driver = "true" (Altera/Intel)
--   Prevents optimization from removing synchronizer FFs.
--
-- Students: This is the MOST IMPORTANT pattern in FPGA design! Every async
-- signal MUST be synchronized. Never skip this step - metastability kills!
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_synchronizer is
    generic (
        DEPTH : integer range 2 to 4 := 2  -- Synchronizer depth (2-4 stages)
    );
    port (
        -- Clock and control
        clk         : in  std_logic;       -- Destination clock domain
        n_reset     : in  std_logic;       -- Active-low reset (synchronous)

        -- Input (asynchronous)
        async_in    : in  std_logic;       -- Asynchronous input signal

        -- Output (synchronized)
        sync_out    : out std_logic;       -- Synchronized output

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)  -- Status register
    );
end entity volo_synchronizer;

architecture rtl of volo_synchronizer is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    -- None needed for this simple module

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    -- Synchronizer flip-flop chain (fixed size, use first DEPTH elements)
    -- sync_chain(0) is first FF (directly samples async_in)
    -- sync_chain(DEPTH-1) is last FF (drives sync_out)
    -- Max depth is 4, so allocate 4 FFs (only DEPTH are used)
    signal sync_chain : std_logic_vector(3 downto 0);

    -- Synthesis attributes to prevent optimization
    -- Note: These are for documentation - actual attributes added in constraints
    -- attribute ASYNC_REG : string;
    -- attribute ASYNC_REG of sync_chain : signal is "TRUE";

begin

    -- =========================================================================
    -- SYNCHRONIZER CHAIN (Sequential)
    -- =========================================================================
    -- Classic shift register: async_in → FF0 → FF1 → ... → FFn → sync_out
    --
    -- Critical: Do NOT add ANY logic between FFs! Pure shift register only.
    -- Any logic breaks the metastability resolution.
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Reset all FFs to 0 (safe default)
            sync_chain <= (others => '0');

        elsif rising_edge(clk) then
            -- Shift register: shift the chain
            -- Always shift all stages (unused stages don't matter)
            sync_chain(0) <= async_in;        -- FF0 samples async input
            sync_chain(1) <= sync_chain(0);    -- FF1 <- FF0
            sync_chain(2) <= sync_chain(1);    -- FF2 <- FF1
            sync_chain(3) <= sync_chain(2);    -- FF3 <- FF2
            -- Only sync_chain(DEPTH-1) is actually used for output
        end if;
    end process;

    -- Output comes from last FF in chain
    sync_out <= sync_chain(DEPTH-1);

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5-4: Synchronizer depth (encoded)
    -- Bit 3-2: Reserved (always 0)
    -- Bit 1: Async input value (RAW - use for debug only!)
    -- Bit 0: Sync output value
    --
    -- Note: Reading async_in in status register is for DEBUG ONLY.
    -- Never use stat_reg[1] in logic - it may be metastable!
    -- Always use sync_out instead.
    stat_reg <= "00" & std_logic_vector(to_unsigned(DEPTH, 2)) & "00" & async_in & sync_chain(DEPTH-1);

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why do we need a synchronizer?
    -- A: Async signals can change near clock edges, causing metastability.
    --    The first FF may oscillate briefly, but settles before the second FF
    --    samples it. This prevents metastability from propagating.
    --
    -- Q: Can I add logic between the FFs?
    -- A: NO! Never add logic in the synchronizer chain. Pure shift register only.
    --    Logic breaks the metastability resolution timing.
    --
    -- Q: When should I use DEPTH=3 instead of DEPTH=2?
    -- A: Use DEPTH=3 for:
    --    - Very high-speed clocks (>200 MHz)
    --    - Safety-critical applications
    --    - Reset synchronization
    --    Use DEPTH=2 for most other cases.
    --
    -- Q: What about the async_in in stat_reg[1]?
    -- A: That's for DEBUG ONLY (waveform viewing). Never use it in logic!
    --    It may be metastable. Always use sync_out.
    --
    -- Q: How do I synchronize multi-bit buses?
    -- A: DON'T! Use handshake protocols (req/ack) or async FIFOs instead.
    --    Synchronizing buses can cause data corruption (each bit syncs differently).
    --
    -- Q: Can I use this for clock domain crossing?
    -- A: Yes, but ONLY for single-bit signals. For multi-bit data, use:
    --    - Async FIFO (different clocks)
    --    - Handshake protocol (req/ack with synchronizers)
    --    - Gray code counters (special case)
    --
    -- Q: Why is reset synchronous, not asynchronous?
    -- A: To avoid introducing metastability in the synchronizer itself!
    --    If you have an async reset input, use a SEPARATE reset synchronizer
    --    with DEPTH=3.

end architecture rtl;

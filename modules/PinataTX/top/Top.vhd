--------------------------------------------------------------------------------
-- PinataTX - CustomWrapper Top Level (MokuBench Deployment)
--
-- Description:
--   UART transmitter for sending commands to Riscure Pinata board.
--   Single-byte raw binary protocol at 115200 baud.
--
-- Control Register Map:
--   MCC 3-Bit Control Scheme:
--     Control0[31] = MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
--     Control0[30] = User Enable (1=enable, 0=disable)
--     Control0[29] = Clock Enable (1=clocked, 0=frozen)
--     Control0[7:0] = Command byte (e.g., 0x74='t' trigger, 0x70='p' ping)
--
--   Control1[0]  = Send pulse (write 1 to transmit cmd_byte)
--
-- Output Mapping:
--   OutputA(0) = UART TX bit → DIO pin (via MCC routing)
--   OutputA(15:1) = '0' (unused bits)
--   OutputB(0) = TX busy (1=transmitting, 0=ready)
--   OutputB(1) = TX done pulse (1 cycle wide)
--   OutputB(15:2) = '0' (reserved)
--   OutputC = '0' (unused)
--   OutputD = '0' (unused)
--
-- Usage (Python MokuBench):
--   # Initialize with MCC 3-bit control
--   mcc.set_control(0, 0xE0000074)  # MCC_READY + Enable + ClkEn + cmd='t'
--   mcc.set_control(1, 0x00000001)  # Send pulse
--
--   # Wait for completion (read OutputB for status)
--   while mcc.get_output('b') & 0x01:  # Check TX busy (OutputB bit 0)
--       pass
--
--   # Send next command
--   mcc.set_control(0, 0xE0000070)  # cmd='p' ping
--   mcc.set_control(1, 0x00000001)  # Send pulse
--
-- Pinata Commands:
--   0x74 ('t') - Trigger (start capture/attack)
--   0x70 ('p') - Ping (connection test)
--   0x78 ('x') - Reset target
--   0x6B ('k') - Glitch test
--
-- Timing:
--   Each byte: ~86.8 μs @ 115200 baud
--   Max rate: ~11.5 kB/s (but check TX busy between commands!)
--
-- Tier: 1 (Strict RTL - Verilog portable top level)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture PinataTX of CustomWrapper is

    -- ========================================================================
    -- MCC Control Signals (3-bit scheme)
    -- ========================================================================
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal user_clk_en    : std_logic;
    signal global_enable  : std_logic;

    -- ========================================================================
    -- Command Interface
    -- ========================================================================
    signal cmd_byte       : std_logic_vector(7 downto 0);
    signal send_pulse     : std_logic;

    -- ========================================================================
    -- UART Signals
    -- ========================================================================
    signal uart_tx_bit    : std_logic;
    signal tx_busy_flag   : std_logic;
    signal tx_done_pulse  : std_logic;

    -- ========================================================================
    -- Active-Low Reset
    -- ========================================================================
    signal n_reset        : std_logic;

begin

    -- ========================================================================
    -- MCC_READY LOGIC (3-Bit Active-High Convention)
    -- ========================================================================
    -- Control0[31] = MCC_READY: Set by MCC after configuration loaded
    -- Control0[30] = User Enable: User-level enable bit
    -- Control0[29] = Clock Enable: Runtime clock freeze control
    -- Global enable gates all three: module only operates when MCC is ready AND user enables
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    user_clk_en    <= Control0(29);
    global_enable  <= mcc_ready and user_enable and user_clk_en;

    -- Reset is active-low, inverted from Reset input
    n_reset <= not Reset;

    -- ========================================================================
    -- COMMAND EXTRACTION
    -- ========================================================================
    cmd_byte     <= Control0(7 downto 0);   -- Command byte (0x74='t', 0x70='p', etc.)
    send_pulse   <= Control1(0);            -- Send trigger (pulse high to transmit)

    -- ========================================================================
    -- PINATA TX CORE INSTANCE
    -- ========================================================================
    U_PINATA_TX: entity WORK.PinataTX_core
        port map (
            clk         => Clk,
            n_reset     => n_reset,
            enable      => global_enable,
            clk_en      => user_clk_en,
            cmd_byte    => cmd_byte,
            send_pulse  => send_pulse,
            uart_tx     => uart_tx_bit,
            tx_busy     => tx_busy_flag,
            tx_done     => tx_done_pulse
        );

    -- ========================================================================
    -- OUTPUT MAPPING
    -- ========================================================================
    -- OutputA(0) = UART TX bit → routes to DIO pin via MCC
    -- OutputA(15:1) = unused (tie to zero)
    OutputA(0)           <= uart_tx_bit when global_enable = '1' else '1';  -- Idle high when disabled
    OutputA(15 downto 1) <= (others => '0');

    -- OutputB = Status bits (for readback in Python)
    --   Bit 0: TX busy (1=transmitting, 0=ready for next command)
    --   Bit 1: TX done pulse (may be missed if polling too slow)
    --   Bits 15:2: Reserved (zero)
    OutputB(0)            <= tx_busy_flag;
    OutputB(1)            <= tx_done_pulse;
    OutputB(15 downto 2)  <= (others => '0');

    -- Unused outputs (tie to zero)
    OutputC <= (others => '0');
    OutputD <= (others => '0');

end architecture PinataTX;

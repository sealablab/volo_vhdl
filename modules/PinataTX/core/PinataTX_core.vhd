--------------------------------------------------------------------------------
-- Entity: PinataTX_core
-- Filename: PinataTX_core.vhd
-- Purpose: Pinata UART transmitter core (115200 baud, 8N1)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Simple UART transmitter for sending single-byte commands to Riscure Pinata
--   board. Uses volo_uart_tx_core configured for 115200 baud @ 125 MHz.
--
-- Protocol:
--   - Baud rate: 115200 (Pinata standard)
--   - Format: 8N1 (8 data bits, no parity, 1 stop bit)
--   - Encoding: Raw binary (no hex encoding like SimpleSerial V1)
--   - Commands: Single bytes ('t'=0x74 trigger, 'p'=0x70 ping, etc.)
--
-- Interface:
--   clk         - 125 MHz system clock
--   n_reset     - Active-low reset
--   enable      - Functional enable (0=idle, 1=active)
--   clk_en      - Clock enable (0=frozen, 1=running)
--   cmd_byte    - Command byte to transmit (e.g., 0x74 for 't')
--   send_pulse  - Pulse high for 1 cycle to start transmission
--   uart_tx     - UART TX output (connect to DIO pin)
--   tx_busy     - Transmission in progress flag
--   tx_done     - Transmission complete pulse (1 cycle)
--
-- Common Commands:
--   0x74 ('t') - Trigger (start capture/attack)
--   0x70 ('p') - Ping (connection test)
--   0x78 ('x') - Reset target
--   0x6B ('k') - Glitch test
--
-- Usage:
--   1. Set cmd_byte to desired command (e.g., 0x74)
--   2. Pulse send_pulse high for 1 clock cycle
--   3. Wait for tx_busy to go low (or tx_done pulse)
--   4. Repeat for next command
--
-- Timing:
--   - Each byte takes ~86.8 μs @ 115200 baud (10 bits × 8.68 μs/bit)
--   - Minimum spacing: wait for tx_busy=0 before next send
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PinataTX_core is
    port (
        -- Clock and control
        clk         : in  std_logic;                     -- System clock (125 MHz)
        n_reset     : in  std_logic;                     -- Active-low reset
        enable      : in  std_logic;                     -- Functional enable
        clk_en      : in  std_logic;                     -- Clock enable (freeze FSM)

        -- Command interface
        cmd_byte    : in  std_logic_vector(7 downto 0);  -- Command to send
        send_pulse  : in  std_logic;                     -- Pulse to start transmission

        -- UART output
        uart_tx     : out std_logic;                     -- UART TX line (to DIO)

        -- Status
        tx_busy     : out std_logic;                     -- Transmission in progress
        tx_done     : out std_logic                      -- Transmission complete (1 cycle pulse)
    );
end entity PinataTX_core;

architecture rtl of PinataTX_core is

    -- =========================================================================
    -- CONSTANTS
    -- =========================================================================
    -- Pinata uses 115200 baud @ 125 MHz
    constant CLK_FREQ_HZ : natural := 125_000_000;
    constant BAUD_RATE   : natural := 115200;

begin

    -- =========================================================================
    -- UART TRANSMITTER CORE
    -- =========================================================================
    -- Instantiate volo_uart_tx_core with Pinata-specific configuration
    U_UART_TX: entity WORK.uart_tx_core
        generic map (
            CLK_FREQ_HZ => CLK_FREQ_HZ,
            BAUD_RATE   => BAUD_RATE
        )
        port map (
            clk        => clk,
            rst_n      => n_reset,
            enable     => enable,
            data_in    => cmd_byte,
            send_valid => send_pulse,
            tx         => uart_tx,
            tx_busy    => tx_busy,
            tx_done    => tx_done,
            stat_reg   => open  -- Don't need internal status for Pinata
        );

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why is this module so simple?
    -- A: Because we built solid reusable components! PinataTX is just a
    --    wrapper around volo_uart_tx_core with Pinata-specific config.
    --
    -- Q: What's the difference between this and SimpleSerial?
    -- A: Pinata uses raw binary commands (single bytes). SimpleSerial V1
    --    uses hex-encoded ASCII with terminators. SimpleSerial V2 uses
    --    binary with COBS encoding and CRC.
    --
    -- Q: Can I use this for other UART applications?
    -- A: Yes! Just change CLK_FREQ_HZ and BAUD_RATE constants. Or make
    --    them generics for even more flexibility.
    --
    -- Q: How do I send multiple commands?
    -- A: Wait for tx_busy=0, then:
    --    1. Change cmd_byte to new value
    --    2. Pulse send_pulse high for 1 cycle
    --    3. Wait for tx_busy=0 again
    --
    -- Q: What happens if I pulse send_pulse while tx_busy=1?
    -- A: The volo_uart_tx_core ignores send_valid when busy, so the
    --    new command is dropped. Always wait for tx_busy=0!

end architecture rtl;

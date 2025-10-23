--------------------------------------------------------------------------------
-- Entity: uart_tx_core
-- Filename: volo_uart_tx_core.vhd
-- Purpose: UART transmitter with 8N1 framing (8 data bits, no parity, 1 stop)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Single-byte UART transmitter with clean interface. Handles framing
--   (start bit, 8 data bits, stop bit) and timing. Designed for reusability
--   and integration with higher-level modules (FIFO wrappers, protocol
--   handlers, etc.).
--
-- Features:
--   - 8N1 UART framing (standard)
--   - Configurable baud rate via generic or divider input
--   - Single-byte interface (load data, pulse send, wait for ready)
--   - Status outputs: tx_busy, tx_done
--   - Idles high when not transmitting (UART standard)
--   - Enable input for control
--
-- Timing:
--   - Load data_in and pulse send_valid high for 1 cycle
--   - tx_busy goes high during transmission (10 bit periods)
--   - tx_done pulses high for 1 cycle when frame completes
--   - Ready for next byte when tx_busy returns low
--
-- Frame Structure (8N1):
--   [START=0][D0][D1][D2][D3][D4][D5][D6][D7][STOP=1]
--   - Start bit: Always 0
--   - Data bits: LSB first (D0 to D7)
--   - Stop bit: Always 1
--   - Total: 10 bits per frame
--
-- Integration Example:
--   UART_TX: entity work.uart_tx_core
--       generic map (CLK_FREQ_HZ => 125_000_000, BAUD_RATE => 115200)
--       port map (clk => clk, rst_n => rst_n, enable => '1',
--                 data_in => tx_byte, send_valid => tx_send,
--                 tx => uart_tx_pin, tx_busy => uart_busy);
--
-- Students: This is a classic FSM (Finite State Machine) design!
-- States: IDLE → START → DATA0..7 → STOP → IDLE
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.uart_pkg.all;

entity uart_tx_core is
    generic (
        CLK_FREQ_HZ   : natural := CLK_FREQ_MOKU_GO;  -- System clock (default: 125 MHz)
        BAUD_RATE     : natural := UART_BAUD_115200   -- Target baud rate (default: 115200)
    );
    port (
        -- Clock and control
        clk         : in  std_logic;                    -- System clock
        rst_n       : in  std_logic;                    -- Active-low reset
        enable      : in  std_logic;                    -- Enable (freeze FSM when low)

        -- Data interface
        data_in     : in  std_logic_vector(7 downto 0); -- Byte to transmit
        send_valid  : in  std_logic;                    -- Pulse high to send data_in

        -- UART output
        tx          : out std_logic;                    -- UART TX line

        -- Status outputs
        tx_busy     : out std_logic;                    -- Transmission in progress
        tx_done     : out std_logic;                    -- Frame complete (1-cycle pulse)

        -- Status register (for debugging/monitoring)
        stat_reg    : out std_logic_vector(7 downto 0)  -- [7:4]=state, [3:0]=bit_index
    );
end entity uart_tx_core;

architecture rtl of uart_tx_core is

    -- FSM states (using std_logic_vector for Verilog portability)
    constant STATE_IDLE  : std_logic_vector(3 downto 0) := "0000";  -- Idle, ready for data
    constant STATE_START : std_logic_vector(3 downto 0) := "0001";  -- Transmitting start bit
    constant STATE_DATA  : std_logic_vector(3 downto 0) := "0010";  -- Transmitting data bits
    constant STATE_STOP  : std_logic_vector(3 downto 0) := "0011";  -- Transmitting stop bit

    -- Internal signals
    signal state          : std_logic_vector(3 downto 0);  -- Current FSM state
    signal tx_shift_reg   : std_logic_vector(7 downto 0);  -- Shift register for data
    signal bit_index      : unsigned(3 downto 0);          -- Current bit being transmitted (0-7)
    signal tx_int         : std_logic;                     -- Internal TX signal
    signal busy_int       : std_logic;                     -- Internal busy signal

    -- Baud rate generator signals
    signal baud_div       : std_logic_vector(15 downto 0);
    signal baud_tick      : std_logic;

    -- Calculate divider at compile time
    constant DIVIDER_VALUE : natural := calc_baud_divider(CLK_FREQ_HZ, BAUD_RATE);

begin

    -- =========================================================================
    -- BAUD RATE GENERATOR INSTANCE
    -- =========================================================================

    -- Convert divider to std_logic_vector
    baud_div <= std_logic_vector(to_unsigned(DIVIDER_VALUE, 16));

    BAUD_GEN: entity work.uart_baud_gen
        generic map (
            MAX_DIVIDER => 65535
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            enable    => enable,
            div_value => baud_div,
            baud_tick => baud_tick,
            stat_reg  => open  -- Not used
        );

    -- =========================================================================
    -- UART TX FSM
    -- =========================================================================

    uart_tx_fsm: process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Reset: Return to idle state
            state         <= STATE_IDLE;
            tx_shift_reg  <= (others => '0');
            bit_index     <= (others => '0');
            tx_int        <= UART_IDLE_STATE;  -- TX line idles high
            busy_int      <= '0';
            tx_done       <= '0';

        elsif rising_edge(clk) then
            -- Default: Clear single-cycle pulses
            tx_done <= '0';

            if enable = '1' then
                case state is

                    -- =============================================================
                    -- IDLE STATE: Wait for send_valid pulse
                    -- =============================================================
                    when STATE_IDLE =>
                        tx_int   <= UART_IDLE_STATE;  -- Keep TX high
                        busy_int <= '0';

                        if send_valid = '1' then
                            -- Load data into shift register and start transmission
                            tx_shift_reg <= data_in;
                            bit_index    <= (others => '0');
                            busy_int     <= '1';
                            state        <= STATE_START;
                        end if;

                    -- =============================================================
                    -- START BIT: Transmit start bit (low) for 1 bit period
                    -- =============================================================
                    when STATE_START =>
                        tx_int <= UART_START_BIT;  -- Start bit = 0

                        if baud_tick = '1' then
                            -- Start bit complete, move to data transmission
                            state <= STATE_DATA;
                            bit_index <= (others => '0');
                        end if;

                    -- =============================================================
                    -- DATA BITS: Transmit 8 data bits (LSB first)
                    -- =============================================================
                    when STATE_DATA =>
                        -- Output current bit (LSB first)
                        tx_int <= tx_shift_reg(0);

                        if baud_tick = '1' then
                            -- Shift right to get next bit
                            tx_shift_reg <= '0' & tx_shift_reg(7 downto 1);

                            if bit_index = 7 then
                                -- All 8 bits transmitted, move to stop bit
                                state <= STATE_STOP;
                            else
                                -- More bits to transmit
                                bit_index <= bit_index + 1;
                            end if;
                        end if;

                    -- =============================================================
                    -- STOP BIT: Transmit stop bit (high) for 1 bit period
                    -- =============================================================
                    when STATE_STOP =>
                        tx_int <= UART_STOP_BIT;  -- Stop bit = 1

                        if baud_tick = '1' then
                            -- Frame complete!
                            tx_done  <= '1';  -- Pulse tx_done for 1 cycle
                            busy_int <= '0';
                            state    <= STATE_IDLE;
                        end if;

                    -- =============================================================
                    -- DEFAULT: Return to idle (safety)
                    -- =============================================================
                    when others =>
                        state    <= STATE_IDLE;
                        busy_int <= '0';
                        tx_int   <= UART_IDLE_STATE;

                end case;

            else
                -- Enable low: freeze FSM, hold TX line
                -- (state, tx_int, busy_int all hold their values)
                null;
            end if;
        end if;
    end process uart_tx_fsm;

    -- =========================================================================
    -- OUTPUT ASSIGNMENTS
    -- =========================================================================

    tx      <= tx_int;
    tx_busy <= busy_int;

    -- Status register: [7:4]=state, [3:0]=bit_index
    stat_reg <= state & std_logic_vector(bit_index);

    -- =========================================================================
    -- ASSERTIONS (Simulation only)
    -- =========================================================================

    -- synthesis translate_off
    assert_baud_error: process
        variable actual_baud : natural;
        variable error_pct   : real;
    begin
        wait for 0 ns;  -- Run once at start of simulation

        actual_baud := calc_actual_baud(CLK_FREQ_HZ, DIVIDER_VALUE);
        error_pct   := calc_baud_error_pct(BAUD_RATE, actual_baud);

        report "uart_tx_core: Configured for " & integer'image(BAUD_RATE) & " baud" severity note;
        report "uart_tx_core: Actual baud = " & integer'image(actual_baud) &
               " (" & real'image(error_pct) & "% error)" severity note;
        report "uart_tx_core: Divider = " & integer'image(DIVIDER_VALUE) severity note;

        assert error_pct < 2.0
            report "uart_tx_core: WARNING - Baud rate error > 2%!"
            severity warning;

        wait;  -- Run once only
    end process assert_baud_error;

    assert_no_overrun: process(clk)
    begin
        if rising_edge(clk) then
            if send_valid = '1' and busy_int = '1' then
                report "uart_tx_core: ERROR - send_valid asserted while tx_busy! Data will be lost!"
                    severity error;
            end if;
        end if;
    end process assert_no_overrun;
    -- synthesis translate_on

end architecture rtl;

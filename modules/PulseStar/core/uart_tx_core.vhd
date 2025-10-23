--------------------------------------------------------------------------------
-- UART Transmitter Core - PulseStar Digital Pattern Generator
--
-- Description:
--   Simple UART transmitter that sends repeating ASCII pattern "VOLO".
--   Configurable baud rate for testing digital signal decoding.
--
-- Features:
--   - Standard 8N1 format (8 data bits, no parity, 1 stop bit)
--   - Configurable baud rate via clock divider
--   - Repeating pattern: "VOLO" (0x56 0x4F 0x4C 0x4F)
--   - Clean start/stop bit generation
--
-- UART Frame Format:
--   [START=0][D0][D1][D2][D3][D4][D5][D6][D7][STOP=1]
--
-- Inputs:
--   clk         : System clock (125 MHz)
--   n_reset     : Active-low reset
--   enable      : Functional enable (0=idle, 1=transmitting)
--   clk_en      : Clock enable (0=frozen, 1=running)
--   baud_div    : Baud rate divider (clk / (baud_div+1) = baud_rate)
--                 Example: 125MHz / 1085 ≈ 115200 baud → baud_div = 1084
--
-- Outputs:
--   uart_out    : UART serial output (signed 16-bit for CustomWrapper)
--                 High (0x7FFF) = logic '1', Low (0x8000) = logic '0'
--
-- Tier: 1 (Strict RTL - Verilog portable core logic)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx_core is
    port (
        -- Clock and Control
        clk         : in  std_logic;
        n_reset     : in  std_logic;
        enable      : in  std_logic;
        clk_en      : in  std_logic;

        -- Configuration
        baud_div    : in  std_logic_vector(15 downto 0);  -- Baud rate divider

        -- Output
        uart_out    : out signed(15 downto 0)
    );
end entity uart_tx_core;

architecture rtl of uart_tx_core is

    -- Pattern ROM: "VOLO" ASCII characters
    type pattern_rom_t is array (0 to 3) of std_logic_vector(7 downto 0);
    constant PATTERN_ROM : pattern_rom_t := (
        X"56",  -- 'V'
        X"4F",  -- 'O'
        X"4C",  -- 'L'
        X"4F"   -- 'O'
    );

    -- State machine encoding
    constant STATE_IDLE  : std_logic_vector(1 downto 0) := "00";
    constant STATE_START : std_logic_vector(1 downto 0) := "01";
    constant STATE_DATA  : std_logic_vector(1 downto 0) := "10";
    constant STATE_STOP  : std_logic_vector(1 downto 0) := "11";

    signal current_state : std_logic_vector(1 downto 0);

    -- Baud rate clock enable generator
    signal baud_counter : unsigned(15 downto 0);
    signal baud_tick    : std_logic;

    -- Pattern index (0-3 for "VOLO")
    signal pattern_idx : unsigned(1 downto 0);

    -- Bit counter (0-7 for data bits)
    signal bit_idx : unsigned(2 downto 0);

    -- Current data byte being transmitted
    signal tx_data : std_logic_vector(7 downto 0);

    -- UART output bit (internal)
    signal uart_bit : std_logic;

begin

    -- ========================================================================
    -- Baud Rate Clock Enable Generator
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            baud_counter <= (others => '0');
            baud_tick    <= '0';

        elsif rising_edge(clk) then
            if clk_en = '1' and enable = '1' then
                if baud_counter >= unsigned(baud_div) then
                    baud_counter <= (others => '0');
                    baud_tick    <= '1';
                else
                    baud_counter <= baud_counter + 1;
                    baud_tick    <= '0';
                end if;
            else
                baud_counter <= (others => '0');
                baud_tick    <= '0';
            end if;
        end if;
    end process;

    -- ========================================================================
    -- UART Transmit State Machine
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            current_state <= STATE_IDLE;
            pattern_idx   <= (others => '0');
            bit_idx       <= (others => '0');
            tx_data       <= (others => '0');
            uart_bit      <= '1';  -- Idle high

        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then
                    if baud_tick = '1' then
                        case current_state is

                            when STATE_IDLE =>
                                -- Load next character from pattern ROM
                                tx_data       <= PATTERN_ROM(to_integer(pattern_idx));
                                current_state <= STATE_START;
                                uart_bit      <= '1';  -- Idle high

                            when STATE_START =>
                                -- Send start bit (0)
                                uart_bit      <= '0';
                                bit_idx       <= (others => '0');
                                current_state <= STATE_DATA;

                            when STATE_DATA =>
                                -- Send data bits LSB first
                                uart_bit <= tx_data(to_integer(bit_idx));

                                if bit_idx = 7 then
                                    current_state <= STATE_STOP;
                                else
                                    bit_idx <= bit_idx + 1;
                                end if;

                            when STATE_STOP =>
                                -- Send stop bit (1)
                                uart_bit <= '1';

                                -- Advance to next character in pattern
                                if pattern_idx = 3 then
                                    pattern_idx <= (others => '0');  -- Wrap to 'V'
                                else
                                    pattern_idx <= pattern_idx + 1;
                                end if;

                                current_state <= STATE_IDLE;

                            when others =>
                                current_state <= STATE_IDLE;
                                uart_bit      <= '1';

                        end case;
                    end if;

                else
                    -- Disabled: reset to idle
                    current_state <= STATE_IDLE;
                    pattern_idx   <= (others => '0');
                    uart_bit      <= '1';
                end if;
            end if;
            -- clk_en='0': state frozen
        end if;
    end process;

    -- ========================================================================
    -- Output Mapping: Convert UART bit to signed output
    -- ========================================================================
    -- UART high (1) → 0x7FFF (max positive)
    -- UART low  (0) → 0x8000 (max negative)
    uart_out <= X"7FFF" when uart_bit = '1' else X"8000";

end architecture rtl;

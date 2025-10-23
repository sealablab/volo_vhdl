--------------------------------------------------------------------------------
-- PulseStar - CustomWrapper Top Level (MokuBench Deployment)
--
-- Description:
--   4-channel calibration signal generator for verifying inter-instrument
--   communication and signal integrity. Produces I/Q quadrature waveforms,
--   UART serial patterns, and synchronization triggers.
--
-- Control Register Map:
--   MCC_READY Convention:
--     Control0[31] = MCC_READY flag (ACTIVE-HIGH)
--       0 = Module disabled (safe during bitstream load / all-zero state)
--       1 = Module enabled and ready for operation
--
--   Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
--   Control0[30]:    Global Enable (1=enable, 0=disable)
--   Control0[29]:    Clock Enable (1=run, 0=freeze all outputs)
--   Control0[28:21]: Frequency Divider (0-255) for I/Q waveforms
--   Control0[19:16]: Reserved
--   Control0[15:8]:  Reserved (future: amplitude scale)
--   Control0[7:0]:   Reserved (future: phase offset)
--
--   Control1[31:16]: UART Baud Divider (clk / (baud_div+1) = baud_rate)
--                    Example: 1084 → 115200 baud @ 125MHz
--   Control1[15:0]:  Trigger Pulse Interval (clock cycles between pulses)
--
--   Control2[31:24]: Trigger Pulse Width (clock cycles per pulse)
--   Control2[23:0]:  Reserved
--
-- Output Mapping:
--   OutputA: I Channel (Sine wave, 16-bit signed)
--   OutputB: Q Channel (Cosine wave, 90° phase offset, 16-bit signed)
--   OutputC: UART Serial ("VOLO" repeating pattern, 16-bit signed)
--   OutputD: Trigger Pulse (synchronization/timing reference, 16-bit signed)
--
-- Usage (Python MokuBench):
--   # Basic configuration (115200 baud, 1kHz I/Q, 1ms trigger interval)
--   mcc.set_control(0, 0xC0F40000)  # MCC_READY + Enable + ClkEn + Div=244 (≈1kHz)
--   mcc.set_control(1, 0x043C7D00)  # Baud=1084 (115200), Interval=32000 (256us)
--   mcc.set_control(2, 0x64000000)  # PulseWidth=100 clocks (800ns)
--
-- Tier: 1 (Strict RTL - Verilog portable top level)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture PulseStar of CustomWrapper is

    -- ========================================================================
    -- MCC Control Signals
    -- ========================================================================
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal user_clk_en    : std_logic;
    signal global_enable  : std_logic;

    -- ========================================================================
    -- Configuration Signals (extracted from Control registers)
    -- ========================================================================
    signal freq_div         : std_logic_vector(7 downto 0);   -- Control0[28:21]
    signal baud_div         : std_logic_vector(15 downto 0);  -- Control1[31:16]
    signal trigger_interval : std_logic_vector(15 downto 0);  -- Control1[15:0]
    signal trigger_width    : std_logic_vector(7 downto 0);   -- Control2[31:24]

    -- ========================================================================
    -- Internal Signals
    -- ========================================================================
    signal n_reset   : std_logic;
    signal i_signal  : signed(15 downto 0);
    signal q_signal  : signed(15 downto 0);
    signal uart_sig  : signed(15 downto 0);
    signal trig_sig  : signed(15 downto 0);

begin

    -- ========================================================================
    -- MCC_READY LOGIC (Active-High Convention)
    -- ========================================================================
    -- Control0[31] = MCC_READY: Set by MCC after configuration loaded
    -- Control0[30] = User Enable: User-level enable bit
    -- Control0[29] = Clock Enable: Runtime clock freeze control
    -- Global enable gates both: module only operates when MCC is ready AND user enables
    mcc_ready      <= Control0(31);
    user_enable    <= Control0(30);
    user_clk_en    <= Control0(29);
    global_enable  <= mcc_ready and user_enable;

    -- Reset is active-low, inverted from Reset input
    n_reset <= not Reset;

    -- ========================================================================
    -- CONFIGURATION EXTRACTION
    -- ========================================================================
    freq_div         <= Control0(28 downto 21);  -- Frequency divider (0-255)
    baud_div         <= Control1(31 downto 16);  -- UART baud rate divider
    trigger_interval <= Control1(15 downto 0);   -- Trigger pulse interval
    trigger_width    <= Control2(31 downto 24);  -- Trigger pulse width

    -- ========================================================================
    -- CORE INSTANCES
    -- ========================================================================

    -- I/Q Waveform Generator (OutputA/B)
    U_WAVEFORM_GEN: entity WORK.waveform_gen_core
        port map (
            clk         => Clk,
            n_reset     => n_reset,
            enable      => global_enable,
            clk_en      => user_clk_en,
            freq_div    => freq_div,
            i_out       => i_signal,
            q_out       => q_signal
        );

    -- UART Transmitter (OutputC)
    U_UART_TX: entity WORK.uart_tx_core
        port map (
            clk         => Clk,
            n_reset     => n_reset,
            enable      => global_enable,
            clk_en      => user_clk_en,
            baud_div    => baud_div,
            uart_out    => uart_sig
        );

    -- Trigger Pulse Generator (OutputD)
    U_TRIGGER_GEN: entity WORK.trigger_gen_core
        port map (
            clk             => Clk,
            n_reset         => n_reset,
            enable          => global_enable,
            clk_en          => user_clk_en,
            pulse_interval  => trigger_interval,
            pulse_width     => trigger_width,
            trigger_out     => trig_sig
        );

    -- ========================================================================
    -- OUTPUT MAPPING
    -- ========================================================================
    OutputA <= i_signal;   -- I Channel (Sine)
    OutputB <= q_signal;   -- Q Channel (Cosine, 90° offset)
    OutputC <= uart_sig;   -- UART Serial ("VOLO")
    OutputD <= trig_sig;   -- Trigger Pulse

end architecture PulseStar;

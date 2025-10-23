--------------------------------------------------------------------------------
-- Simple Counter - CustomWrapper Top Level (MokuBench Deployment)
--
-- Description:
--   CustomWrapper architecture for deploying simple_counter_core to Moku via
--   CloudCompile. Demonstrates minimal MokuBench configuration.
--
-- Control Register Map:
--   Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
--   Control0[30]:    User Enable (1=enable, 0=disable)
--   Control0[29]:    Clock Enable (1=run, 0=freeze)
--   Control0[28:0]:  Reserved
--
-- Output Mapping:
--   OutputA: Counter value (16-bit, mapped to signed)
--   OutputB: Counter MSB (repeated for visibility)
--   OutputC: Zero
--   OutputD: Zero
--
-- Usage (Python MokuBench):
--   mcc.set_control(0, 0xE0000000)  # MCC_READY + Enable + ClkEn
--   # Counter increments, OutputA shows count value
--
-- Tier: 1 (Strict RTL - Verilog portable top level)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture simple_counter_top of CustomWrapper is

    -- MCC control signals
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal user_clk_en    : std_logic;
    signal global_enable  : std_logic;

    -- Counter signals
    signal count_value    : std_logic_vector(15 downto 0);
    signal n_reset        : std_logic;

begin

    -- Extract control signals from Control0
    mcc_ready    <= Control0(31);
    user_enable  <= Control0(30);
    user_clk_en  <= Control0(29);

    -- Global enable: Safe when MCC_READY=1 and user enables
    global_enable <= mcc_ready and user_enable;

    -- Reset is active-low, inverted from Reset input
    n_reset <= not Reset;

    -- Instantiate simple_counter_core
    COUNTER_CORE: entity WORK.simple_counter_core
        port map (
            clk       => Clk,
            n_reset   => n_reset,
            clk_en    => user_clk_en,
            enable    => global_enable,
            count_out => count_value
        );

    -- Output mapping (convert unsigned count to signed outputs)
    OutputA <= signed(count_value);                     -- Full 16-bit counter
    OutputB <= resize(signed(count_value(15 downto 8)), 16);  -- MSB only (for visualization)
    OutputC <= (others => '0');                         -- Unused
    OutputD <= (others => '0');                         -- Unused

end architecture simple_counter_top;

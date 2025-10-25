-- ###########################################################################
-- # OneHot-Analog-Monitor (Marker DAC for Sequencer)                        #
-- #
-- # High-level
-- # - A tiny wrapper that maps a one-hot sequencer state to a configurable
-- #   analog level on a 16-bit signed DAC output (Moku:Go, -5V..+5V).
-- # - Purpose: let students SEE state transitions on a scope and set simple
-- #   voltage triggers (stair-step levels: S1<S2<S3<S4).
-- #
-- # Behavior
-- # - S1 -> level_s1 input (default: 1.1V = 0x199A = 6554)
-- # - S2 -> level_s2 input (default: 1.2V = 0x1EB8 = 7864)
-- # - S3 -> level_s3 input (default: 1.3V = 0x23D7 = 9175)
-- # - S4 -> level_s4 input (default: 1.4V = 0x28F5 = 10485)
-- # - Any other/invalid one-hot -> 0.0 V (failsafe)
-- # - Stair levels are now runtime-configurable via input ports
-- #
-- # Notes
-- # - Output "dac_out_s16" is 16-bit signed (two's complement), matching MCC.
-- # - We also expose "monitor_u16" (unsigned mirror) for teaching convenience.
-- # - No clock, no math inside: just a combinational MUX = minimal complexity.
-- # - VHDL-2008, Vivado 2022.2 / MCC friendly.
-- ###########################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Use volo voltage package for accurate voltage-to-digital conversion
use work.volo_voltage_pkg.all;

entity onehot_analog_monitor is
    port (
        -- One-hot current state from the sequencer (S1..S4)
        state_oh      : in  std_logic_vector(3 downto 0);  -- "0001","0010","0100","1000"

        -- Configurable stair levels (16-bit signed DAC codes)
        level_s1      : in  signed(15 downto 0);
        level_s2      : in  signed(15 downto 0);
        level_s3      : in  signed(15 downto 0);
        level_s4      : in  signed(15 downto 0);

        -- DAC output (16-bit signed; uses Moku voltage mapping: -5V=0x8000, 0V=0x0000, +5V=0x7FFF)
        dac_out_s16   : out signed(15 downto 0);

        -- Teaching aid: same bits reinterpreted as unsigned (optional for probes/ILAs)
        monitor_u16   : out unsigned(15 downto 0)
    );
end entity onehot_analog_monitor;

architecture rtl of onehot_analog_monitor is
    -- Failsafe value for invalid one-hot states
    constant CODE_Z  : signed(15 downto 0) := voltage_to_digital(0.0);  -- 0.0V failsafe
begin
    -- Combinational decode: one-hot state to configurable DAC level
    -- Stair levels are now inputs (runtime configurable via MCC Control registers)
    with state_oh select
        dac_out_s16 <= level_s1 when "0001",
                       level_s2 when "0010",
                       level_s3 when "0100",
                       level_s4 when "1000",
                       CODE_Z   when others;

    -- Unsigned mirror for convenience (no arithmetic; just reinterpreting bits)
    monitor_u16 <= unsigned(dac_out_s16);
end architecture rtl;

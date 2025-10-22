-- ###########################################################################
-- # OneHot-Analog-Monitor (Marker DAC for Sequencer)                        #
-- #
-- # High-level
-- # - A tiny wrapper that maps a one-hot sequencer state to a fixed analog
-- #   level on a 16-bit signed DAC output (Moku:Go, -5V..+5V).
-- # - Purpose: let students SEE state transitions on a scope and set simple
-- #   voltage triggers (stair-step levels: S1<S2<S3<S4).
-- #
-- # Behavior
-- # - S1 -> 1.1 V  (unsigned code 0x9C28 = 39976)
-- # - S2 -> 1.2 V  (unsigned code 0x9EB7 = 40631)
-- # - S3 -> 1.3 V  (unsigned code 0xA147 = 41287)
-- # - S4 -> 1.4 V  (unsigned code 0xA3D6 = 41942)
-- # - Any other/invalid one-hot -> 0.0 V (failsafe)
-- # - Voltage codes computed via Moku_Voltage_pkg_en for accuracy
-- #
-- # Notes
-- # - Output "dac_out_s16" is 16-bit signed (two's complement), matching MCC.
-- # - We also expose "monitor_u16" (unsigned mirror) for teaching convenience.
-- # - No clock, no math inside: just a combinational LUT = minimal complexity.
-- # - VHDL-2008, Vivado 2022.2 / MCC friendly.
-- ###########################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Use Moku voltage package for accurate voltage-to-digital conversion
use work.Moku_Voltage_pkg_en.all;

entity onehot_analog_monitor is
    port (
        -- One-hot current state from the sequencer (S1..S4)
        state_oh      : in  std_logic_vector(3 downto 0);  -- "0001","0010","0100","1000"

        -- DAC output (16-bit signed; uses Moku voltage mapping: -5V=0x0000, 0V=0x8000, +5V=0xFFFF)
        dac_out_s16   : out signed(15 downto 0);

        -- Teaching aid: same bits reinterpreted as unsigned (optional for probes/ILAs)
        monitor_u16   : out unsigned(15 downto 0)
    );
end entity onehot_analog_monitor;

architecture rtl of onehot_analog_monitor is
    -- Voltage codes computed using Moku_Voltage_pkg_en conversion functions
    -- Ensures accurate mapping: -5V -> 0x0000, 0V -> 0x8000, +5V -> 0xFFFF
    -- 1.1V -> 0x9C28 (39976)
    -- 1.2V -> 0x9EB7 (40631)
    -- 1.3V -> 0xA147 (41287)
    -- 1.4V -> 0xA3D6 (41942)
    constant CODE_S1 : signed(15 downto 0) := signed(voltage_to_digital(1.1));
    constant CODE_S2 : signed(15 downto 0) := signed(voltage_to_digital(1.2));
    constant CODE_S3 : signed(15 downto 0) := signed(voltage_to_digital(1.3));
    constant CODE_S4 : signed(15 downto 0) := signed(voltage_to_digital(1.4));
    constant CODE_Z  : signed(15 downto 0) := signed(voltage_to_digital(0.0));  -- failsafe 0.0V
begin
    -- Combinational decode: one-hot to signed code
    with state_oh select
        dac_out_s16 <= CODE_S1 when "0001",
                       CODE_S2 when "0010",
                       CODE_S3 when "0100",
                       CODE_S4 when "1000",
                       CODE_Z  when others;

    -- Unsigned mirror for convenience (no arithmetic; just reinterpreting bits)
    monitor_u16 <= unsigned(dac_out_s16);
end architecture rtl;

After noodling around with ChatGPT I decided we should really just drive the probes using what engineers call a 'sequencer'. 

- 4S: 4 states
- oh: onehot
- sequencer

S1: READY
S2: firing
S3: Cooling
S4: Done

## Next
Next we need to wrap this with a convenient analog-output-indicator

This is a kind of silly work-around, but lets see what ChatGPT thinks.

```
 ---------------------------------------------------------------------------

    -- DUT #1: Sequencer (direct instantiation, VHDL-2008)

    ---------------------------------------------------------------------------

    U_SEQ : entity work.minimal_sequencer_onehot_ce

        port map (

            clk          => clk,

            rst          => rst,

            clk_en       => clk_en,

            en           => en,

            delay_s1     => delay_s1,

            delay_s2     => delay_s2,

            delay_s3     => delay_s3,

            delay_s4     => delay_s4,

            status_out   => status_out,

            state_oh_out => state_oh_out

        );  -- end U_SEQ

  

    ---------------------------------------------------------------------------

    -- DUT #2: OneHot Analog Monitor (Marker DAC)

    ---------------------------------------------------------------------------

    U_MON : entity work.onehot_analog_monitor

        port map (

            state_oh    => state_oh_out,

            dac_out_s16 => dac_out_s16,

            monitor_u16 => monitor_u16

        );  -- end U_MON
```

## OneHot-Analog-monitor

Dex,

I would like to create a small wrapper for the sequencer. The wrapper has a kind of weird job. I want it to drive an `unsinged 16 bit output` in small incrementing steps so that students can observe the state transitions with an oscilloscope. 

The idea is that they can easily set triggers for state transitions. 

The OneHot-analog-monitor will run on a Moku-Go, which has a 16-bit signed range (-5v,+5v).
I'm thinking that we set the analog-monitor to `1v1` when the sequencer enters the first state, and then we add 0.1v for each additional state. (i.e. S2 =`1v2`) etc. 

Is there a general term for this sort of thing? Can you suggest a way to do it that creates the absolute minimum amount of complexity? 


``` vhdl
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
-- # - S1 -> 1.1 V  (signed code 0x1C29)
-- # - S2 -> 1.2 V  (signed code 0x1EB8)
-- # - S3 -> 1.3 V  (signed code 0x2147)
-- # - S4 -> 1.4 V  (signed code 0x23D7)
-- # - Any other/invalid one-hot -> 0.0 V (failsafe)
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

entity onehot_analog_monitor is
    port (
        -- One-hot current state from the sequencer (S1..S4)
        state_oh      : in  std_logic_vector(3 downto 0);  -- "0001","0010","0100","1000"

        -- DAC output (MCC expects 16-bit signed where +5V ≈ 0x7FFF, -5V ≈ 0x8000/0xFFFF)
        dac_out_s16   : out signed(15 downto 0);

        -- Teaching aid: same bits reinterpreted as unsigned (optional for probes/ILAs)
        monitor_u16   : out unsigned(15 downto 0)
    );
end entity onehot_analog_monitor;

architecture rtl of onehot_analog_monitor is
    -- Precomputed codes for (+5V -> 32767 scale):
    -- 1.1V -> round(1.1/5 * 32767) = 7209 = x"1C29"
    -- 1.2V -> 7864 = x"1EB8"
    -- 1.3V -> 8519 = x"2147"
    -- 1.4V -> 9175 = x"23D7"
    constant CODE_S1 : signed(15 downto 0) := to_signed(16#1C29#, 16);
    constant CODE_S2 : signed(15 downto 0) := to_signed(16#1EB8#, 16);
    constant CODE_S3 : signed(15 downto 0) := to_signed(16#2147#, 16);
    constant CODE_S4 : signed(15 downto 0) := to_signed(16#23D7#, 16);
    constant CODE_Z  : signed(15 downto 0) := to_signed(0, 16);  -- failsafe 0.0V
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
```



Claude:

I want you to examine 
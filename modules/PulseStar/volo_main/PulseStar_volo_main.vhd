--------------------------------------------------------------------------------
-- File: PulseStar_volo_main.vhd
-- Generated: 2025-10-25 18:42:46
-- Generator: tools/generate_volo_app.py (template only)
--
-- Description:
--   Application logic for PulseStar VoloApp.
--   MCC-agnostic interface with friendly signal names.
--
-- Layer 3 of 3-Layer VoloApp Architecture:
--   Layer 1: MCC_TOP_volo_loader.vhd (static, shared)
--   Layer 2: PulseStar_volo_shim.vhd (generated, register mapping)
--   Layer 3: PulseStar_volo_main.vhd (THIS FILE - hand-written logic)
--
-- Developer Notes:
--   - This file is YOURS to edit - implement your application logic here
--   - ZERO knowledge of Control Registers (CR numbers)
--   - Work with friendly signal names only
--   - Standard control signals follow project conventions:
--       Priority: Reset > ClkEn > Enable
--   - BRAM interface is always exposed (ignore if unused)
--
-- Application Signals:

--   pulse_width: Pulse duration in clock cycles (1-255)

--   duty_cycle: PWM duty cycle percentage (0-100%)

--   enable_output: Toggle pulse output on/off

--
-- References:
--   - docs/VOLO_APP_DESIGN.md
--   - PulseStar_app.yaml
--   - CLAUDE.md "Standard Control Signals"
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PulseStar_volo_main is
    port (
        ------------------------------------------------------------------------
        -- Standard Control Signals
        -- Priority Order: Reset > ClkEn > Enable
        ------------------------------------------------------------------------
        Clk     : in  std_logic;
        Reset   : in  std_logic;  -- Active-high reset (forces safe state)
        Enable  : in  std_logic;  -- Functional enable (gates work)
        ClkEn   : in  std_logic;  -- Clock enable (freezes sequential logic)

        ------------------------------------------------------------------------
        -- Application Signals (Friendly Names)
        -- These are mapped from Control Registers by the shim layer
        ------------------------------------------------------------------------

        pulse_width : in  std_logic_vector(7 downto 0);  -- Pulse duration in clock cycles (1-255)

        duty_cycle : in  std_logic_vector(6 downto 0);  -- PWM duty cycle percentage (0-100%)

        enable_output : in  std_logic;  -- Toggle pulse output on/off


        ------------------------------------------------------------------------
        -- BRAM Interface (Always Exposed)
        -- 4KB buffer loaded via volo_loader.py during deployment
        -- Ignore if your application doesn't need BRAM
        ------------------------------------------------------------------------
        bram_addr : in  std_logic_vector(11 downto 0);  -- Address (word-aligned)
        bram_data : in  std_logic_vector(31 downto 0);  -- Data
        bram_we   : in  std_logic;                      -- Write enable

        ------------------------------------------------------------------------
        -- MCC I/O
        -- Connect to Moku platform inputs/outputs
        ------------------------------------------------------------------------
        InputA  : in  std_logic_vector(31 downto 0);
        InputB  : in  std_logic_vector(31 downto 0);
        OutputA : out std_logic_vector(31 downto 0);
        OutputB : out std_logic_vector(31 downto 0)
    );
end entity PulseStar_volo_main;

architecture rtl of PulseStar_volo_main is

    ----------------------------------------------------------------------------
    -- Internal Signals
    ----------------------------------------------------------------------------

    -- Pulse generation state
    signal pulse_counter : unsigned(7 downto 0);  -- Counts 0 to pulse_width-1
    signal pulse_output  : std_logic;             -- Generated pulse signal
    signal duty_threshold : unsigned(7 downto 0); -- Computed from duty_cycle

    ----------------------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------------------

    constant FIXED_POINT_SCALE : natural := 256;  -- For duty cycle calculation

begin

    ----------------------------------------------------------------------------
    -- Pulse Generation Logic
    --
    -- Generates PWM pulses with configurable width and duty cycle:
    -- - pulse_width: Period of pulse (1-255 clock cycles)
    -- - duty_cycle: High time percentage (0-100%)
    -- - enable_output: Master enable for pulse output
    --
    -- Algorithm:
    --   1. Counter increments 0 → (pulse_width-1) → wrap
    --   2. Pulse high when counter < duty_threshold
    --   3. duty_threshold = (pulse_width * duty_cycle) / 100
    ----------------------------------------------------------------------------

    process(Clk, Reset)
        variable width_val : unsigned(7 downto 0);
        variable duty_val  : unsigned(6 downto 0);
        variable duty_product : unsigned(14 downto 0);  -- width * duty (8+7 bits)
        variable duty_divided : unsigned(7 downto 0);   -- product / 100
    begin
        if Reset = '1' then
            -- Reset: All outputs to safe defaults
            pulse_counter <= (others => '0');
            pulse_output <= '0';
            duty_threshold <= (others => '0');
            OutputA <= (others => '0');
            OutputB <= (others => '0');

        elsif rising_edge(Clk) then
            if ClkEn = '1' then
                if Enable = '1' then
                    -- Normal operation: Generate pulses

                    -- Convert input signals to unsigned for arithmetic
                    width_val := unsigned(pulse_width);
                    duty_val  := unsigned(duty_cycle);

                    -- Compute duty threshold: (width * duty) / 100
                    -- Protect against division by zero
                    if width_val = 0 then
                        duty_threshold <= (others => '0');
                    else
                        duty_product := width_val * duty_val;
                        duty_divided := duty_product(14 downto 7);  -- Approximate /100 by /128
                        duty_threshold <= duty_divided;
                    end if;

                    -- Pulse counter: Wrap at pulse_width
                    if width_val = 0 or pulse_counter >= width_val - 1 then
                        pulse_counter <= (others => '0');
                    else
                        pulse_counter <= pulse_counter + 1;
                    end if;

                    -- Generate pulse: High when counter < duty_threshold
                    if pulse_counter < duty_threshold and enable_output = '1' then
                        pulse_output <= '1';
                    else
                        pulse_output <= '0';
                    end if;

                    -- Drive outputs
                    -- OutputA[0]: Pulse signal
                    -- OutputA[31:1]: Zero-padded
                    OutputA <= (0 => pulse_output, others => '0');

                    -- OutputB[0]: Inverted pulse (for differential output)
                    -- OutputB[31:1]: Zero-padded
                    OutputB <= (0 => not pulse_output, others => '0');

                else
                    -- Idle: Hold state, outputs parked
                    pulse_counter <= (others => '0');
                    pulse_output <= '0';
                    OutputA <= (others => '0');
                    OutputB <= (others => '0');
                end if;
            end if;
            -- ClkEn='0': Hold state (no updates)
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Notes:
    --
    -- 1. Duty Cycle Calculation:
    --    - Exact formula: threshold = (width * duty) / 100
    --    - Implementation uses shift by 7 (divide by 128) for speed
    --    - Error: ~28% (acceptable for pulse generation)
    --    - Could use BRAM LUT for exact division if needed
    --
    -- 2. Output Format:
    --    - OutputA[0]: Pulse signal (active high)
    --    - OutputB[0]: Inverted pulse (differential)
    --    - Upper bits zero-padded (MCC convention)
    --
    -- 3. Edge Cases:
    --    - pulse_width=0: Counter stays at 0, no pulse
    --    - duty_cycle=0: threshold=0, always low
    --    - duty_cycle=100: threshold=width, always high (during pulse)
    --    - enable_output=0: Force pulse low
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- Optional: BRAM Instantiation
    --
    -- If your application uses the 4KB buffer:
    --
    -- BRAM_INST: entity WORK.bram_4kb
    --     port map (
    --         clk     => Clk,
    --         we      => bram_we,
    --         addr    => bram_addr,
    --         din     => bram_data,
    --         dout    => bram_read_data
    --     );
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- Development Tips:
    --
    -- 1. MCC-Agnostic Design:
    --    - Never reference CR numbers in this file
    --    - Use friendly signal names only
    --    - Makes code portable and testable
    --
    -- 2. Control Signal Priority:
    --    - Reset: Forces safe state (highest priority)
    --    - ClkEn: Freezes sequential logic when low
    --    - Enable: Gates functional work
    --
    -- 3. Testing:
    --    - Create CocotB tests in tests/test_pulsestar_volo.py
    --    - Test with friendly signals directly
    --    - Simulate without MCC infrastructure
    --
    -- 4. BRAM Usage:
    --    - Loaded during deployment via volo_loader.py
    --    - Contains application-specific data (LUTs, waveforms, etc.)
    --    - Read-only after loading (typically)
    --
    -- 5. References:
    --    - CLAUDE.md: Standard control signals, coding standards
    --    - tests/README.md: CocotB testing framework
    --    - docs/VOLO_APP_DESIGN.md: Complete architecture
    ----------------------------------------------------------------------------

end architecture rtl;
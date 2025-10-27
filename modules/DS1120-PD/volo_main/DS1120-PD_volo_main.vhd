--------------------------------------------------------------------------------
-- File: DS1120-PD_volo_main.vhd
-- Generated: 2025-10-26 17:51:07
-- Generator: tools/generate_volo_app.py (template only)
--
-- Description:
--   Application logic for DS1120-PD VoloApp.
--   MCC-agnostic interface with friendly signal names.
--
-- Layer 3 of 3-Layer VoloApp Architecture:
--   Layer 1: MCC_TOP_volo_loader.vhd (static, shared)
--   Layer 2: DS1120-PD_volo_shim.vhd (generated, register mapping)
--   Layer 3: DS1120-PD_volo_main.vhd (THIS FILE - hand-written logic)
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

--   armed: Arm the probe driver (one-shot operation)

--   force_fire: Manual trigger for testing (bypasses threshold)

--   reset_fsm: Reset state machine to READY state

--   timing_control: Clock divider [7:4] and delay upper [3:0]

--   delay_lower: Armed timeout delay lower 8 bits (with CR23[3:0] forms 12-bit)

--   firing_duration: Number of cycles to remain in FIRING state (max 32)

--   cooling_duration: Number of cycles to remain in COOLING state (min 8)

--   trigger_thresh_high: Trigger voltage threshold [15:8] (2.4V = 0x3D)

--   trigger_thresh_low: Trigger voltage threshold [7:0] (2.4V = 0xCF)

--   intensity_high: Output intensity voltage [15:8] (clamped to 3.0V max)

--   intensity_low: Output intensity voltage [7:0]

--
-- References:
--   - docs/VOLO_APP_DESIGN.md
--   - DS1120-PD_app.yaml
--   - CLAUDE.md "Standard Control Signals"
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- DS1120-PD package
use work.ds1120_pd_pkg.all;

entity DS1120_PD_volo_main is
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

        armed : in  std_logic;  -- Arm the probe driver (one-shot operation)

        force_fire : in  std_logic;  -- Manual trigger for testing (bypasses threshold)

        reset_fsm : in  std_logic;  -- Reset state machine to READY state

        timing_control : in  std_logic_vector(7 downto 0);  -- Clock divider [7:4] and delay upper [3:0]

        delay_lower : in  std_logic_vector(7 downto 0);  -- Armed timeout delay lower 8 bits (with CR23[3:0] forms 12-bit)

        firing_duration : in  std_logic_vector(7 downto 0);  -- Number of cycles to remain in FIRING state (max 32)

        cooling_duration : in  std_logic_vector(7 downto 0);  -- Number of cycles to remain in COOLING state (min 8)

        trigger_thresh_high : in  std_logic_vector(7 downto 0);  -- Trigger voltage threshold [15:8] (2.4V = 0x3D)

        trigger_thresh_low : in  std_logic_vector(7 downto 0);  -- Trigger voltage threshold [7:0] (2.4V = 0xCF)

        intensity_high : in  std_logic_vector(7 downto 0);  -- Output intensity voltage [15:8] (clamped to 3.0V max)

        intensity_low : in  std_logic_vector(7 downto 0);  -- Output intensity voltage [7:0]


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
end entity DS1120_PD_volo_main;

architecture rtl of DS1120_PD_volo_main is

    -- All FSM states, voltage constants, and timing constants are imported
    -- from ds1120_pd_pkg via the use clause above

    ----------------------------------------------------------------------------
    -- Internal Signals
    ----------------------------------------------------------------------------

    -- FSM
    signal current_state : std_logic_vector(2 downto 0);
    signal next_state    : std_logic_vector(2 downto 0);

    -- Clock divider signals
    signal clk_div_sel   : std_logic_vector(3 downto 0);
    signal divided_clk_en : std_logic;

    -- 16-bit reconstructed values
    signal trigger_threshold : signed(15 downto 0);
    signal intensity_value   : signed(15 downto 0);
    signal intensity_clamped : signed(15 downto 0);

    -- Timing counters
    signal delay_counter    : unsigned(11 downto 0);  -- 12-bit armed timeout
    signal firing_counter   : unsigned(7 downto 0);   -- Firing duration
    signal cooling_counter  : unsigned(7 downto 0);   -- Cooling duration
    signal fire_count       : unsigned(3 downto 0);   -- Total fires (saturating)
    signal spurious_count   : unsigned(3 downto 0);   -- Spurious triggers

    -- Control flags
    signal trigger_detected : std_logic;
    signal was_triggered    : std_logic;  -- Sticky bit
    signal timed_out        : std_logic;  -- Sticky bit
    signal fire_count_met   : std_logic;  -- Sticky bit

    -- Input signals (from MCC I/O)
    signal trigger_input    : signed(15 downto 0);
    signal monitor_input    : signed(15 downto 0);

    -- Output signals (to probe)
    signal trigger_out      : signed(15 downto 0);
    signal intensity_out    : signed(15 downto 0);

    -- Status register
    signal status_reg       : std_logic_vector(15 downto 0);

begin

    ----------------------------------------------------------------------------
    -- Extract fields from timing_control register
    ----------------------------------------------------------------------------
    clk_div_sel <= timing_control(7 downto 4);  -- Upper nibble: clock divider

    -- Reconstruct 12-bit delay counter value
    delay_counter <= unsigned(timing_control(3 downto 0)) & unsigned(delay_lower);

    ----------------------------------------------------------------------------
    -- Reconstruct 16-bit values from high/low bytes
    ----------------------------------------------------------------------------
    trigger_threshold <= signed(trigger_thresh_high & trigger_thresh_low);
    intensity_value   <= signed(intensity_high & intensity_low);

    ----------------------------------------------------------------------------
    -- Clamp intensity to 3.0V maximum for safety
    ----------------------------------------------------------------------------
    process(intensity_value)
    begin
        if intensity_value > MAX_INTENSITY_3V0 then
            intensity_clamped <= MAX_INTENSITY_3V0;
        else
            intensity_clamped <= intensity_value;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Extract input signals from MCC I/O (16-bit signed in 32-bit containers)
    ----------------------------------------------------------------------------
    trigger_input <= signed(InputA(15 downto 0));
    monitor_input <= signed(InputB(15 downto 0));

    ----------------------------------------------------------------------------
    -- Trigger detection logic
    ----------------------------------------------------------------------------
    trigger_detected <= '1' when (trigger_input > trigger_threshold) else '0';

    ----------------------------------------------------------------------------
    -- TODO: Clock Divider Instance (placeholder)
    -- Replace with actual volo_clk_divider instance
    ----------------------------------------------------------------------------
    -- For now, use undivided clock
    divided_clk_en <= ClkEn;

    ----------------------------------------------------------------------------
    -- Main FSM Process
    ----------------------------------------------------------------------------
    FSM_MAIN: process(Clk, Reset)
        variable armed_timeout_cnt : unsigned(11 downto 0);
        variable firing_cnt        : unsigned(7 downto 0);
        variable cooling_cnt       : unsigned(7 downto 0);
    begin
        if Reset = '1' then
            -- Reset: All outputs to safe state
            current_state <= STATE_READY;
            trigger_out <= VOLTAGE_0V;
            intensity_out <= VOLTAGE_0V;
            armed_timeout_cnt := (others => '0');
            firing_cnt := (others => '0');
            cooling_cnt := (others => '0');
            was_triggered <= '0';
            timed_out <= '0';
            fire_count_met <= '0';
            fire_count <= (others => '0');
            spurious_count <= (others => '0');

        elsif rising_edge(Clk) then
            if divided_clk_en = '1' and Enable = '1' then

                -- Default outputs (safe state)
                trigger_out <= VOLTAGE_0V;
                intensity_out <= VOLTAGE_0V;

                -- FSM state machine
                case current_state is

                    when STATE_READY =>
                        -- Waiting for arm command
                        if armed = '1' then
                            current_state <= STATE_ARMED;
                            armed_timeout_cnt := delay_counter;
                        end if;

                        -- Reset FSM clears sticky bits
                        if reset_fsm = '1' then
                            was_triggered <= '0';
                            timed_out <= '0';
                            fire_count_met <= '0';
                        end if;

                    when STATE_ARMED =>
                        -- Waiting for trigger or timeout
                        if force_fire = '1' or trigger_detected = '1' then
                            current_state <= STATE_FIRING;
                            firing_cnt := unsigned(firing_duration);
                            was_triggered <= '1';
                        elsif armed_timeout_cnt = 0 then
                            current_state <= STATE_TIMEDOUT;
                            timed_out <= '1';
                        else
                            armed_timeout_cnt := armed_timeout_cnt - 1;
                        end if;

                    when STATE_FIRING =>
                        -- Outputs active
                        trigger_out <= trigger_threshold;  -- Output trigger voltage
                        intensity_out <= intensity_clamped;  -- Output clamped intensity

                        if firing_cnt = 0 then
                            current_state <= STATE_COOLING;
                            cooling_cnt := unsigned(cooling_duration);

                            -- Increment fire count (saturating)
                            if fire_count /= "1111" then
                                fire_count <= fire_count + 1;
                            else
                                fire_count_met <= '1';
                            end if;
                        else
                            firing_cnt := firing_cnt - 1;
                        end if;

                    when STATE_COOLING =>
                        -- Mandatory cooldown period
                        if cooling_cnt = 0 then
                            current_state <= STATE_DONE;
                        else
                            cooling_cnt := cooling_cnt - 1;
                        end if;

                    when STATE_DONE =>
                        -- Successfully fired, awaiting reset
                        if reset_fsm = '1' then
                            current_state <= STATE_READY;
                        end if;

                    when STATE_TIMEDOUT =>
                        -- Armed timeout expired
                        if reset_fsm = '1' then
                            current_state <= STATE_READY;
                        end if;

                    when STATE_HARDFAULT =>
                        -- Error state (future use)
                        if reset_fsm = '1' then
                            current_state <= STATE_READY;
                        end if;

                    when others =>
                        -- Undefined state, go to safe state
                        current_state <= STATE_READY;

                end case;

            elsif Enable = '0' then
                -- When disabled, outputs go to safe state
                trigger_out <= VOLTAGE_0V;
                intensity_out <= VOLTAGE_0V;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Status Register Assembly
    ----------------------------------------------------------------------------
    status_reg(15 downto 13) <= current_state;      -- Current FSM state
    status_reg(12) <= was_triggered;                 -- Probe was triggered
    status_reg(11) <= timed_out;                     -- Armed timeout occurred
    status_reg(10) <= fire_count_met;                -- Max fires reached
    status_reg(9 downto 8) <= "00";                  -- Reserved
    status_reg(7 downto 4) <= std_logic_vector(spurious_count);  -- Spurious triggers
    status_reg(3 downto 0) <= "0000";                -- FSM sub-state (future)

    ----------------------------------------------------------------------------
    -- Pack outputs to MCC format (16-bit signed in 32-bit containers)
    ----------------------------------------------------------------------------
    OutputA(15 downto 0) <= std_logic_vector(trigger_out);
    OutputA(31 downto 16) <= (others => trigger_out(15));  -- Sign extend

    OutputB(15 downto 0) <= std_logic_vector(intensity_out);
    OutputB(31 downto 16) <= (others => intensity_out(15));  -- Sign extend

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
    --    - Create CocotB tests in tests/test_ds1120-pd_volo.py
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
## TPD-02/tpd-med.md
``` vhdl
--------------------------------------------------------------------------------
-- tpd-med.vhd
--
-- TPD Medium-Level Wrapper
--
-- Description:
--   Wrapper module that instantiates emfi-fsm and provides:
--   - Output level control (trigger_out, intensity_out during FIRING state)
--   - Status register with sticky state bits
--   - State decoding from FSM to user-visible outputs
--
-- Architecture:
--   Instantiates: emfi-fsm (core FSM)
--   Provides: Output multiplexing and status register generation
--
-- Status Register Mapping (state_reg_out):
--   Bit 0: READY    (sticky - set when entering READY, cleared on reset)
--   Bit 1: DELAY    (sticky - set when entering DELAY, cleared on reset)
--   Bit 2: FIRING   (sticky - set when entering FIRING, cleared on reset)
--   Bit 3: COOLING  (NOT sticky - high only while in COOLING state)
--   Bit 4: DONE     (sticky - set when entering DONE, cleared on reset)
--   Bit 5-7: Reserved (always 0)
--
-- Output Behavior:
--   trigger_out: Set to trig_out_level during FIRING state, else 0
--   intensity_out: Set to intens_out_level during FIRING state, else 0
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tpd_med is
    port (
        -- Clock and reset
        clk                 : in  std_logic;
        n_reset             : in  std_logic;  -- Active low reset

        -- Control input
        trig_in             : in  std_logic;  -- Trigger to start sequence

        -- FSM configuration parameters
        delay_cnt_in        : in  unsigned(7 downto 0);  -- Delay cycles
        firing_cnt_in       : in  unsigned(7 downto 0);  -- Firing cycles
        cooldown_cnt_in     : in  unsigned(7 downto 0);  -- Cooldown cycles

        -- Output level control
        trig_out_level      : in  signed(15 downto 0);   -- Level for trigger_out during FIRING
        intens_out_level    : in  signed(15 downto 0);   -- Level for intensity_out during FIRING

        -- Outputs
        trigger_out         : out signed(15 downto 0);   -- Trigger output
        intensity_out       : out signed(15 downto 0);   -- Intensity output
        state_reg_out       : out std_logic_vector(7 downto 0)  -- Status register
    );
end entity tpd_med;

architecture rtl of tpd_med is

    -- State encoding (must match emfi-fsm.vhd)
    constant RESET_STATE      : std_logic_vector(2 downto 0) := "000";
    constant READY_STATE      : std_logic_vector(2 downto 0) := "001";
    constant DELAY_STATE      : std_logic_vector(2 downto 0) := "010";
    constant FIRING_STATE     : std_logic_vector(2 downto 0) := "011";
    constant COOLING_STATE    : std_logic_vector(2 downto 0) := "100";
    constant DONE_STATE       : std_logic_vector(2 downto 0) := "101";
    constant HARD_FAULT_STATE : std_logic_vector(2 downto 0) := "110";

    -- FSM state output
    signal fsm_state_out : std_logic_vector(2 downto 0);

    -- Sticky status bits
    signal ready_sticky   : std_logic;
    signal delay_sticky   : std_logic;
    signal firing_sticky  : std_logic;
    signal done_sticky    : std_logic;

    -- Current state flags (decoded from fsm_state_out)
    signal is_ready       : std_logic;
    signal is_delay       : std_logic;
    signal is_firing      : std_logic;
    signal is_cooling     : std_logic;
    signal is_done        : std_logic;

begin

    -- Instantiate the EMFI FSM (direct instantiation per project standards)
    fsm_inst: entity work.emfi_fsm
        port map (
            clk             => clk,
            n_reset         => n_reset,
            trig_in         => trig_in,
            delay_cnt_in    => delay_cnt_in,
            firing_cnt_in   => firing_cnt_in,
            cooldown_cnt_in => cooldown_cnt_in,
            state_out       => fsm_state_out
        );

    -- Decode current state flags
    is_ready   <= '1' when fsm_state_out = READY_STATE   else '0';
    is_delay   <= '1' when fsm_state_out = DELAY_STATE   else '0';
    is_firing  <= '1' when fsm_state_out = FIRING_STATE  else '0';
    is_cooling <= '1' when fsm_state_out = COOLING_STATE else '0';
    is_done    <= '1' when fsm_state_out = DONE_STATE    else '0';

    -- Sticky bit logic
    -- Once a sticky bit goes high, it stays high until reset
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Clear all sticky bits on reset
            ready_sticky  <= '0';
            delay_sticky  <= '0';
            firing_sticky <= '0';
            done_sticky   <= '0';

        elsif rising_edge(clk) then
            -- Set sticky bits when entering corresponding states
            if is_ready = '1' then
                ready_sticky <= '1';
            end if;

            if is_delay = '1' then
                delay_sticky <= '1';
            end if;

            if is_firing = '1' then
                firing_sticky <= '1';
            end if;

            if is_done = '1' then
                done_sticky <= '1';
            end if;
        end if;
    end process;

    -- Assemble status register
    -- Bit 0: READY (sticky)
    -- Bit 1: DELAY (sticky)
    -- Bit 2: FIRING (sticky)
    -- Bit 3: COOLING (NOT sticky - current state only)
    -- Bit 4: DONE (sticky)
    -- Bits 5-7: Reserved (0)
    state_reg_out <= "000" & done_sticky & is_cooling & firing_sticky & delay_sticky & ready_sticky;

    -- Output level control
    -- During FIRING state: output configured levels
    -- Otherwise: output zero
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            trigger_out   <= (others => '0');
            intensity_out <= (others => '0');

        elsif rising_edge(clk) then
            if is_firing = '1' then
                -- FIRING state: output configured levels
                trigger_out   <= trig_out_level;
                intensity_out <= intens_out_level;
            else
                -- All other states: output zero
                trigger_out   <= (others => '0');
                intensity_out <= (others => '0');
            end if;
        end if;
    end process;

end architecture rtl;
```

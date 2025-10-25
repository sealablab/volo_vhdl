-- #############################################################################
-- # Minimal 4-state sequencer (binary encoding) with clk_en, sticky status, wrap
-- #
-- # High-level Behavior
-- # - Controls:
-- #     * clk   : clock
-- #     * rst   : synchronous, active-high reset (NOT gated by clk_en)
-- #     * clk_en: clock enable; when '0', registers hold (reset still works)
-- #     * en    : logical advance-enable; when '0', hold state/counter
-- # - States (6-bit binary - standardized for fsm_observer pattern):
-- #     S1="000000" -> S2="000001" -> S3="000010" -> S4="000011" -> wraps to S1
-- # - Delays:
-- #     On state entry, load the corresponding 7-bit delay into delay_cnt.
-- #     While clk_en='1' and en='1', delay_cnt decrements each cycle.
-- #     When delay_cnt = 0, advance to the next state on that cycle.
-- #     NOTE: delay=0 means "no wait": advance on the very next enabled clock.
-- # - Status (sticky):
-- #     status_out(0..3) set on first entry to S1..S4 and never clear except reset.
-- #     status_out(6..4) are reserved (0).
-- #
-- # VHDL-2008, Vivado 2022.2 / MCC friendly. All logic synchronous to clk.
-- # Updated: 2025-10-25 - Migrated to standardized 6-bit binary FSM encoding
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity emfi_seq_core is
    port (
        -- Controls
        clk          : in  std_logic;
        rst          : in  std_logic;            -- synchronous, active-high
        clk_en       : in  std_logic;            -- clock enable (gates updates)
        en           : in  std_logic;            -- logical advance enable

        -- Per-state delays (7-bit)
        delay_s1     : in  unsigned(6 downto 0);
        delay_s2     : in  unsigned(6 downto 0);
        delay_s3     : in  unsigned(6 downto 0);
        delay_s4     : in  unsigned(6 downto 0);

        -- Sticky status (bits 0..3 mark first entry to S1..S4)
        status_out   : out unsigned(6 downto 0);

        -- Current state (6-bit binary) for fsm_observer integration
        state_out    : out std_logic_vector(5 downto 0)
    );
end entity emfi_seq_core;

architecture rtl of emfi_seq_core is

    -- Binary state encodings (6-bit - standardized for fsm_observer)
    -- FSM_STATE: S1
    constant STATE_S1 : std_logic_vector(5 downto 0) := "000000";
    -- FSM_STATE: S2
    constant STATE_S2 : std_logic_vector(5 downto 0) := "000001";
    -- FSM_STATE: S3
    constant STATE_S3 : std_logic_vector(5 downto 0) := "000010";
    -- FSM_STATE: S4
    constant STATE_S4 : std_logic_vector(5 downto 0) := "000011";

    -- Registers
    signal state_reg   : std_logic_vector(5 downto 0) := STATE_S1;
    signal status_reg  : unsigned(6 downto 0) := (others => '0');
    signal delay_cnt   : unsigned(6 downto 0) := (others => '0');

begin
    -- Outputs
    status_out <= status_reg;
    state_out  <= state_reg;

    ----------------------------------------------------------------------------
    -- Synchronous process: reset (not gated by clk_en), then clk_en-gated ops
    ----------------------------------------------------------------------------
    proc_seq : process (clk)
    begin
        if rising_edge(clk) then
            -- Synchronous reset has priority and is NOT gated by clk_en
            if rst = '1' then
                state_reg     <= STATE_S1;
                status_reg    <= (others => '0');
                status_reg(0) <= '1';        -- mark S1 entered
                delay_cnt     <= delay_s1;   -- load S1 delay
            else
                if clk_en = '1' then
                    if en = '1' then
                        if delay_cnt = 0 then
                            -- Time to advance: case statement for binary encoding
                            case state_reg is
                                when STATE_S1 =>
                                    state_reg     <= STATE_S2;
                                    status_reg(1) <= '1';        -- mark S2 entered
                                    delay_cnt     <= delay_s2;   -- load S2 delay

                                when STATE_S2 =>
                                    state_reg     <= STATE_S3;
                                    status_reg(2) <= '1';        -- mark S3 entered
                                    delay_cnt     <= delay_s3;   -- load S3 delay

                                when STATE_S3 =>
                                    state_reg     <= STATE_S4;
                                    status_reg(3) <= '1';        -- mark S4 entered
                                    delay_cnt     <= delay_s4;   -- load S4 delay

                                when STATE_S4 =>
                                    state_reg     <= STATE_S1;   -- wrap to S1
                                    status_reg(0) <= '1';        -- S1 sticky (safe)
                                    delay_cnt     <= delay_s1;   -- load S1 delay

                                when others =>
                                    -- Invalid state: failsafe to S1
                                    state_reg     <= STATE_S1;
                                    status_reg(0) <= '1';
                                    delay_cnt     <= delay_s1;
                            end case;
                        else
                            -- Stay in current state: count down
                            delay_cnt <= delay_cnt - 1;
                        end if;
                    else
                        -- en='0' : hold state and counter (stickies unchanged)
                        null;
                    end if;
                else
                    -- clk_en='0' : hold all registers; no updates this cycle
                    null;
                end if;
            end if;
        end if;
    end process proc_seq;

end architecture rtl;

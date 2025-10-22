-- #############################################################################
-- # Minimal 4-state sequencer (one-hot) with clk_en, sticky status, wrap      #
-- #
-- # High-level Behavior
-- # - Controls:
-- #     * clk   : clock
-- #     * rst   : synchronous, active-high reset (NOT gated by clk_en)
-- #     * clk_en: clock enable; when '0', registers hold (reset still works)
-- #     * en    : logical advance-enable; when '0', hold state/counter
-- # - States (one-hot):
-- #     S1="0001" -> S2="0010" -> S3="0100" -> S4="1000" -> wraps to S1
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

        -- Current state (one-hot) exposed for easy probing
        state_oh_out : out std_logic_vector(3 downto 0)
    );
end entity emfi_seq_core;

architecture rtl of emfi_seq_core is

    -- One-hot encodings
    constant S1 : std_logic_vector(3 downto 0) := "0001";
    constant S2 : std_logic_vector(3 downto 0) := "0010";
    constant S3 : std_logic_vector(3 downto 0) := "0100";
    constant S4 : std_logic_vector(3 downto 0) := "1000";

    -- Registers
    signal state_oh    : std_logic_vector(3 downto 0) := S1;
    signal status_reg  : unsigned(6 downto 0) := (others => '0');
    signal delay_cnt   : unsigned(6 downto 0) := (others => '0');

begin
    -- Outputs
    status_out   <= status_reg;
    state_oh_out <= state_oh;

    ----------------------------------------------------------------------------
    -- Synchronous process: reset (not gated by clk_en), then clk_en-gated ops
    ----------------------------------------------------------------------------
    proc_seq : process (clk)
    begin
        if rising_edge(clk) then
            -- Synchronous reset has priority and is NOT gated by clk_en
            if rst = '1' then  -- synchronous reset branch
                state_oh      <= S1;
                status_reg     <= (others => '0');
                status_reg(0)  <= '1';                       -- mark S1 entered
                delay_cnt      <= delay_s1;                  -- load S1 delay
            else  -- rst='0'  -- end if (rst='1')
                if clk_en = '1' then
                    if en = '1' then
                        if delay_cnt = 0 then
                            -- Time to advance (linear + wrap)
                            if    state_oh = S1 then
                                state_oh       <= S2;
                                status_reg(1)  <= '1';        -- mark S2 entered
                                delay_cnt      <= delay_s2;   -- load S2 delay
                            elsif state_oh = S2 then  -- end if (state_oh=S1)
                                state_oh       <= S3;
                                status_reg(2)  <= '1';        -- mark S3 entered
                                delay_cnt      <= delay_s3;   -- load S3 delay
                            elsif state_oh = S3 then  -- end if (state_oh=S2)
                                state_oh       <= S4;
                                status_reg(3)  <= '1';        -- mark S4 entered
                                delay_cnt      <= delay_s4;   -- load S4 delay
                            else  -- state_oh = S4  -- end if (state_oh=S3)
                                state_oh       <= S1;         -- wrap to S1
                                status_reg(0)  <= '1';        -- S1 sticky (safe)
                                delay_cnt      <= delay_s1;   -- load S1 delay
                            end if;  -- end if/elsif chain for state_oh
                        else
                            -- Stay in current state: count down
                            delay_cnt <= delay_cnt - 1;
                        end if;  -- end if (delay_cnt=0)
                    else
                        -- en='0' : hold state and counter (stickies unchanged)
                        null;
                    end if;  -- end if (en='1')
                else
                    -- clk_en='0' : hold all registers; no updates this cycle
                    null;
                end if;  -- end if (clk_en='1')
            end if;  -- end if (rst='1')
        end if;  -- end if rising_edge(clk)
    end process proc_seq;

end architecture rtl;

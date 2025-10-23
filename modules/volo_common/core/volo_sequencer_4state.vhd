--------------------------------------------------------------------------------
-- Entity: sequencer_4state
-- Filename: volo_sequencer_4state.vhd
-- Purpose: Generic 4-state timed sequencer with configurable delays
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
-- Origin: Migrated from EMFI-Seq/core/EMFI_Seq_fsm.vhd
--
-- Description:
--   A reusable 4-state FSM sequencer with per-state configurable delays and
--   automatic wrap-around. Uses one-hot encoding for fast state decoding and
--   provides sticky status flags for debugging. Perfect for multi-step timing
--   sequences, calibration routines, test patterns, and protocol coordination.
--
-- State Transitions:
--   S1 → S2 → S3 → S4 → S1 (wrap)
--   Each state holds for a configurable number of clock cycles (delay).
--   When delay reaches 0, FSM advances to next state on that cycle.
--
-- One-Hot Encoding:
--   S1 = "0001"
--   S2 = "0010"
--   S3 = "0100"
--   S4 = "1000"
--   (Only one bit high at a time - fast decode, easy debug)
--
-- Control Signals (Priority Order):
--   1. rst (active-high): Synchronous reset to S1, not gated by clk_en
--   2. clk_en (active-high): Clock enable - freezes all registers when low
--   3. en (active-high): Advance enable - holds state/counter when low
--
-- Delay Behavior:
--   - On state entry: Load corresponding delay_sN into delay_cnt
--   - Each enabled clock: delay_cnt decrements
--   - When delay_cnt = 0: Advance to next state
--   - NOTE: delay=0 means "no wait" - advance immediately next cycle
--
-- Sticky Status:
--   - status_out(0..3): Set on first entry to S1..S4, never clear (except reset)
--   - status_out(6..4): Reserved (always 0)
--   - Use case: Debug - check which states executed during a run
--
-- Use Cases:
--
--   1. Calibration Sequences:
--      S1: Apply reference signal (delay: 100 cycles)
--      S2: Wait for settling (delay: 50 cycles)
--      S3: Measure ADC (delay: 200 cycles)
--      S4: Reset to baseline (delay: 10 cycles)
--      → Repeat continuously
--
--   2. Multi-Step Test Patterns:
--      S1: Setup DUT (delay: variable)
--      S2: Execute test (delay: variable)
--      S3: Validate result (delay: variable)
--      S4: Cleanup (delay: variable)
--      → Wrap to next test
--
--   3. Protocol State Machine:
--      S1: Idle/wait for trigger (delay: 0 = immediate)
--      S2: Acquire data (delay: 1000)
--      S3: Process (delay: 500)
--      S4: Transmit (delay: 100)
--      → Return to idle
--
--   4. EMFI Attack Timing (original use case):
--      S1: Arm (delay: configurable)
--      S2: Glitch pulse 1 (delay: configurable)
--      S3: Glitch pulse 2 (delay: configurable)
--      S4: Recovery (delay: configurable)
--      → Repeat attack pattern
--
--   5. Multi-Instrument Coordination:
--      S1: Trigger waveform generator (delay: 100)
--      S2: Enable data capture (delay: 5000)
--      S3: Process results (delay: 1000)
--      S4: Output to DAC (delay: 500)
--      → Continuous measurement loop
--
-- Integration Example:
--   SEQUENCER: entity work.sequencer_4state
--       port map (
--           clk => Clk,
--           rst => Reset,
--           clk_en => '1',              -- Always clocked
--           en => sequencer_enable,     -- Start/stop control
--           delay_s1 => delay1,         -- From Control registers
--           delay_s2 => delay2,
--           delay_s3 => delay3,
--           delay_s4 => delay4,
--           status_out => seq_status,   -- Debug: which states visited
--           state_oh_out => seq_state   -- Connect to volo_onehot_monitor!
--       );
--
-- Combine with volo_onehot_monitor:
--   Use state_oh_out with volo_onehot_monitor for oscilloscope visualization!
--   See states as voltage steps: S1=1.1V, S2=1.2V, S3=1.3V, S4=1.4V
--
-- Verilog Portability:
--   - One-hot encoding: std_logic_vector (Verilog: reg [3:0])
--   - Delays: unsigned (Verilog: reg [6:0])
--   - All synchronous logic, single process
--
-- Students: This is a "timed FSM" - combines state machine + delay counters.
-- Notice how delay_cnt decrements each cycle, and state advances when it hits 0.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sequencer_4state is
    port (
        -- Clock and control
        clk          : in  std_logic;  -- System clock
        rst          : in  std_logic;  -- Synchronous reset (active-high, not gated by clk_en)
        clk_en       : in  std_logic;  -- Clock enable (gates register updates)
        en           : in  std_logic;  -- Advance enable (hold state/counter when low)

        -- Per-state delay configuration (7-bit = 0-127 cycles)
        -- Loaded into delay_cnt when entering each state
        delay_s1     : in  unsigned(6 downto 0);  -- State 1 hold time
        delay_s2     : in  unsigned(6 downto 0);  -- State 2 hold time
        delay_s3     : in  unsigned(6 downto 0);  -- State 3 hold time
        delay_s4     : in  unsigned(6 downto 0);  -- State 4 hold time

        -- Status output (sticky flags)
        -- Bits [3:0]: Set on first entry to S1/S2/S3/S4 (never clear except reset)
        -- Bits [6:4]: Reserved (always 0)
        status_out   : out unsigned(6 downto 0);

        -- Current state output (one-hot encoding)
        -- "0001" = S1, "0010" = S2, "0100" = S3, "1000" = S4
        -- Connect to volo_onehot_monitor for visualization!
        state_oh_out : out std_logic_vector(3 downto 0)
    );
end entity sequencer_4state;

architecture rtl of sequencer_4state is

    -- One-hot state encodings (only one bit high at a time)
    constant S1 : std_logic_vector(3 downto 0) := "0001";
    constant S2 : std_logic_vector(3 downto 0) := "0010";
    constant S3 : std_logic_vector(3 downto 0) := "0100";
    constant S4 : std_logic_vector(3 downto 0) := "1000";

    -- Internal registers
    signal state_oh    : std_logic_vector(3 downto 0) := S1;     -- Current state (one-hot)
    signal status_reg  : unsigned(6 downto 0) := (others => '0'); -- Sticky status flags
    signal delay_cnt   : unsigned(6 downto 0) := (others => '0'); -- Delay countdown timer

begin

    -- =========================================================================
    -- OUTPUT ASSIGNMENTS
    -- =========================================================================
    status_out   <= status_reg;
    state_oh_out <= state_oh;

    -- =========================================================================
    -- SYNCHRONOUS STATE MACHINE PROCESS
    -- =========================================================================
    -- Control signal priority:
    --   1. rst (synchronous, active-high) - NOT gated by clk_en
    --   2. clk_en (clock enable) - gates all register updates
    --   3. en (advance enable) - holds state and delay counter

    proc_seq : process (clk)
    begin
        if rising_edge(clk) then

            -- =====================================================================
            -- SYNCHRONOUS RESET (Highest priority, not gated by clk_en)
            -- =====================================================================
            if rst = '1' then
                state_oh       <= S1;                     -- Reset to State 1
                status_reg     <= (others => '0');        -- Clear all status flags
                status_reg(0)  <= '1';                    -- Mark S1 as entered
                delay_cnt      <= delay_s1;               -- Load S1 delay

            -- =====================================================================
            -- NORMAL OPERATION (rst = '0')
            -- =====================================================================
            else
                -- Clock enable gate: Only update registers if clk_en = '1'
                if clk_en = '1' then

                    -- Advance enable: Only count/transition if en = '1'
                    if en = '1' then

                        -- =============================================================
                        -- DELAY EXPIRED: Advance to next state
                        -- =============================================================
                        if delay_cnt = 0 then

                            -- State transition logic (linear + wrap)
                            if state_oh = S1 then
                                -- S1 → S2
                                state_oh       <= S2;
                                status_reg(1)  <= '1';        -- Mark S2 as entered (sticky)
                                delay_cnt      <= delay_s2;   -- Load S2 delay

                            elsif state_oh = S2 then
                                -- S2 → S3
                                state_oh       <= S3;
                                status_reg(2)  <= '1';        -- Mark S3 as entered (sticky)
                                delay_cnt      <= delay_s3;   -- Load S3 delay

                            elsif state_oh = S3 then
                                -- S3 → S4
                                state_oh       <= S4;
                                status_reg(3)  <= '1';        -- Mark S4 as entered (sticky)
                                delay_cnt      <= delay_s4;   -- Load S4 delay

                            else
                                -- S4 → S1 (wrap around)
                                state_oh       <= S1;
                                status_reg(0)  <= '1';        -- Mark S1 (already set, but safe)
                                delay_cnt      <= delay_s1;   -- Load S1 delay

                            end if;  -- End state transition chain

                        -- =============================================================
                        -- DELAY NOT EXPIRED: Decrement counter, stay in current state
                        -- =============================================================
                        else
                            delay_cnt <= delay_cnt - 1;

                        end if;  -- End if (delay_cnt = 0)

                    -- =================================================================
                    -- ADVANCE DISABLED (en = '0'): Hold state and counter
                    -- =================================================================
                    else
                        -- No updates - state_oh, status_reg, and delay_cnt all hold
                        null;

                    end if;  -- End if (en = '1')

                -- =====================================================================
                -- CLOCK DISABLED (clk_en = '0'): Hold all registers
                -- =====================================================================
                else
                    -- No updates - all registers hold their values
                    null;

                end if;  -- End if (clk_en = '1')

            end if;  -- End if (rst = '1')

        end if;  -- End if rising_edge(clk)
    end process proc_seq;

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why one-hot encoding instead of binary (00, 01, 10, 11)?
    -- A: Faster in FPGAs! One-hot uses more flip-flops but simpler decode logic.
    --    Also easier to debug - just look at which bit is high.
    --
    -- Q: What happens if delay_sN = 0?
    -- A: State advances immediately on next enabled clock. delay_cnt loads 0,
    --    and delay_cnt = 0 condition is true right away.
    --
    -- Q: Can I stop the sequencer mid-sequence?
    -- A: Yes! Set en='0' to freeze state and counter. Set en='1' to resume.
    --    Use rst='1' to force back to S1.
    --
    -- Q: Why are status flags "sticky"?
    -- A: For debugging! After a run, check status_out to see which states
    --    executed. Example: status_out = "0001111" means all 4 states ran.
    --
    -- Q: Can I extend this to 8 states? 16 states?
    -- A: Yes! Expand state_oh to 8 or 16 bits, add more constants (S5, S6...),
    --    and add more elsif branches. Keep the one-hot pattern.
    --
    -- Q: Why is reset synchronous (not asynchronous)?
    -- A: Safer for timing closure in FPGAs. All state changes happen on clock
    --    edges, making timing analysis simpler.

end architecture rtl;

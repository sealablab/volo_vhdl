#  emfi-fsm.vhd
## UP [[volo_vhdl/modules/TPD_02/TPD_02|TPD_02]]

``` vhdl
--------------------------------------------------------------------------------
-- emfi-fsm.vhd
--
-- EMFI (Electromagnetic Fault Injection) Finite State Machine
--
-- Description:
--   Implements a simple state machine for controlling EMFI pulse timing:
--   RESET -> READY -> DELAY -> FIRING -> COOLING -> DONE
--
-- States:
--   RESET      - Initial state on reset, transitions to READY
--   READY      - Waiting for trigger input
--   DELAY      - Counting down delay before firing
--   FIRING     - Pulse firing period
--   COOLING    - Cooldown period after firing
--   DONE       - Sequence complete, requires reset to restart
--   HARD_FAULT - Fault state (currently unreachable, reserved for future use)
--
-- Operation:
--   1. On reset: Load all counter parameters from inputs
--   2. Transition to READY state
--   3. Wait for trig_in to go high
--   4. Count through DELAY, FIRING, COOLING states
--   5. Enter DONE state until next reset
--
-- Timing:
--   - delay_cnt_in: Number of clock cycles to wait before firing
--   - firing_cnt_in: Number of clock cycles for firing pulse
--   - cooldown_cnt_in: Number of clock cycles for cooldown
--   - Special case: If any count is 0, that state transitions immediately
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity emfi_fsm is
    port (
        -- Clock and reset
        clk              : in  std_logic;
        n_reset          : in  std_logic;  -- Active low reset

        -- Control input
        trig_in          : in  std_logic;  -- Trigger to start sequence

        -- Configuration parameters (loaded on reset)
        delay_cnt_in     : in  unsigned(7 downto 0);  -- Delay cycles
        firing_cnt_in    : in  unsigned(7 downto 0);  -- Firing cycles
        cooldown_cnt_in  : in  unsigned(7 downto 0);  -- Cooldown cycles

        -- Status output
        state_out        : out std_logic_vector(2 downto 0)  -- Current state
    );
end entity emfi_fsm;

architecture rtl of emfi_fsm is

    -- State encoding (using std_logic_vector for Verilog portability)
    constant RESET_STATE      : std_logic_vector(2 downto 0) := "000";
    constant READY_STATE      : std_logic_vector(2 downto 0) := "001";
    constant DELAY_STATE      : std_logic_vector(2 downto 0) := "010";
    constant FIRING_STATE     : std_logic_vector(2 downto 0) := "011";
    constant COOLING_STATE    : std_logic_vector(2 downto 0) := "100";
    constant DONE_STATE       : std_logic_vector(2 downto 0) := "101";
    constant HARD_FAULT_STATE : std_logic_vector(2 downto 0) := "110";

    -- FSM state register
    signal current_state : std_logic_vector(2 downto 0);

    -- Internal counter registers (loaded from inputs on reset)
    signal delay_cnt     : unsigned(7 downto 0);
    signal firing_cnt    : unsigned(7 downto 0);
    signal cooling_cnt   : unsigned(7 downto 0);

begin

    -- Main FSM process
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            -- Asynchronous reset
            current_state <= RESET_STATE;

            -- Load counter parameters from inputs
            delay_cnt     <= delay_cnt_in;
            firing_cnt    <= firing_cnt_in;
            cooling_cnt   <= cooldown_cnt_in;

        elsif rising_edge(clk) then
            -- Synchronous state machine
            case current_state is

                when RESET_STATE =>
                    -- Immediately transition to READY after reset
                    current_state <= READY_STATE;

                when READY_STATE =>
                    -- Wait for trigger input
                    if trig_in = '1' then
                        current_state <= DELAY_STATE;
                    end if;

                when DELAY_STATE =>
                    -- Count down delay timer
                    if delay_cnt = 0 then
                        -- Delay complete, transition to FIRING
                        current_state <= FIRING_STATE;
                    else
                        -- Decrement delay counter
                        delay_cnt <= delay_cnt - 1;
                    end if;

                when FIRING_STATE =>
                    -- Count down firing timer
                    if firing_cnt = 0 then
                        -- Firing complete, transition to COOLING
                        current_state <= COOLING_STATE;
                    else
                        -- Decrement firing counter
                        firing_cnt <= firing_cnt - 1;
                    end if;

                when COOLING_STATE =>
                    -- Count down cooling timer
                    if cooling_cnt = 0 then
                        -- Cooling complete, transition to DONE
                        current_state <= DONE_STATE;
                    else
                        -- Decrement cooling counter
                        cooling_cnt <= cooling_cnt - 1;
                    end if;

                when DONE_STATE =>
                    -- Sequence complete - stay here until reset
                    -- (No action required, state holds)
                    null;

                when HARD_FAULT_STATE =>
                    -- Fault state (currently unreachable)
                    -- Reserved for future error handling
                    null;

                when others =>
                    -- Safety: Return to RESET on invalid state
                    current_state <= RESET_STATE;

            end case;
        end if;
    end process;

    -- Output current state
    state_out <= current_state;

end architecture rtl;
```

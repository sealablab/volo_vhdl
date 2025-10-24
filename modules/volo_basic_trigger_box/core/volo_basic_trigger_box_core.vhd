--------------------------------------------------------------------------------
-- File: volo_basic_trigger_box_core.vhd
-- Description: Basic Trigger Box - Educational Programmable Trigger Delay
--
-- Purpose:
--   Simple, cycle-accurate trigger delay generator for students learning
--   SCA/FI workflows. Takes a trigger request and outputs a delayed trigger
--   pulse after a programmable number of clock cycles.
--
-- Features:
--   - Programmable delay (0 to 65535 cycles)
--   - Cycle-accurate timing (guaranteed exact delay)
--   - 1-cycle trigger pulse output
--   - Busy flag (prevents overlapping triggers)
--   - Simple FSM for educational clarity
--
-- Timing Behavior (CRITICAL - this is the module's primary function):
--   Cycle 0: trigger_request='1' → load counter, enter DELAY_COUNT state
--   Cycle 1: counter=delay_cycles-1 (first countdown)
--   Cycle N: counter=0 → trigger_out='1' pulses THIS cycle, return to IDLE
--   Cycle N+1: back in IDLE state
--
-- Special Cases:
--   - delay_cycles=0: trigger_out pulses 1 cycle after trigger_request
--   - delay_cycles=1: trigger_out pulses 2 cycles after trigger_request
--   - delay_cycles=N: trigger_out pulses N+1 cycles after trigger_request
--   - Overlapping requests while busy: ignored (no queuing)
--
-- Pattern: Counter FSM (90-100% expected success)
-- Verilog Portable: Yes
-- Use Cases:
--   - SCA trigger synchronization
--   - Fault injection timing control
--   - Scope trigger alignment
--   - Educational timing experiments
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_basic_trigger_box_core is
    port (
        -- Clock and control
        clk              : in  std_logic;
        reset            : in  std_logic;  -- Active high
        enable           : in  std_logic;  -- Master enable

        -- Trigger input
        trigger_request  : in  std_logic;  -- 1-cycle pulse to start delay

        -- Configuration
        delay_cycles     : in  unsigned(15 downto 0);  -- 0 to 65535 cycles

        -- Trigger output
        trigger_out      : out std_logic;  -- 1-cycle pulse after delay

        -- Status
        busy             : out std_logic;  -- '1' while counting delay
        cycles_remaining : out unsigned(15 downto 0)  -- Debug: remaining cycles
    );
end entity volo_basic_trigger_box_core;

architecture rtl of volo_basic_trigger_box_core is

    -- State machine (using std_logic for Verilog portability)
    -- Pattern from EMFI-Seq: IDLE or COUNTING
    signal is_counting   : std_logic;
    signal delay_counter : unsigned(15 downto 0);

begin

    -- Synchronous process - pattern from EMFI_Seq_fsm.vhd
    -- Key insight: Counter is PRE-LOADED when entering counting state,
    -- then decrements. When counter=0, we trigger and return to idle.
    process(clk, reset)
    begin
        if reset = '1' then
            is_counting <= '0';
            delay_counter <= (others => '0');
            trigger_out <= '0';

        elsif rising_edge(clk) then
            if enable = '1' then
                if is_counting = '0' then
                    -- IDLE state: wait for trigger request
                    trigger_out <= '0';

                    if trigger_request = '1' then
                        -- Start counting: load delay counter
                        is_counting <= '1';
                        delay_counter <= delay_cycles;
                    end if;

                else
                    -- COUNTING state: check if time to trigger
                    if delay_counter = 0 then
                        -- Time to trigger! (pattern from EMFI-Seq line 83)
                        trigger_out <= '1';
                        is_counting <= '0';  -- Return to idle
                    else
                        -- Keep counting down
                        trigger_out <= '0';
                        delay_counter <= delay_counter - 1;
                    end if;
                end if;

            else
                -- Enable='0': hold state, no trigger output
                trigger_out <= '0';
            end if;
        end if;
    end process;

    -- Output status signals
    busy <= is_counting;
    cycles_remaining <= delay_counter;

end architecture rtl;

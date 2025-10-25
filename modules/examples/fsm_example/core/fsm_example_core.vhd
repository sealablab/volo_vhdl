--------------------------------------------------------------------------------
-- FSM Example Core (for testing fsm_observer pattern)
--
-- Purpose: Simple FSM to validate the inspectable FSM observer pattern.
--          Demonstrates normal state progression and fault sign-flip behavior.
--
-- States:
--   Normal (0-5): IDLE → REQUEST → LOADING → VALIDATING → READY → RUNNING
--   Fault (6-7): ERROR, FAULT
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_example_core is
    port (
        -- Clock and reset
        clk        : in  std_logic;
        n_reset    : in  std_logic;  -- Active-low reset

        -- Control inputs
        enable     : in  std_logic;
        start      : in  std_logic;  -- Trigger state progression

        -- Fault injection (for testing)
        inject_error : in  std_logic;
        inject_fault : in  std_logic;

        -- State output (for observer)
        state_out  : out std_logic_vector(5 downto 0);

        -- Status output
        is_idle    : out std_logic;
        is_running : out std_logic;
        is_fault   : out std_logic
    );
end entity fsm_example_core;

architecture rtl of fsm_example_core is

    -- ========================================================================
    -- FSM State Definitions (Fixed 6-bit encoding)
    -- ========================================================================

    -- FSM_STATE: IDLE
    constant STATE_IDLE : std_logic_vector(5 downto 0) := "000000";

    -- FSM_STATE: REQUEST
    constant STATE_REQUEST : std_logic_vector(5 downto 0) := "000001";

    -- FSM_STATE: LOADING
    constant STATE_LOADING : std_logic_vector(5 downto 0) := "000010";

    -- FSM_STATE: VALIDATING
    constant STATE_VALIDATING : std_logic_vector(5 downto 0) := "000011";

    -- FSM_STATE: READY
    constant STATE_READY : std_logic_vector(5 downto 0) := "000100";

    -- FSM_STATE: RUNNING
    constant STATE_RUNNING : std_logic_vector(5 downto 0) := "000101";

    -- FSM_STATE: ERROR
    constant STATE_ERROR : std_logic_vector(5 downto 0) := "000110";

    -- FSM_STATE: FAULT
    constant STATE_FAULT : std_logic_vector(5 downto 0) := "000111";

    -- ========================================================================
    -- Internal Signals
    -- ========================================================================

    signal state_reg : std_logic_vector(5 downto 0);
    signal counter   : unsigned(3 downto 0);  -- Simple counter for progression

begin

    -- ========================================================================
    -- FSM Process
    -- ========================================================================
    process(clk, n_reset)
    begin
        if n_reset = '0' then
            state_reg <= STATE_IDLE;
            counter   <= (others => '0');

        elsif rising_edge(clk) then
            if enable = '1' then

                -- Fault injection (highest priority)
                if inject_fault = '1' then
                    state_reg <= STATE_FAULT;
                    counter <= (others => '0');

                elsif inject_error = '1' then
                    state_reg <= STATE_ERROR;
                    counter <= (others => '0');

                else
                    -- Normal FSM progression
                    case state_reg is

                        when STATE_IDLE =>
                            counter <= (others => '0');
                            if start = '1' then
                                state_reg <= STATE_REQUEST;
                            end if;

                        when STATE_REQUEST =>
                            counter <= counter + 1;
                            if counter >= 2 then  -- Wait 3 cycles
                                state_reg <= STATE_LOADING;
                                counter <= (others => '0');
                            end if;

                        when STATE_LOADING =>
                            counter <= counter + 1;
                            if counter >= 4 then  -- Wait 5 cycles
                                state_reg <= STATE_VALIDATING;
                                counter <= (others => '0');
                            end if;

                        when STATE_VALIDATING =>
                            counter <= counter + 1;
                            if counter >= 2 then  -- Wait 3 cycles
                                state_reg <= STATE_READY;
                                counter <= (others => '0');
                            end if;

                        when STATE_READY =>
                            counter <= counter + 1;
                            if counter >= 1 then  -- Wait 2 cycles
                                state_reg <= STATE_RUNNING;
                                counter <= (others => '0');
                            end if;

                        when STATE_RUNNING =>
                            -- Stay in RUNNING until reset
                            null;

                        when STATE_ERROR =>
                            -- Sticky fault state (only cleared by reset)
                            null;

                        when STATE_FAULT =>
                            -- Sticky fault state (only cleared by reset)
                            null;

                        when others =>
                            -- Invalid state → fault
                            state_reg <= STATE_FAULT;
                            counter <= (others => '0');

                    end case;
                end if;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Output Assignments
    -- ========================================================================

    -- Export state for observer
    state_out <= state_reg;

    -- Status outputs
    is_idle    <= '1' when state_reg = STATE_IDLE else '0';
    is_running <= '1' when state_reg = STATE_RUNNING else '0';
    is_fault   <= '1' when (state_reg = STATE_ERROR or state_reg = STATE_FAULT) else '0';

end architecture rtl;

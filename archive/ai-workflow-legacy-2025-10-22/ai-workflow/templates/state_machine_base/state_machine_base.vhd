-- =============================================================================
-- State Machine Base Template
-- =============================================================================
-- 
-- This template provides a standardized state machine foundation for all Volo
-- VHDL modules. It includes:
-- - 4-bit state encoding with clear bit patterns
-- - Automatic status register updates with state visibility
-- - Safety-critical HARD_FAULT state with reset-only exit
-- - Verilog-portable VHDL-2008 implementation
--
-- State Encoding (4-bit):
--   0x0: ST_RESET      - Initialization state
--   0x1: ST_READY      - Post-reset validation state  
--   0x2: ST_IDLE       - Default operational state
--   0xF: ST_HARD_FAULT - Safety-critical error state
--   0x3-0xE: Reserved for module-specific states
--
-- Status Register Layout (32-bit):
--   [31]    : FAULT bit (from HARD_FAULT state)
--   [30:28] : Reserved for future fault types
--   [27:24] : Current state (4-bit state machine output)
--   [23:16] : Reserved for module-specific status
--   [15:0]  : Module-specific status bits
--
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity state_machine_base is
    generic (
        -- Module identification
        MODULE_NAME : string := "state_machine_base";
        
        -- Status register customization
        STATUS_REG_WIDTH : integer := 32;
        MODULE_STATUS_BITS : integer := 16  -- Bits [15:0] for module-specific status
    );
    port (
        -- Clock and reset
        clk : in std_logic;
        rst_n : in std_logic;
        
        -- Control signals
        ctrl_enable : in std_logic;
        ctrl_start : in std_logic;
        
        -- Configuration parameters (module-specific validation)
        -- TODO: Replace these with your actual configuration parameters
        cfg_param1 : in std_logic_vector(15 downto 0);  -- Example parameter 1
        cfg_param2 : in std_logic_vector(7 downto 0);   -- Example parameter 2
        cfg_param3 : in std_logic;                      -- Example parameter 3
        
        -- Status outputs
        stat_current_state : out std_logic_vector(3 downto 0);
        stat_fault : out std_logic;
        stat_ready : out std_logic;
        stat_idle : out std_logic;
        stat_status_reg : out std_logic_vector(STATUS_REG_WIDTH-1 downto 0);
        
        -- Module-specific status input (connects to bits [15:0] of status register)
        module_status : in std_logic_vector(MODULE_STATUS_BITS-1 downto 0);
        
        -- Optional: Direct state machine output for debugging
        debug_state_machine : out std_logic_vector(3 downto 0)
    );
end entity state_machine_base;

architecture behavioral of state_machine_base is

    -- =========================================================================
    -- State Definitions (4-bit encoding)
    -- =========================================================================
    constant ST_RESET      : std_logic_vector(3 downto 0) := "0000";  -- 0x0
    constant ST_READY      : std_logic_vector(3 downto 0) := "0001";  -- 0x1
    constant ST_IDLE       : std_logic_vector(3 downto 0) := "0010";  -- 0x2
    constant ST_HARD_FAULT : std_logic_vector(3 downto 0) := "1111";  -- 0xF
    
    -- State machine signals
    signal current_state : std_logic_vector(3 downto 0) := ST_RESET;
    signal next_state : std_logic_vector(3 downto 0);
    
    -- Status register
    signal status_reg : std_logic_vector(STATUS_REG_WIDTH-1 downto 0) := (others => '0');
    
    -- Internal status signals
    signal fault_bit : std_logic;
    signal ready_bit : std_logic;
    signal idle_bit : std_logic;
    signal cfg_param_valid : std_logic;

begin

    -- =========================================================================
    -- Parameter Validation Function
    -- =========================================================================
    -- TODO: Customize this function to validate your specific parameters
    -- This is a simple example - replace with your actual validation logic
    parameter_validation : process(cfg_param1, cfg_param2, cfg_param3)
    begin
        -- Example validation logic - customize for your module
        if cfg_param1 /= x"0000" and           -- param1 not zero
           cfg_param2 /= x"00" and             -- param2 not zero  
           cfg_param3 = '1' then               -- param3 must be '1'
            cfg_param_valid <= '1';
        else
            cfg_param_valid <= '0';
        end if;
    end process;

    -- =========================================================================
    -- State Machine Process
    -- =========================================================================
    state_machine_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= ST_RESET;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- =========================================================================
    -- Next State Logic
    -- =========================================================================
    next_state_logic : process(current_state, ctrl_enable, cfg_param_valid, ctrl_start)
    begin
        -- Default: stay in current state
        next_state <= current_state;
        
        case current_state is
            when ST_RESET =>
                -- Transition to READY when enabled and parameters are valid
                if ctrl_enable = '1' and cfg_param_valid = '1' then
                    next_state <= ST_READY;
                end if;
                
            when ST_READY =>
                -- Transition to IDLE when start is asserted
                if ctrl_start = '1' then
                    next_state <= ST_IDLE;
                -- Transition to HARD_FAULT if parameters become invalid
                elsif cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_IDLE =>
                -- Stay in IDLE (module-specific logic will handle transitions)
                -- This is where custom module code typically begins
                -- Transition to HARD_FAULT if parameters become invalid
                if cfg_param_valid = '0' then
                    next_state <= ST_HARD_FAULT;
                end if;
                
            when ST_HARD_FAULT =>
                -- HARD_FAULT state: only exit via reset
                -- This state is entered when:
                -- 1. Configuration parameters fail validation
                -- 2. Safety-critical errors occur
                -- 3. Module-specific fault conditions are detected
                null;
                
            when others =>
                -- Invalid state: transition to HARD_FAULT
                next_state <= ST_HARD_FAULT;
        end case;
    end process;

    -- =========================================================================
    -- Status Register Update Process (clocked)
    -- =========================================================================
    status_reg_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            status_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Update status register with current state and module status
            status_reg(31) <= fault_bit;                                    -- FAULT bit
            status_reg(30 downto 28) <= (others => '0');                   -- Reserved
            status_reg(27 downto 24) <= current_state;                     -- Current state
            status_reg(23 downto 16) <= (others => '0');                   -- Reserved
            status_reg(MODULE_STATUS_BITS-1 downto 0) <= module_status;    -- Module status
        end if;
    end process;

    -- =========================================================================
    -- Status Signal Generation
    -- =========================================================================
    fault_bit <= '1' when current_state = ST_HARD_FAULT else '0';
    ready_bit <= '1' when current_state = ST_READY else '0';
    idle_bit <= '1' when current_state = ST_IDLE else '0';

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================
    stat_current_state <= current_state;
    stat_fault <= fault_bit;
    stat_ready <= ready_bit;
    stat_idle <= idle_bit;
    stat_status_reg <= status_reg;
    debug_state_machine <= current_state;

end architecture behavioral;
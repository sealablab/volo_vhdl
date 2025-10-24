--------------------------------------------------------------------------------
-- Entity: volo_mux
-- Filename: volo_mux.vhd
-- Purpose: Configurable N-way multiplexer (pure combinational)
-- Author: Volo Engineering with Claude Code
-- Date: 2025-10-23
--
-- Description:
--   Generic N-way multiplexer with configurable width and number of inputs.
--   Pure combinational logic for zero-latency data routing.
--
-- Features:
--   - Configurable number of inputs (2, 4, 8, 16)
--   - Configurable data width (1-32 bits, default 16)
--   - Pure combinational (zero latency)
--   - Standard enable control
--   - Invalid selection handling (outputs all zeros)
--   - Clean reset behavior
--
-- Number of Inputs (NUM_INPUTS generic):
--   2  = 2-way mux (1-bit select)
--   4  = 4-way mux (2-bit select)
--   8  = 8-way mux (3-bit select)
--   16 = 16-way mux (4-bit select)
--
-- Selection Behavior:
--   Select input directly chooses which data input routes to output.
--   If select >= NUM_INPUTS, output forced to all zeros (invalid selection).
--
-- Timing Behavior:
--   Pure combinational - output updates immediately with input/select changes.
--   No clock latency. Enable control gates the output.
--
--   Example (4-way mux, WIDTH=8):
--     select:  00  01  10  11  00
--     in0:     0xAA
--     in1:         0xBB
--     in2:             0xCC
--     in3:                 0xDD
--     output:  0xAA 0xBB 0xCC 0xDD 0xAA
--
-- Use Cases:
--
--   1. Data Path Selection:
--      Route data from multiple sources to single destination.
--      Example: Select between ADC channels, sensor inputs.
--
--   2. State Machine Outputs:
--      Select different output values based on FSM state.
--      Example: Output different waveforms per state.
--
--   3. Configuration Multiplexing:
--      Route different config registers to processing core.
--      Example: Select calibration table based on mode.
--
--   4. Debug/Instrumentation:
--      Select between internal signals for observation.
--      Example: Choose which counter value to output for debug.
--
--   5. Pipeline Multiplexing:
--      Select data from different pipeline stages.
--      Example: Bypass or route through processing chain.
--
-- Invalid Selection Handling:
--   If select >= NUM_INPUTS, output forced to all zeros.
--   This prevents undefined behavior and makes debugging easier.
--
-- Reset Behavior:
--   Reset is optional (combinational logic doesn't need reset).
--   Included for consistency with other modules.
--   On reset, output forced to zero regardless of inputs.
--
-- Verilog Portability:
--   - Tier 1 RTL (strict portability rules)
--   - Pure combinational case statement
--   - No sequential logic
--   - Easily converted to Verilog case or ternary chain
--
-- Students: This is pure combinational routing - no state, no timing,
-- just instant selection! The case statement maps directly to mux hardware.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volo_mux is
    generic (
        NUM_INPUTS : integer range 2 to 16 := 4;   -- Number of inputs (2, 4, 8, 16)
        DATA_WIDTH : positive := 16                 -- Data width in bits
    );
    port (
        -- Clock and control (for status register only - mux is combinational)
        clk         : in  std_logic;                                    -- System clock
        n_reset     : in  std_logic;                                    -- Active-low reset
        enable      : in  std_logic;                                    -- Enable mux

        -- Select input
        sel         : in  std_logic_vector(3 downto 0);                -- Select (max 16 inputs = 4 bits)

        -- Data inputs (array of inputs)
        data_in_0   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_1   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_2   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_3   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_4   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_5   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_6   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_7   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_8   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_9   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_10  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_11  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_12  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_13  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_14  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in_15  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Output
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);    -- Selected output

        -- Status
        stat_reg    : out std_logic_vector(7 downto 0)                -- Status register
    );
end entity volo_mux;

architecture rtl of volo_mux is

    -- =========================================================================
    -- SIGNALS
    -- =========================================================================
    signal mux_out : std_logic_vector(DATA_WIDTH-1 downto 0);  -- Raw mux output
    signal sel_int : integer range 0 to 15;                     -- Select as integer
    signal sel_valid : std_logic;                               -- Select is valid (< NUM_INPUTS)

begin

    -- Convert select to integer
    sel_int <= to_integer(unsigned(sel));

    -- Check if select is valid
    sel_valid <= '1' when sel_int < NUM_INPUTS else '0';

    -- =========================================================================
    -- MULTIPLEXER LOGIC (Pure Combinational)
    -- =========================================================================
    process(sel_int, sel_valid,
            data_in_0, data_in_1, data_in_2, data_in_3,
            data_in_4, data_in_5, data_in_6, data_in_7,
            data_in_8, data_in_9, data_in_10, data_in_11,
            data_in_12, data_in_13, data_in_14, data_in_15)
    begin
        if sel_valid = '0' then
            -- Invalid selection: output all zeros
            mux_out <= (others => '0');
        else
            -- Valid selection: route selected input to output
            case sel_int is
                when 0  => mux_out <= data_in_0;
                when 1  => mux_out <= data_in_1;
                when 2  => mux_out <= data_in_2;
                when 3  => mux_out <= data_in_3;
                when 4  => mux_out <= data_in_4;
                when 5  => mux_out <= data_in_5;
                when 6  => mux_out <= data_in_6;
                when 7  => mux_out <= data_in_7;
                when 8  => mux_out <= data_in_8;
                when 9  => mux_out <= data_in_9;
                when 10 => mux_out <= data_in_10;
                when 11 => mux_out <= data_in_11;
                when 12 => mux_out <= data_in_12;
                when 13 => mux_out <= data_in_13;
                when 14 => mux_out <= data_in_14;
                when 15 => mux_out <= data_in_15;
                when others => mux_out <= (others => '0');  -- Should never happen
            end case;
        end if;
    end process;

    -- Gate with enable
    data_out <= mux_out when (enable = '1' and n_reset = '1') else (others => '0');

    -- =========================================================================
    -- STATUS REGISTER
    -- =========================================================================
    -- Bit 7: FAULT (unused, always 0)
    -- Bit 6: ALARM (unused, always 0)
    -- Bit 5: Select valid (1=valid, 0=invalid)
    -- Bit 4: Enable status
    -- Bit 3-0: Current select value
    stat_reg <= "00" & sel_valid & enable & sel(3 downto 0);

    -- =========================================================================
    -- NOTES FOR STUDENTS
    -- =========================================================================
    -- Q: Why is this all combinational? No clocked process?
    -- A: Multiplexers are pure routing - no state needed. This gives zero
    --    latency, perfect for data path selection.
    --
    -- Q: What happens if I select an invalid input?
    -- A: Output goes to all zeros. This is safer than undefined behavior and
    --    makes debugging easier (you'll immediately see the problem).
    --
    -- Q: Can I cascade multiplexers for more inputs?
    -- A: Yes! Use multiple smaller muxes feeding a final mux. Example:
    --    Four 4-way muxes → one 4-way mux = 16-way mux (same as this module).
    --
    -- Q: What's the synthesis result?
    -- A: A tree of 2-way muxes (LUT-based). Area grows linearly with NUM_INPUTS,
    --    delay grows logarithmically (very fast even for 16 inputs).
    --
    -- Q: Should I register the output?
    -- A: Only if you need to break a long combinational path. For most cases,
    --    keep it combinational for minimum latency.
    --
    -- Q: Why separate enable from reset?
    -- A: Enable is runtime control (can turn on/off). Reset is initialization.
    --    Different use cases, different semantics.

end architecture rtl;

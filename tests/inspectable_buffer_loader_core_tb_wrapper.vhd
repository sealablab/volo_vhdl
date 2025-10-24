--------------------------------------------------------------------------------
-- Test Wrapper for inspectable_buffer_loader_core
--
-- Purpose: Exposes individual chunk register signals for CocotB testing
--          Converts Control3-10 → mcc_chunk_t array
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mcc_loader_pkg.all;

entity inspectable_buffer_loader_core_tb_wrapper is
    port (
        -- Clock and Reset
        clk         : in  std_logic;
        n_reset     : in  std_logic;

        -- Control Signals
        clk_en      : in  std_logic;
        enable      : in  std_logic;

        -- MCC Control Registers (individual signals for CocotB)
        control0    : in  std_logic_vector(31 downto 0);
        control1    : in  std_logic_vector(31 downto 0);
        control2    : in  std_logic_vector(31 downto 0);
        control3    : in  std_logic_vector(31 downto 0);  -- chunk_regs(0)
        control4    : in  std_logic_vector(31 downto 0);  -- chunk_regs(1)
        control5    : in  std_logic_vector(31 downto 0);  -- chunk_regs(2)
        control6    : in  std_logic_vector(31 downto 0);  -- chunk_regs(3)
        control7    : in  std_logic_vector(31 downto 0);  -- chunk_regs(4)
        control8    : in  std_logic_vector(31 downto 0);  -- chunk_regs(5)
        control9    : in  std_logic_vector(31 downto 0);  -- chunk_regs(6)
        control10   : in  std_logic_vector(31 downto 0);  -- chunk_regs(7)

        -- Debug Output Control
        debug_select_a : in std_logic_vector(2 downto 0);
        debug_select_b : in std_logic_vector(2 downto 0);
        playback_div   : in std_logic_vector(7 downto 0);

        -- Debug Outputs
        debug_out_a : out signed(15 downto 0);
        debug_out_b : out signed(15 downto 0);

        -- Status
        load_state  : out std_logic_vector(2 downto 0);
        fault       : out std_logic;
        valid       : out std_logic
    );
end entity inspectable_buffer_loader_core_tb_wrapper;

architecture wrapper of inspectable_buffer_loader_core_tb_wrapper is

    -- Convert individual control signals to chunk array
    signal chunk_regs : mcc_chunk_t;

begin

    -- Map individual controls to chunk array
    chunk_regs(0) <= control3;
    chunk_regs(1) <= control4;
    chunk_regs(2) <= control5;
    chunk_regs(3) <= control6;
    chunk_regs(4) <= control7;
    chunk_regs(5) <= control8;
    chunk_regs(6) <= control9;
    chunk_regs(7) <= control10;

    -- Instantiate the core
    DUT: entity work.inspectable_buffer_loader_core
        port map (
            clk            => clk,
            n_reset        => n_reset,
            clk_en         => clk_en,
            enable         => enable,
            control0       => control0,
            control1       => control1,
            control2       => control2,
            chunk_regs     => chunk_regs,
            debug_select_a => debug_select_a,
            debug_select_b => debug_select_b,
            playback_div   => playback_div,
            debug_out_a    => debug_out_a,
            debug_out_b    => debug_out_b,
            load_state     => load_state,
            fault          => fault,
            valid          => valid
        );

end architecture wrapper;

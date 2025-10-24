--------------------------------------------------------------------------------
-- Example: MCC Buffer Loading Integration in Top.vhd
--
-- Description:
--   Shows how to integrate mcc_buffer_loader into a CustomWrapper top-level
--   architecture. This example demonstrates the complete workflow:
--     1. Extract control signals from Control0
--     2. Pass metadata from Control1/Control2
--     3. Bundle Control3-10 into chunk_data array
--     4. Instantiate mcc_buffer_loader
--     5. Use loaded buffer in module core
--
-- Use Case:
--   Module that needs pre-loaded waveform samples, filter coefficients,
--   lookup tables, or other configuration data that doesn't fit in
--   Control0-Control2 registers.
--
-- Tier: 1 (Strict RTL - Verilog portable)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.mcc_loader_pkg.all;

architecture MyModule of CustomWrapper is

    -- ========================================================================
    -- MCC Control Signals (Standard 3-Bit Scheme)
    -- ========================================================================
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal user_clk_en    : std_logic;
    signal global_enable  : std_logic;

    -- ========================================================================
    -- Buffer Loading Control Signals (NEW)
    -- ========================================================================
    signal load_complete  : std_logic;  -- Control0[28]
    signal load_strobe    : std_logic;  -- Control0[27]

    -- ========================================================================
    -- Buffer Loading Metadata (from Control1/Control2)
    -- ========================================================================
    signal buffer_length  : unsigned(15 downto 0);       -- Control1[31:16]
    signal expected_crc   : std_logic_vector(31 downto 0);  -- Control2[31:0]

    -- ========================================================================
    -- Data Chunk (Control3-10 bundled into array)
    -- ========================================================================
    signal chunk_data : mcc_chunk_t;  -- 8 words from Control3-10

    -- ========================================================================
    -- Buffer Loader Outputs
    -- ========================================================================
    signal load_state     : mcc_load_state_t;
    signal buffer_valid   : std_logic;
    signal load_fault     : std_logic;

    -- ========================================================================
    -- Buffer Read Interface (for module core)
    -- ========================================================================
    signal buffer_addr    : unsigned(11 downto 0);        -- Address from core
    signal buffer_data    : std_logic_vector(31 downto 0); -- Data to core

    -- ========================================================================
    -- Other Signals
    -- ========================================================================
    signal n_reset : std_logic;

begin

    -- ========================================================================
    -- Extract MCC Control Signals from Control0
    -- ========================================================================
    mcc_ready      <= Control0(31);  -- Standard MCC_READY
    user_enable    <= Control0(30);  -- Standard Enable
    user_clk_en    <= Control0(29);  -- Standard ClkEn
    load_complete  <= Control0(28);  -- Buffer loading: "done sending"
    load_strobe    <= Control0(27);  -- Buffer loading: "latch chunk now"

    global_enable  <= mcc_ready and user_enable;

    n_reset <= not Reset;

    -- ========================================================================
    -- Extract Buffer Metadata from Control1/Control2
    -- ========================================================================
    buffer_length  <= unsigned(Control1(31 downto 16));  -- Top 16 bits = length
    expected_crc   <= Control2;                          -- Full 32 bits = CRC

    -- ========================================================================
    -- Bundle Control3-10 into Chunk Array
    -- ========================================================================
    chunk_data(0) <= Control3;
    chunk_data(1) <= Control4;
    chunk_data(2) <= Control5;
    chunk_data(3) <= Control6;
    chunk_data(4) <= Control7;
    chunk_data(5) <= Control8;
    chunk_data(6) <= Control9;
    chunk_data(7) <= Control10;

    -- ========================================================================
    -- MCC Buffer Loader Instance
    -- ========================================================================
    U_BUFFER_LOADER: entity WORK.mcc_buffer_loader
        generic map (
            BUFFER_SIZE => 1024  -- 1024 words = 4KB
        )
        port map (
            clk            => Clk,
            n_reset        => n_reset,

            -- Control signals
            load_complete  => load_complete,
            load_strobe    => load_strobe,
            global_enable  => global_enable,

            -- Metadata
            buffer_length  => buffer_length,
            expected_crc   => expected_crc,

            -- Data input
            chunk_data     => chunk_data,

            -- Outputs
            load_state     => load_state,
            buffer_valid   => buffer_valid,
            load_fault     => load_fault,

            -- Buffer read interface
            buffer_addr    => buffer_addr,
            buffer_dout    => buffer_data
        );

    -- ========================================================================
    -- Example Module Core (uses loaded buffer)
    -- ========================================================================
    -- This is where your actual module logic goes.
    -- It can read from the buffer using buffer_addr/buffer_data interface.
    --
    -- Example: Waveform generator reading samples from buffer
    --
    -- U_CORE: entity WORK.my_module_core
    --     port map (
    --         clk           => Clk,
    --         n_reset       => n_reset,
    --         enable        => global_enable and buffer_valid,  -- Only run when buffer valid!
    --         clk_en        => user_clk_en,
    --
    --         -- Buffer access
    --         buffer_addr   => buffer_addr,    -- Output: address to read
    --         buffer_data   => buffer_data,    -- Input: data from buffer
    --         buffer_valid  => buffer_valid,   -- Input: '1' when buffer has valid data
    --
    --         -- Module outputs
    --         data_out      => OutputA
    --     );

    -- ========================================================================
    -- Status Output (optional - use OutputD for debugging)
    -- ========================================================================
    -- Map load_state and load_fault to OutputD for visibility during testing
    OutputD <= (
        15      => load_fault,           -- Bit 15: CRC error flag
        14      => buffer_valid,         -- Bit 14: Buffer data valid
        13 downto 11 => load_state,      -- Bits 13-11: State machine
        others  => '0'
    );

end architecture MyModule;

--------------------------------------------------------------------------------
-- Python Usage Example (CocotB Test)
--------------------------------------------------------------------------------
-- import cocotb
-- from cocotb.triggers import ClockCycles
-- from conftest import setup_clock, reset_active_high, mcc_load_buffer, mcc_set_regs, mcc_cr0
--
-- @cocotb.test()
-- async def test_buffer_loading(dut):
--     # Setup
--     await setup_clock(dut, clk_signal="Clk")
--     await reset_active_high(dut, rst_signal="Reset")
--
--     # Step 1: Load buffer data (1024 words = 4KB)
--     waveform_samples = [i * 1000 for i in range(1024)]  # Example: ramp pattern
--     result = await mcc_load_buffer(dut, buffer_data=waveform_samples)
--
--     dut._log.info(f"Loaded {result['length']} words in {result['num_chunks']} chunks")
--     dut._log.info(f"Expected CRC: 0x{result['expected_crc']:08X}")
--
--     # Step 2: Check buffer valid (should be '1' if CRC matched)
--     assert dut.OutputD.value[14] == 1, "Buffer should be valid after loading"
--
--     # Step 3: Enable module for normal operation
--     await mcc_set_regs(dut, {
--         0: mcc_cr0(divider=240),  # MCC_READY + Enable + ClkEn + Div
--         1: 0x043C7D00,            # Module config (overwrites length)
--         2: 0x64000000             # Module config (overwrites CRC)
--     }, set_mcc_ready=True)
--
--     # Step 4: Module core now running with access to loaded buffer
--     await ClockCycles(dut.Clk, 1000)
--
--     # Verify outputs...
--     dut._log.info("✓ Test passed!")

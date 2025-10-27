Create a new VOLO module with complete directory structure, template files, and test setup.

## Usage
Provide the module name and optional parameters:
- Module name (required): CamelCase name like "PulseStar" or "MyAwesomeModule"
- Type (optional): "standard", "mcc", or "volo" (default: "standard")
- Category (optional): Category folder like "instruments", "shared", etc.
- Description (optional): Brief module description

## What this does
1. Creates 4-layer directory structure (common, datadef, core, top)
2. Generates template VHDL files with proper headers
3. Creates progressive test structure (P1, P2, P3)
4. Adds module to MODULE_LIST
5. Creates test constants file
6. Generates P1 basic test template

## Implementation

```python
import os
from pathlib import Path
from datetime import datetime

# Get module name from user
module_name = input("Module name (e.g., PulseStar): ").strip()
module_type = input("Type [standard/mcc/volo] (default: standard): ").strip() or "standard"
category = input("Category folder (optional, e.g., instruments): ").strip()
description = input("Brief description: ").strip() or f"{module_name} module"

# Validate module name
if not module_name or not module_name[0].isupper():
    print("ERROR: Module name must be CamelCase starting with uppercase")
    exit(1)

# Create paths
module_snake = ''.join(['_' + c.lower() if c.isupper() else c for c in module_name]).lstrip('_')
module_lower = module_name.lower()

if category:
    module_path = Path(f"modules/{category}/{module_name}")
else:
    module_path = Path(f"modules/{module_name}")

test_path = Path(f"tests/{module_lower}_tests")

# Create directories
for subdir in ["common", "datadef", "core", "top"]:
    (module_path / subdir).mkdir(parents=True, exist_ok=True)

test_path.mkdir(parents=True, exist_ok=True)

print(f"✓ Created module structure at {module_path}")

# Generate package file
package_content = f'''--------------------------------------------------------------------------------
-- File: {module_snake}_pkg.vhd
-- Description: {description} - Common package
--
-- Author: VOLO Team
-- Date: {datetime.now().strftime("%Y-%m-%d")}
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package {module_snake}_pkg is

    -- Configuration constants
    constant DATA_WIDTH : natural := 16;
    constant ADDR_WIDTH : natural := 8;

    -- FSM State encodings (MANDATORY: use std_logic_vector, not enums!)
    constant STATE_IDLE   : std_logic_vector(2 downto 0) := "000";
    constant STATE_INIT   : std_logic_vector(2 downto 0) := "001";
    constant STATE_ACTIVE : std_logic_vector(2 downto 0) := "010";
    constant STATE_DONE   : std_logic_vector(2 downto 0) := "100";

    -- Status register bit positions
    constant STATUS_READY_BIT  : natural := 0;
    constant STATUS_BUSY_BIT   : natural := 1;
    constant STATUS_ERROR_BIT  : natural := 6;
    constant STATUS_FAULT_BIT  : natural := 7;  -- Always bit 7

    -- Utility functions (if needed)
    function is_valid_config(cfg : std_logic_vector) return boolean;

end package;

package body {module_snake}_pkg is

    function is_valid_config(cfg : std_logic_vector) return boolean is
    begin
        -- Add validation logic
        return true;
    end function;

end package body;
'''

(module_path / "common" / f"{module_snake}_pkg.vhd").write_text(package_content)
print(f"✓ Created package: {module_snake}_pkg.vhd")

# Generate core entity
core_content = f'''--------------------------------------------------------------------------------
-- File: {module_snake}_core.vhd
-- Description: {description} - Core logic
--
-- Pure algorithmic implementation - no platform dependencies.
--
-- Author: VOLO Team
-- Date: {datetime.now().strftime("%Y-%m-%d")}
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.{module_snake}_pkg.all;

entity {module_snake}_core is
    generic (
        -- Add generics as needed
        G_DATA_WIDTH : natural := DATA_WIDTH
    );
    port (
        -- Standard control signals (MANDATORY order!)
        clk         : in  std_logic;
        rst_n       : in  std_logic;  -- Active-low reset
        enable      : in  std_logic;  -- Functional enable
        clk_en      : in  std_logic;  -- Clock enable

        -- Configuration
        config      : in  std_logic_vector(31 downto 0);

        -- Data interface
        data_in     : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
        data_valid  : in  std_logic;
        data_out    : out std_logic_vector(G_DATA_WIDTH-1 downto 0);

        -- Status signals
        ready       : out std_logic;
        busy        : out std_logic;
        done        : out std_logic;
        error       : out std_logic
    );
end entity;

architecture rtl of {module_snake}_core is

    -- FSM signals
    signal current_state : std_logic_vector(2 downto 0);
    signal next_state    : std_logic_vector(2 downto 0);

    -- Internal registers
    signal data_reg      : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal counter       : unsigned(7 downto 0);

begin

    ----------------------------------------------------------------------------
    -- State Register
    ----------------------------------------------------------------------------
    STATE_REG: process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= STATE_IDLE;
        elsif rising_edge(clk) then
            if clk_en = '1' then  -- CRITICAL: Check clock enable!
                if enable = '1' then
                    current_state <= next_state;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Next State Logic
    ----------------------------------------------------------------------------
    NEXT_STATE_LOGIC: process(current_state, data_valid, counter)
    begin
        next_state <= current_state;

        case current_state is
            when STATE_IDLE =>
                if data_valid = '1' then
                    next_state <= STATE_INIT;
                end if;

            when STATE_INIT =>
                next_state <= STATE_ACTIVE;

            when STATE_ACTIVE =>
                if counter = x"FF" then
                    next_state <= STATE_DONE;
                end if;

            when STATE_DONE =>
                next_state <= STATE_IDLE;

            when others =>
                next_state <= STATE_IDLE;
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- Output Logic
    ----------------------------------------------------------------------------
    OUTPUT_REG: process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_reg <= (others => '0');
            data_out <= (others => '0');
            counter <= (others => '0');
            ready <= '0';
            busy <= '0';
            done <= '0';
            error <= '0';
        elsif rising_edge(clk) then
            if clk_en = '1' then
                if enable = '1' then
                    -- Default outputs
                    done <= '0';

                    case current_state is
                        when STATE_IDLE =>
                            ready <= '1';
                            busy <= '0';
                            if data_valid = '1' then
                                data_reg <= data_in;
                            end if;

                        when STATE_INIT =>
                            ready <= '0';
                            busy <= '1';
                            counter <= (others => '0');

                        when STATE_ACTIVE =>
                            counter <= counter + 1;
                            -- Process data_reg here
                            data_out <= data_reg;  -- Example

                        when STATE_DONE =>
                            busy <= '0';
                            done <= '1';

                        when others =>
                            error <= '1';
                    end case;
                else
                    -- When disabled, maintain ready signal
                    ready <= '1';
                    busy <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;
'''

(module_path / "core" / f"{module_snake}_core.vhd").write_text(core_content)
print(f"✓ Created core entity: {module_snake}_core.vhd")

# Generate MCC Top wrapper if type is "mcc" or "volo"
if module_type in ["mcc", "volo"]:
    top_content = f'''--------------------------------------------------------------------------------
-- File: Top.vhd
-- Description: {description} - MCC CustomWrapper Architecture
--
-- MCC provides the CustomWrapper entity - we only define the architecture.
-- Implements the mandatory 3-bit control scheme in Control0[31:29].
--
-- Register Map:
--   Control0[31] = MCC_READY (set by MCC after network config)
--   Control0[30] = User Enable
--   Control0[29] = Clock Enable (CRITICAL - without this, logic freezes!)
--   Control0[28:0] = Module-specific configuration
--
-- Author: VOLO Team
-- Date: {datetime.now().strftime("%Y-%m-%d")}
--------------------------------------------------------------------------------

architecture {module_name} of CustomWrapper is

    -- MCC 3-bit control signals (MANDATORY for all MCC modules!)
    signal mcc_ready      : std_logic;
    signal user_enable    : std_logic;
    signal clk_enable     : std_logic;
    signal global_enable  : std_logic;

    -- Core interface signals
    signal core_ready     : std_logic;
    signal core_busy      : std_logic;
    signal core_done      : std_logic;
    signal core_error     : std_logic;

begin

    ----------------------------------------------------------------------------
    -- MCC Control Signal Extraction (CRITICAL!)
    ----------------------------------------------------------------------------
    -- Extract all 3 control bits - missing bit 29 causes frozen modules!
    mcc_ready     <= Control0(31);  -- Set by MCC when ready
    user_enable   <= Control0(30);  -- User control
    clk_enable    <= Control0(29);  -- Clock gating control

    -- Combine for safe operation
    global_enable <= mcc_ready and user_enable and clk_enable;

    ----------------------------------------------------------------------------
    -- Core Instantiation
    ----------------------------------------------------------------------------
    CORE_INST: entity WORK.{module_snake}_core
        generic map (
            G_DATA_WIDTH => 16
        )
        port map (
            -- Control signals
            clk        => Clk,
            rst_n      => not Reset,  -- Convert to active-low
            enable     => global_enable,
            clk_en     => clk_enable,

            -- Configuration
            config     => Control1,

            -- Data interface
            data_in    => InputA(15 downto 0),
            data_valid => Control0(0),  -- Example: use bit 0 as trigger
            data_out   => OutputA(15 downto 0),

            -- Status
            ready      => core_ready,
            busy       => core_busy,
            done       => core_done,
            error      => core_error
        );

    ----------------------------------------------------------------------------
    -- Status Register Assembly
    ----------------------------------------------------------------------------
    -- Status0: Standard status register format
    Status0 <= (
        31 downto 8 => '0',     -- Reserved
        7 => core_error,         -- Bit 7: FAULT (sticky)
        6 => '0',                -- Bit 6: ALARM
        2 => core_done,
        1 => core_busy,
        0 => core_ready,
        others => '0'
    );

    -- Tie unused outputs
    OutputA(31 downto 16) <= (others => '0');
    OutputB <= (others => '0');
    Status1 <= (others => '0');

end architecture;
'''
    (module_path / "top" / "Top.vhd").write_text(top_content)
    print(f"✓ Created MCC wrapper: Top.vhd")

# Generate test constants file
test_constants_content = f'''"""
Test Constants for {module_name}

Single source of truth for test configuration across P1-P4 levels.
Module: {module_name}
Type: {module_type.upper()}
"""

from pathlib import Path

# Module identification
MODULE_NAME = "{module_lower}"
MODULE_PATH = Path("../{str(module_path)}")

# HDL configuration
HDL_SOURCES = [
    MODULE_PATH / "common" / "{module_snake}_pkg.vhd",
    MODULE_PATH / "core" / "{module_snake}_core.vhd",
]

# For testing core directly (initial development)
HDL_TOPLEVEL = "{module_snake}_core"

# For MCC testing (after integration)
# HDL_TOPLEVEL = "CustomWrapper"
# HDL_SOURCES.append(MODULE_PATH / "top" / "Top.vhd")

# Clock configuration
DEFAULT_CLK_PERIOD_NS = 10  # 100 MHz

# Test parameter values - Progressive levels
class TestValues:
    # P1 - Minimal values for speed
    P1_DATA_SIZE = 10
    P1_TEST_CYCLES = 20
    P1_TIMEOUT = 100

    # P2 - Realistic operational values
    P2_DATA_SIZE = 100
    P2_TEST_CYCLES = 200
    P2_TIMEOUT = 1000

    # P3 - Boundary testing
    P3_DATA_SIZE = 65535
    P3_TEST_CYCLES = 5000
    P3_TIMEOUT = 10000

    # P4 - Exhaustive (rarely used)
    P4_ITERATIONS = 10000
    P4_RANDOM_SEEDS = 100

# Configuration constants
DEFAULT_CONFIG = {{
    'enable': 1,
    'clk_en': 1,
    'config': 0x00000000
}}
'''

(test_path / f"{module_lower}_constants.py").write_text(test_constants_content)
print(f"✓ Created test constants: {module_lower}_constants.py")

# Generate P1 test template
p1_test_content = f'''"""
P1 - Basic Tests for {module_name}

MINIMAL output, FAST execution, ESSENTIAL validation only.
Target: 3 tests, <100ms runtime, <50 tokens output.
"""

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from test_base import TestBase
from conftest import (
    setup_clock, reset_active_low, run_with_timeout
)
from {module_lower}_tests.{module_lower}_constants import *


class {module_name}BasicTests(TestBase):
    """P1 Basic test suite for {module_name}."""

    def __init__(self, dut):
        super().__init__(dut, MODULE_NAME)
        self.clk_period_ns = DEFAULT_CLK_PERIOD_NS

    async def test_reset(self):
        """T1: Reset clears all outputs."""
        await setup_clock(self.dut, clk_signal="clk", clk_period_ns=self.clk_period_ns)

        # Apply reset
        self.dut.rst_n.value = 0
        self.dut.enable.value = 0
        self.dut.clk_en.value = 1
        await ClockCycles(self.dut.clk, 5)

        # Check outputs are cleared
        assert self.dut.data_out.value == 0, "Data output not cleared"
        assert self.dut.ready.value == 0, "Ready not cleared"
        assert self.dut.busy.value == 0, "Busy not cleared"
        assert self.dut.error.value == 0, "Error not cleared"

        # Release reset
        self.dut.rst_n.value = 1
        await ClockCycles(self.dut.clk, 2)

        # After reset, should be ready
        assert self.dut.ready.value == 1, "Not ready after reset"

    async def test_clock_enable(self):
        """T2: Clock enable freezes operation."""
        await setup_clock(self.dut, clk_signal="clk", clk_period_ns=self.clk_period_ns)
        await reset_active_low(self.dut, rst_signal="rst_n")

        # Enable module
        self.dut.enable.value = 1
        self.dut.clk_en.value = 1
        self.dut.data_valid.value = 1
        self.dut.data_in.value = 0xABCD

        await ClockCycles(self.dut.clk, 2)
        self.dut.data_valid.value = 0

        # Freeze with clock enable
        self.dut.clk_en.value = 0
        initial_busy = int(self.dut.busy.value)

        await ClockCycles(self.dut.clk, 10)

        # State should not change when frozen
        assert self.dut.busy.value == initial_busy, "State changed while frozen"

        # Unfreeze
        self.dut.clk_en.value = 1
        await ClockCycles(self.dut.clk, 5)

    async def test_basic_operation(self):
        """T3: Basic data processing."""
        await setup_clock(self.dut, clk_signal="clk", clk_period_ns=self.clk_period_ns)
        await reset_active_low(self.dut, rst_signal="rst_n")

        # Configure and enable
        self.dut.enable.value = 1
        self.dut.clk_en.value = 1
        self.dut.config.value = DEFAULT_CONFIG['config']

        # Send data
        test_data = 0x1234
        self.dut.data_in.value = test_data
        self.dut.data_valid.value = 1

        await ClockCycles(self.dut.clk, 1)
        self.dut.data_valid.value = 0

        # Wait for processing
        for _ in range(TestValues.P1_TEST_CYCLES):
            await RisingEdge(self.dut.clk)
            if self.dut.done.value == 1:
                break

        # Check result
        assert self.dut.done.value == 1, "Processing did not complete"
        assert self.dut.error.value == 0, "Error during processing"
        self.log(f"Processing completed in {{_+1}} cycles", level='DEBUG')

    async def run_p1_basic(self):
        """Run all P1 basic tests."""
        await self.test("T1: Reset behavior", self.test_reset)
        await self.test("T2: Clock enable", self.test_clock_enable)
        await self.test("T3: Basic operation", self.test_basic_operation)


@cocotb.test()
async def test_{module_lower}_p1(dut):
    """Entry point - CocotB discovers this."""
    async def test_logic():
        tester = {module_name}BasicTests(dut)
        await tester.run_p1_basic()
        tester.print_summary()

    await run_with_timeout(test_logic(), timeout_sec=5, test_name="{module_name} P1 Basic")
'''

(test_path / f"P1_{module_lower}_basic.py").write_text(p1_test_content)
print(f"✓ Created P1 test: P1_{module_lower}_basic.py")

# Create empty P2 and P3 files
(test_path / f"P2_{module_lower}_intermediate.py").write_text(
    f'"""\nP2 - Intermediate Tests for {module_name}\n\nAdd tests for:\n- Edge cases\n- Error conditions\n- Performance limits\n"""\n\n# TODO: Implement P2 tests'
)

(test_path / f"P3_{module_lower}_comprehensive.py").write_text(
    f'"""\nP3 - Comprehensive Tests for {module_name}\n\nAdd tests for:\n- Stress testing\n- Full integration\n- Random stimulus\n"""\n\n# TODO: Implement P3 tests'
)

# Create __init__.py for test package
(test_path / "__init__.py").write_text(f'''"""
{module_name} Progressive Test Suite

Following VOLO CocotB Testing Standard:
- P1: Basic functionality
- P2: Intermediate with edge cases
- P3: Comprehensive stress testing
"""

from .{module_lower}_constants import MODULE_NAME, TestValues

__all__ = ['MODULE_NAME', 'TestValues']
''')

print(f"✓ Created P2/P3 test templates")

# Add to MODULE_LIST
module_list_path = Path("modules/MODULE_LIST")
if module_list_path.exists():
    existing = module_list_path.read_text()
    if module_name not in existing:
        with open(module_list_path, 'a') as f:
            f.write(f"{module_name}\n")
        print(f"✓ Added {module_name} to MODULE_LIST")
else:
    print(f"⚠ MODULE_LIST not found - add manually")

# Generate summary
print("\n" + "="*60)
print(f"✅ Module '{module_name}' created successfully!")
print("="*60)
print("\nStructure created:")
print(f"  📁 {module_path}/")
print(f"     ├── common/{module_snake}_pkg.vhd")
print(f"     ├── core/{module_snake}_core.vhd")
if module_type in ["mcc", "volo"]:
    print(f"     └── top/Top.vhd")
print(f"  📁 {test_path}/")
print(f"     ├── {module_lower}_constants.py")
print(f"     ├── P1_{module_lower}_basic.py")
print(f"     ├── P2_{module_lower}_intermediate.py")
print(f"     └── P3_{module_lower}_comprehensive.py")

print("\n📋 Next steps:")
print(f"  1. Implement your logic in {module_snake}_core.vhd")
print(f"  2. Run P1 tests: uv run python tests/run.py {module_lower}")
print(f"  3. Add more tests to P2/P3 as needed")
if module_type in ["mcc", "volo"]:
    print(f"  4. Test MCC integration with hardware")

print("\n💡 Tips:")
print("  - Keep P1 tests minimal (3-5 tests, <1s runtime)")
print("  - Use std_logic_vector for FSM states (not enums)")
print("  - Remember the 3-bit MCC control (bits 31,30,29)")
print("  - Test early and often!")
```

This slash command will create a complete module structure with all necessary files and templates. Users just need to provide the module name and a few optional parameters.
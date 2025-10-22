# Volo Base Module

A fundamental VHDL module demonstrating the enhanced rules system patterns and serving as a template for other modules in the Volo project.

## Overview

The base module implements a simple processing unit with configurable data width, counter functionality, and feature enable/disable capabilities. It serves as a reference implementation for:

- **Verilog Portability**: Uses only VHDL-2008 features that translate well to Verilog
- **Signal Priority Hierarchy**: Implements `reset > enable > clk_en > normal operation`
- **Direct Instantiation**: Ready for top-layer integration
- **Configuration Validation**: Safety-critical parameter validation
- **Status Register**: Standardized 8-bit status reporting

## Architecture

### Layer Structure

```
volo_base/
├── common/           # Volo base module specific utilities
├── core/            # Main algorithmic/logic implementation
├── top/             # External interface and register exposure
└── tb/              # Testbenches organized by layer
    ├── common/      # Tests for common layer packages
    ├── core/        # Tests for core layer entities
    └── top/         # Tests for top layer integration
```

### What Belongs Where

#### Volo Common Package (`modules/volo_common/volo_common_pkg.vhd`)
**Contains ONLY truly universal items:**
- ✅ **Status register bit positions** (0-7) - Used consistently across all modules
- ✅ **Universal utility functions** - `clamp_to_range()`, `is_in_range()`
- ✅ **Type conversion functions** - `natural_to_slv()`, `slv_to_natural()`

**What does NOT belong here:**
- ❌ Module-specific constants (data widths, timeouts, etc.)
- ❌ Feature-specific parameters
- ❌ Arbitrary limits that may not apply to all modules

#### Core Layer (`core/base_module_core.vhd`)
**Contains pure logic implementation:**
- ✅ **FSM implementation** - State machine with `std_logic_vector` encoding
- ✅ **Processing logic** - Algorithmic functionality
- ✅ **Configuration validation** - Parameter checking and clamping
- ✅ **Status register** - Module state reporting
- ✅ **Module-specific constants** - `BASE_DEFAULT_DATA_WIDTH`, `BASE_MAX_COUNTER_WIDTH`
- ✅ **Module-specific validation** - Direct validation logic using universal utilities

#### Top Layer (`top/base_module_top.vhd`)
**Contains system integration:**
- ✅ **External interface** - Platform control system connection
- ✅ **Register exposure** - Control, configuration, and status registers
- ✅ **Module integration** - Direct instantiation of core modules

## Key Design Patterns

### Signal Priority Hierarchy (SIG-03)
```vhdl
-- Priority: reset > enable > clk_en > normal operation
if rst_n = '0' then
    -- Reset logic (highest priority)
elsif rising_edge(clk) then
    if clk_en = '1' then
        if enable = '1' then
            -- Normal operation (lowest priority)
        end if;
    end if;
end if;
```

### FSM State Encoding
```vhdl
-- Use std_logic_vector for Verilog compatibility
constant IDLE_STATE      : std_logic_vector(2 downto 0) := "000";
constant CONFIG_STATE    : std_logic_vector(2 downto 0) := "001";
constant READY_STATE     : std_logic_vector(2 downto 0) := "010";
-- ... etc
```

### Status Register
```vhdl
-- Standard 8-bit status register
constant STATUS_FAULT_BIT      : natural := 7;
constant STATUS_ALARM_BIT      : natural := 6;
constant STATUS_BUSY_BIT       : natural := 5;
-- ... etc
```

## Helper Functions

### Volo Common Package Functions

#### `clamp_to_range(value, min_val, max_val)`
Clamps a natural value to a specified range.
```vhdl
signal clamped_value : natural;
clamped_value := clamp_to_range(input_value, 1, 32);
```

#### `is_in_range(value, min_val, max_val)`
Checks if a natural value is within a specified range.
```vhdl
if is_in_range(data_width, 1, 32) then
    -- Valid data width
end if;
```

#### `natural_to_slv(value, width)`
Converts natural to std_logic_vector with specified width.
```vhdl
signal slv_value : std_logic_vector(15 downto 0);
slv_value := natural_to_slv(42, 16);
```

#### `slv_to_natural(value)`
Converts std_logic_vector to natural (with bounds checking).
```vhdl
signal int_value : natural;
int_value := slv_to_natural(slv_input);
```

#### `create_status_reg(fault, alarm, busy, ready, enabled, active, valid, idle)`
Creates a status register from individual status bits.
```vhdl
signal status : std_logic_vector(7 downto 0);
status := create_status_reg('0', '0', '1', '0', '1', '1', '1', '0');
```

## Compilation Instructions

### Prerequisites
- GHDL with VHDL-2008 support
- Recommended: GHDL 5.0+ with LLVM backend

### Compilation Order
```bash
# 1. Compile volo common package first
ghdl -a --std=08 modules/volo_common/volo_common_pkg.vhd

# 2. Compile core entities
ghdl -a --std=08 modules/volo_base/core/base_module_core.vhd

# 3. Compile top entities (when implemented)
ghdl -a --std=08 modules/volo_base/top/base_module_top.vhd

# 4. Compile testbenches
ghdl -a --std=08 modules/volo_base/tb/**/*.vhd

# 5. Elaborate testbench
ghdl -e --std=08 <testbench_entity_name>

# 6. Run simulation
ghdl -r --std=08 <testbench_entity_name>
```

## Usage Examples

### Basic Instantiation
```vhdl
-- Direct instantiation (required for top layer)
base_core_inst: entity work.base_module_core
    generic map (
        DATA_WIDTH        => 16,
        COUNTER_WIDTH     => 8,
        TIMEOUT_VALUE     => to_unsigned(1000, 16)
    )
    port map (
        clk                     => clk,
        rst_n                   => rst_n,
        enable                  => enable,
        clk_en                  => clk_en,
        data_in                 => data_in,
        trigger_in              => trigger_in,
        cfg_data_width_in       => 16,
        cfg_counter_width_in    => 8,
        cfg_timeout_value_in    => to_unsigned(1000, 16),
        cfg_enable_feature_a_in => '1',
        cfg_enable_feature_b_in => '0',
        cfg_threshold_value_in  => x"1000",
        data_out                => data_out,
        result_out              => result_out,
        stat_status_out         => status_out
    );
```

### Status Register Usage
```vhdl
-- Check individual status bits
if status_out(STATUS_FAULT_BIT) = '1' then
    -- Handle fault condition
end if;

if status_out(STATUS_READY_BIT) = '1' then
    -- Module is ready for operation
end if;
```

## Testing

The module includes comprehensive testbenches for all layers:

- **Common Layer Tests**: Validate utility functions and constants
- **Core Layer Tests**: Test FSM behavior, configuration validation, and processing logic
- **Top Layer Tests**: Integration testing with external interfaces

All testbenches follow the project's testbench requirements:
- Print `'ALL TESTS PASSED'` on success
- Print `'TEST FAILED'` on failure
- Always print `'SIMULATION DONE'` at completion
- Use deterministic test patterns
- Compile with `ghdl --std=08`

## Verilog Conversion Notes

This module is designed for easy Verilog conversion:

- **No VHDL-only features**: Avoids records in RTL, enumeration types, etc.
- **Standard types only**: Uses `std_logic`, `std_logic_vector`, `unsigned`, `signed`
- **Explicit bit widths**: All vectors have explicit width declarations
- **Simple state encoding**: FSM uses `std_logic_vector` state encoding
- **Flat interfaces**: No complex type hierarchies in port declarations

## Future Extensions

The base module can be extended for specific applications by:

1. **Adding application-specific processing logic** in the core layer
2. **Implementing custom configuration parameters** in the common layer
3. **Adding specialized status bits** for application-specific monitoring
4. **Creating application-specific top layers** for different platforms

## Related Documentation

- [Enhanced Rules System](../../ng/README-synth-vhdl-tips-ng.md) - VHDL development patterns
- [GHDL Testbench Tips](../../ng/README-ghdl-testbench-tips-ng.md) - Testbench development
- [Base Module Development Roadmap](../../BASE-MODULE-DEVELOPMENT-ROADMAP.md) - Development plan
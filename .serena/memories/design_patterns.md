# Design Patterns and Guidelines

## Key Design Patterns

### 1. Direct Instantiation Pattern (MANDATORY for Top Layer)
All top-level integration files must use direct entity instantiation:

```vhdl
-- Top-level file: modules/*/top/*.vhd
architecture rtl of module_top is
begin
    -- ✅ REQUIRED: Direct instantiation
    U_CORE: entity WORK.module_core
        port map (
            clk => clk,
            n_reset => n_reset,
            enable => enable,
            data_in => data_in,
            data_out => data_out
        );
end architecture;
```

**Benefits**:
- Clear compilation order requirements
- Port mismatches caught at analysis time
- Uniform pattern across top-level files
- Easier dependency tracking

### 2. Platform Interface Package Pattern
For modules requiring register interfaces, use a platform interface package:

```vhdl
-- In common/platform_interface_pkg.vhd
package platform_interface_pkg is
    -- Register field bit positions
    constant CTRL_GLOBAL_ENABLE_BIT : natural := 0;
    constant CTRL_DIV_SEL_LOW : natural := 4;
    constant CTRL_DIV_SEL_HIGH : natural := 7;
    
    -- Validation functions
    function is_wave_select_valid(wave_select : std_logic_vector(1 downto 0)) 
        return std_logic;
    
    -- Field extraction functions
    function extract_ctrl_global_enable(ctrl_data : std_logic_vector(7 downto 0)) 
        return std_logic;
    
    -- Status assembly functions
    function assemble_status0_reg(
        enabled : std_logic;
        wave_select : std_logic_vector(1 downto 0)
    ) return std_logic_vector;
end package;
```

**Usage**:
```vhdl
-- In core or top layer
use work.platform_interface_pkg.all;

-- Validate configuration
if is_wave_select_valid(wave_select) = '0' then
    fault_out <= '1';  -- Trigger fault
end if;

-- Extract fields
global_enable <= extract_ctrl_global_enable(ctrl0_data);

-- Assemble status
status_reg <= assemble_status0_reg(enabled, wave_select);
```

### 3. Standard Control Signal Pattern
Implement control signals with clear priority:

```vhdl
process(clk, n_reset)
begin
    if n_reset = '0' then
        -- Priority 1: Reset dominates
        state <= IDLE_STATE;
        output <= (others => '0');
    elsif rising_edge(clk) then
        if clk_en = '1' then
            -- Priority 2: Clock enable
            if enable = '1' then
                -- Priority 3: Functional enable
                -- Normal operation
                case state is
                    when IDLE_STATE =>
                        state <= ACTIVE_STATE;
                    when ACTIVE_STATE =>
                        output <= computed_value;
                    when others =>
                        state <= IDLE_STATE;
                end case;
            else
                -- Idle: Hold state, outputs parked
                output <= (others => '0');
            end if;
        end if;
        -- clk_en='0': State held (no updates)
    end if;
end process;
```

### 4. FSM State Encoding Pattern
Use `std_logic_vector` with constants instead of enums:

```vhdl
-- State encoding constants
constant IDLE_STATE   : std_logic_vector(1 downto 0) := "00";
constant ACTIVE_STATE : std_logic_vector(1 downto 0) := "01";
constant WAIT_STATE   : std_logic_vector(1 downto 0) := "10";
constant DONE_STATE   : std_logic_vector(1 downto 0) := "11";

-- State register
signal current_state : std_logic_vector(1 downto 0) := IDLE_STATE;
signal next_state : std_logic_vector(1 downto 0);

-- State machine implementation
process(clk, n_reset)
begin
    if n_reset = '0' then
        current_state <= IDLE_STATE;
    elsif rising_edge(clk) then
        if clk_en = '1' then
            current_state <= next_state;
        end if;
    end if;
end process;
```

### 5. Status Register Implementation Pattern
Standard status register with sticky fault bits:

```vhdl
signal status_reg : std_logic_vector(7 downto 0);

-- Bit assignments
constant STATUS_FAULT_BIT : natural := 7;  -- Sticky
constant STATUS_ALARM_BIT : natural := 6;  -- Sticky
constant STATUS_ACTIVE_BIT : natural := 0; -- State

process(clk, n_reset)
begin
    if n_reset = '0' then
        status_reg <= (others => '0');  -- All bits cleared
    elsif rising_edge(clk) then
        -- Sticky bits (only set, never clear except on reset)
        if fault_condition = '1' then
            status_reg(STATUS_FAULT_BIT) <= '1';
        end if;
        if alarm_condition = '1' then
            status_reg(STATUS_ALARM_BIT) <= '1';
        end if;
        
        -- State bits (reflect current state)
        status_reg(STATUS_ACTIVE_BIT) <= is_active;
    end if;
end process;
```

### 6. Testbench 4-Layer Architecture
Structure testbenches in four distinct layers:

```vhdl
-- Layer 1: Interface Testing (external behavior)
procedure test_interface is
begin
    -- Test what the module does via status bits
    -- No assumptions about internal state
end procedure;

-- Layer 2: Validation Testing (error handling)
procedure test_validation is
begin
    -- Test invalid inputs
    -- Verify fault/alarm bits are set
end procedure;

-- Layer 3: Functional Testing (core functionality)
procedure test_functionality is
begin
    -- Test main operational features
    -- Verify correct outputs for valid inputs
end procedure;

-- Layer 4: Generic Parameter Testing (edge cases)
procedure test_generic_parameters is
begin
    -- Test different generic configurations
    -- Verify behavior at parameter boundaries
end procedure;
```

### 7. Voltage/Data Conversion Package Pattern (Datadef Layer)

**When to Use**: Module needs voltage conversion, data scaling, or complex mathematical operations with validation.

**Example**: `modules/volo_common/common/Moku_Voltage_pkg.vhd` (Reference Implementation)

**Package Structure**:
```vhdl
-- In datadef/conversion_package.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Moku_Voltage_pkg is
    -- System constants with unit documentation
    constant VOLTAGE_DATA_WIDTH : natural := 16;      -- Units: bits
    constant VOLTAGE_REFERENCE  : real := 5.0;        -- Units: volts
    constant VOLTAGE_MIN        : real := -5.0;       -- Units: volts
    constant VOLTAGE_MAX        : real := 5.0;        -- Units: volts
    constant DIGITAL_MAX        : natural := 65535;   -- Units: count
    
    -- Bidirectional conversion functions
    function voltage_to_digital(voltage : real) return std_logic_vector;
    function digital_to_voltage(digital : std_logic_vector) return real;
    
    -- Safety and validation functions
    function clamp_voltage_safe(voltage : real) return real;
    function is_voltage_safe(voltage : real) return boolean;
    
    -- Scaling and arithmetic operations
    function scale_voltage(voltage : real; scale_factor : real) return real;
    function add_voltages_safe(v1, v2 : real) return real;
    
    -- Default constants for common values
    constant DEFAULT_VOLTAGE_ZERO : real := 0.0;
    constant DEFAULT_DIGITAL_MID  : std_logic_vector(15 downto 0) := x"8000";
end package;

package body Moku_Voltage_pkg is
    -- Linear mapping: -5V → 0x0000, 0V → 0x8000, +5V → 0xFFFF
    function voltage_to_digital(voltage : real) return std_logic_vector is
        variable clamped_voltage : real;
        variable digital_value : natural;
    begin
        clamped_voltage := clamp_voltage_safe(voltage);
        digital_value := natural((clamped_voltage - VOLTAGE_MIN) * 
                                  real(DIGITAL_MAX) / (VOLTAGE_MAX - VOLTAGE_MIN));
        return std_logic_vector(to_unsigned(digital_value, VOLTAGE_DATA_WIDTH));
    end function;
    
    function clamp_voltage_safe(voltage : real) return real is
    begin
        if voltage < VOLTAGE_MIN then
            return VOLTAGE_MIN;
        elsif voltage > VOLTAGE_MAX then
            return VOLTAGE_MAX;
        else
            return voltage;
        end if;
    end function;
    
    -- ... other function implementations ...
end package body;
```

**Usage in Core Module**:
```vhdl
-- In core/EMFI_Seq_stair.vhd
use work.Moku_Voltage_pkg.all;

architecture rtl of onehot_analog_monitor is
    -- Voltage codes computed using package functions (self-documenting)
    constant CODE_S1 : signed(15 downto 0) := signed(voltage_to_digital(1.1));
    constant CODE_S2 : signed(15 downto 0) := signed(voltage_to_digital(1.2));
    constant CODE_S3 : signed(15 downto 0) := signed(voltage_to_digital(1.3));
    constant CODE_S4 : signed(15 downto 0) := signed(voltage_to_digital(1.4));
    constant CODE_Z  : signed(15 downto 0) := signed(voltage_to_digital(0.0));
begin
    -- Combinational decode using computed constants
    with state_oh select
        dac_out_s16 <= CODE_S1 when "0001",
                       CODE_S2 when "0010",
                       CODE_S3 when "0100",
                       CODE_S4 when "1000",
                       CODE_Z  when others;
end architecture;
```

**Key Benefits**:
- **Self-documenting**: Voltage values explicit in code (1.1, 1.2, etc.)
- **Compile-time computation**: Functions evaluated during synthesis
- **Consistency**: All modules use same conversion algorithm
- **Testable**: Package can be unit tested independently
- **Maintainable**: Change voltage range in one place
- **Safe**: Built-in clamping and validation

**Testbench Pattern** (Tier 3 - Full VHDL-2008):
```vhdl
-- In tb/datadef/tb_Moku_Voltage_pkg.vhd
test_process : process
    variable v_result : real;
    variable d_result : std_logic_vector(15 downto 0);
    
    -- Helper for real number comparison with tolerance
    constant TOLERANCE : real := 0.01;  -- 10mV
    function real_equal(a, b : real) return boolean is
    begin
        return abs(a - b) < TOLERANCE;
    end function;
begin
    -- Test bidirectional conversion
    d_result := voltage_to_digital(1.1);
    check_test("1.1V conversion", d_result = x"9C28");
    
    v_result := digital_to_voltage(x"9C28");
    check_test("Reverse conversion", real_equal(v_result, 1.1));
    
    -- Test clamping
    d_result := voltage_to_digital(10.0);  -- Over max
    check_test("Clamp high", d_result = x"FFFF");
    
    -- Test round-trip
    v_result := digital_to_voltage(voltage_to_digital(2.5));
    check_test("Round-trip 2.5V", real_equal(v_result, 2.5));
end process;
```

**Documentation Pattern**:
Create `datadef/README_PackageName.md` with:
- Function descriptions and signatures
- Unit conventions (volts, bits, ratio, etc.)
- Usage examples from actual code
- Integration notes
- Testbench location and coverage

**Verilog Conversion Strategy**:
- Package functions → SystemVerilog functions or parameters
- Constants computed at compile time → `localparam` with pre-computed values
- Real arithmetic → Fixed-point with documented precision
- Document conversion approach in package header comments

**When NOT to Use**:
- Simple constant definitions (use plain constants)
- Clock-dependent operations (belongs in core layer)
- Platform-specific code (use platform_interface_pkg pattern)

**Reference Files**:
- `modules/volo_common/common/Moku_Voltage_pkg.vhd` - Implementation
- `modules/volo_common/Moku-Voltage-LUTS.md` - Documentation
- `modules/EMFI-Seq/tb/core/tb_EMFI_Seq_stair.vhd` - Tests (17/17 passing)
- `modules/EMFI-Seq/core/EMFI_Seq_stair.vhd` - Usage example

**Discovered**: 2025-01-21, EMFI-Seq voltage package development

### 8. LUT and Data Structure Pattern (Datadef Layer)
Define data structures in datadef with Verilog conversion strategy:

```vhdl
-- In datadef/data_structures_pkg.vhd
package data_structures_pkg is
    -- Array type for LUT (Verilog: parameter array)
    type voltage_lut_t is array (0 to 100) of std_logic_vector(15 downto 0);
    
    -- Record for data organization (Verilog: SystemVerilog struct or packed array)
    type config_record_t is record
        voltage_threshold : std_logic_vector(15 downto 0);
        timeout_value : std_logic_vector(15 downto 0);
        enable_flags : std_logic_vector(7 downto 0);
    end record;
    
    -- Verilog conversion strategy documented in comments
    -- Record → SystemVerilog struct or three separate signals
    
    -- LUT constant (Verilog: parameter array or .mem file)
    constant PERCENT_LUT : voltage_lut_t := (
        0 => X"0000",
        1 => X"028F",
        -- ... rest of LUT
    );
end package;
```

## Anti-Patterns to Avoid

### ❌ Don't Use Component Declarations in Top Layer
```vhdl
-- WRONG: Component declaration in top layer
component my_core is
    port (clk : in std_logic);
end component;

U1: my_core port map (clk => clk);
```

### ❌ Don't Use Enumeration Types in RTL
```vhdl
-- WRONG: Enum type in RTL (core/top layers)
type state_t is (IDLE, ACTIVE, DONE);
signal state : state_t;
```

### ❌ Don't Use Records in RTL Port Declarations
```vhdl
-- WRONG: Record in entity port (except datadef)
entity my_module is
    port (
        config : in config_record_t  -- NOT ALLOWED in core/top
    );
end entity;
```

### ❌ Don't Test Internal State in Testbenches
```vhdl
-- WRONG: Testing internal state machine
-- Instead test external behavior (status bits, outputs)
```

### ❌ Don't Modify ng/ Tip Files Main Body
```vhdl
-- WRONG: Reorganizing README-synth-vhdl-tips-ng.md
-- CORRECT: Append to footer below "------- New Tips here-------"
```

### ❌ Don't Hardcode Conversion Values Without Documentation
```vhdl
-- WRONG: Magic numbers without explanation
constant CODE_S1 : signed(15 downto 0) := x"1C29";  -- What voltage is this?

-- CORRECT: Use conversion package or document heavily
constant CODE_S1 : signed(15 downto 0) := signed(voltage_to_digital(1.1));  -- 1.1V
-- Or if hardcoded, add extensive comments explaining the calculation
```

## Module Dependency Management
Define dependencies in `modules/Makefile.deps`:

```makefile
# Module build order (shared modules built first, then application modules)
MODULE_BUILD_ORDER = probe_driver SimpleWaveGen stoplight

# Specific module dependencies
# Note: clk_divider_core is now part of volo_common (no separate module)
MODULE_DEPS_SimpleWaveGen = volo_common
MODULE_DEPS_probe_driver = volo_common

# Shared modules (built first, objects available to dependent modules)
# volo_common includes: Moku_Voltage_pkg, volo_common_pkg, clk_divider_core
SHARED_MODULES = volo_common
```

## Reference Implementations

### SimpleWaveGen (Complete Reference)
**Location**: `modules/SimpleWaveGen/`

**Demonstrates**:
- Successfully deployed to Moku device
- Complete testing at all layers
- Platform interface package usage
- Direct instantiation in top layer
- Proper control signal handling

### EMFI-Seq (Voltage Conversion Reference)
**Location**: `modules/EMFI-Seq/`

**Demonstrates**:
- Voltage conversion package pattern (datadef layer)
- Multi-core integration (FSM + analog monitor)
- Compile-time constant computation
- Comprehensive package testing (17/17 tests passing)
- Self-documenting voltage codes
- Pattern 1 (Simple Direct Mapping) MCC integration

**Key Files**:
- `datadef/Moku_Voltage_pkg.vhd` - Conversion package with validation
- `datadef/README_Moku_Voltage_pkg.md` - Complete package documentation
- `core/EMFI_Seq_stair.vhd` - Usage of voltage package
- `tb/datadef/tb_Moku_Voltage_pkg.vhd` - Package tests
- `tb/core/tb_EMFI_Seq_stair.vhd` - Core module tests

### volo_common (Shared Modules Reference)
**Location**: `modules/volo_common/`

**Purpose**: Provides shared utilities and reusable cores for all modules

**Key Components**:
- **`common/volo_common_pkg.vhd`** - General utility package
- **`common/Moku_Voltage_pkg.vhd`** - Voltage conversion utilities with bidirectional conversion, clamping, and validation
- **`core/clk_divider_core.vhd`** - Configurable clock divider core

**Clock Divider Core Features** (`clk_divider_core.vhd`):
- **Generic MAX_DIV**: Configurable maximum division ratio (default 256)
- **Enable input**: Freeze/unfreeze counting (Priority: reset > enable > functional logic)
- **div_sel encoding**: Linear mapping (0=÷1, 1=÷2, 2=÷3, ..., up to MAX_DIV)
- **Clock enable output**: Generates clock enable pulses (not divided clock - safer for timing)
- **Status register**: Shows current counter state
- **Testbench**: `tb/core/clk_divider_core_tb.vhd`

**Usage Example**:
```vhdl
-- Direct instantiation of clock divider
U_CLK_DIV: entity WORK.clk_divider_core
    generic map (
        MAX_DIV => 256  -- Support division up to 256
    )
    port map (
        clk         => clk,
        rst_n       => rst_n,
        enable      => clk_div_enable,      -- Freeze when low
        div_sel     => div_sel(7 downto 0), -- 0=÷1, 1=÷2, etc.
        clk_en      => divided_clk_en,      -- Output clock enable
        stat_reg    => clk_div_status       -- Status/counter value
    );
```

**Discovered**: 2025-10-21, consolidated from standalone module into volo_common

### 9. Intensity/Percentage LUT Pattern (Module-Specific)

**Location**: Module-specific datadef layer (e.g., `probe_driver/datadef/PercentLut_pkg.vhd`)

**When to Use**: Module needs intensity/brightness/percentage mapping (0-100%) to voltage values.

**Package Structure** (Record-based with CRC validation):
```vhdl
-- In datadef/PercentLut_pkg.vhd
package PercentLut_pkg is
    constant SYSTEM_PERCENT_LUT_SIZE : natural := 101; -- Indices 0-100
    
    -- Array type for LUT data
    type percent_lut_data_array_t is array (0 to 100) of 
        std_logic_vector(15 downto 0);
    
    -- Record for encapsulation with validation
    type percent_lut_record_t is record
        data_array : percent_lut_data_array_t;
        crc        : std_logic_vector(15 downto 0);
        valid      : std_logic;
        size       : std_logic_vector(6 downto 0);
    end record;
    
    -- CRC validation functions
    function calculate_percent_lut_crc(lut_data : percent_lut_data_array_t) 
        return std_logic_vector;
    function validate_percent_lut_record(lut_rec : percent_lut_record_t) 
        return boolean;
    
    -- Safe lookup with bounds checking
    function get_percentlut_value_safe(lut_rec : percent_lut_record_t; 
                                       index : natural) 
        return std_logic_vector;
end package;
```

**Key Differences from Voltage Package**:
- **Module-specific**: Not moved to volo_common (only used by probe_driver modules)
- **Record-based**: Better type safety and encapsulation
- **CRC validation**: Data integrity checking
- **LUT storage**: Full lookup table (101 entries)

**Reference Implementation**:
- Canonical: `modules/probe_driver/datadef/PercentLut_pkg.vhd`
- Documentation: `modules/probe_driver/datadef/PercentLut_Analysis.md`
- Testbench: `modules/probe_driver/tb/datadef/PercentLut_pkg_tb.vhd`

**Consolidation** (2025-10-21): Removed 10 duplicate enhanced (`_en`) versions


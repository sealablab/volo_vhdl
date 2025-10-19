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

### 7. LUT and Data Structure Pattern (Datadef Layer)
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

## Module Dependency Management
Define dependencies in `modules/Makefile.deps`:

```makefile
# Module build order (dependencies first)
MODULE_BUILD_ORDER := volo_common clk_divider SimpleWaveGen probe_driver

# Specific module dependencies
SimpleWaveGen_DEPS := volo_common clk_divider
probe_driver_DEPS := volo_common
```

## Reference Implementation
**SimpleWaveGen** (`modules/SimpleWaveGen/`) is the canonical reference:
- Demonstrates all required patterns
- Successfully deployed to Moku device
- Complete testing at all layers
- Platform interface package usage
- Direct instantiation in top layer
- Proper control signal handling

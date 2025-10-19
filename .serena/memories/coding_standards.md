# Coding Standards and Conventions

## Core Principle: VHDL-2008 with Verilog Portability
All VHDL code must be designed for easy conversion to Verilog.

## Tiered Rule System

### Tier 1: Strict RTL Rules
**Applies to**: `common/`, `core/`, `top/` directories

**Allowed**:
- `std_logic`, `std_logic_vector`, `unsigned`, `signed`
- Generics and generate statements
- Synchronous processes with `rising_edge(clk)`
- Explicit bit widths

**Forbidden**:
- Records in port declarations
- Enumeration types in RTL (use `std_logic_vector` with constants)
- Subtype range constraints
- `wait` statements in RTL
- `after` delays
- Shared variables

### Tier 2: Relaxed Data Definition Rules
**Applies to**: `datadef/` directories

**Allowed**:
- Records for data organization (with Verilog conversion strategy)
- Array types and complex constants
- LUT definitions
- Data validation functions
- Function overloading

**Forbidden**:
- Clock-dependent operations
- State machines
- RTL logic

### Tier 3: Full VHDL-2008 Rules
**Applies to**: `tb/` directories
- All VHDL-2008 features allowed
- No portability constraints (simulation-only)

## Signal Naming Conventions

### Prefixes (Mandatory)
- **`ctrl_*`** - Control signals (enable, reset)
- **`cfg_*`** - Configuration parameters
- **`stat_*`** - Status and monitoring signals

### Standard Control Signals
All modules should implement these in priority order:
1. **`clk`** - Primary clock input
2. **`reset`** or **`n_reset`** - Active-low reset (highest priority)
3. **`clk_en`** - Clock enable (freezes sequential logic)
4. **`enable`** - Functional enable (gates functional work)

## FSM Implementation
Use `std_logic_vector` for state encoding with constants:
```vhdl
constant IDLE_STATE   : std_logic_vector(1 downto 0) := "00";
constant ACTIVE_STATE : std_logic_vector(1 downto 0) := "01";
constant DONE_STATE   : std_logic_vector(1 downto 0) := "10";

signal current_state : std_logic_vector(1 downto 0);
```

## Direct Instantiation (MANDATORY for Top Layer)
All top-level files (`modules/**/top/*.vhd` and `modules/**/tb/top/*.vhd`) **MUST** use direct instantiation:

```vhdl
-- ✅ REQUIRED: Direct instantiation
U1: entity WORK.module_name
    port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        data_out => data_out
    );

-- ❌ FORBIDDEN in top layer: Component declaration
-- component module_name is ... end component;
-- U1: module_name port map (...);
```

## Process Structure Pattern
```vhdl
process(clk, n_reset)
begin
    if n_reset = '0' then
        -- Reset: All outputs to safe defaults
    elsif rising_edge(clk) then
        if clk_en = '1' then
            if enable = '1' then
                -- Normal operation
            else
                -- Idle: Hold state, outputs parked
            end if;
        end if;
        -- clk_en='0': Hold state (no updates)
    end if;
end process;
```

## Status Register Standards
- **Bit 7**: FAULT (sticky, cleared only on reset)
- **Bit 6**: ALARM (sticky, cleared only on reset)
- **Update timing**: Synchronous on rising edge
- **Reset behavior**: All bits cleared on reset

## Testbench Requirements

### 4-Layer Testing Architecture (Mandatory)
1. **Layer 1: Interface Testing** - Test WHAT the module does, not HOW
2. **Layer 2: Validation Testing** - Test parameter validation and error handling
3. **Layer 3: Functional Testing** - Test core functionality and behavior
4. **Layer 4: Generic Parameter Testing** - Test different generic configurations

### Required Output
All testbenches must print:
```vhdl
report "ALL TESTS PASSED" severity note;  -- On success
report "TEST FAILED" severity error;       -- On failure
report "SIMULATION DONE" severity note;    -- Always at end
```

### Termination Pattern
```vhdl
-- Method 1: Clean stop (preferred)
std.env.stop(0);

-- Method 2: Assertion failure
assert false report "Simulation completed" severity failure;
```

## Platform Interface Package Pattern
For modules requiring register interfaces:
- Define register field bit positions as constants
- Implement field extraction functions
- Implement status assembly functions
- Include validation functions with fault triggering

## Compilation Order
Always compile in this order:
1. Packages (common, datadef)
2. Core modules
3. Top-level modules
4. Testbenches

## GHDL Settings
- **Standard**: Always use `--std=08` for VHDL-2008
- **Work library**: Unified work library shared across modules

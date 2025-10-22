# MCC (Moku Custom Core) Build Pattern

## Overview
The Moku Custom Core (MCC) platform requires a specific entity called `CustomWrapper` with a standardized port interface. Our build system uses a centralized template to provide this entity, while each module provides its own architecture.

## File Structure

### Central Template (Project Level)
```
mcc_templates/
└── mcc-Top.vhd          # CustomWrapper ENTITY ONLY (no architecture)
```

**Purpose**: Provides the standard CustomWrapper entity declaration that all modules share.

**Key Points**:
- Contains ONLY the entity declaration
- NO architecture defined here
- Compiled first by the build system
- All modules' architectures reference this same entity

### Module-Specific Architecture
```
modules/<module_name>/top/
├── <ModuleName>.vhd           # Main module entity + architecture
└── Top.vhd                    # CustomWrapper ARCHITECTURE ONLY
```

**Pattern**: `architecture <ModuleName> of CustomWrapper is`

## Standard CustomWrapper Entity Interface

```vhdl
entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;

        -- Input signals (ADC data, signed 16-bit)
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        InputD  : in  signed(15 downto 0);

        -- Output signals (DAC data, signed 16-bit)
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        OutputD : out signed(15 downto 0);

        -- Control registers (32-bit each, from Moku platform)
        Control0  : in  std_logic_vector(31 downto 0);
        Control1  : in  std_logic_vector(31 downto 0);
        Control2  : in  std_logic_vector(31 downto 0);
        Control3  : in  std_logic_vector(31 downto 0);
        Control4  : in  std_logic_vector(31 downto 0);
        Control5  : in  std_logic_vector(31 downto 0);
        Control6  : in  std_logic_vector(31 downto 0);
        Control7  : in  std_logic_vector(31 downto 0);
        Control8  : in  std_logic_vector(31 downto 0);
        Control9  : in  std_logic_vector(31 downto 0);
        Control10 : in  std_logic_vector(31 downto 0);
        Control11 : in  std_logic_vector(31 downto 0);
        Control12 : in  std_logic_vector(31 downto 0);
        Control13 : in  std_logic_vector(31 downto 0);
        Control14 : in  std_logic_vector(31 downto 0);
        Control15 : in  std_logic_vector(31 downto 0)
    );
end entity CustomWrapper;
```

## Module Architecture Pattern

Each module provides ONLY an architecture in `modules/<module>/top/Top.vhd`:

```vhdl
-- modules/EMFI-Seq/top/Top.vhd
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture EMFI_Seq of CustomWrapper is
    -- Internal signals
    signal status_internal : unsigned(6 downto 0);
    -- ... more signals
begin
    -- Instantiate your module
    EMFI_SEQUENCER: entity WORK.EMFI_Seq
        port map (
            Clk        => Clk,
            Reset      => Reset,
            Enable     => not Control0(31),
            -- ... map registers to module ports
            DACOut     => OutputA
        );
    
    -- Map internal signals to outputs
    OutputB <= signed(resize(status_internal, 16));
end architecture EMFI_Seq;
```

## Build System Integration

The central Makefile (`modules/Makefile`) automatically:

1. **Compiles mcc template first**:
   ```makefile
   @$(GHDL_ANALYZE) $(MCC_TEMPLATE_DIR)/mcc-Top.vhd
   ```

2. **Then compiles each module's architecture**:
   - Compiles `modules/<module>/top/Top.vhd`
   - GHDL matches the architecture to the already-compiled entity

## Common Pitfalls

### ❌ DON'T: Duplicate Entity in Module
```vhdl
-- WRONG: Don't define CustomWrapper entity in your module
entity CustomWrapper is
    ...
end entity;

architecture MyModule of CustomWrapper is
    ...
end architecture;
```

This will cause:
```
warning: entity "customwrapper" was also defined in file "mcc_templates/mcc-Top.vhd"
```

### ✅ DO: Architecture Only
```vhdl
-- CORRECT: Only provide architecture, reference central entity
architecture MyModule of CustomWrapper is
    ...
end architecture;
```

### ❌ DON'T: Missing mcc_templates/
If `mcc_templates/mcc-Top.vhd` doesn't exist, you'll get:
```
error: cannot open /path/to/mcc_templates/mcc-Top.vhd
compilation error
```

**Solution**: Ensure `mcc_templates/mcc-Top.vhd` exists at project root.

### ❌ DON'T: Wrong Architecture Naming
```vhdl
-- WRONG: Generic architecture name
architecture rtl of CustomWrapper is
```

**Problem**: Multiple modules would have the same architecture name `rtl`.

**Solution**: Use module-specific architecture names:
```vhdl
-- CORRECT: Module-specific architecture name
architecture EMFI_Seq of CustomWrapper is  -- Unique to EMFI-Seq
architecture SimpleWaveGen of CustomWrapper is  -- Unique to SimpleWaveGen
```

## Register Mapping Conventions

### Control Registers (Inputs)
Typical usage patterns:

```vhdl
-- Common patterns
Enable     => not Control0(31)           -- Active-low enable
ClkEn      => not Control0(30)           -- Active-low clock enable
DivSel     => Control0(7 downto 0)       -- Clock divider select
Threshold  => signed(Control1(15 downto 0))  -- Signed threshold
Parameter  => unsigned(Control2(6 downto 0)) -- Unsigned parameter
```

### Output Registers (Outputs)
Typical usage patterns:

```vhdl
-- Direct mapping
OutputA <= dac_output;  -- 16-bit DAC value

-- Status packing (resize if needed)
OutputB <= signed(resize(status_reg, 16));

-- Multi-field packing
OutputC <= signed(monitor_value(15 downto 4) & state_onehot);

-- Counter/diagnostic
OutputD <= signed(resize(unsigned(counter), 16));
```

## Two MCC Integration Patterns

### Pattern 1: Simple Direct Mapping (Recommended)
**Example**: EMFI-Seq

**Files**:
- `top/<ModuleName>.vhd` - Main module entity + architecture
- `top/Top.vhd` - CustomWrapper architecture only

**Characteristics**:
- Direct register mapping in port map
- No intermediate signals
- No synchronous process in CustomWrapper
- Minimal complexity
- Use when: Simple register mapping, no validation needed

**Template**:
```vhdl
architecture EMFI_Seq of CustomWrapper is
    signal internal_sig : unsigned(6 downto 0);
begin
    MODULE_INST: entity WORK.EMFI_Seq
        port map (
            Clk => Clk,
            Enable => not Control0(31),
            DataOut => OutputA
        );
    
    OutputB <= signed(resize(internal_sig, 16));
end architecture;
```

### Pattern 2: Platform Interface Package (Complex)
**Example**: SimpleWaveGen

**Files**:
- `common/platform_interface_pkg.vhd` - Register field extraction, validation
- `top/<ModuleName>_top.vhd` - Main module with register logic
- `top/<ModuleName>_customwrapper.vhd` - CustomWrapper architecture

**Characteristics**:
- Complex register field extraction
- Validation functions with fault detection
- Status register assembly logic
- Multiple configuration parameters
- Use when: Need validation, complex register logic, fault handling

**When to Use Each Pattern**:
- **Pattern 1**: Start here by default. Covers 80% of cases.
- **Pattern 2**: Only when you need validation functions or complex register logic.

## Build Order Dependencies

The Makefile ensures correct compilation order:

1. `mcc_templates/mcc-Top.vhd` (CustomWrapper entity)
2. `volo_common` packages (Moku_Voltage_pkg, Moku_Pct_pkg, etc.)
3. Module common packages
4. Module datadef packages
5. Module core entities
6. Module top-level files (including CustomWrapper architecture)

### Package Dependency in volo_common

Special handling for package dependencies in `volo_common/common/`:

```makefile
# Moku_Voltage_pkg compiled first (no dependencies)
$(GHDL_ANALYZE) volo_common/common/Moku_Voltage_pkg.vhd

# Moku_Pct_pkg compiled second (depends on Moku_Voltage_pkg)
$(GHDL_ANALYZE) volo_common/common/Moku_Pct_pkg.vhd

# Other packages compiled last
$(GHDL_ANALYZE) volo_common/common/*.vhd
```

## Verification Checklist

Before committing a new MCC module:

- [ ] `mcc_templates/mcc-Top.vhd` exists at project root
- [ ] Module's `Top.vhd` has ONLY architecture (no entity)
- [ ] Architecture name matches module name (e.g., `architecture EMFI_Seq of CustomWrapper`)
- [ ] No duplicate CustomWrapper entity in module
- [ ] Build completes without errors: `cd modules && make clean && make compile`
- [ ] All register mappings documented in Top.vhd header comments

## Migration from Old Pattern

If you have an old module with local `mcc-Top.vhd`:

1. **Check if module defines CustomWrapper entity locally**:
   ```bash
   grep "entity CustomWrapper" modules/<module>/top/mcc-Top.vhd
   ```

2. **If yes, remove or rename it**:
   ```bash
   mv modules/<module>/top/mcc-Top.vhd modules/<module>/top/mcc-Top.vhd.OLD
   ```

3. **Verify architecture-only file exists**:
   - Should be `Top.vhd` or `<ModuleName>_customwrapper.vhd`
   - Should contain `architecture <Name> of CustomWrapper is`

4. **Rebuild**:
   ```bash
   cd modules && make clean && make compile
   ```

## Reference Implementations

- **Pattern 1 (Simple)**: `modules/EMFI-Seq/top/Top.vhd`
- **Pattern 2 (Complex)**: `modules/SimpleWaveGen/top/SimpleWaveGen_customwrapper.vhd`
- **Central Template**: `mcc_templates/mcc-Top.vhd`

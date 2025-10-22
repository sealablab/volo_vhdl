# Moku Voltage Package (Enhanced)

**Location:** `modules/EMFI-Seq/datadef/Moku_Voltage_pkg_en.vhd`
**Tier:** 2 (Relaxed Data - Records allowed, no clock-dependent ops)
**Purpose:** Voltage conversion and validation utilities for MCC platform

## Overview

This package provides comprehensive voltage handling utilities for the Moku Custom Controller (MCC) platform. It handles bidirectional conversion between real voltage values (±5V range) and 16-bit digital representations, with extensive validation and safety features.

## Key Features

### Voltage Representation
- **Voltage range:** -5.0V to +5.0V (configurable via constants)
- **Digital representation:** 16-bit unsigned (0 to 65535)
- **Mapping:** Linear scaling where -5V → 0x0000, 0V → 0x8000, +5V → 0xFFFF

### Core Functions

#### Conversion Functions
- `voltage_to_digital(voltage: real) → std_logic_vector(15:0)`
  - Converts real voltage to 16-bit digital code with automatic clamping
- `digital_to_voltage(digital: std_logic_vector) → real`
  - Converts 16-bit digital code back to real voltage value

#### Scaling Operations
- `scale_voltage(voltage, scale_factor: real) → real`
  - Multiply voltage by scale factor with safety clamping
- `scale_digital_voltage(digital: slv, scale_factor: real) → std_logic_vector`
  - Scale digital voltage representation (converts to real, scales, converts back)
- `offset_voltage(voltage, offset: real) → real`
  - Add voltage offset with automatic clamping
- `apply_percentage_voltage(voltage, percentage: real) → real`
  - Apply percentage scaling (0-100% → 0.0-1.0 multiplier)

#### Validation Functions
- `is_voltage_safe(voltage: real) → boolean`
  - Returns true if voltage within [-5V, +5V] range
- `is_digital_safe(digital: slv) → boolean`
  - Returns true if digital value within valid range
- `is_scale_factor_safe(scale_factor: real) → boolean`
  - Returns true if scale factor within [0.1, 10.0] range

#### Safe Arithmetic
- `add_voltages_safe(v1, v2: real) → real`
  - Add two voltages with clamping to prevent overflow
- `subtract_voltages_safe(v1, v2: real) → real`
  - Subtract voltages with clamping

### Constants

**System Configuration:**
```vhdl
VOLTAGE_DATA_WIDTH : natural := 16      -- bits
VOLTAGE_REFERENCE  : real := 5.0        -- volts
VOLTAGE_MIN        : real := -5.0       -- volts
VOLTAGE_MAX        : real := 5.0        -- volts
DIGITAL_MAX        : natural := 65535   -- count
DIGITAL_MIN        : natural := 0       -- count
```

**Default Values:**
```vhdl
DEFAULT_VOLTAGE_ZERO : real := 0.0
DEFAULT_DIGITAL_ZERO : slv := x"0000"
DEFAULT_DIGITAL_MID  : slv := x"8000"   -- Corresponds to 0V
DEFAULT_DIGITAL_MAX  : slv := x"FFFF"
```

## Usage Example

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Moku_Voltage_pkg_en.all;

architecture example of my_module is
    signal voltage_value : real := 2.5;
    signal digital_code : std_logic_vector(15 downto 0);
    signal scaled_voltage : real;
begin
    -- Convert voltage to digital representation
    digital_code <= voltage_to_digital(voltage_value);

    -- Scale voltage by 50%
    scaled_voltage <= scale_voltage(voltage_value, 0.5);

    -- Validate before use
    if is_voltage_safe(voltage_value) then
        -- Safe to proceed
    end if;
end architecture;
```

## Unit Conventions

All functions include explicit unit documentation:
- **volts** - Real voltage values
- **bits** - Digital representation widths
- **ratio** - Scaling factors and percentages
- **signal** - Control/status signals
- **count** - Integer counter values

## Design Notes

### Tier 2 Compliance
This package follows **Tier 2 (Relaxed Data)** rules:
- ✅ Records allowed for data organization (though not used in current version)
- ✅ Complex constants and LUTs permitted
- ✅ No clock-dependent operations (all functions are combinational)
- ✅ Documented Verilog conversion strategy (linear scaling math)

### Safety Philosophy
All conversion and arithmetic operations include automatic clamping to prevent out-of-range values. Invalid scale factors cause functions to return the original value unchanged rather than propagating errors.

### Synthesizability
All functions are pure combinational logic suitable for synthesis. The package uses only:
- `real` type (synthesis tools convert to fixed-point)
- `std_logic_vector` and `unsigned` types
- Arithmetic operators supported by synthesis

## Integration Example

### EMFI_Seq_stair.vhd Integration
The stair-step DAC module uses this package to define voltage levels:

```vhdl
use work.Moku_Voltage_pkg_en.all;

-- Self-documenting voltage constants computed at compile time
constant V_1_1 : signed(15 downto 0) := signed(voltage_to_digital(1.1));
constant V_1_2 : signed(15 downto 0) := signed(voltage_to_digital(1.2));
constant V_1_3 : signed(15 downto 0) := signed(voltage_to_digital(1.3));
constant V_1_4 : signed(15 downto 0) := signed(voltage_to_digital(1.4));
```

This approach:
- Makes voltage values explicit and self-documenting
- Ensures consistency with package conversion algorithm
- Allows easy voltage level changes without manual code calculation

## Verification

**Testbench:** `tb/datadef/tb_Moku_Voltage_pkg_en.vhd`

The testbench verifies:
- Conversion accuracy (voltage ↔ digital)
- Clamping behavior at boundaries
- Scale factor validation logic
- Safe arithmetic operations
- Default constant values

## Related Files
- **Used by:** `core/EMFI_Seq_stair.vhd` - Stair-step DAC voltage output
- **Dependencies:** IEEE.NUMERIC_STD
- **Testbench:** `tb/datadef/tb_Moku_Voltage_pkg_en.vhd`

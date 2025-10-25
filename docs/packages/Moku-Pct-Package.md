# Moku_Pct_pkg - Type-Safe Percentage-to-Voltage Conversion

## Overview

`Moku_Pct_pkg` provides type-safe percentage (0-100) to voltage conversions for common voltage ranges used in Moku platform applications. It integrates tightly with `Moku_Voltage_pkg` for actual voltage-to-digital conversions.

**Location**: `modules/volo_common/common/Moku_Pct_pkg.vhd`

## Design Philosophy

- **Type Safety**: Each voltage range gets its own distinct subtype - compiler prevents mixing incompatible ranges
- **Intuitive Scaling**: 0% = range minimum, 100% = range maximum, 50% = midpoint
- **Linear Mapping**: Simple percentage-to-voltage calculation
- **Integration**: Leverages `Moku_Voltage_pkg` for all voltage-to-digital conversions

## Supported Voltage Ranges

### Unipolar Ranges (0V to +Vmax)
- **`pct_5v0_t`**: 0V to +5.0V (full Moku range)
- **`pct_3v3_t`**: 0V to +3.3V (common logic level)
- **`pct_2v5_t`**: 0V to +2.5V (common reference voltage)

### Bipolar Ranges (-Vmax to +Vmax)
- **`pct_bipolar_5v_t`**: -5.0V to +5.0V (full Moku range, centered at 0V)
- **`pct_bipolar_2v5_t`**: -2.5V to +2.5V (centered at 0V)

## Usage Examples

### Basic Usage

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Moku_Voltage_pkg.all;
use work.Moku_Pct_pkg.all;

entity probe_controller is
    port (
        clk : in std_logic;
        probe_level_pct : in std_logic_vector(6 downto 0);  -- 0-100 from register
        dac_output : out signed(15 downto 0)
    );
end entity;

architecture rtl of probe_controller is
    signal probe_level : pct_3v3_t;  -- Type-safe 3.3V percentage
begin
    -- Convert register input to typed percentage
    probe_level <= slv_to_pct(probe_level_pct);

    -- Convert percentage to digital code
    dac_output <= pct_3v3_to_digital(probe_level);

    -- Examples of specific percentages:
    -- 0%   (pct = 0)   → 0.0V  → 0x0000
    -- 50%  (pct = 50)  → 1.65V → 0x54EB (approx)
    -- 100% (pct = 100) → 3.3V  → 0x54EB
end architecture;
```

### Type Safety in Action

```vhdl
signal level_3v3 : pct_3v3_t := 50;   -- 50% of 3.3V = 1.65V
signal level_5v0 : pct_5v0_t := 75;   -- 75% of 5.0V = 3.75V
signal dac_out : signed(15 downto 0);

-- ✅ This works (correct type):
dac_out <= pct_3v3_to_digital(level_3v3);

-- ❌ This FAILS at compile time (type mismatch):
dac_out <= pct_5v0_to_digital(level_3v3);
-- Error: expected type "pct_5v0_t", got "pct_3v3_t"

-- ✅ Explicit conversion required for advanced users:
level_5v0 <= pct_5v0_t(level_3v3);  -- Allowed but explicit
```

### Bipolar Range Example

```vhdl
signal sweep_pct : pct_bipolar_5v_t;  -- -5V to +5V range
signal dac_bipolar : signed(15 downto 0);

-- Sweep from -5V to +5V
process(clk)
begin
    if rising_edge(clk) then
        if sweep_pct < 100 then
            sweep_pct <= sweep_pct + 1;
        else
            sweep_pct <= 0;
        end if;
    end if;
end process;

-- Convert to digital
dac_bipolar <= pct_bipolar_5v_to_digital(sweep_pct);

-- Mapping:
-- pct = 0   → -5.0V  → 0x8000 (-32768)
-- pct = 50  → 0.0V   → 0x0000 (0)
-- pct = 100 → +5.0V  → 0x7FFF (+32767)
```

### Reverse Conversion (Digital → Percentage)

```vhdl
signal adc_input : signed(15 downto 0);
signal measured_pct : pct_3v3_t;

-- Convert ADC reading back to percentage
measured_pct <= digital_to_pct_3v3(adc_input);

-- If adc_input = 0x54EB (≈1.65V), then measured_pct ≈ 50
```

## Function Reference

### Forward Conversion (Percentage → Digital)

| Function | Input Type | Output | Range Mapping |
|----------|------------|--------|---------------|
| `pct_5v0_to_digital()` | `pct_5v0_t` | `signed(15:0)` | 0% → 0V, 100% → 5.0V |
| `pct_3v3_to_digital()` | `pct_3v3_t` | `signed(15:0)` | 0% → 0V, 100% → 3.3V |
| `pct_2v5_to_digital()` | `pct_2v5_t` | `signed(15:0)` | 0% → 0V, 100% → 2.5V |
| `pct_bipolar_5v_to_digital()` | `pct_bipolar_5v_t` | `signed(15:0)` | 0% → -5V, 50% → 0V, 100% → +5V |
| `pct_bipolar_2v5_to_digital()` | `pct_bipolar_2v5_t` | `signed(15:0)` | 0% → -2.5V, 50% → 0V, 100% → +2.5V |

### Reverse Conversion (Digital → Percentage)

| Function | Input Type | Output | Range Mapping |
|----------|------------|--------|---------------|
| `digital_to_pct_5v0()` | `signed(15:0)` | `pct_5v0_t` | 0V → 0%, 5.0V → 100% |
| `digital_to_pct_3v3()` | `signed(15:0)` | `pct_3v3_t` | 0V → 0%, 3.3V → 100% |
| `digital_to_pct_2v5()` | `signed(15:0)` | `pct_2v5_t` | 0V → 0%, 2.5V → 100% |
| `digital_to_pct_bipolar_5v()` | `signed(15:0)` | `pct_bipolar_5v_t` | -5V → 0%, 0V → 50%, +5V → 100% |
| `digital_to_pct_bipolar_2v5()` | `signed(15:0)` | `pct_bipolar_2v5_t` | -2.5V → 0%, 0V → 50%, +2.5V → 100% |

### Utility Functions

| Function | Description |
|----------|-------------|
| `pct_to_slv(pct : natural)` | Convert percentage to 7-bit std_logic_vector |
| `slv_to_pct(slv : std_logic_vector(6:0))` | Convert 7-bit std_logic_vector to percentage |
| `is_valid_pct(pct : natural)` | Check if percentage is in valid range (0-100) |
| `clamp_pct(pct : natural)` | Clamp percentage to 0-100 range |

## Voltage Calculation Formulas

### Unipolar Ranges
```vhdl
-- 0V to +5.0V
voltage = pct * 0.05  -- (5.0V / 100)

-- 0V to +3.3V
voltage = pct * 0.033  -- (3.3V / 100)

-- 0V to +2.5V
voltage = pct * 0.025  -- (2.5V / 100)
```

### Bipolar Ranges
```vhdl
-- -5.0V to +5.0V (10V span)
voltage = -5.0 + (pct * 0.1)  -- (10.0V / 100)

-- -2.5V to +2.5V (5V span)
voltage = -2.5 + (pct * 0.05)  -- (5.0V / 100)
```

## Adding New Voltage Ranges

To add a new voltage range (e.g., 1.8V):

1. **Add subtype** to package declaration:
```vhdl
subtype pct_1v8_t is natural range 0 to 100;
```

2. **Add forward conversion function** declaration:
```vhdl
function pct_1v8_to_digital(pct : pct_1v8_t) return signed;
```

3. **Add reverse conversion function** declaration:
```vhdl
function digital_to_pct_1v8(digital : signed(15 downto 0)) return pct_1v8_t;
```

4. **Implement forward conversion** in package body:
```vhdl
function pct_1v8_to_digital(pct : pct_1v8_t) return signed is
    variable voltage : real;
begin
    voltage := real(pct) * 0.018;  -- 0.018 = 1.8V / 100
    return voltage_to_digital(voltage);
end function;
```

5. **Implement reverse conversion** in package body:
```vhdl
function digital_to_pct_1v8(digital : signed(15 downto 0)) return pct_1v8_t is
    variable voltage : real;
    variable pct : integer;
begin
    voltage := digital_to_voltage(digital);
    pct := integer(voltage / 0.018 + 0.5);  -- Round to nearest
    return clamp_pct(pct);
end function;
```

**That's it!** 4 lines per new range. Simple, explicit, and maintainable.

## Design Tradeoffs

### Why Not Generic Packages?
- **Type safety**: Generic packages don't provide distinct types (subtypes are still compatible)
- **Toolchain compatibility**: Some synthesis tools struggle with generic packages
- **Verilog portability**: Generic packages don't map cleanly to Verilog
- **Clarity**: Explicit ranges are easier to understand and debug

### Why Not LUTs?
- **Compile-time computation**: Functions are evaluated during synthesis (no runtime cost)
- **Memory efficiency**: No LUT storage required
- **Accuracy**: Full precision voltage calculations
- **Simplicity**: Fewer moving parts, easier to verify

## Verilog Conversion Strategy

### Subtypes
VHDL subtypes map to simple integer ranges in Verilog:
```verilog
// VHDL: subtype pct_3v3_t is natural range 0 to 100;
// Verilog:
integer pct;  // 0-100 (rely on naming conventions for range tracking)
```

### Functions
VHDL functions can be converted to Verilog functions or inline expressions:
```verilog
// VHDL: voltage := real(pct) * 0.033;
// Verilog:
voltage = pct * 0.033;
```

**Note**: Type safety is lost in Verilog conversion - must rely on naming conventions.

## Testing

See `tests/test_moku_pct_pkg.py` for CocotB-based tests covering:
- All voltage ranges (unipolar and bipolar)
- Boundary conditions (0%, 50%, 100%)
- Round-trip conversions (pct → digital → pct)
- Type safety verification
- Clamping behavior

## Integration with Moku Platform

### Register Interface Pattern
```vhdl
-- Control0 register bits 6:0 hold percentage (0-100)
signal ctrl0_pct : pct_3v3_t;

ctrl0_pct <= slv_to_pct(Control0(6 downto 0));
OutputA <= pct_3v3_to_digital(ctrl0_pct);
```

### Status Readback Pattern
```vhdl
-- Status0 register bits 6:0 report current percentage
signal current_pct : pct_5v0_t;
signal adc_value : signed(15 downto 0);

current_pct <= digital_to_pct_5v0(adc_value);
Status0(6 downto 0) <= pct_to_slv(current_pct);
```

## See Also

- `Moku_Voltage_pkg.vhd` - Underlying voltage-to-digital conversion
- `Moku-Voltage-LUTS.md` - Moku platform voltage specifications
- `tests/test_moku_pct_pkg.py` - CocotB test suite

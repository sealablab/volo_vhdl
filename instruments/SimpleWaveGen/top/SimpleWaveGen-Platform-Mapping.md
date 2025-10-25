# SimpleWaveGen Platform Interface Mapping

## Overview
This document specifies the mapping between the MCC platform Control registers (defined in `mcc-Top.vhd`) and the SimpleWaveGen core signals.

## Platform Control Register Interface

### MCC CustomWrapper Entity (`mcc-Top.vhd`)
```vhdl
entity CustomWrapper is
    port (
        -- Clock and Reset
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        
        -- Input signals
        InputA  : in  signed(15 downto 0);
        InputB  : in  signed(15 downto 0);
        InputC  : in  signed(15 downto 0);
        
        -- Output signals
        OutputA : out signed(15 downto 0);
        OutputB : out signed(15 downto 0);
        OutputC : out signed(15 downto 0);
        
        -- Control registers (32-bit each)
        Control0  : in  std_logic_vector(31 downto 0);
        Control1  : in  std_logic_vector(31 downto 0);
        Control2  : in  std_logic_vector(31 downto 0);
        -- ... Control3 through Control15 (unused)
    );
end entity;
```

## Signal Mapping

### Control0 Register → WaveGen Control
| Bit Range | Purpose | Description |
|-----------|---------|-------------|
| `[31]` | Global Enable | `'1'` = Enable SimpleWaveGen, `'0'` = Disable |
| `[23:20]` | Clock Divider Selection | 4-bit value for clock division (0=div1, 1=div2, ..., 15=div16) |
| `[19:0]` | Reserved | Unused, set to `'0'` |

### Control1 Register → Wave Selection (Safety Critical)
| Bit Range | Purpose | Description |
|-----------|---------|-------------|
| `[2:0]` | Wave Type Selection | 3-bit wave type selection |
| | `"000"` | Square wave |
| | `"001"` | Triangle wave |
| | `"010"` | Sine wave |
| | `"011"-"111"` | Invalid (triggers fault) |
| `[31:3]` | Reserved | Unused, set to `'0'` |

### Control2 Register → Amplitude Scale
| Bit Range | Purpose | Description |
|-----------|---------|-------------|
| `[15:0]` | Amplitude Scale | 16-bit amplitude scaling factor |
| | `0x0000` | Zero amplitude |
| | `0x8000` | Unity scaling (default) |
| | `0xFFFF` | Maximum scaling |
| `[31:16]` | Reserved | Unused, set to `'0'` |

## Output Mapping

### SimpleWaveGen Outputs → Platform Outputs
| Platform Output | SimpleWaveGen Signal | Description |
|----------------|----------------------|-------------|
| `OutputA` | `wave_out` | 16-bit signed waveform output |
| `OutputB` | `wavegen_status_rd[15:0]` | WaveGen status (enabled bit) |
| `OutputC` | `fault_status_rd[15:0]` | Fault status (fault bit) |

## Safety Features

### Wave Selection Validation
- **Safety Critical**: Wave selection must be valid for safe operation
- **Validation**: Only values `"000"`, `"001"`, `"010"` are accepted
- **Fault Response**: Invalid selections trigger `fault_out` and maintain last valid selection
- **Continuous Monitoring**: Validation occurs on every clock cycle

### Parameter Bounds
- **Clock Divider**: All 4-bit values (0-15) are valid
- **Amplitude Scale**: All 16-bit values are valid (no bounds checking required)

## Usage Example

### Setting Up SimpleWaveGen
```vhdl
-- Enable module and set clock divider to divide by 4
Control0 <= x"80000004";  -- Bit 31='1' (enable), Bits 23:20="0100" (div4)

-- Select triangle wave
Control1 <= x"00000001";  -- Bits 2:0="001" (triangle)

-- Set amplitude to 50% (0x4000)
Control2 <= x"00004000";  -- Bits 15:0=0x4000
```

### Reading Status
```vhdl
-- Check if module is enabled
if OutputB(0) = '1' then
    -- Module is enabled
end if;

-- Check for faults
if OutputC(0) = '1' then
    -- Fault detected
end if;
```

## Implementation Notes

- **Direct Connection**: No write enable logic required - signals are directly mapped
- **Synchronous Operation**: All changes take effect on the next clock edge
- **Reset Behavior**: All registers reset to safe default values
- **Fault Propagation**: Faults are immediately reflected in `fault_status_rd` and `OutputC`

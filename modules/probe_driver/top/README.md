# Probe Driver Top Layer

This directory contains the top-level integration modules for the ProbeDriver system.

## Module Structure

### `probe_driver_interface.vhd`
- **Purpose**: Main interface module that implements the ProbeDriver functionality
- **Usage**: This module is designed to be instantiated by the vendor's CustomWrapper
- **Compilation**: Can be compiled with GHDL for local testing

### `CustomWrapper_example.vhd`
- **Purpose**: Example showing how the vendor's CustomWrapper would instantiate our interface
- **Usage**: Reference only - demonstrates the integration pattern
- **Compilation**: Should NOT be compiled with vendor tools (they provide their own CustomWrapper)

## Compilation Strategy

### For Local GHDL Testing
Compile only the interface module, not the CustomWrapper:

```bash
# Compile packages first
ghdl -a --std=08 ../common/*.vhd
ghdl -a --std=08 ../datadef/*.vhd

# Compile the interface module
ghdl -a --std=08 probe_driver_interface.vhd

# Compile testbenches (if available)
ghdl -a --std=08 ../tb/**/*.vhd

# Elaborate and run tests
ghdl -e --std=08 <testbench_entity_name>
ghdl -r --std=08 <testbench_entity_name>
```

### For Vendor Compilation
- The vendor's compiler package automatically provides the `CustomWrapper` entity
- Only compile `probe_driver_interface.vhd` as a component
- The vendor's CustomWrapper will instantiate our interface module

## Register Layout

### Control0 Register
- **Bit 31**: Global nEnable (inverted enable signal)
- **Bit 23**: Soft trigger input
- **Bits 22-16**: 7-bit intensity index
- **Other bits**: Reserved

### Control1 Register
- **Bits 31-16**: 16-bit unsigned duration
- **Other bits**: Reserved

## Integration Notes

1. **No CustomWrapper Definition**: Our code does not define CustomWrapper to avoid conflicts with the vendor's compiler package
2. **Interface Module**: `probe_driver_interface` provides all the functionality that CustomWrapper needs
3. **Flat Ports**: All interfaces use flat signal types for Verilog compatibility
4. **Synchronous Design**: All logic is synchronous with proper reset handling

## Testing

For local testing, create testbenches that instantiate `probe_driver_interface` directly rather than CustomWrapper. This allows full GHDL compatibility while maintaining the same functionality.
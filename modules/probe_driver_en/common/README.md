# Probe Driver Common Packages

This directory contains shared packages and utilities used across the ProbeDriver system.

## Package Overview

### `probe_driver_pkg.vhd`
- **Purpose**: Core probe driver constants, types, and utility functions
- **Contains**: System constants, state encoding, data width definitions, and utility functions
- **Usage**: Used by core logic, top-level integration, and testbenches

### `platform_interface_pkg.vhd`
- **Purpose**: Platform interface configuration and constants
- **Contains**: Control register bit positions, default values, and interface constants
- **Usage**: Used by CustomWrapper implementations and platform interface modules

## Architecture Separation

The common packages follow a clear separation of concerns:

```
┌─────────────────────────────────────┐
│ CustomWrapper (Moku Platform)      │ ← Platform Interface
├─────────────────────────────────────┤
│ platform_interface_pkg.vhd         │ ← Platform constants & mapping
├─────────────────────────────────────┤
│ probe_driver_top.vhd               │ ← Module Integration (our "top")
├─────────────────────────────────────┤
│ probe_driver_core.vhd              │ ← Core Logic
└─────────────────────────────────────┘
```

**Benefits of this separation:**
- **`probe_driver_pkg`**: Core logic constants that are platform-independent
- **`platform_interface_pkg`**: Platform-specific configuration that can be easily modified
- **Clear boundaries**: Changes to platform interface don't affect core logic
- **Easy testing**: Core logic can be tested without platform dependencies

## Usage Guidelines

### For Core Logic
- Use `probe_driver_pkg` for system constants and utility functions
- Avoid platform-specific constants in core modules

### For Platform Interface
- Use `platform_interface_pkg` for control register definitions
- Keep platform-specific logic separate from core functionality

### For Testbenches
- Import both packages as needed
- Test core logic independently of platform interface

## Compilation Order

When compiling, ensure packages are compiled in dependency order:

```bash
# 1. Compile common packages first
ghdl -a --std=08 common/*.vhd

# 2. Compile datadef packages
ghdl -a --std=08 datadef/*.vhd

# 3. Compile core modules
ghdl -a --std=08 core/*.vhd

# 4. Compile top-level modules
ghdl -a --std=08 top/*.vhd
```

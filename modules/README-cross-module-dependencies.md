# Cross-Module Dependencies Solution

## Problem Solved ✅

The hierarchical makefile system now successfully handles cross-module dependencies. The `probe_driver_top.vhd` file can now reference `clk_divider_core` from the `clk_divider` module without compilation errors.

## Solution: Unified Work Library Approach

### How It Works

1. **Unified Compilation**: All modules are compiled into a single GHDL work library at the `modules/` level
2. **Dependency Order**: Shared modules (like `clk_divider`) are compiled first
3. **Cross-Module References**: Dependent modules can reference entities from shared modules using `entity work.module_name`

### Configuration

The dependency system is configured in `Makefile.deps`:

```makefile
# Define which modules should be compiled as shared libraries
SHARED_MODULES = clk_divider

# Define the build order (modules will be built in this order)
MODULE_BUILD_ORDER = clk_divider probe_driver
```

### Build Process

When you run `make` from the `modules/` directory:

1. **MCC Template**: Compiles the MCC template first
2. **Shared Modules**: Compiles `clk_divider` (common, datadef, core layers)
3. **Dependent Modules**: Compiles `probe_driver` (all layers including top)
4. **Cross-Module References**: `probe_driver_top.vhd` can now reference `clk_divider_core`

### Verification

The work library (`work-obj08.cf`) now contains both modules:

```
clk_divider_core at 5( 138) + 0 on 13;
probe_driver_top at 11( 437) + 0 on 28;
```

This proves that `probe_driver_top` compiled successfully with its reference to `clk_divider_core`.

## Usage Examples

### Build All Modules with Dependencies
```bash
cd modules/
make clean && make compile
```

### Build Individual Modules (still works)
```bash
cd modules/probe_driver/
make compile-basic
```

### Build from Testbench Directory (still works)
```bash
cd modules/probe_driver/tb/
make clean
```

## Benefits

1. **✅ Cross-Module Dependencies**: Modules can reference each other
2. **✅ General-Purpose Modules**: `clk_divider` remains standalone and reusable
3. **✅ Hierarchical Building**: Still works from any directory level
4. **✅ No Code Duplication**: All logic remains centralized
5. **✅ Backward Compatibility**: Individual module building still works

## Adding New Cross-Module Dependencies

To add a new module that depends on existing modules:

1. **Add to Makefile.deps**:
   ```makefile
   MODULE_DEPS_new_module = clk_divider existing_module
   MODULE_BUILD_ORDER = clk_divider existing_module new_module
   ```

2. **Reference in VHDL**:
   ```vhdl
   -- In new_module/top/some_file.vhd
   CLK_DIV: entity work.clk_divider_core
       port map (
           clk => clk,
           rst_n => rst_n,
           -- ... other ports
       );
   ```

3. **Build**: Run `make` from `modules/` directory

## Architecture

```
modules/
├── Makefile                    # Central makefile with dependency logic
├── Makefile.deps              # Dependency configuration (optional)
├── work-obj08.cf              # Unified work library
├── clk_divider/               # Shared module (built first)
│   └── core/clk_divider_core.vhd
└── probe_driver/              # Dependent module
    └── top/probe_driver_top.vhd  # References clk_divider_core
```

## Future Enhancements

1. **Automatic Dependency Detection**: Could scan VHDL files for `entity work.` references
2. **Incremental Builds**: Only rebuild modules when dependencies change
3. **Shared Library Directory**: Could create a dedicated shared library directory
4. **Dependency Visualization**: Could generate dependency graphs

## Notes

- The current error in testbench files is unrelated to cross-module dependencies
- Individual module compilation still works for development
- The unified work library approach is simple and effective
- No changes needed to existing VHDL code
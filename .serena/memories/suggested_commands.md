# Suggested Commands for Development

## Build Commands

### Centralized Build (from `modules/` directory)
```bash
# Build all modules with dependency resolution
cd modules
make clean && make compile && make test

# List all available modules
make list-modules

# Build specific module only
make compile-single-module MODULE_NAME=SimpleWaveGen
```

### Module-Level Build (from `modules/<module_name>/` directory)
```bash
# Navigate to module directory
cd modules/<module_name>

# Clean, compile, and test
make clean && make && make test

# Run specific testbench
make test-<testbench_name>

# Show help for available targets
make help
```

## GHDL Commands (Manual Compilation)
```bash
# Analyze VHDL source (always use --std=08)
ghdl -a --std=08 <filename>.vhd

# Elaborate entity
ghdl -e --std=08 <entity_name>

# Run simulation
ghdl -r --std=08 <entity_name>

# Run with waveform output
ghdl -r --std=08 <entity_name> --wave=<output>.ghw
```

## Git Commands
```bash
# Check status
git status

# View recent commits
git log --oneline -10

# Create new branch
git checkout -b feature/<branch-name>

# Stage and commit
git add <files>
git commit -m "message"

# Push to remote
git push origin <branch-name>
```

## Darwin-Specific Commands
```bash
# List files (macOS version)
ls -la

# Search files
find . -name "*.vhd"

# Search content in files
grep -r "pattern" .

# Change directory
cd <path>

# Show current directory
pwd

# Check system information
uname -a
```

## File Operations
```bash
# View file content
cat <filename>
head -n 20 <filename>
tail -n 20 <filename>

# Count lines
wc -l <filename>

# Find files by pattern
find modules/ -name "*_tb.vhd"
```

## Testing Commands
```bash
# From module directory - run all tests
make test

# Run quick test (main testbench only)
make quick-test

# Run specific testbench
make test-<testbench_name>
# Example: make test-probe_driver_interface
```

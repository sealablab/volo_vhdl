# AI Workflow and System Information

## AI-Powered Development Workflow

The project features a comprehensive AI-assisted development workflow located in `ai-workflow/`.

### Workflow Phases
1. **Interface Definition**: AI-guided requirements refinement and interface specification
2. **Code Generation**: Automated VHDL generation from refined requirements
3. **Validation**: Automated testing and standards compliance checking

### Key Directories
- `ai-workflow/prompts/` - AI prompts for different development phases
- `ai-workflow/templates/` - Input form templates for requirements
- `ai-workflow/examples/` - Complete workflow examples
- `ai-workflow/ng/` - Next-generation structured tips and patterns
  - `README-synth-vhdl-tips-ng.md` - Synthesizable VHDL patterns
  - `README-ghdl-testbench-tips-ng.md` - GHDL testbench patterns
  - `README-layered-testbench-ng.md` - 4-layer testbench architecture

### Important Rules for AI Agents
- **Do NOT reorganize** the main bodies of `ng/README-*-tips-ng.md` files
- **Only append** new tips below the `------- New Tips here-------` marker
- **Use the schema**: Problem / Cause / Solution / Pattern / Tags
- **Document thoroughly**: Long context goes in HTML comments

## Darwin (macOS) System Information

### Platform Details
- **OS**: Darwin (macOS)
- **Kernel**: Darwin Kernel Version 25.0.0
- **Architecture**: ARM64 (Apple Silicon - M1/M2 series)
- **Machine Type**: arm64

### Standard Unix Tools
Darwin includes standard Unix tools with some macOS-specific differences:

#### File Operations
```bash
ls          # List files (BSD version, not GNU)
ls -la      # List all files with details
find        # Find files (BSD version)
grep        # Search text (BSD version)
sed         # Stream editor
awk         # Text processing
cat         # Concatenate files
head        # Show first lines
tail        # Show last lines
```

#### Directory Operations
```bash
pwd         # Print working directory
cd          # Change directory
mkdir       # Create directory
rmdir       # Remove empty directory
rm -rf      # Remove directory recursively
```

#### Development Tools
```bash
make        # GNU Make 3.81 (located at /usr/bin/make)
git         # Git version control
ghdl        # GHDL 5.0.1 (located at /opt/homebrew/bin/ghdl)
```

#### System Information
```bash
uname -a    # System information
which       # Find command location
hostname    # Show hostname
top         # Process monitor
ps          # Process status
```

#### Text Search and Processing
```bash
# Search for pattern in files (BSD grep)
grep -r "pattern" .

# Search with extended regex
grep -E "pattern" file

# Case-insensitive search
grep -i "pattern" file

# Find files by name
find . -name "*.vhd"

# Find files and execute command
find . -name "*.vhd" -exec cat {} \;
```

### macOS-Specific Notes
1. **Case Sensitivity**: macOS filesystem is typically case-insensitive but case-preserving
2. **BSD vs GNU**: Many command-line tools are BSD versions, not GNU
   - `grep` is BSD grep (slightly different options than GNU grep)
   - `sed` is BSD sed (some syntax differences from GNU sed)
3. **Homebrew**: Many development tools installed via Homebrew (`/opt/homebrew/`)
4. **Extended Attributes**: macOS uses extended attributes (can see with `ls -l@`)

## Important Configuration Files

### Source of Truth Documents
Always consult these before making changes:
1. **`.cursor/rules.mdc`** - Complete coding standards and architecture rules
2. **`CLAUDE.md`** - Claude Code guidance and project overview
3. **`AGENTS.md`** - Concise agent guidelines and build commands
4. **`ai-workflow/ng/README-synth-vhdl-tips-ng.md`** - Synthesizable VHDL patterns
5. **`ai-workflow/ng/README-ghdl-testbench-tips-ng.md`** - GHDL testbench patterns
6. **`ai-workflow/ng/README-layered-testbench-ng.md`** - 4-layer testbench architecture

### Build Configuration
- **`modules/Makefile`** - Central build system
- **`modules/Makefile.deps`** - Module dependency definitions
- **`modules/Makefile.shared`** - Shared Makefile rules
- **`modules/<module>/Makefile`** - Module-specific build rules

## Working Example Reference
**SimpleWaveGen** (`modules/SimpleWaveGen/`) is a complete, tested reference implementation:
- Successfully deployed to Moku device
- Demonstrates full workflow from GHDL testing to bitstream
- Includes all layers: common, core, top, testbenches
- See `GHDL-to-MCC-example.md` for development journey

## Quick Reference Commands

### Start New Module Development
```bash
# 1. Create module directory structure
cd modules
mkdir -p new_module/{common,datadef,core,top,tb/{common,datadef,core,top}}

# 2. Copy Makefile template
cp SimpleWaveGen/Makefile new_module/

# 3. Edit Makefile for new module name

# 4. Start development following layer structure
```

### Build and Test Workflow
```bash
# From module directory
cd modules/new_module

# Clean and compile
make clean && make

# Run tests
make test

# Run specific testbench
make test-<testbench_name>
```

### AI Workflow Usage
```bash
# 1. Copy requirements template
cp ai-workflow/templates/requirements/BLANK-requirements-template.md my-module-reqs.md

# 2. Fill in requirements

# 3. Use AI prompts from ai-workflow/prompts/ to refine and generate code

# 4. Follow 4-layer testbench architecture
```

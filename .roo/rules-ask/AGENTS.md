# Project Documentation Rules (Non-Obvious Only)

## Key Documentation Sources
- `ai-workflow/ng/README-synth-vhdl-tips-ng.md` - Synthesizable VHDL patterns
- `ai-workflow/ng/README-ghdl-testbench-tips-ng.md` - GHDL testbench patterns
- `ai-workflow/ng/README-layered-testbench-ng.md` - 4-layer testbench architecture

## Project Structure Context
- Module structure follows strict layering: common → datadef → core → top
- Testbenches mirror module structure in tb/ subdirectories
- Direct instantiation required in top/ layer files
- Shared modules (like clk_divider) are built first and used as dependencies

## Non-Obvious Conventions
- Signal prefixes indicate purpose: `ctrl_*`, `cfg_*`, `stat_*`
- Control priority follows strict hierarchy: `reset > clock_enable > enable`
- Testbenches must implement all 4 layers of the layered architecture
- New tips must be appended below `------- New Tips here-------` in reference files
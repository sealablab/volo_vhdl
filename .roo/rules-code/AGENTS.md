# Project Coding Rules (Roo Context)

## 📚 Primary Source: Serena MCP Memory System

All coding standards and guidelines are maintained in **Serena MCP** at `.serena/memories/`.

**Key Memories:**
- `coding_standards` - VHDL rules and tiered system
- `design_patterns` - Implementation patterns
- `cocotb_testing_guide` - Testing framework (CocotB standard)

## ⚡ Quick Reference (Critical Only)

### VHDL-2008 Requirements
- Always use `--std=08` flag with GHDL
- Use direct instantiation in top-level modules (no component declarations)
- Follow signal priority: `reset > clock_enable > enable`

### Signal Naming
- `ctrl_*` - Control signals
- `cfg_*` - Configuration parameters
- `stat_*` - Status and monitoring

### Testing
- **Current Standard**: CocotB (Python-based)
- **Location**: `tests/` directory
- **⚠️ DO NOT**: Create new GHDL testbenches (deprecated)

## 📖 For Complete Details

Run `mcp__serena__read_memory` with memory name or see `CLAUDE.md` for overview.

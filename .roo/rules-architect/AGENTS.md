# Project Architecture Rules (Roo Context)

## 📚 Primary Source: Serena MCP Memory System

All architecture guidelines and patterns are maintained in **Serena MCP** at `.serena/memories/`.

**Key Memories:**
- `codebase_structure` - Module organization
- `design_patterns` - Architecture patterns and implementations
- `coding_standards` - Tiered rule system

## ⚡ Quick Reference (Critical Only)

### Module Layer Hierarchy
- **Tier 1** (Strict RTL): `common/`, `core/`, `top/` - Verilog portability required
- **Tier 2** (Relaxed Data): `datadef/` - Records allowed, document conversion
- **Tier 3** (Full VHDL-2008): `tb/` - No constraints (testing only)

### Key Requirements
- Direct instantiation in `top/` layer (no component declarations)
- Signal priority: `reset > clock_enable > enable`
- Status register bits: FAULT=7, ALARM=6 (sticky)

### Testing Architecture
- **Current**: CocotB Python tests in `tests/` directory
- **Reference**: `tests/test_clk_divider_core.py`

## 📖 For Complete Details

Run `mcp__serena__read_memory` with memory name or see `CLAUDE.md` for overview.

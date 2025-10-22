# Project Documentation (Roo Context)

## 📚 Primary Source: Serena MCP Memory System

All project documentation and knowledge is maintained in **Serena MCP** at `.serena/memories/`.

**Available Memories:**
- `project_overview` - High-level project info
- `codebase_structure` - Directory organization
- `coding_standards` - VHDL rules
- `design_patterns` - Common patterns
- `cocotb_testing_guide` - Testing framework
- `ghdl_patterns_and_solutions` - Legacy GHDL tips (deprecated)
- `tech_stack` - Tools and versions

## 🔍 How to Get Information

### Check Available Memories
```
mcp__serena__list_memories
```

### Read Specific Memory
```
mcp__serena__read_memory memory_name
```

### Start Fresh
See "Fresh Context Window Checklist" in `CLAUDE.md`

## ⚡ Quick Answers

### Module Structure
- `common/` - Shared utilities
- `datadef/` - Data structures (Tier 2)
- `core/` - Pure logic (Tier 1)
- `top/` - Platform integration (Tier 1)
- `tb/` - Testbenches (deprecated GHDL) or `tests/` (CocotB standard)

### Testing
- **Current**: CocotB in `tests/` directory
- **Commands**: `cd tests && make TEST_MODULE=module_name`
- **Reference**: `tests/test_clk_divider_core.py`

## 📖 For Complete Details

Run `mcp__serena__read_memory` with memory name or see `CLAUDE.md` for overview.

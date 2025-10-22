# AI Workflow Directory Archival - 2025-10-22

## Reason for Archival

This directory contains documentation and prompts from an earlier iteration of the VOLO VHDL development workflow. As of 2025-10-22, the project has migrated to a **Serena-first knowledge architecture**, making this legacy documentation obsolete.

## What Was Archived

### Directory Structure
```
ai-workflow/
├── ng/
│   ├── README-VOLO-STATES.md               # OUTDATED - State pattern not used
│   ├── README-synth-vhdl-tips-ng.md        # ACCURATE but redundant
│   ├── README-multiple-driver-prevention-ng.md  # MIXED - Patterns rarely used
│   └── (other files...)
└── (other subdirectories...)
```

### Analysis of Key Files

**README-VOLO-STATES.md** (OUTDATED):
- Describes RESET/READY/IDLE/FAULT state pattern
- **Status**: No modules in the codebase use this pattern
- Actual modules use simpler patterns (one-hot encoding, direct state machines)
- Verified by examining: EMFI_Seq_fsm.vhd, clk_divider_core.vhd

**README-synth-vhdl-tips-ng.md** (ACCURATE but redundant):
- Contains valid VHDL patterns (latch prevention, signal priority, named association)
- **Status**: All valuable content already captured in Serena's `coding_standards.md`
- Priority hierarchy (reset > clock_enable > enable) confirmed in actual code
- Pattern examples verified in clk_divider_core.vhd

**README-multiple-driver-prevention-ng.md** (MIXED):
- Describes combinational process patterns for status register handling
- **Status**: Most modules use single synchronous process pattern instead
- Combinational process approach rarely used in actual codebase
- Core patterns already covered in Serena's `coding_standards.md`

## Current Source of Truth

As of 2025-10-22, the **authoritative coding standards** are maintained in:

1. **Serena Memories** (MCP-based knowledge system):
   - `coding_standards.md` - Tiered VHDL rules, naming conventions, FSM patterns
   - `design_patterns.md` - Common patterns and implementations
   - `cocotb_testing_guide.md` - Testing framework
   - `ghdl_patterns_and_solutions.md` - Build and test patterns

2. **Project Documentation**:
   - `CLAUDE.md` - Project overview and quick reference
   - `AGENTS.md` - Build commands and agent guidelines
   - `.cursor/rules.mdc` - Points to Serena memories (source of truth)

## Why Serena-First?

The migration to Serena-first architecture provides:
- **Single source of truth**: No conflicting documentation
- **AI-friendly format**: Serena memories optimized for AI agent consumption
- **Active maintenance**: Memories updated as codebase evolves
- **Symbolic code access**: Serena provides intelligent code navigation
- **Reduced duplication**: One memory instead of multiple scattered files

## Migration History

- **2025-01-22**: Original AI workflow directory created
- **2025-10-22**: Serena-first architecture adopted
- **2025-10-22**: AI workflow directory archived (this archival)

## What Happens to This Content?

All valuable patterns from ai-workflow/ have been:
1. **Preserved** in Serena memories (`coding_standards.md`, `design_patterns.md`)
2. **Verified** against actual codebase implementations
3. **Updated** to reflect current project patterns

This archive is maintained for historical reference only.

## References Removed

The following references were removed during archival:
- **Serena Memory**: `ai_workflow_and_system_info.md` (deleted)
- **CLAUDE.md**: 5 references to ai-workflow paths (removed)
- **Other Serena Memories**: Updated to remove ai-workflow pointers

---

**For current coding standards, consult Serena memories or CLAUDE.md**

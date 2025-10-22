# Serena MCP Integration - AI Workflow Documentation

**Date**: 2025-01-21
**Status**: Active

## Overview

The Volo VHDL project now uses the **Serena MCP (Model Context Protocol)** memory system to provide AI agents with searchable, context-aware access to project knowledge. This enhances AI-assisted development by allowing agents to learn from past patterns and solutions.

## What is Serena MCP?

Serena is an MCP server that provides:
- **Persistent memory** across AI conversations
- **Semantic search** of code patterns and solutions
- **Symbol-aware navigation** of the codebase
- **Project-specific knowledge** that improves over time

## Available Memories

The following memories have been created for this project:

### 1. `ghdl_patterns_and_solutions`
**Comprehensive GHDL reference integrating:**
- GHDL compilation patterns and settings
- Common compilation errors and solutions
- Direct instantiation patterns (MANDATORY for top-level files)
- Testbench design patterns and best practices
- Debugging techniques
- Success patterns from real implementations

**Source Materials:**
- `ai-workflow/README-ghdl-testbench-tips.md` (560 lines)
- `ai-workflow/README-direct-instantiation.md` (297 lines)
- EMFI-Seq voltage package development errors (2025-01-21)

**Key Content:**
- 7+ compilation errors with solutions
- Direct instantiation mandatory patterns
- Complete testbench templates
- Real number comparison patterns
- Clock/timing management
- Process organization best practices

### 2. `coding_standards`
**VHDL-2008 with Verilog portability rules**
- Tiered rule system (Tier 1/2/3)
- Signal naming conventions
- FSM implementation patterns
- Status register standards
- 4-layer testbench architecture

### 3. `design_patterns`
**Architectural patterns and templates**
- MCC integration patterns (Pattern 1 vs Pattern 2)
- Platform interface package patterns
- Module organization standards

### 4. `codebase_structure`
**Project layout and organization**
- Module directory structure
- Layer responsibilities (common/datadef/core/top/tb)
- Build system organization

### 5. `project_overview`
**High-level project information**
- Volo VHDL project goals
- Target platforms (Moku devices)
- Development philosophy

### 6. `tech_stack`
**Tools and technologies**
- GHDL for simulation
- Vivado for synthesis
- Build system integration

### 7. `ai_workflow_and_system_info`
**AI-assisted development workflow**
- How to use AI agents effectively
- Workflow stages
- Quality gates

### 8. `suggested_commands`
**Common build and test commands**
- Module-level commands
- Central build system commands

### 9. `task_completion_checklist`
**Verification checklist**
- Pre-commit checks
- Testing requirements
- Documentation standards

## How AI Agents Use Serena

### 1. **Automatic Context Loading**
When an AI agent is invoked, it can read relevant memories:
```
Agent detects GHDL error → Searches ghdl_patterns_and_solutions → Finds solution
```

### 2. **Pattern Matching**
Agents use memories to:
- Find similar past solutions
- Apply proven patterns
- Avoid known pitfalls

### 3. **Learning and Evolution**
New patterns discovered during development are added to memories, creating a growing knowledge base.

## Integration Strategy

### Current Approach

**Human-Readable Markdown Files** (ai-workflow/*.md)
- ✅ Maintained for human reference
- ✅ Historical context preserved
- ✅ Easy to read and edit manually
- ⚠️ Now include cross-reference note to Serena

**Serena Memories** (MCP server)
- ✅ Optimized for AI search and retrieval
- ✅ Context-aware and semantic
- ✅ Cross-referenced with other memories
- ✅ Automatically available to all AI agents

**Best of Both Worlds:**
- Humans can read markdown files
- AI agents use Serena for fast, context-aware access
- Both stay in sync through periodic updates

### Adding New Patterns

When you discover new patterns or solutions:

**Option 1: Update Serena Memory Directly**
```bash
# AI agent can update memory with new pattern
mcp_serena_write_memory(
    memory_name="ghdl_patterns_and_solutions",
    content="... updated content with new pattern ..."
)
```

**Option 2: Update Markdown File, Then Sync**
1. Edit `ai-workflow/README-*.md` with new pattern
2. Ask AI to integrate into Serena memory
3. Both stay in sync

**Option 3: Let AI Decide**
When you encounter a new error/pattern, tell the AI:
> "I hit this error [describe]. Can you document this in the appropriate memory?"

The AI will:
1. Determine which memory to update
2. Format the pattern consistently
3. Cross-reference related content
4. Update the memory

## Benefits of Serena Integration

### For AI Agents
- ✅ **Faster context retrieval** - No need to re-read large files
- ✅ **Semantic search** - Find relevant patterns by meaning, not just keywords
- ✅ **Cross-project learning** - Patterns discovered in one module help others
- ✅ **Consistent formatting** - Standardized pattern templates

### For Developers
- ✅ **Smarter AI assistance** - AI learns from project history
- ✅ **Reduced repetition** - Don't explain the same pattern twice
- ✅ **Knowledge preservation** - Project knowledge survives team changes
- ✅ **Quality improvement** - AI applies proven patterns automatically

### For the Project
- ✅ **Institutional knowledge** - Project-specific wisdom captured
- ✅ **Onboarding acceleration** - New developers/AIs get context quickly
- ✅ **Consistency enforcement** - Standards applied uniformly
- ✅ **Continuous improvement** - Knowledge base grows over time

## Examples of AI Using Serena

### Example 1: GHDL Error Resolution
**Scenario**: AI encounters "shared variable must be protected type" error

**Without Serena**:
- AI reads generic VHDL-2008 documentation
- Suggests protected type implementation (overkill)
- Might not match project patterns

**With Serena**:
- AI searches `ghdl_patterns_and_solutions` memory
- Finds exact error with 3 solution options
- Knows project prefers local variables in testbenches
- Applies correct solution immediately

### Example 2: New Module Development
**Scenario**: Create new EMFI-related module

**Without Serena**:
- AI might use component declarations (wrong for this project)
- FSM might use enums (forbidden in Tier 1)
- Testbench might use wrong termination pattern

**With Serena**:
- AI reads `design_patterns` for module structure
- Reads `coding_standards` for Tier 1 rules
- Reads `ghdl_patterns_and_solutions` for testbench template
- Creates module following all project conventions

### Example 3: Voltage Package Bug Fix (Real Example, 2025-01-21)
**Scenario**: Fixed EMFI-Seq voltage codes and added testbenches

**What Happened**:
1. AI discovered "shared variable" error in testbench
2. Fixed error using local variables pattern
3. Added pattern to `ghdl_patterns_and_solutions` memory
4. Future testbenches automatically use correct pattern

**Benefit**: The next time ANY module needs a testbench, the AI will use the proven pattern.

## Maintaining the Memory System

### When to Update Memories

**Update Immediately When**:
- ✅ New compilation error encountered and solved
- ✅ New design pattern proven successful
- ✅ Project standards change
- ✅ Tool versions update with breaking changes

**Schedule Periodic Reviews**:
- 📅 Monthly: Review and consolidate similar patterns
- 📅 Quarterly: Archive obsolete patterns
- 📅 Per-release: Update with lessons learned

### Memory Hygiene

**Keep Memories**:
- ✅ Focused on specific topics
- ✅ Cross-referenced appropriately
- ✅ Updated with dates and context
- ✅ Organized with clear structure

**Avoid**:
- ❌ Duplicate information across memories
- ❌ Outdated patterns without version context
- ❌ Overly generic advice (use project-specific patterns)
- ❌ Unstructured brain dumps

## Commands for Working with Serena

### List Available Memories
```python
mcp_serena_list_memories()
```

### Read a Memory
```python
mcp_serena_read_memory(memory_file_name="ghdl_patterns_and_solutions")
```

### Write/Update a Memory
```python
mcp_serena_write_memory(
    memory_name="ghdl_patterns_and_solutions",
    content="... full content ..."
)
```

### Delete a Memory (Rarely Needed)
```python
mcp_serena_delete_memory(memory_file_name="obsolete_memory")
```

## Future Enhancements

### Planned Improvements
- [ ] Add memory for Vivado synthesis patterns
- [ ] Add memory for MCC integration examples
- [ ] Create cross-reference index between memories
- [ ] Add version tags to patterns (GHDL 1.0, Vivado 2022.2, etc.)

### Potential Additions
- Platform-specific patterns (Moku:Go vs Moku:Pro)
- Performance optimization patterns
- Debugging workflow patterns
- Git workflow and commit message templates

## Related Files

**This Document**:
- `ai-workflow/README-serena-integration.md` (you are here)

**Source Markdown Files** (human-readable):
- `ai-workflow/README-ghdl-testbench-tips.md`
- `ai-workflow/README-direct-instantiation.md`
- `ai-workflow/ng/README-synth-vhdl-tips-ng.md`
- `ai-workflow/ng/README-ghdl-testbench-tips-ng.md`

**Serena Memories** (AI-optimized):
- Access via MCP tools (see commands above)
- List with `mcp_serena_list_memories()`

## Questions?

If you're unsure whether to update a memory or markdown file, ask an AI agent:
> "Should I add this pattern to a Serena memory or a markdown file?"

The AI will guide you based on:
- Content type (error solution vs tutorial)
- Frequency of use (common pattern vs rare edge case)
- Audience (AI agents vs human developers)

---

**Remember**: The goal is to create a self-improving knowledge base that makes both AI agents and human developers more effective over time.

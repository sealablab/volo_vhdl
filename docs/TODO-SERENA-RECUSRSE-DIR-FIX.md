# TODO: Enable Serena Recursive Directory Support for Memories

**Status**: Research Complete - Implementation Pending
**Date**: 2025-10-25
**Priority**: Nice-to-have (quality of life improvement)

## Problem Statement

Currently, Serena's `.serena/memories/` directory contains 38+ flat memory files, making it difficult to organize related memories into logical categories (instruments, MCC patterns, testing guides, etc.).

While Serena's memory system **already supports** reading/writing to subdirectories, the `list_memories()` tool does **not** discover memories in subdirectories.

## Current Behavior

### What Works ✅
1. **Writing to subdirectories** - Serena can write memories with path separators:
   ```python
   mcp__serena__write_memory(memory_name="instruments/oscilloscope", content="...")
   # Creates: .serena/memories/instruments/oscilloscope.md
   ```

2. **Reading from subdirectories** - Works if you know the path:
   ```python
   mcp__serena__read_memory(memory_file_name="instruments/oscilloscope.md")
   # Successfully reads the file
   ```

### What's Broken ❌
3. **Listing subdirectory memories** - Only shows top-level files:
   ```python
   mcp__serena__list_memories()
   # Returns: ["coding_standards", "design_patterns", ...]
   # Missing: ["instruments/oscilloscope", "mcc/build_pattern", ...]
   ```

## Root Cause

**File**: `serena_git/src/serena/project.py`
**Line**: 48

Current implementation:
```python
def list_memories(self) -> list[str]:
    return [f.name.replace(".md", "") for f in self._memory_dir.iterdir() if f.is_file()]
```

**Issue**: `.iterdir()` only lists immediate children, not recursive contents.

## Proposed Fix

**One-line change** to enable recursive discovery:

```python
def list_memories(self) -> list[str]:
    return [
        str(f.relative_to(self._memory_dir)).replace(".md", "")
        for f in self._memory_dir.rglob("*.md")  # Changed from .iterdir()
    ]
```

**Changes**:
- `.iterdir()` → `.rglob("*.md")` (recursive glob for all .md files)
- `f.name` → `str(f.relative_to(self._memory_dir))` (preserve directory structure)

**Result**:
```python
list_memories()
# Returns: [
#   "coding_standards",
#   "instruments/oscilloscope",
#   "instruments/waveform_generator",
#   "mcc/build_pattern",
#   "mcc/debugging_techniques",
#   ...
# ]
```

## Proposed Directory Structure

Once implemented, organize memories like:

```
.serena/memories/
├── core/                     # Core architecture & standards
│   ├── coding_standards.md
│   ├── design_patterns.md
│   ├── codebase_structure.md
│   └── tech_stack.md
├── instruments/              # Moku instrument memories (17 files)
│   ├── oscilloscope.md
│   ├── waveform_generator.md
│   ├── logic_analyzer.md
│   ├── lock_in_amplifier.md
│   └── ...
├── mcc/                      # MCC CloudCompile & integration
│   ├── build_pattern.md
│   ├── debugging_techniques.md
│   ├── routing_concepts.md
│   ├── cloudcompile_packaging.md
│   └── cloudcompile_human_assisted_workflow.md
├── testing/                  # Testing frameworks & guides
│   ├── cocotb_testing_guide.md
│   ├── python_testing_workflow.md
│   ├── ghdl_patterns_and_solutions.md
│   └── bench_config_framework.md
├── hardware/                 # Platform-specific hardware
│   ├── platform_models.md
│   ├── riscure_ds1120a.md
│   └── riscure_ds1121a.md
└── patterns/                 # Specific implementation patterns
    ├── bram_inference_patterns.md
    ├── oscilloscope_debugging_techniques.md
    └── simpleserial_pinata_protocols.md
```

## Verification Test

Test performed on 2025-10-25:

```python
# 1. Create subdirectory manually
mkdir -p .serena/memories/test

# 2. Write memory with path
mcp__serena__write_memory(
    memory_name="test/directory_structure_test",
    content="# Test\nThis works!"
)
# Result: ✅ Memory test/directory_structure_test written.

# 3. Read it back
mcp__serena__read_memory(memory_file_name="test/directory_structure_test.md")
# Result: ✅ Content returned correctly

# 4. List memories
mcp__serena__list_memories()
# Result: ❌ Does NOT include "test/directory_structure_test"

# 5. Verify on disk
find .serena/memories -name "*.md"
# Result: ✅ File exists at .serena/memories/test/directory_structure_test.md
```

## Implementation Options

### Option 1: Patch Local Serena Installation
Modify your local `~/.local/share/uv/python/.../site-packages/serena/project.py`

**Pros**: Immediate benefit
**Cons**: Lost on Serena updates, not portable

### Option 2: Fork Serena
Fork `oraios/serena` and apply the fix

**Pros**: Persistent, can contribute back via PR
**Cons**: Maintenance overhead

### Option 3: Submit Upstream PR
Create pull request to `oraios/serena` with the fix

**Pros**: Benefits entire community, official support
**Cons**: Waiting for review/merge

### Option 4: Wait for Official Support
File GitHub issue and wait for maintainers

**Pros**: No code maintenance
**Cons**: Uncertain timeline

## Migration Script

Once implemented, use this to reorganize existing memories:

```bash
#!/bin/bash
# migrate_memories.sh - Reorganize Serena memories into subdirectories

MEMORIES_DIR=".serena/memories"

# Create subdirectories
mkdir -p "$MEMORIES_DIR"/{core,instruments,mcc,testing,hardware,patterns}

# Instruments (17 files)
for instrument in oscilloscope waveform_generator logic_analyzer \
    lock_in_amplifier spectrum_analyzer phasemeter \
    frequency_response_analyzer time_frequency_analyzer \
    arbitrary_waveform_generator pid_controller \
    digital_filter_box fir_filter_builder neural_network \
    cloud_compile data_logger laser_lock_box; do
    [ -f "$MEMORIES_DIR/instrument_$instrument.md" ] && \
        git mv "$MEMORIES_DIR/instrument_$instrument.md" \
               "$MEMORIES_DIR/instruments/$instrument.md"
done

# MCC (5 files)
for mcc_file in build_pattern debugging_techniques routing_concepts \
    cloudcompile_packaging cloudcompile_human_assisted_workflow; do
    [ -f "$MEMORIES_DIR/mcc_$mcc_file.md" ] && \
        git mv "$MEMORIES_DIR/mcc_$mcc_file.md" \
               "$MEMORIES_DIR/mcc/$mcc_file.md"
done

# Testing (4 files)
for test_file in cocotb_testing_guide python_testing_workflow \
    ghdl_patterns_and_solutions bench_config_framework; do
    [ -f "$MEMORIES_DIR/$test_file.md" ] && \
        git mv "$MEMORIES_DIR/$test_file.md" \
               "$MEMORIES_DIR/testing/$test_file.md"
done

# Hardware (3 files)
for hw_file in platform_models riscure_ds1120a riscure_ds1121a; do
    [ -f "$MEMORIES_DIR/$hw_file.md" ] && \
        git mv "$MEMORIES_DIR/$hw_file.md" \
               "$MEMORIES_DIR/hardware/$hw_file.md"
done

# Core (4 files)
for core_file in coding_standards design_patterns \
    codebase_structure tech_stack; do
    [ -f "$MEMORIES_DIR/$core_file.md" ] && \
        git mv "$MEMORIES_DIR/$core_file.md" \
               "$MEMORIES_DIR/core/$core_file.md"
done

# Patterns (remaining specialized files)
for pattern_file in bram_inference_patterns \
    oscilloscope_debugging_techniques \
    simpleserial_pinata_protocols \
    mokubench_deployment_success \
    task_completion_checklist \
    project_overview; do
    [ -f "$MEMORIES_DIR/$pattern_file.md" ] && \
        git mv "$MEMORIES_DIR/$pattern_file.md" \
               "$MEMORIES_DIR/patterns/$pattern_file.md"
done

echo "✓ Memory reorganization complete!"
```

## References

- **Serena Repository**: https://github.com/oraios/serena
- **File Location**: `src/serena/project.py` (line 48)
- **Related**: MemoriesManager class (lines 22-53)
- **Local Copy**: `serena_git/` (cloned on 2025-10-25)

## Next Steps

1. **Decide on implementation approach** (Options 1-4 above)
2. **Test the fix** in isolated environment
3. **Run migration script** to reorganize memories
4. **Update CLAUDE.md** to reference new structure
5. **Consider upstream contribution** if fix works well

---

**Notes**:
- The infrastructure is already 90% there - just needs list discovery
- No breaking changes required (backward compatible)
- Would significantly improve organization for projects with 30+ memories
- Consider submitting as enhancement request to Serena maintainers

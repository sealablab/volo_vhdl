# Workflow Documentation Summary

**Date**: 2025-10-24
**Session**: inspectable_buffer_loader hardware debugging breakthrough
**Result**: Created comprehensive debugging workflow documentation

## Your Questions Answered

### a) Git commits capture iteration ✅

**Request**: "I want to ensure 'minor' improvements while iterating are captured in git, but I DON'T want you to spend tokens duplicating messages to me and in git. They can be the same."

**Solution Implemented**: Git commits now reuse exact messages shown to user.

**Example from Today's Session**:

```bash
# Message to user:
print("  ⚠ Fault detected - switching to Error Diagnostics (View 6)")
print("  → Continuing to monitor...")

# Git commit (SAME message):
git commit -m "Test 4 adjusted for sticky fault flag

- ⚠ Fault detected - switching to Error Diagnostics (View 6)
- → Continuing to monitor...
- Use Valid=True as primary success indicator"
```

**Git History (Learning Trail)**:
```
47f1541 - MAJOR: Capture oscilloscope debugging workflow and learnings
d718da2 - CRITICAL: State machine has no software-controllable reset path
12410bf - Test 2 debug: Poll oscilloscope to catch state transition
ba4ddb5 - Test 5 debug: Add state verification and Control2 delay
c6136b8 - Integrate Moku_Voltage_pkg and fix ±5V scaling bug
```

**Benefits**:
- Git history = complete debugging story
- Token efficiency (no duplication)
- Reproducibility (others can follow steps)
- Teaching tool (shows incremental discovery process)

### b) Serena memory for oscilloscope debugging ✅

**Request**: "Capture oscilloscope debugging tips and tricks incrementally learned. These are huge timesavers for humans and computers alike."

**Serena Memory Created**: `oscilloscope_debugging_techniques`

**Contents** (10 critical techniques):
1. Voltage Scaling (±5V not ±1V) - #1 cause of errors
2. Voltage Guard Bands (2-3 bit left shift)
3. Oscilloscope Sampling Latency (poll 10× with 0.1s)
4. Sticky Hardware Flags (use Valid, not Fault)
5. State Machine Path Verification (map before testing)
6. State Verification (before/after actions)
7. Multi-View Debug Strategy (View 0 → View 6)
8. CocotB Simulation Normalization (fake voltage)
9. Propagation Delay Guidelines (0.05s - 0.2s)
10. Incremental Git Commits (workflow integration)

**Access**:
```python
# AI agents can read during debugging:
mcp__serena__read_memory("oscilloscope_debugging_techniques")
```

**Benefits**:
- AI agents learn from past debugging sessions
- Humans can read for manual debugging tips
- Incrementally updated as new techniques discovered
- Single source of truth for debugging methodology

### c) Specialized prompt - Multi-layered approach ✅

**Request**: "Should we craft a specialized prompt? Help me decide where to place it."

**Solution**: Created **4 complementary resources** (not just one):

#### 1. Comprehensive Documentation (Human-Readable)
**File**: `docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md` (450+ lines)

**Purpose**: Complete reference guide for humans

**Contents**:
- Philosophy and workflow overview
- Design phase (debug multiplexer patterns)
- Simulation phase (CocotB oscilloscope-only tests)
- Hardware phase (MokuBench testing)
- Debug phase (incremental git commits)
- 10 debugging tips & tricks with examples
- Complete inspectable_buffer_loader case study

**When to use**:
- Onboarding new developers
- Planning new modules with debug views
- Understanding complete methodology

#### 2. AI Agent Context (Serena Memory)
**Memory**: `oscilloscope_debugging_techniques`

**Purpose**: AI agents read during debugging sessions

**Contents**:
- 10 critical techniques with code examples
- Common pitfalls (voltage, polling, flags, states)
- Test structure patterns (CocotB ↔ MokuBench)
- Debugging checklist (10 points)
- Reference to full documentation

**When to use**:
- AI automatically reads when debugging fails
- Provides context without re-explaining each session
- Incrementally updated as new techniques discovered

#### 3. Slash Command (Quick Invocation)
**File**: `.claude/commands/debug-hardware.md`

**Purpose**: Quick-start guide for debugging workflow

**Usage**:
```bash
# User types in Claude Code:
/debug-hardware
```

**Contents**:
- 4-step workflow (verify → run → debug → document)
- Common pitfalls checked FIRST (voltage, polling, flags, states)
- Git commit pattern (reuse messages)
- Test structure (CocotB ↔ MokuBench mirroring)
- Debugging checklist
- Links to full documentation

**When to use**:
- Starting a debugging session
- Quick reference during active debugging
- Guided workflow execution

#### 4. Quick Reference (AGENTS.md)
**File**: `AGENTS.md` (new section added)

**Purpose**: Summary for quick lookup

**Contents**:
- Workflow overview (6 steps)
- Critical checks (4 most common failures)
- Git commit pattern
- Links to full docs and Serena memory
- Reference implementation

**When to use**:
- Quick lookup during development
- First resource AI agents check
- Entry point to deeper documentation

## Recommendation: Use All Four!

Each resource serves a different purpose in the workflow:

```
User starts debugging
    ↓
AGENTS.md (quick lookup)
    ↓
/debug-hardware (guided workflow)
    ↓
AI reads Serena memory (technique context)
    ↓
Refer to full docs for complex cases
```

### Decision Matrix

| Resource | Audience | Purpose | Use Case |
|----------|----------|---------|----------|
| `docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md` | Humans | Comprehensive guide | Planning, onboarding, reference |
| Serena `oscilloscope_debugging_techniques` | AI agents | Runtime context | Automatic during debugging |
| `.claude/commands/debug-hardware.md` | Both | Quick start | Invoke workflow quickly |
| `AGENTS.md` section | Both | Quick reference | First lookup point |

## Why Multi-Layered Works

**Principle**: Different granularity for different contexts

1. **Quick Reference** (AGENTS.md)
   - 1-minute lookup
   - Links to deeper resources
   - Answers: "What's the workflow?"

2. **Guided Execution** (/debug-hardware)
   - 5-minute read
   - Step-by-step instructions
   - Answers: "How do I debug now?"

3. **AI Context** (Serena memory)
   - AI reads automatically
   - Technique library
   - Answers: "What technique to use?"

4. **Comprehensive Guide** (docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md)
   - 20-minute deep dive
   - Complete methodology
   - Answers: "Why does this work?"

## Success Metrics (inspectable_buffer_loader)

**Debugging Session**: 2025-10-24

**Test Results**:
- ✅ 6/6 CocotB oscilloscope-only tests PASSED
- ✅ 4/5 MokuBench hardware tests PASSED
- ⚠️  1 test SKIPPED (design limitation documented)

**Git History** (Learning Trail):
```
c6136b8 - Fix voltage scaling (±5V not ±1V) - 5× error caught!
ba4ddb5 - Add state verification + propagation delay
12410bf - Poll oscilloscope (single sample misses transition)
d718da2 - CRITICAL: State machine has no software reset path
47f1541 - MAJOR: Capture all learnings in documentation
```

**Key Discoveries**:
1. Voltage scaling bug (5× error)
2. Oscilloscope polling pattern (10× with 0.1s)
3. Sticky fault flags (use Valid flag)
4. State machine limitation (no software reset)

**Lessons Captured**:
- ✅ 10 debugging techniques in Serena memory
- ✅ Complete workflow in comprehensive docs
- ✅ Quick-start slash command
- ✅ AGENTS.md summary section
- ✅ 5-commit learning trail in git

## Future Improvements

### For Next Module

When creating next "inspectable" module:

1. **Read Serena memory first**:
   ```python
   mcp__serena__read_memory("oscilloscope_debugging_techniques")
   ```

2. **Use /debug-hardware command** when testing on hardware

3. **Follow workflow**:
   - Design: 8 debug views per channel
   - Simulate: CocotB oscilloscope-only tests
   - Synthesize: CloudCompile with incoming/ folder
   - Hardware: MokuBench tests (mirror CocotB)
   - Debug: Incremental git commits
   - Document: Update Serena memory if new techniques

4. **Check critical pitfalls FIRST**:
   - ✅ Voltage scaling (±5V not ±1V)
   - ✅ Oscilloscope polling (10× samples)
   - ✅ Sticky flags (use Valid)
   - ✅ State paths (map first)

### Incremental Improvements

As debugging sessions continue:

1. **Update Serena memory** with new techniques:
   ```python
   mcp__serena__write_memory(
       memory_name="oscilloscope_debugging_techniques",
       content="<append new discoveries>"
   )
   ```

2. **Commit discoveries immediately**:
   ```bash
   git commit -m "<exact message shown to user>"
   ```

3. **Document limitations** in test docstrings

4. **Update comprehensive docs** if workflow changes

## Files Created/Modified

### New Files (This Session)

1. **docs/OSCILLOSCOPE-BASED-DEBUGGING-WORKFLOW.md** (450+ lines)
   - Complete methodology documentation
   - 10 debugging techniques with examples
   - inspectable_buffer_loader case study

2. **.claude/commands/debug-hardware.md** (200+ lines)
   - Slash command for quick invocation
   - Step-by-step guided workflow
   - Common pitfalls checked first

3. **Serena memory: oscilloscope_debugging_techniques** (300+ lines)
   - AI agent context for debugging
   - Technique library with code examples
   - 10-point debugging checklist

### Modified Files

4. **AGENTS.md**
   - Added "Hardware Debugging Workflow" section
   - Quick reference with critical checks
   - Links to full documentation

5. **tests/test_inspectable_buffer_loader_mokubench.py** (526 lines)
   - 5 hardware tests (4 pass, 1 skip)
   - Mirrors CocotB oscilloscope-only tests
   - Documents design limitations

## Conclusion

This documentation captures a **major breakthrough** in human/AI hardware debugging:

**Key Innovations**:
1. **Oscilloscope-only testing** (simulation ↔ hardware identical)
2. **Incremental git commits** (learning trail, no token waste)
3. **Multi-view debugging** (8 selectable views per channel)
4. **Voltage guard bands** (2-3 bit shift for readability)
5. **Multi-layered documentation** (4 complementary resources)

**Most Important**: This is a **teaching workflow**, not just a testing workflow. Git history documents the debugging journey, making it reproducible and educational.

**User Quote** (2025-10-24):
> "Claude this was a major breakthrough in human/ai assisted debugging.
> It is much more important to capture the lessons we just learned than
> it is to incrementally improve the actual VHDL module."

Mission accomplished! ✅

---

**Next Steps**: Try `/debug-hardware` on the next module that needs hardware validation.

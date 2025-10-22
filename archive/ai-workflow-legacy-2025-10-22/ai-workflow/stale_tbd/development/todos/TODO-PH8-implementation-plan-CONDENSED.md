# ProbeHero8 Implementation Plan (Condensed)

## 🚨 Git Workflow

| Scenario | Purpose | Commands |
|----------|---------|----------|
| **Initial Setup** | Sync and create feature branch | `git checkout main && git pull origin main && git checkout -b feature/probehero8-implementation` |
| **Daily Start** | Sync feature branch with main | `git checkout main && git pull origin main && git checkout feature/probehero8-implementation && git merge main` |
| **Daily End** | Commit and push progress | `git add . && git commit -m "ProbeHero8: [message]" && git push origin feature/probehero8-implementation` |
| **Merge Complete** | Merge and clean up | `git checkout main && git pull origin main && git branch -d feature/probehero8-implementation && git push origin --delete feature/probehero8-implementation` |

---

## 🎯 Project Overview

**ProbeHero8** is the enhanced version of ProbeHero7, leveraging:
- Enhanced datadef packages (with validation + error handling)
- State machine templates (Verilog-portable FSM base)
- Reset and validation infrastructure
- Layered testbench framework (GHDL-compatible)

**Learning Objectives**
- Validate workflow from datadef → core → top → testbench
- Test enhanced packages/templates in real use
- End-to-end validation of development process
- Gather immediate feedback for refinement

---

## 📋 Implementation Roadmap

### Phase 1: Core Entity Development
- Create `core/probe_hero8_core.vhd` using enhanced packages
- FSM with states: IDLE, ARMED, FIRING, COOLING, HARDFAULT
- Validation: parameter clamping, ALARM signaling, safety checks

### Phase 2: Core Testbench Development
- Build `tb/core/probe_hero8_core_tb.vhd` (layer-organized)
- Test coverage:
  - Reset, enable/disable, state transitions
  - Parameter validation (valid/invalid probe selection, clamping, ALARM bits)
  - Firing sequence (trigger detection, timing, voltage, cooling)
  - Error handling & boundary recovery
- Run GHDL validation (`ghdl --std=08`)

### Phase 3: Top-Level Integration
- Create `top/probe_hero8_top.vhd` (direct instantiation required)
- Build `tb/top/probe_hero8_top_tb.vhd` (direct instantiation)
- Validate system integration, register interface, and end-to-end flow

### Phase 4: System Validation
- Test integration of all enhanced packages
- Validate error handling and status registers
- Performance checks: timing, FSM behavior, error recovery, resource utilization

---

## 🔧 Technical Requirements

**VHDL-2008 + Verilog Portability**
- [ ] Use `std_logic`, `std_logic_vector`
- [ ] FSMs: `std_logic_vector` encoding + constants (no enums)
- [ ] Avoid VHDL-only features

**Direct Instantiation**
- [ ] Required for all top-level modules & testbenches
- [ ] Use `entity WORK.module_name` pattern (no component declarations)

**Enhanced Package Integration**
- [ ] Use validation functions
- [ ] Implement parameter clamping + ALARM signaling
- [ ] Ensure robust error handling paths

---

✅ This condensed version removes redundancy, groups tasks logically, and is easier for both humans and LLMs to parse.

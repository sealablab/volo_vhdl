# ProbeHero8 Implementation Plan (Condensed NG)

## 🚨 Git Workflow

| Scenario | Purpose | Commands |
|----------|---------|----------|
| **Initial Setup** | Sync and create feature branch | `git checkout main-ng && git pull origin main-ng && git checkout -b feature/probehero8-condensed-ng` |
| **Daily Start** | Sync feature branch with main-ng | `git checkout main-ng && git pull origin main-ng && git checkout feature/probehero8-condensed-ng && git merge main-ng` |
| **Daily End** | Commit and push progress | `git add . && git commit -m "ProbeHero8 Condensed NG: [message]" && git push origin feature/probehero8-condensed-ng` |
| **Merge Complete** | Merge and clean up | `git checkout main-ng && git pull origin main-ng && git branch -d feature/probehero8-condensed-ng && git push origin --delete feature/probehero8-condensed-ng` |

---

## 🎯 Project Overview

**ProbeHero8** is the enhanced version of ProbeHero7, leveraging:
- Enhanced datadef packages (with validation + error handling)
- State machine templates (Verilog-portable FSM base)
- Reset and validation infrastructure
- Layered testbench framework (GHDL-compatible)
- **NEW**: Enhanced structured rules system (v1.1) from main-ng branch

**Learning Objectives**
- Validate workflow from datadef → core → top → testbench
- Test enhanced packages/templates in real use
- End-to-end validation of development process
- **NEW**: Evaluate enhanced rules system effectiveness
- Gather immediate feedback for refinement

---

## 📋 Implementation Roadmap

### Phase 1: Core Entity Development
- Create `core/probe_hero8_core.vhd` using enhanced packages
- FSM with states: IDLE, ARMED, FIRING, COOLING, HARDFAULT
- **NEW**: Apply SIG-02 (named association) and SIG-03 (signal priority) patterns
- Validation: parameter clamping, ALARM signaling, safety checks

### Phase 2: Core Testbench Development
- Build `tb/core/probe_hero8_core_tb.vhd` (layer-organized)
- **NEW**: Apply TB-05 (clock management) and TB-06 (reset testing) patterns
- Test coverage:
  - Reset, enable/disable, state transitions
  - Parameter validation (valid/invalid probe selection, clamping, ALARM bits)
  - Firing sequence (trigger detection, timing, voltage, cooling)
  - Error handling & boundary recovery
- Run GHDL validation (`ghdl --std=08`)

### Phase 3: Top-Level Integration
- Create `top/probe_hero8_top.vhd` (direct instantiation required)
- **NEW**: Use SIG-02 pattern for all port mappings
- Build `tb/top/probe_hero8_top_tb.vhd` (direct instantiation)
- Validate system integration, register interface, and end-to-end flow

### Phase 4: System Validation
- Test integration of all enhanced packages
- Validate error handling and status registers
- Performance checks: timing, FSM behavior, error recovery, resource utilization
- **NEW**: Evaluate rules system impact on development process

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

**NEW: Enhanced Rules System Integration**
- [ ] Apply SIG-02: Named association & explicit conversions
- [ ] Apply SIG-03: Define signal priority & truth table
- [ ] Apply TB-05: Clock & timing management
- [ ] Apply TB-06: Reset & initialization testing
- [ ] Track rules system effectiveness in progress log

---

✅ This condensed version removes redundancy, groups tasks logically, and integrates the enhanced rules system for improved development guidance.

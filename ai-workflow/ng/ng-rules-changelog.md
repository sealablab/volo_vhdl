# NG Rules Changelog

> Human-readable changelog for the enhanced structured rule system (`-ng` files)
> 
> This file tracks improvements, integrations, and refinements to the structured rule system.
> It's designed for human review and project management, not machine parsing.

---

## Version 1.1 - Agent Integration & Quality Refinement
**Date**: August 30, 2025  
**Tag**: `enhanced-structured-rule-system-v1.1`  
**Branch**: `main-ng`

### 🎯 **Integration Summary**
Agent evaluation and integration of candidate rules from the footer sections. **Excellent quality control** - only integrated the most valuable tips while maintaining high standards.

### 📈 **Changes Made**

#### **README-synth-vhdl-tips-ng.md**
- **✅ Integrated 2 new tips** from candidate section:
  - **SIG-02**: "Prefer named association & explicit conversions"
    - *Problem*: Port type mismatches and accidental mis-wiring with positional maps
    - *Solution*: Use named port maps with explicit type conversions
    - *Pattern*: Focused on `std_logic_vector`/`unsigned` conversions in port maps
  - **SIG-03**: "Define signal priority & truth table"
    - *Problem*: Unclear behavior when reset, clock_enable, and enable interact
    - *Solution*: Document priority hierarchy (reset > clock_enable > enable)
    - *Pattern*: Simplified, practical reset/enable hierarchy implementation

- **✅ Updated Quick Index** with new error clues:
  - Added "positional map mismatch" → SIG-02
  - Added "priority confusion" → SIG-03

#### **README-ghdl-testbench-tips-ng.md**
- **✅ Enhanced 2 existing tips** with better content:
  - **TB-05**: "Clock & timing management" (enhanced)
    - *Problem*: Flaky tests from inconsistent timing and CE discipline
    - *Solution*: Drive enable/updates synchronously, prefer clock-enables over `wait for`
    - *Pattern*: Focused on synchronous driving with clock enable discipline
  - **TB-06**: "Reset & initialization testing" (enhanced)
    - *Problem*: DUT passes nominal tests but fails power-up/first-cycle
    - *Solution*: Create dedicated reset/boot test for post-reset defaults
    - *Pattern*: Comprehensive reset timing and first-cycle verification

- **✅ Updated Quick Index** with new error clues:
  - Added "clock discipline/CE usage" → TB-05
  - Added "reset held long enough" → TB-06

### 🧹 **Cleanup**
- **✅ Cleaned footer sections** - removed all candidate tips, left clean template
- **✅ Maintained structured format** - preserved quality and organization
- **✅ Enhanced descriptions** - improved problem/solution clarity from original candidates

### 🎯 **Quality Assessment**
- **Selective Integration**: Only integrated 4 high-value tips from 14 candidates
- **Enhanced Content**: Improved descriptions and patterns from original candidates
- **Practical Focus**: Chose tips addressing real, common problems
- **Maintained Standards**: Kept structured format and quality bar high

### 📊 **Impact**
- **Total Tips**: 4 new/enhanced tips integrated
- **Quick Index**: 4 new error clues added
- **Quality**: Maintained high standards with selective integration
- **Usability**: More actionable, specific guidance for AI agents

---

## Version 1.0 - Initial Enhanced Structured Rule System
**Date**: August 30, 2025  
**Tag**: `enhanced-structured-rule-system-v1.0`  
**Branch**: `main-ng`

### 🚀 **Initial Release**
Created the enhanced structured rule system with dual-purpose format and comprehensive tip coverage.

### 📚 **Features Introduced**
- **Dual-purpose format**: Machine-friendly rules + human context in HTML comments
- **Quick Index**: Error message lookup for rapid problem resolution
- **Canonical patterns**: Exact code snippets for common scenarios
- **Cross-references**: Links to detailed documentation
- **Agent contributions**: Built-in mechanism for AI agents to contribute new tips
- **Integration**: Seamless complement to existing workspace rules

### 📈 **Content Added**
- **14 new structured tips** covering VHDL synthesis and GHDL testbench development
- **Comprehensive Quick Index** with error clues and categories
- **Cross-references** to detailed README files in HTML comments
- **Updated workspace rules** with references to the new system

### 🎯 **Integration Points**
- **README-synth-vhdl-tips-ng.md**: 6 new tips (PROC-02, PROC-03, SIG-02, SIG-03, STD-02, STD-03)
- **README-ghdl-testbench-tips-ng.md**: 8 new tips (VS-03, DT-04, LOG-04, GHDL-04, TB-05, TB-06, TB-07, TB-08)
- **README-index.md**: Overview and navigation guide
- **Workspace rules**: Updated rules.mdc and AGENTS.md with references

---

## Future Versions

### Planned Improvements
- [ ] **Version 1.2**: Additional agent contributions and refinements
- [ ] **Version 1.3**: Integration of more detailed examples and edge cases
- [ ] **Version 2.0**: Major expansion based on real-world usage feedback

### Integration Guidelines
- **Quality over Quantity**: Only integrate high-value, practical tips
- **Maintain Standards**: Preserve structured format and quality bar
- **Enhance Content**: Improve descriptions and patterns from candidates
- **Update Index**: Add actionable error clues for new tips
- **Clean Footer**: Remove integrated tips, leave clean template

---

*This changelog is maintained manually and updated with each significant revision to the structured rule system.*
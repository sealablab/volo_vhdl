
``` markdown
  ---
  Next Steps

  You have everything you need to start implementation! Choose your path:

  Option A: Start Implementing Now

  # Create directory structure
  mkdir -p models/volo

  # Start with Task 1.1: Pydantic Models
  # See docs/VOLO_APP_IMPLEMENTATION_PLAN.md for checklist

  Option B: Review and Refine

  Take time to review the design documents and ask any clarifying questions before starting.

  Option C: Fresh Context Later

  When you're ready to implement in a fresh context, just:
  1. Read docs/VOLO_APP_FRESH_CONTEXT.md
  2. Follow Phase 1 checklist
  3. Reference docs/VOLO_APP_DESIGN.md for details
```


  📄 docs/VOLO_APP_DESIGN.md (10KB)
  - Complete architecture overview (3-layer design)
  - Register map specifications
  - Naming conventions (MANDATORY)
  - Pydantic model structure
  - Code generation workflow
  - Deployment workflow
  - Q&A section

  2. Fresh Context System Prompt

  📄 docs/VOLO_APP_FRESH_CONTEXT.md (7KB)
  - Quick-start guide for new context windows
  - All essential information in condensed form
  - Success criteria for Phase 1
  - Reference materials
  - Ready-to-execute checklist

  3. Detailed Implementation Plan

  📄 docs/VOLO_APP_IMPLEMENTATION_PLAN.md (8KB)
  - Phase-by-phase breakdown (5 phases)
  - Task checklists with checkboxes
  - Dependencies and commands
  - Progress tracking table
  - Open questions to resolve

  4. Example VoloApp Definition

  📄 modules/PulseStar/PulseStar_app.yaml (2KB)
  - Complete PulseStar volo-app definition
  - 3 registers (counter, percent, button)
  - Usage instructions in comments
  - Ready to use for testing code generation


  ---
  Quick Summary

  What is VoloApp?
  A hardware abstraction layer with 3 layers:
  1. MCC_TOP_volo_loader.vhd - Static, shared across ALL apps
  2. <AppName>_volo_shim.vhd - Generated from Pydantic model
  3. <AppName>_volo_main.vhd - Hand-written, MCC-agnostic

  Register Map:
  - CR0[31:29] = VOLO_READY control (3-bit scheme)
  - CR10-CR14 = BRAM loader (black box)
  - CR20-CR30 = App registers (human-friendly)

  Naming Convention (MANDATORY):
  - Files: <AppName>_volo_{shim|main}.vhd
  - Signals: "Pulse Width" → pulse_width (snake_case)
  - Location: modules/<AppName>/volo_main/

  ---
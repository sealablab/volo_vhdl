# S1-AFFECTED_MEMORIES.md

## Serena Memory Files Containing References to makefile, ghdl, or cocotb

This file lists all Serena memory files (.serena/memories/) that contain references to one or more of the following terms:
- makefile
- ghdl
- cocotb

### Affected Memory Files (28 total):

1. **bram_inference_patterns.md** - References: ghdl
2. **cocotb_testing_guide.md** - References: makefile, ghdl, cocotb
3. **codebase_structure.md** - References: makefile, ghdl, cocotb
4. **coding_standards.md** - References: ghdl
5. **design_patterns.md** - References: ghdl, cocotb
6. **ghdl_patterns_and_solutions.md** - References: makefile, ghdl, cocotb
7. **instrument_arbitrary_waveform_generator.md** - References: cocotb
8. **instrument_cloud_compile.md** - References: cocotb
9. **instrument_digital_filter_box.md** - References: cocotb
10. **instrument_fir_filter_builder.md** - References: cocotb
11. **instrument_laser_lock_box.md** - References: cocotb
12. **instrument_neural_network.md** - References: cocotb
13. **instrument_phasemeter.md** - References: cocotb
14. **instrument_time_frequency_analyzer.md** - References: cocotb
15. **instrument_waveform_generator.md** - References: cocotb
16. **mcc_build_pattern.md** - References: makefile, ghdl
17. **mcc_cloudcompile_packaging.md** - References: ghdl
18. **mcc_debugging_techniques.md** - References: cocotb
19. **mcc_routing_concepts.md** - References: cocotb
20. **mokubench_deployment_success.md** - References: ghdl, cocotb
21. **mokuconfig_and_benchbench_framework.md** - References: cocotb
22. **mokuconfig_core_abstraction.md** - References: cocotb
23. **oscilloscope_debugging_techniques.md** - References: cocotb
24. **platform_models.md** - References: cocotb
25. **project_overview.md** - References: ghdl
26. **python_testing_workflow.md** - References: makefile, ghdl, cocotb
27. **simpleserial_pinata_protocols.md** - References: cocotb
28. **tech_stack.md** - References: ghdl, cocotb

### Summary Statistics:
- Files containing "makefile": 6
- Files containing "ghdl": 16
- Files containing "cocotb": 24
- Files containing multiple terms: 11

### Most Affected Files (contain all 3 terms):
1. cocotb_testing_guide.md
2. codebase_structure.md
3. ghdl_patterns_and_solutions.md
4. python_testing_workflow.md

## Notes
- Search was performed case-insensitively
- This list was generated on 2025-10-26 to identify documentation that may need updating based on workflow parsing issues
---
Follow-up Questions:

  1. What are the specific parsing issues you identified?
    - Is it related to error message parsing from ghdl compilation output?
    - Or parsing test results from cocotb test runs?
    - Are there specific patterns or text that are causing problems?
  2. Which workflow/agent is affected?
    - Is this impacting the build automation agents?
    - Test execution agents?
    - Documentation generation?
  3. What kind of extraneous text is being problematic?
    - Warning messages that look like errors?
    - Progress indicators or verbose output?
    - Timing information or debug output?
  4. Would you like me to:
    - Review the most affected files (those with all 3 terms) first?
    - Look for specific parsing patterns in the memories?
    - Suggest fixes for the parsing issues once you explain them?

  The 4 most affected files that reference all three terms are:
  - cocotb_testing_guide.md
  - codebase_structure.md
  - ghdl_patterns_and_solutions.md
  - python_testing_workflow.md

  These would be good candidates to review first for any parsing-related documentation that might need updating.

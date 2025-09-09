# VHDL & GHDL Tips Index

This directory contains curated knowledge bases for two distinct domains:

- **README-synth-vhdl-tips-ng.md**  
  Synthesizable VHDL tips and best practices (processes, timing, resources, portability).

- **README-ghdl-testbench-tips-ng.md**  
  GHDL testbench tips and best practices (variables, logging, toolchain quirks, testbench patterns).

- **README-layered-testbench-ng.md**  
  Layered testbench architecture standard (4-layer testing approach, interface-focused testing, maintainable testbenches).

- **README-datadef-testbench.md**  
  Datadef package testbench architecture (function-centric testing, mathematical correctness, package integration testing).

- **README-vhdl-compilation-tricks-ng.md**  
  VHDL compilation patterns and best practices for GHDL (package design, entity patterns, process patterns, error prevention).

- **README-RESET-ng.md**  
  Reset and enable signal behavior documentation (signal priorities, truth table, control signal hierarchy).

All follow the same format:
- Machine‑friendly core sections (Problem/Cause/Solution/Pattern/Tags)
- Human commentary inside `<!-- … -->` blocks
- A manual **Quick Index** at the top
- A footer sandbox (`------- New Tips here-------`) where agents may append new candidate tips

Use these files together: **synthesizable rules for DUTs**, **testbench rules for simulations**, **layered architecture for module testing**, **datadef architecture for package testing**.

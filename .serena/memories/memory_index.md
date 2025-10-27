# Serena Memory Index
*Last Updated: 2025-01-26*

## 🚀 PRIMARY AUTHORITY
- **volo_testing_standard.md** - THE authoritative testing guide (Progressive P1-P4, LLM-optimized)
  - Replaces all old testing documentation
  - MANDATORY for all new modules

## 📦 Core Abstractions & Platform
- **mokuconfig_core_abstraction.md** - Core deployment model (MokuConfig) 
- **mokuconfig_and_benchbench_framework.md** - Infrastructure models comparison
- **platform_models.md** - Hardware platform specifications

## 🛠 MCC Integration Patterns  
- **mcc_build_pattern.md** - MCC build workflow patterns
- **mcc_cloudcompile_packaging.md** - CloudCompile packaging guide
- **mcc_cloudcompile_human_assisted_workflow.md** - Human-in-loop workflow
- **mcc_debugging_techniques.md** - MCC debugging strategies
- **mcc_routing_concepts.md** - MCC signal routing

## 📊 Instruments (Domain Knowledge)
- **instrument_arbitrary_waveform_generator.md** - AWG implementation
- **instrument_cloud_compile.md** - CloudCompile instrument
- **instrument_data_logger.md** - Data logging instrument
- **instrument_digital_filter_box.md** - Digital filter implementation
- **instrument_fir_filter_builder.md** - FIR filter builder
- **instrument_frequency_response_analyzer.md** - FRA implementation
- **instrument_laser_lock_box.md** - Laser lock implementation
- **instrument_lock_in_amplifier.md** - Lock-in amplifier
- **instrument_logic_analyzer.md** - Logic analyzer implementation
- **instrument_neural_network.md** - Neural network implementation
- **instrument_oscilloscope.md** - Oscilloscope implementation
- **instrument_phasemeter.md** - Phasemeter implementation
- **instrument_pid_controller.md** - PID controller
- **instrument_spectrum_analyzer.md** - Spectrum analyzer
- **instrument_time_frequency_analyzer.md** - Time-frequency analyzer
- **instrument_waveform_generator.md** - Waveform generator

## 🔬 Hardware & Protocols
- **riscure_ds1120a.md** - DS1120A hardware specifications
- **riscure_ds1121a.md** - DS1121A hardware specifications
- **simpleserial_pinata_protocols.md** - SimpleSerial protocol specs
- **oscilloscope_debugging_techniques.md** - Hardware debugging techniques

## 📚 General Project Information
- **codebase_structure.md** - Directory organization and architecture
- **coding_standards.md** - VHDL coding standards (Tier system)
- **design_patterns.md** - Common VHDL design patterns
- **project_overview.md** - High-level project context
- **tech_stack.md** - Tools, versions, and technology stack

## ⚠️ DELETED (Obsolete - 2025-01-26)
The following memories were removed during the VOLO Testing Revolution cleanup:
- ~~cocotb_testing_guide.md~~ → Replaced by volo_testing_standard.md
- ~~ghdl_patterns_and_solutions.md~~ → Old patterns, now obsolete
- ~~python_testing_workflow.md~~ → Replaced by volo_testing_standard.md
- ~~mokubench_deployment_success.md~~ → Contained old test patterns
- ~~bram_inference_patterns.md~~ → Contained old GHDL patterns

## 📋 Usage Guidelines

1. **For Testing**: Always start with `volo_testing_standard.md` - it's the ONLY testing authority
2. **For Instruments**: Check relevant `instrument_*.md` for domain knowledge
3. **For MCC Work**: Consult `mcc_*.md` memories for integration patterns
4. **For VHDL Coding**: Reference `coding_standards.md` and `design_patterns.md`
5. **For Deployment**: Use `mokuconfig_core_abstraction.md` as primary reference

## 🎯 Quick Start for New Context Windows

When starting fresh, read in this order:
1. `volo_testing_standard.md` - If doing ANY testing
2. `mokuconfig_core_abstraction.md` - Core deployment model
3. `coding_standards.md` - VHDL rules
4. Domain-specific memories as needed

---
*Total Active Memories: 33 (5 deleted)*
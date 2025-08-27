# VHDL Templates

This directory contains reusable VHDL templates that follow the project's coding standards.

## Template Guidelines

- Keep templates minimal and focused
- Ensure Verilog portability per the global rules
- Follow all VHDL-2008 coding standards
- Use proper signal prefixes: `ctrl_*`, `cfg_*`, `stat_*`
- Include clear examples of proper usage

## Available Templates

### Module Templates
- **Basic Module Template** - Standard entity/architecture structure
- **FSM Template** - State machine implementation with vector encoding
- **Counter Template** - Unsigned counter with explicit widths
- **Register Template** - Synchronous register with reset

### Layer Templates
- **Common Layer Template** - Package and utility function structure
- **Core Layer Template** - Pure logic implementation structure
- **Top Layer Template** - Integration and interface structure

### Testbench Templates
- **Basic Testbench Template** - Standard testbench structure
- **Clock Generator Template** - Clock and reset generation
- **Stimulus Template** - Test stimulus generation

## Usage

1. Copy the appropriate template file
2. Rename to match your module requirements
3. Modify according to your specific needs
4. Ensure compliance with project coding standards

## Important Notes

- Templates are starting points - customize as needed
- Always verify Verilog portability
- Follow the established naming conventions
- Include proper documentation and comments
- Test templates before using in production code

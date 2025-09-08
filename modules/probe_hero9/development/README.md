# ProbeHero9 Development Process

This directory contains development artifacts, prompts, and process documentation.

## Directory Structure

- **`prompts/`** - AI prompts and templates for code generation
- **`design-decisions/`** - Architecture and implementation decisions
- **`iterations/`** - Development iteration snapshots

## Development Workflow

### 1. Requirements Phase
- Start with interface requirements in `../requirements/interface/`
- Use prompts in `prompts/` to refine requirements
- Document decisions in `design-decisions/`

### 2. Implementation Phase
- Create iteration directories for each major phase
- Use prompts to generate VHDL code
- Track progress and decisions

### 3. Testing Phase
- Generate testbenches using prompts
- Document test results and coverage
- Refine implementation based on results

## AI Integration

### Prompt Templates
- **Interface Refinement**: `prompts/interface-refinement-prompt.md`
- **Code Generation**: `prompts/code-generation-prompt.md`
- **Testbench Creation**: `prompts/testbench-prompt.md`

### Design Decisions
- **Architecture**: `design-decisions/PH9-architecture-decisions.md`
- **Implementation**: `design-decisions/PH9-implementation-notes.md`

## Quick Links

- [Requirements](../requirements/README.md)
- [Interface Prompts](prompts/interface-refinement-prompt.md)
- [Code Generation Prompts](prompts/code-generation-prompt.md)

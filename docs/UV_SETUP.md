# UV Python Environment Setup

## Overview

This project uses `uv` for fast, reliable Python dependency management. All Python dependencies (CocotB, Pydantic, Moku API) are managed through `pyproject.toml`.

## Quick Start

### First Time Setup

```bash
# Install uv (if not already installed)
brew install uv

# Sync dependencies (creates .venv and installs packages)
uv sync --no-install-project
```

This creates a virtual environment in `.venv/` with all dependencies installed.

### Running Tests

```bash
# Option 1: Use uv run (automatically uses .venv)
cd tests/
uv run make TEST_MODULE=bench_framework_poc

# Option 2: Activate virtual environment manually
source .venv/bin/activate
cd tests/
make TEST_MODULE=bench_framework_poc
deactivate  # When done
```

## Dependencies

Defined in `pyproject.toml`:

### Core Dependencies
- **cocotb>=1.8.0** - CocotB testing framework
- **pydantic>=2.0.0** - Data validation (Bench Framework)
- **moku>=3.0.0** - Moku device API (Phase 3 hardware backend)

### Optional Dev Dependencies
- **pytest** - Python unit testing
- **black** - Code formatting
- **ruff** - Linting

## Common Commands

```bash
# Sync dependencies (after updating pyproject.toml)
uv sync --no-install-project

# Add new dependency
uv add <package-name>

# Remove dependency
uv remove <package-name>

# Update all dependencies
uv sync --upgrade

# Show installed packages
uv pip list

# Run any command in the uv environment
uv run <command>
```

## Why UV?

- **Fast**: 10-100x faster than pip
- **Reliable**: Reproducible dependency resolution
- **Modern**: Replaces pip, virtualenv, pip-tools in one tool
- **Compatible**: Works with standard Python packaging (pyproject.toml)

## Troubleshooting

### "No module named 'pydantic'" or similar

```bash
# Re-sync dependencies
uv sync --no-install-project
```

### CocotB not finding modules

Make sure you're running tests through `uv run`:

```bash
cd tests/
uv run make TEST_MODULE=<module>
```

### Python version issues

This project requires Python >=3.11. Check your version:

```bash
python3 --version
uv python list  # List available Python versions
```

## Integration with GHDL

UV manages Python dependencies only. GHDL (VHDL simulator) is still installed via Homebrew:

```bash
brew install ghdl
```

The CocotB framework (installed via uv) connects Python tests to GHDL simulation.

## .gitignore

The `.venv/` directory is git-ignored. Each developer runs `uv sync` to create their local environment.

## Migration from requirements.txt

This project has migrated from `requirements.txt` to `pyproject.toml`:

**Old way** (deprecated):
```bash
pip install -r requirements.txt
```

**New way**:
```bash
uv sync --no-install-project
```

## Reference

- UV Documentation: https://docs.astral.sh/uv/
- pyproject.toml specification: https://packaging.python.org/en/latest/specifications/pyproject-toml/

# Volo VHDL Quick Start

**Updated:** 2025-01-25 (Python Runner + CI/CD)

---

## Fresh Clone Setup

```bash
# Install UV (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync --no-install-project

# Verify setup
uv run python --version
uv run python -c "import cocotb; print(f'CocotB {cocotb.__version__}')"
```

---

## Common Commands

### Run Tests
```bash
# Single test
uv run python tests/run.py volo_clk_divider

# All tests
uv run python tests/run.py --all

# By category
uv run python tests/run.py --category=volo_common

# List available tests
uv run python tests/run.py --list

# Faster (no waveforms)
uv run python tests/run.py volo_clk_divider --no-waves
```

### Build VHDL
```bash
# Build all modules (from anywhere!)
uv run python scripts/build_vhdl.py

# Build specific entity (from anywhere!)
uv run python scripts/build_vhdl.py --entity volo_clk_divider

# Clean build artifacts
uv run python scripts/build_vhdl.py --clean
```

### Pre-Push Validation
```bash
# Run before committing
./scripts/validate_ci_setup.sh
```

---

## Test Categories

- `volo_common` (12 tests) - Core utilities
- `uart` (5 tests) - UART components
- `instruments` (2 tests) - Full instruments
- `mcc` (1 test) - MCC integration
- `examples` (1 test) - Example modules

---

## CI/CD Workflows

**Automatic triggers:**
- Every push → Smoke test (~2 min)
- Push to main/feature/** → Full test suite (~15 min)
- Pull requests → Full test suite

**View status:** `https://github.com/<user>/<repo>/actions`

---

## Adding New Tests

Edit `tests/test_configs.py`:

```python
"my_new_module": TestConfig(
    name="my_new_module",
    sources=[VOLO_COMMON / "core/my_module.vhd"],
    toplevel="my_module_entity_name",
    test_module="test_my_new_module",
    category="volo_common",
),
```

That's it! No Makefile updates needed.

---

## Helpful Resources

- **Tests:** `tests/README.md`
- **Build system:** `docs/BUILD-SYSTEM-EVALUATION.md`
- **CI/CD:** `docs/CI-CD-SETUP.md`
- **Migration:** `tests/PYTHON_RUNNER_MIGRATION.md`

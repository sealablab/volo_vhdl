# GitHub Actions CI/CD Workflows

This directory contains automated build and test workflows for the Volo VHDL project.

## Available Workflows

### 1. Smoke Test (`smoke-test.yml`)
**Triggers:** Every push to any branch
**Duration:** ~2-3 minutes
**Purpose:** Quick sanity check

**What it does:**
- Installs GHDL
- Builds MCC templates
- Compiles volo_common shared modules
- Verifies work library creation

**Use case:** Fast feedback for every commit. Catches basic compilation errors immediately.

---

### 2. Build and Test (`build-and-test.yml`)
**Triggers:** Pushes to `main` or `feature/**` branches, PRs to `main`
**Duration:** ~10-15 minutes
**Purpose:** Full integration testing

**What it does:**
- Installs GHDL and UV
- Builds ALL modules with dependency resolution
- Runs complete CocotB test suite:
  - `clk_divider_core` (7 tests)
  - `moku_voltage_pkg` (3 tests)
  - `moku_pct_pkg` (9 tests)
  - `emfi_seq_top` (8 tests)
  - `mcc_primitives` (validation tests)
- Uploads test results as artifacts
- Uploads waveforms on failure

**Use case:** Comprehensive validation before merging to main.

---

## Workflow Status

Add this badge to your README.md to show build status:

```markdown
![Build and Test](https://github.com/<username>/<repo>/actions/workflows/build-and-test.yml/badge.svg)
```

## Local Testing Before Push

To ensure your changes will pass CI:

```bash
# Test the build (matches CI build step)
cd modules
make clean && make compile

# Test the suite (matches CI test steps)
cd ../tests
uv run make TEST_MODULE=clk_divider_core WAVES=0
uv run make TEST_MODULE=moku_voltage_pkg WAVES=0
uv run make TEST_MODULE=moku_pct_pkg WAVES=0
uv run make TEST_MODULE=emfi_seq_top WAVES=0
uv run make TEST_MODULE=mcc_primitives WAVES=0
```

## Adding New Tests to CI

When you create a new CocotB test module:

1. Add test configuration to `tests/Makefile`
2. Add a new test step to `build-and-test.yml`:

```yaml
- name: Run CocotB test - your_new_module
  working-directory: tests
  run: |
    uv run make TEST_MODULE=your_new_module WAVES=0
```

## Artifact Retention

- **Test results** (`results.xml`): 30 days
- **Waveforms** (on failure): 7 days

Download artifacts from the Actions tab on GitHub.

## Troubleshooting CI Failures

### Build Failures
- Check GHDL version compatibility (Ubuntu latest = GHDL 2.0+)
- Verify all source files use `--std=08` compatible features
- Check for absolute paths in code (should be relative)

### Test Failures
- Download waveform artifacts from failed run
- Run locally with `WAVES=1` to generate waveforms
- Check CocotB version compatibility

### UV/Python Issues
- Verify `pyproject.toml` and `uv.lock` are committed
- Check Python version requirements in `pyproject.toml`
- Ensure all test dependencies are in `[project.dependencies]`

## Future Enhancements

Potential additions to CI/CD pipeline:

- [ ] Automated dependency graph generation
- [ ] Code coverage reporting
- [ ] Synthesis size estimation (resource usage)
- [ ] Automatic MCC package building
- [ ] Performance regression testing
- [ ] Documentation generation (Sphinx/Doxygen)

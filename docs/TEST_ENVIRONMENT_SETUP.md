# Test Environment Setup

This guide covers setting up your environment for running VOLO tests.

## Prerequisites

### 1. Python (3.10+)
```bash
# Check Python version
python3 --version

# macOS (if needed)
brew install python@3.11

# Ubuntu/Debian (if needed)
sudo apt update
sudo apt install python3.11 python3.11-venv
```

### 2. UV Package Manager
```bash
# Install UV (recommended method)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or via pip
pip install uv

# Verify installation
uv --version
```

### 3. GHDL Simulator
```bash
# macOS
brew install ghdl

# Ubuntu/Debian
sudo apt install ghdl

# Verify installation
ghdl --version
```

### 4. GTKWave (Optional - for waveform viewing)
```bash
# macOS
brew install --cask gtkwave

# Ubuntu/Debian
sudo apt install gtkwave

# Verify installation
gtkwave --version
```

## Initial Setup (One Time)

### 1. Clone Repository
```bash
git clone https://github.com/yourorg/volo_vhdl.git
cd volo_vhdl
```

### 2. Initialize Python Environment
```bash
# UV automatically creates and manages the virtual environment
uv sync --no-install-project

# This installs all dependencies from pyproject.toml:
# - cocotb (simulation framework)
# - pytest (test runner)
# - pydantic (data validation)
# - rich (terminal formatting)
```

### 3. Verify Setup
```bash
# Run a simple test to verify everything works
uv run python tests/run.py --list

# Should show available test modules
```

## Common Issues and Solutions

### Issue: "command not found: uv"
**Solution:** Add UV to your PATH:
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc  # or ~/.zshrc
```

### Issue: "GHDL: command not found"
**Solution:** GHDL not installed or not in PATH:
```bash
# Check if installed
which ghdl

# If not found, reinstall
brew install ghdl  # macOS
```

### Issue: "ModuleNotFoundError: No module named 'cocotb'"
**Solution:** Dependencies not installed:
```bash
# Reinstall dependencies
uv sync --no-install-project

# Verify cocotb is installed
uv pip list | grep cocotb
```

### Issue: Tests hang or timeout
**Solution:** Check GHDL version compatibility:
```bash
# Should be version 2.0+ for best results
ghdl --version

# Update if needed
brew upgrade ghdl  # macOS
```

### Issue: "Permission denied" errors
**Solution:** Fix file permissions:
```bash
# Make test scripts executable
chmod +x tests/run.py
chmod +x tests/ghdl_output_filter.py
```

## Environment Variables

### Optional Configuration
```bash
# Add to ~/.bashrc or ~/.zshrc for permanent settings

# Default to normal verbosity (instead of minimal)
export COCOTB_VERBOSITY=NORMAL

# Disable waveform generation by default (faster tests)
export WAVES=0

# Use less aggressive GHDL filtering
export GHDL_FILTER_LEVEL=normal
```

## Docker Alternative (Isolated Environment)

If you prefer a containerized environment:

```dockerfile
# Dockerfile (create in repo root)
FROM ghdl/ghdl:ubuntu20-llvm-10

RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    curl \
    git

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /workspace
COPY . .
RUN uv sync --no-install-project

CMD ["uv", "run", "python", "tests/run.py", "--list"]
```

Build and run:
```bash
docker build -t volo-test .
docker run -it volo-test uv run python tests/run.py ds1120_pd_volo
```

## VS Code Integration

### Recommended Extensions
```json
// .vscode/extensions.json
{
  "recommendations": [
    "mshr-h.veriloghdl",
    "leafvmaple.vhdl",
    "ms-python.python",
    "ms-python.vscode-pylance"
  ]
}
```

### Task Configuration
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run P1 Tests",
      "type": "shell",
      "command": "uv run python tests/run.py ${input:moduleName}",
      "group": "test"
    },
    {
      "label": "Run P2 Tests",
      "type": "shell",
      "command": "TEST_LEVEL=P2_INTERMEDIATE uv run python tests/run.py ${input:moduleName}",
      "group": "test"
    }
  ],
  "inputs": [
    {
      "id": "moduleName",
      "type": "promptString",
      "description": "Module name (e.g., ds1120_pd_volo)"
    }
  ]
}
```

## Verification Checklist

After setup, verify everything works:

- [ ] `uv --version` shows version 0.1.0+
- [ ] `ghdl --version` shows version 2.0+
- [ ] `uv run python tests/run.py --list` shows test modules
- [ ] `uv run python tests/run.py clk_divider_core` passes
- [ ] `WAVES=1 uv run python tests/run.py clk_divider_core` generates `sim_build/dump.vcd`

## Need Help?

- Check existing tests: `tests/ds1120_pd_volo_tests/` for examples
- Review test standard: `tests/README.md`
- Ask in team chat with error messages and environment details

---

*Last Updated: 2025-01-27*
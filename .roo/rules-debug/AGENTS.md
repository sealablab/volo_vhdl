# Project Debug Guidelines (Roo Context)

## 📚 Primary Source: Serena MCP Memory System

Debugging patterns and solutions are maintained in **Serena MCP** at `.serena/memories/`.

**Key Memory:**
- `ghdl_patterns_and_solutions` - GHDL-specific debug info (legacy but useful)

## ⚡ Quick Debug Tips

### CocotB Testing (Current Standard)
```bash
cd tests/
make TEST_MODULE=module_name              # Run test
make TEST_MODULE=module_name WAVES=1      # With waveforms
COCOTB_LOG_LEVEL=DEBUG make TEST_MODULE=...  # Verbose logging
```

**View waveforms:**
```bash
gtkwave tests/dump.ghw
```

### GHDL Simulation (Legacy/Backend)
- Use `--wave=wave.ghw` for waveform generation
- Compile order: packages → entities → testbenches
- Always use `--std=08` flag

### Common Issues

**CocotB Tests:**
- Signal not updating: Add `await ClockCycles(dut.clk, 1)` after assignment
- Test hangs: Use `wait_for_value()` with timeout (see `conftest.py`)
- Metavalue warnings: Set inputs before reset

**VHDL/GHDL:**
- Multiple drivers: Check for 'U' or 'X' values in waveforms
- Unintended latches: Ensure all branches assign outputs
- Missing signals: Verify `work` library compilation order

## 📖 For Complete Details

Run `mcp__serena__read_memory ghdl_patterns_and_solutions` for GHDL-specific tips.

See `tests/README.md` for CocotB debugging guide.

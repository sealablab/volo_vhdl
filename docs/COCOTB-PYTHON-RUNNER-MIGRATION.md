# CocotB Python Runner Migration Plan

**Date:** 2025-01-25
**Status:** READY TO EXECUTE
**Approach:** Fast and complete migration (breaking changes accepted)

---

## Why This Migration?

✅ **Native Python** - No more Makefile maintenance
✅ **Auto-discovery** - Test files detected automatically
✅ **UV-friendly** - Works seamlessly with `pyproject.toml`
✅ **Type hints** - Better IDE support and code completion
✅ **CocotB 2.0+** - Already installed, ready to use
✅ **LiquidInstruments approved** - CocotB is their standard

---

## Current State Analysis

**Test Files:** 26 Python test modules
**CocotB Version:** 2.0.0 ✅ (Python runner available)
**GHDL:** Already working with CocotB
**Dependencies:** Minimal (mostly volo_common)

**Makefile pain points:**
- 21 separate `ifeq` blocks (manual maintenance)
- Hardcoded path: `VOLO_COMMON = $(MODULES_DIR)/volo_common` (wrong after reorganization)
- Duplication between test configurations
- No auto-discovery

---

## Migration Strategy

### Phase 1: Create Python Runner Infrastructure (30 minutes)
1. Create `tests/test_configs.py` - Auto-discovered test configurations
2. Create `tests/run.py` - Main test runner using CocotB Python API
3. Keep `conftest.py` - Shared utilities (no changes needed)

### Phase 2: Test and Validate (30 minutes)
1. Run 2-3 tests with new runner
2. Fix any path issues
3. Verify waveform generation works

### Phase 3: Update CI/CD (15 minutes)
1. Update GitHub Actions workflows
2. Replace `make TEST_MODULE=X` with `python tests/run.py X`
3. Test CI pipeline

### Phase 4: Cleanup (15 minutes)
1. Archive `tests/Makefile` → `tests/Makefile.legacy`
2. Update documentation (`CLAUDE.md`, `AGENTS.md`, `tests/README.md`)
3. Commit and push

**Total time:** ~90 minutes

---

## New Architecture

### File Structure
```
tests/
├── run.py                  # Main test runner (NEW)
├── test_configs.py         # Test configurations (NEW)
├── conftest.py             # Shared utilities (KEEP)
├── test_*.py               # Individual tests (KEEP)
├── *_tb_wrapper.vhd        # VHDL wrappers (KEEP)
├── Makefile.legacy         # Archived old Makefile
└── README.md               # Updated docs
```

### Usage Examples

```bash
# Run single test
uv run python tests/run.py volo_clk_divider

# Run all tests
uv run python tests/run.py --all

# Run with waveforms disabled (faster)
uv run python tests/run.py volo_clk_divider --no-waves

# List available tests
uv run python tests/run.py --list

# Run specific category
uv run python tests/run.py --category=volo_common
```

---

## Implementation Details

### test_configs.py (Auto-discovered)
```python
"""
Auto-discovered test configurations for CocotB Python Runner.
Add new tests here - no Makefile updates needed!
"""

from pathlib import Path
from dataclasses import dataclass
from typing import List

PROJECT_ROOT = Path(__file__).parent.parent
MODULES = PROJECT_ROOT / "modules"
VOLO_COMMON = MODULES / "shared/volo_common"
TESTS = PROJECT_ROOT / "tests"

@dataclass
class TestConfig:
    """Configuration for a single CocotB test"""
    name: str
    sources: List[Path]
    toplevel: str
    test_module: str
    category: str = "misc"
    ghdl_args: List[str] = None

    def __post_init__(self):
        if self.ghdl_args is None:
            self.ghdl_args = ["--std=08"]


# Test configurations (auto-discovered from test_*.py files)
TESTS_CONFIG = {
    # === Volo Common Core Tests ===
    "volo_clk_divider": TestConfig(
        name="volo_clk_divider",
        sources=[VOLO_COMMON / "core/volo_clk_divider.vhd"],
        toplevel="clk_divider_core",
        test_module="test_volo_clk_divider",
        category="volo_common",
    ),

    "edge_detector": TestConfig(
        name="edge_detector",
        sources=[VOLO_COMMON / "core/volo_edge_detector.vhd"],
        toplevel="edge_detector",
        test_module="test_edge_detector",
        category="volo_common",
    ),

    "pulse_generator": TestConfig(
        name="pulse_generator",
        sources=[VOLO_COMMON / "core/volo_pulse_generator.vhd"],
        toplevel="pulse_generator",
        test_module="test_pulse_generator",
        category="volo_common",
    ),

    "counter_nbit": TestConfig(
        name="counter_nbit",
        sources=[VOLO_COMMON / "core/volo_counter_nbit.vhd"],
        toplevel="counter_nbit",
        test_module="test_counter_nbit",
        category="volo_common",
    ),

    "delay_line": TestConfig(
        name="delay_line",
        sources=[VOLO_COMMON / "core/volo_delay_line.vhd"],
        toplevel="delay_line",
        test_module="test_delay_line",
        category="volo_common",
    ),

    "comparator": TestConfig(
        name="comparator",
        sources=[VOLO_COMMON / "core/volo_comparator.vhd"],
        toplevel="volo_comparator",
        test_module="test_comparator",
        category="volo_common",
    ),

    "synchronizer": TestConfig(
        name="synchronizer",
        sources=[VOLO_COMMON / "core/volo_synchronizer.vhd"],
        toplevel="volo_synchronizer",
        test_module="test_synchronizer",
        category="volo_common",
    ),

    "debouncer": TestConfig(
        name="debouncer",
        sources=[VOLO_COMMON / "core/volo_debouncer.vhd"],
        toplevel="volo_debouncer",
        test_module="test_debouncer",
        category="volo_common",
    ),

    "mux": TestConfig(
        name="mux",
        sources=[VOLO_COMMON / "core/volo_mux.vhd"],
        toplevel="volo_mux",
        test_module="test_mux",
        category="volo_common",
    ),

    "pwm": TestConfig(
        name="pwm",
        sources=[VOLO_COMMON / "core/volo_pwm.vhd"],
        toplevel="volo_pwm",
        test_module="test_pwm",
        category="volo_common",
    ),

    # === Volo Common Package Tests ===
    "volo_voltage_pkg": TestConfig(
        name="volo_voltage_pkg",
        sources=[
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            TESTS / "moku_voltage_pkg_tb_wrapper.vhd",
        ],
        toplevel="moku_voltage_pkg_tb_wrapper",
        test_module="test_volo_voltage_pkg",
        category="volo_common",
    ),

    "moku_pct_pkg": TestConfig(
        name="moku_pct_pkg",
        sources=[
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            VOLO_COMMON / "common/Moku_Pct_pkg.vhd",
            TESTS / "moku_pct_pkg_tb_wrapper.vhd",
        ],
        toplevel="moku_pct_pkg_tb_wrapper",
        test_module="test_moku_pct_pkg",
        category="volo_common",
    ),

    # === UART Tests ===
    "uart_baud_gen": TestConfig(
        name="uart_baud_gen",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
        ],
        toplevel="uart_baud_gen",
        test_module="test_uart_baud_gen",
        category="uart",
    ),

    "uart_tx_core": TestConfig(
        name="uart_tx_core",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
        ],
        toplevel="uart_tx_core",
        test_module="test_uart_tx_core",
        category="uart",
    ),

    # === Instrument Tests ===
    "emfi_seq_top": TestConfig(
        name="emfi_seq_top",
        sources=[
            VOLO_COMMON / "core/volo_clk_divider.vhd",
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_stair.vhd",
            MODULES / "instruments/EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            MODULES / "instruments/EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_emfi_seq_top",
        category="instruments",
    ),

    "mcc_primitives": TestConfig(
        name="mcc_primitives",
        sources=[
            VOLO_COMMON / "core/volo_clk_divider.vhd",
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_fsm.vhd",
            MODULES / "instruments/EMFI-Seq/core/EMFI_Seq_stair.vhd",
            MODULES / "instruments/EMFI-Seq/top/EMFI_Seq.vhd",
            PROJECT_ROOT / "mcc_templates/CustomWrapper_test_stub.vhd",
            MODULES / "instruments/EMFI-Seq/top/Top.vhd",
        ],
        toplevel="customwrapper",
        test_module="test_mcc_primitives",
        category="mcc",
    ),

    # === SimpleSerial Tests ===
    "simpleserial_v1_tx": TestConfig(
        name="simpleserial_v1_tx",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
            VOLO_COMMON / "core/volo_simpleserial_v1_tx.vhd",
        ],
        toplevel="simpleserial_v1_tx",
        test_module="test_simpleserial_v1_tx",
        category="uart",
    ),

    "simpleserial_v2_tx": TestConfig(
        name="simpleserial_v2_tx",
        sources=[
            VOLO_COMMON / "common/volo_uart_pkg.vhd",
            VOLO_COMMON / "common/volo_cobs_pkg.vhd",
            VOLO_COMMON / "core/volo_uart_baud_gen.vhd",
            VOLO_COMMON / "core/volo_uart_tx_core.vhd",
            VOLO_COMMON / "core/volo_simpleserial_v2_tx.vhd",
        ],
        toplevel="simpleserial_v2_tx",
        test_module="test_simpleserial_v2_tx",
        category="uart",
    ),

    # === FSM Example ===
    "fsm_example": TestConfig(
        name="fsm_example",
        sources=[
            VOLO_COMMON / "common/volo_voltage_pkg.vhd",
            VOLO_COMMON / "observer/fsm_observer.vhd",
            MODULES / "examples/fsm_example/core/fsm_example_core.vhd",
            MODULES / "examples/fsm_example/top/fsm_example_top.vhd",
        ],
        toplevel="fsm_example_top",
        test_module="test_fsm_example",
        category="examples",
    ),
}


def get_test_names():
    """Get list of all test names"""
    return sorted(TESTS_CONFIG.keys())


def get_tests_by_category(category: str):
    """Get tests filtered by category"""
    return {
        name: config
        for name, config in TESTS_CONFIG.items()
        if config.category == category
    }


def get_categories():
    """Get list of all unique categories"""
    return sorted(set(config.category for config in TESTS_CONFIG.values()))
```

---

## Breaking Changes (Intentional)

1. ❌ `tests/Makefile` → `tests/Makefile.legacy` (archived)
2. ❌ Environment variable `TEST_MODULE` → CLI argument
3. ❌ `make TEST_MODULE=X` → `python tests/run.py X`
4. ✅ All test files unchanged (only runner changes)
5. ✅ `conftest.py` unchanged (utilities work as-is)
6. ✅ VHDL wrapper files unchanged

---

## Rollback Plan

If migration fails:
```bash
mv tests/Makefile.legacy tests/Makefile
git restore tests/run.py tests/test_configs.py
```

Tests still work with old Makefile system.

---

## Success Criteria

✅ All 26 tests discoverable via `python tests/run.py --list`
✅ Sample test runs successfully with Python runner
✅ Waveforms generate correctly
✅ CI/CD pipeline passes with new runner
✅ Documentation updated

---

## Next Steps

1. **Execute migration:** Create `run.py` and `test_configs.py`
2. **Test locally:** Run 2-3 tests to verify
3. **Update CI/CD:** Modify GitHub Actions workflows
4. **Document:** Update `CLAUDE.md` and `AGENTS.md`
5. **Commit:** Push to `feature/cicd` branch

**Ready to proceed?** Say "do it" and I'll create the files immediately.

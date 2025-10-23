"""
Bench Framework Phase 1 Proof of Concept

Tests the bench configuration framework with simple_counter module.
Demonstrates unified abstraction working with simulation backend.

Test: Counter → Oscilloscope bench configuration
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from conftest import setup_clock, reset_active_low

# Import bench framework
import sys
sys.path.insert(0, str(cocotb.plusargs.get('BENCH_FRAMEWORK_PATH', 'tests')))
from bench_framework import BenchConfig, SimulationBackend
from bench_framework.config import MOKU_GO, SlotConfig, Connection


@cocotb.test()
async def test_bench_framework_basic_config(dut):
    """Test 1: Basic bench configuration can be created and validated"""
    dut._log.info("=" * 70)
    dut._log.info("Test 1: Basic Bench Configuration")
    dut._log.info("=" * 70)

    # Create a simple bench configuration
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                settings={},
                bitstream='simple_counter.tar.gz'
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'sample_rate': 1e6, 'channels': ['count_out']}
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),
        ],
        metadata={'name': 'Counter PoC', 'version': '1.0'}
    )

    # Validate configuration
    errors = config.validate_connections()
    assert len(errors) == 0, f"Configuration validation failed: {errors}"

    dut._log.info(f"Platform: {config.platform['name']}")
    dut._log.info(f"Slots: {len(config.slots)}")
    dut._log.info(f"Connections: {len(config.connections)}")
    dut._log.info("✓ Configuration validation PASSED")


@cocotb.test()
async def test_bench_framework_simulation_backend(dut):
    """Test 2: SimulationBackend setup and initialization"""
    dut._log.info("=" * 70)
    dut._log.info("Test 2: Simulation Backend Setup")
    dut._log.info("=" * 70)

    # Setup DUT
    await setup_clock(dut)
    dut.clk_en.value = 1
    dut.enable.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Create configuration
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile', settings={}),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'sample_rate': 1e6, 'channels': ['count_out']}
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),
        ]
    )

    # Create simulation backend
    backend = SimulationBackend.from_config(config, dut)
    await backend.setup()

    dut._log.info(f"Backend: {backend}")
    dut._log.info(f"Simulators: {len(backend.simulators)}")
    assert backend._setup_complete, "Backend setup should be complete"
    dut._log.info("✓ Backend setup PASSED")


@cocotb.test()
async def test_bench_framework_counter_capture(dut):
    """Test 3: Full workflow - Counter → Oscilloscope data capture"""
    dut._log.info("=" * 70)
    dut._log.info("Test 3: Counter → Oscilloscope Data Capture")
    dut._log.info("=" * 70)

    # Setup DUT
    await setup_clock(dut)
    dut.clk_en.value = 1
    dut.enable.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Create bench configuration
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                settings={},
                bitstream='simple_counter.tar.gz'
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={
                    'sample_rate': 100e6,  # 100 MHz sample rate (matches clock)
                    'channels': ['count_out']
                }
            )
        },
        connections=[
            Connection(source='Slot1OutA', destination='Slot2InA'),
        ],
        metadata={'name': 'Counter Capture Test'}
    )

    # Create and setup backend
    backend = SimulationBackend.from_config(config, dut)
    await backend.setup()

    # Run for 100 microseconds
    dut._log.info("Running bench for 100 µs...")
    data = await backend.run(duration_ms=0.1)  # 100 µs = 0.1 ms

    # Get oscilloscope data
    osc = backend.get_instrument('Oscilloscope')
    osc_data = osc.get_data('count_out')

    dut._log.info(f"Captured {osc_data['sample_count']} samples")
    dut._log.info(f"First 5 values: {osc_data['values'][:5]}")
    dut._log.info(f"Last 5 values: {osc_data['values'][-5:]}")

    # Verify we captured data
    assert osc_data['sample_count'] > 0, "Should have captured samples"

    # Verify counter is incrementing
    is_incrementing = osc.verify_incrementing('count_out', start_sample=10, count=20)
    assert is_incrementing, "Counter should increment by 1 each sample"

    dut._log.info("✓ Counter capture and verification PASSED")


@cocotb.test()
async def test_bench_framework_get_instrument(dut):
    """Test 4: Get instrument by slot number and by type name"""
    dut._log.info("=" * 70)
    dut._log.info("Test 4: Get Instrument Interface")
    dut._log.info("=" * 70)

    # Setup DUT
    await setup_clock(dut)
    dut.clk_en.value = 1
    dut.enable.value = 1
    await reset_active_low(dut, rst_signal="n_reset")

    # Create configuration
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile', settings={}),
            2: SlotConfig(instrument='Oscilloscope', settings={'channels': ['count_out']})
        },
        connections=[]
    )

    backend = SimulationBackend.from_config(config, dut)
    await backend.setup()

    # Get by slot number
    osc_by_slot = backend.get_instrument(2)
    assert osc_by_slot is not None, "Should get instrument by slot number"

    # Get by instrument type
    osc_by_type = backend.get_instrument('Oscilloscope')
    assert osc_by_type is not None, "Should get instrument by type name"

    # Should be the same instance
    assert osc_by_slot is osc_by_type, "Should return same instance"

    dut._log.info("✓ Get instrument interface PASSED")


@cocotb.test()
async def test_bench_framework_validation(dut):
    """Test 5: Configuration validation catches errors"""
    dut._log.info("=" * 70)
    dut._log.info("Test 5: Configuration Validation")
    dut._log.info("=" * 70)

    # Invalid connection (non-existent source)
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='Oscilloscope', settings={})
        },
        connections=[
            Connection(source='InvalidSource', destination='Slot1InA')
        ]
    )

    errors = config.validate_connections()
    assert len(errors) > 0, "Should detect invalid connection"
    dut._log.info(f"Detected validation errors: {errors}")

    # Valid configuration
    valid_config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='Oscilloscope', settings={})
        },
        connections=[
            Connection(source='Input1', destination='Slot1InA')
        ]
    )

    errors = valid_config.validate_connections()
    assert len(errors) == 0, "Valid configuration should pass"

    dut._log.info("✓ Configuration validation PASSED")


# Test completion marker
@cocotb.test()
async def test_all_tests_passed(dut):
    """Final test marker"""
    dut._log.info("=" * 70)
    dut._log.info("ALL BENCH FRAMEWORK POC TESTS PASSED")
    dut._log.info("=" * 70)

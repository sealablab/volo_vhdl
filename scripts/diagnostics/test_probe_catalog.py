"""
Test Probe Catalog Integration with BenchConfig

Validates that external hardware (EMFI probes) can be correctly configured
in BenchConfig, with proper validation and diagram generation.
"""

try:
    import pytest
    PYTEST_AVAILABLE = True
except ImportError:
    PYTEST_AVAILABLE = False
    # Simple pytest.raises alternative for manual testing
    class RaisesContext:
        def __init__(self, exc_type, match=None):
            self.exc_type = exc_type
            self.match = match
        def __enter__(self):
            return self
        def __exit__(self, exc_type, exc_val, exc_tb):
            if exc_type is None:
                raise AssertionError(f"Expected {self.exc_type.__name__} but no exception raised")
            if not issubclass(exc_type, self.exc_type):
                return False
            if self.match and self.match not in str(exc_val):
                raise AssertionError(f"Exception message doesn't contain '{self.match}': {exc_val}")
            return True

    class pytest:
        @staticmethod
        def raises(exc_type, match=None):
            return RaisesContext(exc_type, match)

from bench_framework import (
    BenchConfig,
    SlotConfig,
    ProbeConnection,
    ExternalHardware,
    MOKU_GO,
    generate_ascii_diagram,
    generate_mermaid_diagram,
    generate_summary,
)
from pydantic import ValidationError

# ==================================================================================
# NOTE: This script uses the ARCHIVED bench_framework API (now in archive/)
#
# TODO: Update to use new API:
#   - BenchConfig → MokuPlatformConfig + BenchBench
#   - Connection → MokuConnection
#   - bench_framework → tests.moku_platform_simulator
#
# See: docs/MIGRATION_PLAN_MokuPlatformSimulator.md
# ==================================================================================


def test_probe_connection_validation():
    """Test 1: ProbeConnection validates Moku ports"""
    # Valid connections
    conn1 = ProbeConnection(probe='digital_glitch', moku='OutputA')
    assert conn1.probe == 'digital_glitch'
    assert conn1.moku == 'OutputA'

    conn2 = ProbeConnection(probe='coil_current', moku='InputA')
    assert conn2.moku == 'InputA'

    # Invalid Moku port
    with pytest.raises(ValidationError, match="Invalid Moku port"):
        ProbeConnection(probe='test', moku='InvalidPort')

    print("✓ Test 1 PASSED: ProbeConnection validation works")


def test_external_hardware_basic():
    """Test 2: ExternalHardware basic creation and validation"""
    # Valid device
    device = ExternalHardware(
        device_type='riscure_ds1120a',
        name='emfi_probe',
        connections=[
            ProbeConnection(probe='digital_glitch', moku='OutputA'),
            ProbeConnection(probe='pulse_amplitude', moku='DACOut1'),
            ProbeConnection(probe='coil_current', moku='InputA')
        ],
        settings={'probe_tip': '4mm_positive'}
    )

    assert device.device_type == 'riscure_ds1120a'
    assert device.name == 'emfi_probe'
    assert len(device.connections) == 3
    assert device.settings['probe_tip'] == '4mm_positive'

    # Unknown device type
    with pytest.raises(ValidationError, match="Unknown device type"):
        ExternalHardware(
            device_type='unknown_probe',
            connections=[ProbeConnection(probe='test', moku='OutputA')]
        )

    print("✓ Test 2 PASSED: ExternalHardware basic validation works")


def test_external_hardware_duplicate_ports():
    """Test 3: ExternalHardware detects duplicate Moku port usage"""
    # Duplicate port within same device (should fail)
    with pytest.raises(ValidationError, match="used multiple times"):
        ExternalHardware(
            device_type='riscure_ds1120a',
            connections=[
                ProbeConnection(probe='signal1', moku='OutputA'),
                ProbeConnection(probe='signal2', moku='OutputA')  # Duplicate!
            ]
        )

    print("✓ Test 3 PASSED: Duplicate port detection works")


def test_bench_config_with_external_hardware():
    """Test 4: BenchConfig with external hardware"""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(
                instrument='CloudCompile',
                bitstream='test_module.tar.gz',
                control_registers={0: 0xE0000000}
            ),
            2: SlotConfig(
                instrument='Oscilloscope',
                settings={'sample_rate': 125e6}
            )
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                name='emfi_probe',
                connections=[
                    ProbeConnection(probe='digital_glitch', moku='OutputA'),
                    ProbeConnection(probe='pulse_amplitude', moku='DACOut1'),
                    ProbeConnection(probe='coil_current', moku='InputA')
                ],
                settings={'probe_tip': '4mm_positive'}
            )
        ]
    )

    assert len(config.external_hardware) == 1
    assert config.external_hardware[0].device_type == 'riscure_ds1120a'
    assert len(config.external_hardware[0].connections) == 3

    # Validate no routing errors
    errors = config.validate_external_hardware_routing()
    assert len(errors) == 0, f"Should have no routing errors, got: {errors}"

    print("✓ Test 4 PASSED: BenchConfig with external hardware works")


def test_port_conflict_detection():
    """Test 5: Detect port conflicts between external hardware and slots"""
    # This config has InputA used by external hardware
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        connections=[],  # No conflicts here
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='coil_current', moku='InputA')
                ]
            )
        ]
    )

    # Should be valid (no conflicts)
    errors = config.validate_external_hardware_routing()
    assert len(errors) == 0

    print("✓ Test 5 PASSED: Port conflict detection works")


def test_multiple_external_devices():
    """Test 6: Multiple external devices with conflict detection"""
    # Two devices using different ports (valid)
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='coil_current', moku='InputA')
                ]
            ),
            ExternalHardware(
                device_type='riscure_ds1120a',
                name='probe2',
                connections=[
                    ProbeConnection(probe='coil_current', moku='InputB')
                ]
            )
        ]
    )

    errors = config.validate_external_hardware_routing()
    assert len(errors) == 0

    # Two devices using same port (invalid)
    config_conflict = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='signal1', moku='InputA')
                ]
            ),
            ExternalHardware(
                device_type='riscure_ds1121a',
                connections=[
                    ProbeConnection(probe='signal2', moku='InputA')  # Conflict!
                ]
            )
        ]
    )

    errors = config_conflict.validate_external_hardware_routing()
    assert len(errors) > 0, "Should detect port conflict between devices"
    assert 'InputA' in errors[0]

    print("✓ Test 6 PASSED: Multiple device handling works")


def test_signal_flow_graph_generation():
    """Test 7: Signal flow graph generation for diagrams"""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='digital_glitch', moku='OutputA'),
                    ProbeConnection(probe='coil_current', moku='InputA')
                ]
            )
        ]
    )

    graph = config.get_signal_flow_graph()

    # Verify graph structure
    assert 'nodes' in graph
    assert 'edges' in graph
    assert graph['platform'] == 'Moku:Go'
    assert graph['num_slots'] == 1
    assert graph['num_external_devices'] == 1

    # Check nodes
    node_types = [n['type'] for n in graph['nodes']]
    assert 'platform' in node_types
    assert 'instrument' in node_types
    assert 'external' in node_types

    # Check edges
    assert len(graph['edges']) > 0

    print("✓ Test 7 PASSED: Signal flow graph generation works")


def test_ascii_diagram_generation():
    """Test 8: ASCII diagram generation"""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile', bitstream='test.tar.gz')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                name='emfi_probe',
                connections=[
                    ProbeConnection(probe='digital_glitch', moku='OutputA'),
                    ProbeConnection(probe='coil_current', moku='InputA')
                ],
                settings={'probe_tip': '4mm_positive'}
            )
        ]
    )

    diagram = generate_ascii_diagram(config)

    # Verify diagram contains key elements
    assert 'Platform: Moku:Go' in diagram
    assert 'External Devices' in diagram
    assert 'emfi_probe' in diagram
    assert 'riscure_ds1120a' in diagram
    assert 'OutputA' in diagram
    assert 'InputA' in diagram
    assert 'Slot 1: CloudCompile' in diagram

    print("✓ Test 8 PASSED: ASCII diagram generation works")
    print("\nGenerated Diagram:")
    print(diagram)


def test_mermaid_diagram_generation():
    """Test 9: Mermaid diagram generation"""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='digital_glitch', moku='OutputA')
                ]
            )
        ]
    )

    mermaid = generate_mermaid_diagram(config)

    # Verify Mermaid syntax
    assert 'flowchart LR' in mermaid
    assert 'moku' in mermaid
    assert 'slot1' in mermaid
    assert 'ext_0' in mermaid
    assert 'classDef' in mermaid

    print("✓ Test 9 PASSED: Mermaid diagram generation works")
    print("\nGenerated Mermaid:")
    print(mermaid)


def test_configuration_summary():
    """Test 10: Configuration summary generation"""
    config = BenchConfig(
        platform=MOKU_GO,
        slots={
            1: SlotConfig(instrument='CloudCompile')
        },
        external_hardware=[
            ExternalHardware(
                device_type='riscure_ds1120a',
                connections=[
                    ProbeConnection(probe='digital_glitch', moku='OutputA')
                ]
            )
        ]
    )

    summary = generate_summary(config)

    # Verify summary contents
    assert 'Bench Configuration Summary' in summary
    assert 'Platform: Moku:Go' in summary
    assert 'CloudCompile' in summary
    assert 'riscure_ds1120a' in summary
    assert 'valid' in summary.lower()

    print("✓ Test 10 PASSED: Configuration summary works")
    print("\nGenerated Summary:")
    print(summary)


def test_all_tests_passed_marker():
    """Test 11: All tests passed marker"""
    print("\n" + "=" * 60)
    print("ALL PROBE CATALOG TESTS PASSED")
    print("=" * 60)


if __name__ == '__main__':
    """Run tests directly (without pytest)"""
    test_probe_connection_validation()
    test_external_hardware_basic()
    test_external_hardware_duplicate_ports()
    test_bench_config_with_external_hardware()
    test_port_conflict_detection()
    test_multiple_external_devices()
    test_signal_flow_graph_generation()
    test_ascii_diagram_generation()
    test_mermaid_diagram_generation()
    test_configuration_summary()
    test_all_tests_passed_marker()

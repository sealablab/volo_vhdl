"""
Hardware Backend

MCC API-based hardware backend for deploying to real Moku devices.
"""

from typing import Any
import time
from .backend import Backend
from moku_models.moku_config import MokuPlatformConfig
from models.bench.benchbench import BenchBench

# Import Moku API
try:
    from moku.instruments import (
        MultiInstrument, Oscilloscope, WaveformGenerator, CloudCompile, Datalogger,
        SpectrumAnalyzer, LogicAnalyzer, Phasemeter, LockInAmp, PIDController,
        FrequencyResponseAnalyzer, DigitalFilterBox, FIRFilterBuilder,
        ArbitraryWaveformGenerator, TimeFrequencyAnalyzer, LaserLockBox
    )
    MOKU_AVAILABLE = True
except ImportError:
    MOKU_AVAILABLE = False
    # Define stubs for type hints
    MultiInstrument = Any
    Oscilloscope = Any
    WaveformGenerator = Any
    CloudCompile = Any
    Datalogger = Any
    SpectrumAnalyzer = Any
    LogicAnalyzer = Any
    Phasemeter = Any
    LockInAmp = Any
    PIDController = Any
    FrequencyResponseAnalyzer = Any
    DigitalFilterBox = Any
    FIRFilterBuilder = Any
    ArbitraryWaveformGenerator = Any
    TimeFrequencyAnalyzer = Any
    LaserLockBox = Any


class HardwareBackend(Backend):
    """
    Hardware backend using Moku MCC MultiInstrument Mode API.

    Deploys MokuPlatformConfig to real Moku hardware.
    """

    def __init__(self, config: MokuPlatformConfig, bench: BenchBench):
        """
        Initialize hardware backend.

        Args:
            config: MokuPlatformConfig instance (what to deploy)
            bench: BenchBench instance (where to deploy - has IP address)
        """
        super().__init__(config)

        if not MOKU_AVAILABLE:
            raise ImportError("Moku Python API not available. Install: uv add moku")

        self.bench = bench
        self.ip_address = bench.get_moku_ip()

        if not self.ip_address:
            raise ValueError(f"Bench {bench.bench_id} has no Moku IP address")

        # Determine platform_id from Moku model
        platform_map = {'Moku:Go': 2, 'Moku:Lab': 1, 'Moku:Pro': 3}
        self.platform_id = platform_map.get(bench.moku.name, 2)

        self.multi_instrument: MultiInstrument | None = None

        # Map instrument type names to Moku classes
        self.instrument_classes = {
            'Oscilloscope': Oscilloscope,
            'WaveformGenerator': WaveformGenerator,
            'CloudCompile': CloudCompile,
            'Datalogger': Datalogger,
            'SpectrumAnalyzer': SpectrumAnalyzer,
            'LogicAnalyzer': LogicAnalyzer,
            'Phasemeter': Phasemeter,
            'LockInAmp': LockInAmp,
            'PIDController': PIDController,
            'FrequencyResponseAnalyzer': FrequencyResponseAnalyzer,
            'DigitalFilterBox': DigitalFilterBox,
            'FIRFilterBuilder': FIRFilterBuilder,
            'ArbitraryWaveformGenerator': ArbitraryWaveformGenerator,
            'TimeFrequencyAnalyzer': TimeFrequencyAnalyzer,
            'LaserLockBox': LaserLockBox,
        }


    async def setup(self) -> None:
        """Setup hardware: connect, deploy instruments, configure routing."""
        print(f"[HardwareBackend] Connecting to {self.bench.moku} at {self.ip_address}...")

        # Connect to Moku
        try:
            self.multi_instrument = MultiInstrument(
                self.ip_address,
                platform_id=self.platform_id,
                force_connect=True
            )
            print(f"[HardwareBackend] ✓ Connected (platform_id={self.platform_id})")
        except Exception as e:
            raise ConnectionError(f"Failed to connect to {self.ip_address}: {e}")

        # Validate routing
        routing_errors = self.config.validate_routing()
        if routing_errors:
            raise ValueError(f"Routing validation failed:\n" + "\n".join(routing_errors))

        # Deploy instruments
        print("[HardwareBackend] Deploying instruments...")
        for slot_num, slot_config in self.config.slots.items():
            await self._deploy_instrument(slot_num, slot_config)

        # Setup routing
        print("[HardwareBackend] Configuring MCC routing...")
        await self._setup_routing()

        # Apply control registers
        print("[HardwareBackend] Applying control registers...")
        await self._apply_control_registers()

        self._setup_complete = True
        print("[HardwareBackend] ✓ Setup complete!")

    async def _deploy_instrument(self, slot_num: int, slot_config) -> None:
        """
        Deploy instrument to specified slot.

        Args:
            slot_num: Target slot number (1-4)
            slot_config: SlotConfig instance

        Raises:
            ValueError: If instrument type not supported
            RuntimeError: If deployment fails
        """
        instrument_type = slot_config.instrument

        print(f"  Slot {slot_num}: {instrument_type}...", end=" ")

        # Get instrument class
        if instrument_type not in self.instrument_classes:
            raise ValueError(f"Unsupported instrument type: {instrument_type}")

        instrument_class = self.instrument_classes[instrument_type]

        # Deploy instrument
        try:
            if instrument_type == 'CloudCompile':
                # CloudCompile requires bitstream path
                if not slot_config.bitstream:
                    raise ValueError(f"CloudCompile in slot {slot_num} requires 'bitstream' path")

                instrument = self.multi_instrument.set_instrument(
                    slot_num,
                    instrument_class,
                    bitstream=slot_config.bitstream
                )
            else:
                # Other instruments don't need extra args
                instrument = self.multi_instrument.set_instrument(
                    slot_num,
                    instrument_class
                )

            # Store instrument reference
            self.instruments[slot_num] = instrument

            # Apply instrument-specific settings
            if slot_config.settings:
                await self._apply_instrument_settings(instrument, slot_config.settings, instrument_type)

            print("✓")

        except Exception as e:
            print(f"✗ Failed")
            raise RuntimeError(f"Failed to deploy {instrument_type} to slot {slot_num}: {e}")

    async def _apply_instrument_settings(self, instrument: Any, settings: dict, instrument_type: str) -> None:
        """
        Apply settings to deployed instrument.

        Args:
            instrument: Moku instrument instance
            settings: Settings dictionary
            instrument_type: Instrument type name
        """
        if instrument_type == 'Oscilloscope' and settings:
            # Apply oscilloscope settings
            if 'timebase' in settings:
                timebase = settings['timebase']
                instrument.set_timebase(timebase[0], timebase[1])

            if 'trigger' in settings:
                trigger = settings['trigger']
                instrument.set_trigger(**trigger)

        elif instrument_type == 'WaveformGenerator' and settings:
            # Apply waveform generator settings
            if 'channel' in settings:
                ch = settings['channel']
                waveform_type = settings.get('type', 'Sine')
                frequency = settings.get('frequency', 1e6)
                amplitude = settings.get('amplitude', 1.0)

                instrument.generate_waveform(ch, waveform_type, amplitude=amplitude, frequency=frequency)

        elif instrument_type == 'Datalogger' and settings:
            # Apply data logger settings
            # Note: set_samplerate is deprecated, sample_rate is now set in start_streaming
            if 'streaming' in settings:
                streaming_cfg = settings['streaming']
                if streaming_cfg.get('enabled', False):
                    duration = streaming_cfg.get('duration', 10)
                    sample_rate = streaming_cfg.get('sample_rate', 1e3)
                    instrument.start_streaming(duration=duration, sample_rate=sample_rate)

        elif instrument_type == 'SpectrumAnalyzer' and settings:
            # Apply spectrum analyzer settings
            if 'span' in settings:
                span = settings['span']
                instrument.set_span(span[0], span[1])

            if 'rbw' in settings:
                instrument.set_rbw(settings['rbw'])

        elif instrument_type == 'LogicAnalyzer' and settings:
            # Apply logic analyzer settings
            if 'samplerate' in settings:
                instrument.set_samplerate(settings['samplerate'])

            if 'trigger' in settings:
                trigger = settings['trigger']
                instrument.set_trigger(
                    source=trigger.get('source', 'DIO'),
                    edge=trigger.get('edge', 'Rising'),
                    channel_mask=trigger.get('channel_mask', 0x01)
                )

        elif instrument_type == 'Phasemeter' and settings:
            # Apply phasemeter settings
            if 'pm_loop' in settings:
                loop_cfg = settings['pm_loop']
                for channel, cfg in loop_cfg.items():
                    instrument.set_pm_loop(
                        channel=channel,
                        auto_acquire=cfg.get('auto_acquire', False),
                        frequency=cfg.get('frequency', 1e6),
                        bandwidth=cfg.get('bandwidth', '100Hz')
                    )

    async def _setup_routing(self) -> None:
        """Establish MCC routing."""
        if not self.config.routing:
            return

        # Convert to MCC format
        mcc_connections = [conn.to_dict() for conn in self.config.routing]

        try:
            self.multi_instrument.set_connections(connections=mcc_connections)
            print(f"  ✓ Configured {len(mcc_connections)} connections")
        except Exception as e:
            raise RuntimeError(f"Failed to configure routing: {e}")

    async def _apply_control_registers(self) -> None:
        """
        Apply control registers to CloudCompile slots.

        Reads control_registers from SlotConfig and applies via set_control().
        """
        for slot_num, slot_config in self.config.slots.items():
            if slot_config.instrument == 'CloudCompile' and slot_config.control_registers:
                instrument = self.instruments[slot_num]

                for reg_num, value in slot_config.control_registers.items():
                    instrument.set_control(reg_num, value)
                    print(f"  Slot {slot_num} Control{reg_num} = 0x{value:08X}")

    async def run(self, duration_ms: float) -> dict[str, Any]:
        """Run hardware for specified duration and collect data."""
        self.validate_setup()

        print(f"[HardwareBackend] Running for {duration_ms} ms...")

        # Wait for specified duration
        time.sleep(duration_ms / 1000.0)

        # Collect data from instruments
        data = {}
        for slot_num, instrument in self.instruments.items():
            slot_config = self.config.get_slot(slot_num)

            if slot_config.instrument == 'Oscilloscope':
                # Get oscilloscope data
                osc_data = instrument.get_data()
                data[slot_num] = {
                    'ch1': osc_data['ch1'],
                    'ch2': osc_data['ch2'],
                    'time': osc_data['time']
                }
                print(f"  ✓ Captured {len(osc_data['ch1'])} samples from Oscilloscope (slot {slot_num})")

            elif slot_config.instrument == 'Datalogger':
                # Get data logger streaming data
                stream_data = instrument.get_stream_data()
                if stream_data:
                    data[slot_num] = {
                        'ch1': stream_data.get('ch1', []),
                        'ch2': stream_data.get('ch2', []),
                        'time': stream_data.get('time', [])
                    }
                    ch1_len = len(data[slot_num]['ch1'])
                    print(f"  ✓ Captured {ch1_len} samples from Datalogger (slot {slot_num})")
                else:
                    data[slot_num] = {'ch1': [], 'ch2': [], 'time': []}
                    print(f"  ⚠ No streaming data available from Datalogger (slot {slot_num})")

            elif slot_config.instrument == 'SpectrumAnalyzer':
                # Get spectrum analyzer data
                spectrum_data = instrument.get_data()
                data[slot_num] = {
                    'frequency': spectrum_data.get('frequency', []),
                    'ch1': spectrum_data.get('ch1', []),
                    'ch2': spectrum_data.get('ch2', [])
                }
                freq_points = len(data[slot_num]['frequency'])
                print(f"  ✓ Captured {freq_points} frequency points from SpectrumAnalyzer (slot {slot_num})")

            elif slot_config.instrument == 'LogicAnalyzer':
                # Get logic analyzer data
                logic_data = instrument.get_data()
                data[slot_num] = logic_data  # Contains ch0-ch15 digital channels
                # Count channels with data
                channels_with_data = sum(1 for ch in range(16) if logic_data.get(f'ch{ch}', None) is not None)
                print(f"  ✓ Captured logic data from {channels_with_data} channels (slot {slot_num})")

            elif slot_config.instrument == 'Phasemeter':
                # Get phasemeter data
                phase_data = instrument.get_data()
                data[slot_num] = phase_data  # Contains phase, frequency, amplitude arrays
                print(f"  ✓ Captured phasemeter data (slot {slot_num})")

        print(f"[HardwareBackend] ✓ Run complete")
        return data

    def get_instrument(self, slot_or_name: int | str) -> Any:
        """Get hardware instrument by slot number or type name."""
        if isinstance(slot_or_name, int):
            if slot_or_name not in self.instruments:
                raise KeyError(f"No instrument in slot {slot_or_name}")
            return self.instruments[slot_or_name]

        elif isinstance(slot_or_name, str):
            # Search by instrument type name
            for slot_num, slot_config in self.config.slots.items():
                if slot_config.instrument == slot_or_name:
                    return self.instruments[slot_num]
            raise KeyError(f"No instrument of type '{slot_or_name}' found")

        else:
            raise TypeError(f"slot_or_name must be int or str, got {type(slot_or_name)}")

    async def teardown(self) -> None:
        """Clean up hardware resources."""
        if self.multi_instrument:
            print("[HardwareBackend] Disconnecting...")
            try:
                self.multi_instrument.relinquish_ownership()
                print("[HardwareBackend] ✓ Disconnected")
            except Exception as e:
                print(f"[HardwareBackend] Warning: {e}")
            finally:
                self.multi_instrument = None

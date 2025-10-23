"""
Hardware Backend (MokuBench - Phase 3)

MCC API-based hardware backend for deploying to real Moku devices.
Implements full MultiInstrument Mode deployment with CloudCompile bitstreams.
"""

from typing import Any, Dict, Union, Optional
import time
from .backend import Backend
from .config import BenchConfig

# Import Moku API
try:
    from moku.instruments import MultiInstrument, Oscilloscope, WaveformGenerator, CloudCompile, Datalogger, SpectrumAnalyzer
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


class HardwareBackend(Backend):
    """
    Hardware backend using Moku MCC Multi-Instrument Mode API.

    Deploys BenchConfig to real Moku hardware:
    - Connects to Moku device via IP
    - Deploys CloudCompile bitstreams to slots
    - Configures instruments (Oscilloscope, WaveformGenerator, etc.)
    - Establishes signal routing
    - Collects data from real instruments

    Usage:
        bench = HardwareBackend.from_config(config, ip='192.168.1.100')
        bench.setup()  # Deploy to hardware
        data = bench.run(duration_ms=100)  # Capture data
    """

    def __init__(self, config: BenchConfig, ip_address: str, platform_id: int = 2):
        """
        Initialize hardware backend.

        Args:
            config: BenchConfig instance
            ip_address: IP address of Moku device (e.g., '192.168.1.100')
            platform_id: Platform ID (1=Moku:Lab, 2=Moku:Go, 3=Moku:Pro)
        """
        super().__init__(config)

        if not MOKU_AVAILABLE:
            raise ImportError(
                "Moku Python API not available. Install with: uv add moku\n"
                "Or run: pip install moku"
            )

        self.ip_address = ip_address
        self.platform_id = platform_id
        self.multi_instrument: Optional[MultiInstrument] = None

        # Map instrument type names to Moku classes
        self.instrument_classes = {
            'Oscilloscope': Oscilloscope,
            'WaveformGenerator': WaveformGenerator,
            'CloudCompile': CloudCompile,
            'Datalogger': Datalogger,
            'SpectrumAnalyzer': SpectrumAnalyzer,
        }

    @classmethod
    def from_config(cls, config: Union[BenchConfig, str, Dict], ip_address: str, platform_id: int = 2) -> 'HardwareBackend':
        """
        Create HardwareBackend from config.

        Args:
            config: BenchConfig instance, path to config file, or config dict
            ip_address: IP address of Moku device
            platform_id: Platform ID (1=Moku:Lab, 2=Moku:Go, 3=Moku:Pro)

        Returns:
            HardwareBackend instance
        """
        if isinstance(config, str):
            raise NotImplementedError("Loading from file not implemented yet")
        elif isinstance(config, dict):
            config = BenchConfig.from_dict(config)
        elif not isinstance(config, BenchConfig):
            raise TypeError(f"config must be BenchConfig, str, or dict, got {type(config)}")

        return cls(config, ip_address, platform_id)

    async def setup(self) -> None:
        """
        Setup hardware backend: connect, deploy instruments, configure routing.

        Steps:
        1. Connect to Moku device via IP
        2. Initialize MultiInstrument mode
        3. Deploy instruments to each slot (CloudCompile bitstreams, etc.)
        4. Configure instrument settings
        5. Establish signal routing via set_connections()
        6. Apply control registers to CloudCompile slots

        Raises:
            ConnectionError: If Moku device unreachable
            ValueError: If configuration invalid
            RuntimeError: If deployment fails
        """
        print(f"[MokuBench] Connecting to Moku at {self.ip_address}...")

        # Step 1: Connect to Moku device
        try:
            self.multi_instrument = MultiInstrument(
                self.ip_address,
                platform_id=self.platform_id,
                force_connect=True
            )
            print(f"[MokuBench] ✓ Connected to Moku (platform_id={self.platform_id})")
        except Exception as e:
            raise ConnectionError(f"Failed to connect to Moku at {self.ip_address}: {e}")

        # Step 2: Validate configuration
        connection_errors = self.config.validate_connections()
        if connection_errors:
            raise ValueError(f"Configuration validation failed:\n" + "\n".join(connection_errors))

        # Step 3: Deploy instruments to slots
        print("[MokuBench] Deploying instruments to slots...")
        for slot_num, slot_config in self.config.slots.items():
            await self._deploy_instrument(slot_num, slot_config)

        # Step 4: Establish signal routing
        print("[MokuBench] Configuring signal routing...")
        await self._setup_routing()

        # Step 5: Apply control registers to CloudCompile slots
        print("[MokuBench] Applying control registers...")
        await self._apply_control_registers()

        self._setup_complete = True
        print("[MokuBench] ✓ Setup complete - ready to run!")

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

    async def _apply_instrument_settings(self, instrument: Any, settings: Dict, instrument_type: str) -> None:
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

    async def _setup_routing(self) -> None:
        """
        Establish signal routing between slots/ports.

        Translates BenchConfig connections to MCC set_connections() format.
        """
        if not self.config.connections:
            return  # No routing needed

        # Convert BenchConfig connections to MCC format
        mcc_connections = [
            {'source': conn.source, 'destination': conn.destination}
            for conn in self.config.connections
        ]

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

    async def run(self, duration_ms: float) -> Dict[str, Any]:
        """
        Run hardware testbench and collect data.

        Args:
            duration_ms: Duration to run in milliseconds

        Returns:
            Dictionary mapping slot numbers to instrument data

        Raises:
            RuntimeError: If run() called before setup()
        """
        self.validate_setup()

        print(f"[MokuBench] Running for {duration_ms} ms...")

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

        print(f"[MokuBench] ✓ Run complete")
        return data

    def get_instrument(self, slot_or_name: Union[int, str]) -> Any:
        """
        Get hardware instrument instance by slot number or type name.

        Args:
            slot_or_name: Slot number (int) or instrument type name (str)

        Returns:
            Moku instrument API object

        Raises:
            KeyError: If slot/instrument not found
        """
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
        """
        Clean up hardware resources.

        - Relinquish ownership of Moku device
        - Close MultiInstrument connection
        """
        if self.multi_instrument:
            print("[MokuBench] Disconnecting from Moku...")
            try:
                self.multi_instrument.relinquish_ownership()
                print("[MokuBench] ✓ Disconnected")
            except Exception as e:
                print(f"[MokuBench] Warning: Teardown error: {e}")
            finally:
                self.multi_instrument = None

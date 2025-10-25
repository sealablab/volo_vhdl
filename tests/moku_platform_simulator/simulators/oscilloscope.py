"""
Oscilloscope Simulator

Behavioral model for Moku Oscilloscope instrument.
Captures DUT output signals for analysis in simulation.
"""

from typing import Dict, List, Any, Optional
import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.handle import SimHandleBase


class OscilloscopeSimulator:
    """
    Behavioral model of Moku Oscilloscope.

    Captures time-series data from DUT signals. Provides functional
    accuracy suitable for verification (not cycle-accurate hardware simulation).

    Phase 1: Minimal implementation for counter PoC
    Phase 2: Advanced features (triggering, decimation, FFT)
    """

    def __init__(self, dut: Any, settings: Dict[str, Any]):
        """
        Initialize oscilloscope simulator.

        Args:
            dut: CocotB DUT handle
            settings: Configuration dict, may contain:
                - timebase: Tuple (start_time, end_time) in seconds
                - sample_rate: Samples per second (default: 1e6)
                - channels: List of channel names to capture (default: all outputs)
        """
        self.dut = dut
        self.settings = settings

        # Data storage: channel_name -> list of (time, value) tuples
        self.data: Dict[str, List[tuple]] = {}

        # Settings
        self.sample_rate = settings.get('sample_rate', 1e6)  # 1 MHz default
        self.sample_period_ns = int(1e9 / self.sample_rate)

        # Determine which signals to capture
        self.channels = settings.get('channels', ['count_out'])

        # Initialize data buffers
        for channel in self.channels:
            self.data[channel] = []

    async def run(self, duration_ns: int) -> None:
        """
        Run oscilloscope capture for specified duration.

        Args:
            duration_ns: Capture duration in nanoseconds
        """
        start_time = cocotb.utils.get_sim_time(units='ns')

        # Capture loop: sample at regular intervals
        elapsed_ns = 0
        while elapsed_ns < duration_ns:
            # Sample all configured channels
            current_time_ns = cocotb.utils.get_sim_time(units='ns')

            for channel in self.channels:
                signal = self._get_signal(channel)
                if signal is not None:
                    value = self._read_signal_value(signal)
                    self.data[channel].append((current_time_ns, value))

            # Wait for next sample period
            await Timer(self.sample_period_ns, units='ns')
            elapsed_ns += self.sample_period_ns

    def _get_signal(self, channel_name: str) -> Optional[SimHandleBase]:
        """
        Get DUT signal handle by name.

        Args:
            channel_name: Signal name (e.g., 'count_out')

        Returns:
            Signal handle or None if not found
        """
        try:
            return getattr(self.dut, channel_name)
        except AttributeError:
            self.dut._log.warning(f"OscilloscopeSimulator: Signal '{channel_name}' not found in DUT")
            return None

    def _read_signal_value(self, signal: SimHandleBase) -> int:
        """
        Read signal value and convert to integer.

        Args:
            signal: CocotB signal handle

        Returns:
            Integer value
        """
        try:
            return int(signal.value)
        except Exception:
            # Handle undefined/high-impedance values
            return 0

    def get_data(self, channel: Optional[str] = None) -> Dict[str, Any]:
        """
        Retrieve captured data.

        Args:
            channel: Optional channel name (returns all if None)

        Returns:
            Dictionary with captured data:
            {
                'channel_name': {
                    'time': [t1, t2, ...],
                    'values': [v1, v2, ...]
                }
            }
        """
        if channel:
            return self._format_channel_data(channel)
        else:
            # Return all channels
            result = {}
            for ch in self.channels:
                result[ch] = self._format_channel_data(ch)
            return result

    def _format_channel_data(self, channel: str) -> Dict[str, List]:
        """
        Format channel data for easier analysis.

        Args:
            channel: Channel name

        Returns:
            Dict with 'time' and 'values' lists
        """
        if channel not in self.data:
            return {'time': [], 'values': []}

        time_values = self.data[channel]
        times = [t for t, v in time_values]
        values = [v for t, v in time_values]

        return {
            'time': times,
            'values': values,
            'sample_count': len(values)
        }

    def get_value_at_sample(self, channel: str, sample_index: int) -> Optional[int]:
        """
        Get value at specific sample index.

        Args:
            channel: Channel name
            sample_index: Sample index (0-based)

        Returns:
            Value at that sample, or None if out of range
        """
        if channel not in self.data:
            return None

        if sample_index < 0 or sample_index >= len(self.data[channel]):
            return None

        return self.data[channel][sample_index][1]  # Return value (not time)

    def verify_incrementing(self, channel: str, start_sample: int = 0, count: int = 10) -> bool:
        """
        Verify that signal increments by 1 each sample (for counter testing).

        Args:
            channel: Channel name
            start_sample: Starting sample index
            count: Number of samples to check

        Returns:
            True if values increment correctly, False otherwise
        """
        if channel not in self.data:
            return False

        for i in range(count - 1):
            idx = start_sample + i
            if idx + 1 >= len(self.data[channel]):
                return False

            current_val = self.data[channel][idx][1]
            next_val = self.data[channel][idx + 1][1]

            # Check if incremented (with wrap-around for 16-bit)
            expected = (current_val + 1) & 0xFFFF
            if next_val != expected:
                return False

        return True

    def __repr__(self) -> str:
        """String representation for debugging."""
        sample_counts = {ch: len(self.data[ch]) for ch in self.channels}
        return f"OscilloscopeSimulator(channels={self.channels}, samples={sample_counts})"

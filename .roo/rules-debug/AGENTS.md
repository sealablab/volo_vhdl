# Project Debug Rules (Non-Obvious Only)

## GHDL Debugging Specifics
- Use `--wave=wave.ghw` flag to generate waveform files for debugging
- Compile order matters: packages → entities → testbenches
- Initialize all signals to avoid non-deterministic behavior
- Use `--vcd=output.vcd` for VCD format if GTKWave compatibility is needed

## Testbench Debugging
- Check for multiple drivers when 'U' or 'X' values appear
- Verify clock generation and timing in testbenches
- Ensure proper reset timing (hold reset for at least 2 clock cycles)
- Check for infinite simulation loops (missing termination)

## Common Issues
- String length mismatches in reports or slices
- Missing variable/signal conversion in procedure calls
- Unintended latches from incomplete process branches
- Timing violations from long combinatorial paths
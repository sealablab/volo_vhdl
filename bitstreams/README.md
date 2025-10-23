# Bitstreams Directory

This directory holds `.tar.gz` bitstream files downloaded from Moku Cloud Compile.

## Usage

1. **Build CloudCompile package**:
   ```bash
   cd modules/<module_name>/
   ./build_cloudcompile.sh
   ```

2. **Upload to Cloud Compile**:
   - Zip: `cd cloudcompile_package/ && zip -r <module>.zip *.vhd`
   - Upload to: https://cloud-compile.liquidinstruments.com/
   - Wait for Vivado synthesis (~5-10 minutes)

3. **Download bitstream**:
   - Save `<module>.tar.gz` to this directory
   - Example: `bitstreams/simple_counter.tar.gz`

4. **Use with MokuBench**:
   ```python
   SlotConfig(
       instrument='CloudCompile',
       bitstream='bitstreams/simple_counter.tar.gz'
   )
   ```

## Files

Bitstream files (`.tar.gz`) are gitignored to keep repository size manageable.
Regenerate by uploading to Cloud Compile.

## Available Bitstreams

- `simple_counter.tar.gz` - Phase 3 PoC: 16-bit counter for MokuBench testing
- (Add your bitstreams here as you build them)

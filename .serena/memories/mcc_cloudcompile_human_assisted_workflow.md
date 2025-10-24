# MCC Cloud Compile Workflow (Human-Assisted)

**Last Updated**: 2025-10-24  
**Status**: Active until MCC API becomes available  
**Purpose**: Streamlined workflow for building, uploading, and testing MCC Cloud Compile packages with minimal friction and error tracking

## Overview

This workflow minimizes human-computer errors by:
1. Auto-generating build manifests (git hash, file checksums)
2. Auto-importing downloaded bitstreams with proper organization
3. Tracking which source code → which bitstream
4. Providing clear verification steps

## Complete Workflow

### 1. BUILD: Create Package with Manifest

```bash
cd /Users/johnycsh/volo_codes/volo_vhdl
python3 scripts/build_mcc_package.py modules/buffer_waveform_gen
```

**Output**:
```
modules/buffer_waveform_gen/cloudcompile_package/
├── buffer_waveform_gen_core.vhd
├── Top.vhd
├── mcc_loader_pkg.vhd
├── crc32_core.vhd
├── mcc_buffer_loader.vhd
├── clk_divider_core.vhd
├── README.txt                    # Usage instructions
├── BUILD_MANIFEST.txt            # ⭐ NEW: Git hash, checksums, timestamp
└── buffer_waveform_gen.zip       # (not used for upload)
```

**BUILD_MANIFEST.txt** contains:
- Git commit hash
- Git branch name
- Uncommitted changes warning (if any)
- SHA256 checksum of each `.vhd` file
- Build timestamp

### 2. UPLOAD: Manual File Upload (until API available)

```
1. Go to: https://cloud-compile.liquidinstruments.com/
2. Click "Upload Files" or use file picker
3. Navigate to: modules/buffer_waveform_gen/cloudcompile_package/
4. Select ALL .vhd files (not .zip, not .txt files)
5. Upload
6. Wait for synthesis (~5-10 min)
```

**Important**: Upload individual `.vhd` files, NOT the `.zip` file!

### 3. DOWNLOAD: Save Results to Downloads

When synthesis completes, download both files:
- `25ffXXX_mokugo_4.0.3_2_synthesis.log`
- `25ffXXX_mokugo_4.0.3_2_bitstreams.tar`

MCC automatically names files with incrementing timestamp (25ff362, 25ff363, 25ff364...)

Save both files to `~/Downloads/` (default browser download location)

### 4. IMPORT: Auto-Organize Results

```bash
cd /Users/johnycsh/volo_codes/volo_vhdl
python3 scripts/import_mcc_build.py modules/buffer_waveform_gen
```

**What it does**:
1. Scans `~/Downloads/` for newest `25ff*` files
2. Moves them to `modules/buffer_waveform_gen/latest/`
3. Extracts MCC job ID (e.g., `25ff362`)
4. Reads BUILD_MANIFEST.txt from cloudcompile_package/
5. Creates BUILD_INFO.txt linking manifest → bitstream

**Output**:
```
modules/buffer_waveform_gen/latest/
├── 25ff362_mokugo_4.0.3_2_synthesis.log
├── 25ff362_mokugo_4.0.3_2_bitstreams.tar
└── BUILD_INFO.txt                # ⭐ Links git hash → bitstream
```

**BUILD_INFO.txt** contains:
- MCC job ID (25ff362)
- Download timestamp
- Full BUILD_MANIFEST (git hash, checksums)
- Links source code version to bitstream

### 5. TEST: Run on Hardware

```bash
cd tests
python3 test_buffer_waveform_hardware.py --ip 192.168.13.159 \\
    --bitstream ../modules/buffer_waveform_gen/latest/25ff362_mokugo_4.0.3_2_bitstreams.tar
```

Or use auto-detection (picks newest bitstream):
```bash
python3 test_buffer_waveform_hardware.py --ip 192.168.13.159
```

### 6. VERIFY: Confirm Build Matches Source

```bash
cat modules/buffer_waveform_gen/latest/BUILD_INFO.txt
```

Check:
- ✅ Git commit hash matches your current code
- ✅ No uncommitted changes warning
- ✅ Timestamp is recent (built after your changes)

## Troubleshooting

### Problem: Bitstream doesn't have my latest changes

**Diagnosis**:
```bash
# Check git hash in BUILD_INFO.txt
cat modules/buffer_waveform_gen/latest/BUILD_INFO.txt | grep "Commit:"

# Compare to current git hash
git rev-parse HEAD
```

**Solution**: Hashes don't match → Rebuild package and re-upload

### Problem: Can't find downloaded files

**Diagnosis**:
```bash
# Check Downloads folder
ls -lt ~/Downloads/25ff* | head -5
```

**Solution**: 
- Make sure both `.log` and `.tar` files were downloaded
- Check browser's download location

### Problem: Import script says "files already exist"

**Solution**: 
- Script asks for confirmation to overwrite
- Type `y` to replace old bitstream with new one
- Or manually delete old files from `latest/` first

## Key Benefits

### ✅ Traceability
- Every bitstream is linked to exact git commit
- File checksums verify integrity
- Timestamps show build order

### ✅ Error Prevention
- No manual file renaming/moving
- Auto-detection prevents wrong bitstream usage
- Manifest warns about uncommitted changes

### ✅ Reproducibility
- Git hash allows checkout of exact source
- File checksums verify no corruption
- Build manifest preserves all metadata

### ✅ Streamlined Testing
- One command to import results
- Auto-detection picks newest bitstream
- Clear feedback on what was imported

## Files Created by Workflow

```
modules/buffer_waveform_gen/
├── cloudcompile_package/           # Build output
│   ├── *.vhd                       # Source files to upload
│   ├── BUILD_MANIFEST.txt          # ⭐ Tracks source at build time
│   ├── README.txt                  # Usage instructions
│   └── buffer_waveform_gen.zip     # (not used)
│
└── latest/                         # Downloaded results
    ├── 25ff362_*_synthesis.log     # Vivado synthesis log
    ├── 25ff362_*_bitstreams.tar    # FPGA bitstream
    └── BUILD_INFO.txt              # ⭐ Links manifest → bitstream
```

## Future Improvements (when MCC API available)

When Liquid Instruments releases the MCC API:
1. Auto-upload from `build_mcc_package.py`
2. Auto-poll for completion
3. Auto-download results
4. End-to-end automated workflow

Current workflow is designed to transition smoothly to API-based automation.

## Related Files

- **Build script**: `scripts/build_mcc_package.py`
- **Import script**: `scripts/import_mcc_build.py`
- **Test script**: `tests/test_*_hardware.py`
- **Package manifest**: `modules/*/mcc_package.yaml`

## Related Memories

- `mcc_cloudcompile_packaging` - Package structure and requirements
- `mcc_build_pattern` - Build system patterns
- `instrument_cloud_compile` - Instrument-specific CloudCompile usage

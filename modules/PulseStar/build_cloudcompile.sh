#!/bin/bash
################################################################################
# Build Script: Prepare PulseStar for Moku Cloud Compile
#
# Usage:
#   ./build_cloudcompile.sh
#
# Output:
#   cloudcompile_package/ - Directory ready for upload to Moku Cloud Compile
#
# Workflow:
#   1. Run this script to create package
#   2. Test compilation locally with GHDL (optional)
#   3. Zip cloudcompile_package/ contents
#   4. Upload to Moku Cloud Compile web interface
#   5. Download resulting bitstream.tar.gz
#   6. Use with MokuBench!
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PulseStar - CloudCompile Package${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Directories
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="${MODULE_DIR}/cloudcompile_package"
TEMPLATES_DIR="${MODULE_DIR}/../../mcc_templates"
VOLO_COMMON_DIR="${MODULE_DIR}/../volo_common"

# Clean and create package directory
echo -e "${YELLOW}[1/5] Creating package directory...${NC}"
rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}"

# Copy PulseStar files
echo -e "${YELLOW}[2/5] Copying PulseStar VHDL files...${NC}"
cp "${MODULE_DIR}/datadef/waveform_lut_pkg.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/core/waveform_gen_core.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/core/trigger_gen_core.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/core/uart_tx_core.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/top/Top.vhd" "${PKG_DIR}/"
echo "  ✓ Copied: waveform_lut_pkg.vhd (sine/cosine LUTs)"
echo "  ✓ Copied: waveform_gen_core.vhd (I/Q generator)"
echo "  ✓ Copied: trigger_gen_core.vhd (trigger pulse generator)"
echo "  ✓ Copied: uart_tx_core.vhd (UART transmitter)"
echo "  ✓ Copied: Top.vhd (CustomWrapper architecture)"

# Copy volo_common dependency (clk_divider_core)
echo -e "${YELLOW}[3/5] Copying dependencies from volo_common...${NC}"
cp "${VOLO_COMMON_DIR}/core/clk_divider_core.vhd" "${PKG_DIR}/"
echo "  ✓ Copied: clk_divider_core.vhd (from volo_common)"
echo "  ! Excluded: mcc-Top.vhd (MCC provides CustomWrapper entity)"

# Create README for upload
echo -e "${YELLOW}[4/5] Creating README...${NC}"
cat > "${PKG_DIR}/README.txt" << 'EOF'
PulseStar - Moku Cloud Compile Package
========================================

Module: PulseStar
Description: 4-channel calibration signal generator with I/Q quadrature,
             UART serial, and trigger outputs
Platform: Moku:Go / Moku:Lab / Moku:Pro
Dependencies: volo_common (clk_divider_core included in package)

Files Included:
- waveform_lut_pkg.vhd: 256-point sine/cosine LUTs (datadef)
- waveform_gen_core.vhd: I/Q signal generator core
- trigger_gen_core.vhd: Trigger pulse generator core
- uart_tx_core.vhd: UART transmitter core
- clk_divider_core.vhd: Clock divider (from volo_common)
- Top.vhd: CustomWrapper architecture (PulseStar)

IMPORTANT: This package does NOT include mcc-Top.vhd because Moku Cloud
Compile already provides the CustomWrapper entity. Only upload the
architecture (Top.vhd) and your module logic.

Control Register Map:
- Control0[31]:    MCC_READY (1=ready, 0=disabled) - AUTO SET BY MCC
- Control0[30]:    Global Enable (1=enable, 0=disable)
- Control0[29]:    Clock Enable (1=run, 0=freeze all outputs)
- Control0[28:21]: Frequency Divider (0-255) for I/Q waveforms
- Control1[31:16]: UART Baud Divider (clk / (baud_div+1) = baud_rate)
- Control1[15:0]:  Trigger Pulse Interval (clock cycles between pulses)
- Control2[31:24]: Trigger Pulse Width (clock cycles per pulse)

Output Map:
- OutputA: I Channel (Sine wave, 16-bit signed)
- OutputB: Q Channel (Cosine wave, 90° phase offset, 16-bit signed)
- OutputC: UART Serial ("VOLO" pattern, 16-bit signed: 0x7FFF=high, 0x8000=low)
- OutputD: Trigger Pulse (16-bit signed: 0x7FFF=active, 0x0000=idle)

Python MokuBench Usage Example:
  from moku.instruments import MultiInstrument, CloudCompile

  m = MultiInstrument('192.168.1.100', platform_id=2)
  mcc = m.set_instrument(2, CloudCompile, bitstream="pulsestar.tar.gz")

  # Configure: 1kHz I/Q, 115200 baud UART, 256μs trigger interval
  mcc.set_control(0, 0xC0F00000)  # MCC_READY + Enable + ClkEn + Div=240 (≈1kHz)
  mcc.set_control(1, 0x043C7D00)  # Baud=1084 (115200), Interval=32000 (256μs)
  mcc.set_control(2, 0x64000000)  # PulseWidth=100 clocks (800ns @ 125MHz)

  # Route to Oscilloscope for monitoring
  connections = [
      dict(source="Slot2OutA", destination="Slot1InA"),  # I channel
      dict(source="Slot2OutB", destination="Slot1InB"),  # Q channel
      dict(source="Slot2OutD", destination="Slot1InC"),  # Trigger
  ]
  m.set_connections(connections=connections)

Frequency Calculation:
  Output Frequency (Hz) = 125 MHz / (freq_div + 1) / 256

  Examples:
  - freq_div=0   → 488.3 kHz (max)
  - freq_div=24  → 19.5 kHz
  - freq_div=240 → 2.0 kHz
  - freq_div=255 → 1.9 kHz (min)

UART Baud Rate Calculation:
  Baud Rate = 125 MHz / (baud_div + 1)

  Examples:
  - baud_div=1084  → 115200 baud (standard)
  - baud_div=13333 → 9600 baud (standard)

Upload Instructions:
1. Zip this package: zip -r pulsestar.zip *.vhd README.txt
2. Go to Moku Cloud Compile: https://cloud-compile.liquidinstruments.com/
3. Upload pulsestar.zip
4. Wait for synthesis (Vivado takes ~5-10 minutes)
5. Download resulting bitstream.tar.gz
6. Save as: pulsestar.tar.gz
7. Use with MokuBench!

Note: MCC provides CustomWrapper entity automatically. This package only
contains your module logic and CustomWrapper architecture.

Author: Claude Code
Date: 2025-01-22
Branch: feature/PulseStar
EOF

# Test compilation with GHDL BEFORE packaging (use local mcc-Top.vhd)
echo -e "${YELLOW}[5/5] Testing local GHDL compilation...${NC}"
if command -v ghdl &> /dev/null; then
    mkdir -p "${MODULE_DIR}/ghdl_test_work"
    cd "${MODULE_DIR}"

    echo "  Analyzing mcc-Top.vhd (from templates)..."
    ghdl -a --std=08 --workdir=ghdl_test_work "${TEMPLATES_DIR}/mcc-Top.vhd"

    echo "  Analyzing clk_divider_core.vhd (dependency)..."
    ghdl -a --std=08 --workdir=ghdl_test_work "${VOLO_COMMON_DIR}/core/clk_divider_core.vhd"

    echo "  Analyzing waveform_lut_pkg.vhd..."
    ghdl -a --std=08 --workdir=ghdl_test_work datadef/waveform_lut_pkg.vhd

    echo "  Analyzing waveform_gen_core.vhd..."
    ghdl -a --std=08 --workdir=ghdl_test_work core/waveform_gen_core.vhd

    echo "  Analyzing trigger_gen_core.vhd..."
    ghdl -a --std=08 --workdir=ghdl_test_work core/trigger_gen_core.vhd

    echo "  Analyzing uart_tx_core.vhd..."
    ghdl -a --std=08 --workdir=ghdl_test_work core/uart_tx_core.vhd

    echo "  Analyzing Top.vhd..."
    ghdl -a --std=08 --workdir=ghdl_test_work top/Top.vhd

    echo "  Elaborating CustomWrapper..."
    ghdl -e --std=08 --workdir=ghdl_test_work CustomWrapper

    rm -rf ghdl_test_work  # Clean up test artifacts

    echo -e "${GREEN}  ✓ Local GHDL compilation successful!${NC}"
    echo "  (CloudCompile package does NOT include mcc-Top.vhd - MCC provides it)"
else
    echo -e "${YELLOW}  ! GHDL not found, skipping local compilation test${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Package ready: ${PKG_DIR}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Files in package:"
ls -1 "${PKG_DIR}"
echo ""
echo "Next steps:"
echo "1. cd ${PKG_DIR}"
echo "2. zip -r pulsestar.zip *.vhd README.txt"
echo "   (Package contains: all cores + datadef + Top.vhd + clk_divider_core.vhd)"
echo "3. Upload to Moku Cloud Compile: https://cloud-compile.liquidinstruments.com/"
echo "4. Download bitstream.tar.gz when synthesis completes (~5-10 min)"
echo "5. Save to: static/bitstreams/pulsestar.tar.gz"
echo "6. Use with MokuBench!"
echo ""
echo "Note: mcc-Top.vhd is NOT included - MCC provides CustomWrapper entity"
echo ""

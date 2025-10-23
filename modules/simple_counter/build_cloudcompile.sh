#!/bin/bash
################################################################################
# Build Script: Prepare simple_counter for Moku Cloud Compile
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
echo -e "${GREEN}Simple Counter - CloudCompile Package${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Directories
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="${MODULE_DIR}/cloudcompile_package"
TEMPLATES_DIR="${MODULE_DIR}/../../mcc_templates"

# Clean and create package directory
echo -e "${YELLOW}[1/4] Creating package directory...${NC}"
rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}"

# Copy required files
echo -e "${YELLOW}[2/4] Copying VHDL files...${NC}"
cp "${TEMPLATES_DIR}/mcc-Top.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/core/simple_counter_core.vhd" "${PKG_DIR}/"
cp "${MODULE_DIR}/top/Top.vhd" "${PKG_DIR}/"

# Create README for upload
echo -e "${YELLOW}[3/4] Creating README...${NC}"
cat > "${PKG_DIR}/README.txt" << 'EOF'
Simple Counter - Moku Cloud Compile Package
===========================================

Module: simple_counter
Description: 16-bit counter for MokuBench Phase 3 proof of concept
Platform: Moku:Go / Moku:Pro

Files Included:
- mcc-Top.vhd: CustomWrapper entity (Moku platform interface)
- simple_counter_core.vhd: 16-bit counter core logic
- Top.vhd: CustomWrapper architecture (simple_counter_top)

Control Register Map:
- Control0[31]: MCC_READY (auto-set by platform)
- Control0[30]: User Enable (1=enable, 0=disable)
- Control0[29]: Clock Enable (1=run counter, 0=freeze)

Output Map:
- OutputA: 16-bit counter value
- OutputB: Counter MSB (for visibility)
- OutputC: Unused (0)
- OutputD: Unused (0)

Python MokuBench Usage:
  from bench_framework import HardwareBackend

  config = BenchConfig(
      platform=MOKU_GO,
      slots={
          1: SlotConfig(
              instrument='CloudCompile',
              bitstream='simple_counter.tar.gz',
              control_registers={0: 0xE0000000}  # MCC_READY + Enable + ClkEn
          ),
          2: SlotConfig(
              instrument='Oscilloscope',
              settings={'timebase': (-5e-3, 5e-3)}
          )
      },
      connections=[
          Connection(source='Slot1OutA', destination='Slot2InA')
      ]
  )

  bench = HardwareBackend.from_config(config, ip='192.168.1.100')
  bench.setup()
  data = bench.run(duration_ms=100)

Upload Instructions:
1. Zip this package: zip -r simple_counter.zip mcc-Top.vhd simple_counter_core.vhd Top.vhd
2. Go to Moku Cloud Compile web interface
3. Upload simple_counter.zip
4. Wait for synthesis (Vivado takes ~5-10 minutes)
5. Download resulting bitstream.tar.gz
6. Use with MokuBench!
EOF

# Test compilation with GHDL (if available)
echo -e "${YELLOW}[4/4] Testing compilation with GHDL...${NC}"
if command -v ghdl &> /dev/null; then
    cd "${PKG_DIR}"
    mkdir -p work

    echo "  Analyzing mcc-Top.vhd..."
    ghdl -a --std=08 --workdir=work mcc-Top.vhd

    echo "  Analyzing simple_counter_core.vhd..."
    ghdl -a --std=08 --workdir=work simple_counter_core.vhd

    echo "  Analyzing Top.vhd..."
    ghdl -a --std=08 --workdir=work Top.vhd

    echo "  Elaborating CustomWrapper..."
    ghdl -e --std=08 --workdir=work CustomWrapper

    rm -rf work  # Clean up test artifacts

    echo -e "${GREEN}  ✓ GHDL compilation successful!${NC}"
else
    echo -e "${YELLOW}  ! GHDL not found, skipping compilation test${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Package ready: ${PKG_DIR}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. cd ${PKG_DIR}"
echo "2. zip -r simple_counter.zip *.vhd"
echo "3. Upload to Moku Cloud Compile: https://cloud-compile.liquidinstruments.com/"
echo "4. Download bitstream.tar.gz when synthesis completes"
echo "5. Use with MokuBench!"
echo ""

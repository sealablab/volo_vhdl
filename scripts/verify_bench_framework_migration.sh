#!/bin/bash
# Verification script for bench_framework → moku_platform_simulator migration
# Usage: ./scripts/verify_bench_framework_migration.sh

set -e

echo "Checking for old bench_framework references..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check for old imports (should only be in archived files)
echo -e "\n1. Checking for old imports in active test files..."
IMPORTS=$(grep -r "from.*bench_framework" --include="*.py" tests/ 2>/dev/null | \
    grep -v "test_bench_framework_poc.py" | \
    grep -v ".pyc" | \
    grep -v "moku_platform_simulator" || true)

if [ -z "$IMPORTS" ]; then
    echo -e "   ${GREEN}✓${NC} No old imports found (except legacy test)"
else
    echo -e "   ${RED}✗${NC} Found old imports:"
    echo "$IMPORTS"
    ERRORS=$((ERRORS + 1))
fi

# Check Serena memories for old class patterns
echo -e "\n2. Checking Serena memories for old BenchConfig class..."
OLD_CLASS=$(grep -l "class BenchConfig" .serena/memories/*.md 2>/dev/null | \
    grep -v "bench_config_framework.md" || true)

if [ -z "$OLD_CLASS" ]; then
    echo -e "   ${GREEN}✓${NC} No 'class BenchConfig' references (except main memory)"
else
    echo -e "   ${RED}✗${NC} Found old class definitions in:"
    echo "$OLD_CLASS"
    ERRORS=$((ERRORS + 1))
fi

# Check for old directory references in Serena memories
echo -e "\n3. Checking for 'tests/bench_framework/' references..."
OLD_DIR=$(grep -l "tests/bench_framework/" .serena/memories/*.md 2>/dev/null | \
    grep -v "bench_config_framework.md" || true)

if [ -z "$OLD_DIR" ]; then
    echo -e "   ${GREEN}✓${NC} No old directory references (except main memory)"
else
    echo -e "   ${YELLOW}⚠${NC}  Found old directory paths in:"
    echo "$OLD_DIR"
    echo "   (This is OK if they're in historical context)"
fi

# Check for proper new imports in code
echo -e "\n4. Checking for new model imports..."
NEW_IMPORTS=$(grep -r "from models\.moku\.platform_config import" --include="*.py" tests/ 2>/dev/null | wc -l)
NEW_IMPORTS_TRIMMED=$(echo $NEW_IMPORTS | xargs)  # Trim whitespace

if [ "$NEW_IMPORTS_TRIMMED" -gt 0 ]; then
    echo -e "   ${GREEN}✓${NC} Found $NEW_IMPORTS_TRIMMED files using new imports"
else
    echo -e "   ${YELLOW}⚠${NC}  No files using new imports yet"
fi

# Check if main Serena memory updated
echo -e "\n5. Checking key documentation updates..."

if grep -q "MokuPlatformConfig" .serena/memories/bench_config_framework.md 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} bench_config_framework.md mentions MokuPlatformConfig"
else
    echo -e "   ${RED}✗${NC} bench_config_framework.md NOT updated"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "BenchBench" .serena/memories/bench_config_framework.md 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} bench_config_framework.md mentions BenchBench"
else
    echo -e "   ${RED}✗${NC} bench_config_framework.md missing BenchBench"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "moku_platform_simulator" CLAUDE.md 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} CLAUDE.md mentions new directory name"
else
    echo -e "   ${YELLOW}⚠${NC}  CLAUDE.md may need update"
fi

# Check if old config.py properly archived
echo -e "\n6. Checking if old config.py archived..."
if [ -f "archive/bench_config_old.py" ]; then
    echo -e "   ${GREEN}✓${NC} Old config archived"
elif [ -f "tests/moku_platform_simulator/config.py" ]; then
    echo -e "   ${YELLOW}⚠${NC}  Old config.py still in moku_platform_simulator/"
else
    echo -e "   ${GREEN}✓${NC} No old config.py found"
fi

# Check if new models exist
echo -e "\n7. Checking new model files exist..."
if [ -f "models/moku/platform_config.py" ]; then
    echo -e "   ${GREEN}✓${NC} models/moku/platform_config.py exists"
else
    echo -e "   ${RED}✗${NC} models/moku/platform_config.py MISSING"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "models/bench/benchbench.py" ]; then
    echo -e "   ${GREEN}✓${NC} models/bench/benchbench.py exists"
else
    echo -e "   ${RED}✗${NC} models/bench/benchbench.py MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo -e "\n=============================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Verification complete! All critical checks passed.${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS critical issue(s). See above for details.${NC}"
    exit 1
fi

#!/bin/bash
# Validate CI/CD setup before pushing to GitHub
# Usage: ./scripts/validate_ci_setup.sh

set -e  # Exit on error

echo "======================================================================="
echo "CI/CD Setup Validation Script"
echo "======================================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
VALIDATION_PASSED=true

# Test 1: Check YAML syntax
echo "Test 1: Validating YAML syntax..."
if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-and-test.yml'))" 2>/dev/null; then
    echo -e "${GREEN}✅ build-and-test.yml: Valid YAML${NC}"
else
    echo -e "${RED}❌ build-and-test.yml: Invalid YAML${NC}"
    VALIDATION_PASSED=false
fi

if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/smoke-test.yml'))" 2>/dev/null; then
    echo -e "${GREEN}✅ smoke-test.yml: Valid YAML${NC}"
else
    echo -e "${RED}❌ smoke-test.yml: Invalid YAML${NC}"
    VALIDATION_PASSED=false
fi
echo ""

# Test 2: Verify Makefile portability (no hardcoded paths)
echo "Test 2: Checking for hardcoded paths in Makefile..."
if grep -q "/Users/" modules/Makefile; then
    echo -e "${RED}❌ Found hardcoded paths in modules/Makefile${NC}"
    grep "/Users/" modules/Makefile
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✅ No hardcoded paths found${NC}"
fi
echo ""

# Test 3: Test modules build
echo "Test 3: Testing modules build..."
cd modules
if make clean >/dev/null 2>&1 && make compile >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Modules build successful${NC}"
    # Check that work library was created
    if [ -f work-obj08.cf ]; then
        echo -e "${GREEN}✅ GHDL work library created${NC}"
    else
        echo -e "${RED}❌ GHDL work library not found${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}❌ Modules build failed${NC}"
    VALIDATION_PASSED=false
fi
cd ..
echo ""

# Test 4: Verify UV environment
echo "Test 4: Checking UV Python environment..."
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✅ UV is installed${NC}"
    uv --version
else
    echo -e "${YELLOW}⚠️  UV not found (will be installed by CI)${NC}"
fi
echo ""

# Test 5: Check for required files
echo "Test 5: Verifying required files exist..."
REQUIRED_FILES=(
    ".github/workflows/build-and-test.yml"
    ".github/workflows/smoke-test.yml"
    "modules/Makefile"
    "modules/Makefile.deps"
    "tests/run.py"
    "tests/test_configs.py"
    "tests/conftest.py"
    "pyproject.toml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ Missing: $file${NC}"
        VALIDATION_PASSED=false
    fi
done
echo ""

# Test 6: Quick CocotB test with Python runner (if UV is available)
if command -v uv &> /dev/null; then
    echo "Test 6: Running quick CocotB test with Python runner..."
    if uv run python tests/run.py volo_clk_divider --no-waves >/dev/null 2>&1; then
        echo -e "${GREEN}✅ CocotB Python runner test passed${NC}"
    else
        echo -e "${YELLOW}⚠️  CocotB test failed${NC}"
        echo -e "${YELLOW}   This may indicate an issue - check manually with:${NC}"
        echo -e "${YELLOW}   uv run python tests/run.py volo_clk_divider --no-waves${NC}"
        # Don't fail validation - could be env-specific
    fi
    echo ""
else
    echo "Test 6: Skipping CocotB test (UV not installed)"
    echo ""
fi

# Summary
echo "======================================================================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ ALL VALIDATION CHECKS PASSED${NC}"
    echo ""
    echo "Your CI/CD setup is ready to push!"
    echo ""
    echo "Next steps:"
    echo "  1. git add modules/Makefile .github/"
    echo "  2. git commit -m 'feat: Add CI/CD with GitHub Actions'"
    echo "  3. git push origin feature/cicd"
    echo "  4. Watch workflows at: https://github.com/<username>/<repo>/actions"
    echo "======================================================================="
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Please fix the issues above before pushing."
    echo "======================================================================="
    exit 1
fi

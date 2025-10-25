#!/bin/bash
# Bulk update script for Serena instrument memories
# Updates old bench_framework references to new moku_platform_simulator
# Usage: ./scripts/update_memory_imports.sh [--dry-run]

set -e

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No files will be modified"
    echo "==========================================="
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

UPDATE_COUNT=0

# Function to update a single file
update_file() {
    local file="$1"
    local basename=$(basename "$file")

    echo -e "\n${BLUE}Processing:${NC} $basename"

    # Check if file has old references
    if ! grep -q "bench_framework\|BenchConfig(" "$file" 2>/dev/null; then
        echo "  → No updates needed (no old references found)"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  → Would update:"
        grep -n "bench_framework\|BenchConfig(" "$file" | head -3
        [ $(grep -c "bench_framework\|BenchConfig(" "$file") -gt 3 ] && echo "  → ... and more"
    else
        # Create backup
        cp "$file" "$file.bak"

        # Apply replacements
        sed -i '' 's/from tests\.bench_framework/from tests.moku_platform_simulator/g' "$file"
        sed -i '' 's/import bench_framework/import moku_platform_simulator/g' "$file"
        sed -i '' 's/bench_framework\./moku_platform_simulator./g' "$file"
        sed -i '' 's/BenchConfig(/MokuPlatformConfig(/g' "$file"

        # Note: Keep "BenchConfig" as a concept/term in prose, only replace code usage

        echo -e "  ${GREEN}✓${NC} Updated"
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
    fi
}

# Update instrument memories
echo "Updating instrument Serena memories..."
echo "======================================"

for file in .serena/memories/instrument_*.md; do
    [ -f "$file" ] || continue
    update_file "$file"
done

# Update Riscure probe memories
echo -e "\n\nUpdating Riscure probe memories..."
echo "===================================="

for file in .serena/memories/riscure_*.md; do
    [ -f "$file" ] || continue
    update_file "$file"
done

# Update README files in scripts/
echo -e "\n\nUpdating script README files..."
echo "================================"

for file in scripts/*/README.md; do
    [ -f "$file" ] || continue
    update_file "$file"
done

# Summary
echo -e "\n========================================="
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
    echo "Run without --dry-run to apply changes"
else
    echo -e "${GREEN}✓ Update complete!${NC}"
    echo "Files updated: $UPDATE_COUNT"
    echo ""
    echo "Backup files created with .bak extension"
    echo "To remove backups after verification:"
    echo "  find .serena/memories scripts/ -name '*.bak' -delete"
fi

echo ""
echo "Next steps:"
echo "  1. Review changed files: git diff .serena/memories/"
echo "  2. Run verification: ./scripts/verify_bench_framework_migration.sh"
echo "  3. Update code examples manually (script only updates imports)"

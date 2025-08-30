#!/bin/bash
# Simple script to capture conversation context

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M:%S)

echo "# Conversation Capture - $DATE $TIMESTAMP" >> conversation-history.md
echo "" >> conversation-history.md
echo "## Context at $TIMESTAMP" >> conversation-history.md
echo "- Branch: $(git branch --show-current)" >> conversation-history.md
echo "- Last commit: $(git log --oneline -1)" >> conversation-history.md
echo "- Working directory: $(pwd)" >> conversation-history.md
echo "" >> conversation-history.md
echo "---" >> conversation-history.md
echo "" >> conversation-history.md

echo "Conversation context captured to conversation-history.md"
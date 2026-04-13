#!/bin/bash

# Agent OS Kernel Guard: Security Audit Hook
# Performs a sweep of staged files for common security risks.

echo "🛡️  Running Intelligent Operating System Security Audit..."

# 1. Check for staged files
STAGED_FILES=$(git diff --cached --name-only)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No files staged for audit."
    exit 0
fi

# 2. Simple pattern matching for "Leaked Secrets" (Baseline example)
# In a real Agent OS, this would trigger a specialist model call.
SECRET_PATTERNS=("API_KEY" "SECRET" "PASSWORD")

for file in $STAGED_FILES; do
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$file"; then
            echo "⚠️  WARNING: Potential sensitive pattern '$pattern' found in $file"
        fi
    done
done

# 3. Trigger Agent Sync (Mock)
# This is where the Agent OS would ground itself in the staged changes.
echo "✅ Audit complete. Files are governed."
exit 0

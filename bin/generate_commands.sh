#!/bin/bash

# Command Generation Script (Step 2 of 2)
# This script generates improvement commands based on website analysis
# Prerequisite: Website must be analyzed first (./bin/analyze_websites.sh)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "⚡ Step 2: Generating improvement commands with Claude Code..."
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "❌ Error: Claude Code CLI not found"
    echo "Install it from: https://claude.ai/download"
    exit 1
fi

# Run Claude Code with the directive
claude "
Read the CLAUDE_COMMAND_GENERATION_DIRECTIVE.md file in this directory.

Follow ALL steps in that directive to:
1. Query the database for analyzed websites (status='analyzed')
2. Review the existing context document for each website
3. Read and apply the CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md
4. Generate 3-7 specific, actionable improvement commands
5. Insert commands into the database
6. Update website status to 'active'

Focus 60-70% of commands on fixing the main bottleneck.
Be specific and explain conversion impact in reasoning.

Work through websites one at a time.

Database connection: shepherd_dev (PostgreSQL)
"

echo ""
echo "✅ Step 2 complete! Commands generated and saved."
echo ""
echo "Check your Phoenix app at http://localhost:4000/website?tab=commands"

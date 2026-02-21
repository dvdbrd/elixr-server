#!/bin/bash

# Website Analysis Script (Step 1 of 2)
# This script analyzes websites and creates context documents
# To generate commands, run: ./bin/generate_commands.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🔍 Step 1: Analyzing pending websites with Claude Code..."
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "❌ Error: Claude Code CLI not found"
    echo "Install it from: https://claude.ai/download"
    exit 1
fi

# Check for Anthropic API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "⚠️  Warning: ANTHROPIC_API_KEY is not set"
    echo "Claude Code may not be able to make API calls without it."
    echo "Set it with: export ANTHROPIC_API_KEY=your-key-here"
    echo ""
fi

# Run Claude Code with the directive
claude "
Read the CLAUDE_ANALYSIS_DIRECTIVE.md file in this directory.

Follow ALL steps in that directive to:
1. Query the database for pending websites (status='pending_analysis')
2. For each website, use WebFetch to analyze it through the 8-step conversion ladder
3. Save the analysis results to the database (website_contexts table)
4. Update website status to 'analyzed' (NOT 'active')

IMPORTANT: Do NOT generate commands. That happens in step 2.

Work through websites one at a time. Be thorough and specific in your analysis.

Database connection: Use the DATABASE_URL environment variable (PostgreSQL)
"

echo ""
echo "✅ Step 1 complete! Website analysis saved."
echo ""
echo "Next step: Generate improvement commands"
echo "Run: ./bin/generate_commands.sh"

# Claude Code Manual Analysis Workflow

**Status:** MVP Implementation - Manual Trigger

This document explains how the new Claude Code-based website analysis works.

---

## Overview

Instead of using the Anthropic API, this system uses **Claude Code CLI** to analyze websites through **two-step sequential process**.

**Benefits:**
- ✅ Two-step process prevents LLM overload (analyze → generate commands)
- ✅ More token-efficient (only fetches what's needed)
- ✅ Smarter exploration (can navigate sites intelligently)
- ✅ Sequential reasoning (each step builds on previous)
- ✅ Uses WebFetch tool for dynamic content fetching
- ✅ No API costs (uses Claude Code instead)

---

## How It Works

### User Flow

1. **User submits website in Phoenix UI**
   - Website created with status: `pending_analysis`
   - Log message: "Run 'bin/analyze_websites.sh' to analyze with Claude Code"

2. **User runs STEP 1 - Analysis:**
   ```bash
   cd /Users/apple/Documents/shepherd
   ./bin/analyze_websites.sh
   ```
   - Claude Code analyzes website through 8-step conversion ladder
   - Saves context document to `website_contexts` table
   - Updates status to `analyzed` (NOT `active` yet)

3. **User runs STEP 2 - Command Generation:**
   ```bash
   ./bin/generate_commands.sh
   ```
   - Claude Code reads existing analysis + conversion framework
   - Generates 3-7 specific improvement commands
   - Saves to `commands` table
   - Updates status to `active`

4. **User refreshes Phoenix UI:**
   - Sees analysis results at `/website?tab=commands`
   - Commands appear sorted by urgency

---

## Files Created

### 1. `CLAUDE_ANALYSIS_DIRECTIVE.md` (Step 1)
Directive for website analysis only.

**Contains:**
- Step-by-step instructions for analyzing websites
- 8-step conversion ladder framework
- Database query examples
- JSON schema for context document
- SQL commands for saving analysis
- Sets status to `analyzed` (not `active`)

### 2. `CLAUDE_COMMAND_GENERATION_DIRECTIVE.md` (Step 2)
Directive for generating improvement commands.

**Contains:**
- Instructions to read existing analysis
- How to apply conversion ladder framework
- Command generation strategies
- Prioritization rules (60-70% on bottleneck)
- SQL commands for saving commands
- Sets status to `active`

### 3. `bin/analyze_websites.sh` (Step 1 Script)
Bash script that analyzes websites.

**Usage:**
```bash
./bin/analyze_websites.sh
```

### 4. `bin/generate_commands.sh` (Step 2 Script)
Bash script that generates commands.

**Usage:**
```bash
./bin/generate_commands.sh
```

---

## Modified Files

### 1. `lib/shepherd/llm/website_manager.ex`
- `create_website_with_scan/2` now sets status to `pending_analysis`
- No longer queues Oban background job
- Added `pending_analysis` and `analyzing` to valid statuses

### 2. `lib/shepherd/websites/website.ex`
- Updated status validation to include `pending_analysis` and `analyzing`

### 3. `lib/shepherd/llm/context_schema.ex`
- Added new fields: `conversion_goal`, `step_analysis`, `bottleneck_step`, `bottleneck_issue`
- Updated validation to require new fields

### 4. `lib/shepherd/llm/directives.ex`
- Rewrote `@on_website_scan_requested` with 8-step framework
- Rewrote `@on_analysis_completed` for bottleneck-focused commands
- **Note:** These directives are NOT used in MVP (Claude Code uses CLAUDE_ANALYSIS_DIRECTIVE.md instead)
- Can be useful for future API-based automation

---

## Testing the Workflow

### 1. Create a test website

```bash
# Start Phoenix server
mix phx.server

# In browser, go to http://localhost:4000
# Submit a website URL (e.g., https://example.com)
```

**Expected:**
- Website created with status `pending_analysis`
- Log shows: "Run 'bin/analyze_websites.sh' to analyze with Claude Code"

### 2. Run analysis

```bash
./bin/analyze_websites.sh
```

**Claude Code will:**
- Query for pending websites
- Use WebFetch to analyze each
- Save results to database
- Update status to `active`

### 3. View results

```bash
# Refresh browser at http://localhost:4000/website?tab=commands
```

**Expected:**
- Context populated with 8-step analysis
- Commands visible (3-7 commands)
- Sorted by urgency (critical → high → medium → low)

---

## Database Queries (Debugging)

### Check pending websites
```sql
SELECT id, url, name, status, inserted_at
FROM websites
WHERE status = 'pending_analysis';
```

### Check analysis results
```sql
SELECT w.name, w.status, wc.context_document
FROM websites w
LEFT JOIN website_contexts wc ON wc.website_id = w.id
WHERE w.id = '<website_id>';
```

### Check generated commands
```sql
SELECT command_text, urgency, llm_reasoning, status
FROM commands
WHERE entity_type = 'website' AND entity_id = '<website_id>'
ORDER BY
  CASE urgency
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
  END;
```

---

## Future Automation Options

### Option 1: Cron Job (Simple)
```bash
# Add to crontab (runs every 5 minutes)
*/5 * * * * cd /Users/apple/Documents/shepherd && ./bin/analyze_websites.sh >> /tmp/website_analysis.log 2>&1
```

### Option 2: Systemd Service (Linux)
Create a service that watches for new websites and triggers analysis automatically.

### Option 3: File Watcher
Use `fswatch` or similar to watch database changes and trigger analysis.

### Option 4: Restore Oban Job (with subprocess)
Modify `ScanWebsiteWorker` to spawn Claude Code as subprocess instead of calling Anthropic API.

---

## Troubleshooting

### "Claude Code not found"
Install Claude Code CLI:
```bash
# Download from https://claude.ai/download
# Or use homebrew (if available)
brew install claude-cli
```

### Analysis not saving to database
Check database connection:
```bash
psql -d shepherd_dev -c "SELECT COUNT(*) FROM websites;"
```

Verify Claude Code can access database:
```bash
claude "Query the shepherd_dev database and show me website count"
```

### Website stuck in "pending_analysis"
Manually run analysis:
```bash
./bin/analyze_websites.sh
```

Or manually update status:
```sql
UPDATE websites SET status = 'active' WHERE status = 'pending_analysis';
```

---

## Key Differences from Previous Approach

| Aspect | Old (Anthropic API) | New (Claude Code) |
|--------|---------------------|-------------------|
| **Trigger** | Automatic (Oban job) | Manual (run script) |
| **Analysis** | Single API call with 15k HTML | Multi-step with WebFetch |
| **Cost** | API tokens per request | Free (uses Claude Code) |
| **Flexibility** | Fixed prompt | Can navigate site intelligently |
| **Control** | Background automatic | User-triggered manual |

---

## Next Steps

1. **Test with real websites** - Try analyzing various website types
2. **Refine directive** - Improve CLAUDE_ANALYSIS_DIRECTIVE.md based on results
3. **Automate** - Set up cron job or other automation when ready
4. **Command generation** - Optionally add command generation to the directive
5. **Multi-page analysis** - Extend directive to analyze beyond homepage

---

## Support

For issues or questions:
1. Check logs: `tail -f log/dev.log`
2. Check database directly with `psql -d shepherd_dev`
3. Run Claude Code manually with verbose output

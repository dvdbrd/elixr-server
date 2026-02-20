# Shepherd - Developer Guide

**Last Updated:** 2026-02-20

## What This Is

An Elixir/Phoenix web application where users submit their website URLs and receive AI-generated improvement commands. You (the operator) run Claude Code CLI on the server to analyze websites and generate actionable commands for users.

---

## Architecture Overview

**Deployment Model:**
- Phoenix web app deployed on server
- Claude Code CLI installed on same server
- You SSH into server to trigger analysis manually
- No Anthropic API calls - everything via Claude Code

**User Flow:**
1. User creates account (Phoenix authentication)
2. User submits website URL via `/website?tab=settings`
3. Website saved with `status='pending_analysis'`
4. User sees "Awaiting Analysis" message in UI

**Your Flow (Manual MVP):**
1. SSH into server where app is deployed
2. Run `./bin/analyze_websites.sh` (Step 1: Analysis)
3. Claude Code fetches website, analyzes via 8-step conversion ladder, saves to DB
4. Run `./bin/generate_commands.sh` (Step 2: Commands)
5. Claude Code generates 3-7 commands based on analysis, saves to DB
6. User refreshes UI → sees commands at `/website?tab=commands`

**Future Automation:**
- Cron job or systemd timer to run scripts periodically
- Or file watcher to detect new websites and auto-trigger

---

## Database Schema

### Core Tables

**users** - Phoenix authentication (phx.gen.auth)
- Standard auth fields (email, hashed_password, etc.)

**websites** - User-submitted websites
- `user_id` → references users
- `url` → Website URL (string, max 500 chars)
- `name` → Optional website name
- `status` → pending_analysis | analyzing | analyzed | active | error | inactive
- `last_scanned_at` → Timestamp of last analysis
- **Flow:** pending_analysis → analyzed → active

**website_contexts** - Analysis results (JSONB)
```json
{
  "concept": "What this website does (1 sentence)",
  "business_type": "travel_agency | tour_operator | ecommerce | saas | other",
  "target_destinations": ["Country1", "Country2"],
  "service_types": ["tours", "hotels", "flights"],
  "primary_cta": "Exact CTA button text",
  "confusion": [{"issue": "unclear thing", "page": "where found"}],
  "scan_cache": {
    "pages_analyzed": ["url1"],
    "scan_date": "2026-02-20T10:30:00Z",
    "homepage_summary": "Brief summary"
  },
  "conversion_goal": "Primary action visitors should take",
  "step_analysis": {
    "step_1_attention": {"status": "good", "notes": "..."},
    "step_2_engagement": {"status": "weak", "notes": "..."},
    "step_3_comprehension": {"status": "failing", "notes": "..."},
    "step_4_belief": {"status": "weak", "notes": "..."},
    "step_5_desire": {"status": "good", "notes": "..."},
    "step_6_urgency": {"status": "failing", "notes": "..."},
    "step_7_intent": {"status": "good", "notes": "..."},
    "step_8_action": {"status": "weak", "notes": "..."}
  },
  "bottleneck_step": "step_3_comprehension",
  "bottleneck_issue": "Clear description of why this step fails"
}
```

**commands** - AI-generated improvement tasks (polymorphic)
- `user_id` → references users
- `entity_type` / `entity_id` → "website" + website UUID
- `command_text` → "Update homepage hero section to clearly state..."
- `urgency` → low | medium | high | critical
- `llm_reasoning` → "The value proposition is buried, costing 40-60% conversions"
- `status` → pending | in_progress | completed | dismissed | overdue
- `created_by` → llm | user | system

**user_questions** - Questions from AI to user (polymorphic)
- Used for onboarding questions or complaints
- `question_type` → onboarding | complaint | clarification | feedback_request
- `severity` → info | warning | critical

**action_logs** - Audit trail (not actively used yet)

**user_behavior_metrics** - Behavioral tracking (planned, not implemented)

---

## Key Modules

### WebsiteManager (`lib/shepherd/llm/website_manager.ex`)

Main interface for website operations.

**Most Important Functions:**

```elixir
# Create website with pending_analysis status
WebsiteManager.create_website_with_scan(%{
  user_id: 1,
  url: "https://example.com",
  name: "Example Site"
})

# Get context document
{:ok, context} = WebsiteManager.get_context(user_id, website_id)

# Update context document
WebsiteManager.update_context(user_id, website_id, new_jsonb_map)

# Update website status
WebsiteManager.update_website_status(user_id, website_id, "analyzed")

# Get websites needing analysis
WebsiteManager.get_unscanned_websites(user_id, limit)
```

### CommandManager (`lib/shepherd/llm/command_manager.ex`)

Manages improvement commands.

```elixir
# Get pending commands
{:ok, commands} = CommandManager.get_pending_commands(user_id, "website", website_id)

# Create command
CommandManager.create_command(%{
  user_id: 1,
  entity_type: "website",
  entity_id: website_id,
  command_text: "Add pricing table to homepage",
  urgency: "critical",
  llm_reasoning: "Step 3 comprehension failing...",
  created_by: "llm"
})

# User actions
CommandManager.complete_command(user_id, command_id)
CommandManager.dismiss_command(user_id, command_id)
```

---

## Running Analysis Manually

### Setup

```bash
# Ensure Claude Code CLI is installed
which claude

# If not installed, get it from:
# https://claude.ai/download

# Ensure Phoenix app is running (for DB access)
mix phx.server
```

### Step 1: Analyze Websites

```bash
ssh user@yourserver.com
cd /path/to/shepherd

# Run analysis script
./bin/analyze_websites.sh

# Or invoke Claude directly:
claude "
Read CLAUDE_ANALYSIS_DIRECTIVE.md and process all pending websites.
Database: shepherd_dev
"
```

**What happens:**
- Claude queries for `status='pending_analysis'`
- For each website:
  - Fetches homepage with WebFetch tool
  - Analyzes through 8-step conversion ladder
  - Saves context document to `website_contexts` table
  - Updates status to `analyzed`

### Step 2: Generate Commands

```bash
# Run command generation script
./bin/generate_commands.sh

# Or invoke Claude directly:
claude "
Read CLAUDE_COMMAND_GENERATION_DIRECTIVE.md and generate commands.
Database: shepherd_dev
"
```

**What happens:**
- Claude queries for `status='analyzed'`
- For each website:
  - Reads existing context document
  - Applies conversion framework
  - Generates 3-7 specific commands (60-70% on bottleneck)
  - Inserts into `commands` table
  - Updates status to `active`

---

## Common Queries

### Check pending websites

```sql
SELECT id, url, name, status, inserted_at
FROM websites
WHERE status = 'pending_analysis'
ORDER BY inserted_at ASC;
```

### Check analysis results

```sql
SELECT w.name, w.status, wc.context_document->>'bottleneck_step' as bottleneck
FROM websites w
LEFT JOIN website_contexts wc ON wc.website_id = w.id
WHERE w.user_id = 1;
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

### Find websites needing re-analysis (stale)

```sql
SELECT id, url, name, last_scanned_at
FROM websites
WHERE last_scanned_at < NOW() - INTERVAL '7 days'
  OR last_scanned_at IS NULL
ORDER BY last_scanned_at ASC NULLS FIRST;
```

---

## Development Setup

### First Time Setup

```bash
# Clone and install
git clone <repo>
cd shepherd
mix setup

# Configure environment
cp .env.example .env
# Edit .env - no API keys needed for MVP

# Start server
mix phx.server

# Visit http://localhost:4000
```

### Database Reset

```bash
# Reset DB and run seeds
mix ecto.reset

# Seeds create a test website with pending_analysis status
# Then you can run analysis scripts to test
```

### Testing the Full Flow

```bash
# 1. Start Phoenix
mix phx.server

# 2. In browser: Create account at http://localhost:4000
# 3. Submit website URL at /website?tab=settings

# 4. In terminal: Run analysis
./bin/analyze_websites.sh

# 5. Run command generation
./bin/generate_commands.sh

# 6. In browser: Refresh /website?tab=commands
# Should see 3-7 commands sorted by urgency
```

---

## File Structure

```
shepherd/
├── README.md                                    # External overview
├── WORKFLOW.md                                  # Manual workflow docs
├── GUIDE.md                                     # This file
├── CLAUDE_ANALYSIS_DIRECTIVE.md                # Step 1 instructions
├── CLAUDE_COMMAND_GENERATION_DIRECTIVE.md      # Step 2 instructions
├── CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md     # Analysis framework
│
├── bin/
│   ├── analyze_websites.sh                     # Step 1 script
│   └── generate_commands.sh                    # Step 2 script
│
├── lib/shepherd/
│   ├── llm/
│   │   ├── website_manager.ex                  # Core functions
│   │   ├── command_manager.ex                  # Command CRUD
│   │   └── context_schema.ex                   # Validation
│   ├── websites/
│   │   ├── website.ex                          # Schema
│   │   ├── website_context.ex                  # Schema
│   │   └── user_question.ex                    # Schema
│   └── commands/
│       └── command.ex                          # Schema
│
├── lib/shepherd_web/live/
│   └── website_live/
│       └── index.ex                            # Main UI
│
└── priv/repo/
    ├── migrations/                             # DB migrations
    └── seeds.exs                               # Test data
```

---

## UI Overview

### User Dashboard (`/website?tab=<tab>`)

**Tabs:**
- **Commands** - Pending improvement commands (complete/dismiss actions)
- **Complain** - AI-detected issues as questions (not actively used)
- **Report** - Placeholder
- **Brainstorm** - Placeholder
- **Settings** - Edit website URL, view analysis status

**User sees:**
- Website concept summary (from context)
- 3-7 commands sorted by urgency (critical → high → medium → low)
- Each command shows reasoning and business impact
- Complete/Dismiss buttons

---

## Future Plans

### Phase 1: MVP (Current)
- ✅ Manual website analysis via Claude Code
- ✅ Command generation via conversion framework
- ✅ User UI for viewing/completing commands
- ✅ Polymorphic architecture (ready for expansion)

### Phase 2: Automation
- [ ] Cron job to auto-process pending websites
- [ ] Periodic re-analysis of stale websites
- [ ] Email notifications for new commands

### Phase 3: Behavioral Tracking
- [ ] Track user response times
- [ ] Track command completion rates
- [ ] Adapt LLM tone based on behavior (harsh for procrastinators)
- [ ] Generate behavioral feedback

### Phase 4: Multi-Domain
- [ ] Marketing campaign commands
- [ ] Sales funnel optimization
- [ ] Customer support analysis

---

## Important Notes

1. **Manual workflow is intentional** - Keeps costs zero, gives you control
2. **User ID mostly hardcoded** - Current UI uses `user_id: 1` in LiveView
3. **Single website per user** - MVP limitation, DB supports multiple
4. **Polymorphic design** - Easy to add new entity types later
5. **No API costs** - Everything via Claude Code CLI
6. **Graceful errors** - Analysis can succeed even if command gen fails

---

## Troubleshooting

**Commands not appearing:**
1. Check website status: `SELECT status FROM websites WHERE id = '<id>';`
2. Should be `active` after step 2
3. Query commands table directly
4. Check logs from Claude Code execution

**Analysis not saving:**
1. Verify database connection: `psql -d shepherd_dev`
2. Check Claude has DB access
3. Look for SQL errors in Claude output

**Website stuck in pending_analysis:**
1. Run analysis script manually
2. Or update status: `UPDATE websites SET status = 'active' WHERE status = 'pending_analysis';`

---

## Security

**User scoping:**
All functions enforce user_id scoping:
```elixir
from w in Website,
  where: w.id == ^website_id and w.user_id == ^user_id
```

**Claude Code permissions:**
- Can read/write database
- Can fetch URLs via WebFetch
- Cannot execute arbitrary system commands (sandboxed)

---

For workflow details, see **WORKFLOW.md**.
For analysis instructions, see **CLAUDE_ANALYSIS_DIRECTIVE.md**.
For command generation, see **CLAUDE_COMMAND_GENERATION_DIRECTIVE.md**.

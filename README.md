# Shepherd

**Autonomous website management using LLM**

Your AI manager that analyzes websites, identifies opportunities, and issues commands for improvement - automatically.

## ✅ MVP is Live

```elixir
# Create a website
{:ok, website} = Shepherd.LLM.WebsiteManager.create_website_with_scan(%{
  user_id: 1,
  url: "https://example.com",
  name: "My Site"
})

# That's it! Background job will:
# 1. Analyze the website
# 2. Generate structured context
# 3. Create 3-7 actionable commands
# 4. Show results in UI
```

## What It Does

1. **Scans Your Website** - LLM analyzes homepage, understands business type, value prop, CTAs
2. **Creates Context** - Structured understanding (concept, services, target audience, confusion points)
3. **Generates Commands** - 3-7 prioritized improvements with urgency levels and business reasoning
4. **Tracks Progress** - UI to complete/dismiss commands, behavioral feedback system

## Quick Start

```bash
# Setup
git clone <repo>
cd shepherd
cp .env.example .env
# Add ANTHROPIC_API_KEY to .env

# Run
source .env
mix setup
mix phx.server

# Visit http://localhost:4000
```

## Tech Stack

- **Elixir/Phoenix** - Web framework
- **LiveView** - Real-time UI
- **Oban** - Background jobs
- **Anthropic Claude** - LLM analysis
- **PostgreSQL** - Database with JSONB

## Architecture

**Polymorphic Design** - Commands, questions, and tracking work for any entity type:
- Websites (MVP)
- Marketing campaigns (planned)
- Sales pipelines (planned)

**Automatic Flow:**
```
Create website → Queue scan → LLM analyzes → Generate commands → UI updates
```

## Documentation

- **CLAUDE.md** - Developer guide (comprehensive)
- **MVP_SUMMARY.md** - Implementation changelog
- **Context.md** - Product vision

## Status

✅ MVP Complete:
- Auto-scan on website creation
- Context generation with validated schema
- Command generation (3-7 per site)
- Commands UI (complete/dismiss)
- Background job processing

🚧 In Progress:
- Behavioral tracking & tone adaptation
- Multi-page scanning
- Periodic re-scans

## License

MIT

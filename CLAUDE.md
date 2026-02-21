# Shepherd (elixr-server)

AI-powered website conversion analysis tool. Phoenix 1.8 + LiveView + PostgreSQL + Oban.

## Commands

- `mix setup` — Install deps, create DB, run migrations, build assets
- `mix phx.server` — Start dev server on localhost:4000
- `mix test` — Run test suite
- `mix ecto.migrate` — Run pending migrations
- `mix ecto.reset` — Drop + recreate + migrate + seed DB
- `bin/analyze_websites.sh` — Step 1: Claude CLI analyzes pending websites
- `bin/generate_commands.sh` — Step 2: Claude CLI generates commands for analyzed websites

## Architecture

```
lib/shepherd/          — Business logic (contexts)
  accounts/            — Auth system (phx.gen.auth): users, tokens, scopes
  websites/            — Website, WebsiteContext, UserQuestion schemas
  commands/            — Command schema (prioritized action items)
  contexts/            — ContextFragment schema + Shepherd.Contexts context module
  analytics/           — ActionLog, UserBehaviorMetric schemas + Shepherd.Analytics context module
  llm/                 — LLM integration: WebsiteManager, CommandManager, FeedbackManager, ContextManager, ContextSchema, UserCommand, DirectiveProcessor, Directives
  workers/             — Oban background jobs: ExpirationWorker, MetricsAggregationWorker

lib/shepherd_web/      — Web layer
  live/                — All LiveViews (HQ dashboards, website mgmt, terminal, auth)
  controllers/         — Session controller, page controller
  components/          — CoreComponents, Navbar, CustomIcons, Layouts
```

## Key Design Decisions

- **Two-step manual CLI workflow**: `bin/analyze_websites.sh` then `bin/generate_commands.sh`. No runtime Anthropic API calls in MVP.
- **Polymorphic entity pattern**: Commands, questions, context_fragments, action_logs use `entity_type` + `entity_id` columns for multi-domain support.
- **UUIDs for domain tables**: All domain tables use UUID primary keys. `users` table uses integer PK.
- **Website status flow**: `pending_analysis` → `analyzed` → `active` (with `error`/`inactive` branches)

## Known MVP Limitations

- `UserCommand` is a schema alias mirroring `Commands.Command`, used by HQ LiveViews.

## Code Conventions

- Elixir standard: snake_case modules, 2-space indent
- Phoenix contexts pattern: manager modules in `lib/shepherd/llm/` wrap Ecto queries
- LiveView pattern: `mount/3` → `handle_params/3` → `handle_event/3`, use `assign/2`
- Frontend: Tailwind v4 + DaisyUI dark theme + terminal/retro green-on-black aesthetic
- JSONB for flexible data: `context_document`, `options`, `answer`, `metadata`, `context_data`
- Return tuples: `{:ok, result}` / `{:error, changeset}` for all context/manager functions
- Polymorphic pattern: `entity_type` (string) + `entity_id` (UUID) for cross-domain references
- UUID PKs for domain tables, integer PK for `users` table only

## Routing

- All domain views require authentication via `on_mount: [{ShepherdWeb.UserAuth, :require_authenticated}]`
- Auth views use `on_mount: [{ShepherdWeb.UserAuth, :mount_current_scope}]`
- API routes (`/api/*`) use `:api` pipeline (JSON only)
- Dev-only routes: `/dev/dashboard` (LiveDashboard), `/dev/mailbox` (Swoosh preview)
- Session: cookie-based, signed with `_shepherd_key`, 14-day remember-me via `_shepherd_web_user_remember_me`

## Supervision Tree

`Shepherd.Application` starts: Telemetry → Repo → DNSCluster → PubSub → Oban → Endpoint

## Database

- PostgreSQL with `citext` extension
- Dev DB: `shepherd_dev` (postgres/postgres on localhost)
- Seeds: `test@example.com` / `password12345` with one website (`https://gudauri.school`)

## Important Files

- When analyzing websites, read `CLAUDE_ANALYSIS_DIRECTIVE.md` for the 8-step conversion ladder analysis process
- When generating commands, read `CLAUDE_COMMAND_GENERATION_DIRECTIVE.md` for command generation rules
- For the conversion framework theory, read `CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md`
- For the full project guide, read `GUIDE.md`

## Deployment

Target: Gigalixir with PostgreSQL

### Required Setup
1. `pip install gigalixir` — install CLI
2. `gigalixir create` — create app
3. `gigalixir pg:create --free` — provision PostgreSQL
4. `gigalixir config:set SECRET_KEY_BASE=$(mix phx.gen.secret) PHX_HOST=your-app.gigalixirapp.com`
5. `git push gigalixir main` — deploy

### CI/CD
GitHub Actions runs tests on push to `main`/`develop` and auto-deploys to Gigalixir on `main`.

### Health Check
`GET /api/health` — returns `{"status": "ok"}` if DB is reachable.

## Module-Level CLAUDE.md Files

Each major module has its own CLAUDE.md with detailed documentation. These are loaded on-demand when working in that directory:

| Module | Path | Description |
|--------|------|-------------|
| LLM | `lib/shepherd/llm/CLAUDE.md` | Manager modules, context schema, stubs |
| Accounts | `lib/shepherd/accounts/CLAUDE.md` | Auth system (phx.gen.auth) |
| Websites | `lib/shepherd/websites/CLAUDE.md` | Website, WebsiteContext, UserQuestion schemas |
| Commands | `lib/shepherd/commands/CLAUDE.md` | Command schema and pipeline |
| Analytics | `lib/shepherd/analytics/CLAUDE.md` | ActionLog, UserBehaviorMetric (unused) |
| Contexts | `lib/shepherd/contexts/CLAUDE.md` | ContextFragment schema (unused) |
| LiveViews | `lib/shepherd_web/live/CLAUDE.md` | All LiveView modules and routes |
| Components | `lib/shepherd_web/components/CLAUDE.md` | CoreComponents, Navbar, CustomIcons, Layouts |
| Controllers | `lib/shepherd_web/controllers/CLAUDE.md` | Session, Health, Page controllers |

## Auto-Update Rules

When making significant changes to the codebase, update the relevant CLAUDE.md files:

- **Adding/removing a module**: Update the Architecture section here AND the module's own CLAUDE.md
- **Adding/removing routes**: Update the Routing section here AND `lib/shepherd_web/live/CLAUDE.md`
- **Changing status enums or data structures**: Update the relevant module's CLAUDE.md
- **Adding/removing supervision children**: Update the Supervision Tree section
- **Changing deployment config**: Update the Deployment section
- **Resolving a Known MVP Limitation**: Remove or update the entry in Known MVP Limitations
- **Adding a new context/domain module**: Create a CLAUDE.md in its directory following the existing pattern
- Always verify CLAUDE.md files reflect the current state after significant changes

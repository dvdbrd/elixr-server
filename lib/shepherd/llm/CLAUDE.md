# LLM Integration Layer

Core business logic for the Shepherd system. These modules are the primary interface between the CLI-driven analysis pipeline and the database. They provide user-scoped CRUD operations for websites, commands, feedback, and questions, plus schema definitions and validation for the JSONB context documents produced by LLM analysis.

## Module Overview

### Manager Modules (Business Logic)

- **`WebsiteManager`** (`website_manager.ex`) — Primary entry point for website operations. Handles the full website lifecycle: creation with auto-scan enqueueing, context document read/write, website status transitions, user question management (both legacy website-scoped and polymorphic entity-scoped), question expiration, question stats, fetching page HTML content, and retrieving LLM directives. Depends on `Directives` for directive retrieval and on `Shepherd.Websites.{Website, WebsiteContext, UserQuestion}` schemas.
- **`CommandManager`** (`command_manager.ex`) — CRUD for LLM-issued commands. Retrieves pending commands (sorted by urgency), fetches all commands with pagination, creates new commands, marks commands as completed or dismissed, and returns aggregate command stats by status. Operates on `Shepherd.Commands.Command` schema.
- **`FeedbackManager`** (`feedback_manager.ex`) — CRUD for LLM-generated feedback messages. Fetches active feedback (filtered by expiration and sorted by severity), fetches by type, retrieves full history with pagination, computes stats (active/critical/warning counts), creates feedback, acknowledges or dismisses individual items, expires stale feedback in bulk, and provides an admin delete-all function. Operates on the `Feedback` schema.
- **`ContextManager`** (`context_manager.ex`) — Full context management module with command and feedback tracking, question oversight, and dashboard summary. Exposes functions for command management, feedback tracking, question tracking, and dashboard data aggregation.

### Schema Modules (Data Definitions)

- **`Feedback`** (`feedback.ex`) — Ecto schema for the `llm_feedback` table. Defines fields: `user_id`, `feedback_type`, `severity`, `tone`, `title`, `message`, `context_data` (map), `status`, `expires_at`, `acknowledged_at`, `dismissed_at`, plus timestamps. Provides `changeset/2`, `acknowledge_changeset/1`, `dismiss_changeset/1`, and presentation helpers (`type_icon/1`, `severity_class/1`, `severity_symbol/1`). Uses binary UUID primary key.
- **`UserCommand`** (`user_command.ex`) — Ecto schema alias for the `commands` table, used by HQ LiveViews. Mirrors `Shepherd.Commands.Command` with identical fields: `user_id`, `entity_type`, `entity_id`, `command_text`, `urgency`, `status`, `created_by`, `llm_reasoning`, `deadline`, `completed_at`, `dismissed_at`, `time_to_complete`, `reminded_count`. Uses binary UUID primary key. Provides a basic `changeset/2`.
- **`ContextSchema`** (`context_schema.ex`) — Defines, documents, and validates the JSONB structure for website context documents stored in `website_contexts.context_document`. Provides `schema/0` (type map), `template/0` (example document), `field_documentation/0` (detailed field docs for LLM prompts), `validate/1` (structural validation), and `merge_contexts/2` (intelligent merge that appends confusion arrays).

### Directive Modules (LLM Prompt Infrastructure)

- **`Directives`** (`directives.ex`) — Defines and retrieves available LLM directives. Provides functions to list all directives, get by name, and query by trigger. Returns 4 directive definitions.
- **`DirectiveProcessor`** (`directive_processor.ex`) — Processes LLM directives when user questions are answered. Handles the `question_followup` directive; other directives are handled by CLI.

## Public Function Reference

### WebsiteManager

| Function | Signature | Returns |
|---|---|---|
| `get_context` | `(user_id, website_id)` | `{:ok, context_map}` or `{:error, reason}` |
| `update_context` | `(user_id, website_id, new_jsonb)` | `{:ok, website_context}` or `{:error, reason}` |
| `get_directives` | `()` | map of directives |
| `ask_question` | `(user_id, website_id, question_text, options)` | `{:ok, question}` or `{:error, reason}` |
| `get_unanswered_questions` | `(user_id, website_id)` | `{:ok, [questions]}` or `{:error, reason}` |
| `record_answer` | `(user_id, question_id, answer)` | `{:ok, question}` or `{:error, reason}` |
| `dismiss_question` | `(user_id, question_id)` | `{:ok, question}` or `{:error, reason}` |
| `get_unanswered_questions_by_entity` | `(user_id, entity_type, entity_id)` | `{:ok, [questions]}` or `{:error, reason}` |
| `get_unanswered_questions_by_type` | `(user_id, entity_type, entity_id, question_type)` | `{:ok, [questions]}` or `{:error, reason}` |
| `ask_question_polymorphic` | `(user_id, entity_type, entity_id, question_text, options, opts \\ [])` | `{:ok, question}` or `{:error, reason}` |
| `expire_old_questions` | `()` | `{:ok, count}` |
| `get_question_stats` | `(user_id, entity_type, entity_id)` | `{:ok, stats_map}` or `{:error, reason}` |
| `fetch_page_content` | `(url)` | `{:ok, html_string}` or `{:error, reason}` |
| `get_website_info` | `(user_id, website_id)` | `{:ok, website_map}` or `{:error, reason}` |
| `update_website_status` | `(user_id, website_id, status)` | `{:ok, website}` or `{:error, reason}` |
| `get_unscanned_websites` | `(user_id, limit \\ 10)` | list of websites |
| `get_stale_websites` | `(user_id, days_threshold \\ 7, limit \\ 10)` | list of websites |
| `create_website_with_scan` | `(attrs, opts \\ [])` | `{:ok, website}` or `{:error, changeset}` |

### CommandManager

| Function | Signature | Returns |
|---|---|---|
| `get_pending_commands` | `(user_id, entity_type, entity_id)` | `{:ok, [commands]}` |
| `get_all_commands` | `(user_id, entity_type, entity_id, limit \\ 50)` | `{:ok, [commands]}` |
| `get_pending_commands_by_type` | `(user_id, entity_type)` | `{:ok, [commands]}` |
| `create_command` | `(attrs)` | `{:ok, command}` or `{:error, changeset}` |
| `complete_command` | `(user_id, command_id)` | `{:ok, command}` or `{:error, :not_found}` |
| `dismiss_command` | `(user_id, command_id)` | `{:ok, command}` or `{:error, :not_found}` |
| `get_command_stats` | `(user_id)` | `%{pending, completed, dismissed, overdue}` |

### FeedbackManager

| Function | Signature | Returns |
|---|---|---|
| `get_active_feedback` | `(user_id)` | list of feedback |
| `get_feedback_by_type` | `(user_id, feedback_type)` | list of feedback |
| `get_all_feedback` | `(user_id, limit \\ 50)` | list of feedback |
| `get_feedback_stats` | `(user_id)` | `%{total_active, critical, warning}` |
| `create_feedback` | `(attrs)` | `{:ok, feedback}` or `{:error, changeset}` |
| `acknowledge_feedback` | `(user_id, feedback_id)` | `{:ok, feedback}` or `{:error, :not_found}` |
| `dismiss_feedback` | `(user_id, feedback_id)` | `{:ok, feedback}` or `{:error, :not_found}` |
| `expire_old_feedback` | `()` | `{count, nil}` (Repo.update_all result) |
| `delete_all_user_feedback` | `(user_id)` | `{count, nil}` (Repo.delete_all result) |

### ContextManager

| Function | Signature | Returns |
|---|---|---|
| `mark_command_dismissed` | `(user_id, command_id)` | delegates to `CommandManager.dismiss_command/2` |
| `get_command_overview` | `(user_id)` | map with command counts by status |
| `get_commands_by_domain` | `(user_id, entity_type)` | `{:ok, [commands]}` or `{:error, reason}` |
| `get_active_feedback` | `(user_id)` | list of active feedback |
| `get_feedback_stats` | `(user_id)` | map with feedback counts |
| `get_unanswered_questions` | `(user_id)` | list of pending questions |
| `get_dashboard_summary` | `(user_id)` | aggregated context for HQ dashboard |

### ContextSchema

| Function | Signature | Returns |
|---|---|---|
| `schema` | `()` | map of field names to types |
| `template` | `()` | example context document map |
| `field_documentation` | `()` | string with detailed field docs for LLM prompts |
| `validate` | `(context)` | `{:ok, context}` or `{:error, reason_string}` |
| `merge_contexts` | `(existing, new_context)` | merged context map |

### Directives

| Function | Signature | Returns |
|---|---|---|
| `all` | `()` | list of 4 directive definitions |
| `get` | `(name)` | directive struct or nil |
| `for_trigger` | `(trigger)` | list of directives matching trigger |
| `names` | `()` | list of directive names |

### DirectiveProcessor

| Function | Signature | Returns |
|---|---|---|
| `process` | `(directive, params)` | `{:ok, result}` or `{:error, reason}` |

## Context Document Structure

The `context_document` JSONB field in `website_contexts` follows the schema defined in `ContextSchema`. All fields are required (use empty values when data is unavailable).

**Top-level fields:**
- `concept` (string) — One sentence describing what the website does
- `business_type` (string) — One of: `travel_agency`, `tour_operator`, `booking_platform`, `other`
- `target_destinations` (array of strings) — Main countries/regions, max 5
- `service_types` (array of strings) — From: `tours`, `flights`, `hotels`, `packages`, `car_rental`, `activities`, `cruises`
- `primary_cta` (string) — Exact call-to-action wording from the homepage
- `confusion` (array of objects) — Each has `issue` (string) and `page` (string)
- `scan_cache` (object) — Required nested fields: `pages_analyzed` (array), `scan_date` (ISO datetime string), `homepage_summary` (string)
- `conversion_goal` (string) — Primary desired visitor action
- `step_analysis` (object) — 8-step conversion ladder, keys `step_1_attention` through `step_8_action`, each with `status` (`good`/`weak`/`failing`) and `notes`
- `bottleneck_step` (string) — Worst-performing step name (e.g., `step_3_comprehension`)
- `bottleneck_issue` (string) — Why that step fails

**Merge behavior:** `merge_contexts/2` takes new values for all scalar fields but appends (not replaces) the `confusion` array.

## Enums and Allowed Values

**Website statuses** (enforced by `update_website_status/3`):
`pending_analysis`, `analyzing`, `analyzed`, `active`, `error`, `inactive`

**Command urgency levels** (sorted in `get_pending_commands`):
`critical` > `high` > `medium` > `low`

**Command statuses:**
`pending`, `completed`, `dismissed`, `overdue`

**Feedback types:**
`daily_summary`, `weekly_summary`, `procrastination_warning`, `encouragement`, `harsh_warning`, `performance_review`

**Feedback severities** (sorted in `get_active_feedback`):
`critical` > `warning` > `success` > `info`

**Feedback tones:**
`harsh`, `direct`, `encouraging`, `neutral`, `robotic`

**Feedback statuses:**
`active`, `acknowledged`, `dismissed`, `expired`

**Question statuses:**
`pending`, `answered`, `dismissed`, `expired`

**Question types** (polymorphic, `ask_question_polymorphic` opts):
`onboarding` (default), plus any custom string

**Question severity levels:**
`info` (default), plus any custom string

## Patterns and Conventions

- **User scoping**: All manager functions that touch user data take `user_id` as the first argument. Guard clauses (`when not is_nil(user_id)`) enforce this at the function head level, with explicit `nil` user_id clauses returning `{:error, :user_id_required}`.
- **Return tuples**: Manager functions consistently return `{:ok, result}` / `{:error, reason}` tuples. Reasons are atoms (`:not_found`, `:user_id_required`, `:invalid_jsonb`, `:invalid_status`) or Ecto changesets.
- **Ownership verification**: Before mutating any record, managers query to verify the record belongs to the requesting user via a join or where clause on `user_id`.
- **Polymorphic entity pattern**: Commands, questions, and context fragments use `entity_type` (string) + `entity_id` (binary UUID) columns. `WebsiteManager` supports both legacy website-scoped question functions and newer polymorphic variants. When `entity_type` is `"website"`, `ask_question_polymorphic` also sets `website_id` for backward compatibility.
- **Urgency/severity sorting**: Both `CommandManager.get_pending_commands` and `FeedbackManager.get_active_feedback` use SQL `CASE` fragments to sort by priority level.
- **Bulk operations**: `expire_old_questions/0` and `expire_old_feedback/0` use `Repo.update_all` for batch status transitions.
- **Insert-or-update**: `WebsiteManager.update_context` uses `Repo.get_by` then `Repo.insert_or_update` to create context records on first write.
- **HTTP fetching**: `fetch_page_content/1` uses `Req` library with 3 max redirects and 15s timeout. It is the only function in this module that does not require `user_id`.
- **UUID primary keys**: Both `Feedback` and `UserCommand` schemas use `@primary_key {:id, :binary_id, autogenerate: true}`.
- **Schema duplication**: `UserCommand` is a deliberate schema alias that mirrors `Shepherd.Commands.Command`, providing a separate Ecto schema for the same `commands` table, used by HQ LiveViews.
- **Directive infrastructure**: `Directives` defines 4 LLM directives and `DirectiveProcessor` processes the `question_followup` directive when user questions are answered. Other directives are handled by CLI.

## Module Dependencies

```
WebsiteManager
  ├── Shepherd.Repo
  ├── Shepherd.Websites.{Website, WebsiteContext, UserQuestion}
  └── Directives (via get_directives/0)

CommandManager
  ├── Shepherd.Repo
  └── Shepherd.Commands.Command

FeedbackManager
  ├── Shepherd.Repo
  └── Feedback (local schema)

ContextManager
  └── CommandManager (delegates mark_command_completed)

ContextSchema
  └── (no dependencies, pure functions)

Feedback
  └── Ecto.Schema / Ecto.Changeset

UserCommand
  └── Ecto.Schema / Ecto.Changeset

Directives
  └── (no dependencies)

DirectiveProcessor
  └── Logger
```

## Auto-Update Rules

When modifying files in this module:
- Adding/removing a module: Update the Modules section
- Adding/removing public functions: Update the relevant module description
- Changing return types or function signatures: Update Patterns section
- Changing data structures (JSONB schemas, enums): Update relevant sections
- Always verify this CLAUDE.md reflects the current state after significant changes

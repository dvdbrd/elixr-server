# Analytics Context

Schemas for tracking user behavior and audit logging. Supports LLM personality adaptation and procrastination detection. Currently schema-only with no context module, no tests, and no integration into LiveViews or other application code.

## Modules

### `Shepherd.Analytics.ActionLog`

Audit trail schema for tracking all user actions. Maps to the `action_logs` table.

**Primary key:** `:id` (bigserial, auto-generated)

#### Schema Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `user_id` | `:integer` | -- | References the user who performed the action |
| `action_type` | `:string` | -- | One of the valid action types (see below) |
| `entity_type` | `:string` | -- | Polymorphic: the kind of entity acted upon (e.g., `"user_question"`, `"command"`) |
| `entity_id` | `:binary_id` | -- | UUID of the entity acted upon |
| `metadata` | `:map` | `%{}` | JSONB details about the action (kept minimal for performance) |
| `timestamp` | `:utc_datetime` | -- | When the action occurred |

No `timestamps()` macro is used; `timestamp` is a manually managed field.

#### Valid Action Types

Defined in `@valid_action_types`:
- `"question_answered"`
- `"question_dismissed"`
- `"command_completed"`
- `"command_dismissed"`
- `"context_updated"`
- `"website_added"`
- `"website_scanned"`
- `"settings_updated"`

#### Associations

None. `user_id` is a plain integer field, not a `belongs_to` association.

#### Functions

- **`changeset/2`** (`@doc false`) -- Casts all fields, requires `[:user_id, :action_type, :timestamp]`, validates `action_type` inclusion against `@valid_action_types`, auto-sets `timestamp` to `DateTime.utc_now()` (truncated to second) if not provided.
- **`log/1`** -- Creates and inserts an `ActionLog` entry via `Shepherd.Repo.insert/1`. Accepts an attrs map.
- **`log_question_answered/4`** -- Convenience wrapper around `log/1`. Params: `(user_id, question_id, answer, response_time_seconds)`. Sets `action_type: "question_answered"`, `entity_type: "user_question"`, and stores `answer` and `response_time_seconds` in metadata.
- **`log_command_completed/3`** -- Convenience wrapper around `log/1`. Params: `(user_id, command_id, time_to_complete)`. Sets `action_type: "command_completed"`, `entity_type: "command"`, and stores `time_to_complete` in metadata.

#### Private Functions

- **`maybe_set_timestamp/1`** -- If `timestamp` is nil on the changeset, sets it to `DateTime.utc_now()` truncated to the second.

---

### `Shepherd.Analytics.UserBehaviorMetric`

Aggregated behavioral pattern schema, calculated from action logs. Enables LLM personality adaptation and procrastination detection. Maps to the `user_behavior_metrics` table.

**Primary key:** `:id` (UUID, auto-generated)
**Foreign key type:** `:binary_id`

#### Schema Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `user_id` | `:integer` | -- | References the user; has a unique constraint |
| `avg_question_response_time` | `:integer` | -- | Average question response time in seconds |
| `avg_command_completion_time` | `:integer` | -- | Average command completion time in seconds |
| `question_completion_rate` | `:decimal` | -- | Rate from 0.0 to 1.0 |
| `command_completion_rate` | `:decimal` | -- | Rate from 0.0 to 1.0 |
| `dismissal_rate` | `:decimal` | -- | Rate from 0.0 to 1.0 |
| `procrastination_score` | `:decimal` | -- | Score from 0.0 to 10.0 (higher = more procrastination) |
| `overdue_command_count` | `:integer` | `0` | Number of overdue commands |
| `active_hours` | `:map` | `%{}` | JSONB map of active hours pattern |
| `active_days` | `:map` | `%{}` | JSONB map of active days pattern |
| `preferred_communication_style` | `:string` | -- | One of: `"direct"`, `"encouraging"`, `"harsh"`, `"neutral"` |
| `responds_to_urgency` | `:boolean` | `true` | Whether the user responds to urgency-based prompts |
| `total_questions_answered` | `:integer` | `0` | Lifetime count |
| `total_commands_completed` | `:integer` | `0` | Lifetime count |
| `total_commands_dismissed` | `:integer` | `0` | Lifetime count |
| `updated_at` | `:utc_datetime` | -- | Auto-set on every changeset application |

No `timestamps()` macro is used; `updated_at` is manually managed via `maybe_set_updated_at/1`.

#### Associations

None. `user_id` is a plain integer field with a unique constraint, not a `belongs_to` association.

#### Functions

- **`changeset/2`** (`@doc false`) -- Casts all fields (except `:id`), requires `[:user_id]`. Validations:
  - `question_completion_rate`: >= 0, <= 1
  - `command_completion_rate`: >= 0, <= 1
  - `dismissal_rate`: >= 0, <= 1
  - `procrastination_score`: >= 0, <= 10
  - `preferred_communication_style`: must be one of `["direct", "encouraging", "harsh", "neutral"]`
  - `unique_constraint` on `:user_id`
  - Auto-sets `updated_at` via `maybe_set_updated_at/1`

- **`recommend_communication_style/1`** -- Pure function. Takes a numeric `procrastination_score` and returns a communication style string:
  - >= 8.0 -> `"harsh"`
  - >= 5.0 -> `"direct"`
  - >= 2.0 -> `"encouraging"`
  - < 2.0 -> `"neutral"`

- **`procrastinating?/1`** -- Takes a `%UserBehaviorMetric{}` struct. Returns `true` if any of:
  - `procrastination_score >= 6.0`
  - `overdue_command_count >= 3`
  - `command_completion_rate < 0.5` (defaults to `1.0` if nil)

- **`calculate_procrastination_score/1`** -- Pure function. Takes a keyword list with optional keys `:overdue_count`, `:avg_delay_hours`, `:dismissal_rate`. Returns a float score from 0.0 to 10.0 using a weighted formula:
  - `overdue_score = min(overdue_count * 2.0, 5.0)`
  - `delay_score = min(avg_delay_hours / 24.0, 3.0)`
  - `dismissal_score = dismissal_rate * 2.0`
  - Total capped at 10.0

#### Private Functions

- **`maybe_set_updated_at/1`** -- Always sets `updated_at` to `DateTime.utc_now()` truncated to the second on every changeset.

## Integration Status

- **No context module exists.** There is no `Shepherd.Analytics` context module wrapping queries or business logic. Both schemas call `Shepherd.Repo` directly (only `ActionLog.log/1` does so).
- **No LiveView integration.** No LiveView or controller references, aliases, or calls any analytics module.
- **No tests.** No test files exist for this module.
- **No callers.** `log/1`, `log_question_answered/4`, and `log_command_completed/3` are defined but never invoked from anywhere in the codebase. The `UserBehaviorMetric` pure functions (`recommend_communication_style/1`, `procrastinating?/1`, `calculate_procrastination_score/1`) are also uncalled.

## TODO

- Create a `Shepherd.Analytics` context module to wrap Repo operations and provide a public API.
- Integrate `ActionLog.log/1` calls into LiveView event handlers to begin collecting action data.
- Build a periodic job (e.g., Oban worker) to aggregate `action_logs` into `user_behavior_metrics`.
- Wire `recommend_communication_style/1` and `procrastinating?/1` into LLM prompt generation for personality adaptation.
- Add `belongs_to :user` associations (requires adding foreign key constraints to migrations).
- Write tests for changesets, pure functions, and future context module.

## Auto-Update Rules

When modifying files in this module:
- Adding/removing schema fields: Update field documentation
- Adding context modules: Update module list and remove from TODO
- Integrating into LiveViews: Update integration status
- Adding new convenience functions: Document in the relevant schema section
- Always verify this CLAUDE.md reflects the current state after significant changes

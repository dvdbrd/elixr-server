# LiveViews

All UI is rendered via Phoenix LiveView. No JSON API endpoints exist (except `GET /api/health`).

## Routing Overview

All domain LiveViews live in the `:default` live_session, which requires authentication via `{ShepherdWeb.UserAuth, :require_authenticated}` and uses the `:app` layout. Auth views (login, registration, confirmation) live in the `:current_user` live_session with `mount_current_scope`. Settings lives in `:require_authenticated_user` with `require_authenticated` and `require_sudo_mode`.

---

## HQ Views (Dashboard/Command Center)

### `HqLive.Index` -- `/`

Primary dashboard showing LLM feedback stats, urgent items, domain cards, and activity timeline.

**Dependencies:** `Shepherd.LLM.Feedback`, `Shepherd.LLM.FeedbackManager`

**Assigns:**
- `:page_title` -- `"HQ"`
- `:active_section` -- `"hq"`
- `:user_id` -- from `current_scope.user.id`
- `:all_feedback` -- list of active feedback from `FeedbackManager.get_active_feedback/1`
- `:urgent_feedback` -- filtered subset (severity "critical" or "warning", max 5)
- `:recent_activity` -- built from acknowledged/dismissed feedback
- `:stats` -- from `FeedbackManager.get_feedback_stats/1` (contains `.total_active`, `.critical`)
- `:procrastination_score`, `:procrastination_display`, `:procrastination_status`, `:procrastination_trend` -- extracted from feedback `context_data`
- `:completion_rate`, `:completion_display`, `:completion_status`, `:completion_trend` -- extracted from feedback `context_data`

**Events:**
- `"acknowledge_feedback"` (`id`) -- marks feedback acknowledged via `FeedbackManager`, reloads data
- `"dismiss_feedback"` (`id`) -- marks feedback dismissed via `FeedbackManager`, reloads data

**Components:** `metric_card`, `urgent_item`, `feedback_stream_item`, `domain_card`, `activity_item`

---

### `HqLive.Index2` -- `/hq2`

DEFCON-style ops UI with threat board, active operations with progress bars, command queue, and domain status panel. Uses 1-second tick intervals for progress bar animation. All data is hardcoded (demo/mock data, no database queries).

**Dependencies:** None (no context modules, all data is hardcoded)

**Assigns:**
- `:page_title` -- `"HQ v2"`
- `:active_section` -- `"hq"`
- `:command_input` -- text input state for command bar
- `:defcon_level` -- integer (default 2)
- `:active_ops_count` -- integer (default 4)
- `:queue_depth` -- integer (default 12)
- `:threats` -- list of threat maps (hardcoded)
- `:active_operations` -- list of operation maps with progress (hardcoded, ticked)
- `:command_queue` -- list of command maps (hardcoded + user-submitted)
- `:domain_status` -- list of domain health maps (hardcoded)

**Events:**
- `"deploy_threat"` (`id`) -- removes threat from board
- `"defer_threat"` (`id`) -- removes threat from board
- `"dismiss_threat"` (`id`) -- removes threat from board
- `"abort_operation"` (`name`) -- removes operation from list
- `"bump_queue"` (`index`) -- moves queue item to front
- `"kill_queue"` (`index`) -- removes item from queue
- `"submit_command"` (`command`) -- adds new command to queue with auto-detected domain
- `"update_command"` (`value`) -- updates command input state

**handle_info:** `:tick` -- increments operation progress bars by 1-3% each second

**Components:** `threat_card`, `operation_card`, `queue_item`, `domain_status_card`

---

### `HqLive.Index3` -- `/hq3`

Multi-mode command center with four view modes: threat, pulse, domain, and triage. Loads real data from the database via `UserCommand` queries. Uses 2-second tick intervals.

**Dependencies:** `Shepherd.LLM.ContextManager`, `Shepherd.LLM.UserCommand`, `Shepherd.Repo`, `Ecto.Query`

**Assigns:**
- `:page_title` -- `"HQ v3"`
- `:active_section` -- `"hq"`
- `:view_mode` -- one of `"threat"`, `"pulse"`, `"domain"`, `"triage"` (default `"threat"`)
- `:focused_domain` -- string or nil, filters signals by domain
- `:triage_index` -- integer, current position in triage queue
- `:command_input` -- text input state for command bar
- `:user_id` -- from `current_scope.user.id`
- `:signals` -- list of signal maps built from pending `UserCommand` records
- `:domain_pulse` -- list of domain health/velocity maps (hardcoded)

**Events:**
- `"switch_mode"` (`mode`) -- changes view mode
- `"focus_domain"` (`domain`) -- toggles domain filter
- `"triage_deploy"` -- marks current triage signal's command as completed via `ContextManager.mark_command_completed/2`, removes signal
- `"triage_defer"` -- same as deploy (marks completed, removes signal)
- `"triage_skip"` -- advances triage index without acting
- `"signal_action"` (`id`, `action`) -- deploy/defer a specific signal from threat view
- `"submit_command"` (`command`) -- clears input (no-op for actual processing)
- `"update_command"` -- updates command input state

**handle_info:** `:tick` (2s) -- reloads signals from database, updates domain pulse

**Components:** `threat_view`, `pulse_view`, `domain_view`, `triage_view`, `signal_card`, `domain_pulse_card`

---

### `HqLive.Index4` -- `/hq4`

Manager feedback interface with tone-adaptive display. Shows LLM-generated feedback with varying presentation based on tone (harsh, encouraging, robotic, direct). Supports active/history view modes.

**Dependencies:** `Shepherd.LLM.Feedback`, `Shepherd.LLM.FeedbackManager`

**Assigns:**
- `:page_title` -- `"HQ - Manager Feedback"`
- `:active_section` -- `"hq"`
- `:user_id` -- from `current_scope.user.id`
- `:view_mode` -- `"active"` or `"all"` (default `"active"`)
- `:feedback` -- list of feedback records (active or all depending on mode)
- `:stats` -- from `FeedbackManager.get_feedback_stats/1` (contains `.total_active`, `.critical`, `.warning`)

**Events:**
- `"switch_mode"` (`mode`) -- switches between "active" and "all" (history) views, reloads feedback
- `"acknowledge_feedback"` (`id`) -- acknowledges feedback via `FeedbackManager`
- `"dismiss_feedback"` (`id`) -- dismisses feedback via `FeedbackManager`

**Components:** `feedback_card` (uses `Feedback.severity_class/1`, `Feedback.type_icon/1`, `Feedback.severity_symbol/1`)

---

## Domain Views

### `WebsiteLive.Index` -- `/website`

Full-featured website management view with sidebar navigation and five tabs: commands, complain, report, brainstorm, settings. Loads real data from the database.

**Dependencies:** `Shepherd.LLM.WebsiteManager`, `Shepherd.LLM.DirectiveProcessor`, `Shepherd.LLM.CommandManager`, `Shepherd.Repo`, `Shepherd.Websites.Website`, `Ecto.Query`

**Assigns:**
- `:page_title` -- `"Website"` (changes per tab)
- `:active_section` -- `"website"`
- `:active_tab` -- query param `tab` value (nil, "commands", "complain", "report", "brainstorm", "settings")
- `:user_id` -- from `current_scope.user.id`
- `:website` -- the user's first `Website` record or nil
- `:questions` -- unanswered onboarding questions for the website
- `:complaints` -- unanswered complaint-type questions for the website
- `:commands` -- pending commands for the website from `CommandManager`
- `:context` -- website context map from `WebsiteManager.get_context/2`

**Events:**
- `"change_tab"` (`tab`) -- navigates via `push_patch` to update URL query param
- `"answer_question"` (`question-id`, `answer`) -- records answer via `WebsiteManager.record_answer/3`, processes with `DirectiveProcessor` for onboarding questions
- `"create_website"` (`url`, optional `name`) -- creates website via `WebsiteManager.create_website_with_scan/1`
- `"update_domain"` (`domain`) -- updates website URL
- `"dismiss_question"` (`question-id`) -- dismisses question via `WebsiteManager.dismiss_question/2`
- `"complete_command"` (`command-id`) -- completes command via `CommandManager.complete_command/2`
- `"dismiss_command"` (`command-id`) -- dismisses command via `CommandManager.dismiss_command/2`

**handle_params:** Updates `:active_tab` and `:page_title` from URL query params.

**Tabs:**
- **commands** -- shows pending commands with urgency badges and LLM reasoning; complete/dismiss actions
- **complain** -- shows complaint-type questions with severity and answer choices
- **report** -- placeholder content
- **brainstorm** -- placeholder content
- **settings** -- website domain editor, website info display, analysis status with CLI instructions

**Components:** `website_sidebar`, `sidebar_nav_link`, `question_card`, `command_card`, `complaint_card`

---

### `TerminalLive.Index` -- `/terminal`

Simulated terminal monitoring UI with live clock, process progress bars, agent status matrix, queue stats, system vitals, control buttons, and a scrolling system log. All data is hardcoded (demo). Uses 1-second tick intervals.

**Dependencies:** None (all data is hardcoded)

**Assigns:**
- `:page_title` -- `"Terminal"`
- `:active_section` -- `"terminal"`
- `:uptime_seconds` -- integer, incremented every tick
- `:system_load` -- integer (hardcoded 84)
- `:active_agents` -- integer (hardcoded 17)
- `:active_processes` -- list of process maps with progress bars
- `:agent_status` -- list of agent maps (hardcoded)
- `:queue_data` -- map with task counts by department (hardcoded)
- `:system_vitals` -- map with token/API/resource usage (hardcoded)
- `:log_entries` -- list of log entry maps, grows over time

**Events:**
- `"refresh_ai"` -- resets active processes and adds log entry
- `"emergency_stop"` -- clears all active processes, adds critical log entry

**handle_info:** `:tick` (1s) -- increments uptime, updates process progress, randomly adds log entries

---

## Sidebar-Navigation Domain Views (Scaffold/Demo)

These views share the same pattern: sidebar with tab links, tab content via `handle_params`, and hardcoded demo `command_card` components with [Done]/[No]/[Push] buttons that have no wired-up event handlers. They do NOT use `current_scope` or any database context modules.

**Common pattern:**
- `mount/3`: assigns `:page_title`, `:active_section`, `:active_tab`
- `handle_params/3`: updates `:active_tab` and `:page_title` from URL params
- `handle_event("change_tab", ...)`: uses `push_patch` to update URL
- Components: domain-specific `_sidebar`, shared `sidebar_nav_link`, `command_card`

### `AppLive.Index` -- `/app`
Tabs: backlog, bugs, pull_requests, deployments, documentation, settings. First tab ("backlog") and "bugs" and "deployments" have hardcoded command cards. Others are placeholder text.

### `MarketingLive.Index` -- `/marketing`
Tabs: campaigns, content, analytics, social_media, creative_assets, settings. "campaigns" tab has hardcoded command cards. Others are placeholder text.

### `FunnelLive.Index` -- `/funnel`
Tabs: funnels, builder, pages, analytics, conversions, settings. "funnels" tab has hardcoded command cards. Others are placeholder text.

### `SalesLive.Index` -- `/sales`
Tabs: pipeline, leads, active_deals, follow_ups, proposals, reports, settings. "pipeline" tab has hardcoded command cards. Others are placeholder text.

### `HrLive.Index` -- `/hr`
Tabs: recruiting, onboarding, performance, team_events, policies, reports, settings. "recruiting" tab has hardcoded command cards. Others are placeholder text.

### `CustomersLive.Index` -- `/customers`
Tabs: support, feedback, accounts, health_score, renewals, reports, settings. "support" tab has hardcoded command cards. Others are placeholder text.

---

## Authentication Views (UserLive)

These views use the standard `Layouts.app` layout (not the terminal theme). They are generated/adapted from `phx.gen.auth`.

### `UserLive.Login` -- `/users/log-in`

**Live session:** `:current_user` (on_mount `mount_current_scope` -- does not require auth)

**Dependencies:** `Shepherd.Accounts`

**Assigns:**
- `:form` -- login form (email field)
- `:trigger_submit` -- boolean for phx-trigger-action on password form

**Events:**
- `"submit_password"` -- sets `trigger_submit: true` to POST to `UserSessionController.create`
- `"submit_magic"` (`email`) -- sends magic link login email via `Accounts.deliver_login_instructions/2`, shows flash

### `UserLive.Registration` -- `/users/register`

**Live session:** `:current_user` (on_mount `mount_current_scope` -- does not require auth)

**Dependencies:** `Shepherd.Accounts`, `Shepherd.Accounts.User`

**Assigns:**
- `:form` -- registration form (email field)

**Events:**
- `"save"` (`user` params) -- registers user via `Accounts.register_user/1`, sends login email
- `"validate"` (`user` params) -- validates email changeset in real-time

**Note:** Redirects to signed-in path if user is already authenticated.

### `UserLive.Settings` -- `/users/settings` and `/users/settings/confirm-email/:token`

**Live session:** `:require_authenticated_user` (requires auth + sudo mode via `require_sudo_mode` on_mount)

**Dependencies:** `Shepherd.Accounts`

**Assigns:**
- `:current_email` -- current user email
- `:email_form` -- email change form
- `:password_form` -- password change form
- `:trigger_submit` -- boolean for password form submission

**Events:**
- `"validate_email"` -- validates email changeset
- `"update_email"` -- sends email change confirmation link
- `"validate_password"` -- validates password changeset
- `"update_password"` -- triggers password update form submission to `UserSessionController.update_password`

**mount with token:** Processes email confirmation token via `Accounts.update_user_email/2`.

### `UserLive.Confirmation` -- `/users/log-in/:token`

**Live session:** `:current_user` (on_mount `mount_current_scope` -- does not require auth)

**Dependencies:** `Shepherd.Accounts`

**Assigns:**
- `:user` -- user looked up by magic link token
- `:form` -- token form
- `:trigger_submit` -- boolean

**Events:**
- `"submit"` (`user` params) -- triggers form action to POST login with token

**Note:** Shows different UI for unconfirmed users (confirm + login) vs confirmed users (just login). Redirects to login page if token is invalid/expired.

---

## Known Issues

- `HqLive.Index2` and `TerminalLive.Index` use entirely hardcoded demo data with no database integration
- Sidebar domain views (`AppLive`, `MarketingLive`, `FunnelLive`, `SalesLive`, `HrLive`, `CustomersLive`) have [Done]/[No]/[Push] buttons on command cards that are not wired to any `handle_event` callbacks
- `HqLive.Index3` domain pulse data is hardcoded (not derived from database); only signals are loaded from the database
- `HqLive.Index3` `"submit_command"` event clears input but does not actually create a command in the database

---

## Patterns and Conventions

- **Terminal aesthetic:** green-on-black, ASCII box-drawing characters, CRT scanline overlay (`<div class="scanlines pointer-events-none">`), `terminal-glow` / `terminal-glow-red` CSS classes
- **Live ticking:** `:timer.send_interval(1000, self(), :tick)` in `connected?/1` guard for real-time updates (Index2, Index3, TerminalLive)
- **Tab navigation:** URL query params (`?tab=commands`) via `handle_params/3`; sidebar links use `navigate` with sigil_p
- **All HQ views** use inline HEEx templates (no separate `.heex` files)
- **All domain sidebar views** share the same structural pattern: sidebar + content area, `change_tab` event, `sidebar_nav_link` component
- **Auth integration:** Active views (HQ Index, Index3, Index4, WebsiteLive) extract `user_id` from `socket.assigns.current_scope.user.id`
- **Context module usage:**
  - `FeedbackManager` -- used by `HqLive.Index` and `HqLive.Index4`
  - `ContextManager` + `UserCommand` -- used by `HqLive.Index3`
  - `WebsiteManager` + `CommandManager` + `DirectiveProcessor` -- used by `WebsiteLive.Index`
- **Component pattern:** Private function components with `attr` declarations, used for cards and list items

---

## Auto-Update Rules

When modifying files in this module:
- Adding/removing a LiveView: Update Active Views or Stub Views sections
- Adding/removing routes: Update routes in view descriptions
- Adding handle_event callbacks: Update the view's event documentation
- Changing assigns: Update assigns documentation
- Fixing known issues: Remove from Known Issues section
- Always verify this CLAUDE.md reflects the current state after significant changes

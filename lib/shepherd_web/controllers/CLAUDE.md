# Controllers Module

Web controllers for the Shepherd application. Handles HTTP requests for health checks, static pages, user session management, and error rendering. All controllers use `ShepherdWeb, :controller` or `ShepherdWeb, :html` macros.

## Controllers

### HealthController (`health_controller.ex`)

API-only controller for infrastructure health checks. Returns JSON responses.

- **Module:** `ShepherdWeb.HealthController`
- **Pipeline:** `:api` (JSON only, no session/CSRF)
- **Route:** `GET /api/health` -> `:check`

#### Actions

- `check/2` -- Executes `SELECT 1` against `Shepherd.Repo` to verify database connectivity. Returns `{"status": "ok", "timestamp": "<utc_now>"}` with 200 on success, or `{"status": "error", "message": "database unavailable"}` with 503 on failure.

### PageController (`page_controller.ex`)

Serves static pages. Currently only the home/landing page.

- **Module:** `ShepherdWeb.PageController`
- **Pipeline:** `:browser`
- **Note:** The `"/"` route is actually handled by `HqLive.Index` (behind authentication), NOT by PageController. PageController's `home` action is not currently routed in the router.

#### Actions

- `home/2` -- Renders the `:home` template via `PageHTML` with `layout: false` (no application layout wrapper).

### UserSessionController (`user_session_controller.ex`)

Handles user authentication session lifecycle: login (email/password and magic link), password update, and logout.

- **Module:** `ShepherdWeb.UserSessionController`
- **Aliases:** `Shepherd.Accounts`, `ShepherdWeb.UserAuth`

#### Actions

- `create/2` -- Login action with two entry patterns:
  - **Confirmed user flow:** When params contain `"_action" => "confirmed"`, delegates to private `create/3` with flash message "User confirmed successfully."
  - **Standard login flow:** All other cases delegate to private `create/3` with flash message "Welcome back!"
  - Private `create/3` supports two authentication methods:
    - **Magic link login:** When params contain `"user" => %{"token" => token}`. Calls `Accounts.login_user_by_magic_link/1`. On success, disconnects old sessions and logs in via `UserAuth.log_in_user/3`. On failure, redirects to `/users/log-in` with error flash.
    - **Email/password login:** When params contain `"user" => %{"email" => ..., "password" => ...}`. Calls `Accounts.get_user_by_email_and_password/2`. On failure, sets error flash and preserves email (truncated to 160 chars) to prevent user enumeration attacks.
- `update_password/2` -- Updates user password. Requires authenticated user (`:require_authenticated_user` plug) and sudo mode (`Accounts.sudo_mode?/1` assertion). Calls `Accounts.update_user_password/2`, disconnects expired sessions, sets return path to `/users/settings`, then re-logs in via `create/2`.
- `delete/2` -- Logs out the user. Sets info flash "Logged out successfully." and calls `UserAuth.log_out_user/1`.

#### Routes

| Method | Path | Action | Pipeline/Scope |
|--------|------|--------|----------------|
| POST | `/users/log-in` | `:create` | `:browser` |
| DELETE | `/users/log-out` | `:delete` | `:browser` |
| POST | `/users/update-password` | `:update_password` | `:browser`, `:require_authenticated_user` |

## Views and Templates

### PageHTML (`page_html.ex`)

- **Module:** `ShepherdWeb.PageHTML`
- Uses `ShepherdWeb, :html`
- Embeds all templates from the `page_html/` directory via `embed_templates "page_html/*"`

### Templates

- **`page_html/home.html.heex`** -- Landing page template. Displays the Phoenix Framework logo, version badge, theme toggle, and links to Phoenix docs, GitHub source, and changelog. Also includes community links (Elixir Forum, Discord, Slack) and Phoenix deployment docs link. Rendered with `layout: false`.

### ErrorHTML (`error_html.ex`)

- **Module:** `ShepherdWeb.ErrorHTML`
- Uses `ShepherdWeb, :html`
- Invoked by the endpoint for HTML error responses (configured in `config/config.exs`)
- Uses a catch-all `render/2` that converts template names to plain text status messages via `Phoenix.Controller.status_message_from_template/1` (e.g., `"404.html"` -> `"Not Found"`)
- Custom error templates can be added by uncommenting `embed_templates "error_html/*"` and creating files like `error_html/404.html.heex`

### ErrorJSON (`error_json.ex`)

- **Module:** `ShepherdWeb.ErrorJSON`
- Invoked by the endpoint for JSON error responses (configured in `config/config.exs`)
- Uses a catch-all `render/2` that returns `%{errors: %{detail: "<status message>"}}` using `Phoenix.Controller.status_message_from_template/1`
- Custom status-specific handlers can be added as additional `render/2` clauses (e.g., `render("500.json", _assigns)`)

## Pipelines and Plugs

### `:browser` Pipeline

Applied to PageController and UserSessionController routes:

1. `plug :accepts, ["html"]` -- Accept HTML content type
2. `plug :fetch_session` -- Load session data
3. `plug :fetch_live_flash` -- Load flash messages (LiveView compatible)
4. `plug :put_root_layout, html: {ShepherdWeb.Layouts, :root}` -- Set root layout
5. `plug :protect_from_forgery` -- CSRF protection
6. `plug :put_secure_browser_headers` -- Security headers
7. `plug :fetch_current_scope_for_user` -- Load current user scope from session (from `ShepherdWeb.UserAuth`)

### `:api` Pipeline

Applied to HealthController routes:

1. `plug :accepts, ["json"]` -- Accept JSON content type only

### Authentication Plugs

- `:require_authenticated_user` -- Applied to the `/users/update-password` route scope. Defined in `ShepherdWeb.UserAuth`. Ensures the connection has an authenticated user.

## Error Handling Patterns

- **Health check:** Returns structured JSON with appropriate HTTP status codes (200 for ok, 503 for database unavailable). Uses pattern matching on `Ecto.Adapters.SQL.query/2` result.
- **Authentication errors:** Failed login attempts redirect to `/users/log-in` with error flash messages. Email is preserved in flash (truncated to 160 chars) to prevent user enumeration.
- **Magic link errors:** Invalid or expired tokens redirect to `/users/log-in` with descriptive error flash.
- **HTML errors:** `ErrorHTML.render/2` catch-all produces plain text status messages from template names.
- **JSON errors:** `ErrorJSON.render/2` catch-all produces structured `%{errors: %{detail: ...}}` responses.
- **Sudo mode:** `update_password/2` uses `true = Accounts.sudo_mode?(user)` assertion which will raise `MatchError` if sudo mode is not active.

## Session Management

- **Login:** `UserAuth.log_in_user/3` handles session creation after successful authentication. Supports optional `"remember_me"` parameter via `user_params`.
- **Logout:** `UserAuth.log_out_user/1` clears the session and redirects.
- **Session disconnection:** `UserAuth.disconnect_sessions/1` invalidates existing LiveView sessions when tokens are rotated (on magic link login or password update).
- **Password update flow:** After updating password, expired tokens are disconnected, return path is set to `/users/settings`, and the user is re-authenticated through the `create` action pipeline.
- **User scope:** `fetch_current_scope_for_user` plug loads the current user scope into `conn.assigns.current_scope` on every browser request.

## Auto-Update Rules

When modifying files in this module:
- Adding/removing controllers: Update Controllers section
- Adding/removing actions: Update action documentation
- Changing routes: Update route documentation
- Adding error handlers: Update Error Handling section
- Always verify this CLAUDE.md reflects the current state after significant changes

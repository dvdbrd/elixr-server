# Web Components

## Modules

### `CoreComponents` (`core_components.ex`)

Phoenix-derived core UI component library. Uses `Phoenix.Component`, `Gettext`, and `Phoenix.LiveView.JS`.

#### Function Components

- **`flash/1`** -- Renders toast-style flash notices (top-right positioned).
  - `attr :id, :string` -- optional id for the flash container
  - `attr :flash, :map, default: %{}` -- map of flash messages
  - `attr :title, :string, default: nil` -- optional title text
  - `attr :kind, :atom, values: [:info, :error]` -- determines styling and flash key lookup
  - `attr :rest, :global` -- arbitrary HTML attributes
  - `slot :inner_block` -- optional inner block overriding the flash message
  - Uses DaisyUI `toast`, `alert`, `alert-info`, `alert-error` classes.
  - Auto-generates id as `"flash-#{kind}"` if not provided.
  - Click dismisses via `JS.push("lv:clear-flash")` + `hide/2`.

- **`button/1`** -- Renders a button or navigation link.
  - `attr :variant, :string, values: ~w(primary)` -- `"primary"` renders `btn-primary`; `nil` (default) renders `btn-primary btn-soft`
  - `attr :rest, :global, include: ~w(href navigate patch)` -- supports navigation attrs
  - `slot :inner_block, required: true`
  - Renders as `<.link>` when `href`, `navigate`, or `patch` is present; otherwise renders as `<button>`.

- **`input/1`** -- Renders form inputs with label and error messages.
  - `attr :id, :any, default: nil`
  - `attr :name, :any`
  - `attr :label, :string, default: nil`
  - `attr :value, :any`
  - `attr :type, :string, default: "text"` -- supports: `checkbox`, `color`, `date`, `datetime-local`, `email`, `file`, `month`, `number`, `password`, `range`, `search`, `select`, `tel`, `text`, `textarea`, `time`, `url`, `week`
  - `attr :field, Phoenix.HTML.FormField` -- form field struct (e.g. `@form[:email]`)
  - `attr :errors, :list, default: []`
  - `attr :checked, :boolean` -- for checkbox inputs
  - `attr :prompt, :string, default: nil` -- prompt option for select inputs
  - `attr :options, :list` -- options for select inputs
  - `attr :multiple, :boolean, default: false` -- multiple flag for select
  - `attr :rest, :global` -- includes standard HTML input attributes (accept, autocomplete, disabled, placeholder, required, rows, etc.)
  - Wraps each input in `<fieldset class="fieldset mb-2">` with `<label>`.
  - Checkbox: renders hidden "false" input + `checkbox checkbox-sm`.
  - Select: renders `<select class="w-full select">` with error class `select-error`.
  - Textarea: renders `<textarea class="w-full textarea">` with error class `textarea-error`.
  - Default: renders `<input class="w-full input">` with error class `input-error`.

- **`header/1`** -- Renders a page header with title, optional subtitle, and action buttons.
  - `attr :class, :string, default: nil`
  - `slot :inner_block, required: true` -- the title content
  - `slot :subtitle` -- optional subtitle paragraph
  - `slot :actions` -- optional action buttons (right-aligned)
  - Renders `<header>` with flex layout when actions are present; always includes `pb-4`.

- **`table/1`** -- Renders a data table with generic styling.
  - `attr :id, :string, required: true`
  - `attr :rows, :list, required: true` -- supports regular lists and `Phoenix.LiveView.LiveStream`
  - `attr :row_id, :any, default: nil` -- function for generating row ids
  - `attr :row_click, :any, default: nil` -- function for `phx-click` on each row
  - `attr :row_item, :any, default: &Function.identity/1` -- maps each row before rendering
  - `slot :col, required: true` -- column slots with `attr :label, :string`
  - `slot :action` -- optional action column (rendered last)
  - Uses DaisyUI `table table-zebra` class. Supports LiveView streams via `phx-update="stream"`.

- **`list/1`** -- Renders a definition-style data list.
  - `slot :item, required: true` -- items with `attr :title, :string, required: true`
  - Uses DaisyUI `list` and `list-row` classes.

- **`icon/1`** -- Renders a Heroicon.
  - `attr :name, :string, required: true` -- icon name (must start with `"hero-"`), suffixed with `-solid` or `-mini` for variants
  - `attr :class, :string, default: "size-4"`
  - Renders as `<span class={[@name, @class]} />`. Icons bundled by `assets/vendor/heroicons.js`.

#### JS Command Helpers

- **`show/2`** -- Animates element in with opacity+translate transition (300ms ease-out).
- **`hide/2`** -- Animates element out with opacity+translate transition (200ms ease-in).

#### Error Translation

- **`translate_error/1`** -- Translates `{msg, opts}` error tuples using Gettext (`"errors"` domain).
- **`translate_errors/2`** -- Translates all errors for a given field from a keyword list.

---

### `CustomIcons` (`custom_icons.ex`)

Custom SVG icon components for navigation and UI elements. All icons are stroke-based, 24x24 viewBox.

#### Function Component

- **`custom_icon/1`**
  - `attr :name, :string, required: true` -- icon name identifier
  - `attr :class, :string, default: "w-6 h-6"` -- CSS classes
  - `attr :rest, :global` -- additional HTML attributes

#### Available Icons

| Name             | Description                    |
|------------------|--------------------------------|
| `dashboard`      | Home/house icon (Dashboard/Feed) |
| `globe`          | Globe icon (Website)           |
| `code`           | Code brackets icon (App)       |
| `megaphone`      | Arrows icon (Marketing)        |
| `dollar`         | Dollar in circle icon (Sales)  |
| `briefcase`      | Briefcase icon (HR)            |
| `customer_group` | Multiple users icon (Customers)|
| `funnel`         | Funnel/filter icon (Funnel)    |
| `profile`        | Single user icon (Profile)     |
| `settings`       | Gear/cog icon (Settings)       |

Fallback: unknown names render a plus/cross icon.

---

### `Navbar` (`navbar.ex`)

Fixed left sidebar navigation. Imports `ShepherdWeb.CustomIcons`.

#### Function Component

- **`navbar/1`** (public)
  - `attr :active_section, :string, default: "search"`
  - Renders a `<nav>` fixed to the left edge, full viewport height.
  - Width: `w-16` on mobile, `md:w-40` on desktop.
  - Styled with `bg-terminal`, green border, and green glow box-shadow.
  - Section labels are hidden on mobile (`hidden md:inline`).

#### Navigation Links (top to bottom)

**Main section (top, flex-1):**

| Icon             | Section      | Path          |
|------------------|-------------|---------------|
| `dashboard`      | `hq`        | `/`           |
| `globe`          | `website`   | `/website`    |
| `code`           | `app`       | `/app`        |
| `megaphone`      | `marketing` | `/marketing`  |
| `funnel`         | `funnel`    | `/funnel`     |
| `dollar`         | `sales`     | `/sales`      |
| `briefcase`      | `hr`        | `/hr`         |
| `customer_group` | `customers` | `/customers`  |

**Bottom section (mt-auto):**

| Icon       | Section    | Path              |
|------------|-----------|-------------------|
| `settings` | `terminal`| `/terminal`       |
| `profile`  | `account` | `/users/settings` |

#### Private Components

- **`nav_icon/1`** -- Renders a single nav link with icon, label, and optional notification badge.
  - `attr :icon, :string, required: true`
  - `attr :section, :string, required: true`
  - `attr :active, :boolean, required: true`
  - `attr :notification_count, :integer, default: 0`
  - `attr :class, :string, default: ""`
  - Active state: green background/border glow. Inactive: transparent with hover glow.
  - Badge: red circle positioned top-right, capped at `"99+"`.
  - Inline hover effects via `onmouseover`/`onmouseout` for box-shadow glow.

- **`get_section_path/1`** -- Maps section name to URL path.

---

### `Layouts` (`layouts.ex`)

Layout components and templates. Uses `ShepherdWeb, :html`. Imports `ShepherdWeb.Navbar`. Embeds templates from `layouts/` directory.

#### Function Components (Public)

- **`simple/1`** -- Minimal layout without navbar. Centered content with flash.
  - `slot :inner_block` -- page content
  - Renders `<main>` with max-width container + `<.flash_group>`.

- **`flash_group/1`** -- Renders the standard flash message group.
  - `attr :flash, :map, required: true`
  - `attr :id, :string, default: "flash-group"`
  - Includes `:info` and `:error` flash components.
  - Includes auto-show/hide client-error and server-error flashes for LiveView disconnection/reconnection (with spinning arrow icon).

- **`main_layout/1`** -- Primary layout with sidebar navbar for authenticated pages.
  - `attr :current_user, :map, default: nil`
  - `attr :current_location, :map, default: nil`
  - `attr :active_section, :string, default: nil`
  - `attr :active_subsection, :string, default: nil`
  - `attr :categories, :list, default: []`
  - `attr :received_offers, :list, default: []`
  - `attr :sent_offers, :list, default: []`
  - `attr :accepted_offers, :list, default: []`
  - `attr :flash, :map, default: %{}`
  - `attr :active_offers_count, :integer, default: 0`
  - `attr :unread_notifications_count, :integer, default: 0`
  - `attr :unread_messages_count, :integer, default: 0`
  - `attr :socket, :any, default: nil`
  - `slot :inner_block, required: true`
  - Renders `h-screen bg-terminal` container with `<.navbar>` and `<main>` offset by `pl-16 md:pl-40`.

- **`theme_toggle/1`** -- Three-way theme toggle (system / light / dark).
  - Dispatches `"phx:set-theme"` JS event with `%{theme: "system"|"light"|"dark"}`.
  - Styled as pill-shaped card with sliding indicator using CSS attribute selectors (`[data-theme=light]`, `[data-theme=dark]`).
  - Uses Heroicons: `hero-computer-desktop-micro`, `hero-sun-micro`, `hero-moon-micro`.

#### Private Components

- **`profile_button/1`** -- User avatar button with dropdown menu.
  - `attr :current_user, :map, default: nil`
  - Logged in: shows avatar initial, toggles `#profile-dropdown` with `JS.toggle`.
  - Dropdown items: Profile (`/my`), Subscription (`/subscription`), Settings (`/settings`), Sign out (`/users/log_out` DELETE).
  - Logged out: shows "Account" link to `/users/log_in`.

- **`mobile_nav_content/1`** -- Mobile navigation drawer content.
  - `attr :current_user, :map, default: nil`
  - `attr :active_offers_count, :integer, default: 0`
  - `attr :unread_notifications_count, :integer, default: 0`
  - `attr :unread_messages_count, :integer, default: 0`
  - Logged in: Offers, Items, Messages (with badges), Subscription, Settings, Sign Out.
  - Logged out: "View Premium Features" and "Sign In" buttons.

- **`mobile_nav_item/1`** -- Single mobile nav link with icon and optional badge.
  - `attr :path, :string, default: nil`
  - `attr :navigate, :string, default: nil`
  - `attr :href, :string, default: nil`
  - `attr :method, :string, default: nil`
  - `attr :icon, :string, required: true`
  - `attr :badge, :integer, default: nil`
  - `slot :inner_block, required: true`

- **`desktop_nav_item/1`** -- Desktop nav link with icon and optional badge.
  - `attr :path, :string, required: true`
  - `attr :icon, :string, required: true`
  - `attr :badge, :integer, default: nil`
  - `slot :inner_block, required: true`

- **`locked_desktop_nav_item/1`** -- Disabled/locked nav item (greyed out with lock icon).
  - `attr :icon, :string, required: true`
  - `attr :text, :string, required: true`

- **`dropdown_item/1`** -- Profile dropdown menu item.
  - `attr :navigate, :string, default: nil`
  - `attr :href, :string, default: nil`
  - `attr :method, :string, default: nil`
  - `attr :icon, :string, required: true`
  - `attr :text, :string, required: true`
  - `attr :danger, :boolean, default: false` -- applies `text-error` styling

---

## Layout Templates

### `app.html.heex`

The application layout template embedded by `Layouts`. Wraps content in `<.main_layout>` passing through assigns:
- `current_user`, `active_section`, `active_subsection`
- `received_offers`, `sent_offers`, `accepted_offers`
- `flash`
- Renders `@inner_content` inside the main layout.

### `root.html.heex`

The HTML document shell. Includes:
- **Meta tags**: charset, viewport, CSRF token
- **User meta** (when logged in): `user-token` (Phoenix.Token signed), `current-user-id`
- **SEO meta**: `page_title` (via `<.live_title>`), `meta_description`, `meta_keywords`, `canonical_url`
- **Open Graph tags**: `og_title`, `og_description`, `og_image`, `og_url`, `og_type` (default `"website"`), `og:site_name` ("Shepherd")
- **Twitter Card tags**: `twitter_title`, `twitter_description`, `twitter_image` (card type: `summary_large_image`)
- **Structured data**: optional `structured_data` assign rendered as `application/ld+json` script
- **Assets**: `/assets/css/app.css` (phx-track-static), `/assets/js/app.js` (defer, phx-track-static)
- **Theme script** (inline, runs before paint): reads `localStorage["phx:theme"]`, sets `data-theme` attribute on `<html>`. Listens for `storage` events and `phx:set-theme` custom events.
- **Body**: `class="h-full antialiased bg-terminal text-green-500"`, wraps `@inner_content` in a div with `data-route` attribute.

---

## Styling

### Framework
- Tailwind CSS v4 + DaisyUI component library
- Theme toggle supports system/light/dark via `data-theme` attribute on `<html>`

### Terminal Aesthetic Classes
- `bg-terminal` -- dark terminal background color
- `terminal-glow` -- green glow effect
- `terminal-glow-red` -- red glow effect
- `scanlines` -- CRT scanline overlay effect
- Base text color: `text-green-500` (set on `<body>`)

### DaisyUI Components Used
- `toast`, `alert`, `alert-info`, `alert-error` -- flash notifications
- `btn`, `btn-primary`, `btn-soft`, `btn-accent` -- buttons
- `fieldset`, `fieldset-label` -- form field wrappers
- `input`, `input-error` -- text inputs
- `select`, `select-error` -- select dropdowns
- `textarea`, `textarea-error` -- textareas
- `checkbox`, `checkbox-sm` -- checkboxes
- `table`, `table-zebra` -- data tables
- `list`, `list-row` -- data lists
- `card` -- card containers (theme toggle)
- `badge` -- notification badges use custom red styling, not DaisyUI badge

### Navbar-Specific Styling
- Active nav item: `bg-green-500 bg-opacity-20 border-green-400 text-green-300` + green box-shadow glow
- Inactive nav item: `bg-terminal border-green-500 border-opacity-20 text-green-500 text-opacity-60` with hover glow
- Notification badge: `bg-red-500 text-white` absolute-positioned circle with red box-shadow glow

### Vendor JS
Located in `assets/vendor/`:
- `daisyui.js` -- DaisyUI runtime
- `daisyui-theme.js` -- DaisyUI theme configuration
- `heroicons.js` -- Heroicon CSS bundling plugin
- `topbar.js` -- Page load progress bar

---

## JavaScript Behavior

### Theme Persistence (inline in `root.html.heex`)
- Reads/writes `localStorage["phx:theme"]` with values `"light"`, `"dark"`, or removed for system
- Sets `data-theme` attribute on `<html>` element
- Listens for `storage` events (cross-tab sync) and `phx:set-theme` custom events (from `theme_toggle/1`)

### LiveView JS Commands
- `JS.push("lv:clear-flash")` -- clears flash on click
- `JS.toggle(to: "#profile-dropdown")` -- toggles profile dropdown visibility
- `JS.hide(to: "#profile-dropdown")` -- hides dropdown on click-away
- `JS.hide(to: "#mobile-nav-menu")` -- hides mobile nav on item click
- `JS.dispatch("phx:set-theme", detail: %{theme: ...})` -- dispatches theme change
- `JS.show/JS.hide` with `phx-disconnected`/`phx-connected` for client/server error flashes

### Inline Event Handlers (Navbar)
- `onmouseover`/`onmouseout` on inactive nav items for box-shadow glow effect

---

## Auto-Update Rules

When modifying files in this module:
- Adding/removing components: Update the relevant module section
- Adding/removing component attrs: Update component documentation
- Adding custom icons: Update CustomIcons list
- Changing navbar links: Update Navbar documentation
- Changing CSS classes or design tokens: Update Styling section
- Always verify this CLAUDE.md reflects the current state after significant changes

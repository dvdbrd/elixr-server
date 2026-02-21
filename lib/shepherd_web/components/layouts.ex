defmodule ShepherdWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use ShepherdWeb, :html
  alias Phoenix.LiveView.JS
  import ShepherdWeb.Navbar

  embed_templates "layouts/*"

  def simple(assigns) do
    ~H"""
    <main class="px-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders the main layout with navbar for LiveView pages.
  """
  attr :current_user, :map, default: nil
  attr :current_location, :map, default: nil
  attr :active_section, :string, default: nil
  attr :active_subsection, :string, default: nil
  attr :categories, :list, default: []
  attr :received_offers, :list, default: []
  attr :sent_offers, :list, default: []
  attr :accepted_offers, :list, default: []
  attr :flash, :map, default: %{}
  attr :active_offers_count, :integer, default: 0
  attr :unread_notifications_count, :integer, default: 0
  attr :unread_messages_count, :integer, default: 0
  attr :notification_counts, :map, default: %{}
  attr :socket, :any, default: nil
  slot :inner_block, required: true

  def main_layout(assigns) do
    ~H"""
    <div class="h-screen bg-terminal">
      <.navbar active_section={assigns[:active_section]} notification_counts={@notification_counts} />

      <main class="h-full overflow-y-auto bg-terminal pl-16 md:pl-40">
        {render_slot(@inner_block)}
      </main>
    </div>

    <.flash_group flash={assigns[:flash] || %{}} />
    """
  end

  attr :current_user, :map, default: nil

  defp profile_button(assigns) do
    ~H"""
    <%= if @current_user do %>
      <button
        class=" rounded-lg hover:bg-base-200 transition-colors"
        phx-click={JS.toggle(to: "#profile-dropdown")}
        aria-label="Toggle profile menu"
      >
        <div class="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-primary-content font-bold text-sm">
          {String.first(@current_user.username || @current_user.email)}
        </div>
      </button>

      <div
        id="profile-dropdown"
        class="hidden absolute top-14 right-2 w-48 rounded-lg p-2 bg-base-100 border border-base-200 shadow-lg z-50"
        phx-click-away={JS.hide(to: "#profile-dropdown")}
      >
        <.dropdown_item navigate="/my" icon="hero-user" text="Profile" />
        <.dropdown_item navigate="/subscription" icon="hero-star" text="Subscription" />
        <.dropdown_item navigate="/users/settings" icon="hero-cog-6-tooth" text="Settings" />
        <div class="my-2 border-t border-base-content/20"></div>
        <.dropdown_item
          href="/users/log-out"
          method="delete"
          icon="hero-arrow-right-on-rectangle"
          text="Sign out"
          danger={true}
        />
      </div>
    <% else %>
      <.link navigate="/users/log_in" class="btn btn-primary btn-md">
        Account
      </.link>
    <% end %>
    """
  end

  attr :current_user, :map, default: nil
  attr :active_offers_count, :integer, default: 0
  attr :unread_notifications_count, :integer, default: 0
  attr :unread_messages_count, :integer, default: 0

  defp mobile_nav_content(assigns) do
    ~H"""
    <div class="py-4">
      <div class="space-y-1 px-2">
        <%= if @current_user do %>
          <.mobile_nav_item
            path="/my/offers"
            icon="hero-arrow-path-rounded-square"
            badge={@active_offers_count}
          >
            Offers
          </.mobile_nav_item>

          <.mobile_nav_item path="/my/items" icon="hero-cube">
            Items
          </.mobile_nav_item>

          <.mobile_nav_item
            path="/messages"
            icon="hero-chat-bubble-left-right"
            badge={@unread_messages_count}
          >
            Messages
          </.mobile_nav_item>

          <div class="border-t border-base-content/20 my-4 mx-4"></div>
          <.mobile_nav_item navigate="/subscription" icon="hero-star">
            Subscription
          </.mobile_nav_item>

          <.mobile_nav_item navigate="/users/settings" icon="hero-cog-6-tooth">
            Settings
          </.mobile_nav_item>

          <div class="border-t border-base-content/20 my-4 mx-4"></div>
          <.mobile_nav_item href="/users/log-out" method="delete" icon="hero-arrow-right-on-rectangle">
            Sign Out
          </.mobile_nav_item>
        <% else %>
          <div class="px-4 py-4 space-y-3">
            <.link navigate="/pricing" class="btn btn-accent w-full">
              View Premium Features
            </.link>
            <.link navigate="/users/log_in" class="btn btn-primary w-full">
              Sign In
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :path, :string, default: nil
  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :method, :string, default: nil
  attr :icon, :string, required: true
  attr :badge, :integer, default: nil
  slot :inner_block, required: true

  defp mobile_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate || @path}
      href={@href}
      method={@method}
      class="flex items-center px-2 py-4 text-base rounded-lg transition-colors text-base-content hover:bg-base-200 hover:text-primary"
      phx-click={JS.hide(to: "#mobile-nav-menu")}
    >
      <.icon name={@icon} class="w-5 h-5 mr-3" />
      <span class="flex-1">{render_slot(@inner_block)}</span>
      <%= if @badge && @badge > 0 do %>
        <span class="text-xs px-2 py-1 rounded-full ml-2 font-bold bg-error text-error-content">
          {@badge}
        </span>
      <% end %>
    </.link>
    """
  end

  attr :path, :string, required: true
  attr :icon, :string, required: true
  attr :badge, :integer, default: nil
  slot :inner_block, required: true

  defp desktop_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class="flex items-center px-6 py-3 text-base font-medium rounded-lg transition-colors text-base-content hover:bg-base-200 hover:text-primary"
    >
      <.icon name={@icon} class="w-5 h-5 mr-3" />
      <span>{render_slot(@inner_block)}</span>
      <%= if @badge && @badge > 0 do %>
        <span class="text-xs px-2 py-1 rounded-full ml-2 font-bold bg-error text-error-content">
          {@badge}
        </span>
      <% end %>
    </.link>
    """
  end

  attr :icon, :string, required: true
  attr :text, :string, required: true

  defp locked_desktop_nav_item(assigns) do
    ~H"""
    <div class="flex items-center px-6 py-3 text-base font-medium rounded-lg opacity-40 cursor-not-allowed bg-base-200">
      <.icon name="hero-lock-closed" class="w-5 h-5 mr-3 text-base-content opacity-50" />
      <.icon name={@icon} class="w-5 h-5 mr-3 text-base-content opacity-50" />
      <span class="text-base-content opacity-50">{@text}</span>
    </div>
    """
  end

  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :method, :string, default: nil
  attr :icon, :string, required: true
  attr :text, :string, required: true
  attr :danger, :boolean, default: false

  defp dropdown_item(assigns) do
    ~H"""
    <%= if @navigate do %>
      <.link
        navigate={@navigate}
        class={[
          "flex items-center gap-3 px-4 py-3 text-sm rounded-lg transition-colors w-full",
          @danger && "text-error hover:bg-base-200",
          !@danger && "text-base-content hover:bg-base-200 hover:text-primary"
        ]}
      >
        <.icon name={@icon} class="w-4 h-4" />
        {@text}
      </.link>
    <% else %>
      <.link
        href={@href}
        method={@method}
        class={[
          "flex items-center gap-3 px-4 py-3 text-sm rounded-lg transition-colors w-full",
          @danger && "text-error hover:bg-base-200",
          !@danger && "text-base-content hover:bg-base-200 hover:text-primary"
        ]}
      >
        <.icon name={@icon} class="w-4 h-4" />
        {@text}
      </.link>
    <% end %>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-[33%] h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2" aria-label="Use system theme">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2" aria-label="Use light theme">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2" aria-label="Use dark theme">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end

defmodule ShepherdWeb.HqLive.Index4 do
  @moduledoc """
  HQ v4 - Manager Feedback Interface

  Displays LLM-generated feedback with varying tones:
  - Harsh warnings for procrastinators
  - Encouraging messages for high performers
  - Robotic analysis for technical feedback
  - Direct summaries for weekly/daily recaps
  """

  use ShepherdWeb, :live_view
  alias Shepherd.LLM.{Feedback, FeedbackManager}

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "HQ - Manager Feedback")
      |> assign(:active_section, "hq")
      |> assign(:user_id, user_id)
      |> assign(:notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(user_id))
      |> assign(:view_mode, "active")
      |> load_feedback()
      |> load_stats()

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_mode", %{"mode" => mode}, socket) do
    socket =
      socket
      |> assign(:view_mode, mode)
      |> load_feedback()

    {:noreply, socket}
  end

  @impl true
  def handle_event("acknowledge_feedback", %{"id" => feedback_id}, socket) do
    user_id = socket.assigns.user_id

    case FeedbackManager.acknowledge_feedback(user_id, feedback_id) do
      {:ok, _feedback} ->
        socket =
          socket
          |> load_feedback()
          |> load_stats()
          |> refresh_notification_counts()
          |> put_flash(:info, "Feedback acknowledged")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to acknowledge feedback")}
    end
  end

  @impl true
  def handle_event("dismiss_feedback", %{"id" => feedback_id}, socket) do
    user_id = socket.assigns.user_id

    case FeedbackManager.dismiss_feedback(user_id, feedback_id) do
      {:ok, _feedback} ->
        socket =
          socket
          |> load_feedback()
          |> load_stats()
          |> refresh_notification_counts()
          |> put_flash(:info, "Feedback dismissed")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to dismiss feedback")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-hidden terminal-screen flex flex-col">
      <!-- CRT Scanlines -->
      <div class="scanlines pointer-events-none"></div>

      <!-- Header -->
      <div class="border-b-2 border-green-500 p-3 relative">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-4">
            <div class="text-sm font-bold uppercase">HQ - MANAGER FEEDBACK</div>
            <div class="text-xs opacity-40">
              [<.link navigate="/" class="hover:text-green-300">v1</.link> |
              <.link navigate="/hq2" class="hover:text-green-300">v2</.link> |
              <.link navigate="/hq3" class="hover:text-green-300">v3</.link> |
              <span class="text-green-400">v4</span>]
            </div>
          </div>

          <!-- Stats Summary -->
          <div class="flex items-center gap-4 text-xs">
            <div>
              ACTIVE: <span class="font-bold"><%= @stats.total_active %></span>
            </div>
            <div class={if @stats.critical > 0, do: "text-red-500 animate-pulse", else: ""}>
              CRITICAL: <span class="font-bold"><%= @stats.critical %></span>
            </div>
            <div class={if @stats.warning > 0, do: "text-yellow-500", else: ""}>
              WARNINGS: <span class="font-bold"><%= @stats.warning %></span>
            </div>
          </div>
        </div>

        <!-- View Mode Switcher -->
        <div class="flex gap-2 text-xs">
          <button
            phx-click="switch_mode"
            phx-value-mode="active"
            class={mode_button_class(@view_mode, "active")}
          >
            ACTIVE
          </button>
          <button
            phx-click="switch_mode"
            phx-value-mode="all"
            class={mode_button_class(@view_mode, "all")}
          >
            HISTORY
          </button>
        </div>
      </div>

      <!-- Feedback Stream -->
      <div class="flex-1 overflow-auto p-4">
        <%= if @feedback == [] do %>
          <div class="flex items-center justify-center h-full">
            <div class="text-center border-2 border-green-500 p-12">
              <div class="text-4xl mb-4">✓</div>
              <%= if @view_mode == "active" do %>
                <div class="text-lg font-bold mb-2">NO ACTIVE FEEDBACK</div>
                <div class="text-xs opacity-60">Your manager has nothing to say right now</div>
              <% else %>
                <div class="text-lg font-bold mb-2">NO FEEDBACK HISTORY</div>
                <div class="text-xs opacity-60">No feedback records found</div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="max-w-4xl mx-auto space-y-4">
            <%= for feedback <- @feedback do %>
              <.feedback_card feedback={feedback} />
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Footer Info -->
      <div class="border-t-2 border-green-500 p-2 bg-terminal text-xs opacity-60 text-center">
        Feedback generated by LLM based on your behavioral metrics • Last updated: <%= format_time(
          Enum.at(@feedback, 0)
        ) %>
      </div>
    </div>
    """
  end

  # ============================================================================
  # COMPONENTS
  # ============================================================================

  attr :feedback, :map, required: true

  defp feedback_card(assigns) do
    ~H"""
    <div class={[
      "border-4 bg-terminal transition-all hover:scale-[1.01]",
      Feedback.severity_class(@feedback.severity)
    ]}>
      <!-- Header -->
      <div class="border-b-2 border-current p-4">
        <div class="flex items-start justify-between gap-4 mb-2">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="text-2xl"><%= Feedback.type_icon(@feedback.feedback_type) %></span>
              <div class="text-xs font-bold uppercase opacity-80">
                <%= format_feedback_type(@feedback.feedback_type) %> | <%= String.upcase(
                  @feedback.tone
                ) %>
              </div>
            </div>
            <h2 class="text-xl font-bold"><%= @feedback.title %></h2>
          </div>
          <div class="flex flex-col items-end gap-2">
            <span class="text-3xl"><%= Feedback.severity_symbol(@feedback.severity) %></span>
            <div class="text-xs opacity-60">
              <%= format_relative_time(@feedback.inserted_at) %>
            </div>
          </div>
        </div>
      </div>

      <!-- Message Body -->
      <div class="p-6">
        <div class="text-sm whitespace-pre-line opacity-90 leading-relaxed mb-6">
          <%= @feedback.message %>
        </div>

        <!-- Context Data (if present) -->
        <%= if @feedback.context_data != %{} do %>
          <div class="border-t border-current border-opacity-30 pt-4 mb-6">
            <div class="text-xs font-bold mb-2 opacity-60">DATA SNAPSHOT</div>
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 text-xs">
              <%= for {key, value} <- @feedback.context_data do %>
                <div>
                  <div class="opacity-60 mb-1"><%= format_key(key) %></div>
                  <div class="font-bold"><%= format_value(value) %></div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <!-- Actions -->
        <%= if @feedback.status == "active" do %>
          <div class="flex gap-2">
            <button
              phx-click="acknowledge_feedback"
              phx-value-id={@feedback.id}
              class="flex-1 border-2 border-current px-4 py-3 hover:bg-current hover:bg-opacity-10 transition-all font-bold text-sm uppercase"
            >
              [A] ACKNOWLEDGE
            </button>
            <button
              phx-click="dismiss_feedback"
              phx-value-id={@feedback.id}
              class="border-2 border-current border-opacity-30 px-4 py-3 opacity-60 hover:opacity-100 transition-all font-bold text-sm uppercase"
            >
              [D] DISMISS
            </button>
          </div>
        <% else %>
          <div class="text-center py-3 text-xs opacity-40 uppercase border border-current border-opacity-20">
            <%= @feedback.status %> • <%= format_relative_time(@feedback.acknowledged_at || @feedback.dismissed_at) %>
          </div>
        <% end %>
      </div>

      <!-- Expiration Notice (if applicable) -->
      <%= if @feedback.expires_at && @feedback.status == "active" do %>
        <div class="border-t-2 border-current p-2 text-center text-xs opacity-60">
          ⏰ Expires <%= format_relative_time(@feedback.expires_at) %>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  defp refresh_notification_counts(socket) do
    assign(socket, :notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(socket.assigns.user_id))
  end

  defp load_feedback(socket) do
    user_id = socket.assigns.user_id
    mode = socket.assigns[:view_mode] || "active"

    feedback =
      case mode do
        "active" -> FeedbackManager.get_active_feedback(user_id)
        "all" -> FeedbackManager.get_all_feedback(user_id, 20)
        _ -> FeedbackManager.get_active_feedback(user_id)
      end

    assign(socket, :feedback, feedback)
  end

  defp load_stats(socket) do
    user_id = socket.assigns.user_id
    stats = FeedbackManager.get_feedback_stats(user_id)
    assign(socket, :stats, stats)
  end

  defp mode_button_class(current_mode, mode) do
    base = "px-3 py-1 border transition-all"

    if current_mode == mode do
      base <> " border-green-400 text-green-400 bg-green-900 bg-opacity-20"
    else
      base <> " border-green-500 border-opacity-30 opacity-60 hover:opacity-100"
    end
  end

  defp format_feedback_type(type) do
    type
    |> String.replace("_", " ")
    |> String.upcase()
  end

  defp format_key(key) when is_binary(key) do
    key
    |> String.replace("_", " ")
    |> String.upcase()
  end

  defp format_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> format_key()
  end

  defp format_value(value) when is_float(value) do
    cond do
      value < 1.0 -> "#{round(value * 100)}%"
      true -> Float.to_string(value)
    end
  end

  defp format_value(value) when is_integer(value), do: Integer.to_string(value)
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value), do: inspect(value)

  defp format_relative_time(nil), do: "never"

  defp format_relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604800 -> "#{div(diff, 86400)}d ago"
      true -> "#{div(diff, 604800)}w ago"
    end
  end

  defp format_time(nil), do: "never"

  defp format_time(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d, %Y at %H:%M UTC")
  end

  defp format_time(feedback) when is_map(feedback) do
    format_time(feedback.updated_at || feedback.inserted_at)
  end
end

defmodule ShepherdWeb.HqLive.Index do
  use ShepherdWeb, :live_view
  alias Shepherd.LLM.FeedbackManager

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "HQ")
      |> assign(:active_section, "hq")
      |> assign(:user_id, user_id)
      |> load_feedback_data()
      |> load_stats()

    {:ok, socket}
  end

  @impl true
  def handle_event("acknowledge_feedback", %{"id" => feedback_id}, socket) do
    user_id = socket.assigns.user_id

    case FeedbackManager.acknowledge_feedback(user_id, feedback_id) do
      {:ok, _} ->
        socket =
          socket
          |> load_feedback_data()
          |> load_stats()
          |> put_flash(:info, "Feedback acknowledged")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to acknowledge")}
    end
  end

  @impl true
  def handle_event("dismiss_feedback", %{"id" => feedback_id}, socket) do
    user_id = socket.assigns.user_id

    case FeedbackManager.dismiss_feedback(user_id, feedback_id) do
      {:ok, _} ->
        socket =
          socket
          |> load_feedback_data()
          |> load_stats()
          |> put_flash(:info, "Feedback dismissed")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to dismiss")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-auto terminal-screen">
      <!-- CRT Scanlines Effect -->
      <div class="scanlines pointer-events-none"></div>

      <div class="p-4 lg:p-6 relative">
        <!-- Terminal Header -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 p-3">
            <div class="flex items-center gap-2 mb-2">
              <div class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
              <div class="w-2 h-2 rounded-full bg-yellow-500 animate-pulse"></div>
              <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
            </div>
            <div class="text-sm lg:text-base uppercase">
              HQ - BUSINESS OPERATIONS COMMAND
            </div>
            <div class="text-xs opacity-80 mt-1">
              SYSTEM STATUS: OPERATIONAL | MANAGER FEEDBACK ACTIVE
            </div>
          </div>
        </div>

        <!-- Business Health Metrics -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ PERFORMANCE METRICS ═══</span>
          </div>
          <div class="p-3">
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
              <.metric_card
                label="Active Feedback"
                value={"#{@stats.total_active}"}
                change={if @stats.total_active > 3, do: "HIGH", else: "NORMAL"}
                trend={if @stats.total_active > 3, do: "down", else: "up"}
                icon="feedback"
              />
              <.metric_card
                label="Critical Issues"
                value={"#{@stats.critical}"}
                change={if @stats.critical > 0, do: "ACTION REQUIRED", else: "ALL CLEAR"}
                trend={if @stats.critical > 0, do: "down", else: "up"}
                icon="critical"
              />
              <.metric_card
                label="Proc. Score"
                value={@procrastination_display}
                change={@procrastination_status}
                trend={@procrastination_trend}
                icon="score"
              />
              <.metric_card
                label="Completion"
                value={@completion_display}
                change={@completion_status}
                trend={@completion_trend}
                icon="completion"
              />
            </div>
          </div>
        </div>

        <!-- Main Grid: Urgent Items + Feedback Stream -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
          <!-- Urgent Items -->
          <div class="lg:col-span-1">
            <div class="border-2 border-red-500 terminal-glow-red">
              <div class="border-b-2 border-red-500 px-3 py-2 bg-terminal">
                <span class="text-sm font-bold text-red-500">⊗ URGENT FEEDBACK</span>
              </div>
              <div class="p-3 space-y-2">
                <%= for feedback <- @urgent_feedback do %>
                  <.urgent_item feedback={feedback} />
                <% end %>
                <%= if Enum.empty?(@urgent_feedback) do %>
                  <div class="text-xs opacity-60 p-2">All clear - no urgent items</div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Feedback Stream -->
          <div class="lg:col-span-2">
            <div class="border-2 border-green-500 terminal-glow">
              <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                <span class="text-sm font-bold text-green-400">═══ MANAGER FEEDBACK STREAM ═══</span>
              </div>
              <div class="p-3 space-y-2">
                <%= for feedback <- Enum.take(@all_feedback, 10) do %>
                  <.feedback_stream_item feedback={feedback} />
                <% end %>
                <%= if Enum.empty?(@all_feedback) do %>
                  <div class="text-center p-6">
                    <div class="text-2xl mb-3">◇</div>
                    <p class="text-xs font-bold text-green-400 uppercase mb-1">No active feedback</p>
                    <p class="text-xs opacity-60">Check back after running analysis.</p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Domain Summary Cards -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ DOMAINS ═══</span>
          </div>
          <div class="p-3">
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
              <.domain_card
                name="Website"
                icon="hero-globe-alt"
                pending_tasks={3}
                link="/website"
                status="healthy"
              />
              <.domain_card name="App" icon="hero-code-bracket" pending_tasks={5} link="/app" status="warning" />
              <.domain_card
                name="Marketing"
                icon="hero-megaphone"
                pending_tasks={2}
                link="/marketing"
                status="healthy"
              />
              <.domain_card name="Funnel" icon="hero-funnel" pending_tasks={1} link="/funnel" status="healthy" />
              <.domain_card
                name="Sales"
                icon="hero-currency-dollar"
                pending_tasks={4}
                link="/sales"
                status="healthy"
              />
              <.domain_card
                name="HR"
                icon="hero-user-group"
                pending_tasks={2}
                link="/hr"
                status="healthy"
              />
              <.domain_card
                name="Customers"
                icon="hero-user-circle"
                pending_tasks={3}
                link="/customers"
                status="warning"
              />
            </div>
          </div>
        </div>

        <!-- Recent Activity Timeline -->
        <div class="border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ RECENT ACTIVITY TIMELINE ═══</span>
          </div>
          <div class="p-3 space-y-3">
            <%= for activity <- @recent_activity do %>
              <.activity_item
                action={activity.action}
                domain={activity.domain}
                title={activity.title}
                time={activity.time}
              />
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============================================================================
  # COMPONENTS
  # ============================================================================

  # Metric Card Component
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :change, :string, required: true
  attr :trend, :string, required: true
  attr :icon, :string, required: true

  defp metric_card(assigns) do
    ~H"""
    <div class="border border-green-500 p-3 bg-terminal">
      <div class="text-xs opacity-80 uppercase mb-1">
        {@label}
      </div>
      <div class="text-xl font-bold mb-2">
        {@value}
      </div>
      <div class={[
        "text-xs flex items-center gap-1",
        @trend == "up" && "text-green-400",
        @trend == "down" && "text-red-500"
      ]}>
        <span>{if @trend == "up", do: "▲", else: "▼"}</span>
        <span>{@change}</span>
      </div>
      <div class="mt-2 text-xs opacity-60">
        {terminal_icon(@icon)}
      </div>
    </div>
    """
  end

  # Urgent Item Component
  attr :feedback, :map, required: true

  defp urgent_item(assigns) do
    ~H"""
    <div class="block p-2 border border-red-500 bg-terminal">
      <div class="flex items-start justify-between gap-2">
        <div class="flex items-start gap-2 flex-1">
          <span class="text-red-500 text-xs">►</span>
          <div class="flex-1">
            <p class="text-xs font-bold text-red-500 uppercase">
              [{severity_label(@feedback.severity)}] {String.upcase(@feedback.tone)}
            </p>
            <p class="text-xs mt-1 opacity-90">
              {@feedback.title}
            </p>
          </div>
          <p class="text-xs opacity-60 whitespace-nowrap">
            {time_ago(@feedback.inserted_at)}
          </p>
        </div>
        <button
          phx-click="acknowledge_feedback"
          phx-value-id={@feedback.id}
          class="text-xs border border-green-500 text-green-500 px-2 py-0.5 hover:bg-green-900 hover:bg-opacity-20 transition-colors"
        >
          ACK
        </button>
      </div>
    </div>
    """
  end

  # Feedback Stream Item Component
  attr :feedback, :map, required: true

  defp feedback_stream_item(assigns) do
    ~H"""
    <div class="block p-2 border border-green-500 bg-terminal">
      <div class="flex items-center justify-between gap-2">
        <div class="flex items-center gap-2 flex-1">
          <span class="text-green-400 text-xs">{status_icon(@feedback.status)}</span>
          <div class="flex-1">
            <p class="text-xs font-bold text-green-400 uppercase">
              [{feedback_type_label(@feedback.feedback_type)}] {String.upcase(@feedback.tone)}
            </p>
            <p class="text-xs mt-1 opacity-90">
              {@feedback.title}
            </p>
          </div>
          <span class={[
            "text-xs px-2 py-0.5 border uppercase",
            severity_class(@feedback.severity)
          ]}>
            {@feedback.severity}
          </span>
        </div>
        <%= if @feedback.status == "active" do %>
          <div class="flex gap-1 ml-2">
            <button
              phx-click="acknowledge_feedback"
              phx-value-id={@feedback.id}
              class="text-xs border border-green-500 text-green-500 px-2 py-0.5 hover:bg-green-900 hover:bg-opacity-20 transition-colors"
            >
              ACK
            </button>
            <button
              phx-click="dismiss_feedback"
              phx-value-id={@feedback.id}
              class="text-xs border border-red-500 text-red-500 px-2 py-0.5 hover:bg-red-900 hover:bg-opacity-20 transition-colors"
            >
              DISMISS
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Domain Card Component
  attr :name, :string, required: true
  attr :icon, :string, required: true
  attr :pending_tasks, :integer, required: true
  attr :link, :string, required: true
  attr :status, :string, required: true

  defp domain_card(assigns) do
    ~H"""
    <.link
      navigate={@link}
      class="border border-green-500 p-3 bg-terminal hover:bg-green-900 hover:bg-opacity-20 transition-colors block"
    >
      <div class="flex items-center gap-2 mb-3">
        <span class="text-sm">{domain_icon(@name)}</span>
        <h3 class="font-bold text-xs uppercase flex-1">
          {@name}
        </h3>
        <span class={["text-xs", domain_status_indicator(@status)]}>
          {status_symbol(@status)}
        </span>
      </div>
      <div class="text-xs opacity-80">
        TASKS: {@pending_tasks}
      </div>
      <div class="text-xs opacity-60 mt-1">
        [{render_mini_bar(@pending_tasks, 8)}]
      </div>
    </.link>
    """
  end

  # Activity Item Component
  attr :action, :string, required: true
  attr :domain, :string, required: true
  attr :title, :string, required: true
  attr :time, :string, required: true

  defp activity_item(assigns) do
    ~H"""
    <div class="flex items-start gap-2 text-xs">
      <span class={["text-sm flex-shrink-0", activity_icon_class(@action)]}>
        {activity_icon(@action)}
      </span>
      <div class="flex-1">
        <span class={["font-bold uppercase", activity_color(@action)]}>
          [{@domain}]
        </span>
        <span class="opacity-90 ml-2">
          {@title}
        </span>
      </div>
      <span class="text-xs opacity-60 whitespace-nowrap">
        [{@time}]
      </span>
    </div>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  defp load_feedback_data(socket) do
    user_id = socket.assigns.user_id
    all_feedback = FeedbackManager.get_active_feedback(user_id)

    urgent_feedback =
      all_feedback
      |> Enum.filter(&(&1.severity in ["critical", "warning"]))
      |> Enum.take(5)

    # Get recent activity from all feedback (acknowledged + dismissed)
    recent_activity = build_recent_activity(user_id)

    socket
    |> assign(:all_feedback, all_feedback)
    |> assign(:urgent_feedback, urgent_feedback)
    |> assign(:recent_activity, recent_activity)
  end

  defp load_stats(socket) do
    user_id = socket.assigns.user_id
    stats = FeedbackManager.get_feedback_stats(user_id)

    # Extract procrastination score from active feedback context_data
    {proc_score, proc_display, proc_status, proc_trend} = extract_procrastination_data(socket.assigns.all_feedback)

    # Extract completion rate from active feedback context_data
    {comp_rate, comp_display, comp_status, comp_trend} = extract_completion_data(socket.assigns.all_feedback)

    socket
    |> assign(:stats, stats)
    |> assign(:procrastination_score, proc_score)
    |> assign(:procrastination_display, proc_display)
    |> assign(:procrastination_status, proc_status)
    |> assign(:procrastination_trend, proc_trend)
    |> assign(:completion_rate, comp_rate)
    |> assign(:completion_display, comp_display)
    |> assign(:completion_status, comp_status)
    |> assign(:completion_trend, comp_trend)
  end

  defp extract_procrastination_data(feedback_list) do
    # Find feedback with procrastination_score in context_data
    score =
      feedback_list
      |> Enum.find_value(fn f ->
        f.context_data["procrastination_score"] || f.context_data[:procrastination_score]
      end)

    case score do
      nil ->
        {0.0, "N/A", "NO DATA", "up"}

      score when is_float(score) or is_integer(score) ->
        score_float = if is_integer(score), do: score * 1.0, else: score
        display = "#{:erlang.float_to_binary(score_float, decimals: 1)}/10"

        {status, trend} =
          cond do
            score_float >= 8.0 -> {"CRITICAL", "down"}
            score_float >= 6.0 -> {"WARNING", "down"}
            score_float >= 4.0 -> {"MODERATE", "up"}
            true -> {"GOOD", "up"}
          end

        {score_float, display, status, trend}

      _ ->
        {0.0, "N/A", "NO DATA", "up"}
    end
  end

  defp extract_completion_data(feedback_list) do
    # Find feedback with completion_rate in context_data
    rate =
      feedback_list
      |> Enum.find_value(fn f ->
        f.context_data["completion_rate"] || f.context_data[:completion_rate]
      end)

    case rate do
      nil ->
        {0.0, "N/A", "NO DATA", "up"}

      rate when is_float(rate) or is_integer(rate) ->
        rate_float = if is_integer(rate), do: rate * 1.0, else: rate
        percentage = trunc(rate_float * 100)
        display = "#{percentage}%"

        {status, trend} =
          cond do
            rate_float >= 0.8 -> {"EXCELLENT", "up"}
            rate_float >= 0.6 -> {"GOOD", "up"}
            rate_float >= 0.4 -> {"NEEDS WORK", "down"}
            true -> {"POOR", "down"}
          end

        {rate_float, display, status, trend}

      _ ->
        {0.0, "N/A", "NO DATA", "up"}
    end
  end

  defp build_recent_activity(user_id) do
    all = FeedbackManager.get_all_feedback(user_id, 10)

    all
    |> Enum.filter(&(&1.status in ["acknowledged", "dismissed"]))
    |> Enum.take(5)
    |> Enum.map(fn feedback ->
      action =
        case feedback.status do
          "acknowledged" -> "completed"
          "dismissed" -> "rejected"
          _ -> "started"
        end

      time_at = feedback.acknowledged_at || feedback.dismissed_at || feedback.inserted_at

      %{
        action: action,
        domain: feedback_type_to_domain(feedback.feedback_type),
        title: feedback.title,
        time: time_ago(time_at)
      }
    end)
    |> then(fn activities ->
      # If no activities, show dummy data
      if Enum.empty?(activities) do
        [
          %{action: "completed", domain: "Feedback", title: "No recent activity", time: "N/A"}
        ]
      else
        activities
      end
    end)
  end

  defp feedback_type_to_domain(feedback_type) do
    case feedback_type do
      "daily_summary" -> "Summary"
      "weekly_summary" -> "Summary"
      "procrastination_warning" -> "Manager"
      "harsh_warning" -> "Manager"
      "encouragement" -> "Manager"
      "performance_review" -> "Analysis"
      _ -> "System"
    end
  end

  defp terminal_icon(icon) do
    case icon do
      "feedback" -> "[◉]"
      "critical" -> "[✕]"
      "score" -> "[▓]"
      "completion" -> "[●]"
      _ -> "[•]"
    end
  end

  defp status_icon(status) do
    case status do
      "active" -> "○"
      "acknowledged" -> "●"
      "dismissed" -> "✕"
      "expired" -> "◌"
      _ -> "•"
    end
  end

  defp severity_class(severity) do
    case severity do
      "critical" -> "border-red-500 text-red-500"
      "warning" -> "border-yellow-500 text-yellow-500"
      "success" -> "border-green-400 text-green-400"
      "info" -> "border-green-500 text-green-500 opacity-60"
      _ -> "border-green-500 text-green-500"
    end
  end

  defp severity_label(severity) do
    String.upcase(severity)
  end

  defp feedback_type_label(type) do
    type
    |> String.replace("_", " ")
    |> String.upcase()
  end

  defp domain_icon(name) do
    case name do
      "Website" -> "◆"
      "App" -> "▣"
      "Marketing" -> "♦"
      "Funnel" -> "▼"
      "Sales" -> "◉"
      "HR" -> "◈"
      "Customers" -> "◍"
      _ -> "■"
    end
  end

  defp status_symbol(status) do
    case status do
      "healthy" -> "●"
      "warning" -> "▲"
      "error" -> "✕"
      _ -> "○"
    end
  end

  defp domain_status_indicator(status) do
    case status do
      "healthy" -> "text-green-400"
      "warning" -> "text-yellow-500"
      "error" -> "text-red-500"
      _ -> "text-green-500"
    end
  end

  defp render_mini_bar(count, max_width) do
    filled = min(count, max_width)
    String.duplicate("█", filled) <> String.duplicate("░", max_width - filled)
  end

  defp activity_icon(action) do
    case action do
      "completed" -> "►"
      "started" -> "◐"
      "rejected" -> "✕"
      _ -> "•"
    end
  end

  defp activity_icon_class(action) do
    case action do
      "completed" -> "text-green-400"
      "started" -> "text-yellow-500"
      "rejected" -> "text-red-500"
      _ -> "text-green-500"
    end
  end

  defp activity_color(action) do
    case action do
      "completed" -> "text-green-400"
      "started" -> "text-yellow-500"
      "rejected" -> "text-red-500"
      _ -> "text-green-500"
    end
  end

  defp time_ago(nil), do: "unknown"

  defp time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end

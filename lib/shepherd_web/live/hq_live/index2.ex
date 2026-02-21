defmodule ShepherdWeb.HqLive.Index2 do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      socket
      |> assign(:page_title, "HQ v2")
      |> assign(:active_section, "hq")
      |> assign(:command_input, "")
      |> assign(:defcon_level, 2)
      |> assign(:active_ops_count, 4)
      |> assign(:queue_depth, 12)
      |> assign_threats()
      |> assign_active_operations()
      |> assign_command_queue()
      |> assign_domain_status()

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      socket
      |> update_active_operations()

    {:noreply, socket}
  end

  @impl true
  def handle_event("deploy_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "AI resources deployed to threat ##{id}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("defer_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "Threat ##{id} deferred to tomorrow")

    {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "Threat ##{id} dismissed")

    {:noreply, socket}
  end

  @impl true
  def handle_event("abort_operation", %{"name" => name}, socket) do
    socket =
      socket
      |> remove_operation(name)
      |> add_flash_message(:warning, "Operation #{name} aborted")

    {:noreply, socket}
  end

  @impl true
  def handle_event("bump_queue", %{"index" => index_str}, socket) do
    case Integer.parse(index_str) do
      {index, _} ->
        queue = socket.assigns.command_queue

        if index > 0 and index < length(queue) do
          item = Enum.at(queue, index)
          new_queue = List.delete_at(queue, index) |> List.insert_at(0, item)

          socket =
            socket
            |> assign(:command_queue, new_queue)
            |> add_flash_message(:info, "Command bumped to front of queue")

          {:noreply, socket}
        else
          {:noreply, socket}
        end

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("kill_queue", %{"index" => index_str}, socket) do
    case Integer.parse(index_str) do
      {index, _} ->
        queue = socket.assigns.command_queue

        if index >= 0 and index < length(queue) do
          new_queue = List.delete_at(queue, index)

          socket =
            socket
            |> assign(:command_queue, new_queue)
            |> add_flash_message(:warning, "Command removed from queue")

          {:noreply, socket}
        else
          {:noreply, socket}
        end

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit_command", %{"command" => command}, socket) do
    if String.trim(command) != "" do
      new_command = %{
        id: :rand.uniform(10000),
        text: command,
        domain: detect_domain(command),
        eta: "~#{:rand.uniform(15)}m"
      }

      socket =
        socket
        |> update(:command_queue, fn queue -> queue ++ [new_command] end)
        |> assign(:command_input, "")
        |> add_flash_message(:info, "Command queued for execution")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_command", %{"value" => value}, socket) do
    {:noreply, assign(socket, :command_input, value)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-hidden terminal-screen flex flex-col">
      <!-- CRT Scanlines Effect -->
      <div class="scanlines pointer-events-none"></div>

      <!-- SITREP Header -->
      <div class="border-b-2 border-green-500 p-3 relative">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-4">
            <div class="text-sm lg:text-base font-bold uppercase">HQ - COMMAND OPERATIONS</div>
            <div class="text-xs opacity-60">
              [<.link navigate="/" class="hover:text-green-300">HQ v1</.link> | <span class="text-green-400">HQ v2</span>]
            </div>
          </div>
          <div class="flex items-center gap-3">
            <div class={[
              "text-xs font-bold px-2 py-1 border-2",
              defcon_class(@defcon_level)
            ]}>
              DEFCON <%= @defcon_level %>
            </div>
            <div class="text-xs opacity-80">
              OPS: <%= @active_ops_count %> | QUEUE: <%= @queue_depth %>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Layout -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left: THREAT BOARD -->
        <div class="w-80 flex-shrink-0 border-r-2 border-green-500 overflow-auto relative">
          <div class="border-b-2 border-red-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-red-500">⊗ THREAT BOARD</span>
          </div>
          <div class="p-3 space-y-2">
            <%= if @threats == [] do %>
              <div class="text-center text-xs opacity-60 py-8 border border-green-500">
                ALL CLEAR<br />NO ACTIVE THREATS
              </div>
            <% else %>
              <%= for threat <- @threats do %>
                <.threat_card threat={threat} />
              <% end %>
            <% end %>
          </div>
        </div>

        <!-- Center: ACTIVE OPS + COMMAND QUEUE -->
        <div class="flex-1 flex flex-col overflow-hidden">
          <!-- Active Operations -->
          <div class="border-b-2 border-green-500 flex-1 overflow-auto relative">
            <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal sticky top-0 z-10">
              <span class="text-sm font-bold text-green-400">═══ ACTIVE OPERATIONS ═══</span>
            </div>
            <div class="p-3 space-y-3">
              <%= if @active_operations == [] do %>
                <div class="text-center text-xs opacity-60 py-8">
                  NO ACTIVE OPERATIONS
                </div>
              <% else %>
                <%= for op <- @active_operations do %>
                  <.operation_card operation={op} />
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- Command Queue -->
          <div class="h-64 border-b-2 border-green-500 overflow-auto relative">
            <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal sticky top-0 z-10">
              <span class="text-sm font-bold text-green-400">═══ COMMAND QUEUE ═══</span>
            </div>
            <div class="p-3 space-y-2">
              <%= if @command_queue == [] do %>
                <div class="text-center text-xs opacity-60 py-4">
                  QUEUE EMPTY
                </div>
              <% else %>
                <%= for {cmd, index} <- Enum.with_index(@command_queue) do %>
                  <.queue_item command={cmd} index={index} position={index + 1} />
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- Command Input -->
          <div class="border-t-2 border-green-500 p-3 bg-terminal">
            <form phx-submit="submit_command" class="flex gap-2">
              <div class="flex-1 flex items-center border-2 border-green-500 bg-terminal px-3 py-2">
                <span class="text-green-400 mr-2">></span>
                <input
                  type="text"
                  name="command"
                  value={@command_input}
                  phx-change="update_command"
                  placeholder="Issue Command..."
                  class="flex-1 bg-transparent outline-none text-green-500 placeholder-green-500 placeholder-opacity-40"
                  autocomplete="off"
                />
              </div>
              <button
                type="submit"
                class="border-2 border-green-500 text-green-500 px-6 py-2 hover:bg-green-900 hover:bg-opacity-30 hover:text-green-400 hover:border-green-400 transition-all font-bold uppercase text-xs"
              >
                [EXECUTE]
              </button>
            </form>
          </div>
        </div>

        <!-- Right: DOMAIN STATUS -->
        <div class="w-64 flex-shrink-0 border-l-2 border-green-500 overflow-auto relative">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">DOMAINS</span>
          </div>
          <div class="p-3 space-y-2">
            <%= for domain <- @domain_status do %>
              <.domain_status_card domain={domain} />
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Threat Card Component
  attr :threat, :map, required: true

  defp threat_card(assigns) do
    ~H"""
    <div class={[
      "border-2 bg-terminal p-2 text-xs",
      threat_border_class(@threat.severity)
    ]}>
      <div class="flex items-start justify-between gap-2 mb-2">
        <div class="flex-1">
          <div class={[
            "font-bold uppercase mb-1",
            threat_text_class(@threat.severity)
          ]}>
            <%= @threat.severity %> | <%= @threat.domain %>
          </div>
          <div class="opacity-90 mb-2">
            <%= @threat.title %>
          </div>
          <div class="opacity-60 space-y-0.5">
            <div>IMPACT: <%= @threat.impact %></div>
            <div>TIME: <%= @threat.time_detected %></div>
          </div>
        </div>
      </div>
      <div class="flex gap-1 justify-end mt-2">
        <button
          phx-click="deploy_threat"
          phx-value-id={@threat.id}
          class="border border-green-500 text-green-500 px-2 py-1 hover:bg-green-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DEPLOY]
        </button>
        <button
          phx-click="defer_threat"
          phx-value-id={@threat.id}
          class="border border-yellow-500 text-yellow-500 px-2 py-1 hover:bg-yellow-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DEFER]
        </button>
        <button
          phx-click="dismiss_threat"
          phx-value-id={@threat.id}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DISMISS]
        </button>
      </div>
    </div>
    """
  end

  # Operation Card Component
  attr :operation, :map, required: true

  defp operation_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal p-3">
      <div class="flex items-start justify-between mb-2">
        <div class="flex-1">
          <div class="text-sm font-bold mb-1"><%= @operation.name %></div>
          <div class="text-xs opacity-80 mb-2"><%= @operation.description %></div>
          <div class="text-xs opacity-60">
            DOMAIN: <%= @operation.domain %> | AGENT: <%= @operation.agent %>
          </div>
        </div>
        <button
          phx-click="abort_operation"
          phx-value-name={@operation.name}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px] ml-2"
        >
          [ABORT]
        </button>
      </div>
      <div class="flex items-center gap-2 text-xs">
        <div class="flex-1">
          [<%= render_bar(@operation.progress, 20) %>]
        </div>
        <span><%= @operation.progress %>%</span>
        <span class="opacity-60">ETA: <%= @operation.eta %></span>
      </div>
    </div>
    """
  end

  # Queue Item Component
  attr :command, :map, required: true
  attr :index, :integer, required: true
  attr :position, :integer, required: true

  defp queue_item(assigns) do
    ~H"""
    <div class="border border-green-500 bg-terminal p-2 flex items-center gap-2 text-xs">
      <div class="text-green-400 font-bold w-8">#<%= @position %></div>
      <div class="flex-1">
        <div class="font-bold mb-1"><%= @command.text %></div>
        <div class="opacity-60">DOMAIN: <%= @command.domain %> | ETA: <%= @command.eta %></div>
      </div>
      <div class="flex gap-1">
        <%= if @index > 0 do %>
          <button
            phx-click="bump_queue"
            phx-value-index={@index}
            class="border border-yellow-500 text-yellow-500 px-2 py-1 hover:bg-yellow-900 hover:bg-opacity-20 uppercase text-[10px]"
          >
            [BUMP]
          </button>
        <% end %>
        <button
          phx-click="kill_queue"
          phx-value-index={@index}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [KILL]
        </button>
      </div>
    </div>
    """
  end

  # Domain Status Card Component
  attr :domain, :map, required: true

  defp domain_status_card(assigns) do
    ~H"""
    <div class="border border-green-500 bg-terminal p-2 text-xs">
      <div class="flex items-center justify-between mb-2">
        <div class="font-bold uppercase"><%= @domain.name %></div>
        <span class={domain_health_class(@domain.health)}>
          <%= health_symbol(@domain.health) %>
        </span>
      </div>
      <div class="opacity-80 space-y-0.5">
        <div>PENDING: <%= @domain.pending %></div>
        <div>LAST: <%= @domain.last_activity %></div>
      </div>
      <.link
        navigate={@domain.link}
        class="block text-center border border-green-500 py-1 mt-2 hover:bg-green-900 hover:bg-opacity-20 uppercase text-[10px]"
      >
        [INTERVENE]
      </.link>
    </div>
    """
  end

  # Helper Functions

  defp assign_threats(socket) do
    threats = [
      %{
        id: 1,
        severity: "CRITICAL",
        domain: "Sales",
        title: "Enterprise deal stalled - no contact in 48h",
        impact: "Revenue: $45K/mo",
        time_detected: "2h ago"
      },
      %{
        id: 2,
        severity: "CRITICAL",
        domain: "App",
        title: "Memory leak causing crashes for 12% of users",
        impact: "Reputation",
        time_detected: "4h ago"
      },
      %{
        id: 3,
        severity: "HIGH",
        domain: "Customers",
        title: "Support ticket #1247 escalated by VP",
        impact: "Churn risk",
        time_detected: "6h ago"
      },
      %{
        id: 4,
        severity: "ELEVATED",
        domain: "Marketing",
        title: "Campaign CTR down 34% vs. last week",
        impact: "Pipeline",
        time_detected: "8h ago"
      }
    ]

    assign(socket, :threats, threats)
  end

  defp assign_active_operations(socket) do
    operations = [
      %{
        name: "SALES_OUTREACH_089",
        description: "Drafting follow-up email sequence for Enterprise Corp",
        domain: "Sales",
        agent: "QUALIFIER_03",
        progress: 67,
        eta: "04:23"
      },
      %{
        name: "BUG_FIX_MEMORY_LEAK",
        description: "Analyzing WebSocket connection handler for memory leaks",
        domain: "App",
        agent: "DEBUGGER_01",
        progress: 40,
        eta: "08:15"
      },
      %{
        name: "SUPPORT_TICKET_1247",
        description: "Researching account history and generating response",
        domain: "Customers",
        agent: "SUPPORT_AI_02",
        progress: 78,
        eta: "02:45"
      },
      %{
        name: "CAMPAIGN_ANALYSIS_Q1",
        description: "Analyzing campaign performance and generating optimization plan",
        domain: "Marketing",
        agent: "OPTIMIZER_01",
        progress: 23,
        eta: "12:08"
      }
    ]

    assign(socket, :active_operations, operations)
  end

  defp assign_command_queue(socket) do
    queue = [
      %{
        id: 101,
        text: "Draft Q1 investor update email highlighting revenue growth",
        domain: "Sales",
        eta: "~8m"
      },
      %{
        id: 102,
        text: "Analyze competitor pricing for Enterprise tier",
        domain: "Marketing",
        eta: "~12m"
      },
      %{
        id: 103,
        text: "Create onboarding video script for new feature",
        domain: "Marketing",
        eta: "~15m"
      }
    ]

    assign(socket, :command_queue, queue)
  end

  defp assign_domain_status(socket) do
    domains = [
      %{name: "Website", health: "healthy", pending: 3, last_activity: "10m ago", link: "/website"},
      %{name: "App", health: "warning", pending: 5, last_activity: "2m ago", link: "/app"},
      %{name: "Marketing", health: "warning", pending: 4, last_activity: "5m ago", link: "/marketing"},
      %{name: "Funnel", health: "healthy", pending: 1, last_activity: "15m ago", link: "/funnel"},
      %{name: "Sales", health: "critical", pending: 7, last_activity: "1m ago", link: "/sales"},
      %{name: "HR", health: "healthy", pending: 2, last_activity: "45m ago", link: "/hr"},
      %{name: "Customers", health: "warning", pending: 3, last_activity: "3m ago", link: "/customers"}
    ]

    assign(socket, :domain_status, domains)
  end

  defp update_active_operations(socket) do
    updated_ops =
      Enum.map(socket.assigns.active_operations, fn op ->
        new_progress = min(op.progress + Enum.random(1..3), 100)
        %{op | progress: new_progress}
      end)

    assign(socket, :active_operations, updated_ops)
  end

  defp remove_threat(socket, id_str) do
    id = String.to_integer(id_str)
    threats = Enum.reject(socket.assigns.threats, fn t -> t.id == id end)
    assign(socket, :threats, threats)
  end

  defp remove_operation(socket, name) do
    operations = Enum.reject(socket.assigns.active_operations, fn op -> op.name == name end)
    assign(socket, :active_operations, operations)
  end

  defp add_flash_message(socket, type, message) do
    Phoenix.LiveView.put_flash(socket, type, message)
  end

  defp detect_domain(command) do
    cond do
      String.contains?(String.downcase(command), ["email", "campaign", "marketing", "social"]) ->
        "Marketing"

      String.contains?(String.downcase(command), ["deal", "sales", "pricing", "revenue"]) ->
        "Sales"

      String.contains?(String.downcase(command), ["bug", "fix", "code", "deploy", "api"]) ->
        "App"

      String.contains?(String.downcase(command), ["website", "landing", "page"]) ->
        "Website"

      String.contains?(String.downcase(command), ["customer", "support", "ticket"]) ->
        "Customers"

      String.contains?(String.downcase(command), ["hire", "recruit", "job"]) ->
        "HR"

      true ->
        "General"
    end
  end

  defp defcon_class(level) do
    case level do
      1 -> "border-red-500 text-red-500 animate-pulse"
      2 -> "border-yellow-500 text-yellow-500"
      3 -> "border-green-400 text-green-400"
      _ -> "border-green-500 text-green-500"
    end
  end

  defp threat_border_class(severity) do
    case severity do
      "CRITICAL" -> "border-red-500"
      "HIGH" -> "border-yellow-500"
      "ELEVATED" -> "border-orange-500"
      _ -> "border-green-500"
    end
  end

  defp threat_text_class(severity) do
    case severity do
      "CRITICAL" -> "text-red-500"
      "HIGH" -> "text-yellow-500"
      "ELEVATED" -> "text-orange-500"
      _ -> "text-green-500"
    end
  end

  defp domain_health_class(health) do
    case health do
      "healthy" -> "text-green-400"
      "warning" -> "text-yellow-500"
      "critical" -> "text-red-500 animate-pulse"
      _ -> "text-green-500"
    end
  end

  defp health_symbol(health) do
    case health do
      "healthy" -> "●"
      "warning" -> "▲"
      "critical" -> "✕"
      _ -> "○"
    end
  end

  defp render_bar(percentage, width) do
    filled = round(percentage / 100 * width)
    empty = width - filled

    String.duplicate("█", filled) <> String.duplicate("░", empty)
  end
end
